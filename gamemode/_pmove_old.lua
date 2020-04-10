-- GMOD does not expose needed variables
--[[
local function ComputeConstraintSpeedFactor(player, mv)
    -- If we have a constraint, slow down because of that too.
    if mv:GetConstraintRadius() == 0.0 then
        return 1.0
    end
    -- "mv->m_vecConstraintCenter" is not exposed via GMOD Lua API
    -- this is a workaround that hopefully is correct
    local mv_ConstraintCenter = 
    local distSq = mv:GetAbsOrigin():DistToSqr()
end
]]

local function IsDead(player)
    return player:Health() <= 0
end

local function CheckParameters(player, mv)
    if player:GetMoveType() ~= MOVETYPE_ISOMETRIC and
       player:GetMoveType() ~= MOVETYPE_NOCLIP and
       player:GetMoveType() ~= MOVETYPE_OBSERVER then
        local spd = (mv:GetForwardSpeed() * mv:GetForwardSpeed()) +
                    (mv:GetSideSpeed() * mv:GetSideSpeed()) +
                    (mv:GetUpSpeed() + mv:GetUpSpeed())
        local maxspeed = mv:GetClientMaxSpeed()
        if maxspeed ~= 0.0 then
            mv:SetMaxSpeed(math.min(maxspeed, mv:GetMaxSpeed())
        end
        -- Slow down by the speed factor
        local speedFactor = 1.0
        local surfaceData = util.GetSurfaceData(player:EntIndex())
        if surfaceData then
            speedFactor = surfaceData.maxSpeedFactor
        end
        -- If we have a constraint, slow down because of that too.
        -- nvm, doesn't seem possible, GMOD doesn't expose enough
        -- skipping this part
        --[[
        local constraintSpeedFactor = ComputeConstraintSpeedFactor(player, mv)
        if constraintSpeedFactor < speedFactor then
            speedFactor = constraintSpeedFactor
        end
        ]]
        mv:SetMaxSpeed(mv:GetMaxSpeed() * speedFactor)
        -- skipping g_bMovementOptimizations
        spd = math.sqrt(spd)
        if spd ~= 0.0 and spd > mv:GetMaxSpeed() then
            local ratio = mv:GetMaxSpeed() / spd
            mv:SetForwardSpeed(mv:GetForwardSpeed() * ratio)
            mv:SetSideSpeed(mv:GetSideSpeed() * ratio)
            mv:SetUpSpeed(mv:GetUpSpeed() * ratio)
        end
    end

    if player:IsFlagSet(FL_FROZEN) or 
       player:IsFlagSet(FL_ONTRAIN) or
       IsDead(player) then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
    end

    -- Skipping for now
    -- DecayPunchAngle()

    -- Take angles from command.
    -- skipping
    -- ...

    -- Set dead player view_offset
    -- skipping
    -- ..

    -- Adjust client view angles to match values used on server.
    -- nvm, apparently broken according to gmod issues
end

local function PlayerMove(player, mv)
    CheckParameters()

    -- clear output applied velocity
    -- skipped. don't have access

    -- Always try and unstick us unless we are using a couple of the movement modes
    -- skipped.
    
end