--[=[
	@Author: Gavin Rosenthal - Mullets
	@Author: Lucas Wolschick - codes4breakfast
	@Desc: Internal input functions
]=]

local Input = {}
Input._Objects = {}
Input._BindCache = {}
Input._InputCache = {}
Input._InputCallbacks = {}
Input._InputTouchCallbacks = {}
Input._Buttons = {}

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local Manager = require("Manager")
local UserInputService = game:GetService("UserInputService")

--[=[
	Find the center of a map based on a number
	
	@return number
	@private
]=]
local function Map(x: number, x0: number, x1: number, y0: number, y1: number): number
	return (x - x0) / (x1 - x0) * (y1 - y0) + y0
end

--[=[
	Create a table with the first row being 3 and growing +1 thereafter
	
	@param num number -- the provided number to work with
	@return Locations
	@private
]=]
function Input.MakePositioning(num: number): table
	local accum = num
	local start_row = 3
	local increment = 1
	local proxy = {}

	while accum > 0 do
		local row_size = start_row + #proxy * increment
		if accum >= row_size then
			table.insert(proxy, row_size)
			accum -= row_size
		else
			table.insert(proxy, accum)
			accum = 0
		end
	end

	return proxy
end

--[=[
	Get the positions on a quarter-circle with a provided config
	
	@param config table -- the configuration to work with
	@return Positions
	@private
]=]
function Input.GetPositioning(config: table): table
	local res = config.RESOLUTION

	local b_pos = config.CENTER_BUTTON_POSITION
	local min_radius
	if b_pos.X / res.X > b_pos.Y / res.Y then
		min_radius = res.X - b_pos.X
	else
		min_radius = res.Y - b_pos.Y
	end
	if config.MIN_RADIUS then
		min_radius = math.max(min_radius, config.MIN_RADIUS)
	end

	local approx_angle = (math.pi / 2) / (config.N_BUTTONS + 1)
	local factor = math.sqrt(2 + 2 * math.cos(approx_angle))
	local approx_space = factor * 0.5 * (config.BUTTON_SIZE.X.Offset + config.BUTTON_SIZE.X.Scale * res.X)
	local min_space = (approx_space + config.BUTTON_PADDING) * (config.N_BUTTONS + 1)
	local radius = math.max(
		min_space / (0.5 * math.pi),
		min_radius + config.BUTTON_SIZE.X.Offset + config.MIN_RADIUS_PADDING
	)

	local corner = b_pos + config.CENTER_BUTTON_SIZE
	local x_offset = res.X - corner.X
	local y_offset = res.Y - corner.Y

	local extra_angle_x = math.asin(x_offset / radius)
	local extra_angle_y = math.asin(y_offset / radius)

	local result = { list = {}, radius = radius }
	for index = 1, config.N_BUTTONS do
		local angle = (math.pi / 2) / (config.N_BUTTONS + 1) * index

		angle = Map(angle, 0, math.pi / 2, -extra_angle_x, math.pi / 2 + extra_angle_y)
		result.list[index] = UDim2.new(
			0,
			res.X - x_offset + math.cos(math.pi / 2 + angle) * radius,
			0,
			res.Y - y_offset - math.sin(math.pi / 2 + angle) * radius
		)
	end

	return result
end

--[=[
	Using rows, get the positions of multiple rows and spots
	
	@param buttons table -- list of button positions generated by MakePositioning
	@param config table -- the configuration to work with
	@return Positions
	@private
]=]
function Input.GetPositionsWithRows(buttons: table, config: table): table
	local result = {}

	local lastOffset = config.MIN_RADIUS or 0
	for _, nButtons in ipairs(buttons) do
		config.N_BUTTONS = nButtons
		config.MIN_RADIUS = lastOffset

		local positions = Input.GetPositioning(config)
		table.move(positions.list, 1, #positions.list, #result + 1, result)

		lastOffset = positions.radius
	end

	return result
end

--[=[
	Creates a button object

	@param uid string -- the unique identifier for the keybind
	@param name string -- the name derived from the uid
	@param parent GuiObject? -- the container for a button if present
]=]
function Input.Button(uid: string, name: string, parent: GuiObject?): typeof(Input.Button())
	local toggle = {
		button = nil,
	}

	do
		local button = Instance.new("ImageButton")
		button.Name = name
		button.BackgroundTransparency = 1
		button.Image = "rbxassetid://3376854277"
		button.ImageColor3 = Color3.fromRGB(0, 0, 0)
		button.ImageTransparency = 0.5
		button.Visible = false
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.Image = ""
		icon.ImageColor3 = Color3.fromRGB(0, 0, 0)
		icon.ImageTransparency = 0.5
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.new(0.5, 0, 0.5, 0)
		icon.Size = UDim2.new(0.8, 0, 0.8, 0)
		icon.ZIndex = 10
		icon.Parent = button
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromScale(0.5, 0.5)
		title.AnchorPoint = Vector2.new(0.5, 0.5)
		title.Size = UDim2.fromScale(0.8, 0.8)
		title.TextScaled = true
		title.Font = Enum.Font.SourceSansBold
		title.TextColor3 = Color3.fromRGB(0, 0, 0)
		title.ZIndex = 5
		title.Text = ""
		title.Parent = button

		toggle.button = button
		if parent then
			button.Parent = parent
		end

		Manager.ConnectKey(
			uid,
			button.MouseButton1Down:Connect(function()
				button.ImageColor3 = Color3.fromRGB(255, 255, 255)
				button.ImageTransparency = 0.75
			end)
		)

		Manager.ConnectKey(
			uid,
			button.MouseButton1Up:Connect(function()
				button.ImageColor3 = Color3.fromRGB(0, 0, 0)
				button.ImageTransparency = 0.5
			end)
		)

		Manager.ConnectKey(
			uid,
			button.MouseLeave:Connect(function()
				button.ImageColor3 = Color3.fromRGB(0, 0, 0)
				button.ImageTransparency = 0.5
			end)
		)

		Manager.ConnectKey(
			uid,
			button.InputBegan:Connect(function(obj)
				local data = Input._Objects[uid]

				if not data then
					return
				end

				if not data._enabled then
					return
				end

				if data._hook then
					Manager.Wrap(data._hook, obj)
				end

				if data._bind then
					Manager.Wrap(data._bind, Enum.UserInputState.Begin, obj)
				end
			end)
		)

		Manager.ConnectKey(
			uid,
			button.InputChanged:Connect(function(obj)
				local data = Input._Objects[uid]

				if not data then
					return
				end

				if not data._enabled then
					return
				end

				if data._bind then
					Manager.Wrap(data._bind, Enum.UserInputState.Change, obj)
				end
			end)
		)

		Manager.ConnectKey(
			uid,
			button.InputEnded:Connect(function(obj)
				local data = Input._Objects[uid]

				if not data then
					return
				end

				if not data._enabled then
					return
				end

				if data._bind then
					Manager.Wrap(data._bind, Enum.UserInputState.End, obj)
				end
			end)
		)
	end

	function toggle:Get(): ImageButton?
		if self.button.Parent ~= nil then
			return self.button
		end
	end

	function toggle:Set(container: GuiObject?): ImageButton?
		if container then
			self.button.Parent = container
			return self.button
		end
	end

	function toggle:Enable(state: boolean): nil
		local button = self.button

		if state then
			button.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			button.Icon.ImageTransparency = 0
		else
			button.Title.TextColor3 = Color3.fromRGB(0, 0, 0)
			button.Icon.ImageColor3 = Color3.fromRGB(0, 0, 0)
			button.Icon.ImageTransparency = 0.5
		end
	end

	return toggle
end

--[=[
	Enable a currently-created buttons state
	
	@param name string -- name of the button
	@param state boolean -- the state of the button
	@return nil
	@private
]=]
function Input.EnableButton(name: string, state: boolean): nil
	local button = Input.GetButton(name)
	local data = Input._InputCache[name]

	if not button or not data then
		return
	end

	if state then
		button.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		button.Icon.ImageTransparency = 0
	else
		button.Icon.ImageColor3 = Color3.fromRGB(0, 0, 0)
		button.Icon.ImageTransparency = 0.5
	end
end

if Manager.IsClient then
	UserInputService.InputBegan:Connect(function(obj, processed)
		if processed then
			return
		end

		for _, data in pairs(Input._Objects) do
			if not data._enabled then
				continue
			end

			if not table.find(data._keys, obj.KeyCode) and not table.find(data._keys, obj.UserInputType) then
				continue
			end

			if data._hook then
				Manager.Wrap(data._hook, obj)
			end

			if data._bind then
				Manager.Wrap(data._bind, Enum.UserInputState.Begin, obj)
			end
		end

		for _, data in pairs(Input._InputCallbacks) do
			if data["Type"] == "Began" then
				if table.find(data["Keys"], obj.KeyCode) or table.find(data["Keys"], obj.UserInputType) then
					local code = data["Code"]
					Manager.Wrap(code, obj)
				end
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(obj, processed)
		if processed then
			return
		end

		for _, data in pairs(Input._Objects) do
			if not data._enabled then
				continue
			end

			if not table.find(data._keys, obj.KeyCode) and not table.find(data._keys, obj.UserInputType) then
				continue
			end

			if data._bind then
				Manager.Wrap(data._bind, Enum.UserInputState.Change, obj)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(obj, processed)
		if processed then
			return
		end

		for _, data in pairs(Input._Objects) do
			if not data._enabled then
				continue
			end

			if not table.find(data._keys, obj.KeyCode) and not table.find(data._keys, obj.UserInputType) then
				continue
			end

			if data._bind then
				Manager.Wrap(data._bind, Enum.UserInputState.End, obj)
			end
		end

		for _, data in pairs(Input._InputCallbacks) do
			if data["Type"] == "Ended" then
				if table.find(data["Keys"], obj.KeyCode) or table.find(data["Keys"], obj.UserInputType) then
					local code = data["Code"]
					Manager.Wrap(code, obj)
				end
			end
		end
	end)

	UserInputService.TouchTap:Connect(function(obj, processed)
		if processed then
			return
		end
		for _, data in pairs(Input._InputTouchCallbacks) do
			local code = data["Code"]
			Manager.Wrap(code, obj)
		end
	end)
end

return Input
