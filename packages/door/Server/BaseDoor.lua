local DoorEvents = Package.Require("DoorEvents.lua")

-- Shared skeleton for every door variant: owns the interaction trigger and
-- the open/closed state machine + network broadcast. Concrete door types
-- (HingeDoor, SlidingDoor, ...) only implement Open()/Close() below with
-- their own movement — nothing here needs to change to add a new door type.
BaseDoor = StaticMesh.Inherit("BaseDoor")

-- Fallback door mesh asset, used by subclasses when their caller doesn't
-- declare one via the door_asset constructor argument.
BaseDoor.DEFAULT_MESH_ASSET = "nanos-world::SM_Plane"

function BaseDoor:Constructor(location, rotation, mesh_asset, trigger_extent)
    self.Super:Constructor(location, rotation, mesh_asset)

    self.trigger = Trigger(location, Rotator(), trigger_extent or 150, TriggerType.Sphere, false, Color.RED, { "Character" })
    self.state = DoorEvents.STATE.CLOSED
    self.locked = false

    self.trigger:Subscribe("BeginOverlap", function(_, actor)
        if not actor:IsA(Character) then return end
        if self.locked then return end
        actor:PlayAnimation("nanos-world::AM_Mannequin_DoorOpen_01", AnimationSlotType.UpperBody)
        self:SetState(DoorEvents.STATE.OPEN)
    end)

    self.trigger:Subscribe("EndOverlap", function(_, actor)
        if not actor:IsA(Character) then return end
        self:SetState(DoorEvents.STATE.CLOSED)
    end)
end

function BaseDoor:SetState(new_state)
    if self.state == new_state then return end
    self.state = new_state

    if new_state == DoorEvents.STATE.OPEN then
        self:Open()
    else
        self:Close()
    end

    Events.BroadcastRemote(DoorEvents.STATE_CHANGED, true, new_state)
end

function BaseDoor:Open()
    error("BaseDoor:Open() must be overridden by a door subclass")
end

function BaseDoor:Close()
    error("BaseDoor:Close() must be overridden by a door subclass")
end

-- Locking prevents BeginOverlap from opening the door; it does not affect
-- Open()/Close() called directly (eg. from other package code).
function BaseDoor:Lock()
    if self.locked then return end
    self.locked = true
    self:SetState(DoorEvents.STATE.CLOSED)
    Events.BroadcastRemote(DoorEvents.LOCK_CHANGED, true, true)
end

function BaseDoor:Unlock()
    if not self.locked then return end
    self.locked = false
    Events.BroadcastRemote(DoorEvents.LOCK_CHANGED, true, false)
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
