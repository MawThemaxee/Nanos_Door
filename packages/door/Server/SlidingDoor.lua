Package.Require("BaseDoor.lua")

-- Sliding door: the entity is the door panel itself; opening translates it
-- sideways by slide_offset instead of rotating it.
SlidingDoor = BaseDoor.Inherit("SlidingDoor")

-- Fallback size for the door panel mesh, used when door_scale isn't passed.
SlidingDoor.DEFAULT_SCALE = Vector(1, 2, 0.1)

function SlidingDoor:Constructor(location, rotation, slide_offset, door_asset, door_scale)
    self.Super:Constructor(location, rotation, door_asset or BaseDoor.DEFAULT_MESH_ASSET)
    self:SetScale(door_scale or SlidingDoor.DEFAULT_SCALE)

    self.closed_location = location
    self.open_location = location + (slide_offset or Vector(0, 100, 0))
end

function SlidingDoor:Open()
    self:TranslateTo(self.open_location, 1)
end

function SlidingDoor:Close()
    self:TranslateTo(self.closed_location, 1)
end
