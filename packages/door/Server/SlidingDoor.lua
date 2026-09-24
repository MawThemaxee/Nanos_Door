Package.Require("BaseDoor.lua")
Package.Require("DoorMapLoader.lua")

-- Sliding door: the entity is the door panel itself; opening translates it
-- sideways by slide_offset (in the door's local space) instead of rotating it.
SlidingDoor = BaseDoor.Inherit("SlidingDoor")

-- Fallback size for the door panel mesh, used when door_scale isn't passed.
SlidingDoor.DEFAULT_SCALE = Vector(1, 2, 0.1)

function SlidingDoor:Constructor(location, rotation, slide_offset, door_asset, door_scale)
    BaseDoor.Constructor(self, location, rotation, door_asset or BaseDoor.DEFAULT_MESH_ASSET)
    self:SetScale(door_scale or SlidingDoor.DEFAULT_SCALE)

    self.closed_location = location
    -- slide_offset is local to the door (rotated by its placed rotation), so
    -- a door placed at any orientation in a map slides along its own axis.
    self.open_location = location + rotation:RotateVector(slide_offset or Vector(0, 100, 0))
end

function SlidingDoor:Open()
    self:TranslateTo(self.open_location, 1)
end

function SlidingDoor:Close()
    self:TranslateTo(self.closed_location, 1)
end

BaseDoor.RegisterMapType("Sliding", function(spec)
    return SlidingDoor(spec.location, spec.rotation, spec.slide_offset, spec.asset, spec.scale)
end)
