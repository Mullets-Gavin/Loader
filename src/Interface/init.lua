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
Interface._Name = string.upper(script.Name)
Interface._Error = '['.. Interface._Name ..']: '
Interface._ComponentCode = {}
Interface._ComponentCache = {}
Interface._AssignSizesCache = {}
Interface._AssignSizesOveride = false
setmetatable(Interface,Interface)

local Loader = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))
local Manager = Loader('Manager')
local Input = Loader(script:WaitForChild('Input'))
local Components = Loader(script:WaitForChild('Components'))
local Animator = Loader(script:WaitForChild('Animator'))
local Workspace = Loader['Workspace']
local GuiService = Loader['GuiService']
local Players = Loader['Players']
local UserInputService = Loader['UserInputService']
local CollectionService = Loader['CollectionService']
local Camera = Workspace.CurrentCamera
local Container

--[=[
	A local function to convert a color3 to RichText format
	
	@param color Color3 -- the color3 to convert
	@return string -- rgb(color.r,color.g,color.b)
]=]
local function FormatColor(color: Color3): string
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
	@return nil
	@private
]=]
local function ResizeContainer(element: GuiObject, scale: number, min: number, max: number): nil
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
	Bind & create a component with an element
	
	@param tag string -- the tag used
	@param element GuiObject -- the object used for the component
	@return nil
]=]
local function BindComponent(tag: string, element: GuiObject): nil
	if Interface._ComponentCache[tag][element] then return end
	
	local Player = Players.LocalPlayer
	local PlayerGui = Player.PlayerGui
	
	while not element:IsDescendantOf(PlayerGui) do
		element.AncestryChanged:Wait()
	end
	
	local code = Interface._ComponentCode[tag]
	local create = Components.new(element)
	Interface._ComponentCache[tag][element] = create
	
	Manager.wrap(code,create)
end

--[=[
	Returns whether the clients device is a computer
	
	@return boolean
]=]
function Interface.IsComputer(): boolean
	local check = Interface.IsKeyboard() and Interface.IsMouse() and true or false
	return check
end

--[=[
	Returns whether the clients device is a mobile device
	
	@return boolean
]=]
function Interface.IsMobile(): boolean
	local check = Interface.IsTouch() and not Interface.IsKeyboard() and true or false
	return check
end

--[=[
	Returns whether the clients device is a console
	
	@return boolean
]=]
function Interface.IsConsole(): boolean
	return GuiService:IsTenFootInterface()
end

--[=[
	Returns whether the clients device has a keyboard
	
	@return boolean
]=]
function Interface.IsKeyboard(): boolean
	return UserInputService.KeyboardEnabled
end

--[=[
	Returns whether the clients device has a mouse
	
	@return boolean
]=]
function Interface.IsMouse(): boolean
	return UserInputService.MouseEnabled
end

--[=[
	Returns whether the clients device is touch enabled
	
	@return boolean
]=]
function Interface.IsTouch(): boolean
	return UserInputService.TouchEnabled
end

--[=[
	Returns whether the clients device has a controller
	
	@return boolean
]=]
function Interface.IsGamepad(): boolean
	return UserInputService.GamepadEnabled
end

--[=[
	Returns whether the clients device is virtual reality
	
	@return boolean
]=]
function Interface.IsVR(): boolean
	return UserInputService.VREnabled
end

--[=[
	Replicate GuiObject containers, skipping Roblox character dependency
	
	@return nil
]=]
function Interface.Replicate(): nil -- TODO
	
end

--[=[
	Create an AssignSizes Object and connect an element
	
	@param element Instance -- a GuiObject to assign a size
	@param scale number -- the scale of which to size the element
	@param min number -- the minimum size of the element
	@param max number -- the maximum size of the element
	@return nil
]=]
function Interface.AssignSizes(element: GuiObject, scale: number, min: number, max: number): typeof(Interface.AssignSizes())
	local control = {}	
	control._element = element;
	control._scale = scale;
	control._min = min;
	control._max = max;
	
	function control:Update(_scale: number, _min: number, _max: number): typeof(control)
		control._scale = _scale or control._scale
		control._min = _min or control._min
		control._max = _max or control._max
		
		ResizeContainer(control._element,control._scale,control._min,control._max)
		
		return control
	end
	
	function control:Changed(code: () -> ()): typeof(control)
		local file = Interface._AssignSizesCache[element]
		
		if file ~= nil then
			file['Code'] = code
			Interface._AssignSizesCache[element] = file
		end
		
		return control
	end
	
	function control:Disconnect(): typeof(control)
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
function Interface.Richtext(): typeof(Interface.Richtext())
	local control = {}
	control._raw = {}
	control._append = {}
	
	function control:Append(value: string | table): typeof(control)
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

	function control:Bold(state: boolean): typeof(control)
		if state then
			table.insert(control._raw,'<b>')
		else
			table.insert(control._raw,'</b>')
		end
		
		return control
	end

	function control:Italic(state: boolean): typeof(control)
		if state then
			table.insert(control._raw,'<i>')
		else
			table.insert(control._raw,'</i>')
		end
		
		return control
	end

	function control:Underline(state: boolean): typeof(control)
		if state then
			table.insert(control._raw,'<u>')
		else
			table.insert(control._raw,'</u>')
		end
		
		return control
	end

	function control:Strike(state: boolean): typeof(control)
		if state then
			table.insert(control._raw,'<s>')
		else
			table.insert(control._raw,'</s>')
		end
		
		return control
	end

	function control:Comment(state: boolean): typeof(control)
		if state then
			table.insert(control._raw,'<!--')
		else
			table.insert(control._raw,'-->')
		end
		
		return self
	end

	function control:Font(name: string | EnumItem | boolean): typeof(control)
		if typeof(name) == 'string' then
			table.insert(control._raw,'<font face="'.. name ..'">')
		elseif typeof(name) == 'EnumItem' then
			table.insert(control._raw,'<font face="'.. name.Name ..'">')
		elseif not name then
			table.insert(control._raw,'</font>')
		end
		
		return control
	end

	function control:Size(number: number | boolean): typeof(control)
		if typeof(number) == 'number' then
			table.insert(control._raw,'<font size="'.. number ..'">')
		elseif not number then
			table.insert(control._raw,'</font>')
		end
		
		return control
	end

	function control:Color(color: Color3 | boolean): typeof(control)
		if typeof(color) == 'Color3' then
			table.insert(control._raw,'<font color="'.. FormatColor(color) ..'">')
		elseif not color then
			table.insert(control._raw,'</font>')
		end
		
		return control
	end

	function control:GetRaw(): typeof(control)
		return table.concat(control._append)
	end

	function control:GetText(): typeof(control)
		return table.concat(control._raw)
	end
	
	return control
end

--[=[
	Create a keybind with an optional mobile button
	
	@param name string -- the internal name of the keybind, be unique
	@return KeybindObject
]=]
function Interface.Keybind(name: string): typeof(Interface.Keybind())
	Input:CreateButton(name,Container)
	
	if not Input._InputCache[name] then
		Input._InputCache[name] = {}
	end
	
	local control = {}
	
	function control._Verify(): nil
		if Input._InputCache[name]['Keys'] and Input._InputCache[name]['Function'] then
			Input._InputCache[name]['Verify'] = true
		else
			Input._InputCache[name]['Verify'] = false
		end
	end
	
	function control:Enabled(state: boolean): nil
		Input._InputCache[name]['Enabled'] = state
		Input:EnableButton(name,state)
		control._Verify()
	end
	
	function control:Keybinds(...): nil
		local capture = {}
		
		for index,key in pairs({...}) do
			assert(typeof(key) == 'EnumItem')
			table.insert(capture,key)
		end
		
		Input._InputCache[name]['Keys'] = capture
		control._Verify()
	end
	
	function control:Mobile(state: boolean, image: string?): nil
		Input._InputCache[name]['Mobile'] = state
		local button = Input:GetButton(name)
		
		if button then
			button.Visible = state
			if image then
				button.Icon.Image = image
			end
		end
		
		control._Verify()
	end
	
	function control:Hook(code: () -> ()): nil
		if Input._InputCache[name]['Function'] then
			Input._InputCache[name]['Function'] = nil
		end
		
		Input._InputCache[name]['Function'] = code
		control._Verify()
	end
	
	function control:Destroy(): typeof(control:Destroy())
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
	@return nil
]=]
function Interface:Disconnect(name: string): nil
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
function Interface:Update(name: string, keys: table): boolean
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
	@return nil
]=]
function Interface:Began(name: string, keys: table, code: (any) -> nil): nil
	for index,key in pairs(keys) do
		assert(typeof(key) == 'EnumItem')
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
	@return nil
]=]
function Interface:Ended(name: string, keys: table, code: (any) -> nil): nil
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
	@return nil
]=]
function Interface:Tapped(name: string, code: (any) -> nil): nil
	assert(typeof(name) == 'string')
	assert(typeof(code) == 'function')
	
	Input._InputTouchCallbacks[name] = {
		['Code'] = code;
		['Type'] = 'Ended';
	}
end

--[=[
	Play an animation located in the Animator lib
	
	@param name string -- an animation name & function in Animator
	@param element GuiObject -- a GuiObject to animate
	@param async boolean -- if the animation should yield or not
	@return nil
]=]
function Interface:Play(name: string, element: GuiObject, async: boolean?): nil
	assert(Animator[name] ~= nil)
	
	local code = Animator[name]
	if async then
		code(element)
	else
		Manager.wrap(code,element)
	end
end

--[=[
	Return a component on an element
	
	@param element GuiObject -- the element to get a component from
	@return Component?
]=]
function Interface:Get(element: GuiObject): typeof(Interface:Create())?
	for tag,data in pairs(Interface._ComponentCache) do
		for index,obj in pairs(data) do
			if index ~= element then continue end
			return obj
		end
	end
end

--[=[
	Returns all the components on a tag in PlayerGui
	
	@param tag string -- the tag to get from
	@return table
]=]
function Interface:GetAll(tag: string): table
	return Interface._ComponentCache[tag]
end

--[=[
	Get the first component on a tag in the PlayerGui
	
	@param tag string
	@return Component?
]=]
function Interface:GetComponent(tag: string): typeof(Interface:Create())?
	local tags = Interface:GetAll(tag)
	for index,component in pairs(tags) do
		return component
	end
end

--[=[
	Fires a function with the tag
	
	@param name string -- the name of the binding
	@param ...? any -- optional parameters to pass
	@return nil
]=]
function Interface:Fire(name: string, ...): nil
	assert(Components._Bindings[name],"Attempted to fire non-existant binding on '"..name.."'")
	
	local code = Components._Bindings[name]
	Manager.wrap(code,...)
end

--[=[
	Create a component out of a collection service tag!
	
	@param tag string -- the CollectionService tag to track
	@param code function -- the function to run when you get a component
	@return nil
]=]
function Interface:Create(tag: string, code: (any) -> nil): nil
	assert(Interface._ComponentCache[tag] == nil,"tag is claimed")
	
	Interface._ComponentCache[tag] = {}
	Interface._ComponentCode[tag] = code
	
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(component)
		Manager.wrap(BindComponent,tag,component)
	end)
	
	local tagged = CollectionService:GetTagged(tag)
	for index,component in pairs(tagged) do
		Manager.wrap(BindComponent,tag,component)
	end
end

--[=[
	Redirects to either Interface:Create() or Interface:GetComponent(), streamlines shortcutting to Interface()
	
	@param tag string -- the CollectionService tag to track
	@param code? function -- the function to run when you get a component
	@return typeof(Interface:Create())?
]=]
function Interface:__call(tag: string, code: ((any) -> nil)?): typeof(Interface:Create())?
	if not code and Interface._ComponentCache[tag] then
		return Interface:GetComponent(tag)
	end
	
	Interface:Create(tag,code)
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