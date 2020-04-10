local MIN_WALK_NORMAL = 0.7

local function GroundTraceMissed()
end

local function CrashLand()
end

local function HitGround(ply, mv)
    local point = Vector(mv:GetOrigin())
    point.z = mv:GetOrigin().z - 0.25

    local trace = util.TraceEntity({startpos = mv:GetOrigin(), endpos = point, filter = ply}, ply)

    return trace.Fraction < 1
end

local function GroundTrace(pml, ply, mv)
    local point = Vector(mv:GetOrigin())
    point.z = mv:GetOrigin().z - 0.25

    local trace = util.TraceEntity({startpos = mv:GetOrigin(), endpos = point, filter = ply}, ply)

    if trace.AllSolid then
        -- do something corrective if the trace starts in a solid ..
        print("ALL SOLID UH OH")
    end

    -- if the trace didn't hit anything, we are in free fall
    if trace.Fraction == 1.0 then
        GroundTraceMissed()
        pml.groundPlane = false
        pml.walking = false
        return
    end

    -- check if getting thrown off the ground
    if mv:GetVelocity().z > 0 and mv:GetVelocity():Dot(trace.HitNormal) > 10 then
        -- go into jump animation
        if mv:GetForwardSpeed() >= 0 then
            -- ...
        else
            -- ...
        end
        ply:SetGroundEntity(NULL)
        pml.groundPlane = false
        pml.walking = false
        return
    end

    -- slopes that are too steep will not be considered onground
    if trace.HitNormal.z < MIN_WALK_NORMAL then
        -- FIXME: if they cna't slide down the slope, let them
        -- walk (sharp crevices)
        ply:SetGroundEntity(NULL)
        pml.groundPlane = true
        pml.walking = false
        return
    end

    -- hitting solid ground will end a waterjump
    -- ...

    if ply:GetGroundEntity() == NULL then
        -- just hit the ground
        CrashLand()

        -- don't do landing time if we were just going down a slope
        -- ...
    end

    ply:SetGroundEntity(trace.HitEnt)
end

return {HitGround = HitGround, GroundTrace = GroundTrace}