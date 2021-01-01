local Loader = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local Player = Loader("player")
local Network = Loader("Network")

return {
	["ParameterGenerator"] = function()
		local plr = Player.generate(1)
		return plr
	end,

	["Functions"] = {
		["fire event"] = function(profiler, plr)
			Network:FireAllClients("BRENCHMRK_FIRE", plr)
		end,

		["fire bindable"] = function(profiler, plr)
			Network:FireBindable("BRENCHMRK_FIRE", plr)
		end,

		["create event"] = function(profiler, plr)
			local result = Network.CreateEvent("BENCHMARK_CREATE")
			assert(
				typeof(result) == "Instance" and result:IsA("RemoteEvent"),
				"Failed to create RemoteEvent"
			)
		end,

		["create bindable"] = function(profiler, plr)
			local result = Network.CreateBindableEvent("BENCHMARK_CREATE")
			assert(
				typeof(result) == "Instance" and result:IsA("BindableEvent"),
				"Failed to create BindableEvent"
			)
		end,

		["hook event"] = function(profiler, plr)
			local result
			result = Network:HookEvent("BENCHMARK_EVENT", function()
				Network:UnhookEvent("BENCHMARK_EVENT")
			end)
			assert(
				typeof(result) == "Instance" and result:IsA("RemoteEvent"),
				"Failed to hook RemoteEvent"
			)
		end,

		["bind event"] = function(profiler, plr)
			local result = Network:BindEvent("BENCHMARK_EVENT", function()
				Network:UnbindEvent("BENCHMARK_EVENT")
			end)
			assert(
				typeof(result) == "Instance" and result:IsA("BindableEvent"),
				"Failed to hook BindableEvent"
			)
		end,

		["pipeline"] = function(profiler, plr)
			local result
			result = Network:BindEvent("BENCHMARK_BINDABLE", function()
				result = nil
			end)
			assert(
				typeof(result) == "Instance" and result:IsA("BindableEvent"),
				"Failed to connect event"
			)

			Network:FireBindable("BENCHMARK_BINDABLE")
		end,

		["connection"] = function(profiler, plr)
			local result = Network:HookEvent("BENCHMARK_HOOK", function()
				print("Anonymous function")
			end)
			assert(result, "Failed to hook event")

			result = Network:UnhookEvent("BENCHMARK_HOOK")
			assert(result, "Failed to unhook event")
		end,

		["invocation"] = function(profiler, plr)
			local event = Network:BindFunction("BENCHMARK_INVOKE", function()
				Network:UnbindFunction("BENCHMARK_INVOKE")
				return true
			end)
			assert(event, "Failed to bind function")

			local result = Network:InvokeBindable("BENCHMARK_INVOKE")
			assert(result and typeof(result) == "boolean", "Failed to invoke BindableFunction")
		end,
	},
}
