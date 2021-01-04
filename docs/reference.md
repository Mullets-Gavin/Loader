# Reference

Examples and instructions on initializing Loader & its counterpart libraries. For specific API documentation, check out the specific pages:

* [Loader](loader.md)
* [DataSync](datasync.md)
* [Interface](interface.md)
* [Manager](manager.md)
* [Network](network.md)
* [Roblox](roblox.md)

## Loader

```lua
----------------
-- Initialize --
----------------

-- recommended
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))

-- optional
local Loader = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))

---------------------
-- Require Example --
---------------------

local SomeModule = require("SomeModule") -- Loader("SomeModule")
local SomeModule = require.require("SomeModule") -- Loader.require("SomeModule")
local SomeClient = require.client("SomeClient") -- Loader.client("SomeClient")
local SomeServer = require.server("SomeServer") -- Loader.server("SomeServer")

------------------------
-- Enumerator Example --
------------------------

local Enums = Loader.enum("Example",{"this","is","a","test"})
print(shared.Example.this) --> this
print(shared.Example.is == shared.Example.a) --> false
print(shared.Example.test == shared.Example.test) --> true
```

## DataSync

```lua
----------------
-- Initialize --
----------------

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local DataSync = require("DataSync")

-------------------
-- Store Example --
-------------------

local Store = DataSync.GetStore("DataStoreKey",{
    ["Cash"] = 0;
    ["Banned"] = false;
    ["Inventory"] = {
        ["Apple"] = 3;
    }
})

Store:FilterKeys("Banned")

------------------
-- File Example --
------------------

local File = Store:GetFile(player.UserId)
print(File:GetData("Cash"))

--------------------------
-- Subscription Example --
--------------------------

local Subscription;
Subscription = Store:Subscribe(player.UserId,"all",function(new,old)
    print(new.Stat,"updated:",new.Value)
    print("Previously",old.Value)

    if new.Value >= 10 then
        Subscription:Disconnect()
    end
end)
```