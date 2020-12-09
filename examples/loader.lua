-- initialize Loader
local Loader = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))



-- Built in options, similar to Rusts' "Option" enum, though this compares types
-- Option is created on the global 'shared' by Loader
-- Lua should implement its own Option, would make this so much easier.
shared.Option:Set('result1','string') -- type: string
shared.Option:Set('result2',23876) -- type: number
shared.Option:Set('result3','string') -- type: string

print(shared.Option.result1:Match(shared.Option.result2)) --> false
print(shared.Option.result1:Match(shared.Option.result3)) --> true