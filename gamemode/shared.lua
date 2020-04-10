local PLAYER = FindMetaTable("Player")
local PM = include("pmove.lua")

JUMP_RELEASED = 0
JUMP_HELD = 1

function PLAYER:SetJumpState(value)
    self:SetNWInt("JumpState", value)
end

function PLAYER:GetJumpState()
    return self:GetNWInt("JumpState")
end

local function IsFlagSet(var, flag)
    return bit.band(var, flag)
end

local function RemoveFlag(var, flag)
    return bit.band(var, bit.bnot(flag))
end

local function AddFlag(var, flag)
    return bit.bor(var, flag)
end

local function GetCurrentGravity()
    return 800
end

local function VectorMA(start, scale, direction)
    local dest = Vector()
	dest.x=start.x+direction.x*scale
	dest.y=start.y+direction.y*scale
    dest.z=start.z+direction.z*scale
    return dest
end

local function StartGravity(ply, vec)
    local ent_gravity
    if ply:GetGravity() > 0 then
        ent_gravity = ply:GetGravity()
    else
        ent_gravity = 1.0
    end
    local vel = Vector(vec)
    vel.z = vel.z - (ent_gravity * GetCurrentGravity() * 0.5 * FrameTime())
    vel.z = vel.z + (ply:GetBaseVelocity().z * FrameTime())
    return vel
end

local function FinishGravity(ply, vec)
    local ent_gravity
    if ply:GetGravity() > 0 then
        ent_gravity = ply:GetGravity()
    else
        ent_gravity = 1.0
    end
    local vel = Vector(vec)
    vel.z = vel.z - (ent_gravity * GetCurrentGravity() * FrameTime() * 0.5)
    return vel
end
--[[
local function AddJumpPower(ply, vel)
    local vel = Vector(vel)
    vel.z = vel.z + ply:GetJumpPower()
    return vel
end

-- Estimates if they jumped 
local function DidPlayerJump(ply, mv)
    local v = ply:GetVelocity()
    local v = StartGravity(ply, v)
    -- dont need to add jump power, it seems to be not needed
    -- local v = AddJumpPower(ply, v)
    local v = FinishGravity(ply, v)
    return v.z == mv:GetVelocity().z
end
]]

local function ClipVelocity(in_, normal, out, overbounce)
    local out = Vector(out)
    local angle = normal.z
    local blocked = 0x00
    if angle > 0 then
        blocked = bit.bor(blocked, 0x01)
    end
    if angle == 0 then
        blocked = bit.bor(blocked, 0x02)
    end

    local backoff = in_:Dot(normal) * overbounce

    local change
    for i=1,3 do
        change = normal[i] * backoff
        out[i] = in_[i] - change
    end

    local adjust = out:Dot(normal)
    if adjust < 0 then
        out = out - (normal * adjust)
    end
    return out
end

local function TryPlayerMove(ent, origin_, velocity)
    local origin = Vector(origin_)
    local velocity = Vector(velocity)
    local original_velocity = Vector(velocity)
    local primal_velocity = Vector(velocity)
    local time_left = FrameTime()
    local numbumps = 4
    local blocked = 0
    local numplanes = 0
    local allFraction = 0
    local MAX_CLIP_PLANES = 5
    local planes = {}

    for bumpcount=0,numbumps-1,1 do
        if velocity:Length() == 0 then
            break
        end

        local endpos = VectorMA(origin, time_left, velocity)

        local pm = util.TraceEntity({start = origin, endpos = endpos, filter = ent}, ent)

        allFraction = allFraction + pm.Fraction

        if pm.AllSolid then
            return Vector(0, 0, 0), origin
        end

        if pm.Fraction > 0 then
            if numbumps > 0 and pm.Fraction == 1 then
                local stuck = util.TraceEntity({start = pm.HitPos, endpos = pm.HitPos, filter = ent}, ent)
                if stuck.StartSolid or stuck.Fraction ~= 1.0 then
                    velocity = Vector(0, 0, 0)
                    break
                end
            end

            origin = Vector(pm.HitPos)
            if origin == nil then
                print("ORIGIN IS NIL")
            end
            original_velocity = Vector(velocity)
            numplanes = 0
        end

        if pm.Fraction == 1 then
            break
        end

        if pm.HitNormal.z > 0.7 then
            blocked = bit.bor(blocked, 1)
        end

        if pm.HitNormal.z == 0 then
            blocked = bit.bor(blocked, 2)
        end

        time_left = time_left - (time_left * pm.Fraction)

        if numplanes >= 5 then
            velocity = Vector(0, 0, 0)
            break
        end

        planes[numplanes] = Vector(pm.HitNormal)
        numplanes = numplanes + 1

        if numplanes == 1 and ent:GetMoveType() == MOVETYPE_WALK and ent:GetGroundEntity() == NULL then
            for i=0,numplanes-1,1 do
                if planes[i].z > 0.7 then
                    new_velocity = ClipVelocity(original_velocity, planes[i], new_velocity, 1)
                    original_velocity = new_velocity
                else
                    new_velocity = ClipVelocity(original_velocity, planes[i], new_velocity, 1.0)
                end
            end

            velocity = new_velocity
            original_velocity = new_velocity
        else
            for i=0,numplanes-1,1 do
                velocity = ClipVelocity(original_velocity, planes[i], velocity, 1)

                for j=0,numplanes-1,1 do
                    if j ~= i then
                        if velocity:Dot(planes[j]) < 0 then
                            break
                        end
                    end
                    if j == numplanes then
                        break
                    end
                end

                if i ~= numplanes then
                    -- ...
                else
                    if numplanes ~= 2 then
                        velocity = Vector(0, 0, 0)
                        break
                    end
                    local dir = planes[0]:Cross(planes[1]):GetNormalized()
                    local d = dir.Dot(velocity)
                    velocity = dir:Mul(d)
                end

                local d = velocity:Dot(primal_velocity)
                if d <= 0 then
                    velocity = Vector(0, 0, 0)
                    break
                end
            end
        end
    end

    if allFraction == 0 then
        velocity = Vector(0, 0, 0)
    end

    return velocity, origin
end

local function VQ3_CmdScale(cmd, playerSpeed)
    local abs = math.abs
    local sqrt = math.sqrt
    local max = abs(cmd:GetForwardMove())
    if abs(cmd:GetSideMove()) > max then
        max = abs(cmd:GetSideMove())
    end
    if abs(cmd:GetUpMove()) > max then
        max = abs(cmd:GetUpMove())
    end
    if not max or max == 0 then
        return 0
    end
    local total = sqrt(cmd:GetForwardMove() * cmd:GetForwardMove() + cmd:GetSideMove() * cmd:GetSideMove() + cmd:GetUpMove() * cmd:GetUpMove())
    local scale = playerSpeed * max / (127 * total)
    return scale
end

local function VQ3_Accelerate(playerVel, wishdir, wishspeed, accel)
    local currentspeed = playerVel:Dot(wishdir)
    local addspeed = wishspeed - currentspeed

    if addspeed <= 0 then
        return playerVel
    end

    local accelspeed = accel * wishspeed * FrameTime()

    if accelspeed > addspeed then
        accelspeed = addspeed
    end

    local x = playerVel.x + (accelspeed * wishdir.x)
    local y = playerVel.y + (accelspeed * wishdir.y)
    local z = playerVel.z + (accelspeed * wishdir.z)
    return Vector(x, y, z)
end

local function VQ3_AirMove(scale, playerVel, mv)
    local angles = mv:GetMoveAngles()
    local forward = angles:Forward()
    local up = angles:Up()
    local right = angles:Right()

    local fmove = mv:GetForwardSpeed()
    local smove = mv:GetSideSpeed()
    --[[
    local angles = cmd:GetViewAngles()
    print(angles)
    local forward = angles:Forward()
    local right = angles:Right()
    local up = angles:Up()

    local fmove = cmd:GetForwardMove()
    local smove = cmd:GetSideMove()
    ]]

    forward.z = 0
    right.z = 0
    forward:Normalize()
    right:Normalize()

    local wishvel = Vector()
    wishvel.x = forward.x * fmove + right.x * smove
    wishvel.y = forward.y * fmove + right.y * smove
    wishvel.z = 0

    local wishdir = Vector(wishvel)
    wishdir:Normalize()
    local wishspeed = wishdir:LengthSqr()
    wishspeed = wishspeed * scale

    local accel = 1
    return VQ3_Accelerate(playerVel, wishdir, wishspeed, accel)
end

hook.Add("PlayerTick", "Bhop", function (ply, mv)
    if not mv:KeyDown(IN_JUMP) then
        ply:SetJumpState(JUMP_RELEASED)
    end
end)



shared_cmdScale = -1

hook.Add("SetupMove", "Bhop", function (ply, mv, cmd)
    ply.oldOnGround = ply:OnGround()
    ply.oldOrigin = mv:GetOrigin()
    ply.cmd = cmd
    ply.cmdScale = VQ3_CmdScale(cmd, ply:GetMaxSpeed())
    shared_cmdScale = ply.cmdScale
    if ply:GetJumpState() == JUMP_HELD then
        -- disable jump
        mv:SetOldButtons(AddFlag(mv:GetOldButtons(), IN_JUMP))
    elseif ply:GetJumpState() == JUMP_RELEASED then
        -- allow jump
        mv:SetOldButtons(RemoveFlag(mv:GetOldButtons(), IN_JUMP))
    end
end)

hook.Add("Move", "Bhop", function (ply, mv)
    if not ply:OnGround() and not PM.HitGround(ply, mv) then
        local v = mv:GetVelocity()
        local v = StartGravity(ply, v)
        local v = VQ3_AirMove(ply.cmdScale, v, mv)
        local v = FinishGravity(ply, v)
        local v, origin = TryPlayerMove(ply, mv:GetOrigin(), v)
        mv:SetVelocity(v)
        mv:SetOrigin(origin)
        return true
    end
end)

hook.Add("FinishMove", "Bhop", function (ply, mv)
    local jumped = false
    if mv:KeyDown(IN_JUMP) and mv:KeyWasDown(IN_JUMP) and ply.oldOnGround and not ply:OnGround() then
        ply:SetJumpState(JUMP_HELD)
        jumped = true
    end
    --[[
    if not ply:OnGround() and mv:KeyDown(IN_SPEED) and not jumped then
        local old_vel = ply:GetVelocity()
        local new_vel = StartGravity(ply, old_vel)
        local new_vel = VQ3_AirMove(nil, old_vel, mv)
        local new_vel = FinishGravity(ply, new_vel)
        local new_pos = VectorMA(ply:GetPos(), FrameTime(), new_vel)
        ply:SetVelocity(new_vel)
        ply:SetPos(new_pos)
        return true
    end
    ]]
end)