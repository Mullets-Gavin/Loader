--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Internal methods for DataStores
]=]

local Methods = {}
Methods._Occupants = {}
Methods._MaxRetries = 5
Methods._Private = "__"

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local Manager = require("Manager")
local DataStoreService = game:GetService("DataStoreService")

--[=[
	Load DataStore
	
	@param key string -- DataStore key
	@param index string -- DataStore scope
	@param file table -- Default table
	@return File & bool
	@private
]=]
function Methods.LoadData(key: string, index: string, file: table): table & boolean
	assert(Manager.IsServer, "'LoadData' can only be used on the server")
	index = tostring(index)

	if Methods._Occupants[key .. index] then
		return Methods._Private .. "OCCUPIED"
	end

	Methods._Occupants[key .. index] = true

	local success1, store = Manager.Rerun(Methods._MaxRetries, function()
		return DataStoreService:GetDataStore(key, index)
	end)

	if not success1 then
		warn(store)
	end

	local success2, data = Manager.Rerun(Methods._MaxRetries, function()
		return store:UpdateAsync(index, function(last)
			if typeof(last) == "string" then
				last = Manager.Decode(last)
			end

			if not last then
				last = Manager.DeepCopy(file)
			elseif typeof(last) == "table" then
				for scope, value in pairs(file) do
					if last[scope] ~= nil then
						continue
					end
					last[scope] = value
				end
			end

			last[Methods._Private .. "CanSave"] = true
			last[Methods._Private .. "HasChanged"] = false
			last[Methods._Private .. "IsReady"] = false
			return last
		end)
	end)

	if not success2 then
		warn(data)

		data = Manager.DeepCopy(file)
		data[Methods._Private .. "CanSave"] = false
		data[Methods._Private .. "HasChanged"] = false
		data[Methods._Private .. "IsReady"] = false
	end

	Methods._Occupants[key .. index] = nil

	return data, success2
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
	assert(Manager.IsServer, "'SaveData' can only be used on the server")
	index = tostring(index)

	if
		file == nil
		or Methods._Occupants[key .. index]
		or not file[Methods._Private .. "HasChanged"]
		or not file[Methods._Private .. "CanSave"]
	then
		return file or Methods._Private .. "OCCUPIED", true
	end

	Methods._Occupants[key .. index] = true

	local _, store = Manager.Rerun(Methods._MaxRetries, function()
		return DataStoreService:GetDataStore(key, index)
	end)

	local success, data = Manager.Rerun(Methods._MaxRetries, function()
		return store:UpdateAsync(index, function()
			file[Methods._Private .. "HasChanged"] = false
			file = Manager.Encode(file)
			return file
		end)
	end)

	Methods._Occupants[key .. index] = nil

	return data, success
end

--[=[
	Wipe a file from a DataStore
	
	@param key string -- DataStore key
	@param index string -- DataStore scope
	@return File & bool
	@private
]=]
function Methods.WipeData(key: string, index: string): table & boolean
	assert(Manager.IsServer, "'WipeData' can only be used on the server")
	index = tostring(index)

	if Methods._Occupants[key .. index] then
		return false, false
	end

	Methods._Occupants[key .. index] = true

	local _, store = Manager.Rerun(Methods._MaxRetries, function()
		return DataStoreService:GetDataStore(key, index)
	end)

	local success, data = Manager.Rerun(Methods._MaxRetries, function()
		return store:RemoveAsync(index)
	end)

	Methods._Occupants[key .. index] = nil

	return data, success
end

return Methods
