<div align="center">
<h1>Loader</h1>

[![version](https://img.shields.io/badge/version-v1.1.1-red)](https://github.com/Mullets-Gavin/Loader/releases/tag/v1.1.1) [![tests: passing](https://img.shields.io/badge/tests-passing-brightgreen)](https://github.com/Mullets-Gavin/Loader/tree/master/tests) [![chat](https://img.shields.io/discord/281959162470989834?color=blue)](https://discord.gg/dZYyvBu) [![examples](https://img.shields.io/badge/examples-1-blueviolet)](https://github.com/Mullets-Gavin/Loader/tree/master/examples)

A Roblox Luau lazy-library loader with built-in libraries and functions.
</div>

## Installation
You can install Loader with two methods, though it is recommended that you install Loader via the `rbxm` model located in the releases.

### Method 1, Model:
* Download the `rbxm` model [here](https://github.com/Mullets-Gavin/Loader/releases/tag/v1.0.0)
* Drag and drop the file into a Roblox place
* Set Loader in `ReplicatedStorage`
* You're all set!

### Method 2, Filesystem:
* Download the `src` of this repository
* Use a File-syncing plugin like [Rojo](https://github.com/rojo-rbx/rojo) to sync to a Roblox place
* Set Loader in `ReplicatedStorage`
* You're all set!

## Hierarchy
```
ReplicatedStorage
└─ Loader
   ├─ DataSync
   ├─ Interface
   ├─ Manager
   ├─ Network
   └─ Roblox
```

## Example
```lua
----------------
-- Initialize --
----------------

-- recommended
local Loader = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))

-- optional
local require = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))

------------------
-- Load Example --
------------------
local DataSync = Loader('DataSync')
local Roblox = Loader.require('Roblox')
local SomeClient = Loader.client('SomeClient')
local SomeServer = Loader.server('SomeServer')

----------------------
-- Services Example --
----------------------
local RunService = Loader['RunService']
local PlayerService = Loader.import('Players')

------------------------
-- Enumerator Example --
------------------------
local Enums = Loader.enum('Example',{'this','is','a','test'})
print(shared.Example.this) --> this
print(shared.Example.is == shared.Example.a) --> false
print(shared.Example.test == shared.Example.test) --> true
```

## API
Temporary API docs until proper documentation is released.

### Loader.require
```lua
Loader.require(module: string | number | Instance) -> RequiredModule?
```
Require a module instance or search containers for a module with a string

### Loader.server
```lua
Loader.server(module: string | number | Instance) -> RequiredModule?
```
Require a module instance or search server containers for a module with a string

### Loader.client
```lua
Loader.client(module: string | number | Instance) -> RequiredModule?
```
Require a module instance or search client containers for a module with a string

### Loader.import
```lua
Loader.import(service: string) -> RobloxService?
```
Import a Roblox service

### Loader.enum
```lua
Loader.enum(name: string, members: table) -> Enumerator
```
Create a custom enum library on `shared`

### Loader()
```lua
Loader(module: string | number | Instance) -> RequiredModule?
```
Replace the require function by Roblox

### Loader[]
```lua
Loader[service: string] -> RobloxService?
```
Quickly import services by indexing Loader