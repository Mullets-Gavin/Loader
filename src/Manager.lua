--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: A manager for Luau with a large library of functions & methods
]=]

--[=[
[DOCUMENTATION]:
	https://github.com/Mullets-Gavin/Manager
	Listed below is a quick glance on the API, visit the link above for proper documentation.
	
	Manager.Wait(time)
	Manager.Set(dictionary)
	Manager.Wrap(function,...)
	Manager.Spawn(function,...)
	Manager.Garbage(time,instance)
	Manager.Delay(time,function,...)
	Manager.Retry(time,function,...)
	Manager.Rerun(tries,function,...)
	Manager.Debounce(key,function,...)
	Manager.Debug(label)
	Manager.Round(number[,decimal])
	
	Manager.FormatCounter(number,decimal)
	Manager.FormatValue(number)
	Manager.FormatMoney(number)
	Manager.FormatClock(number)
	Manager.Format24H(number)
	Manager.FormatDate(number)
	
	Manager.Tween(object,properties,goals[,duration,style,direction])
	Manager.Copy(table)
	Manager.DeepCopy(table)
	Manager.Shuffle(table)
	Manager.Encode(any)
	Manager.Decode(encodedText)
	
	event = Manager.Connect(function)
	event:Disconnect()
	event:Fire(...)
	
	event = Manager.ConnectKey(key,function)
	event:Disconnect()
	event:Fire(...)
	
	Manager.FireKey(key,...)
	Manager.DisconnectKey(key)
	
	event = Manager.Task([fps])
	event:Queue(function)
	event:Pause()
	event:Resume()
	event:Wait()
	event:Enabled()
	event:Disconnect()
	
[OUTLINE]:
	Manager
	├─ .Set(properties)
	├─ .Wait(clock)
	├─ .Wrap(function,...)
	├─ .Spawn(function,...)
	├─ .Delay(time,function,...)
	├─ .Garbage(time,instance)
	├─ .Retry(time,function,...)
	├─ .Rerun(tries,function,...)
	├─ .Debounce(key,function,...)
	├─ .Debug(label)
	├─ .Round(number[,decimal])
	├─ .FormatCounter(number,decimal)
	├─ .FormatValue(number)
	├─ .FormatMoney(number)
	├─ .FormatClock(number)
	├─ .Format24H(number)
	├─ .FormatDate(number)
	├─ .Tween(object,properties,goals[,duration,style,direction])
	├─ .Copy(table)
	├─ .DeepCopy(table)
	├─ .Shuffle(table)
	├─ .Encode(any)
	├─ .Decode(encodedText)
	├─ :FireKey(key,...)
	├─ :DisconnectKey(key)
	├─ :Connect(function)
	│  ├─ :Fire(...)
	│  └─ :Disconnect()
	├─ :ConnectKey(key,function)
	│  ├─ :Fire(...)
	│  └─ :Disconnect()
	└─ :Task([fps])
	   ├─ :Queue(function)
	   ├─ :Pause()
	   ├─ :Resume()
	   ├─ :Wait()
	   ├─ :Enabled()
	   └─ :Disconnect()
	
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

local Manager = {}
Manager._Connections = {}
Manager._Timers = {}
Manager._Bouncers = {}
Manager._LastIteration = nil
Manager._Name = string.upper(script.Name)

local Compression = {}
Compression.Dictionary = {}
Compression.EscapeMap = {}
Compression.Length = 0

local Numbers = {}
Numbers.Suffixes = {
	"k", "M", "B", "T", "qd", "Qn", "sx", "Sp", "O", "N", "de",
	"Ud", "DD", "tdD", "qdD", "QnD", "sxD", "SpD", "OcD", "NvD",
	"Vgn", "UVg", "DVg", "TVg", "qtV", "QnV", "SeV", "SPG", "OVG",
	"NVG", "TGN", "UTG", "DTG", "tsTG", "qtTG", "QnTG", "ssTG",
	"SpTG", "OcTG", "NoTG", "QdDR", "uQDR", "dQDR", "tQDR", "qdQDR",
	"QnQDR", "sxQDR", "SpQDR", "OQDDr", "NQDDr", "qQGNT", "uQGNT",
	"dQGNT", "tQGNT", "qdQGNT", "QnQGNT", "sxQGNT", "SpQGNT",
	"OQQGNT", "NQQGNT", "SXGNTL"
}

local Settings = {}
Settings.Debug = false
Settings.RunService = "Stepped"

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

Manager.IsStudio = RunService:IsStudio() and "Studio"
Manager.IsServer = RunService:IsServer() and "Server"
Manager.IsClient = RunService:IsClient() and "Client"

--[=[
	Set the internal settings of Manager with a dictionary
	
	@param properties table -- a dictionary with the settings & boolean
	@return nil
	@outline Set
]=]
function Manager.Set(properties: table): nil
	Settings.Debug = properties["Debug"] or false
	Settings.RunService = properties["RunService"] or "Stepped"
end

--[=[
	Wait a frame or a given number of seconds near 100% accuracy
	
	@param clock? number -- provide a time you want to wait for
	@return delta
	@outline Wait
]=]
function Manager.Wait(clock: number?): number
	clock = clock or 0

	local start = os.clock()
	local delta = 0
	repeat
		delta += RunService[Settings.RunService]:Wait()
	until delta >= clock

	return os.clock() - start
end

--[=[
	Wrap a function with a coroutine and report custom errors
	
	@param code function -- the function to wrap
	@param ...? any -- optional parameters to pass in the function
	@return nil
	@outline Wrap
]=]
function Manager.Wrap(code: (any) -> nil, ...): nil
	local thread = coroutine.create(code)
	local ran, response = coroutine.resume(thread, ...)

	if not ran then
		local trace = debug.traceback(thread)
		error(response .. "\n" .. trace, 2)
	end
end

--[=[
	Supress errors with a similar call to wrap without error reporting
	
	@param code function -- the function to spawn
	@param ...? any -- optional parameters to pass in the function
	@return nil
	@outline Spawn
]=]
function Manager.Spawn(code: (any) -> nil, ...): nil
	coroutine.resume(coroutine.create(code), ...)
end

--[=[
	Create an infinite loop at a 60fps
	
	@param code function -- the function to callback
	@param ...? any -- optional parameters to pass in the function
	@return RBXScriptConnection
	@outline Loop
]=]
function Manager.Loop(code: (any) -> nil, ...): RBXScriptConnection
	local data = { ... }
	local rate = 1 / 60
	local logged = 0
	local event
	event = RunService[Settings.RunService]:Connect(function(delta)
		logged = logged + delta

		while logged >= rate do
			logged = logged - rate
			code(table.unpack(data))
		end
	end)

	return event
end

--[=[
	Delay a function for a given number of time
	
	@param clock number -- the time to wait
	@param code function -- the function to callback
	@param ...? any -- optional parameters to pass in the function
	@return nil
	@outline Delay
]=]
function Manager.Delay(clock: number, code: (any) -> nil, ...): nil
	local data = { ... }
	Manager.Wrap(function()
		local current = os.clock()

		while clock > os.clock() - current do
			Manager.Wait()
		end

		code(table.unpack(data))
	end)
end

--[=[
	Delay destroying an Instance for a given number of time
	
	@param clock number -- the time to wait
	@param obj Instance -- the Instance to destroy
	@return nil
	@outline Garbage
]=]
function Manager.Garbage(clock: number, obj: Instance): nil
	Manager.Wrap(function()
		local current = os.clock()

		while clock > os.clock() - current do
			Manager.Wait()
		end

		obj:Destroy()
	end)
end

--[=[
	Retry a function until it succeeds or times out
	
	@param clock number -- time to wait before timeout
	@param code function -- the function to run for success
	@param ...? any -- optional parameters to pass in the function
	@return boolean & (any?)
	@outline Retry
]=]
function Manager.Retry(clock: number, code: (any) -> nil, ...): boolean & (any?)
	local current = os.clock()
	local success, response

	while not success and clock > os.clock() - current do
		success, response = pcall(code, ...)

		if not success then
			Manager.Wait()
		end
	end

	if not success and Settings.Debug then
		warn(response, debug.traceback())
	end

	return success, response
end

--[=[
	Rerun a function until it succeeds or hits the max retry limit provided
	
	@param times number -- how many times to retry
	@param code function -- the function to run for success
	@param ...? any -- optional parameters to pass in the function
	@return boolean & (any?)
	@outline Rerun
]=]
function Manager.Rerun(times: number, code: (any) -> nil, ...): boolean & (any?)
	local current = 0
	local success, response
	repeat
		current += 1
		success, response = pcall(code, ...)

		if not success then
			Manager.Wait()
		end
	until success or current >= times

	if not success and Settings.Debug then
		warn(response, debug.traceback())
	end

	return success, response
end

--[=[
	Debounce a function & return a result if one is provided
	
	@param key string -- the key of the debounce
	@param code function -- the function to wait for
	@return boolean | (any?)
	@outline Debounce
]=]
function Manager.Debounce(key: any, code: (any) -> nil, ...): boolean | (any?)
	if Manager._Bouncers[key] then
		return false
	end
	Manager._Bouncers[key] = true

	local result = code(...)

	Manager._Bouncers[key] = false
	return result
end

--[=[
	A custom debug profiler function which uses time to benchmark
	
	@param label? string -- provide a label to use & track otherwise the requirer script name is used
	@return nil
	@outline Debug
]=]
function Manager.Debug(label: string?): nil
	local backtrace = getfenv(3).script
	label = label or string.lower(backtrace.Name)

	local timer = Manager._Timers[label]
	if not timer then
		timer = os.clock()
	else
		warn(label, "took:", os.clock() - timer .. "ms")
		timer = nil
	end

	Manager._Timers[label] = timer
end

--[=[
	Round a number to the nearest given decimal or return math.round
	
	@param input number -- the input to round
	@param decimal? number -- optional decimal to round to
	@return RoundedNumber
	@outline Round
]=]
function Manager.Round(input: number, decimal: number?): number
	if not decimal then
		return math.round(input)
	end

	return math.floor(input * (10 ^ decimal)) / (10 ^ decimal)
end

--[=[
	Format a number with a decimal
	
	@param input number -- the number to format
	@param decimal number -- how many decimals it should display
	@return FormattedNumber -- 4 -> 4.0
	@outline FormatCounter
]=]
function Manager.FormatCounter(input: number, decimal: number): string
	local format = tostring(input)
	local raw = "%." .. decimal .. "f"

	return string.format(raw, format)
end

--[=[
	Format a number for visuals
	
	@param input number -- the number to format
	@return FormattedNumber -- 4000 -> 4,000
	@outline FormatValue
]=]
function Manager.FormatValue(input: number): string
	local format, remain = tonumber(input)

	while remain ~= 0 do
		format, remain = string.gsub(format, "^(-?%d+)(%d%d%d)", "%1,%2")
	end

	return format
end

--[=[
	Format a number for money
	
	@param input number -- the number to format
	@return FormattedNumber -- 4000 -> 4k
	@outline FormatMoney
]=]
function Manager.FormatMoney(input: number): number | string
	local negative = input < 0
	input = math.abs(input)

	local paired = false
	for index, _ in pairs(Numbers.Suffixes) do
		if not (input >= 10 ^ (3 * index)) then
			input = input / 10 ^ (3 * (index - 1))
			local isComplex = (string.find(tostring(input), ".") and string.sub(tostring(input), 4, 4) ~= ".")
			input = string.sub(tostring(input), 1, (isComplex and 4) or 3) .. (Numbers.Suffixes[index - 1] or "")
			paired = true
			break
		end
	end

	if not paired then
		local Rounded = math.floor(input)
		input = tostring(Rounded)
	end

	if negative then
		return "-" .. input
	end

	return input
end

--[=[
	Format a number for clock time
	
	@param input number -- the number to format
	@return FormattedNumber -- 3000 -> 5:00
	@outline FormatClock
]=]
function Manager.FormatClock(input: number): string
	local seconds = tonumber(input)

	if seconds <= 0 then
		return "0:00"
	else
		local mins = string.format("%01.f", math.floor(seconds / 60))
		local secs = string.format("%02.f", math.floor(seconds - mins * 60))

		return mins .. ":" .. secs
	end
end

--[=[
	Format a number for 24 hour time
	
	@param input number -- the number to format
	@return FormattedNumber -- HH:MM:SS
	@outline Format24H
]=]
function Manager.Format24H(input: number): string
	local seconds = tonumber(input)

	if seconds <= 0 then
		return "00:00:00"
	else
		local hours = string.format("%02.f", math.floor(seconds / 3600))
		local mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)))
		local secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60))

		return hours .. ":" .. mins .. ":" .. secs
	end
end

--[=[
	Format a number for the date
	
	@param input number -- the number to format
	@return FormattedNumber -- DD:HH:MM:SS
	@outline FormatDate
]=]
function Manager.FormatDate(input: number): string
	local days = math.floor(input / 86400)
	local hours = math.floor(math.fmod(input, 86400) / 3600)
	local minutes = math.floor(math.fmod(input, 3600) / 60)
	local seconds = math.floor(math.fmod(input, 60))

	return string.format("%d:%02d:%02d:%02d", days, hours, minutes, seconds)
end

--[=[
	Create and play a tween
	
	@param object Instance -- the instance to tween
	@param properties table -- a list of the properties
	@param goals table | any -- either a list of goals to fit properties, or a single goal
	@param duration? number -- how long the tween lasts
	@param style EnumItem -- an Enum.EasingStyle
	@param direction EnumItem -- an Enum.EasingDirection
	@return TweenObject
	@outline Tween
]=]
function Manager.Tween(object: Instance, properties: table, goals: any | table, duration: number?, style: EnumItem?, direction: EnumItem?): TweenObject
	duration = typeof(duration) == "number" and duration or 0.5
	style = typeof(style) == "EnumItem" and style or Enum.EasingStyle.Linear
	direction = typeof(direction) == "EnumItem" and direction or Enum.EasingDirection.InOut

	local values = {}
	do
		for index, prop in pairs(properties) do
			values[prop] = typeof(goals) == "table" and goals[index] or goals
		end
	end

	local info = TweenInfo.new(duration, style, direction)
	local tween = TweenService:Create(object, info, values)
	tween:Play()

	return tween
end

--[=[
	Returns the size of the table
	
	@param master table -- table to count
	@return number
	@outline Count
]=]
function Manager.Count(master: table): number
	local count = 0

	for _, _ in pairs(master) do
		count += 1
	end

	return count
end

--[=[
	Shallow copy a table
	
	@param master table -- the table to copy
	@return table
	@outline Copy
]=]
function Manager.Copy(master: table): table
	local clone = {}

	for key, value in pairs(master) do
		if typeof(value) == "table" then
			clone[key] = Manager.Copy(value)
		else
			clone[key] = value
		end
	end

	return clone
end

--[=[
	Deep copy a table
	
	@param master table -- the table to copy
	@return table
	@outline DeepCopy
]=]
function Manager.DeepCopy(master: any): any?
	local clone

	if typeof(master) == "table" then
		clone = {}
		for key, value in next, master, nil do
			clone[Manager.DeepCopy(key)] = Manager.DeepCopy(value)
		end
		setmetatable(clone, Manager.DeepCopy(getmetatable(master)))
	else
		clone = master
	end

	return clone
end

--[=[
	Shuffle a table
	
	@param master table -- the table to shuffle
	@return table
	@outline Shuffle
]=]
function Manager.Shuffle(master: table): table
	local rng = Random.new()

	for index = #master, 2, -1 do
		local random = rng:NextInteger(1, index)
		master[index], master[random] = master[random], master[random]
	end

	return master
end

--[=[
	Encode data with JSON
	
	@param data any -- the data to convert to a string
	@return EncodedString
	@outline Encode
]=]
function Manager.Encode(data: any): any? | boolean
	local success, response = pcall(function()
		return HttpService:JSONEncode(data)
	end)

	if success then
		return response
	end
	warn(response)
	return success
end

--[=[
	Decode an EncodedString with JSON
	
	@param text string -- the encoded string to decode
	@return DecodedData
	@outline Decode
]=]
function Manager.Decode(text: string): any? | boolean
	local success, response = pcall(function()
		return HttpService:JSONDecode(text)
	end)

	if success then
		return response
	end
	warn(response)
	return success
end

--[=[
	Wait for a given tag to load (1 instance means this is complete!)
	
	@param tag string -- the tag to yield for
	@return table
	@outline WaitForTag
]=]
function Manager.WaitForTag(tag: string): table
	while not CollectionService:GetTagged(tag)[1] do
		Manager.Wait()
	end

	return CollectionService:GetTagged(tag)
end

--[=[
	Wait for a players character to load
	
	@param player Instance -- the player instance
	@return Character
	@outline WaitForCharacter
]=]
function Manager.WaitForCharacter(player: Player): Instance
	while not player.Character do
		Manager.Wait()
	end

	while not player.Character:IsDescendantOf(Workspace) do
		Manager.wait()
	end

	return player.Character
end

--[=[
	Connect a function to a custom connection
	
	@param code function -- the function to connect
	@return ScriptSignal
	@outline Connect
]=]
function Manager.Connect(code: RBXScriptConnection | table | (any) -> nil): typeof(Manager.Connect())
	local control = {}

	function control:Disconnect(): typeof(control)
		self = nil

		if typeof(code) == "RBXScriptConnection" then
			code:Disconnect()
		elseif typeof(code) == "table" then
			local success, err = pcall(function()
				code:Disconnect()
			end)
			if not success and Settings.Debug then
				warn(err)
			end
		end

		code = nil
		return setmetatable(self, nil)
	end

	function control:Fire(...): any?
		if typeof(code) == "function" then
			return Manager.Wrap(code, ...)
		else
			warn("Attempted to call ':Fire' on '" .. typeof(code) .. "'")
		end
	end

	return control
end

--[=[
	Connect a function to a key
	
	@param key string -- name of the connection key
	@param code function -- the function to connect
	@return RBXScriptConnection
	@outline ConnectKey
]=]
function Manager.ConnectKey(key: any, code: RBXScriptConnection | table | (any) -> nil): typeof(Manager.ConnectKey())
	if not Manager._Connections[key] then
		Manager._Connections[key] = {}
	end

	local control = {}

	function control:Disconnect(): nil
		if not Manager._Connections[key] then
			return
		end
		Manager._Connections[key][code] = nil

		if typeof(code) == "RBXScriptConnection" then
			code:Disconnect()
		elseif typeof(code) == "table" then
			local success, err = pcall(function()
				code:Disconnect()
			end)

			if not success and Settings.Debug then
				warn(err)
			end
		end

		code = nil
		return setmetatable(self, nil)
	end

	function control:Fire(...): any?
		if typeof(code) == "function" then
			return Manager.Wrap(code, ...)
		else
			warn("Attempted to call ':Fire' on '" .. typeof(code) .. "'")
		end
	end

	Manager._Connections[key][code] = control
	return control
end

--[=[
	Fire all the functions connected to a key
	
	@param key string -- name of the connection key
	@param ...? any -- optional parameters to pass
	@return nil
	@outline FireKey
]=]
function Manager.FireKey(key: string, ...): nil
	if not Manager._Connections[key] then
		return
	end

	for _, control in pairs(Manager._Connections[key]) do
		control:Fire(...)
	end
end

--[=[
	Disconnect all connections on a key
	
	@param key any -- name of the connection key
	@outline DisconnectKey
]=]
function Manager.DisconnectKey(key: any): nil
	if not Manager._Connections[key] then
		return
	end

	for code, control in pairs(Manager._Connections[key]) do
		control:Disconnect()
		Manager._Connections[key][code] = nil
	end

	Manager._Connections[key] = nil
end

--[=[
	Create a task scheduler on a framerate, -1 for no framerate
	
	@param targetFPS number -- the FPS to run at, default 60
	@return TaskScheduler
	@outline Task
]=]
function Manager.Task(targetFPS: number?): typeof(Manager.Task())
	targetFPS = targetFPS or 60

	local control = {}
	control.CodeQueue = {}
	control.UpdateTable = {}
	control.Enable = true
	control.Sleeping = true
	control.Paused = false
	control.UpdateTableEvent = nil

	local start = os.clock()
	Manager.Wait()

	function control:_Frames(): number
		return (((os.clock() - start) >= 1 and #self.UpdateTable) or (#self.UpdateTable / (os.clock() - start)))
	end

	function control:_Update(): nil
		Manager._LastIteration = os.clock()

		for index = #self.UpdateTable, 1, -1 do
			self.UpdateTable[index + 1] = ((self.UpdateTable[index] >= (Manager._LastIteration - 1)) and self.UpdateTable[index] or nil)
		end

		self.UpdateTable[1] = Manager._LastIteration
	end

	function control:_Loop(): nil
		self.UpdateTableEvent = RunService[Settings.RunService]:Connect(function()
			self:_Update()
		end)

		while true do
			if self.Sleeping then
				break
			end
			if not self:Enabled() then
				break
			end

			if targetFPS < 0 then
				if #self.CodeQueue > 0 then
					self.CodeQueue[1]()
					table.remove(self.CodeQueue, 1)
					if not self:Enabled() then
						break
					end
				else
					self.Sleeping = true
					break
				end
			else
				local fps = (
						((os.clock() - start) >= 1 and #self.UpdateTable)
						or (#self.UpdateTable / (os.clock() - start))
					)
				if fps >= targetFPS and (os.clock() - self.UpdateTable[1]) < (1 / targetFPS) then
					if #self.CodeQueue > 0 then
						self.CodeQueue[1]()
						table.remove(self.CodeQueue, 1)
						if not self:Enabled() then
							break
						end
					else
						self.Sleeping = true
						break
					end
				elseif self:Enabled() then
					Manager.Wait()
				end
			end
		end

		self.UpdateTableEvent:Disconnect()
		self.UpdateTableEvent = nil
	end

	function control:Enabled(): boolean
		return self.Enable
	end

	function control:Pause(): number
		self.Paused = true
		self.Sleeping = true

		return self:_Frames()
	end

	function control:Resume(): number
		if self.Paused then
			self.Paused = false
			self.Sleeping = false
			self:_Loop()
		end

		return self:_Frames()
	end

	function control:Wait(): number
		while not self.Sleeping do
			Manager.Wait()
		end

		return self:_Frames()
	end

	function control:Disconnect(): typeof(control)
		self.Enable = false
		self:Pause()
		self.CodeQueue = nil
		self.UpdateTable = nil
		self.UpdateTableEvent:Disconnect()
		self:Wait()

		for index in pairs(self) do
			self[index] = nil
		end

		return setmetatable(self, nil)
	end

	function control:Queue(code: () -> ()): nil
		if not self.CodeQueue then
			return
		end
		self.CodeQueue[#self.CodeQueue + 1] = code

		if self.Sleeping and not self.Paused then
			self.Sleeping = false
			self:_Loop()
		end
	end

	return control
end

return Manager
