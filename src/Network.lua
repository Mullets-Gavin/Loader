--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: A networking wrapper for Roblox client to server or environment to environment
]=]

--[=[
[DOCUMENTATION]:
	.CreateEvent()
	.CreateFunction()
	.CreateBindable()
	
	:HookEvent()
	:HookFunction()
	:UnhookEvent()
	:UnhookFunction()
	
	.FireServer()
	.FireClient()
	.FireClients()
	.FireAllClients()
	
	:InvokeServer()
	:InvokeClient()
	:InvokeAllClients()
	
	:BindEvent()
	:BindFunction()
	:UnbindEvent()
	:UnbindFunction()
	
	.FireBindable()
	:InvokeBindable()
	
[OUTLINE]:
	Network
	├─ GetRemote()
	├─ GetBindable()
	├─ .CreateEvent(name)
	├─ .CreateFunction(name)
	├─ .CreateBindableEvent(name)
	├─ .CreateBindableFunction(name)
	├─ :HookEvent(name,code)
	├─ :UnhookEvent(name)
	├─ :HookFunction(name,code)
	├─ :UnhookFunction(name)
	├─ .FireServer(name,...)
	├─ .FireClient(name,player,...)
	├─ .FireClients(name,clients,...)
	├─ .FireAllClients(name,...)
	├─ .FireAllClientsExcept(name,player,...)
	├─ :InvokeServer(name,...)
	├─ :InvokeClient(name,player,...)
	├─ :InvokeAllClients(name,timeout,...)
	├─ :BindEvent(name,code)
	├─ :UnbindEvent(name)
	├─ :BindFunction(name,code)
	├─ :UnbindFunction(name)
	├─ .FireBindable(name,...)
	└─ :InvokeBindable(name,...)

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

local Network = {}
Network._Events = {}
Network._Functions = {}
Network._Bindables = {}
Network._Invocables = {}
Network._Name = string.upper(script.Name)
Network.Enums = {
	["Event"] = 1,
	["Function"] = 2,
}

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local Manager = require("Manager")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Container = ReplicatedStorage:FindFirstChild(Network._Name .. "_FOLDER")
do
	if Manager.IsServer and not Container then
		local Folder = Instance.new("Folder")
		Folder.Name = Network._Name .. "_FOLDER"
		Folder.Archivable = false
		Folder.Parent = ReplicatedStorage
		Container = Folder
	elseif not Container then
		Container = ReplicatedStorage:WaitForChild(Network._Name .. "_FOLDER")
	end
end

--[=[
	Get a remote or create one if server
	
	@param name string -- the name of the remote
	@param enum NetworkEnum -- the network enum of the remote
	@return Remote
	@private
]=]
local function GetRemote(name: string, enum: number): Instance?
	name = tostring(name) .. "_Remote"

	if Manager.IsServer then
		local remote = Container:FindFirstChild(name)

		if not remote then
			local new
			do
				if enum == Network.Enums.Event then
					new = Network.CreateEvent(name)
				elseif enum == Network.Enums.Function then
					new = Network.CreateFunction(name)
				end
			end
			remote = new
		end

		return remote
	elseif Manager.IsClient then
		local remote = Container:WaitForChild(name, 3)
		assert(remote ~= nil, name)
		return remote
	end
end

--[=[
	Get a bindable or create one
	
	@param name string -- the name of the bindable
	@param enum NetworkEnum -- the network enum of the bindable
	@return Bindable
	@private
]=]
local function GetBindable(name: string, enum: number): Instance?
	name = name .. "_Bindable"

	if enum then
		local bindable = Container:FindFirstChild(name)

		if not bindable then
			local new
			do
				if enum == Network.Enums.Event then
					new = Network.CreateBindableEvent(name)
				elseif enum == Network.Enums.Function then
					new = Network.CreateBindableFunction(name)
				end
			end
			bindable = new
		end

		return bindable
	else
		local bindable = Container:WaitForChild(name, 3)
		assert(bindable ~= nil, name)
		return bindable
	end
end

--[=[
	Create a Remote event
	
	@param name string -- the name of the remote
	@return RemoteEvent
	@outline CreateEvent
]=]
function Network.CreateEvent(name: string): RemoteEvent
	if not string.find(name, "_Remote") then
		name = name .. "_Remote"
	end

	local remote = Container:FindFirstChild(name)
	if not remote then
		local new = Instance.new("RemoteEvent")
		new.Name = name
		new.Parent = Container
		remote = new
	end

	return remote
end

--[=[
	Create a Remote function
	
	@param name string -- the name of the remote
	@return RemoteFunction
	@outline CreateFunction
]=]
function Network.CreateFunction(name: string): RemoteFunction
	if not string.find(name, "_Remote") then
		name = name .. "_Remote"
	end

	local remote = Container:FindFirstChild(name)
	if not remote then
		local new = Instance.new("RemoteFunction")
		new.Name = name
		new.Parent = Container
		remote = new
	end

	return remote
end

--[=[
	Create a Bindable event
	
	@param name string -- the name of the bindable
	@return BindableEvent
	@outline CreateBindableEvent
]=]
function Network.CreateBindableEvent(name: string): BindableEvent
	if not string.find(name, "_Bindable") then
		name = name .. "_Bindable"
	end

	local bindable = Container:FindFirstChild(name)
	if not bindable then
		local new = Instance.new("BindableEvent")
		new.Name = name
		new.Parent = Container
		bindable = new
	end

	return bindable
end

--[=[
	Create a Bindable function
	
	@param name string -- the name of the bindable
	@return BindableFunction
	@outline CreateBindableFunction
]=]
function Network.CreateBindableFunction(name: string): BindableFunction
	if not string.find(name, "_Bindable") then
		name = name .. "_Bindable"
	end

	local bindable = Container:FindFirstChild(name)
	if not bindable then
		local new = Instance.new("BindableFunction")
		new.Name = name
		new.Parent = Container
		bindable = new
	end

	return bindable
end

--[=[
	Hook a function to a RemoteEvent
	
	@oaram name string -- the name of the remote
	@param code function -- the function to hook
	@return RemoteEvent
	@outline HookEvent
]=]
function Network:HookEvent(name: string, code: (any) -> nil): RemoteEvent
	local remote = GetRemote(name, Network.Enums.Event)
	local event = Manager.IsClient and remote.OnClientEvent or remote.OnServerEvent
	local connection = event:Connect(function(...)
		code(...)
	end)

	Network._Events[name] = connection

	return remote
end

--[=[
	Unhook a RemoteEvent
	
	@oaram name string -- the name of the remote
	@return boolean
	@outline UnhookEvent
]=]
function Network:UnhookEvent(name: string): boolean
	local connection = Network._Events[name]
	if connection then
		connection:Disconnect()
		return true
	end

	return false
end

--[=[
	Hook a function to a RemoteFunction
	
	@oaram name string -- the name of the remote
	@param code function -- the function to hook
	@return RemoteFunction
	@outline HookFunction
]=]
function Network:HookFunction(name: string, code: (any) -> nil): RemoteFunction
	local remote = GetRemote(name, Network.Enums.Function)
	local callbackKey = Manager.IsClient and "OnClientInvoke" or "OnServerInvoke"
	remote[callbackKey] = code
	Network._Functions[name] = remote

	return remote
end

--[=[
	Unhook a RemoteFunction
	
	@param name string -- the name of the remote
	@return boolean
	@outline UnhookFunction
]=]
function Network:UnhookFunction(name: string): boolean
	local connection = Network._Functions[name]
	if connection then
		local callbackKey = Manager.IsClient and "OnClientInvoke" or "OnServerInvoke"
		connection[callbackKey] = nil
		return true
	end

	return false
end

--[=[
	Fire a RemoteEvent from the client to the server
	
	@param name string -- the name of the remote
	@param ...? any -- extra parameters to pass
	@return nil
	@outline FireServer
]=]
function Network.FireServer(name: string, ...): nil
	assert(Manager.IsClient, "Attempted to call 'FireServer' on server")

	local remote = GetRemote(name, Network.Enums.Event)
	remote:FireServer(...)
end

--[=[
	Fire a RemoteEvent from the server to the client
	
	@param name string -- the name of the remote
	@param player Instance -- the player Instance to send to
	@param ...? any -- extra parameters to pass
	@return nil
	@outline FireClient
]=]
function Network.FireClient(name: string, player: Player, ...): nil
	assert(Manager.IsServer, "Attempted to call 'FireClient' on client")

	local remote = GetRemote(name, Network.Enums.Event)
	remote:FireClient(player, ...)
end

--[=[
	Fire a RemoteEvent from the server to multiple clients
	
	@param name string -- the name of the remote
	@param clients table -- a table of player Instances to send to
	@param ...? any -- extra parameters to pass
	@return nil
	@outline FireClients
]=]
function Network.FireClients(name: string, clients: table, ...): nil
	assert(Manager.IsServer, "Attempted to call 'FireClients' on client")

	for _, player in pairs(clients) do
		assert(typeof(player) == "Instance" and player:IsA("Player"))

		local remote = GetRemote(name, Network.Enums.Event)
		remote:FireClient(player, ...)
	end
end

--[=[
	Fire a RemoteEvent from the server to all clients
	
	@param name string -- the name of the remote
	@param ...? any -- extra parameters to pass
	@return nil
	@outline FireAllClients
]=]
function Network.FireAllClients(name: string, ...): nil
	assert(Manager.IsServer, "Attempted to call 'FireAllClients' on client")

	local remote = GetRemote(name, Network.Enums.Event)
	remote:FireAllClients(...)
end

--[=[
	Fire a RemoteEvent from the server to all clients except a specified player
	
	@param name string -- the name of the remote
	@param player Instance -- ignore this player
	@param ...? any -- extra parameters to pass
	@return nil
	@outline FireAllClientsExcept
]=]
function Network.FireAllClientsExcept(name: string, player: Player, ...): nil
	assert(Manager.IsServer, "Attempted to call 'FireAllClientsExcept' on client")

	local remote = GetRemote(name, Network.Enums.Event)
	for _, client in pairs(Players:GetPlayers()) do
		if client == player then
			continue
		end
		remote:FireClient(client, ...)
	end
end

--[=[
	Invoke the server from the client
	
	@param name string -- the name of the remote
	@param ...? any -- extra parameters to pass
	@return any?
	@outline InvokeServer
]=]
function Network:InvokeServer(name: string, ...): any?
	assert(Manager.IsClient, "Attempted to invoke the server on the server")

	local remote = GetRemote(name)
	return remote:InvokeServer(...)
end

--[=[
	!WARNING! This is NOT recommended & not common; revisit your code before you do this.
	Invoke the client from the server
	
	@param name string -- the name of the remote
	@param ...? any -- extra parameters to pass
	@return any?
	@outline InvokeClient
]=]
function Network:InvokeClient(name: string, player: Player, ...): any?
	assert(Manager.IsServer, "Attempted to invoke the client on the client")

	local data = { ... }
	local remote = GetRemote(name)

	local success, response = pcall(function()
		return remote:InvokeClient(player, table.unpack(data))
	end)

	if success then
		return response
	end

	return success
end

--[=[
	!WARNING! This is NOT recommended & not common; revisit your code before you do this.
	Invoke all the clients from the server with a timeout
	
	@param name string -- the name of the remote
	@param timeout number -- how long before a timeout
	@param ...? any -- extra parameters to pass
	@return table
	@outline InvokeAllClients
]=]
function Network:InvokeAllClients(name: string, timeout: number, ...): table
	assert(Manager.IsServer, "Attempted to invoke all clients on the client")

	local remote = GetRemote(name)
	local clock = os.clock()
	local count = 0
	local max = #Players:GetPlayers()
	local data = { ... }
	local proxy = {}

	for _, player in pairs(Players:GetPlayers()) do
		Manager.Spawn(function()
			local response = remote:InvokeClient(player, data)
			if response then
				proxy[player] = response
				count += 1
			end
		end)
	end

	while count < max and os.clock() - clock < timeout do
		Manager.Wait()
	end

	return proxy
end

--[=[
	Bind a function the a BindableEvent
	
	@param name string -- name of the Bindable
	@param code function -- the function to bind
	@return BindableEvent
	@outline BindEvent
]=]
function Network:BindEvent(name: string, code: (any) -> nil): BindableEvent
	local bindable = GetBindable(name, Network.Enums.Event)
	local event = bindable.Event
	local connection = event:Connect(function(...)
		code(...)
	end)

	Network._Bindables[name] = connection

	return bindable
end

--[=[
	Unbind a BindableEvent
	
	@param name string -- the name of the bindable
	@return boolean
	@outline UnbindEvent
]=]
function Network:UnbindEvent(name: string): boolean
	local connection = Network._Bindables[name]
	if connection then
		connection:Disconnect()
		return true
	end

	return false
end

--[=[
	Bind a function the a BindableFunction
	
	@param name string -- name of the bindable
	@param code function -- the function to bind
	@return BindableFunction
	@outline BindFunction
]=]
function Network:BindFunction(name: string, code: (any) -> nil): BindableFunction
	local bindable = GetBindable(name, Network.Enums.Function)
	bindable.OnInvoke = code
	Network._Invocables[name] = bindable

	return bindable
end

--[=[
	Unbind a BindableFunction
	
	@param name string -- the name of the bindable
	@return boolean
	@outline UnbindFunction
]=]
function Network:UnbindFunction(name: string): boolean
	local connection = Network._Invocables[name]
	if connection then
		connection.OnInvoke = nil
		return true
	end

	return false
end

--[=[
	Fire a BindableEvent
	
	@param name string -- the name of the bindable
	@param ...? any -- extra parameters to pass
	@return nil
	@outline FireBindable
]=]
function Network.FireBindable(name: string, ...): nil
	local bindable = GetBindable(name, Network.Enums.Event)
	bindable:Fire(...)
end

--[=[
	Invoke a BindableFunction
	
	@param name string -- the name of the bindable
	@param ...? any -- extra parameters to pass
	@return any?
	@outline InvokeBindable
]=]
function Network:InvokeBindable(name: string, ...): any?
	local bindable = GetBindable(name, Network.Enums.Function)
	return bindable:Invoke(...)
end

return Network
