# Change Log

All notable changes to "Loader" will be documented in this file.

Check [Keep a Changelog](http://keepachangelog.com/) for recommendations on how to structure this file.

## Unreleased

- Official Roblox TS typings support

## v1.3.0

A significantly large change that passes all of selene's lints! This change contains a large change in the API as well as new API and the removal of it as well.

⚠ USING THIS VERSION OF LOADER MAY ERASE ANY CURRENT DATA AS THE INDEX HAS CHANGED. USE PRIOR VERSIONS IF YOU DEPEND ON THE INDEX. ⚠

**Changes:**
- Component system in Interface. I've decided against combining MCS into Interface in favor of declarative UI with Roact, which has official support and backing by Roblox.
- "FPS" parameter in `Manager.Loop`
- New API for the `Interface.Keybind` object! The following API was updated:
	- `Keybind:Mobile` - this can now take `false` as a second parameter to disable a displayed icon in favor of text
	- `Keybind:Bind` - this is a superior method to `Keybind:Hook`, which fires at Began/Changed/Ended and provides the UserInputState as its first parameter in the function, and the object follows as second.
	- `Keybind:Disconnect` - this now disconnects both `:Bind` and `:Hook` functions from the Keybind, allowing you to still access the button without a function
	- `Keybind:Destroy` - now COMPLETELY destroys the button, this frees up the unique identifier you used prior.
- Manager API has been updated to remove all `:Method`-like calls on Manager itself in favor of callback functions (`.Function()`). This change will completely change the functionality of Manager API such as:
	- `Manager:Connect` -> `Manager.Connect`
	- `Manager:Disconnect` -> `Manager.Disconnect`
	- `Manager:ConnectKey` -> `Manager.ConnectKey`
	- `Manager:DisconnectKey` -> `Manager.DisconnectKey`
	- `Manager:FireKey` -> `Manager.FireKey`
	- `Manager:Task` -> `Manager.Task`

## v1.2.3

Numerous bug fixes

**Changes:**
- Removed race conditions in DataSync
- `DataSync:GetFile` handles errors with ease

## v1.2.2

Removal of the compression algorithm from Manager and DataSync.

⚠ USING THIS VERSION OF LOADER MAY ERASE ANY CURRENT DATA AS THE COMPRESSION ALGORITHM NO LONGER EXISTS. USE PRIOR VERSIONS IF YOU DEPEND ON THE COMPRESSION ALGORITHM. ⚠

**Changes:**
- Compression algorithm removed
- DataSync updated to support backwards compatibility
- JSON Encode/Decode DataSync to minimize the saved data & allow to error if saving un-saveable data (userdatas)

## v1.2.1

With this update comes numerous bug fixes including DataSync not syncing data by default. This resolves all issues w/Manager as well.

**Changes:**
- DataSync auto-subscribes data to download
- DataSync is now *lighter* on the networking
- Manager bugs resolved

## v1.2.0

**Optimization update v1.2.0! 🥳**

With this update comes a large number of changes (even to the API) and you may have to reformat your games API if you used any version beneath this one.

**Awesome Changes:**
- Subscriptions on DataSync stores are unique & objects so they can be independently called
- Subscriptions are now *faster* in providing updates to any function
- Manager API is now 100% PascalCase, this was to make the Loader API consistent
- Network API now uses periods (`.`) instead of colons (`:`), to maintain consistency with the codebase
- Formatting! Loader & modules are now formatted with StyLua
- Minor optimizations - there were a flurry of changes made, but all in good taste!
- Bug fixes - resolved bugs reported

**Edits:**
- Resolved infinite yield issues
- Micro-optimized the subscriptions.. again
- New DataSync methods `:Ready()` and `:Loaded()`, ready provides the DataFIle being able to be used, and Loaded provides if the data loaded OR if it didn't and its using default, unsaveable data.

## v1.1.3

Fixed replicating DataSync data & removed some useless prints I left in from debugging.

**Changes:**
- Minor code cleanup
- Reliable DataSync changes
- Fixed player data replication
- Fixed yielding issue that occurred under certain scenarios

## v1.1.2

Pretty significant move, but I've decided to drop import + Option from Loader & follow the conventional require route. This update no longer allows you to indice Loader for a service, or use Loader.import.

**New changes:**
- Recommended to set Loader as require
	- ie. `local require = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))`
- DataSync got a ton of minor bugs fixed + smoother DataStore usage. Tests passed!
- Cleaned up Manager & Roblox a bit, and added _Name properties
- Network got some fresh changes, now "super-compatible" with making Real Games.
- There's a bunch more minor changes, but this was a general move so it doesn't qualify as a minor update but rather a patch.

## v1.1.1

A quick patch to update DataSync to include a new DataSync store method! You can now filter a set of keys from filtering, but they can still sync, useful for live inventories etc.

`store:FilterKeys({'list','of','keys'}, boolean: true to whitelist, false to blacklist)`

**Updates include:**
- Manager functions got fixed
- Smarter DataSync, can now handle requests better
- Networking changes, just minor improvements

## v1.1.0

A minor update with some new features & now with typed luau annotations!

**Updates include:**
- Loader & libraries are now in typed luau - the use of --!strict is not recommended since it's unstable release
- Manager now has a couple more functions - one includes Manager.debounce() which makes debouncing easy
- Big Interface refactor - Refactored functions to be more reliable
- New Modular Component System built into Interface - create component based UI without Roact.

## v1.0.0

- Loader initial release!
- Loader v1.0.0 includes 5 built-in libraries, such as Manager, DataSync, Interface, Network, Roblox.