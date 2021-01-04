# Loader

Loader is, at it's finest, a Roblox Luau library loader with some sweet built-in libraries. Loader aims to replace the require function within your game. By doing so, this allows you to lazy load modules, which means you can require modules by name like `require('Module')` & deep search your DataModel for that script.

```lua
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
```

## Reasoning

You're probably thinking, "ANOTHER library loader?" and to that I say, yes. Loader is an extremely well-packed Library Loader to require modules. The perks of using Loader are as follows; lazy-load modules, quick load cached modules, and have global enums along with built in libraries.

Lazy-loading modules is using the name of the module to deep search the game to require. This can make workflows cleaner by applying a simple require for the name. Loader will also quick-load modules that have already been required (cached) which makes the deep search extremely inexpensive after the initial search. Built-into Loader is also an enum function to create global enums on the environment. Not to mention the extremely useful libraries included in Loader, which consistent of the following; DataSync, Interface, Manager, Network, and Roblox.

## Libraries

Loader is not just a library loader, but also a library provider. Built into Loader lays 5 libraries which take priority in string searching for a module. The libraries provided are all created Roblox-specific use for creating games. Each library comes with a vast amount of API which makes installing minor implementations of Roblox's API extremely easy and convenient.

Read more about what each library provides:

* [DataSync](datasync.md)
* [Interface](interface.md)
* [Manager](manager.md)
* [Network](network.md)
* [Roblox](roblox.md)

## Start

So you want to use Loader, congrats! You can get started on learning how to install, use, and what API is available with Loader by moving onto the next step, [Getting Started](start.md). Stick around if you're looking to use a lite variant of Loader and read up on it's use cases below.

# Lighter

Impacted by long timings? Loader is too big for a small use-case? Worried about performance? Look no further, there's a lite variant of Loader! Lighter is a light-weight version of Loader which *doesn't* include a game deep search or extra libraries. Lighter aims to solve the issue of Loader being too big for systems, plugins, and sometimes games! Lighter was originally created with the intention to use it for plugin development, but has become a cornerstone module in the development of Loader.

Lighter is extremely light-weight, and you can find the download for it [here](https://github.com/Mullets-Gavin/Loader/releases/tag/v1.0.0-lite).

## Installation

Installing Lighter is much different from installing Loader, but close enough. There's 2 preferred methods of installation, but if you wish to use Rojo, you totally can.

### Method 1

* [Download the release build](https://github.com/Mullets-Gavin/Loader/releases/tag/v1.0.0-lite) 
* Drop it into a Roblox place
* You're all set!

### Method 2

* Install [Deliver](https://github.com/Mullets-Gavin/Deliver)
* Run the following command:

```
--install https://github.com/Mullets-Gavin/Loader/tree/master/lite game.ReplicatedStorage
```

* You're all set!

## Documentation

Lighter is pretty similar to Loader in API, so you can read about it's documentation [here](loader.md). There is currently no included libraries, so you do *not* need to read up on the library API since it will not be included.

## Example

```lua
----------------
-- Initialize --
----------------

-- recommended
local require = require(Folder:WaitForChild("Lighter"))

-- optional
local Lighter = require(Folder:WaitForChild("Lighter"))

---------------------
-- Require Example --
---------------------

local SomeModule = require("SomeModule") -- Lighter("SomeModule")
local SomeModule = require.require("SomeModule") -- Lighter.require("SomeModule")

--------------------
-- Plugin Example --
--------------------

local plugin = script:FindFirstAncestorWhichIsA("Plugin")
local require = require(plugin:FindFirstChild("Lighter",true))
local SomeModule = require("SomeModule")
```

### Hierarchy
```
plugin
├─ Main
├─ Lighter
└─ Modules
   └─ SomeModule
```