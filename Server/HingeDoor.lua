Package.Require("BaseDoor.lua")
Package.Require("DoorMapLoader.lua")

-- Classic hinged door: the entity itself is the hinge, and the visible door
-- panel is a child mesh attached offset from the hinge pivot, so rotating
-- self swings the whole door.
HingeDoor = BaseDoor.Inherit("HingeDoor")

-- Fallback size for the door panel mesh, used when door_scale isn't passed.
HingeDoor.DEFAULT_SCALE = Vector(1, 2, 1)

-- Yaw added to the placed rotation when the door is open.
HingeDoor.OPEN_YAW = -90

function HingeDoor:Constructor(location, rotation, door_asset, door_scale)
    BaseDoor.Constructor(self, location, rotation, "nanos-world::SM_None")

    self.mesh = StaticMesh(Vector(), Rotator(), door_asset or BaseDoor.DEFAULT_MESH_ASSET)
    self.mesh:SetScale(door_scale or HingeDoor.DEFAULT_SCALE)
    self.mesh:AttachTo(self)
    self.mesh:SetRelativeLocation(Vector(50, 0, 0))

    -- Swing relative to the placed rotation (not an absolute rotator), so
    -- doors placed at any orientation in a map open correctly.
    self.closed_rotation = rotation
    self.open_rotation = Rotator(rotation.Pitch, rotation.Yaw + HingeDoor.OPEN_YAW, rotation.Roll)
end

function HingeDoor:GetVisualMesh()
    return self.mesh
end

function HingeDoor:Open()
    self:RotateTo(self.open_rotation, 1)
end

function HingeDoor:Close()
    self:RotateTo(self.closed_rotation, 1)
end

BaseDoor.RegisterMapType("Hinge", function(spec)
    return HingeDoor(spec.location, spec.rotation, spec.asset, spec.scale)
end)
