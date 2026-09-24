local DoorEvents = Package.Require("DoorEvents.lua")

-- Client side of key-driven interaction: Input and Trace are client-only,
-- so the client finds what the player is looking at and asks the server to
-- act on it (Server/DoorInteraction.lua validates and toggles the door).

-- Reuses an interact binding that already exists (from the game or another
-- package) so players keep a single "interact" key; a binding with no
-- mapped keys doesn't exist. Falls back to registering our own.
local function ResolveInteractBinding()
    for _, binding_name in ipairs(DoorEvents.INTERACT_GLOBAL_BINDINGS) do
        local keys = Input.GetMappedKeys(binding_name)
        if keys and #keys > 0 then
            return binding_name
        end
    end

    Input.Register(DoorEvents.INTERACT_BINDING, DoorEvents.INTERACT_DEFAULT_KEY, "Open / close a door")
    return DoorEvents.INTERACT_BINDING
end

local interact_binding = ResolveInteractBinding()
Console.Log("[door] interact binding: " .. interact_binding)

Input.Bind(interact_binding, InputEvent.Pressed, function()
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
