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

local Interface = {}
Interface._Name = string.upper(script.Name)
Interface._ComponentCode = {}
Interface._ComponentCache = {}
Interface._AssignSizesCache = {}
Interface._AssignSizesOveride = false

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local Manager = require("Manager")
local Input = require(script:WaitForChild("Input"))

local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Camera = Workspace.CurrentCamera
local Container

--[=[
	A local function to convert a color3 to RichText format
	
	@param color Color3 -- the color3 to convert
	@return string -- rgb(color.r,color.g,color.b)
]=]
local function FormatColor(color: Color3): string
	return string.format(
		"rgb(%i,%i,%i)",
		math.floor(color.R * 255),
		math.floor(color.G * 255),
		math.floor(color.B * 255)
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
	local viewportSize = Camera.ViewportSize
	do
		if viewportSize.Y <= 700 then
			Interface._AssignSizesOveride = true
		else
			Interface._AssignSizesOveride = false
		end
	end

	local Size = Interface._AssignSizesCache[element]["Size"]
	if UserInputService.TouchEnabled or Interface._AssignSizesOveride then

		local uiSize = (viewportSize.X / viewportSize.Y) * scale
		local clampX = math.clamp(Size.X.Scale * uiSize, min, max)
		local clampY = math.clamp(Size.Y.Scale * uiSize, min, max)

		element.Size = UDim2.new(clampX, 0, clampY, 0)
	else
		local uiSize
		do
			if (viewportSize.X / viewportSize.Y) >= 2 then
				uiSize = (viewportSize.X / viewportSize.Y) * (scale / 3.5)
			else
				uiSize = (viewportSize.X / viewportSize.Y) * (scale / 2)
			end
		end

		local clampX = math.clamp(Size.X.Scale * uiSize, min, max)
		local clampY = math.clamp(Size.Y.Scale * uiSize, min, max)

		element.Size = UDim2.new(clampX, 0, clampY, 0)

		local absoluteY = element.AbsoluteSize.Y
		if absoluteY < 36 then
			ResizeContainer(element, scale * 2, min, max)
		end
	end
end

--[=[
	Returns whether the clients device is a computer
	
	@return boolean
	@outline IsComputer
]=]
function Interface.IsComputer(): boolean
	local check = Interface.IsKeyboard() and Interface.IsMouse() and true or false
	return check
end

--[=[
	Returns whether the clients device is a mobile device
	
	@return boolean
	@outline IsMobile
]=]
function Interface.IsMobile(): boolean
	local check = Interface.IsTouch() and not Interface.IsKeyboard() and true or false
	return check
end

--[=[
	Returns whether the clients device is a console
	
	@return boolean
	@outline IsConsole
]=]
function Interface.IsConsole(): boolean
	return GuiService:IsTenFootInterface()
end

--[=[
	Returns whether the clients device has a keyboard
	
	@return boolean
	@outline IsKeyboard
]=]
function Interface.IsKeyboard(): boolean
	return UserInputService.KeyboardEnabled
end

--[=[
	Returns whether the clients device has a mouse
	
	@return boolean
	@outline IsMouse
]=]
function Interface.IsMouse(): boolean
	return UserInputService.MouseEnabled
end

--[=[
	Returns whether the clients device is touch enabled
	
	@return boolean
	@outline IsTouch
]=]
function Interface.IsTouch(): boolean
	return UserInputService.TouchEnabled
end

--[=[
	Returns whether the clients device has a controller
	
	@return boolean
	@outline IsGamepad
]=]
function Interface.IsGamepad(): boolean
	return UserInputService.GamepadEnabled
end

--[=[
	Returns whether the clients device is virtual reality
	
	@return boolean
	@outline IsVR
]=]
function Interface.IsVR(): boolean
	return UserInputService.VREnabled
end

--[=[
	Create an AssignSizes Object and connect an element
	
	@param element Instance -- a GuiObject to assign a size
	@param scale number -- the scale of which to size the element
	@param min number -- the minimum size of the element
	@param max number -- the maximum size of the element
	@return nil
	@outline AssignSizes
]=]
function Interface.AssignSizes(element: GuiObject, scale: number, min: number, max: number): typeof(Interface.AssignSizes())
	local control = {}
	control._element = element
	control._scale = scale
	control._min = min
	control._max = max

	function control:Update(_scale: number, _min: number, _max: number): typeof(control)
		control._scale = _scale or control._scale
		control._min = _min or control._min
		control._max = _max or control._max

		ResizeContainer(control._element, control._scale, control._min, control._max)

		return control
	end

	function control:Changed(code: () -> ()): typeof(control)
		local file = Interface._AssignSizesCache[element]

		if file ~= nil then
			file["Code"] = code
			Interface._AssignSizesCache[element] = file
		end

		return control
	end

	function control:Disconnect(): typeof(control)
		local file = Interface._AssignSizesCache[element]

		if file ~= nil then
			file["Event"]:Disconnect()
			file["Event"] = nil
			file["Code"] = nil
			Interface._AssignSizesCache[element] = file
		end

		return control
	end

	local file = Interface._AssignSizesCache[element]

	if file and file["Event"] ~= nil then
		file["Event"]:Disconnect()
	else
		file = {
			["Event"] = nil,
			["Code"] = nil,
			["Size"] = element.Size,
		}
	end

	if file["Size"] == nil then
		file["Size"] = element.Size
	end

	file["event"] = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		ResizeContainer(control._element, control._scale, control._min, control._max)
		local import = Interface._AssignSizesCache[element]
		if import and import["Code"] then
			import["Code"]()
		end
	end)

	Interface._AssignSizesCache[element] = file

	ResizeContainer(control._element, control._scale, control._min, control._max)

	return control
end

--[=[
	Create a RichText Object
	
	@return RichTextObject
	@outline RichText
]=]
function Interface.RichText(): typeof(Interface.RichText())
	local control = {}
	control._raw = {}
	control._append = {}

	function control:Append(value: string | table): typeof(control)
		if typeof(value) == "string" then
			table.insert(control._raw, value)
			table.insert(control._append, value)
		elseif typeof(value) == "table" then
			for _, format in ipairs(value._raw) do
				table.insert(control._raw, format)
				table.insert(control._append, format)
			end
		end

		return control
	end

	function control:Bold(state: boolean): typeof(control)
		if state then
			table.insert(control._raw, "<b>")
		else
			table.insert(control._raw, "</b>")
		end

		return control
	end

	function control:Italic(state: boolean): typeof(control)
		if state then
			table.insert(control._raw, "<i>")
		else
			table.insert(control._raw, "</i>")
		end

		return control
	end

	function control:Underline(state: boolean): typeof(control)
		if state then
			table.insert(control._raw, "<u>")
		else
			table.insert(control._raw, "</u>")
		end

		return control
	end

	function control:Strike(state: boolean): typeof(control)
		if state then
			table.insert(control._raw, "<s>")
		else
			table.insert(control._raw, "</s>")
		end

		return control
	end

	function control:Comment(state: boolean): typeof(control)
		if state then
			table.insert(control._raw, "<!--")
		else
			table.insert(control._raw, "-->")
		end

		return self
	end

	function control:Font(name: string | EnumItem | boolean): typeof(control)
		if typeof(name) == "string" then
			table.insert(control._raw, "<font face=\"" .. name .. "\">")
		elseif typeof(name) == "EnumItem" then
			table.insert(control._raw, "<font face=\"" .. name.Name .. "\">")
		elseif not name then
			table.insert(control._raw, "</font>")
		end

		return control
	end

	function control:Size(number: number | boolean): typeof(control)
		if typeof(number) == "number" then
			table.insert(control._raw, "<font size=\"" .. number .. "\">")
		elseif not number then
			table.insert(control._raw, "</font>")
		end

		return control
	end

	function control:Color(color: Color3 | boolean): typeof(control)
		if typeof(color) == "Color3" then
			table.insert(control._raw, "<font color=\"" .. FormatColor(color) .. "\">")
		elseif not color then
			table.insert(control._raw, "</font>")
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
	@outline Keybind
]=]
function Interface.Keybind(name: string): typeof(Interface.Keybind())
	local uid = "KEYBIND_" .. name

	if Input._Objects[uid] then
		return Input._Objects[uid]
	end

	local keybind = {
		_uid = uid,
		_name = name,
		_button = Input.Button(uid, name, Container),
		_enabled = false,

		_keys = nil,
		_mobile = nil,
		_icon = nil,
		_hook = nil,
		_bind = nil,
	}

	--[=[
		Enable the keybind object

		@param state Boolean? -- if true, enables the keybind, false/nil disables it
		@return self
	]=]
	function keybind:Enabled(state: boolean?): keybind
		state = state ~= nil and state or false

		self._enabled = state
		self._button:Enable(state)

		Input._Objects[uid] = self
		return self
	end

	--[=[
		Set the keybinds in the object

		@param ... table | tuple -- must be EnumItems, provide a table OR tuple - converts to table
		@return self
	]=]
	function keybind:Keybinds(...): keybind
		local keys = { ... }
		keys = typeof(keys[1]) == "table" and keys[1] or keys

		for _, key in ipairs(keys) do
			assert(typeof(key) == "EnumItem", "Keybind must be an EnumItem")
		end

		self._keys = keys

		Input._Objects[uid] = self
		return self
	end

	--[=[
		Enable mobile usage

		@param state boolean -- whether or not to enable mobile
		@param icon string | boolean | nil -- an optional icon, false to remove the icon
		@return self
	]=]
	function keybind:Mobile(state: boolean, icon: string | boolean | nil): keybind
		self._mobile = state ~= nil and state or false
		self._icon = self._icon ~= nil and icon ~= false and self._icon or icon

		local button = self._button:Get()
		if button ~= nil then
			button.Visible = state
			if icon then
				button.Title.Text = ""
				button.Icon.Image = icon
			elseif not self._icon then
				button.Icon.Image = ""
				button.Title.Text = name
			end
		end

		Input._Objects[uid] = self
		return self
	end

	--[=[
		Hook a cheap function to the InputBegan of the keybind
		
		@param code function -- the function to hook
		@return self
	]=]
	function keybind:Hook(code: (InputObject) -> nil): keybind
		assert(typeof(code) == "function", "'Hook' requires a function parameter")

		self._hook = code

		Input._Objects[uid] = self
		return self
	end

	--[=[
		Bind a more expensive function to Began/Changed/Ended
		
		@param code function -- the function to bind, has higher priority than hook
		@return self
	]=]
	function keybind:Bind(code: (InputState, InputObject) -> nil): keybind
		assert(typeof(code) == "function", "'Bind' requires a function parameter")

		self._bind = code

		Input._Objects[uid] = self
		return self
	end

	--[=[
		Disconnects both Hook and Bind functions only

		@return nil
	]=]
	function keybind:Disconnect(): nil
		self._bind = nil
		self._hook = nil

		Input._Objects[uid] = self
	end

	--[=[
		Completely destroys the entire keybind object

		@return nil
	]=]
	function keybind:Destroy(): nil
		if not Input._Objects[uid] then
			return nil
		end

		local button = self._button:Get()
		if button ~= nil then
			button:Destroy()
		end

		Manager.DisconnectKey(uid)
		Input._Objects[uid] = nil
	end

	Input._Objects[uid] = keybind
	return keybind
end

--[=[
	Disconnect a keybind
	
	@param name string -- the name of the keybind to find
	@return nil
	@outline Disconnect
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
	@outline Update
]=]
function Interface:Update(name: string, keys: table): boolean
	for _, key in pairs(keys) do
		assert(typeof(key) == "EnumItem")
	end

	if Input._InputCallbacks[name] then
		Input._InputCallbacks[name]["Keys"] = keys
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
	@outline Began
]=]
function Interface:Began(name: string, keys: table, code: (any) -> nil): nil
	for _, key in pairs(keys) do
		assert(typeof(key) == "EnumItem")
	end

	Interface:Disconnect(name)
	Input._InputCallbacks[name] = {
		["Keys"] = keys,
		["Code"] = code,
		["Type"] = "Began",
	}
end

--[=[
	Track a keybind when UIS.InputEnded fires
	
	@param name string -- the name of the keybind
	@param keys table -- a list of the enum keycodes
	@param code function -- a callback function when a key depresses
	@return nil
	@outline Ended
]=]
function Interface:Ended(name: string, keys: table, code: (any) -> nil): nil
	for _, key in pairs(keys) do
		assert(typeof(key) == "EnumItem")
	end

	Interface:Disconnect(name)
	Input._InputCallbacks[name] = {
		["Keys"] = keys,
		["Code"] = code,
		["Type"] = "Ended",
	}
end

--[=[
	Track a keybind when UIS.TouchTap fires
	
	@param name string -- the name of the keybind
	@param code function -- a callback function when there is a tap
	@return nil
	@outline Tapped
]=]
function Interface:Tapped(name: string, code: (any) -> nil): nil
	assert(typeof(name) == "string")
	assert(typeof(code) == "function")

	Input._InputTouchCallbacks[name] = {
		["Code"] = code,
		["Type"] = "Ended",
	}
end

Manager.Wrap(function()
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
		local PlayerGui = Player:WaitForChild("PlayerGui")

		Container = Instance.new("ScreenGui")
		do
			Container.Name = "DiceMobile"
			Container.Enabled = false
			Container.ResetOnSpawn = false
			Container.Parent = PlayerGui
		end

		if Interface.Mobile then
			Container.Enabled = true

			local Size, Jump
			do
				local TouchGui = PlayerGui:WaitForChild("TouchGui", math.huge)
				local TouchFrame = TouchGui:WaitForChild("TouchControlFrame", math.huge)
				Jump = TouchFrame:WaitForChild("JumpButton", math.huge)
				Manager.WaitForCharacter(Player)
				Size = UDim2.fromOffset(Jump.Size.X.Offset / 1.25, Jump.Size.Y.Offset / 1.25)
			end

			local Log = {}
			local Config = {
				CENTER_BUTTON_POSITION = Jump.AbsolutePosition,
				CENTER_BUTTON_SIZE = Jump.AbsoluteSize,
				N_BUTTONS = 4,
				MIN_RADIUS_PADDING = 10,
				BUTTON_PADDING = 5,
				BUTTON_SIZE = UDim2.fromOffset(Jump.Size.X.Offset / 1.25, Jump.Size.Y.Offset / 1.25),
				RESOLUTION = Container.AbsoluteSize,
			}

			local function Organize()
				local generate = Input.MakePositioning(#Log)
				Config.MIN_RADIUS = 0
				local positions = Input.GetPositionsWithRows(generate, Config)
				for index, button in ipairs(Log) do
					if not button then
						continue
					end
					button.Position = positions[index]
				end
			end

			for _, button in ipairs(Container:GetChildren()) do
				if table.find(Log, button) then
					continue
				end
				table.insert(Log, button)
				button.Size = Size
				Organize()
			end

			Container.ChildAdded:Connect(function(button)
				if table.find(Log, button) then
					return
				end
				table.insert(Log, button)
				button.Size = Size
				Organize()
			end)
		end
	end
end)

return Interface
