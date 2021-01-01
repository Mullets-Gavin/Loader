local Loader = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local UserId = Loader("userid")

local LibList = { "DataSync", "Interface", "Manager", "Network", "Roblox" }
local Cache = {}

return {
	["ParameterGenerator"] = function()
		local lib = LibList[math.random(1, #LibList)]
		local enums = {
			["list"] = { lib },
		}
		repeat
			enums["name"] = tostring(UserId[math.random(1, #UserId)])
		until not table.find(Cache, enums["name"])
		table.insert(Cache, enums["name"])

		return lib, enums
	end,

	["Functions"] = {
		["library"] = function(profiler, lib)
			local result = Loader(lib)
			assert(result ~= nil, "Library module failed")
		end,

		["require"] = function(profiler, lib)
			local result = Loader(1936396537)
			assert(result ~= nil, "Require module failed")
		end,

		["string"] = function(profiler, lib)
			local result = Loader("player")
			assert(result ~= nil, "Require module failed")
		end,

		["enumerator"] = function(profiler, lib, enums)
			local result = Loader.enum(enums.name, enums.list)
			assert(shared[enums.name] ~= nil, "Failed to set enumerator")
		end,
	},
}
