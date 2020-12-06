--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Internal Modular Component System
]=]

local Components = {}
Components._Name = 'Modular Component System'
Components._Error = '[MCS]: '
Components._Bindings = {}

local Loader = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))
local Manager = Loader('Manager')
local RunService = Loader['RunService']

--[=[
	Construct a new component out of a pre-existing element
	
	@param element GuiObject -- the main component
	@return Class
]=]
function Components.new(element: GuiObject): Class
	local config = element:FindFirstChildWhichIsA('Configuration') do
		if not config then
			config = Instance.new('Configuration')
			config.Name = 'MCS_'..element.Name
			config.Parent = element
		end
	end
	
	return setmetatable({
		element = element;
		config = config;
	},Components)
end

--[=[
	Bind a function to a codename
	
	@param name string -- the name of the binding
	@param code function -- the function to bind
	@return nil
]=]
function Components:Bind(name: string, code: (any) -> nil): nil
	assert(Components._Bindings[name] == nil,"Attempted to overwrite binding on '"..name.."'")
	
	Components._Bindings[name] = code
end

--[=[
	Unbind a codename
	
	@param name string -- the name of the binding
	@return nil
]=]
function Components:Unbind(name: string): nil
	Components._Bindings[name] = nil
end

--[=[
	Fire a binded function on a codename
	
	@param name string -- the name of the binding
	@param ...? any -- optional parameters to pass
	@return nil
]=]
function Components:Fire(name: string, ...): nil
	assert(Components._Bindings[name],"Attempted to fire a non-existant binding on '"..name.."'")
	
	Manager.wrap(Components._Bindings[name],...)
end

--[=[
	Get an attribute value on the component. Checks for value objects first
	
	@param name string -- name of the attribute
	@return Value any?
]=]
function Components:Get(name: string): any?
	local obj = self.config:FindFirstChild(name)
	
	if obj then
		return obj.Value
	else
		return self.config:GetAttribute(name)
	end
end

--[=[
	Set an attribute value on the component. Checks for value objects first
	
	@param name string -- name of the attribute
	@param value any -- the value to set on an attribute
	@return Value any
]=]
function Components:Set(name: string, value: any): any?
	local obj = self.config:FindFirstChild(name)
	
	if obj then
		obj.Value = value
	else
		self.config:SetAttribute(name,value)
	end
	
	return value
end

--[=[
	Update a known attribute with a value & increment numbers
	
	@param name string -- the name of the attribute
	@param value any -- the value to update on an attribute
	@return Value any
]=]
function Components:Update(name: string, value: any): any
	local get = self:Get(name)
	
	assert(get ~= nil,Components._Error.."Attempted to update nil attribute '"..name.."'")
	
	if typeof(get) == 'number' and typeof(value) == 'number' then
		get += value
		self:Set(name,get)
	else
		self:Set(name,value)
	end
	
	return self:Get(name)
end

--[=[
	Bind a function to an attribute that changes. Checks for value objects first
	
	@param name string -- the name of the attribute
	@param code function -- the function to connect
	@return RBXScriptSignal
]=]
function Components:Attribute(name: string, code: (any, any) -> nil): RBXScriptSignal
	local last = self:Get(name)
	
	assert(last ~= nil,Components._Error.."Attempted to bind to nil attribute '"..name.."'")
	
	Manager.wrap(code,last,last)
	
	local obj = self.config:FindFirstChild(name)
	local signal; do
		if obj then
			signal = obj.Changed:Connect(function(new)
				Manager.wrap(code,new,last)
				
				last = new
			end)
		else
			signal = self.config:GetAttributeChangedSignal(name):Connect(function()
				local new = self:Get(name)
				
				Manager.wrap(code,new,last)
				
				last = new
			end)
		end
	end
	
	Manager:ConnectKey('attribute_'..name,signal)
	
	return signal
end

--[=[
	Connect an event to a GuiObject apart of the component
	
	@param object GuiObject -- the object to connect
	@param event string -- the connection type
	@param code function -- the function to connect
	@return RBXScriptSignal
]=]
function Components:Connect(object: GuiObject, event: string, code: (any) -> nil): RBXScriptSignal
	local signal = object[event]:Connect(function(...)
		code(...)
	end)
	
	Manager:ConnectKey('connection_'..object.Name,signal)
	
	return signal
end

--[=[
	Hook a function to a lifecycle event which fires when the component is visible
	
	@param name string -- the name of the lifecycle
	@param code function -- the function to run
	@return RBXScriptSignal
]=]
function Components:Lifecycle(name: string, code: (number) -> nil): RBXScriptSignal
	local signal = RunService.RenderStepped:Connect(function(delta)
		if self.element.Visible then
			code(delta)
		end
	end)
	
	Manager:ConnectKey('lifecycle_'..name,signal)
	
	return signal
end

--[=[
	Destroys all the signals connected to a name no matter the type
	
	@param name string -- name of the signal key connected
	@return nil
]=]
function Components:Destroy(name: string): nil
	Manager:DisconnectKey('attribute_'..name)
	Manager:DisconnectKey('connection_'..name)
	Manager:DisconnectKey('lifecycle_'..name)
end

--[=[
	A custom index method which handles unknown or known indices
	
	@param index any -- the index being called on the component
	@return any?
]=]
function Components:__index(index: any): any?
	if Components[index] then
		return Components[index]
	end
	
	if index == self.element.Name then
		return self.element
	end
	
	if self.element[index] then
		return self.element[index]
	end
	
	error(index..' is not a valid member of '..self.element:GetFullName()..' "'..self.element.ClassName..'"',2)
end

--[=[
	Shorten getting an attribute attached to the component
	
	@param name string -- name of the component
	@return Value any
]=]
function Components:__call(name: string): any?
	return self:Get(name)
end

return Components