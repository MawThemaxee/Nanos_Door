local DoorEvents = Package.Require("DoorEvents.lua")

-- Shared skeleton for every door variant: owns the trigger (forwarded to the
-- door's interaction mode, see DoorInteractionModes.lua) and the open/closed
-- state machine + network broadcast. Concrete door types
-- (HingeDoor, SlidingDoor, ...) only implement Open()/Close() below with
-- their own movement — nothing here needs to change to add a new door type.
BaseDoor = StaticMesh.Inherit("BaseDoor")

-- Fallback door mesh asset, used by subclasses when their caller doesn't
-- declare one via the door_asset constructor argument.
BaseDoor.DEFAULT_MESH_ASSET = "nanos-world::SM_Plane"

-- Door ID -> door. A client trace hits the visible panel (for HingeDoor a
-- child mesh, not the door itself), so clients send this numeric ID,
-- synced on the visual mesh via DoorEvents.DOOR_ID_KEY, instead.
local doors_by_id = {}
local next_door_id = 0

-- Characters (incl. game-mode subclasses, hence IsA) and CharacterSimple.
local function IsDoorUser(actor)
    return actor:IsA(Character) or actor:IsA(CharacterSimple)
end

function BaseDoor:Constructor(location, rotation, mesh_asset, trigger_extent)
    self.Super:Constructor(location, rotation, mesh_asset)

    self.trigger = Trigger(location, Rotator(), trigger_extent or 150, TriggerType.Sphere, false, Color.RED, { "Character", "CharacterSimple" })
    self.state = DoorEvents.STATE.CLOSED
    self.locked = false
    -- Not published to clients until SetInteractionMode() is called: the
    -- visual mesh may not exist yet here (HingeDoor creates it afterwards),
    -- and clients treat a missing value as "no interact key".
    self.interaction_mode = DoorEvents.INTERACTION_MODE.TRIGGER

    -- The trigger only reports who entered/left; what that does is up to the
    -- door's interaction mode (see DoorInteractionModes.lua).
    self.trigger:Subscribe("BeginOverlap", function(_, actor)
        if IsDoorUser(actor) then self:CallModeCallback("OnBeginOverlap", actor) end
    end)

    self.trigger:Subscribe("EndOverlap", function(_, actor)
        if IsDoorUser(actor) then self:CallModeCallback("OnEndOverlap", actor) end
    end)
end

-- Calls `callback_name` on the door's current interaction mode, if it
-- defines it, and returns its result.
function BaseDoor:CallModeCallback(callback_name, ...)
    local mode = BaseDoor.GetInteractionModeDefinition(self.interaction_mode)
    local callback = mode and mode[callback_name]
    if callback then
        return callback(self, ...)
    end
end

-- Chooses what opens/closes the door: a mode name registered with
-- BaseDoor.RegisterInteractionMode() — built-in "trigger", "interact",
-- "manual", or your own. Call it after construction, eg.
-- HingeDoor(...):SetInteractionMode("interact").
function BaseDoor:SetInteractionMode(mode_name)
    local mode = BaseDoor.GetInteractionModeDefinition(mode_name)
    if not mode then
        error("BaseDoor:SetInteractionMode() unknown mode: " .. tostring(mode_name))
    end

    self:CallModeCallback("OnDetach")
    self.interaction_mode = mode_name

    if not self.door_id then
        next_door_id = next_door_id + 1
        self.door_id = next_door_id
        doors_by_id[self.door_id] = self
        self:Subscribe("Destroy", function()
            doors_by_id[self.door_id] = nil
        end)
    end

    local visual_mesh = self:GetVisualMesh()
    visual_mesh:SetValue(DoorEvents.DOOR_ID_KEY, self.door_id, true)
    visual_mesh:SetValue(DoorEvents.INTERACTION_MODE_KEY, mode_name, true)
    visual_mesh:SetValue(DoorEvents.INTERACTABLE_KEY, mode.uses_interact_key == true, true)

    self:CallModeCallback("OnAttach")
    return self
end

function BaseDoor:GetInteractionMode()
    return self.interaction_mode
end

-- Returns the door with this ID (see DoorEvents.DOOR_ID_KEY), or nil. Only
-- doors that went through SetInteractionMode() are registered.
function BaseDoor.GetByDoorID(door_id)
    return doors_by_id[door_id]
end

-- The door's Trigger entity, to customize it (eg. SetExtent, SetColor,
-- SetOverlapOnlyClasses). Its overlaps are forwarded to the current mode.
function BaseDoor:GetTrigger()
    return self.trigger
end

function BaseDoor:SetTriggerExtent(extent)
    self.trigger:SetExtent(extent)
end

function BaseDoor:IsOpen()
    return self.state == DoorEvents.STATE.OPEN
end

function BaseDoor:Toggle()
    if self:IsOpen() then
        self:SetState(DoorEvents.STATE.CLOSED)
    else
        self:SetState(DoorEvents.STATE.OPEN)
    end
end

-- Lock-aware helpers for interaction modes: they refuse to open a locked
-- door and return true only if the door actually moved.
function BaseDoor:TryOpen(character)
    if self.locked or self:IsOpen() then return false end
    if character and character:IsA(Character) then
        character:PlayAnimation("nanos-world::AM_Mannequin_DoorOpen_01", AnimationSlotType.UpperBody)
    end
    self:SetState(DoorEvents.STATE.OPEN)
    return true
end

function BaseDoor:TryClose()
    if not self:IsOpen() then return false end
    self:SetState(DoorEvents.STATE.CLOSED)
    return true
end

function BaseDoor:TryToggle(character)
    if self:IsOpen() then return self:TryClose() end
    return self:TryOpen(character)
end

-- Interact-key entry point (called by Server/DoorInteraction.lua once the
-- request is range-checked). Forwards to the mode's OnInteract, only if the
-- mode uses the interact key. Returns true if the mode did something.
function BaseDoor:Interact(character)
    local mode = BaseDoor.GetInteractionModeDefinition(self.interaction_mode)
    if not mode or not mode.uses_interact_key or not mode.OnInteract then return false end
    return mode.OnInteract(self, character) == true
end

function BaseDoor:SetState(new_state)
    if self.state == new_state then return end
    self.state = new_state

    if new_state == DoorEvents.STATE.OPEN then
        self:Open()
    else
        self:Close()
    end

    Events.BroadcastRemote(DoorEvents.STATE_CHANGED, Reliability.Reliable, new_state)
end

function BaseDoor:Open()
    error("BaseDoor:Open() must be overridden by a door subclass")
end

function BaseDoor:Close()
    error("BaseDoor:Close() must be overridden by a door subclass")
end

-- Locking makes TryOpen() refuse (so the built-in modes can't open the door);
-- it does not affect SetState()/Toggle() called directly (eg. from other
-- package code or a custom mode that bypasses locks on purpose).
function BaseDoor:Lock()
    if self.locked then return end
    self.locked = true
    self:SetState(DoorEvents.STATE.CLOSED)
    Events.BroadcastRemote(DoorEvents.LOCK_CHANGED, Reliability.Reliable, true)
end

function BaseDoor:Unlock()
    if not self.locked then return end
    self.locked = false
    Events.BroadcastRemote(DoorEvents.LOCK_CHANGED, Reliability.Reliable, false)
end

function BaseDoor:IsLocked()
    return self.locked
end

-- Returns the StaticMesh entity that represents the visible door panel.
-- Defaults to self (true for SlidingDoor, whose entity IS the panel);
-- HingeDoor overrides this to point at its attached child mesh instead.
function BaseDoor:GetVisualMesh()
    return self
end

function BaseDoor:SetDoorAsset(asset)
    self:GetVisualMesh():SetMesh(asset)
end

function BaseDoor:SetDoorScale(scale)
    self:GetVisualMesh():SetScale(scale)
end

function BaseDoor:SetDoorMaterial(material_path, index)
    self:GetVisualMesh():SetMaterial(material_path, index)
end
