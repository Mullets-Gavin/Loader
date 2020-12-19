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
DataSync._Private = '__'
DataSync._Cache = {}
DataSync._Stores = {}
DataSync._Files = {}
DataSync._Filters = {}
DataSync._Defaults = {}
DataSync._Network = {}
DataSync._Sessions = {}
DataSync._Subscriptions = {}
DataSync._Remotes = {
	['Download'] = '_DOWNLOAD';
	['Upload'] = '_UPLOAD';
	['Subscribe'] = '_SUBSCRIBE';
}

DataSync.Sync = true -- allow data to sync - highly recommended to leave this to true
DataSync.Shutdown = true -- support BindToClose & autosave all DataFiles
DataSync.AutoSave = true -- can DataFiles autosave
DataSync.AutoSaveTimer = 30 -- how often, in seconds, a DataFile autosaves
DataSync.FailProof = true -- kick the player if the datastore failed loading player-based data
DataSync.All = 'all' -- the 'all' variable for streamlining data types

local require = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))
local Manager = require('Manager')
local Network = require('Network')
local Methods = require(script:WaitForChild('Methods'))
local Subscribe = require(script:WaitForChild('Subscribe'))
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

--[=[
	Get the Player from either the instance or UserId
	
	@param index string | number | Instance -- find the player from the index
	@return Index & Player?
]=]
local function GetPlayer(index: string | number | Instance): ((number | string) & (Player?))
	local player; do
		local success,response = pcall(function()
			return Players:GetPlayerByUserId(index)
		end)
		
		if success then
			player = response
		end
	end
	
	if typeof(index) == 'Instance' and index:IsA('Player') then
		player = index
		index = tostring(player.UserId)
	elseif tostring(index) then
		index = tostring(index)
	end
	
	return index,player
end

--[=[
	Get a DataStore object on a key
	
	@param key string -- the DataStore key required
	@param data? table -- if you set a default table to load player data
	@return DataStoreObject
]=]
function DataSync.GetStore(key: string, data: table?): typeof(DataSync.GetStore())
	if DataSync._Stores[key] and not data then
		return DataSync._Stores[key]
	end
	
	if not DataSync._Cache[key] then
		DataSync._Cache[key] = {}
	end
	
	if not DataSync._Defaults[key] and typeof(data) == 'table' then
		DataSync._Defaults[key] = data
	end
	
	local store = {
		_key = key;
	}
	
	setmetatable(store,DataSync)
	
	DataSync._Stores[key] = store
	return store
end

--[=[
	A blacklist/whitelist filter for saving keys on a datastore

	@param keys table -- the keys to filter
	@param filter? boolean -- if true, only save these keys, if false, don't save those keys
]=]
function DataSync:FilterKeys(keys: table, filter: boolean?): typeof(DataSync.GetStore())
	assert(self._key,"':FilterKeys' can only be used with a store")
	
	if not DataSync._Defaults[self._key] then
		warn('Unable to set filter, no Default Data table found')
		return self
	end
	
	DataSync._Filters[self._key] = {
		['Keys'] = keys;
		['Type'] = filter and 'Whitelist' or 'Blacklist'
	}
	
	return self
end

--[=[
	Get a DataFile Object with an index on a store
	
	@param index string | number | nil & client -- the index on the DataStore
	@return DataFileObject
]=]
function DataSync:GetFile(index: string | number | nil): typeof(DataSync:GetFile())
	assert(self._key,"':GetFile' can only be used with a store")
	
	if not index and Manager.IsClient and Players.LocalPlayer then
		index = tostring(Players.LocalPlayer.UserId)
	end
	
	if DataSync._Sessions[index] then
		while not DataSync._Files[index] do
			Manager.wait()
		end
		
		return DataSync._Files[index]
	end
	
	if DataSync._Files[index] then
		return DataSync._Files[index]
	end
	
	DataSync._Sessions[index] = true
	
	local player; index,player = GetPlayer(index)
	
	if not DataSync._Cache[self._key][index] and Manager.IsServer and not self._sesh then
		self._sesh = true
		
		if not DataSync._Defaults[self._key] then
			while not DataSync._Files[index] do
				Manager.wait()
			end
			
			return DataSync._Files[index]
		end
		
		local load,success = Methods.LoadData(self._key,index,DataSync._Defaults[self._key])
		if not success then
			if load == '__OCCUPIED' or DataSync._Sessions[index] then
				while not DataSync._Files[index] do
					Manager.wait()
				end
				
				return DataSync._Files[index]
			end
			
			warn('DataStores are currently down; returning default data')
			
			if player and not Manager.IsStudio and DataSync.FailProof then
				player:Kick('\n'..'DataStores are currently down, please try again later')
				return nil
			end
			
			load = Manager.Copy(DataSync._Defaults[self._key])
		end
		
		DataSync._Cache[self._key][index] = load
		self._sesh = false
	end
	
	local data = {
		_key = self._key;
		_file = index;
	}
	
	local info = player or index
	
	if info then
		self:Subscribe(info,index,'all')
	end
	
	self.IsReady = true
	
	if Manager.IsClient and DataSync.Sync then
		local download = Network:InvokeServer(DataSync._Remotes.Upload,self._key,index)
		DataSync._Cache[self._key][index] = download or {}
	end
	
	setmetatable(data,DataSync)
	
	if DataSync.AutoSave and Manager.IsServer then
		Manager.wrap(function()
			while Manager.wait(DataSync.AutoSaveTimer) do
				if player then
					local success,response = Manager.retry(1,function()
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
	
	data:UpdateData('__IsReady',true)
	data:UpdateData('__HasChanged',false)
	
	DataSync._Files[index] = data
	DataSync._Sessions[index] = false
	
	return data
end

--[=[
	Get the value of a specified data or the entire DataFile
	
	@param value? string | number -- the value to grab data from
	@return DataValue | DataFile?
]=]
function DataSync:GetData(value: string | number | nil): any? | table
	assert(self._file,"':GetData' can only be used with a data file")
	
	local file = DataSync._Cache[self._key][self._file]
	
	while not DataSync._Cache[self._key][self._file] do
		Manager.wait()
	end
	
	file = DataSync._Cache[self._key][self._file]
	
	--if file == nil then
	--	DataSync._Cache[self._key][self._file] = Manager.Copy(DataSync._Defaults[self._key])
	--	file = DataSync._Cache[self._key][self._file]
	--end
	
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
]=]
function DataSync:UpdateData(value: string, data: any?): typeof(DataSync:GetFile())
	assert(self._file,"':UpdateData' can only be used with a data file")
	
	local file = DataSync._Cache[self._key][self._file]
	if data == nil and DataSync._Defaults[self._key][value] ~= nil then
		data = DataSync._Defaults[self._key][value]
	end
	
	if file == nil and Manager.IsServer then
		while DataSync._Cache[self._key][self._file] == nil do
			Manager.wait()
		end 
		
		file = DataSync._Cache[self._key][self._file]
	end
	
	if file[value] ~= nil then
		file[value] = data
	elseif DataSync._Defaults[self._key][value] ~= nil then
		file[value] = data
	elseif typeof(value) == 'table' then
		file = value
	else
		file[value] = data
	end
	
	if string.sub(tostring(value),1,#DataSync._Private) ~= DataSync._Private then
		if not file['__HasChanged'] then
			file['__HasChanged'] = true
		end
	end
	
	local tosend = file[value] ~= nil and file[value] or file
	DataSync._Cache[self._key][self._file] = file
	self:_FireSubscriptions(self._file,value,tosend)
	
	return self
end

--[=[
	Increment a numerical value with the given number
	
	@param value string -- the specific value in a DataFile
	@param num number -- how much to increment/decrement
	@return DataFileObject
]=]
function DataSync:IncrementData(value: string, num: number): typeof(DataSync:GetFile())
	assert(self._file,"':UpdateData' can only be used with a data file")
	
	local current = self:GetData(value)
	if typeof(current) == 'number' then
		self:UpdateData(value,current + num)
	else
		error("':IncrementData' failed, tried to increment a non-number")
	end
	
	return self
end

--[=[
	Save a DataFile to the cloud (Roblox DataStores)
	
	@return DataFileObject
]=]
function DataSync:SaveData(override: boolean?): typeof(DataSync:GetFile())
	assert(self._file,"':SaveData' can only be used with a data file")
	assert(Manager.IsServer,"':SaveData' only works on the server")
	
	if (DataSync._ShuttingDown and not override) or self._sesh then
		return self
	end
	
	self._sesh = true
	
	local file = DataSync._Cache[self._key][self._file]
	local clone = Manager.DeepCopy(file)
	local filter = DataSync._Filters[self._key]
	
	if filter and filter['Type'] == 'Whitelist' then
		for key,data in pairs(file) do
			if not table.find(filter['Keys'],key) then
				clone[key] = nil
			end
		end
	elseif filter and filter['Type'] == 'Blacklist' then
		for key,data in pairs(file) do
			if table.find(filter['Keys'],key) then
				clone[key] = nil
			end
		end
	end
	
	local load,success = Methods.SaveData(self._key,self._file,clone)
	if not success then
		warn("!URGENT! Failed to save file '"..self._file.."' on store '"..self._key.."'")
	end
	
	if DataSync._Cache[self._key][self._file] then
		DataSync._Cache[self._key][self._file]['__HasChanged'] = false
	end
	
	self._sesh = false
	
	return self
end

--[=[
	Remove & destroy a DataFile from cache
	
	@return DestroyedDataFileObject
]=]
function DataSync:RemoveData(override: boolean?): typeof(DataSync:RemoveData())
	assert(self._file,"':RemoveData' can only be used with a data file")
	if self._sesh then return self end
	
	if DataSync._ShuttingDown and not override then
		return self
	end
	
	if DataSync._Cache[self._key][self._file] ~= nil then
		for index,value in pairs(DataSync._Cache[self._key][self._file]) do
			DataSync._Cache[self._key][self._file][index] = nil
		end
		DataSync._Cache[self._key][self._file] = nil
	end
	
	if DataSync._Subscriptions[self._key..self._file] ~= nil then
		DataSync._Subscriptions[self._key..self._file]:Unsubscribe()
	end
	
	if DataSync._Files[self._file] then
		DataSync._Files[self._file] = nil
	end
	
	return self
end

--[=[
	Wipe a DataFile from the cloud (Roblox DataStores)
	
	@Return DataFileObject
]=]
function DataSync:WipeData(): typeof(DataSync:GetFile())
	assert(self._file,"':WipeData' can only be used with a data file")
	assert(Manager.IsServer,"':SaveData' only works on the server")
	
	Methods.WipeData(self._key,self._file)
	
	return self
end

--[=[
	Subscribe to an index with a value and possibly a provided function
	
	@param index number | string | Instance -- the index can be a number or Player, and converted to string
	@param value string -- the value for the file
	@param code function -- the function which to be called whenever the value changes
]=]
function DataSync:Subscribe(index: string | number | Player, value: string, code: (any) -> nil, _sent: Player?): typeof(DataSync:Subscribe())
	assert(self._key,"':Subscribe' can only be used with a store")
	
	local index,player = tostring(GetPlayer(index))
	local player = Manager.IsClient and Players.LocalPlayer or Manager.IsServer and _sent
	local info = player or index
	
	local _subscription = {
		value = value;
		info = info;
		index = index;
	}
	self._subscription = _subscription
	
	Subscribe.ConnectSubscription(info,self._key,index,value,code)
	DataSync._Subscriptions[index .. value] = self._subscription
	
	return self
end

--[=[
	Unsubscribe from a subscription on a store
	
	@return SubscriptionObject
]=]
function DataSync:Unsubscribe(): typeof(DataSync:Unsubscribe())
	assert(self._key,"':Unsubscribe' can only be used with a store")
	assert(self._subscription,"':Unsubscribe' can only be used with a subscription created with ':Subscribe'")
	
	if not DataSync._Subscriptions[self._subscription.index .. self._subscription.value] then
		return self
	end
	
	Subscribe.DisconnectSubscription(self._subscription.info,self._key,self._subscription.index,self._subscription.value)
	DataSync._Subscriptions[self._subscription.index .. self._subscription.value] = nil
	
	return self
end

--[=[
	Fire all the subscriptions on a value & the 'all' values
	
	@param index string -- the DataFile index
	@param value string -- the value to fire
	@param data any? -- this can be any data
	@return nil
]=]
function DataSync:_FireSubscriptions(index: string, value: string, data: any?): nil
	assert(self._key,"':Subscribe' can only be used with a store")
	
	if string.sub(tostring(tostring(value)),1,#DataSync._Private) == DataSync._Private then
		return true
	end
	
	Subscribe.FireSubscription(self._key,index,value,data)
end

if Manager.IsServer then
	if DataSync.Shutdown then
		game:BindToClose(function()
			DataSync._ShuttingDown = true
			
			if not next(DataSync._Files) then
				return
			end
			
			print('Shutting down and saving DataSync files')
			
			for index,file in pairs(DataSync._Files) do
				file:SaveData(true):RemoveData(true)
			end
			
			Manager.wait(1)
		end)
	end
	
	Network.CreateEvent(DataSync._Remotes.Download)
	
	Network:HookFunction(DataSync._Remotes.Upload,function(client,key,index,value)
		assert(typeof(key) == 'string',typeof(key))
		assert(index ~= nil)
		
		return DataSync.GetStore(key):GetFile(index):GetData(value)
	end)
	
	Network:HookEvent(DataSync._Remotes.Subscribe,function(client,key,index,value)
		local store = DataSync.GetStore(key)
		store:Subscribe(index,value,nil,client)
	end)
elseif Manager.IsClient then
	Network:HookEvent(DataSync._Remotes.Download,function(key,index,value,data)
		if not DataSync._Cache[key] then
			DataSync._Cache[key] = {}
		end
		
		if not DataSync._Cache[key][index] then
			DataSync._Cache[key][index] = {}
		end
		
		if string.lower(value) == 'all' then
			DataSync._Cache[key][index] = data
		else
			DataSync._Cache[key][index][value] = data
		end
		
		Subscribe.FireSubscription(key,index,value,data)
	end)
end

return DataSync