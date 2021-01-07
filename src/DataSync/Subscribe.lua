--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Internal subscription functions
]=]

local Subscribe = {}
Subscribe._Cache = {}
Subscribe._All = {}
Subscribe._Remotes = {
	["Download"] = "_DOWNLOAD",
	["Upload"] = "_UPLOAD",
	["Subscribe"] = "_SUBSCRIBE",
}

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local Manager = require("Manager")
local Network = require("Network")

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

--[=[
	Fire a subscription
	
	@param key any -- DataStore key
	@param index any -- DataFile index
	@param value any -- DataFile value
	@param data any -- new data
	@return nil
	@private
]=]
function Subscribe.FireSubscription(key: any, index: any, value: any, data: any): nil
	index = tostring(index)
	local store = Subscribe._Cache[key] or {}
	local caught = {}

	for guid, file in pairs(store) do
		if index ~= file.Index then
			continue
		end

		if not table.find(file.Values, value) and not table.find(file.Values, "all") then
			continue
		end

		local client = file.Client
		if Manager.IsServer and typeof(client) == "Instance" and client:IsA("Player") then
			local catch = caught[client]
			if not catch or catch and not table.find(catch, value) then
				catch = catch or {}
				table.insert(catch, value)
				caught[client] = catch

				Network:FireClient(Subscribe._Remotes.Download, client, key, index, value, data)
			end
		end

		if file.Code then
			Manager.Wrap(file.Code, {
				["Key"] = key,
				["Stat"] = value,
				["Value"] = data,
				["Index"] = index,
				["Client"] = file.Client,
			})
		end
	end
end

--[[
	Connect a subscription
	
	@param info Instance | any -- player or index
	@param key any -- DataStore key
	@param index any -- DataFile index
	@param value table -- DataFile value
	@param code function -- the function to callback
	@return nil
	@private
--]]
function Subscribe.ConnectSubscription(info: Instance | any, key: any, index: any, values: table, code: ((any) -> nil)?, uid: string?): nil
	local client
	if typeof(info) == "Instance" and info:IsA("Player") then
		client = info
		info = client.UserId
	end
	info = tostring(info)
	index = tostring(index)

	local store = Subscribe._Cache[key] or {}
	local guid = uid or HttpService:GenerateGUID(false)
	local cache = {
		["Code"] = code,
		["Index"] = index,
		["Client"] = client,
		["Values"] = values,
	}

	store[guid] = cache
	Subscribe._Cache[key] = store

	if Manager.IsClient then
		Network:FireServer(Subscribe._Remotes.Subscribe, key, index, values, guid)
	end

	return guid
end

--[=[
	Disconnect a subscription
	
	@param info Instance | any -- player or index
	@param key any -- DataStore key
	@param index any -- DataFile index
	@param value any -- DataFile value
	@return nil
	@private
]=]
function Subscribe.DisconnectSubscription(key: string, guid: string): nil
	local store = Subscribe._Cache[key]

	if store[guid] then
		store[guid] = nil
		Subscribe._Cache[key] = store
	end
end

return Subscribe
