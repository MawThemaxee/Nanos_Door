local DoorEvents = Package.Require("DoorEvents.lua")
Package.Require("BaseDoor.lua")

-- Interaction modes decide WHAT makes a door open/close. BaseDoor only
-- forwards events to the door's current mode, so any package can add its own
-- (keycard, code, button, timer...) with BaseDoor.RegisterInteractionMode()
-- without editing the door package.
--
-- A mode is a table; every field is optional:
--   uses_interact_key = true           -- clients send interact-key presses
--                                      -- on this door (look at it + E)
--   OnInteract(door, character)        -- a player pressed the interact key
--                                      -- on the door (already range-checked);
--                                      -- return true if it did something
--   OnBeginOverlap(door, character)    -- a Character entered the door's trigger
--   OnEndOverlap(door, character)      -- a Character left the door's trigger
--   OnAttach(door) / OnDetach(door)    -- the mode was set on / removed from a
--                                      -- door (set up / clean up timers etc.)
-- All callbacks run on the server. Use door:TryOpen(character) /
-- door:TryClose() / door:TryToggle(character) to respect the door's lock,
-- or door:Open()-level calls (SetState / Toggle) to deliberately bypass it.
local modes = {}

function BaseDoor.RegisterInteractionMode(name, mode)
    if type(name) ~= "string" or type(mode) ~= "table" then
        error("BaseDoor.RegisterInteractionMode(name, mode): name must be a string and mode a table")
    end
    modes[name] = mode
end

function BaseDoor.GetInteractionModeDefinition(name)
    return modes[name]
end

-- Walk in to open, walk out to close.
BaseDoor.RegisterInteractionMode(DoorEvents.INTERACTION_MODE.TRIGGER, {
    OnBeginOverlap = function(door, character)
        door:TryOpen(character)
    end,
    OnEndOverlap = function(door)
        door:TryClose()
    end,
})

-- Look at the door and press the interact key to toggle it.
BaseDoor.RegisterInteractionMode(DoorEvents.INTERACTION_MODE.INTERACT, {
    uses_interact_key = true,
    OnInteract = function(door, character)
        return door:TryToggle(character)
    end,
})

-- Nothing automatic: only your own code opens/closes the door (buttons,
-- scripted events, quests...), eg. door:TryOpen() / door:Toggle().
BaseDoor.RegisterInteractionMode(DoorEvents.INTERACTION_MODE.MANUAL, {})
