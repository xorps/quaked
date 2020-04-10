include("shared.lua")

local function TranslateState(state)
    if state == JUMP_HELD then return "JUMP_HELD" end
    if state == JUMP_RELEASED then return "JUMP_RELEASED" end
    return "UNKNOWN STATE"
end

hook.Add("HUDPaint", "MyHUD", function ()
    surface.SetFont("Default")
	surface.SetTextColor(255, 255, 255)
	surface.SetTextPos(128, 128)
    --surface.DrawText(TranslateState(LocalPlayer():GetJumpState()))
    surface.DrawText(tostring(shared_cmdScale))
end)