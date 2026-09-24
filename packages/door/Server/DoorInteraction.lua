local DoorEvents = Package.Require("DoorEvents.lua")
Package.Require("BaseDoor.lua")

-- Server side of key-driven interaction. The client (Client/DoorInput.lua)
-- only says "I pressed interact while looking at door N"; everything that
-- matters is re-checked here, since client input can't be trusted.
Events.SubscribeRemote(DoorEvents.INTERACT_REQUEST, function(player, door_id)
    if type(door_id) ~= "number" then return end

    local door = BaseDoor.GetByDoorID(door_id)
    if not door or not door:IsValid() then return end

    local character = player:GetControlledCharacter()
    if not character or not character:IsValid() then return end

    local distance = character:GetLocation():Distance(door:GetVisualMesh():GetLocation())
    if distance > DoorEvents.INTERACT_MAX_DISTANCE then return end

    door:Interact(character)
end)
