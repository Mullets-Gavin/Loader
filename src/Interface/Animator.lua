--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: An Animation library for GuiObjects
]=]

--[=[
[DOCUMENTATION]:
	Simply use Tiffany's tag editor & apply the tags listed below
	to GuiObjects which take the given events! Settings are attributes
	to the script.
	
	Tag editor:
	https://www.roblox.com/library/948084095/Tag-Editor
]=]

local require = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))
local Manager = require('Manager')

local RunService = game:GetService('RunService')
local HttpService = game:GetService('HttpService')
local CollectionService = game:GetService('CollectionService')
local Config = script:WaitForChild('Config')

local Animator = {}
Animator.SignalCache = {}
Animator.ElementCache = {}
Animator.IdleAnimations = {}
Animator.HoverAnimations = {}
Animator.ToggleAnimations = {}
Animator.ButtonAnimations = {}
Animator.UnstableAnimations = {}
Animator.Prefixes = {
	['ButtonAnimations'] = 'Button_';
	['HoverAnimations'] = 'Hover_';
	['ToggleAnimations'] = 'Toggle_';
	['IdleAnimations'] = 'Idle_';
	['UnstableAnimations'] = 'Unstable_';
}

local Length = 0.1
local Events = {
	['OnClick'] = 'MouseButton1Click';
	['OnEnter'] = 'MouseEnter';
	['OnLeave'] = 'MouseLeave';
	['OnPress'] = 'MouseButton1Down';
	['OnLetgo'] = 'MouseButton1Up';
	['OnEvent'] = 'Heartbeat';
	['OnCallback'] = '()';
}

----------------------------
-- Internal Get Functions --
----------------------------

local function GetOriginal(element: GuiObject): typeof(Vector3.new()) & boolean
	local isImage = element:IsA('ImageButton') or element:IsA('ImageLabel')
	
	if not Animator.ElementCache[element] then
		Animator.ElementCache[element] = {
			['AnchorPoint'] = element.AnchorPoint;
			['Position'] = element.Position;
			['Size'] = element.Size;
			
			['BackgroundColor3'] = element.BackgroundColor3;
			['BackgroundTransparency'] = element.BackgroundTransparency;
			['BorderColor3'] = element.BorderColor3;
			
			['ImageColor3'] = isImage and element.ImageColor3 or nil;
			['ImageTransparency'] = isImage and element.ImageTransparency or nil;
		}
	end
	
	return Animator.ElementCache[element],isImage
end

local function GetSignal(element,tag,guid): table
	local cache = Animator.SignalCache[element] or {}
	
	if tag == nil and guid == nil then
		return cache
	elseif tag and guid == nil then
		local proxy = {}
		
		for index,content in pairs(cache) do
			if content.Tag ~= tag then continue end
			
			table.insert(proxy,content.GUID)
		end
		
		return proxy
	end
	
	table.insert(cache, {
		['Tag'] = tag;
		['GUID'] = guid;
	})
	
	Animator.SignalCache[element] = cache
	return GetSignal(element,tag)
end

local function GetIntensity(tag: string): number
	local findValueBase = Config:FindFirstChild(tag)
	
	if findValueBase then
		return findValueBase.Value
	end
	
	return Config:GetAttribute(tag)
end

--------------------------
-- Internal Connections --
--------------------------

local function SearchAnimations(search: string): table?
	for index,prefix in pairs(Animator.Prefixes) do
		local library = Animator[index]
		
		for tag,animation in pairs(library) do
			if prefix..tag ~= search then continue end
			
			return animation,prefix
		end
	end
end

local function ConnectAnimations(tag: string, element: GuiObject): nil
	if not element:IsA('GuiObject') then return end
	
	local animation,prefix = SearchAnimations(tag)
	
	if not animation then return end
	
	local connections = animation(element,tag)
	for event,code in pairs(connections) do
		local guid = HttpService:GenerateGUID(false)
		
		local success,response = pcall(function()
			if event == 'Heartbeat' then
				return RunService[event]:Connect(function(...)
					code(...)
				end)
			else
				return element[event]:Connect(function(...)
					local data = {...}
					
					Manager.debounce(guid,function()
						code(table.unpack(data))
					end)
				end)
			end
		end)
		
		if not success then
			warn("Failed to connect '"..event.."' to class '"..element.ClassName.."' on '"..element:GetFullName().."'")
			warn(response)
			return
		end
		
		GetSignal(element,tag,guid)
		Manager:ConnectKey(guid,response)
	end
end

local function DisconnectAnimations(tag: string, element: GuiObject): nil
	if not element:IsA('GuiObject') then return end
	
	local signals = GetSignal(element,tag)
	
	for index,guid in ipairs(signals) do
		Manager:DisconnectKey(guid)
	end
end

-----------------------
-- Button Animations --
-----------------------

Animator.ButtonAnimations['BounceUp'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	
	return {
		[Events.OnClick] = function()
			local increment = -GetIntensity(tag)
			local goal = UDim2.new(original.Position.X.Scale, original.Position.X.Offset, original.Position.Y.Scale, original.Position.Y.Offset + increment)
			
			Manager.Tween(element,{'Position'},{goal},Length).Completed:Wait()
			Manager.Tween(element,{'Position'},{original.Position},Length).Completed:Wait()
		end;
		
		[Events.OnPress] = function()
			local increment = -GetIntensity(tag)
			local goal = UDim2.new(original.Position.X.Scale, original.Position.X.Offset, original.Position.Y.Scale, original.Position.Y.Offset + increment)
			
			Manager.Tween(element,{'Position'},{goal},Length).Completed:Wait()
			Manager.Tween(element,{'Position'},{original.Position},Length).Completed:Wait()
		end;
		
		[Events.OnLeave] = function()
			Manager.Tween(element,{'Position'},{original.Position},Length).Completed:Wait()
		end;
	}
end

Animator.ButtonAnimations['BounceDown'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	
	return {
		[Events.OnClick] = function()
			local increment = GetIntensity(tag)
			local goal = UDim2.new(original.Position.X.Scale, original.Position.X.Offset, original.Position.Y.Scale, original.Position.Y.Offset + increment)
			
			Manager.Tween(element,{'Position'},{goal},Length).Completed:Wait()
			Manager.Tween(element,{'Position'},{original.Position},Length).Completed:Wait()
		end;
		
		[Events.OnPress] = function()
			local increment = GetIntensity(tag)
			local goal = UDim2.new(original.Position.X.Scale, original.Position.X.Offset, original.Position.Y.Scale, original.Position.Y.Offset + increment)
			
			Manager.Tween(element,{'Position'},{goal},Length).Completed:Wait()
		end;
		
		[Events.OnLeave] = function()
			Manager.Tween(element,{'Position'},{original.Position},Length).Completed:Wait()
		end;
	}
end

Animator.ButtonAnimations['Shrink'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	
	return {
		[Events.OnClick] = function()
			local increment = -GetIntensity(tag)
			local goal = UDim2.new(original.Size.X.Scale, original.Size.X.Offset + increment, original.Size.Y.Scale, original.Size.Y.Offset + increment)
			
			Manager.Tween(element,{'Size'},{goal},Length).Completed:Wait()
			Manager.Tween(element,{'Size'},{original.Size},Length).Completed:Wait()
		end;
		
		[Events.OnPress] = function()
			local increment = -GetIntensity(tag)
			local goal = UDim2.new(original.Size.X.Scale, original.Size.X.Offset + increment, original.Size.Y.Scale, original.Size.Y.Offset + increment)
			
			Manager.Tween(element,{'Size'},{goal},Length).Completed:Wait()
		end;
		
		[Events.OnLeave] = function()
			Manager.Tween(element,{'Size'},{original.Size},Length).Completed:Wait()
		end;
	}
end

Animator.ButtonAnimations['Grow'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	
	return {
		[Events.OnClick] = function()
			local increment = GetIntensity(tag)
			local goal = UDim2.new(original.Size.X.Scale, original.Size.X.Offset + increment, original.Size.Y.Scale, original.Size.Y.Offset + increment)
			
			Manager.Tween(element,{'Size'},{goal},Length).Completed:Wait()
			Manager.Tween(element,{'Size'},{original.Size},Length).Completed:Wait()
		end;
		
		[Events.OnPress] = function()
			local increment = GetIntensity(tag)
			local goal = UDim2.new(original.Size.X.Scale, original.Size.X.Offset + increment, original.Size.Y.Scale, original.Size.Y.Offset + increment)
			
			Manager.Tween(element,{'Size'},{goal},Length).Completed:Wait()
		end;
		
		[Events.OnLeave] = function()
			Manager.Tween(element,{'Size'},{original.Size},Length).Completed:Wait()
		end;
	}
end

----------------------
-- Hover Animations --
----------------------

Animator.HoverAnimations['Grow'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	
	return {
		[Events.OnEnter] = function()
			local increment = GetIntensity(tag)
			local goal = UDim2.new(original.Size.X.Scale, original.Size.X.Offset + increment, original.Size.Y.Scale, original.Size.Y.Offset + increment)
			
			Manager.Tween(element,{'Size'},{goal},Length).Completed:Wait()
		end;
		
		[Events.OnLeave] = function()
			Manager.Tween(element,{'Size'},{original.Size},Length).Completed:Wait()
		end;
	}
end

Animator.HoverAnimations['Shrink'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	
	return {
		[Events.OnEnter] = function()
			local increment = -GetIntensity(tag)
			local goal = UDim2.new(original.Size.X.Scale, original.Size.X.Offset + increment, original.Size.Y.Scale, original.Size.Y.Offset + increment)
			
			Manager.Tween(element,{'Size'},{goal},Length).Completed:Wait()
		end;
		
		[Events.OnLeave] = function()
			Manager.Tween(element,{'Size'},{original.Size},Length).Completed:Wait()
		end;
	}
end

Animator.HoverAnimations['Saturate'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	
	return {
		[Events.OnEnter] = function()
			local increment = GetIntensity(tag)
			local prop = isImage and 'ImageColor3' or 'BackgroundColor3'
			local goal = Color3.new(original[prop].R + increment, original[prop].G + increment, original[prop].B + increment)
			
			Manager.Tween(element,{prop},{goal},Length).Completed:Wait()
		end;
		
		[Events.OnLeave] = function()
			local prop = isImage and 'ImageColor3' or 'BackgroundColor3'
			
			Manager.Tween(element,{prop},{original[prop]},Length).Completed:Wait()
		end;
	}
end

Animator.HoverAnimations['Desaturate'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	
	return {
		[Events.OnEnter] = function()
			local increment = -GetIntensity(tag)
			local prop = isImage and 'ImageColor3' or 'BackgroundColor3'
			local goal = Color3.new(original[prop].R + increment, original[prop].G + increment, original[prop].B + increment)
			
			Manager.Tween(element,{prop},{goal},Length).Completed:Wait()
		end;
		
		[Events.OnLeave] = function()
			local prop = isImage and 'ImageColor3' or 'BackgroundColor3'
			
			Manager.Tween(element,{prop},{original[prop]},Length).Completed:Wait()
		end;
	}
end

---------------------
-- Idle Animations --
---------------------

Animator.IdleAnimations['GradientSpin'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	local gradient = element:FindFirstChildWhichIsA('UIGradient')
	local rate = 1/30
	local logged = 0
	local increment = GetIntensity(tag)
	
	assert(gradient,"No UIGradient object found, create one under your element '"..element:GetFullName().."'")
	return {
		[Events.OnEvent] = function(delta)
			logged += delta
			
			while logged >= rate do
				logged -= rate
				gradient.Rotation += increment
			end
		end;
	}
end

------------------------------------
-- Template & Unstable Animations --
------------------------------------

Animator.UnstableAnimations['ex'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	
	return {
		
	}
end

Animator.UnstableAnimations['Reset'] = function(element: GuiObject, tag: string): table
	local original,isImage = GetOriginal(element)
	
	return {
		[Events.OnCallback] = function()
			local original = Animator._Original[element]
			
			local prop,value = {},{}
			for index,base in pairs(original) do
				table.insert(prop,index)
				table.insert(value,base)
			end
			
			local tween = Manager.Tween(element,prop,value,Length)
			tween.Completed:Wait()
		end;
	}
end

---------------
-- Functions --
---------------

function Animator.new(tag: string): typeof(Animator.new())
	local self = {}
	self.__index = self
	
	local connections
	for index,prefix in pairs(Animator.Prefixes) do
		local library = Animator[index]
		
		for name,animation in pairs(library) do
			if prefix..name ~= tag then continue end
			
			connections = animation
			break
		end
		
		if connections then
			break
		end
	end
	
	return setmetatable({
		_tag = tag;
		_animation = connections;
	},self)
end

function Animator:Play(list: GuiObject | table): typeof(Animator.new())
	list = typeof(list) == 'table' and list or {list}
	
	for index,element in ipairs(list) do
		ConnectAnimations(self._tag,element)
	end
	
	return self
end

function Animator:Stop(list: GuiObject | table): typeof(Animator.new())
	list = typeof(list) == 'table' and list or {list}
	
	for index,element in ipairs(list) do
		DisconnectAnimations(self._tag,element)
	end
	
	return self
end

----------------
-- Initialize --
----------------

local function SubscribeTag(tag: string): nil
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(element: GuiObject)
		ConnectAnimations(tag,element)
	end)
	
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(element: GuiObject)
		DisconnectAnimations(tag,element)
	end)
	
	local Tagged = CollectionService:GetTagged(tag)
	for index,element in ipairs(Tagged) do
		ConnectAnimations(tag,element)
	end
end

for lib,prefix in pairs(Animator.Prefixes) do
	local library = Animator[lib] or {}
	
	for tag,content in pairs(library) do
		SubscribeTag(prefix..tag)
	end
end

return Animator