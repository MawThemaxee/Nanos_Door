# Nanos Door

A Nanos World package for creating and controlling doors — hinged or sliding, with configurable
mesh/size/material, an interaction trigger, and a lock system — from Lua.

- [Installation](#installation)
- [Quick start](#quick-start)
- [Door types](#door-types)
- [Runtime control](#runtime-control)
- [Events](#events)
- [Using Nanos Door from your own package](#using-nanos-door-from-your-own-package)
- [Adding a new door type](#adding-a-new-door-type)
- [Troubleshooting](#troubleshooting)

## Installation

1. Place (or symlink) the `door` package folder into your server's `Packages/` directory.
2. Enable it in your server's `Config.toml`:

   ```toml
   [game]
       packages = [
                                "door",
       ]
   ```
3. Start the server. A successful load logs:

   ```text
   INFO  Loading Package 'door' (0.1.0)...
   INFO  Package 'door' (0.1.0) loaded.
   ```

## Quick start

Spawn a door from any **Server** Lua script (your own package's `Server/Index.lua`, a game mode,
etc.) — no `require`/import needed:

```lua
-- A classic hinged door
local door = HingeDoor(Vector(0, 0, 100), Rotator(0, 0, 90))

-- A sliding door
local gate = SlidingDoor(Vector(500, 0, 100), Rotator())
```

Walk into either one — the trigger opens it automatically, and it closes again once you walk away.

## Door types

Both door types share the same base behavior (trigger, open/close state, locking, events) and
differ only in how they move. All arguments after `rotation` are optional; pass `nil` to skip one
and still set a later one.

### `HingeDoor(location, rotation, door_asset?, door_scale?)`

A door that swings open around a hinge, like the [official doors tutorial](https://docs.nanos-world.com/docs/getting-started/tutorials-and-examples/doors).

| Argument | Type | Default |
|---|---|---|
| `location` | Vector | — |
| `rotation` | Rotator | — |
| `door_asset` | string (mesh asset) | `BaseDoor.DEFAULT_MESH_ASSET` (`"nanos-world::SM_Plane"`) |
| `door_scale` | Vector | `HingeDoor.DEFAULT_SCALE` (`Vector(1, 2, 1)`) |

```lua
HingeDoor(Vector(0, 0, 100), Rotator(0, 0, 90), "nanos-world::SM_Cube", Vector(2, 3, 1.5))
```

### `SlidingDoor(location, rotation, slide_offset?, door_asset?, door_scale?)`

A door that translates sideways to open instead of rotating.

| Argument | Type | Default |
|---|---|---|
| `location` | Vector | — |
| `rotation` | Rotator | — |
| `slide_offset` | Vector, added to `location` for the open position | `Vector(0, 100, 0)` |
| `door_asset` | string (mesh asset) | `BaseDoor.DEFAULT_MESH_ASSET` |
| `door_scale` | Vector | `SlidingDoor.DEFAULT_SCALE` (`Vector(1, 2, 0.1)`) |

```lua
SlidingDoor(Vector(500, 0, 100), Rotator(), Vector(0, 150, 0))
```

## Runtime control

Every door instance (both types), from server-side code:

```lua
door:SetDoorAsset("nanos-world::SM_Cube")      -- swap the mesh/model
door:SetDoorScale(Vector(2, 3, 1.5))           -- resize it
door:SetDoorMaterial("nanos-world::M_Metal")   -- swap the material/texture

door:Lock()      -- force-closes the door and blocks trigger-driven opening
door:Unlock()
door:IsLocked()  --> boolean
```

`Lock()`/`Unlock()` only stop the interaction trigger from auto-opening the door — you can still
call `door:Open()` / `door:Close()` directly from your own code regardless of lock state.

## Events

`DoorEvents` (from `Shared/DoorEvents.lua`) is available as a global once the package has loaded:

```lua
DoorEvents.STATE.OPEN     -- "open"
DoorEvents.STATE.CLOSED   -- "closed"
DoorEvents.STATE_CHANGED  -- "Door.StateChanged"
DoorEvents.LOCK_CHANGED   -- "Door.LockChanged"
```

Subscribe on either side to react to any door's state (useful for sound/UI on the client):

```lua
Events.SubscribeRemote(DoorEvents.STATE_CHANGED, function(state)
    -- state is DoorEvents.STATE.OPEN or DoorEvents.STATE.CLOSED
end)

Events.SubscribeRemote(DoorEvents.LOCK_CHANGED, function(is_locked)
    -- is_locked is true/false
end)
```

These broadcasts aren't scoped to a single door — if you need to know *which* door changed, track
it on your own side (eg. keep a reference to the door instance you spawned).

## Using Nanos Door from your own package

You don't need to touch the `door` package to place doors for your map — put that configuration in
your own package instead. `HingeDoor`, `SlidingDoor` and `DoorEvents` are usable from any other
package's Server scripts as soon as `door` has loaded — no import call needed.

Add `door` as a dependency in your own package's `Package.toml`, so it's guaranteed to load first:

```toml
[script]
    packages_requirements = [
                             "door",
    ]
```

Then just call the door constructors from your own `Server/Index.lua` (or any Server script):

```lua
local DOORS = {
    { type = "hinge",   location = Vector(0, 0, 100),    rotation = Rotator(0, 0, 90) },
    { type = "sliding", location = Vector(500, 0, 100),  rotation = Rotator(), slide_offset = Vector(0, 150, 0) },
}

for _, door_config in pairs(DOORS) do
    if door_config.type == "hinge" then
        HingeDoor(door_config.location, door_config.rotation, door_config.door_asset, door_config.door_scale)
    elseif door_config.type == "sliding" then
        SlidingDoor(door_config.location, door_config.rotation, door_config.slide_offset, door_config.door_asset, door_config.door_scale)
    end
end
```

This keeps your map's door *placement* separate from the door package's behavior.

## Adding a new door type

New door types extend `BaseDoor` and only implement movement — the trigger, state machine, locking
and events are inherited for free:

```lua
Package.Require("BaseDoor.lua")

MyDoor = BaseDoor.Inherit("MyDoor")
MyDoor.DEFAULT_SCALE = Vector(1, 2, 1)

function MyDoor:Constructor(location, rotation, door_asset, door_scale)
    self.Super:Constructor(location, rotation, door_asset or BaseDoor.DEFAULT_MESH_ASSET)
    self:SetScale(door_scale or MyDoor.DEFAULT_SCALE)
end

function MyDoor:Open()
    -- move/animate to the open state
end

function MyDoor:Close()
    -- move/animate to the closed state
end
```

If the entity itself isn't the visible panel (like `HingeDoor`'s hinge), also override
`GetVisualMesh()` to return whichever child mesh is visible, so `SetDoorAsset`/`SetDoorScale`/
`SetDoorMaterial` keep working.

## Troubleshooting

- **The trigger doesn't detect the player at all.** Game modes commonly spawn players as subclasses
  of `Character`, not `Character` itself. Any custom trigger logic must use `actor:IsA(Character)`,
  never `actor:GetClass() ~= Character` (an exact-equality check silently excludes every subclass).
  `BaseDoor` already does this correctly.
- **Server logs a `Trigger` overlap performance warning.** Every `Trigger` needs
  `overlap_only_classes` set (7th constructor argument) — `BaseDoor` already passes
  `{ "Character" }`; only relevant if you're adding your own trigger elsewhere.
- **Package fails to load with `Could not determine the type of the Package!`.** `Package.toml`'s
  `[meta]` table never has a `type` field — the package's type is determined by which type-specific
  table (`[script]`, `[game_mode]`, `[map]`, ...) is present instead.
- **Calling `HingeDoor(...)`/`SlidingDoor(...)` from another package errors as a `nil` global, or
  `DoorEvents` is `nil`.** Your package almost certainly loaded before `door` did — add
  `packages_requirements = ["door"]` to your own `Package.toml`'s `[script]` table.
