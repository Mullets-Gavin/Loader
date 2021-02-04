--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Loader, a custom Roblox Luau Library Loader
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
	https://mullets-gavin.github.io/Loader/
	Listed below is a quick glance on the API, visit the link above for proper documentation.
	
	Loader(module)
	Loader.require(module)
	Loader.server(module)
	Loader.client(module)
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
	├─ .enum(name,members)
	│  └─ create a custom enum on shared
	├─ .__version() and .VERSION Returns the current version
	└─ :__call redirects to .require
	
[LICENSE]:
	MIT License
	
	Copyright (c) 2020 Gavin "Mullets" Rosenthal
	
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

local Chat = game:GetService("Chat")
local Players = game:GetService("Players")
local Geometry = game:GetService("Geometry")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local IsStudio = RunService:IsStudio() and "Studio"
local IsServer = RunService:IsServer() and "Server"
local IsClient = RunService:IsClient() and "Client"

local Loader = {}
Loader.__index = Loader
Loader._ModuleCache = {}
Loader._Name = string.upper(script.Name)
Loader._Containers = { "PlayerScripts", "PlayerGui", "Backpack" }
Loader._Services = {
	["Client"] = { ReplicatedFirst },
	["Server"] = { ServerStorage, ServerScriptService },
	["Shared"] = { ReplicatedStorage, Chat, Geometry },
}
Loader._Version = {
	["MAJOR"] = 1,
	["MINOR"] = 3,
	["PATCH"] = 0,
}

--[=[
	Loaders settings
	
	Defaults:
	Loader.MaxRetryTime = 5
	Loader.Timeout = 5
	Loader.Filter = false
]=]
Loader.MaxRetryTime = 5
Loader.Timeout = 5
Loader.Filter = false

--[=[
	Safely require a module like the Roblox require function works
	
	@param module ModuleScript -- required module
	@param requirer Instance -- the source script requiring this
	@return table?
	@private
]=]
local function SafeRequire(module: ModuleScript, requirer: Script): any?
	local time = os.clock()
	local event
	event = RunService.Stepped:Connect(function()
		if os.clock() >= time + Loader.Timeout then
			warn(string.format("%s -> %s is taking too long", tostring(requirer), tostring(module)))
			if event then
				event:Disconnect()
				event = nil
			end
		end
	end)

	local loaded
	local success, response = pcall(function()
		loaded = require(module)
	end)

	if not success then
		if type(loaded) == "nil" and string.find(response, "exactly one value") then
			error("Module did not return exactly one value: " .. module:GetFullName(), 3)
		else
			error(
				"Module " .. module:GetFullName() .. " experienced an error while loading: " .. response,
				3
			)
		end
	end

	if event then
		event:Disconnect()
		event = nil
	end

	return loaded
end

--[=[
	Deep search a list for a specific name
	
	@param name string -- the name of the module
	@param list table -- the list of instances to filter
	@return ModuleScript?
	@private
]=]
local function DeepSearch(name: string, list: table): ModuleScript?
	for _, asset in ipairs(list) do
		if not asset:IsA("ModuleScript") then
			continue
		end
		if Loader.Filter and asset.Parent:IsA("ModuleScript") then
			continue
		end

		if string.lower(asset.Name) == name then
			return asset
		end
	end

	return nil
end

--[=[
	The internal require function which searches the built-in library & all containers per-environment
	
	@param module string | number | ModuleScript -- the module to require
	@param requirer Script -- the script that required this function to simulate require()
	@return table?
	@private
	@outline ___require
]=]
function Loader.__require(module: ModuleScript | string | number, requirer: Script): any?
	local clock = os.clock()
	local name = string.lower(typeof(module) == "Instance" and module.Name or module)

	if Loader._ModuleCache[name] then
		return Loader._ModuleCache[name]
	end

	if typeof(module) == "number" or typeof(module) == "Instance" then
		Loader._ModuleCache[name] = require(module)
		return Loader._ModuleCache[name]
	end

	while not Loader._ModuleCache[name] and os.clock() - clock < Loader.MaxRetryTime do
		local libModule = DeepSearch(name, script:GetChildren())
		if libModule then
			Loader._ModuleCache[name] = SafeRequire(libModule, requirer)
			return Loader._ModuleCache[name]
		end

		for _, service in pairs(Loader._Services.Shared) do
			local sharedModule = DeepSearch(name, service:GetDescendants())

			if sharedModule then
				Loader._ModuleCache[name] = SafeRequire(sharedModule, requirer)
				return Loader._ModuleCache[name]
			end
		end

		if IsClient then
			local response = Loader.__client(module, requirer, true)

			if response then
				return Loader._ModuleCache[name]
			end
		elseif IsServer then
			local response = Loader.__server(module, requirer)

			if response then
				return Loader._ModuleCache[name]
			end

			break
		end

		RunService.Heartbeat:Wait()
	end

	assert(
		Loader._ModuleCache[name],
		"attempted to require a non-existant module: '" .. name .. "'"
	)
	return Loader._ModuleCache[name]
end

--[=[
	The internal require function for filtering the server containers
	
	@param module string | number | ModuleScript -- the module to require
	@param requirer Instance -- the script that required this function to simulate require()
	@return RequiredModule?
	@private
	@outline ___server
]=]
function Loader.__server(module: ModuleScript | numnber | string, requirer: Script): any?
	local name = string.lower(typeof(module) == "Instance" and module.Name or module)

	if Loader._ModuleCache[name] then
		return Loader._ModuleCache[name]
	end

	for _, service in pairs(Loader._Services.Server) do
		local serverModule = DeepSearch(name, service:GetDescendants())

		if serverModule then
			Loader._ModuleCache[name] = SafeRequire(serverModule, requirer)
			return Loader._ModuleCache[name]
		end
	end

	return Loader._ModuleCache[name]
end

--[=[
	The internal require function for filtering the client containers
	
	@param module string | ModuleScript -- the module to require
	@param requirer Instance -- the script that required this function to simulate require()
	@return RequiredModule?
	@private
	@outline ___client
]=]
function Loader.__client(module: ModuleScript | string, requirer: Script, __disabled: boolean?): any?
	local clock = os.clock()
	local name = string.lower(typeof(module) == "Instance" and module.Name or module)

	if Loader._ModuleCache[name] then
		return Loader._ModuleCache[name]
	end

	while not Loader._ModuleCache[name] and os.clock() - clock < Loader.MaxRetryTime do
		local player = Players.LocalPlayer

		for _, container in pairs(player:GetChildren()) do
			if not table.find(Loader._Containers, container.Name) then
				continue
			end

			local clientModule = DeepSearch(name, container:GetDescendants())

			if clientModule then
				Loader._ModuleCache[name] = SafeRequire(clientModule, requirer)
				return Loader._ModuleCache[name]
			end
		end

		for _, service in pairs(Loader._Services.Client) do
			local clientModule = DeepSearch(name, service:GetDescendants())

			if clientModule then
				Loader._ModuleCache[name] = SafeRequire(clientModule, requirer)
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
	@outline require
]=]
function Loader.require(module: ModuleScript | string | number): any?
	local requirer = getfenv(2).script
	return Loader.__require(module, requirer)
end

--[=[
	Require a module instance or search server containers for a module with a string
	
	@param module string | number | ModuleScript -- the module type to require
	@return RequiredModule?
	@outline server
]=]
function Loader.server(module: ModuleScript | string | number): any?
	assert(IsServer, "Attempted to access .server from the client")

	local requirer = getfenv(2).script
	return Loader.__server(module, requirer)
end

--[=[
	Require a module instance or search client containers for a module with a string
	
	@param module string | ModuleScript -- the module type to require
	@return RequiredModule?
	@outline client
]=]
function Loader.client(module: ModuleScript | string): any?
	assert(IsClient, "Attempted to access .client from the server")

	local requirer = getfenv(2).script
	return Loader.__client(module, requirer)
end

--[=[
	Create a custom enum library on 'shared'
	
	@param name string -- the name & index of the enum
	@param members table -- list of all the enum members
	@return table
	@outline enum
]=]
function Loader.enum(name: string, members: table): table
	assert(shared[name] == nil, "Error claiming enum '" .. name .. "': already claimed")

	local proxy = {}

	for _, enum in ipairs(members) do
		proxy[enum] = enum
	end

	shared[name] = proxy
	return shared[name]
end

--[=[
	Replace the require function by Roblox
	
	@param module string | number | Instance -- the module type to require
	@return table?
	@outline __call
]=]
function Loader:__call(module: ModuleScript | string | number): table?
	local requirer = getfenv(2).script
	return Loader.__require(module, requirer)
end

--[=[
	Provides the Loader version when called tostring()
	
	@return FormattedVersion
	@outline __tostring
]=]
function Loader:__tostring(): string
	return "Loader " .. Loader.__version()
end

--[=[
	Returns the current version of Loader
	
	@return FormattedVersion
	@outline __version
]=]
function Loader.__version(): string
	return string.format(
		"v%d.%d.%d",
		Loader._Version.MAJOR,
		Loader._Version.MINOR,
		Loader._Version.PATCH
	)
end
Loader.VERSION = Loader.__version()

do
	if not shared.Loader and (not IsStudio or (IsStudio and IsServer)) then
		Loader.enum("Loader", { "Initialized" })
		print("Loader initialized", "|", Loader.VERSION)
	end

	if IsClient and not IsStudio then
		while not game:IsLoaded() do
			game.Loaded:Wait()
		end
	end
end

return setmetatable(Loader, Loader)
