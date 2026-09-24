Package.Require("BaseDoor.lua")

-- Classic hinged door: the entity itself is the hinge, and the visible door
-- panel is a child mesh attached offset from the hinge pivot, so rotating
-- self swings the whole door.
HingeDoor = BaseDoor.Inherit("HingeDoor")

-- Fallback size for the door panel mesh, used when door_scale isn't passed.
HingeDoor.DEFAULT_SCALE = Vector(1, 2, 1)

function HingeDoor:Constructor(location, rotation, door_asset, door_scale)
    self.Super:Constructor(location, rotation, "nanos-world::SM_None")

    self.mesh = StaticMesh(Vector(), Rotator(), door_asset or BaseDoor.DEFAULT_MESH_ASSET)
    self.mesh:SetScale(door_scale or HingeDoor.DEFAULT_SCALE)
    self.mesh:AttachTo(self)
    self.mesh:SetRelativeLocation(Vector(50, 0, 0))
end

function HingeDoor:GetVisualMesh()
    return self.mesh
end

function HingeDoor:Open()
    self:RotateTo(Rotator(0, -90, 90), 1)
end

function HingeDoor:Close()
    self:RotateTo(Rotator(0, 0, 90), 1)
end
