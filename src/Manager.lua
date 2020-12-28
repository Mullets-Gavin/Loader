--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: A manager for Luau with a large library of functions & methods
]=]

--[=[
[DOCUMENTATION]:
	https://github.com/Mullets-Gavin/DiceManager
	Listed below is a quick glance on the API, visit the link above for proper documentation.
	
	Manager.wait(time)
	Manager.set(dictionary)
	Manager.wrap(function,...)
	Manager.spawn(function,...)
	Manager.garbage(time,instance)
	Manager.delay(time,function,...)
	Manager.retry(time,function,...)
	Manager.rerun(tries,function,...)
	Manager.debounce(key,function,...)
	Manager.debug(label)
	Manager.round(number[,decimal])
	
	Manager.formatCounter(number,decimal)
	Manager.formatValue(number)
	Manager.formatMoney(number)
	Manager.formatClock(number)
	Manager.format24H(number)
	Manager.formatDate(number)
	
	Manager.Tween(object,properties,goals[,duration,style,direction])
	Manager.Copy(table)
	Manager.DeepCopy(table)
	Manager.Shuffle(table)
	Manager.Encode(any)
	Manager.Decode(encodedText)
	Manager.Compress(any)
	Manager.Decompress(compressedText)
	
	event = Manager:Connect(function)
	event:Disconnect()
	event:Fire(...)
	
	event = Manager:ConnectKey(key,function)
	event:Disconnect()
	event:Fire(...)
	
	Manager:FireKey(key,...)
	Manager:DisconnectKey(key)
	
	event = Manager:Task([fps])
	event:Queue(function)
	event:Pause()
	event:Resume()
	event:Wait()
	event:Enabled()
	event:Disconnect()
	
[OUTLINE]:
	Manager
	├─ .set(properties)
	├─ .wait(clock)
	├─ .wrap(function,...)
	├─ .spawn(function,...)
	├─ .delay(time,function,...)
	├─ .garbage(time,instance)
	├─ .retry(time,function,...)
	├─ .rerun(tries,function,...)
	├─ .debounce(key,function,...)
	├─ .debug(label)
	├─ .round(number[,decimal])
	├─ .formatCounter(number,decimal)
	├─ .formatValue(number)
	├─ .formatMoney(number)
	├─ .formatClock(number)
	├─ .format24H(number)
	├─ .formatDate(number)
	├─ .Tween(object,properties,goals[,duration,style,direction])
	├─ .Copy(table)
	├─ .DeepCopy(table)
	├─ .Shuffle(table)
	├─ .Encode(any)
	├─ .Decode(encodedText)
	├─ .Compress(any)
	├─ .Decompress(compressedText)
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
Numbers.Suffixes = {'k','M','B','T','qd','Qn','sx','Sp','O','N','de','Ud','DD','tdD','qdD','QnD','sxD','SpD','OcD','NvD',
	'Vgn','UVg','DVg','TVg','qtV','QnV','SeV','SPG','OVG','NVG','TGN','UTG','DTG','tsTG','qtTG','QnTG','ssTG','SpTG','OcTG',
	'NoTG','QdDR','uQDR','dQDR','tQDR','qdQDR','QnQDR','sxQDR','SpQDR','OQDDr','NQDDr','qQGNT','uQGNT','dQGNT','tQGNT',
	'qdQGNT','QnQGNT','sxQGNT','SpQGNT', 'OQQGNT','NQQGNT','SXGNTL'}

local Settings = {}
Settings.Debug = false
Settings.RunService = 'Stepped'

local require = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))
local Workspace = game:GetService('Workspace')
local CollectionService = game:GetService('CollectionService')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')

--[=[
	Remove escape characters and return the translation
	
	@param s string -- the string to check for characters
	@return string
	@private
]=]
local function Escape(s: string): string
	return (string.gsub(s,"[%c\"\\]", function(c)
		return '\127'.. Compression.EscapeMap[c]
	end))
end

--[=[
	Unescape characters and return the translation
	
	@param s string -- the string to check for characters
	@return string
	@private
]=]
local function Unescape(s: strng): string
	return (string.gsub(s,'\127(.)', function(c)
		return Compression.EscapeMap[c]
	end))
end

--[=[
	Take a value and make it base 93
	
	@param value number -- the number required
	@return string
	@private
]=]
local function ToBase93(n: number): string
	local value = ''
	
	repeat
		local remainder = n % 93
		value = Compression.Dictionary[remainder]..value
		n = (n - remainder)/93
	until n == 0
	
	return value
end

--[=[
	Take a value and make it base 10
	
	@param value number -- the number required
	@return number
	@private
]=]
local function ToBase10(value: string): number
	local n = 0
	
	for i = 1, #value do
		n = n + 93 ^ (i - 1) * Compression.Dictionary[string.sub(value,-i,-i)]
	end
	
	return n
end

--[=[
	Set the internal settings of Manager with a dictionary
	
	@param properties table -- a dictionary with the settings & boolean
	@return nil
]=]
function Manager.set(properties: table): nil
	Settings.Debug = properties['Debug'] or false
	Settings.RunService = properties['RunService'] or 'Stepped'
end

--[=[
	Wait a frame or a given number of seconds near 100% accuracy
	
	@param clock? number -- provide a time you want to wait for
	@return delta
]=]
function Manager.wait(clock: number?): number
	if clock then
		local current = os.clock()
		
		while clock > os.clock() - current do
			RunService[Settings.RunService]:Wait()
		end
	end
	
	return RunService[Settings.RunService]:Wait()
end

--[=[
	Wrap a function with a coroutine and report custom errors
	
	@param code function -- the function to wrap
	@param ...? any -- optional parameters to pass in the function
	@return nil
]=]
function Manager.wrap(code: (any) -> nil, ...): nil
	local thread = coroutine.create(code)
	local ran,response = coroutine.resume(thread,...)
	
	if not ran then
		local trace = debug.traceback(thread)
		error(response .. "\n" .. trace,2)
	end
end

--[=[
	Supress errors with a similar call to wrap without error reporting
	
	@param code function -- the function to spawn
	@param ...? any -- optional parameters to pass in the function
	@return nil
]=]
function Manager.spawn(code: (any) -> nil, ...): nil
	coroutine.resume(coroutine.create(code),...)
end

--[=[
	Create an infinite loop at a given rate
	
	@param fps number -- the FPS to run at, default 60
	@param code function -- the function to callback
	@param ...? any -- optional parameters to pass in the function
	@return RBXScriptConnection
]=]
function Manager.loop(fps: number, code: (any) -> nil, ...): RBXScriptConnection
	local data = {...}
	local rate = 1/60
	local logged = 0
	local event; event = RunService[Settings.RunService]:Connect(function(delta)
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
]=]
function Manager.delay(clock: number, code: (any) -> nil, ...): nil
	local data = {...}
	Manager.wrap(function()
		local current = os.clock()
		
		while clock > os.clock() - current do
			Manager.wait()
		end
		
		code(table.unpack(data))
	end)
end

--[=[
	Delay destroying an Instance for a given number of time
	
	@param clock number -- the time to wait
	@param obj Instance -- the Instance to destroy
	@return nil
]=]
function Manager.garbage(clock: number, obj: Instance): nil
	Manager.wrap(function()
		local current = os.clock()
		
		while clock > os.clock() - current do
			Manager.wait()
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
]=]
function Manager.retry(clock: number, code: (any) -> nil, ...): boolean & (any?)
	local current = os.clock()
	local success,response
	
	while not success and clock > os.clock() - current do
		success,response = pcall(code,...)
		
		if not success then
			Manager.wait()
		end
	end
	
	if not success and Settings.Debug then
		warn(response,debug.traceback())
	end
	
	return success,response
end

--[=[
	Rerun a function until it succeeds or hits the max retry limit provided
	
	@param times number -- how many times to retry
	@param code function -- the function to run for success
	@param ...? any -- optional parameters to pass in the function
	@return boolean & (any?)
]=]
function Manager.rerun(times: number, code: (any) -> nil, ...): boolean & (any?)
	local current = 0
	local success,response; repeat
		current += 1
		success,response = pcall(code,...)
		
		if not success then
			Manager.wait()
		end
	until success or current >= times
	
	if not success and Settings.Debug then
		warn(response,debug.traceback())
	end
	
	return success,response
end

--[=[
	Debounce a function & return a result if one is provided
	
	@param key string -- the key of the debounce
	@param code function -- the function to wait for
	@return boolean | (any?)
]=]
function Manager.debounce(key: any, code: (any) -> nil, ...): boolean | (any?)
	if Manager._Bouncers[key] then return false end
	Manager._Bouncers[key] = true
	
	local result = code(...)
	
	Manager._Bouncers[key] = false
	return result
end

--[=[
	A custom debug profiler function which uses time to benchmark
	
	@param label? string -- provide a label to use & track otherwise the requirer script name is used
	@return nil
]=]
function Manager.debug(label: string?): nil
	local backtrace = getfenv(3).script
	label = label or string.lower(backtrace.Name)
	
	local timer = Manager._Timers[label]
	if not timer then
		timer = os.clock()
	else
		warn(label,'took:',os.clock() - timer..'ms')
		timer = nil
	end
	
	Manager._Timers[label] = timer
end

--[=[
	Round a number to the nearest given decimal or return math.round
	
	@param input number -- the input to round
	@param decimal? number -- optional decimal to round to
	@return RoundedNumber
]=]
function Manager.round(input: number, decimal: number?): number
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
]=]
function Manager.formatCounter(input: number, decimal: number): string
	local format = tostring(input)
	local raw = '%.'..decimal..'f'
	
	return string.format(raw,format)
end

--[=[
	Format a number for visuals
	
	@param input number -- the number to format
	@return FormattedNumber -- 4000 -> 4,000
]=]
function Manager.formatValue(input: number): string
	local format,remain = tonumber(input)
	
	while remain ~= 0 do
		format,remain = string.gsub(format,'^(-?%d+)(%d%d%d)','%1,%2')
	end
	
	return format
end

--[=[
	Format a number for money
	
	@param input number -- the number to format
	@return FormattedNumber -- 4000 -> 4k
]=]
function Manager.formatMoney(input: number): number | string
	local negative = input < 0
	input = math.abs(input)

	local paired = false
	for i,v in pairs(Numbers.Suffixes) do
		if not (input >= 10^(3 * i)) then
			input = input / 10^(3*(i - 1))
			local isComplex = (string.find(tostring(input),'.') and string.sub(tostring(input),4,4) ~= '.')
			input = string.sub(tostring(input),1,(isComplex and 4) or 3) .. (Numbers.Suffixes[i - 1] or '')
			paired = true
			break;
		end
	end
	
	if not paired then
		local Rounded = math.floor(input)
		input = tostring(Rounded)
	end

	if negative then
		return '-'..input
	end
	
	return input
end

--[=[
	Format a number for clock time
	
	@param input number -- the number to format
	@return FormattedNumber -- 3000 -> 5:00
]=]
function Manager.formatClock(input: number): string
	local seconds = tonumber(input)
	
	if seconds <= 0 then
		return '0:00';
	else
		local mins = string.format('%01.f', math.floor(seconds / 60));
		local secs = string.format('%02.f', math.floor(seconds - mins * 60));
		
		return mins..':'..secs
	end
end

--[=[
	Format a number for 24 hour time
	
	@param input number -- the number to format
	@return FormattedNumber -- HH:MM:SS
]=]
function Manager.format24H(input: number): string
	local seconds = tonumber(input)
	
	if seconds <= 0 then
		return '00:00:00';
	else
		local hours = string.format('%02.f', math.floor(seconds / 3600));
		local mins = string.format('%02.f', math.floor(seconds / 60 - (hours * 60)));
		local secs = string.format('%02.f', math.floor(seconds - hours * 3600 - mins * 60));
		
		return hours..':'..mins..':'..secs
	end
end

--[=[
	Format a number for the date
	
	@param input number -- the number to format
	@return FormattedNumber -- DD:HH:MM:SS
]=]
function Manager.formatDate(input: number): string
	local days = math.floor(input / 86400)
	local hours = math.floor(math.fmod(input, 86400) / 3600)
	local minutes = math.floor(math.fmod(input,3600) / 60)
	local seconds = math.floor(math.fmod(input,60))
	
	return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
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
]=]
function Manager.Tween(object: Instance, properties: table, goals: any | table, duration: number?, style: EnumItem?, direction: EnumItem?): TweenObject
	duration = typeof(duration) == 'number' and duration or 0.5
	style = typeof(style) == 'EnumItem' and style or Enum.EasingStyle.Linear
	direction = typeof(direction) == 'EnumItem' and direction or Enum.EasingDirection.InOut
	
	local values = {}; do
		for index,prop in pairs(properties) do
			values[prop] = typeof(goals) == 'table' and goals[index] or goals
		end
	end
	
	local info = TweenInfo.new(duration,style,direction)
	local tween = TweenService:Create(object,info,values)
	tween:Play()
	
	return tween
end

--[=[
	Returns the size of the table
	
	@param master table -- table to count
	@return number
]=]
function Manager.Count(master: table): number
	local count = 0
	
	for index,element in pairs(master) do
		count += 1
	end
	
	return count
end

--[=[
	Shallow copy a table
	
	@param master table -- the table to copy
	@return table
]=]
function Manager.Copy(master: table): table
	local clone = {}
	
	for key,value in pairs(master) do
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
]=]
function Manager.DeepCopy(master: any): any?
	local clone
	
	if typeof(master) == 'table' then
		clone = {}
		for key,value in next, master, nil do
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
]=]
function Manager.Shuffle(master: table): table
	local rng = Random.new()
	
	for index = #master, 2, -1 do
		local random = rng:NextInteger(1,index)
		master[index],master[random] = master[random],master[random]
	end
	
	return master
end

--[=[
	Encode data with JSON
	
	@param data any -- the data to convert to a string
	@return EncodedString
]=]
function Manager.Encode(data: any): any? | boolean
	local success,response = Manager.rerun(5,function()
		return HttpService:JSONEncode(data)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Decode an EncodedString with JSON
	
	@param text string -- the encoded string to decode
	@return DecodedData
]=]
function Manager.Decode(text: string): any? | boolean
	local success,response = Manager.rerun(5,function()
		return HttpService:JSONDecode(text)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Compress text and data
	
	@param text any -- data to compress
	@return CompressedString
]=]
function Manager.Compress(text: any): string
	text = Manager.Encode(text)
	
	local dictionary = Manager.Copy(Compression.Dictionary)
	local key, sequence, size = '', {}, #dictionary
	local width, spans, span = 1, {}, 0
	
	local function listkey(key)
		local value = ToBase93(dictionary[key])
		if #value > width then
			width, span, spans[width] = #value, 0, span
		end
		sequence[#sequence + 1] = string.rep(' ',width - #value).. value
		span = span + 1
	end
	
	text = Escape(text)
	for index = 1, #text do
		local char = string.sub(text,index,index)
		local new = key .. char
		if dictionary[new] then
			key = new
		else
			listkey(key)
			key, size = char, size + 1
			dictionary[new], dictionary[size] = size, new
		end
	end
	
	listkey(key)
	spans[width] = span
	
    return table.concat(spans, ',')..'|'..table.concat(sequence)
end

--[=[
	Decompress a CompressedString with JSON
	
	@param text string -- the compressed string to decode
	@return DecompressedData
]=]
function Manager.Decompress(text: string): any?
	local dictionary = Manager.Copy(Compression.Dictionary)
	local sequence, spans, content = {}, string.match(text,'(.-)|(.*)')
	local groups, start = {}, 1
	
	for span in string.gmatch(spans,'%d+') do
		local width = #groups + 1
		groups[width] = string.sub(content,start,start + span * width - 1)
		start = start + span * width
	end
	
	local previous;
	for width = 1, #groups do
		for value in string.gmatch(groups[width],string.rep('.',width)) do
			local entry = dictionary[ToBase10(value)]
			if previous then
				if entry then
					sequence[#sequence + 1] = entry
					dictionary[#dictionary + 1] = previous..string.sub(entry,1,1)
				else
					entry = previous..string.sub(previous,1,1)
					sequence[#sequence + 1] = entry
					dictionary[#dictionary + 1] = entry
				end
			else
				sequence[1] = entry
			end
			previous = entry
		end
	end
	
	return Manager.Decode(Unescape(table.concat(sequence)))
end

--[=[
	Wait for a given tag to load (1 instance means this is complete!)
	
	@param tag string -- the tag to yield for
	@return table
]=]
function Manager:WaitForTag(tag: string): table
	while not CollectionService:GetTagged(tag)[1] do
		Manager.wait()
	end
	
	return CollectionService:GetTagged(tag)
end

--[=[
	Wait for a players character to load
	
	@param player Instance -- the player instance
	@return Character
]=]
function Manager:WaitForCharacter(player: Player): Instance
	while not player.Character do
		Manager.wait()
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
]=]
function Manager:Connect(code: RBXScriptConnection | table | (any) -> nil): typeof(Manager:Connect())
	local control = {}
	
	function control:Disconnect(): typeof(control)
		control = nil
		
		if typeof(code) == 'RBXScriptConnection' then
			code:Disconnect()
		elseif typeof(code) == 'table' then
			local success,err = pcall(function()
				code:Disconnect()
			end)
			if not success and Settings.Debug then
				warn(err)
			end
		end
		
		code = nil
		return setmetatable(control,nil)
	end
	
	function control:Fire(...): any?
		if typeof(code) == 'function' then
			return Manager.wrap(code,...)
		else
			warn("Attempted to call ':Fire' on '".. typeof(code) .."'")
		end
	end
	
	return control
end

--[=[
	Connect a function to a key
	
	@param key string -- name of the connection key
	@param code function -- the function to connect
	@return RBXScriptConnection
]=]
function Manager:ConnectKey(key: any, code: RBXScriptConnection | table | (any) -> nil): typeof(Manager:ConnectKey())
	if not Manager._Connections[key] then
		Manager._Connections[key] = {}
	end
	
	local control = {}
	
	function control:Disconnect(): nil
		if not Manager._Connections[key] then return end
		Manager._Connections[key][code] = nil
		
		if typeof(code) == 'RBXScriptConnection' then
			code:Disconnect()
		elseif typeof(code) == 'table' then
			local success,err = pcall(function()
				code:Disconnect()
			end)
			
			if not success and Settings.Debug then
				warn(err)
			end
		end
		
		code = nil
		return setmetatable(control,nil)
	end
	
	function control:Fire(...): any?
		if typeof(code) == 'function' then
			return Manager.wrap(code,...)
		else
			warn("Attempted to call ':Fire' on '".. typeof(code) .."'")
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
]=]
function Manager:FireKey(key: string, ...): nil
	if not Manager._Connections[key] then
		return
	end
	
	for code,control in pairs(Manager._Connections[key]) do
		control:Fire(...)
	end
end

--[=[
	Disconnect all connections on a key
	
	@param key any -- name of the connection key
]=]
function Manager:DisconnectKey(key: any): nil
	if not Manager._Connections[key] then
		return
	end
	
	for code,control in pairs(Manager._Connections[key]) do
		control:Disconnect()
		Manager._Connections[key][code] = nil
	end
	
	Manager._Connections[key] = nil
end

--[=[
	Create a task scheduler on a framerate, -1 for no framerate
	
	@param targetFPS number -- the FPS to run at, default 60
	@return TaskScheduler
]=]
function Manager:Task(targetFPS: number?): typeof(Manager:Task())
	targetFPS = targetFPS or 60
	
	local control = {}
	control.CodeQueue = {}
	control.UpdateTable = {}
	control.Enable = true
	control.Sleeping = true
	control.Paused = false
	control.UpdateTableEvent = nil
	
	local start = os.clock()
	Manager.wait()
	
	local function Frames(): number
		return (((os.clock() - start) >= 1 and #control.UpdateTable) or (#control.UpdateTable / (os.clock() - start)))
	end
	
	local function Update(): nil
		Manager._LastIteration = os.clock()
		
		for index = #control.UpdateTable,1,-1 do
			control.UpdateTable[index + 1] = ((control.UpdateTable[index] >= (Manager._LastIteration - 1)) and control.UpdateTable[index] or nil)
		end
		
		control.UpdateTable[1] = Manager._LastIteration
	end
	
	local function Loop(): nil
		control.UpdateTableEvent = RunService[Settings.RunService]:Connect(Update)
		
		while (true) do
			if control.Sleeping then break end
			if not control:Enabled() then break end
			
			if targetFPS < 0 then
				if (#control.CodeQueue > 0) then
					control.CodeQueue[1]()
					table.remove(control.CodeQueue, 1)
					if not control:Enabled() then
						break
					end
				else
					control.Sleeping = true
					break
				end
			else
				local fps = (((os.clock() - start) >= 1 and #control.UpdateTable) or (#control.UpdateTable / (os.clock() - start)))
				if (fps >= targetFPS and (os.clock() - control.UpdateTable[1]) < (1 / targetFPS)) then
					if (#control.CodeQueue > 0) then
						control.CodeQueue[1]()
						table.remove(control.CodeQueue, 1)
						if not control:Enabled() then
							break
						end
					else
						control.Sleeping = true
						break
					end
				elseif control:Enabled() then
					Manager.wait()
				end
			end
		end
		
		control.UpdateTableEvent:Disconnect()
		control.UpdateTableEvent = nil
	end
	
	function control:Enabled(): boolean
		return control.Enable
	end
	
	function control:Pause(): number
		control.Paused = true
		control.Sleeping = true
		
		return Frames()
	end
	
	function control:Resume(): number
		if control.Paused then
			control.Paused = false
			control.Sleeping = false
			Loop()
		end
		
		return Frames()
	end
	
	function control:Wait(): number
		while not control.Sleeping do
			Manager.wait()
		end
		
		return Frames()
	end
	
	function control:Disconnect(): typeof(control)
		control.Enable = false
		control:Pause()
		control.CodeQueue = nil
		control.UpdateTable = nil
		control.UpdateTableEvent:Disconnect()
		control:Wait()
		
		for index in pairs(control) do
			control[index] = nil
		end
		
		return setmetatable(control,nil)
	end
	
	function control:Queue(code: () -> ()): nil
		if not control.CodeQueue then return end
		control.CodeQueue[#control.CodeQueue + 1] = code
		
		if (control.Sleeping and not control.Paused) then
			control.Sleeping = false
			Loop()
		end
	end
	
	return control
end

do
	Manager.IsStudio = RunService:IsStudio() and 'Studio'
	Manager.IsServer = RunService:IsServer() and 'Server'
	Manager.IsClient = RunService:IsClient() and 'Client'
	
	for index = 32, 127 do
		if index ~= 34 and index ~= 92 then
			local char = string.char(index)
			Compression.Dictionary[char] = Compression.Length
			Compression.Dictionary[Compression.Length] = char
			Compression.Length = Compression.Length + 1
		end
	end

	for index = 1, 34 do
		index = ({34, 92, 127})[index - 31] or index
		local char,ending = string.char(index),string.char(index + 31)
		Compression.EscapeMap[char] = ending
		Compression.EscapeMap[ending] = char
	end
end

return Manager