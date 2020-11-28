--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: An Interface library with various functionality for Gui and Inputs
]=]

--[=[
[DOCUMENTATION]:
	.IsComputer()
	.IsMobile()
	.IsConsole()
	.IsKeyboard()
	.IsMouse()
	.IsTouch()
	.IsGamepad()
	.IsVR()
	.Replicate()
	.AssignSize()
	.RichText()
	.Keybind(name)
	:Disconnect(name)
	:Update(name,keys)
	:Began(name,keys,code)
	:Ended(name,keys,code)
	:Tapped(name,code)
	
[OUTLINE]:
	Interface
	├─ .IsComputer()
	│  └─ alias variable: .Computer
	├─ .IsMobile()
	│  └─ alias variable: .Mobile
	├─ .IsConsole()
	│  └─ alias variable: .Console
	├─ .IsKeyboard()
	│  └─ alias variable: .Keyboard
	├─ .IsMouse()
	│  └─ alias variable: .Mouse
	├─ .IsTouch()
	│  └─ alias variable: .Touch
	├─ .IsGamepad()
	│  └─ alias variable: .Gamepad
	├─ .IsVR()
	│  └─ alias variable: .VR
	├─ .Replicate()
	│  └─ Replicate Gui contents from ReplicatedStorage
	├─ .AssignSize()
	│  ├─ Simplified AssignSizes implementation
	│  ├─ :Update(scale,min,max)
	│  │  └─ Update the scale, min and max used
	│  ├─ :Changed(function)
	│  │  └─ Fires everytime UI resizes
	│  └─ :Disconnect()
	│     └─ Disconnects the events changing the UI
	├─ .RichText()
	│  ├─ Create a RichText object
	│  ├─ :Append(text or RichText)
	│  ├─ :GetText()
	│  ├─ :GetRaw()
	│  ├─ :Bold(bool)
	│  ├─ :Italic(bool)
	│  ├─ :Underline(bool)
	│  ├─ :Strike(bool)
	│  ├─ :Comment(bool)
	│  ├─ :Font(textFont or bool)
	│  ├─ :Size(textSize or bool)
	│  └─ :Color(textColor or bool)
	├─ .Keybind(name)
	│  ├─ :Enabled(bool)
	│  ├─ :Keybinds(...)
	│  ├─ :Mobile(bool[,image])
	│  ├─ :Hook(function)
	│  └─ :Destroy()
	├─ :Disconnect(name)
	├─ :Update(name,keys)
	├─ :Began(name,keys,code)
	├─ :Ended(name,keys,code)
	└─ :Tapped(name,code)

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

local Interface = {}
Interface.__index = Interface
setmetatable(Interface,Interface)

Interface._Name = string.upper(script.Name)
Interface._Error = '['.. Interface._Name ..']: '

Interface._AssignSizesCache = {}
Interface._AssignSizesOveride = false

local Loader = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))

local Manager = Loader('Manager')
local Input = Loader(script:WaitForChild('Input'))

local Workspace = Loader['Workspace']
local GuiService = Loader['GuiService']
local Players = Loader['Players']
local UserInputService = Loader['UserInputService']

local Camera = Workspace.CurrentCamera
local Container

--[=[
	A local function to convert a color3 to RichText format
	
	@param color Color3 -- the color3 to convert
	@return RichText rgb(color.r,color.g,color.b)
]=]
local function FormatColor(color)
	assert(typeof(color) == 'Color3',"Must provide a valid Color3")
	
	return string.format(
		'rgb(%i,%i,%i)',
		math.floor(color.r * 255),
		math.floor(color.g * 255),
		math.floor(color.b * 255)
	)
end

--[=[
	A local function to resize a GuiObject
	
	@param element Instance -- a GuiObject to assign a size
	@param scale number -- the scale of which to size the element
	@param min number -- the minimum size of the element
	@param max number -- the maximum size of the element
	@private
]=]
local function ResizeContainer(element,scale,min,max)
	assert(typeof(element) == 'Instance' and element:IsA('GuiObject'),Interface._Error.."'ResizeContainer' expected a GuiObject for element, got '"..typeof(element).."'")
	assert(typeof(scale) == 'number',Interface._Error.."'ResizeContainer' expected a number for scale, got '"..typeof(scale).."'")
	assert(typeof(min) == 'number',Interface._Error.."'ResizeContainer' expected a number for min, got '"..typeof(min).."'")
	assert(typeof(max) == 'number',Interface._Error.."'ResizeContainer' expected a number for max, got '"..typeof(max).."'")
	
	local viewportSize = Camera.ViewportSize; do
		if viewportSize.Y <= 700 then
			Interface._AssignSizesOveride = true
		else
			Interface._AssignSizesOveride = false
		end
	end
	
	local Size = Interface._AssignSizesCache[element]['Size']
	if UserInputService.TouchEnabled or Interface._AssignSizesOveride then
		
		local uiSize = (viewportSize.X/viewportSize.Y) * scale
		local clampX = math.clamp(Size.X.Scale * uiSize, min, max)
		local clampY = math.clamp(Size.Y.Scale * uiSize, min, max)
		
		element.Size = UDim2.new(clampX, 0, clampY, 0)
	else
		local uiSize; do
			if (viewportSize.X/viewportSize.Y) >= 2 then
				uiSize = (viewportSize.X/viewportSize.Y) * (scale/3.5)
			else
				uiSize = (viewportSize.X/viewportSize.Y) * (scale/2)
			end
		end
		
		local clampX = math.clamp(Size.X.Scale * uiSize, min, max)
		local clampY = math.clamp(Size.Y.Scale * uiSize, min, max)
		
		element.Size = UDim2.new(clampX, 0, clampY, 0)
		
		local absoluteY = element.AbsoluteSize.Y
		if absoluteY < 36 then
			ResizeContainer(element,scale * 2,min,max)
		end
	end
end

--[=[
	Returns whether the clients device is a computer
	
	@return boolean
]=]
function Interface.IsComputer()
	local check = Interface.IsKeyboard() and Interface.IsMouse() and true or false
	return check
end

--[=[
	Returns whether the clients device is a mobile device
	
	@return boolean
]=]
function Interface.IsMobile()
	local check = Interface.IsTouch() and not Interface.IsKeyboard() and true or false
	return check
end

--[=[
	Returns whether the clients device is a console
	
	@return boolean
]=]
function Interface.IsConsole()
	return GuiService:IsTenFootInterface()
end

--[=[
	Returns whether the clients device has a keyboard
	
	@return boolean
]=]
function Interface.IsKeyboard()
	return UserInputService.KeyboardEnabled
end

--[=[
	Returns whether the clients device has a mouse
	
	@return boolean
]=]
function Interface.IsMouse()
	return UserInputService.MouseEnabled
end

--[=[
	Returns whether the clients device is touch enabled
	
	@return boolean
]=]
function Interface.IsTouch()
	return UserInputService.TouchEnabled
end

--[=[
	Returns whether the clients device has a controller
	
	@return boolean
]=]
function Interface.IsGamepad()
	return UserInputService.GamepadEnabled
end

--[=[
	Returns whether the clients device is virtual reality
	
	@return boolean
]=]
function Interface.IsVR()
	return UserInputService.VREnabled
end

--[=[
	Replicate GuiObject containers, skipping Roblox character dependency
	
	@return Interface
]=]
function Interface.Replicate()
	
	return Interface
end

--[=[
	Create an AssignSizes Object and connect an element
	
	@param element Instance -- a GuiObject to assign a size
	@param scale number -- the scale of which to size the element
	@param min number -- the minimum size of the element
	@param max number -- the maximum size of the element
]=]
function Interface.AssignSizes(element,scale,min,max)
	assert(typeof(element) == 'Instance' and element:IsA('GuiObject'),Interface._Error.."'AssignSizes' expected a GuiObject for element, got '"..typeof(element).."'")
	assert(typeof(scale) == 'number',Interface._Error.."'AssignSizes' expected a number for scale, got '"..typeof(scale).."'")
	assert(typeof(min) == 'number',Interface._Error.."'AssignSizes' expected a number for min, got '"..typeof(min).."'")
	assert(typeof(max) == 'number',Interface._Error.."'AssignSizes' expected a number for max, got '"..typeof(max).."'")
	
	local control = {}	
	control._element = element;
	control._scale = scale;
	control._min = min;
	control._max = max;
	
	function control:Update(_scale,_min,_max)
		control._scale = _scale or control._scale
		control._min = _min or control._min
		control._max = _max or control._max
		
		ResizeContainer(control._element,control._scale,control._min,control._max)
		
		return control
	end
	
	function control:Changed(code)
		assert(typeof(code) == 'function',Interface._Error.."':Changed' expected a function, got '"..typeof(code).."'")
		
		local file = Interface._AssignSizesCache[element]
		
		if file ~= nil then
			file['Code'] = code
			Interface._AssignSizesCache[element] = file
		end
		
		return control
	end
	
	function control:Disconnect()
		local file = Interface._AssignSizesCache[element]
		
		if file ~= nil then
			file['Event']:Disconnect()
			file['Event'] = nil
			file['Code'] = nil
			Interface._AssignSizesCache[element] = file
		end
		
		return control
	end
	
	local file = Interface._AssignSizesCache[element]
	
	if file and file['Event'] ~= nil then
		file['Event']:Disconnect()
	else
		file = {
			['Event'] = nil;
			['Code'] = nil;
			['Size'] = element.Size;
		}
	end
	
	if file['Size'] == nil then
		file['Size'] = element.Size
	end
	
	file['event'] = Camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
		ResizeContainer(control._element,control._scale,control._min,control._max)
		local import = Interface._AssignSizesCache[element]
		if import and import['Code'] then
			import['Code']()
		end
	end)
	
	Interface._AssignSizesCache[element] = file
	
	ResizeContainer(control._element,control._scale,control._min,control._max)
	
	return control
end

--[=[
	Create a RichText Object
	
	@return RichTextObject
]=]
function Interface.Richtext()
	local control = {}
	control._raw = {}
	control._append = {}
	
	function control:Append(value)
		assert(typeof(value) == 'string' or 'table',"':Append' Text or other RichText must be defined to correctly format Rich Text")
		
		if typeof(value) == 'string' then
			table.insert(control._raw,value)
			table.insert(control._append,value)
		elseif typeof(value) == 'table' then
			for index,format in ipairs(value._raw) do
				table.insert(control._raw,format)
				table.insert(control._append,format)
			end
		end
		
		return control
	end

	function control:Bold(state)
		assert(typeof(state) == 'boolean',"':Bold' A boolean must be defined to correctly format Rich Text")
		
		if state then
			table.insert(control._raw,'<b>')
		else
			table.insert(control._raw,'</b>')
		end
		
		return control
	end

	function control:Italic(state)
		assert(typeof(state) == 'boolean',"':Italic' A boolean must be defined to correctly format Rich Text")
		
		if state then
			table.insert(control._raw,'<i>')
		else
			table.insert(control._raw,'</i>')
		end
		
		return control
	end

	function control:Underline(state)
		assert(typeof(state) == 'boolean',"':Underline' A boolean must be defined to correctly format Rich Text")
		
		if state then
			table.insert(control._raw,'<u>')
		else
			table.insert(control._raw,'</u>')
		end
		
		return control
	end

	function control:Strike(state)
		assert(typeof(state) == 'boolean',"':Strike' A boolean must be defined to correctly format Rich Text")
		
		if state then
			table.insert(control._raw,'<s>')
		else
			table.insert(control._raw,'</s>')
		end
		
		return control
	end

	function control:Comment(state)
		assert(typeof(state) == 'boolean',"':Comment' A boolean must be defined to correctly format Rich Text")
		
		if state then
			table.insert(control._raw,'<!--')
		else
			table.insert(control._raw,'-->')
		end
		
		return self
	end

	function control:Font(name)
		assert(typeof(name) == 'string' or 'EnumItem' or 'boolean',"':Font' A name or EnumItem or false must be defined to correctly format Rich Text")
		
		if typeof(name) == 'string' then
			table.insert(control._raw,'<font face="'.. name ..'">')
		elseif typeof(name) == 'EnumItem' then
			table.insert(control._raw,'<font face="'.. name.Name ..'">')
		elseif not name then
			table.insert(control._raw,'</font>')
		end
		
		return control
	end

	function control:Size(number)
		assert(typeof(number) == 'number' or 'boolean',"':Size' A number or false must be defined to correctly format Rich Text")
		
		if typeof(number) == 'number' then
			table.insert(control._raw,'<font size="'.. number ..'">')
		elseif not number then
			table.insert(control._raw,'</font>')
		end
		
		return control
	end

	function control:Color(color)
		assert(typeof(color) == 'Color3' or 'boolean',"':Color' A Color3 or false must be defined to correctly format Rich Text")
		
		if typeof(color) == 'Color3' then
			table.insert(control._raw,'<font color="'.. FormatColor(color) ..'">')
		elseif not color then
			table.insert(control._raw,'</font>')
		end
		
		return control
	end

	function control:GetRaw()
		return table.concat(control._append)
	end

	function control:GetText()
		return table.concat(control._raw)
	end
	
	return control
end

--[=[
	Create a keybind with an optional mobile button
	
	@param name string -- the internal name of the keybind, be unique
	@return KeybindObject
]=]
function Interface.Keybind(name)
	assert(typeof(name) == 'string')
	
	Input:CreateButton(name,Container)
	if not Input._InputCache[name] then
		Input._InputCache[name] = {}
	end
	
	local control = {}
	
	function control._Verify()
		assert(Input._InputCache[name] ~= nil)
		
		if Input._InputCache[name]['Keys'] and Input._InputCache[name]['Function'] then
			Input._InputCache[name]['Verify'] = true
		else
			Input._InputCache[name]['Verify'] = false
		end
	end
	
	function control:Enabled(state)
		assert(typeof(state) == 'boolean')
		
		Input._InputCache[name]['Enabled'] = state
		Input:EnableButton(name,state)
		control._Verify()
	end
	
	function control:Keybinds(...)
		local capture = {}
		
		for index,key in pairs({...}) do
			assert(typeof(key) == 'EnumItem')
			table.insert(capture,key)
		end
		
		Input._InputCache[name]['Keys'] = capture
		control._Verify()
	end
	
	function control:Mobile(state,image)
		assert(typeof(state) == 'boolean')
		
		Input._InputCache[name]['Mobile'] = state
		local button = Input:GetButton(name)
		
		if button then
			button.Visible = state
			if image then
				assert(typeof(image) == 'string')
				
				button.Icon.Image = image
			end
		end
		
		control._Verify()
	end
	
	function control:Hook(code)
		assert(typeof(code) == 'function')
		
		if Input._InputCache[name]['Function'] then
			Input._InputCache[name]['Function'] = nil
		end
		
		Input._InputCache[name]['Function'] = code
		control._Verify()
	end
	
	function control:Destroy()
		local button = Input:GetButton(name)
		
		if button then
			Manager:DisconnectKey(name)
			button:Destroy()
		end
		
		for index in pairs(control) do
			control[index] = nil
		end
		
		return setmetatable(control,nil)
	end
	
	return control
end

--[=[
	Disconnect a keybind
	
	@param name string -- the name of the keybind to find
]=]
function Interface:Disconnect(name)
	assert(typeof(name) == 'string')
	
	if Input._InputCallbacks[name] then
		Input._InputCallbacks[name] = nil
	end
end

--[=[
	Update a currently created keybind
	
	@param name string -- the name of the keybind
	@param keys table -- a list of the enum keycodes to switch to
	@return boolean
]=]
function Interface:Update(name,keys)
	assert(typeof(name) == 'string')
	assert(typeof(keys) == 'table')
	for index,key in pairs(keys) do
		assert(typeof(key) == 'EnumItem')
	end
	
	if Input._InputCallbacks[name] then
		Input._InputCallbacks[name]['Keys'] = keys
		return true
	end
	
	return false
end

--[=[
	Track a keybind when UIS.InputBegan fires
	
	@param name string -- the name of the keybind
	@param keys table -- a list of the enum keycodes
	@param code function -- a callback function when a key presses
]=]
function Interface:Began(name,keys,code)
	assert(typeof(name) == 'string')
	assert(typeof(keys) == 'table')
	assert(typeof(code) == 'function')
	for index,key in pairs(keys) do
		assert(typeof(key) == 'EnumItem')
	end
	
	if Input._InputCallbacks[name] then
		Input._InputCallbacks[name] = nil
	end
	
	Interface:Disconnect(name)
	Input._InputCallbacks[name] = {
		['Keys'] = keys;
		['Code'] = code;
		['Type'] = 'Began';
	}
end

--[=[
	Track a keybind when UIS.InputEnded fires
	
	@param name string -- the name of the keybind
	@param keys table -- a list of the enum keycodes
	@param code function -- a callback function when a key depresses
]=]
function Interface:Ended(name,keys,code)
	assert(typeof(name) == 'string')
	assert(typeof(keys) == 'table')
	assert(typeof(code) == 'function')
	for index,key in pairs(keys) do
		assert(typeof(key) == 'EnumItem')
	end
	
	Interface:Disconnect(name)
	Input._InputCallbacks[name] = {
		['Keys'] = keys;
		['Code'] = code;
		['Type'] = 'Ended';
	}
end

--[=[
	Track a keybind when UIS.TouchTap fires
	
	@param name string -- the name of the keybind
	@param code function -- a callback function when there is a tap
]=]
function Input:Tapped(name,code)
	assert(typeof(name) == 'string')
	assert(typeof(code) == 'function')
	
	Input._InputTouchCallbacks[name] = {
		['Code'] = code;
		['Type'] = 'Ended';
	}
end

--[=[
	Allows you to require Interface & immediately replicate
	
	@return Interface
]=]
function Interface:__call()
	return Interface.Replicate()
end

Manager.wrap(function()
	if Manager.IsClient then
		Interface.Computer = Interface.IsComputer()
		Interface.Mobile = Interface.IsMobile()
		Interface.Console = Interface.IsConsole()
		Interface.Keyboard = Interface.IsKeyboard()
		Interface.Mouse = Interface.IsMouse()
		Interface.Touch = Interface.IsTouch()
		Interface.Gamepad = Interface.IsGamepad()
		Interface.VR = Interface.IsVR()
		
		local Player = Players.LocalPlayer
		local PlayerGui = Player:WaitForChild('PlayerGui')
		
		Container = Instance.new('ScreenGui'); do
			Container.Name = 'DiceMobile'
			Container.Enabled = false
			Container.ResetOnSpawn = false
			Container.Parent = PlayerGui
		end
		
		if Interface.Mobile then
			Container.Enabled = true
			
			local Size,Jump; do
				local TouchGui = PlayerGui:WaitForChild('TouchGui',math.huge)
				local TouchFrame = TouchGui:WaitForChild('TouchControlFrame',math.huge)
				Jump = TouchFrame:WaitForChild('JumpButton',math.huge)
				Manager:WaitForCharacter(Player)
				Size = UDim2.fromOffset(Jump.Size.X.Offset/1.25, Jump.Size.Y.Offset/1.25)
			end
			
			local Log = {}
			local Config = {
				CENTER_BUTTON_POSITION = Jump.AbsolutePosition,
				CENTER_BUTTON_SIZE = Jump.AbsoluteSize,
				N_BUTTONS = 4,
				MIN_RADIUS_PADDING = 10,
				BUTTON_PADDING = 5,
				BUTTON_SIZE = UDim2.fromOffset(Jump.Size.X.Offset/1.25, Jump.Size.Y.Offset/1.25),
				RESOLUTION = Container.AbsoluteSize,
			}
			
			local function Organize()
				local generate = Input.MakePositioning(#Log)
				Config.MIN_RADIUS = 0
				local positions = Input.GetPositionsWithRows(generate,Config)
				for index,button in ipairs(Log) do
					if not button then continue end
					button.Position = positions[index]
				end
			end
			
			for index,button in ipairs(Container:GetChildren()) do
				if table.find(Log,button) then continue end
				table.insert(Log,button)
				button.Size = Size
				Input.Effects(button.Name)
				Organize()
			end
			
			Container.ChildAdded:Connect(function(button)
				if table.find(Log,button) then return end
				table.insert(Log,button)
				button.Size = Size
				Input.Effects(button.Name)
				Organize()
			end)
		end
	end
end)

return Interface