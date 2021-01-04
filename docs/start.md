# Getting Started

So you want to use Loader, but don't know where to begin. Or you do know where to begin, and that's why you're here. Whatever the case may be, I am delighted to inform you that it is extremely easy to install.

## Installation

You can install Loader with three methods, though it is recommended that if you want a stable release, install Loader via the `rbxm` model located in the releases. The quickest route is via Deliver, a command-line interface in Studio.

### Method 1, Deliver:

* Make sure you have [Deliver](https://github.com/Mullets-Gavin/Deliver) installed, a command-line interface for Roblox Studio.
* Open up Roblox Studio & enable the output and command line.
* Run the installation command:

```
--install Loader game.ReplicatedStorage
```

* You're all set!

### Method 2, Model:

* Download the `rbxm` model [here](https://github.com/Mullets-Gavin/Loader/releases)
* Drag and drop the file into a Roblox place
* Set Loader in `ReplicatedStorage`
* You're all set!

### Method 3, Filesystem:

* Download the `src` of this repository
* Use a File-syncing plugin like [Rojo](https://github.com/rojo-rbx/rojo) to sync to a Roblox place
* Set Loader in `ReplicatedStorage`
* You're all set!

## Hierarchy

Loader should be installed in the following hierarchy:

```
ReplicatedStorage
└─ Loader
   ├─ DataSync
   ├─ Interface
   ├─ Manager
   ├─ Network
   └─ Roblox
```

## Initialize

Initialize Loader by requiring the module located in ReplicatedStorage. Paste this to each new script you make to stay consistent:
```lua
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
```

It's recommended to set Loader as a `require` replacement since it works the same, with added perks of diagnosing problems.


## More

Learn more about Loader & it's API in the [Reference](reference.md) page.