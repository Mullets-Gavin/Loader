# Loader

Loader, the easiest way to lazy load modules. A fantastic module, Loader provides a wide range of utilities such as global lazy-loading, a replacement of the Lua `require` function, and more. Loader has been thoroughly tested & used within large-scale projects to prove how powerful Loader can be.

# Notes

Loader caches all loaded modules. This optimization allows you to only run the deep search once while searching for the ModuleScript, allowing you to not worry about any expensive functions after the initial search.

# API

* ## **require**
```lua
Loader.require(string | number | ModuleScript): RequiredModule?
```

The main `require` replacement. `require` does a deep search with the following order of precedence for sorting:

**Shared:**
1. ReplicatedStorage
2. Chat
3. Geometry

**Server:**
1. ServerStorage
2. ServerScriptService

**Client:**
1. PlayerScripts
2. PlayerGui
3. Backpack
4. ReplicatedFirst

* ## **server**
```lua
Loader.server(string | number | ModuleScript): RequiredModule?
```

The `server` only-search if you want to keep the search inexpensive, great for large codebases and you know where the code resides. Uses the following precedence:

**Server:**
1. ServerStorage
2. ServerScriptService

* ## **client**
```lua
Loader.server(string | ModuleScript): RequiredModule?
```

The `client` only-search if you want to keep the search inexpensive, great for large codebases and you know where the code resides. Uses the following precedence:

**Client:**
1. PlayerScripts
2. PlayerGui
3. Backpack
4. ReplicatedFirst

* ## **__call**
```lua
require(string | number | ModuleScript): RequiredModule?
```

This callback returns what `require` returns, allowing you to replace the Lua `require` function with Loaders custom `require` which allows text and scripts to be loaded.

* ## **enum**
```lua
Loader.enum(string, table): table
```

Create a global enum on the `shared` global to use between your environment. This makes for a great alternative to custom enumerators since we cannot create enums in the `Enum` built-in library.