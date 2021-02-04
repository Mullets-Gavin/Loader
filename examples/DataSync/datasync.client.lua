-- require loader
local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- grab DataSync and a store
local DataSync = require("DataSync") -- get DataSync
local Store = DataSync.GetStore("PlayerData") -- grab the store, this will connect your DataStore to the server
local File = Store:GetFile() -- no need to put a user ID if you're getting the local players data

print(File:GetData("Money")) -- print the initial cash amount they have

Store:Subscribe(Player.UserId, { "Money" }, function(data) -- print the money of your store live
	print(data.Stat .. ":", data.Value)
end)
