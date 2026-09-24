local DoorEvents = {
    STATE_CHANGED = "Door.StateChanged",
    LOCK_CHANGED = "Door.LockChanged",
    STATE = {
        CLOSED = "closed",
        OPEN = "open",
    },
}

-- Package.Require's return value only reaches files inside this same package.
-- Export it too so other packages (eg. a map package placing doors) can read
-- DoorEvents.STATE / event names without duplicating these string literals.
Package.Export("DoorEvents", DoorEvents)

return DoorEvents
