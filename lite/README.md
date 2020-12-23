<div align="center">
<h1>Lighter</h1>

[![version](https://img.shields.io/badge/version-v1.0.0-red)](https://github.com/Mullets-Gavin/Loader/releases/tag/v1.0.0-lite)

Lighter, a lite variant of Loader, a Roblox Luau Library Loader
</div>

## What's Different?
Lighter is a lite variant of Loader, which includes no libraries & you only deep search the parented container. This means you can now have a blazing fast lazy-loader for localized modules without having to worry about any dependencies or conflicting names. This is an excellent choice for plugin development, seen in an example below.

[(What's Loader?)](https://github.com/Mullets-Gavin/Loader#whats-loader)

## Usage
For installation help, refer to the instructions [here.](https://github.com/Mullets-Gavin/Loader#installation) You can find the files to download [here.](https://github.com/Mullets-Gavin/Loader/releases/tag/v1.0.0-lite)

1. Set Lighter in the container you want to lazy load modules.
2. Require Lighter, like the example below.
3. You're all set! Start lazy loading modules that are parented (descendants) to this container (Lighters parent!)

## Hierarchy
```
ReplicatedStorage
└─ Folder
   ├─ Lighter
   └─ Modules
```

## Example
```lua
----------------
-- Initialize --
----------------

-- recommended
local require = require(Folder:WaitForChild('Lighter'))

-- optional
local Lighter = require(Folder:WaitForChild('Lighter'))

---------------------
-- Require Example --
---------------------

local SomeModule = require('SomeModule') -- Lighter('SomeModule')
local SomeModule = require.require('SomeModule') -- Lighter.require('SomeModule')

--------------------
-- Plugin Example --
--------------------

local plugin = script:FindFirstAncestorWhichIsA('Plugin')
local require = require(plugin:FindFirstChild('Lighter',true))
local SomeModule = require('SomeModule')

-- Hierarchy
plugin
├─ Lighter
└─ Modules
   └─ SomeModule
```