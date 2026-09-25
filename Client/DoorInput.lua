local DoorEvents = Package.Require("DoorEvents.lua")

-- Client side of key-driven interaction: Input and Trace are client-only,
-- so the client finds what the player is looking at and asks the server to
-- act on it (Server/DoorInteraction.lua validates and toggles the door).

-- Hooks the game's own "Interact" binding (always registered by nanos
-- world), so doors use the same key players already use to interact.
Input.Bind(DoorEvents.INTERACT_BINDING, InputEvent.Pressed, function()
    local player = Client.GetLocalPlayer()
    if not player then return end

    local start_location = player:GetCameraLocation()
    local end_location = start_location + player:GetCameraRotation():GetForwardVector() * DoorEvents.INTERACT_TRACE_DISTANCE

    local ignored_actors = {}
    local character = player:GetControlledCharacter()
    if character then ignored_actors = { character } end

    local trace_result = Trace.LineSingle(
        start_location,
        end_location,
        CollisionChannel.WorldStatic | CollisionChannel.WorldDynamic | CollisionChannel.PhysicsBody,
        TraceMode.ReturnEntity,
        ignored_actors
    )
    if not trace_result.Success or not trace_result.Entity then return end

    -- Skip the round-trip for anything that isn't an interactable door
    -- (a door whose interaction mode uses the interact key).
    if trace_result.Entity:GetValue(DoorEvents.INTERACTABLE_KEY) ~= true then return end

    -- Send the door ID (resolved server-side via BaseDoor.GetByDoorID) rather
    -- than the hit entity, which for HingeDoor is the child mesh, not the door.
    local door_id = trace_result.Entity:GetValue(DoorEvents.DOOR_ID_KEY)
    if not door_id then return end

    Events.CallRemote(DoorEvents.INTERACT_REQUEST, Reliability.Reliable, door_id)
end)
