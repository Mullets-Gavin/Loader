<div align="center">
<h1>Lighter</h1>

[![version](https://img.shields.io/badge/version-v1.0.0-red)](https://github.com/Mullets-Gavin/Loader/releases)

Lighter, a lite variant of Loader, a Roblox Luau Library Loader
</div>

## What's Different?
Lighter is a lite variant of Loader, which includes no libraries & you only deep search the parented container. This means you can now have a blazing fast lazy-loader for localized modules without having to worry about any dependencies or conflicting names. This is an excellent choice for plugin development, seen in an example below.

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