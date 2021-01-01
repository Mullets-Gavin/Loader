local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local Player = require("player")
local DataSync = require("DataSync")

local Store = DataSync.GetStore("___tests___", {
	["Number"] = 0,
	["Boolean"] = true,
	["Table"] = { "1", "2", "3" },
	["Dictionary"] = {
		["a"] = "x",
		["b"] = "y",
		["c"] = "z",
	},
})

local Cache = {}

return {
	["ParameterGenerator"] = function()
		local plr
		repeat
			plr = Player.generate(1)
		until not table.find(Cache, plr.UserId)
		table.insert(Cache, plr.UserId)

		local file = Store:GetFile(plr.UserId)
		local data = {
			["number"] = math.random(1, 100),
			["boolean"] = math.random() > 0.5 and true or false,
			["value"] = string.char(math.random(100, 122)),
		}

		return plr, file, data
	end,

	["Functions"] = {
		["add"] = function(profiler, plr, file, data)
			local result = file:IncrementData("Number", data.number):GetData("Number")
			assert(typeof(result) == "number", "Failed to add number, got '" .. typeof(result) .. "'")
		end,

		["subtract"] = function(profiler, plr, file, data)
			local result = file:IncrementData("Number", -data.number):GetData("Number")
			assert(
				typeof(result) == "number",
				"Failed to subtract number, got '" .. typeof(result) .. "'"
			)
		end,

		["boolean"] = function(profiler, plr, file, data)
			local result = file:UpdateData("Boolean", data.boolean):GetData("Boolean")
			assert(typeof(result) == "boolean", "Failed to set boolean, got '" .. typeof(result) .. "'")
		end,

		["table"] = function(profiler, plr, file, data)
			local get = file:GetData("Table")
			table.insert(get, data.value)

			local result = file:UpdateData("Table", get):GetData("Table")
			assert(typeof(result) == "table", "Failed to set table, got '" .. typeof(result) .. "'")
		end,

		["dictionary"] = function(profiler, plr, file, data)
			local get = file:GetData("Dictionary")
			get[data.value] = data.number

			local result = file:UpdateData("Dictionary", get):GetData("Dictionary")
			assert(typeof(result) == "table", "Failed to set dictionary, got '" .. typeof(result) .. "'")
		end,

		["save"] = function(profiler, plr, file, data)
			local saved = file:SaveData()
			assert(saved, "Failed to save file")
		end,

		["remove"] = function(profiler, plr, file, data)
			local remove = file:RemoveData()
			assert(getmetatable(remove) == nil, "Failed to destroy file")
		end,

		["complete"] = function(profiler, plr, file, data)
			local result = file:IncrementData("Number", data.number):UpdateData("Boolean", data.boolean):IncrementData("Number", -data.number):UpdateData("Table", table.insert(file:GetData("Table"), data.value)):RemoveData()
			assert(
				typeof(result) == "table" and getmetatable(result) == nil,
				"Failed to run a complete session"
			)
		end,
	},
}
