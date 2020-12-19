-- initialize Loader
local require = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))

local Cache = {} -- keep track of the modules
local List = {'Manager','Roblox','DataSync','Interface','Network'} -- lets set up a list of modules to require

local function Boot() -- a simple function to load the modules
	for index,module in pairs(List) do -- start up a loop
        Cache[module] = require(module) -- require the module
    end
	
    return Cache
end

local Get = Boot() -- get the modules & boot em
for index,module in pairs(Get) do
    print(module._Name) -- every module has a _Name
end

--[=[
create a new module, run this in the command bar:

local New = Instance.new('ModuleScript')
New.Name = 'WackyModule'
New.Source = 'return {}'
New.Parent = game:GetService('ReplicatedStorage')
]=]

local Name = 'WackyModule'
local Find = game:GetService('ReplicatedStorage'):FindFirstChild(Name)

local RequireByInstance = require(Find) -- require it by instance
local RequireByString = require(Name) -- require that same module

print(RequireByInstance == RequireByString) --> true, because their the same require table