--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: DataSync, a custom DataStoreService wrapper by Mullet Mafia Dev
]=]

--[=[
[DOCUMENTATION]:
	store = DataSync.GetStore(key,default)
	
	subscription = store:Subscribe(index,value,function)
	subscription:Unsubscribe()
	
	file = store:GetFile(index)
	file:GetData(value)
	file:UpdateData(value,data)
	file:IncrementData(value,number)
	file:SaveData()
	file:RemoveData()
	file:WipeData()
	file:Loaded()
	file:Ready()
	
	subscriptionParameters = {
		Stat = 'string';
		Value = <any>;
		Key = 'store_key';
		Index = 'store_index';
		Player = player or nil;
	}
	
	Internal DataStore values:
	__CanSave - determines whether or not the DataFile can be saved
	__IsReady - this is false until the DataFile is ready for use
	__HasChanged - this will fire to true whenever data has changed, this will tell the DataStore whether to save or not
	
[OUTLINE]:
	DataSync
	└─ .GetStore(key[,data])
	   ├─ :GetFile(index)
	   │  ├─ :Ready()
	   │  ├─ :Loaded()
	   │  ├─ :GetData([value])
	   │  ├─ :UpdateData(value,data)
	   │  ├─ :IncrementData(value,num)
	   │  ├─ :SaveData()
	   │  ├─ :WipeData()
	   │  └─ :RemoveData()
	   └─ :Subscribe(index,value,function)
	      └─ :Unsubscribe()

[LICENSE]:
	MIT License
	
	Copyright (c) 2020 Mullet Mafia Dev
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]=]

local DataSync = {}
DataSync.__index = DataSync
DataSync._Name = string.upper(script.Name)
DataSync._ShuttingDown = false
DataSync._Private = "__"
DataSync._Cache = {}
DataSync._Stores = {}
DataSync._Files = {}
DataSync._Filters = {}
DataSync._Defaults = {}
DataSync._Network = {}
DataSync._Sessions = {}
DataSync._Subscriptions = {}
DataSync._Remotes = {
	["Download"] = "_DOWNLOAD",
	["Upload"] = "_UPLOAD",
	["Subscribe"] = "_SUBSCRIBE",
	["Unsubscribe"] = "_UNSUBSCRIBE",
}

DataSync.Sync = true -- allow data to sync - highly recommended to leave this to true
DataSync.Shutdown = true -- support BindToClose & autosave all DataFiles
DataSync.AutoSave = true -- can DataFiles autosave
DataSync.AutoSaveTimer = 30 -- how often, in seconds, a DataFile autosaves
DataSync.FailProof = false -- kick the player if the datastore failed loading player-based data
DataSync.All = "all" -- the 'all' variable for streamlining data types

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local Manager = require("Manager")
local Network = require("Network")
local Methods = require(script:WaitForChild("Methods"))
local Subscribe = require(script:WaitForChild("Subscribe"))
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--[=[
	Get the Player from either the instance or UserId
	
	@param index string | number | Instance -- find the player from the index
	@return Index & Player?
]=]
local function GetPlayer(index: string | number | Instance): ((number | string) & (Player?))
	local player
	do
		local success, response = pcall(function()
			return Players:GetPlayerByUserId(index)
		end)

		if success then
			player = response
		end
	end

	if typeof(index) == "Instance" and index:IsA("Player") then
		player = index
		index = tostring(player.UserId)
	elseif tostring(index) then
		index = tostring(index)
	end

	return index, player
end

--[=[
	Get a DataStore object on a key
	
	@param key string -- the DataStore key required
	@param data? table -- if you set a default table to load player data
	@return DataStoreObject
	@outline GetStore
]=]
function DataSync.GetStore(key: string, data: table?): typeof(DataSync.GetStore())
	if DataSync._Stores[key] and not data then
		return DataSync._Stores[key]
	end

	if not DataSync._Cache[key] then
		DataSync._Cache[key] = {}
	end

	if not DataSync._Defaults[key] and typeof(data) == "table" then
		DataSync._Defaults[key] = data
	end

	local store = {
		_key = key,
	}

	setmetatable(store, DataSync)

	DataSync._Stores[key] = store
	return store
end

--[=[
	A blacklist/whitelist filter for saving keys on a datastore

	@param keys table -- the keys to filter
	@param filter? boolean -- if true, only save these keys, if false, don't save those keys
	@outline FilterKeys
]=]
function DataSync:FilterKeys(keys: table, filter: boolean?): typeof(DataSync.GetStore())
	assert(self._key, "':FilterKeys' can only be used with a store")

	if not DataSync._Defaults[self._key] then
		warn("Unable to set filter, no Default Data table found")
		return self
	end

	DataSync._Filters[self._key] = {
		["Keys"] = keys,
		["Type"] = filter and "Whitelist" or "Blacklist",
	}

	return self
end

--[=[
	Get a DataFile Object with an index on a store
	
	@param index string | number | nil & client -- the index on the DataStore
	@return DataFileObject
	@outline GetFile
]=]
function DataSync:GetFile(index: string | number | nil): typeof(DataSync:GetFile())
	assert(self._key, "':GetFile' can only be used with a store")

	if not index and Manager.IsClient and Players.LocalPlayer then
		index = tostring(Players.LocalPlayer.UserId)
	else
		index = tostring(index)
	end

	if DataSync._Sessions[index] then
		while not DataSync._Files[index] do
			Manager.Wait()
		end

		return DataSync._Files[index]
	end

	if DataSync._Files[index] then
		return DataSync._Files[index]
	end

	DataSync._Sessions[index] = true

	local player
	index, player = GetPlayer(index)

	if not DataSync._Cache[self._key][index] and Manager.IsServer and not self._sesh then
		self._sesh = true

		if not DataSync._Defaults[self._key] then
			while not DataSync._Files[index] do
				Manager.Wait()
			end

			return DataSync._Files[index]
		end

		local load, success = Methods.LoadData(self._key, index, DataSync._Defaults[self._key])
		if not success then
			if load == "__OCCUPIED" then
				while not DataSync._Files[index] do
					Manager.Wait()
				end

				return DataSync._Files[index]
			end

			warn("DataStores are currently down; returning default data")

			if player and not Manager.IsStudio and DataSync.FailProof then
				player:Kick("\n" .. "DataStores are currently down, please try again later")
				return nil
			end

			self._loaded = false
		else
			self._loaded = true
		end

		DataSync._Cache[self._key][index] = load
		self._sesh = false
	end

	if Manager.IsClient and DataSync.Sync then
		local download = Network:InvokeServer(DataSync._Remotes.Upload, self._key, index)
		local cache = download or {}
		DataSync._Cache[self._key][index] = cache

		if cache["__CanSave"] then
			self._loaded = true
		else
			self._loaded = false
		end
		
		self:Subscribe(index, { "all" })
	end

	local info = player or index
	local data = {
		_key = self._key,
		_file = index,
		_loaded = self._loaded,
		_ready = true,
	}

	setmetatable(data, DataSync)

	if DataSync.AutoSave and Manager.IsServer then
		Manager.Wrap(function()
			while Manager.Wait(DataSync.AutoSaveTimer) do
				if player then
					local success, response = Manager.Retry(1, function()
						return Players:GetPlayerByUserId(index)
					end)

					if not success then
						break
					end
				end

				if DataSync._Cache[self._key][index] == nil then
					break
				end

				data:SaveData()
			end
		end)
	end

	data:UpdateData("__IsReady", true)
	data:UpdateData("__HasChanged", false)

	DataSync._Files[index] = data
	DataSync._Sessions[index] = false

	return data
end

--[=[
	Validates if the DataFile loaded or not
	
	@return boolean
	@outline Loaded
]=]
function DataSync:Loaded(): boolean
	assert(self._key, "':Loaded' can only be used with a DataFile")

	while self._loaded == nil do
		Manager.Wait()
	end

	return self._loaded
end

--[=[
	Validates if the DataFile is ready
	
	@return boolean
	@outline Ready
]=]
function DataSync:Ready(): boolean
	assert(self._key, "':Ready' can only be used with a DataFile")

	while self._ready == nil do
		Manager.Wait()
	end

	return self._ready
end

--[=[
	Get the value of a specified data or the entire DataFile
	
	@param value? string | number -- the value to grab data from
	@return DataValue | DataFile?
	@outline GetData
]=]
function DataSync:GetData(value: string | number | nil): any? | table
	assert(self._file, "':GetData' can only be used with a data file")

	local file = DataSync._Cache[self._key][self._file]

	while not DataSync._Cache[self._key][self._file] do
		Manager.Wait()
	end

	file = DataSync._Cache[self._key][self._file]

	if value ~= nil then
		return file[value]
	else
		return file
	end
end

--[=[
	Update a given value with any type of data
	
	@param value string -- the specific value in a DataFile
	@param data any? -- any valid type can be provided to a value
	@return DataFileObject
	@outline UpdateData
]=]
function DataSync:UpdateData(value: string, data: any?): typeof(DataSync:GetFile())
	assert(self._file, "':UpdateData' can only be used with a data file")

	local file = DataSync._Cache[self._key][self._file]
	if data == nil and DataSync._Defaults[self._key][value] ~= nil then
		data = DataSync._Defaults[self._key][value]
	end

	if file == nil and Manager.IsServer then
		while DataSync._Cache[self._key][self._file] == nil do
			Manager.Wait()
		end

		file = DataSync._Cache[self._key][self._file]
	end

	if file[value] ~= nil then
		file[value] = data
	elseif DataSync._Defaults[self._key][value] ~= nil then
		file[value] = data
	elseif typeof(value) == "table" then
		file = value
	else
		file[value] = data
	end

	if string.sub(tostring(value), 1, #DataSync._Private) ~= DataSync._Private then
		if not file["__HasChanged"] then
			file["__HasChanged"] = true
		end
	end

	local tosend = file[value] ~= nil and file[value] or file
	DataSync._Cache[self._key][self._file] = file
	self:_FireSubscriptions(self._file, value, tosend)

	return self
end

--[=[
	Increment a numerical value with the given number
	
	@param value string -- the specific value in a DataFile
	@param num number -- how much to increment/decrement
	@return DataFileObject
	@outline IncrementData
]=]
function DataSync:IncrementData(value: string, num: number): typeof(DataSync:GetFile())
	assert(self._file, "':UpdateData' can only be used with a data file")

	local current = self:GetData(value)
	if typeof(current) == "number" then
		self:UpdateData(value, current + num)
	else
		error("':IncrementData' failed, tried to increment a non-number")
	end

	return self
end

--[=[
	Save a DataFile to the cloud (Roblox DataStores)
	
	@return DataFileObject
	@outline SaveData
]=]
function DataSync:SaveData(override: boolean?): typeof(DataSync:GetFile())
	assert(self._file, "':SaveData' can only be used with a data file")
	assert(Manager.IsServer, "':SaveData' only works on the server")

	if (DataSync._ShuttingDown and not override) or self._sesh then
		return self
	end

	self._sesh = true

	local file = DataSync._Cache[self._key][self._file]
	local clone = Manager.DeepCopy(file)
	local filter = DataSync._Filters[self._key]

	if filter and filter["Type"] == "Whitelist" then
		for key, data in pairs(file) do
			if not table.find(filter["Keys"], key) then
				clone[key] = nil
			end
		end
	elseif filter and filter["Type"] == "Blacklist" then
		for key, data in pairs(file) do
			if table.find(filter["Keys"], key) then
				clone[key] = nil
			end
		end
	end

	local load, success = Methods.SaveData(self._key, self._file, clone)
	if not success then
		warn("!URGENT! Failed to save file '" .. self._file .. "' on store '" .. self._key .. "'")
	end

	if DataSync._Cache[self._key][self._file] then
		DataSync._Cache[self._key][self._file]["__HasChanged"] = false
	end

	self._sesh = false

	return self
end

--[=[
	Remove & destroy a DataFile from cache
	
	@return DestroyedDataFileObject
	@outline RemoveData
]=]
function DataSync:RemoveData(override: boolean?): typeof(DataSync:RemoveData())
	assert(self._file, "':RemoveData' can only be used with a data file")
	if self._sesh then
		return self
	end

	if DataSync._ShuttingDown and not override then
		return self
	end

	if DataSync._Cache[self._key][self._file] ~= nil then
		for index, value in pairs(DataSync._Cache[self._key][self._file]) do
			DataSync._Cache[self._key][self._file][index] = nil
		end
		DataSync._Cache[self._key][self._file] = nil
	end

	if DataSync._Subscriptions[self._key .. self._file] ~= nil then
		DataSync._Subscriptions[self._key .. self._file]:Unsubscribe()
	end

	if DataSync._Files[self._file] then
		DataSync._Files[self._file] = nil
	end

	return self
end

--[=[
	Wipe a DataFile from the cloud (Roblox DataStores)
	
	@Return DataFileObject
	@outline WipeData
]=]
function DataSync:WipeData(): typeof(DataSync:GetFile())
	assert(self._file, "':WipeData' can only be used with a data file")
	assert(Manager.IsServer, "':SaveData' only works on the server")

	Methods.WipeData(self._key, self._file)

	return self
end

--[=[
	Subscribe to an index with a value and possibly a provided function
	
	@param index number | string | Instance -- the index can be a number or Player, and converted to string
	@param value string -- the value for the file
	@param code function -- the function which to be called whenever the value changes
	@outline Subscribe
]=]
function DataSync:Subscribe(index: string | number | Player, value: string | table, code: (any) -> nil, _sent: Player?): typeof(DataSync:Subscribe())
	assert(self._key, "':Subscribe' can only be used with a store")

	value = typeof(value) == "table" and value or { value }
	index = typeof(index) == "Instance" and index:IsA("Player") and tostring(index.UserId) or tostring(index)
	local player = Manager.IsClient and Players.LocalPlayer or Manager.IsServer and _sent
	local info = player or index
	local guid = Subscribe.ConnectSubscription(info, self._key, index, value, code)
	local sub = {
		_key = self._key,
		_index = index,
		_value = value,
		_info = info,
		_guid = guid,
	}

	setmetatable(sub, DataSync)

	DataSync._Subscriptions[self._key .. index] = sub
	return sub
end

--[=[
	Unsubscribe from a subscription on a store
	
	@return SubscriptionObject
	@outline Unsubscribe
]=]
function DataSync:Unsubscribe(): typeof(DataSync:Unsubscribe())
	assert(self._key, "':Unsubscribe' can only be used with a store")
	assert(
		self._guid,
		"':Unsubscribe' can only be used with a subscription created with ':Subscribe'"
	)

	if self._deactivated then
		return self
	end

	Subscribe.DisconnectSubscription(self._key, self._guid)
	self._deactivated = true

	return self
end

--[=[
	Fire all the subscriptions on a value & the 'all' values
	
	@param index string -- the DataFile index
	@param value string -- the value to fire
	@param data any? -- this can be any data
	@return nil
	@outline _FireSubscriptions
]=]
function DataSync:_FireSubscriptions(index: string, value: string, data: any?): nil
	if string.sub(tostring(tostring(value)), 1, #DataSync._Private) == DataSync._Private then
		return true
	end

	Subscribe.FireSubscription(self._key, index, value, data)
end

if Manager.IsServer then
	if DataSync.Shutdown then
		game:BindToClose(function()
			DataSync._ShuttingDown = true

			if Manager.Count(DataSync._Files) == 0 then
				return
			end

			print("Shutting down and saving DataSync files")

			for index, file in pairs(DataSync._Files) do
				Manager.Wrap(function()
					file:SaveData(true):RemoveData(true)
					DataSync._Files[index] = nil
				end)
			end

			while Manager.Count(DataSync._Files) > 0 do
				Manager.Wait()
			end
		end)
	end

	Network.CreateEvent(DataSync._Remotes.Download)

	Network:HookFunction(DataSync._Remotes.Upload, function(client, key, index, value)
		local success, response = pcall(function()
			return DataSync.GetStore(key):GetFile(index):GetData(value)
		end)

		return success and response or nil
	end)

	Network:HookEvent(DataSync._Remotes.Subscribe, function(client, key, index, value, uid)
		local store = DataSync.GetStore(key)

		store:Subscribe(index, value, nil, client, nil, uid)
	end)

	Network:HookEvent(DataSync._Remotes.Unsubscribe, function(client, key, uid)
		Subscribe.DisconnectSubscription(key, uid)
	end)
elseif Manager.IsClient then
	Network:HookEvent(DataSync._Remotes.Download, function(key, index, value, data, uid)
		if not DataSync._Cache[key] then
			DataSync._Cache[key] = {}
		end

		if not DataSync._Cache[key][index] then
			DataSync._Cache[key][index] = {}
		end

		if string.lower(value) == "all" then
			DataSync._Cache[key][index] = data
		else
			DataSync._Cache[key][index][value] = data
		end

		Subscribe.FireSubscription(key, index, value, data, uid)
	end)
end

return DataSync
