--[[
Some useful things to know:
	
	DataSync was written with an object oriented structure, so you
	can chain methods together. You cannot chain the following:
	- store:GetData()
	- subscription:Unsubscribe()
	
	DataSync has 'hidden values' which are prefixed with '__' and any value with this prefix
	will be skipped over and ignored since it assumes it is for internal usage.
	
	These values are as follows, all booleans:
	__CanSave
	__HasChanged
	__IsReady
	
	A fun trick to yield for the file:
	
	while not DataFile:GetData('__IsReady') do
		RunService.Stepped:Wait()
	end
	
	DataSync automatically autosaves all DataFiles, but SaveData will not fire if
	no data was changed since the last load/save
--]]

-- initialize Loader
local Loader = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))
local Cache = {} -- the main DataStore cache table

-- import the modules
local Manager = Loader('Manager')
local DataSync = Loader('DataSync')

-- import the services
local Players = Loader['Players']

-- create a DataStore
local Store = DataSync.GetStore('PlayerData',{ -- first parameter is the key of the store
	['Money'] = 0; -- these values are examples of how you can set up the default dictionary (file)
	['Gems'] = 0;
	['Level'] = 0;
})

-- create a DataStore that the client doesn't sync to unless subscribed
local Test = DataSync.GetStore('HiddenData',{ -- set up the key and default table
	['Karma'] = 1000;
}):GetFile('Stats') -- immediately grab a file, this is useful for global stores

-- player functions
local function PlayerAdded(plr)
	if Cache[plr] then return end -- if theres already a file, dont load another
	
	local file = Store:GetFile(plr.UserId) -- get the file of the player
	Cache[plr] = file -- cache the file so we can use it later
	
	local Subscription; Subscription = Store:Subscribe(plr.UserId,'all',function(new) -- subscribe to all of the players data - this will fire everytime ANY data updates
		--[[
			subscribe returns a dictionary with the Key of the store, the index of the store, the stat of the index, the value of the index, and if player, the player
			subscriptionDictionary = {
				Stat = 'string';
				Value = <any>;
				Key = 'store_key';
				Index = 'store_index';
				Player = player or nil;
			}
		--]]
		print(new.Stat,'::',new.Value) -- print the stat and its corresponding value
		Subscription:Unsubscribe() -- unsubscribe from watching the value - this is called instantly to showcase
	end)
	
	Manager.wrap(function() -- wrap the finite while loop
		while wait(5) and Cache[plr] do -- only work every 5 seconds & if the file exists
			-- player data
			file:IncrementData('Money',500) -- increment the players money
				:IncrementData('Gems',50) -- increment the players gems
				:IncrementData('Level',1) -- increment the players level
			
			-- hidden data
			Test:IncrementData('Karma',-1) -- decrement karma from the hidden store
		end
	end)
end

local function PlayerRemoving(plr)
	if not Cache[plr] then return end -- if not file exists, dont do anything
	
	local file = Cache[plr] -- grab the player file
	file:SaveData() -- save the data
		:RemoveData() -- remove the data since the player left
	Cache[plr] = nil -- uncache the file and free up memory
end

-- connect the player to the game
Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)
for index,plr in pairs(Players:GetPlayers()) do
	PlayerAdded(plr)
end