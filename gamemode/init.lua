AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("pmove.lua")

include("shared.lua")

hook.Add("PlayerLoadout", "GiveWeapons", function (ply)
    ply:Give("weapon_crowbar")
    ply:Give("weapon_crossbow")
end)

hook.Add("Initialize", "init", function ()
    game.ConsoleCommand("sv_gravity 800\n")
end)

hook.Add("PlayerSpawn", "Set Speed", function (ply)
    ply:SetJumpPower(270)
    ply:SetWalkSpeed(320)
    ply:SetRunSpeed(320)
    ply:SetJumpState(JUMP_RELEASED)
end)