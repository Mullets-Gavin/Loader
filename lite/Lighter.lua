--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Lighter, a lite variant of Loader, a Roblox Luau Library Loader by Mullet Mafia Dev
	@Notes: Lighter has the bare basics for requiring modules with a lazy-load string method
]=]

--[=[
[DOCUMENTATION]:
	https://github.com/Mullets-Gavin/Loader/tree/master/lite
	Listed below is a quick glance on the API, visit the link above for proper documentation.
	
	Lighter(module)
	Lighter.require(module)
	Lighter.VERSION()
	
[OUTLINE]:
	Lighter
	├─ .__require(module,requirer)
	│  ├─ if instance, requires the module & caches it
	│  └─ if string, searches the following:
	│     └─ deep search the parent container
	├─ Lighter(module) | .require(module)
	│  └─ Redirects & returns __require()
	├─ .__version() and .VERSION Returns the current version
	└─ :__call redirects to .require
	
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

local RunService = game:GetService('RunService')

local IsStudio = RunService:IsStudio() and 'Studio'
local IsClient = RunService:IsClient() and 'Client'

local Lighter = {}
Lighter.__index = Lighter
Lighter._ModuleCache = {}
Lighter._Initialized = false
Lighter._Name = string.upper(script.Name)
Lighter._Container = script.Parent
Lighter._Version = {
	['MAJOR'] = 1;
	['MINOR'] = 0;
	['PATCH'] = 0;
}

--[=[
	Lighters settings
	
	Defaults:
	Lighter.MaxRetryTime = 5
	Lighter.Timeout = 5
	Lighter.Filter = false
]=]
Lighter.MaxRetryTime = 5
Lighter.Timeout = 5
Lighter.Filter = false

--[=[
	Safely require a module like the Roblox require function works
	
	@param module Instance -- required module
	@param requirer Instance -- the source script requiring this
	@return table?
	@private
]=]
local function SafeRequire(module: ModuleScript, requirer: Script): table?
	local time = os.clock()
	local event; event = RunService.Stepped:Connect(function()
		if os.clock() >= time + Lighter.Timeout then
			warn(string.format('%s -> %s is taking too long',tostring(requirer),tostring(module)))
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
			error("Module did not return exactly one value: " .. module:GetFullName(), 3)
		else
			error("Module " .. module:GetFullName() .. " experienced an error while loading: " .. response, 3)
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
	for count,asset in ipairs(list) do
		if not asset:IsA('ModuleScript') then continue end
		if Lighter.Filter and asset.Parent:IsA('ModuleScript') then continue end
		
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
]=]
function Lighter.__require(module: ModuleScript, requirer: Script): table?
	local clock = os.clock()
	local name = string.lower(typeof(module) == 'Instance' and module.Name or module)
	
	if Lighter._ModuleCache[name] then
		return Lighter._ModuleCache[name]
	end
	
	if typeof(module) == 'number' or typeof(module) == 'Instance' then
		Lighter._ModuleCache[name] = require(module)
		return Lighter._ModuleCache[name]
	end
	
	while not Lighter._ModuleCache[name] and os.clock() - clock < Lighter.MaxRetryTime do
		local asset = DeepSearch(name,Lighter._Container:GetDescendants())
		if asset then
			Lighter._ModuleCache[name] = SafeRequire(asset,requirer)
			return Lighter._ModuleCache[name]
		end
		
		RunService.Heartbeat:Wait()
	end
	
	assert(Lighter._ModuleCache[name],"attempted to require a non-existant module: '"..name.."'")
	return Lighter._ModuleCache[name]
end

--[=[
	Require a module instance or search containers for a module with a string
	
	@param module string | number | Instance -- the module type to require
	@return RequiredModule?
]=]
function Lighter.require(module: ModuleScript | string | number): table?
	local requirer = getfenv(2).script	
	return Lighter.__require(module,requirer)
end

--[=[
	Replace the require function by Roblox
	
	@param module string | number | Instance -- the module type to require
	@return table?
]=]
function Lighter:__call(module: ModuleScript | string | number): table?
	local requirer = getfenv(2).script	
	return Lighter.__require(module,requirer)
end

--[=[
	Provides the Lighter version when called tostring()
	
	@return FormattedVersion
]=]
function Lighter:__tostring(): string
	return 'Lighter '..Lighter.__version()
end

--[=[
	Returns the current version of Lighter
	
	@return FormattedVersion
]=]
function Lighter.__version(): string
	return string.format('v%d.%d.%d',
		Lighter._Version.MAJOR,
		Lighter._Version.MINOR,
		Lighter._Version.PATCH
	)
end
Lighter.VERSION = Lighter.__version()

return setmetatable(Lighter,Lighter)