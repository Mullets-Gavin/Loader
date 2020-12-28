# Loader

Loader is, at it's finest, a Roblox Luau library loader with some sweet built-in libraries. Loader aims to replace the require function within your game. By doing so, this allows you to lazy load modules, which means you can require modules by name like `require('Module')` & deep search your DataModel for that script.

## Reasoning

You're probably thinking, "ANOTHER library loader?" and to that I say, yes. Loader is an extremely well-packed Library Loader to require modules. The perks of using Loader are as follows; lazy-load modules, quick load cached modules, and have global enums along with built in libraries.

Lazy-loading modules is using the name of the module to deep search the game to require. This can make workflows cleaner by applying a simple require for the name. Loader will also quick-load modules that have already been required (cached) which makes the deep search extremely inexpensive after the initial search. Built-into Loader is also an enum function to create global enums on the environment. Not to mention the extremely useful libraries included in Loader, which consistent of the following; DataSync, Interface, Manager, Network, and Roblox.

## Libraries

Loader is not just a library loader, but also a library provider. Built into Loader lays 5 libraries which take priority in string searching for a module. The libraries provided are all created Roblox-specific use for creating games. Each library comes with a vast amount of API which makes installing minor implementations of Roblox's API extremely easy and convenient.

### DataSync

DataSync is a streamlined DataStore wrapper which handles data replication for you. With no dependency on a player, this is the most versatile DataStore wrapper on Roblox with feature-rich API. Within the module, DataSync will handle all compression, replication, and saving/loading in a sleek and streamlined manner. DataSync is an extremely great choice for games that need a tough but customizable DataStore system. You can learn more about DataSync [here](datasync.md).

### Interface

Handling the clients interface, inputs, and device information. Interface is a large library with dozens of API to detect platforms, wrapper functions for any user-made input, and most importantly, handling Roblox user-interface. Interface includes a built-in version of [Modular Component System](https://github.com/Mullets-Gavin/Roblox/tree/master/Client/MCS), an interface component system designed to create components on run time out of tagged UI elements. Read up more on Interface [here](interface.md).

### Manager

The janitor of the school, Manager is a sleek and simple solution to handling events, cleaning up connections, and replacing legacy pure-Lua implementations, such as `spawn()`. Manager is the most accurate wrapper in timings, such as accurate `wait()` functions & controlled task schedulers. An extremely useful library full of useful API, you can find Manager [here](manager.md).

### Network

Wrapping your networking can be extremely beneficial. Network aims to provide a solution to debugging networking issues by providing tracebacks & error handling for you. Network will handle your RemoteEvents, RemoteFunctions, BindableEvents, and BindableFunctions. Using Network can also make it easier for teams to have a unified wrapper that forces a standard to utilize. Learn more about its uses [here](network.md).

### Roblox

A general, catch-all module for wrapping Roblox API in a clean manner. The Roblox library provides you the opportunity to simplify your calls to Roblox's unstable API, and provides an automatic retry system up to 5 runs to try and guarantee success. View what API is available already [here](roblox.md).