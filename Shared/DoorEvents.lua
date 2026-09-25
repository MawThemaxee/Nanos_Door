local DoorEvents = {
    STATE_CHANGED = "Door.StateChanged",
    LOCK_CHANGED = "Door.LockChanged",
    STATE = {
        CLOSED = "closed",
        OPEN = "open",
    },

    -- Built-in interaction modes (Server/DoorInteractionModes.lua): TRIGGER
    -- auto-opens on walk-in / closes on walk-out, INTERACT toggles when a
    -- player looks at it and presses the interact key, MANUAL does nothing
    -- automatically. Other packages can register their own mode names.
    INTERACTION_MODE = {
        TRIGGER = "trigger",
        INTERACT = "interact",
        MANUAL = "manual",
    },
    -- Client -> server request, payload: the door ID (DOOR_ID_KEY) read
    -- from the entity the player's trace hit.
    INTERACT_REQUEST = "Door.InteractRequest",
    -- Synced value on a door's visual mesh holding its door ID.
    DOOR_ID_KEY = "DoorID",
    -- Synced values on a door's visual mesh: its mode name (informative),
    -- and whether its mode uses the interact key, so the client can tell
    -- from a trace hit alone that it is looking at an interactable door.
    INTERACTION_MODE_KEY = "DoorInteractionMode",
    INTERACTABLE_KEY = "DoorInteractable",
    -- The game's built-in interact binding (always registered by nanos world).
    INTERACT_BINDING = "Interact",
    -- Client trace length from the camera (third-person camera sits behind
    -- the character, so this is longer than the server-side reach check).
    INTERACT_TRACE_DISTANCE = 500,
    -- Server-side max distance between the character and the door panel.
    INTERACT_MAX_DISTANCE = 300,
}

-- Package.Require's return value only reaches files inside this same package.
-- Export it too so other packages (eg. a map package placing doors) can read
-- DoorEvents.STATE / event names without duplicating these string literals.
Package.Export("DoorEvents", DoorEvents)

return DoorEvents
