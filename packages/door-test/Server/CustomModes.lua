-- Example custom interaction mode, registered from outside the door package.
-- "timed": press the interact key to open, the door closes itself after
-- CLOSE_DELAY_MS. Use it with door:SetInteractionMode("timed"), or set
-- InteractionMode = "timed" on a BP_DoorMarker in Unreal.
local CLOSE_DELAY_MS = 3000

BaseDoor.RegisterInteractionMode("timed", {
    uses_interact_key = true,

    OnInteract = function(door, character)
        if not door:TryOpen(character) then return false end

        door.close_timer = Timer.SetTimeout(function()
            door.close_timer = nil
            if door:IsValid() then door:TryClose() end
        end, CLOSE_DELAY_MS)
        return true
    end,

    OnDetach = function(door)
        if door.close_timer then
            Timer.ClearTimeout(door.close_timer)
            door.close_timer = nil
        end
    end,
})
