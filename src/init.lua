--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Loader, a custom Roblox Luau Library Loader by Mullet Mafia Dev
	@Notes: Loader & it's library modules are completely documented. All API is listed out within each script.
	@Libraries:
	- DataSync
	- Interface
	- Manager
	- Network
	- Roblox
]=]

--[=[
[DOCUMENTATION]:
	https://github.com/Mullets-Gavin/Loader
	Listed below is a quick glance on the API, visit the link above for proper documentation.
	
	Loader(module)
	Loader[service]
	Loader.require(module)
	Loader.server(module)
	Loader.client(module)
	Loader.import(service)
	Loader.enum(name,members)
	Loader.VERSION()
	
[OUTLINE]:
	Loader
	├─ .__require(module,requirer)
	│  ├─ if instance, requires the module & caches it
	│  └─ if string, searches the following:
	│     ├─ if client: library -> shared -> client
	│     └─ if server: library -> shared -> server
	├─ .__server(module,requirer)
	│  ├─ if instance, requires the module & caches it
	│  └─ if string, searches the following:
	│     └─ if server: server
	├─ .__client(module,requirer)
	│  ├─ if instance, requires the module & caches it
	│  └─ if string, searches the following:
	│     └─ if client: client
	├─ Loader(module) | .require(module)
	│  └─ Redirects & returns __require()
	├─ .server(module)
	│  └─ Redirects & returns __server()
	├─ .client(module)
	│  └─ Redirects & returns __client()
	├─ Loader[service] | .import(service)
	│  └─ validates the service & returns it
	├─ .enum(name,members)
	│  └─ create a custom enum on shared
	├─ .__version() and .VERSION Returns the current version
	└─ :__index and :__call redirect to .import and .require respectively
	
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

local Loader = {}
setmetatable(Loader,Loader)

Loader._ModuleCache = {}
Loader._ServiceCache = {}

Loader._Timeout = 0.5
Loader._Initialized = false
Loader._Filter = false
Loader._Name = string.upper(script.Name)
Loader._Error = '['.. Loader._Name ..']: '
Loader._Version = {
	['MAJOR'] = 1;
	['MINOR'] = 0;
	['PATCH'] = 0;
}

Loader._Containers = {'PlayerScripts','PlayerGui','Backpack'};
Loader._Services = {
	['Client'] = {'ReplicatedFirst'};
	['Server'] = {'ServerScriptService','ServerStorage'};
	['Shared'] = {'ReplicatedStorage','Chat','Lighting'};
}

Loader.MaxRetryTime = 5

local Services = setmetatable({}, {__index = function(cache, service)
	cache[service] = game:GetService(service)
	return cache[service]
end})

local RunService = Services['RunService']

local IsStudio = RunService:IsStudio() and 'Studio'
local IsServer = RunService:IsServer() and 'Server'
local IsClient = RunService:IsClient() and 'Client'

--[=[
	Validates a module script instance
	
	@param module Instance | string | number -- provided module type
	@return boolean
	@private
]=]
local function IsValidModule(module)
	if typeof(module) == 'Instance' then
		if not module:IsA('ModuleScript') then
			return false
		end
		return true
	elseif typeof(module) == 'string' or typeof(module) == 'number' then
		return true
	end
	
	return false
end

--[=[
	Validates and returns a Roblox service
	
	@param service string -- String to check for a service
	@return boolean & boolean
	@private
]=]
local function IsValidService(service)
	return pcall(function()
		return game:FindService(service)
	end)
end

--[=[
	Safely require a module like the Roblox require function works
	
	@param module Instance -- required module
	@param requirer Instance -- the source script requiring this
	@return RequiredModule?
	@private
]=]
local function SafeRequire(module,requirer)
	local time = os.clock()
	local event; event = Services['RunService'].Stepped:Connect(function()
		if os.clock() >= time + Loader._Timeout then
			warn(string.format(Loader._Error..'%s -> %s is taking too long',tostring(requirer),tostring(module)))
			if event then
				event:Disconnect()
				event = nil
			end
		end
	end)
	
	local loaded
	local success,response = pcall(function()
		loaded = require(module)
	end)
	
	if not success then
		if type(loaded) == 'nil' and string.find(response,'exactly one value') then
			error(Loader._Error.."Module did not return exactly one value: " .. module:GetFullName(), 3)
		else
			error(Loader._Error.."Module " .. module:GetFullName() .. " experienced an error while loading: " .. response, 3)
		end
	end
	
	if event then
		event:disconnect()
		event = nil
	end
	
	return loaded
end

--[=[
	Deep search a list for a specific name
	
	@param name string -- the name of the module
	@param list table -- the list of instances to filter
	@return Module?
	@private
]=]
local function DeepSearch(name,list)
	for count,asset in ipairs(list) do
		if not asset:IsA('ModuleScript') then continue end
		if Loader._Filter and asset.Parent:IsA('ModuleScript') then continue end
		
		if string.lower(asset.Name) == name then
			return asset
		end
	end
	
	return nil
end

--[=[
	The internal require function which searches the built-in library & all containers per-environment
	
	@param module string | number | Instance -- the module to require
	@param requirer Instance -- the script that required this function to simulate require()
	@return RequiredModule?
	@private
]=]
function Loader.__require(module,requirer)
	local clock = os.clock()
	local name = string.lower(typeof(module) == 'Instance' and module.Name or module)
	
	if Loader._ModuleCache[name] then
		return Loader._ModuleCache[name]
	end
	
	if typeof(module) == 'number' or typeof(module) == 'Instance' then
		Loader._ModuleCache[name] = require(module)
		return Loader._ModuleCache[name]
	end
	
	while not Loader._ModuleCache[name] and os.clock() - clock < Loader.MaxRetryTime do
		local libModule = DeepSearch(name,script:GetChildren())
		if libModule then
			Loader._ModuleCache[name] = SafeRequire(libModule,requirer)
			return Loader._ModuleCache[name]
		end
		
		for index,service in pairs(Loader._Services.Shared) do
			local container = Services[service]
			local sharedModule = DeepSearch(name,container:GetDescendants())
			
			if sharedModule then
				Loader._ModuleCache[name] = SafeRequire(sharedModule,requirer)
				return Loader._ModuleCache[name]
			end
		end
		
		if IsClient then
			local response = Loader.__client(module,requirer,true)
			
			if response then
				return Loader._ModuleCache[name]
			end
		elseif IsServer then
			local response = Loader.__server(module,requirer)
			
			if response then
				return Loader._ModuleCache[name]
			end
			
			break
		end
		
		RunService.Heartbeat:Wait()
	end
	
	assert(Loader._ModuleCache[name],Loader._Error.."attempted to require a non-existant module")
	return Loader._ModuleCache[name]
end

--[=[
	The internal require function for filtering the server containers
	
	@param module string | number | Instance -- the module to require
	@param requirer Instance -- the script that required this function to simulate require()
	@return RequiredModule?
	@private
]=]
function Loader.__server(module,requirer)
	local name = string.lower(typeof(module) == 'Instance' and module.Name or module)
	
	if Loader._ModuleCache[name] then
		return Loader._ModuleCache[name]
	end
	
	for index,service in pairs(Loader._Services.Server) do
		local container = Services[service]
		local serverModule = DeepSearch(name,container:GetDescendants())
		
		if serverModule then
			Loader._ModuleCache[name] = SafeRequire(serverModule,requirer)
			return Loader._ModuleCache[name]
		end
	end
	
	return Loader._ModuleCache[name]
end

--[=[
	The internal require function for filtering the client containers
	
	@param module string | number | Instance -- the module to require
	@param requirer Instance -- the script that required this function to simulate require()
	@return RequiredModule?
	@private
]=]
function Loader.__client(module,requirer,__disabled)
	local clock = os.clock()
	local name = string.lower(typeof(module) == 'Instance' and module.Name or module)
	
	if Loader._ModuleCache[name] then
		return Loader._ModuleCache[name]
	end
	
	while not Loader._ModuleCache[name] and os.clock() - clock < Loader.MaxRetryTime do
		local player = Services['Players'].LocalPlayer
		
		for index,container in pairs(player:GetChildren()) do
			if not table.find(Loader._Containers,container.Name) then continue end
			
			local clientModule = DeepSearch(name,container:GetDescendants())
			
			if clientModule then
				Loader._ModuleCache[name] = SafeRequire(clientModule,requirer)
				return Loader._ModuleCache[name]
			end
		end
		
		for index,service in pairs(Loader._Services.Client) do
			local container = Services[service]
			local clientModule = DeepSearch(name,container:GetDescendants())
			
			if clientModule then
				Loader._ModuleCache[name] = SafeRequire(clientModule,requirer)
				return Loader._ModuleCache[name]
			end
		end
		
		if __disabled then
			break
		end
	end
	
	return Loader._ModuleCache[name]
end

--[=[
	Require a module instance or search containers for a module with a string
	
	@param module string | number | Instance -- the module type to require
	@return RequiredModule?
]=]
function Loader.require(module)
	assert(IsValidModule(module),Loader._Error.."Expected module or module name, got '".. typeof(module) .."'")
	
	local requirer = getfenv(2).script	
	return Loader.__require(module,requirer)
end

--[=[
	Require a module instance or search server containers for a module with a string
	
	@param module string | number | Instance -- the module type to require
	@return RequiredModule?
]=]
function Loader.server(module)
	assert(IsServer,Loader._Error.."Attempted to access .server from the client")
	assert(IsValidModule(module),Loader._Error.."Expected module or module name, got '".. module .."'")
	
	local requirer = getfenv(2).script
	return Loader.__server(module,require())
end

--[=[
	Require a module instance or search client containers for a module with a string
	
	@param module string | number | Instance -- the module type to require
	@return RequiredModule?
]=]
function Loader.client(module,__disabled)
	assert(IsClient,Loader._Error.."Attempted to access .client from the server")
	assert(IsValidModule(module),Loader._Error.."Expected module or module name, got '".. module .."'")
	
	local requirer = getfenv(2).script
	return Loader.__client(module,requirer)
end

--[=[
	Import a Roblox service
	
	@param service string -- Roblox service name
	@return RobloxService?
]=]
function Loader.import(service)
	assert(IsValidService(service),Loader._Error.."'.import' expected Roblox Service, got '".. service .."'")
	
	if Loader._ServiceCache[service] then
		return Loader._ServiceCache[service]
	end
	
	Loader._ServiceCache[service] = game:GetService(service)
	return Loader._ServiceCache[service]
end

--[=[
	Create a custom enum library on `shared`
	
	@param name string -- the name & index of the enum
	@param members table -- list of all the enum members
	@return Enumerator
]=]
function Loader.enum(name,members)
	assert(typeof(name) == 'string',Loader._Error.."'.enum' missing parameter #1, expected string, got '"..typeof(name).."'")
	assert(typeof(members) == 'table',Loader._Error.."'.enum' missing parameter #2, expected table, got '"..typeof(members).."'")
	assert(shared[name] == nil,Loader._Error.."Error claiming enum '"..name.."': already claimed")
	
	local proxy = {}
	
	for index,enum in ipairs(members) do
		proxy[enum] = enum
	end
	
	shared[name] = proxy
	return shared[name]
end

--[=[
	Replace the require function by Roblox
	
	@param module string | number | Instance -- the module type to require
	@return RequiredModule?
]=]
function Loader:__call(module)
	assert(IsValidModule(module),Loader._Error.."Expected module or module name, got '".. typeof(module) .."'")
	
	local requirer = getfenv(2).script	
	return Loader.__require(module,requirer)
end

--[=[
	Quickly import services by indexing Loader
	Redirects to Loader.import()
	
	@param service string -- Roblox service name
	@return RobloxService?
]=]
function Loader:__index(service)
	if IsValidService(service) then
		return Loader.import(service)
	end
end

--[=[
	Returns the current version of Loader
	
	@return FormattedVersion
]=]
function Loader.__version()
	return string.format('v%d.%d.%d',
		Loader._Version.MAJOR,
		Loader._Version.MINOR,
		Loader._Version.PATCH
	)
end
Loader.VERSION = Loader.__version()

do
	if not shared.Loader and (not IsStudio or (IsStudio and IsServer)) then
		Loader.enum('Loader',{'Initialized'})
		print('Loader by Mullet Mafia Dev initialized','|',Loader.VERSION)
	end
	
	if IsClient then
		while not game:IsLoaded() do
			game.Loaded:Wait()
		end
	end
end

return Loader