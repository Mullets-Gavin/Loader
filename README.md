<div align="center">
<h1>Loader</h1>

By [Mullet Mafia Dev](https://www.roblox.com/groups/5018486/Mullet-Mafia-Dev#!/about) | [Download](https://www.roblox.com/library/5653863543/Loader) | [Source](https://github.com/Mullets-Gavin/Loader)
</div>

Loader is a Roblox Luau lazy library loader. This module can act as a require replacement with complete capabilities. Loader features a set of tools with included libraries to help.

## API

---

**Loader.require**
```lua
Loader.require(module: string | number | Instance) -> RequiredModule?
```
Require a module instance or search containers for a module with a string

---

**Loader.server**
```lua
Loader.server(module: string | number | Instance) -> RequiredModule?
```
Require a module instance or search server containers for a module with a string

---

**Loader.client**
```lua
Loader.client(module: string | number | Instance) -> RequiredModule?
```
Require a module instance or search client containers for a module with a string

---

**Loader.import**
```lua
Loader.import(service: string) -> RobloxService?
```
Import a Roblox service

---

**Loader.enum**
```lua
Loader.enum(name: string, members: table) -> Enumerator
```
Create a custom enum library on `shared`

---

**Loader()**
```lua
Loader(module: string | number | Instance) -> RequiredModule?
```
Replace the require function by Roblox

---

**Loader[]**
```lua
Loader[service: string] -> RobloxService?
```
Quickly import services by indexing Loader

---