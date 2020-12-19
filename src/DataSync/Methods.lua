--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Internal methods for DataStores
]=]

local Methods = {}
Methods._Occupants = {}
Methods._MaxRetries = 5

local require = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))
local Manager = require('Manager')
local DataStoreService = game:GetService('DataStoreService')

--[=[
	Load DataStore
	
	@param key string -- DataStore key
	@param index string -- DataStore scope
	@param file table -- Default table
	@return File & bool
	@private
]=]
function Methods.LoadData(key: string, index: string, file: table): table & boolean
	assert(Manager.IsServer,"'LoadData' can only be used on the server")
	index = tonumber(index) and 'Player_'..index or 'Data_'..index
	
	if Methods._Occupants[key..index] then
		return '__OCCUPIED'
	end
	
	Methods._Occupants[key..index] = true
	
	local success,store = Manager.rerun(Methods._MaxRetries,function()
		return DataStoreService:GetDataStore(key,index)
	end)
	
	if not success then
		warn(store)
	end
	
	local success,data = Manager.rerun(Methods._MaxRetries,function()
		return store:UpdateAsync(index,function(last)
			if typeof(last) == 'string' then
				last = Manager.Decompress(last)
			end
			
			if last == nil then
				last = Manager.DeepCopy(file)
			elseif typeof(last) == 'table' then
				for index,value in pairs(file) do
					if last[index] ~= nil then continue end
					last[index] = value
				end
			end
			
			last['__CanSave'] = true
			last['__HasChanged'] = false
			last['__IsReady'] = false
			return last
		end)
	end)
	
	if not success then
		warn(data)
		
		data = Manager.DeepCopy(file)
		data['__CanSave'] = false
		data['__HasChanged'] = false
		data['__IsReady'] = false
	end
	
	Methods._Occupants[key..index] = nil
	
	return data,success
end

--[=[
	Save a file to a DataStore
	
	@param key string -- DataStore key
	@param index string -- DataStore scope
	@param file table -- File to save
	@return File & bool
	@private
]=]
function Methods.SaveData(key: string, index: string, file: table): table & boolean
	assert(Manager.IsServer,"'SaveData' can only be used on the server")
	index = tonumber(index) and 'Player_'..index or 'Data_'..index
	
	if file == nil or Methods._Occupants[key..index] or not file['__HasChanged'] or not file['__CanSave'] then
		return file or '__OCCUPIED',true
	end
	
	Methods._Occupants[key..index] = true
	
	local success,store = Manager.rerun(Methods._MaxRetries,function()
		return DataStoreService:GetDataStore(key,index)
	end)
	
	local success,data = Manager.rerun(Methods._MaxRetries,function()
		return store:UpdateAsync(index,function(last)
			file['__HasChanged'] = false
			file = Manager.Compress(file)
			return file
		end)
	end)
	
	Methods._Occupants[key..index] = nil
	
	return data,success
end

--[=[
	Wipe a file from a DataStore
	
	@param key string -- DataStore key
	@param index string -- DataStore scope
	@return File & bool
	@private
]=]
function Methods.WipeData(key: string, index: string): table & boolean
	assert(Manager.IsServer,"'WipeData' can only be used on the server")
	index = tonumber(index) and 'Player_'..index or 'Data_'..index
	
	if Methods._Occupants[key..index] then
		return false,false
	end
	
	Methods._Occupants[key..index] = true
	
	local success,store = Manager.rerun(Methods._MaxRetries,function()
		return DataStoreService:GetDataStore(key,index)
	end)
	
	local success,data = Manager.rerun(Methods._MaxRetries,function()
		return store:RemoveAsync(index)
	end)
	
	Methods._Occupants[key..index] = nil
	
	return data,success
end

return Methods