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

[TAGS]:
	MouseButton1Click:
		UI_BounceUp
		UI_BounceDown
		
	MouseButton1Down:
		
	MouseButton1Up:
		
	MouseEnter:
		UI_Grow
		
	MouseLeave:
		UI_Reset
]=]

local Animator = {}
Animator.Cache = {}
Animator.Original = {}
Animator.Prefix = 'UI_'
Animator.TagList = {
	['MouseButton1Click'] = {'BounceUp','BounceDown'};
	['MouseButton1Down'] = {};
	['MouseButton1Up'] = {};
	['MouseEnter'] = {'Grow',''};
	['MouseLeave'] = {'Reset'};
}

local Loader = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))
local Manager = Loader('Manager')
local HttpService = Loader['HttpService']
local CollectionService = Loader['CollectionService']

local AttributeFlag = pcall(function() -- TODO: remove this when Attributes are released
	script:GetAttribute('Test')
end)

local Length = AttributeFlag and script:GetAttribute('AnimationTime') or 0.1
local Scale = AttributeFlag and script:GetAttribute('AnimationScale') or 0.1

--------------------
-- Common Effects --
--------------------
Animator['FadeOut'] = function(element: GuiObject): nil
	
end

Animator['FadeAll'] = function(element: GuiObject): nil
	
end

-----------------------
-- MouseButton1Click --
-----------------------
Animator['BounceUp'] = function(element: GuiObject): nil
	local original = Animator.Original[element]
	
	local increment = 1 - Scale
	local goal; do
		if original.Position.X.Scale > 0 and original.Position.X.Offset == 0 then
			goal = UDim2.fromScale(original.Position.X.Scale,original.Position.Y.Scale * increment)
		elseif original.Position.X.Offset > 0 and original.Position.X.Scale == 0 then
			goal = UDim2.fromOffset(original.Position.X.Offset,original.Position.Y.Offset * increment)
		end
	end
	
	local tween = Manager.Tween(element,{'Position'},{goal},Length)
	tween.Completed:Wait()
	local tween = Manager.Tween(element,{'Position'},{original.Position},Length)
	tween.Completed:Wait()
end

Animator['BounceDown'] = function(element: GuiObject): nil
	local original = Animator.Original[element]
	
	local increment = Scale + 1
	local goal; do
		if original.Position.X.Scale > 0 and original.Position.X.Offset == 0 then
			goal = UDim2.fromScale(original.Position.X.Scale,original.Position.Y.Scale * increment)
		elseif original.Position.X.Offset > 0 and original.Position.X.Scale == 0 then
			goal = UDim2.fromOffset(original.Position.X.Offset,original.Position.Y.Offset * increment)
		end
	end
	
	local tween = Manager.Tween(element,{'Position'},{goal},Length)
	tween.Completed:Wait()
	local tween = Manager.Tween(element,{'Position'},{original.Position},Length)
	tween.Completed:Wait()
end

----------------
-- MouseEnter --
----------------
Animator['Grow'] = function(element: GuiObject): nil
	local original = Animator.Original[element]
	
	local increment = Scale + 1
	local goal; do
		if original.Size.X.Scale > 0 and original.Size.X.Offset == 0 then
			goal = UDim2.fromScale(original.Size.X.Scale * increment,original.Size.Y.Scale * increment)
		elseif original.Size.X.Offset > 0 and original.Size.X.Scale == 0 then
			goal = UDim2.fromOffset(original.Size.X.Offset * increment,original.Size.Y.Offset * increment)
		end
	end
	
	local tween = Manager.Tween(element,{'Size'},{goal},Length)
	tween.Completed:Wait()
end

----------------
-- MouseLeave --
----------------
Animator['Reset'] = function(element: GuiObject): nil
	local original = Animator.Original[element]
	
	local prop,value = {},{}
	for index,base in pairs(original) do
		table.insert(prop,index)
		table.insert(value,base)
	end
	
	local tween = Manager.Tween(element,prop,value,Length)
	tween.Completed:Wait()
end

-----------------
-- Connections --
-----------------
local function ConnectAnimation(element: GuiObject, event: string, tag: string): nil
	local identifier = event..'_'..tag..'_'..tostring(element)
	if Animator.Cache[element] and Animator.Cache[element][identifier] then return end
	
	local IsImage = element:IsA('ImageButton') or element:IsA('ImageLabel')
	
	if not Animator.Original[element] then
		Animator.Original[element] = {
			AnchorPoint = element.AnchorPoint;
			Position = element.Position;
			Size = element.Size;
			
			BackgroundColor3 = element.BackgroundColor3;
			BackgroundTransparency = element.BackgroundTransparency;
			BorderColor3 = element.BorderColor3;
			
			ImageColor3 = IsImage and element.ImageColor3 or nil;
			ImageTransparency = IsImage and element.ImageTransparency or nil;
		}
	end
	
	local guid = HttpService:GenerateGUID(false)
	local code = Animator[string.sub(tag,#Animator.Prefix + 1)]
	local signal = element[event]:Connect(function(...)
		local data = {...}
		
		Manager.debounce(guid,function()
			code(element,table.unpack(data))
		end)
	end)
	
	if not Animator.Cache[element] then
		Animator.Cache[element] = {}
	end
	
	Animator.Cache[element][identifier] = signal
end

local function ConnectTag(event: string, tag: string): nil
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(element: GuiObject)
		ConnectAnimation(element,event,tag)
	end)
	
	local Tagged = CollectionService:GetTagged(tag)
	for index,element in pairs(Tagged) do
		ConnectAnimation(element,event,tag)
	end
end

for event,list in pairs(Animator.TagList) do
	for count,tag in pairs(list) do
		tag = Animator.Prefix..tag
		ConnectTag(event,tag)
	end
end

return Animator