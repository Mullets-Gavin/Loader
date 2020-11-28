--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Internal subscription functions
]=]

local Subscribe = {}
Subscribe.Cache = {}
Subscribe.All = {}
Subscribe.Remotes = {
	['Download'] = '_DOWNLOAD';
	['Upload'] = '_UPLOAD';
	['Subscribe'] = '_SUBSCRIBE';
}

local Loader = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))

local Manager = Loader('Manager')
local Network = Loader('Network')

local Players = Loader['Players']
local RunService = Loader['RunService']

--[=[
	Get a player from an index
	
	@param index Instance | string | number -- index to search
	@return Player?
	@private
]=]
local function GetPlayer(index)
	local player; do
		local success,response = pcall(function()
			return Players:GetPlayerByUserId(index)
		end)
		
		if success then
			player = response
		end
	end
	
	if typeof(index) == 'Instance' and index:IsA('Player') then
		return player
	end
	
	return player
end

--[=[
	Get the subscription cache
	
	@param key any -- the key of the DataStore
	@param index any -- the index of the DataFile
	@param value any -- the value of a DataFile
	@return SubscriptionCache
	@private
]=]
local function GetCache(key,index,value)	
	if not Subscribe.Cache[key] then
		Subscribe.Cache[key] = {}
	end
	
	if not Subscribe.Cache[key][index] then
		Subscribe.Cache[key][index] = {}
	end
	
	if not Subscribe.Cache[key][index][value] then
		Subscribe.Cache[key][index][value] = {
			['Clients'] = {};
			['Code'] = {};
		}
	end
	
	return Subscribe.Cache[key][index][value]
end

--[=[
	Get all subscription cache
	
	@param key any -- the key of the DataStore
	@param index any -- the index of the DataFile
	@return SubscriptionCache
	@private
]=]
local function GetAll(key,index)
	if not Subscribe.All[key] then
		Subscribe.All[key] = {}
	end
	
	if not Subscribe.All[key][index] then
		Subscribe.All[key][index] = {
			['Clients'] = {};
			['Code'] = {};
		}
	end
	
	return Subscribe.All[key][index]
end

--[=[
	Fire a subscription
	
	@param key any -- DataStore key
	@param index any -- DataFile index
	@param value any -- DataFile value
	@param data any -- new data
	@private
]=]
function Subscribe.FireSubscription(key,index,value,data)
	assert(key ~= nil)
	assert(index ~= nil)
	assert(value ~= nil)
	assert(data ~= nil)
	index = tostring(index)
	
	local cache = GetCache(key,index,value)
	local all = GetAll(key,index)
	local player = GetPlayer(index)
	
	if Manager.IsServer then
		local sent = {}
		
		for count,client in pairs(cache['Clients']) do
			Manager.wrap(function()
				table.insert(sent,client)
				Network:FireClient(Subscribe.Remotes.Download,client,key,index,value,data)
			end)
		end
		
		for count,client in pairs(all['Clients']) do
			Manager.wrap(function()
				if not table.find(sent,client) then
					Network:FireClient(Subscribe.Remotes.Download,client,key,index,value,data)
				end
			end)
		end
	end
	
	local params = {
		['Stat'] = value;
		['Value'] = data;
		['Key'] = key;
		['Index'] = index;
		['Player'] = player;
	}
	
	local called = {}
	for hash,code in pairs(cache['Code']) do
		Manager.wrap(function()
			table.insert(called,code)
			code(params)
		end)
	end
	
	for hash,code in pairs(all['Code']) do
		Manager.wrap(function()
			if not table.find(called,code) then
				code(params)
			end
		end)
	end
end

--[[
	Connect a subscription
	
	@param info Instance | any -- player or index
	@param key any -- DataStore key
	@param index any -- DataFile index
	@param value any -- DataFile value
	@param code function -- the function to callback
	@private
--]]
function Subscribe.ConnectSubscription(info,key,index,value,code)
	assert(info ~= nil)
	assert(key ~= nil)
	assert(index ~= nil)
	assert(value ~= nil)
	
	index = tostring(index)
	
	local cache = GetCache(key,index,value)
	local all = string.lower(value) == 'all' and GetAll(key,index)
	
	if typeof(code) == 'function' then
		cache['Code'][info] = code
		if all then
			all['Code'][info] = code
		end
	end
	
	if typeof(info) == 'Instance' and info:IsA('Player') then
		if not table.find(cache['Clients'],info) then
			table.insert(cache['Clients'],info)
		end
		
		if all then
			if not table.find(all['Clients'],info) then
				table.insert(all['Clients'],info)
			end
		end
	end
	
	Subscribe.Cache[key][index][value] = cache
	
	if all then
		Subscribe.All[key][index] = all
	end
	
	if Manager.IsClient then
		Network:FireServer(Subscribe.Remotes.Subscribe,key,index,value)
	end
end

--[=[
	Disconnect a subscription
	
	@param info Instance | any -- player or index
	@param key any -- DataStore key
	@param index any -- DataFile index
	@param value any -- DataFile value
	@private
]=]
function Subscribe.DisconnectSubscription(info,key,index,value)
	assert(info ~= nil)
	assert(key ~= nil)
	assert(index ~= nil)
	value = value or 'all'
	
	local cache = GetCache(key,index,value)
	local all = string.lower(value) == 'all' and GetAll(key,index)
	
	if cache['Code'][info] ~= nil then
		cache['Code'][info] = nil
	end
	if all then
		if all['Code'][info] ~= nil then
			all['Code'][info] = nil
		end
	end
	
	if typeof(info) == 'Instance' and info:IsA('Player') then
		if table.find(cache['Clients'],info) then
			table.remove(cache['Clients'],table.find(cache['Clients'],info))
		end
		
		if all then
			if table.find(all['Clients'],info) then
				table.remove(all['Clients'],table.find(all['Clients'],info))
			end
		end
	end
	
	Subscribe.Cache[key][index][value] = nil
	
	if all then
		Subscribe.All[key][index] = all
	end
end

return Subscribe