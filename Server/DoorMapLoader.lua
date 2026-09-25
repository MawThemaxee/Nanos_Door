local DoorEvents = Package.Require("DoorEvents.lua")
Package.Require("BaseDoor.lua")

-- Spawns doors from plain data specs — the format written by the Unreal
-- exporter (Nanos_Door_UE repo, Content/Python/export_doors.py) into a map
-- package's generated MapDoors.lua. Each door type registers how to build
-- itself from a spec, so adding a type never touches this file.
--
-- Spec fields: type (string, a registered type name), location (Vector),
-- rotation (Rotator), asset? (string), scale? (Vector), mode? (any
-- registered interaction mode name, default "trigger"), trigger_extent?
-- (number, trigger sphere radius), locked? (boolean), plus type-specific
-- fields (eg. slide_offset for "Sliding").
local builders = {}

function BaseDoor.RegisterMapType(type_name, builder)
    builders[type_name] = builder
end

function BaseDoor.SpawnFromList(specs)
    local doors = {}
    for index, spec in ipairs(specs or {}) do
        local builder = builders[spec.type]
        if not builder then
            Console.Warn("[door] map door #%d: unknown type '%s', skipped", index, tostring(spec.type))
        else
            local door = builder(spec)
            local mode = spec.mode or DoorEvents.INTERACTION_MODE.TRIGGER
            if not BaseDoor.GetInteractionModeDefinition(mode) then
                -- The package registering it must load before this one
                -- (list it in packages_requirements).
                Console.Warn("[door] map door #%d: unknown interaction mode '%s', using trigger", index, tostring(mode))
                mode = DoorEvents.INTERACTION_MODE.TRIGGER
            end
            door:SetInteractionMode(mode)
            if spec.trigger_extent then door:SetTriggerExtent(spec.trigger_extent) end
            if spec.locked then door:Lock() end
            table.insert(doors, door)
        end
    end
    return doors
end
