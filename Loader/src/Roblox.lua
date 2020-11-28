--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: A wrapper for Roblox methods that tend to need try calls
]=]

--[=[
[DOCUMENTATION]:
	:PromptFriendRequest(toPlayer)
	:PromptUnfriendRequest(toPlayer)
	:PromptBlockRequest(toPlayer)
	:PromptUnblockRequest(toPlayer)
	:PromptGameInvite(player)
	:GetFriends(player)
	:GetBlocked()
	:GetRankInGroup(player,group)
	:GetFriendsOnline(player,num)
	:GetUserHeadshot(userId,enumSize)
	:GetUserBust(userId,enumSize)
	:GetUserAvatar(userId,enumSize)
	:GetTeleportInfo(userId)
	:IsFriendsWith(player,userId)
	:IsBlockedWith(player,userId)
	:IsGameCreator(player)
	:CanSendGameInviteAsync(player)
	:FilterText(text,userId,context)
	:FilterChatForUser(filter,toUserId)
	:FilterStringForUser(filter,toUserId)
	:FilterStringForBroadcast(filter)
	:SetCoreGuiEnabled(enum,state)
	:SetCoreEnabled(enum,state)
	:PostNotification(properties)
	:PreloadAssets(assets,code)
	
[OUTLINE]:
	Roblox
	├─ :PromptFriendRequest(toPlayer)
	├─ :PromptUnfriendRequest(toPlayer)
	├─ :PromptBlockRequest(toPlayer)
	├─ :PromptUnblockRequest(toPlayer)
	├─ :PromptGameInvite(player)
	├─ :GetFriends(player)
	├─ :GetBlocked()
	├─ :GetRankInGroup(player,group)
	├─ :GetFriendsOnline(player,num)
	├─ :GetUserHeadshot(userId,enumSize)
	├─ :GetUserBust(userId,enumSize)
	├─ :GetUserAvatar(userId,enumSize)
	├─ :GetTeleportInfo(userId)
	├─ :IsFriendsWith(player,userId)
	├─ :IsBlockedWith(player,userId)
	├─ :IsGameCreator(player)
	├─ :CanSendGameInviteAsync(player)
	├─ :FilterText(text,userId,context)
	├─ :FilterChatForUser(filter,toUserId)
	├─ :FilterStringForUser(filter,toUserId)
	├─ :FilterStringForBroadcast(filter)
	├─ :SetCoreGuiEnabled(enum,state)
	├─ :SetCoreEnabled(enum,state)
	├─ :PostNotification(properties)
	└─ :PreloadAssets(assets,code)
	
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

local Roblox = {}
Roblox._ThumbnailCache = {}
Roblox._SetCoreTypes = {
	['PromptFriendRequest'] = 'PromptSendFriendRequest';
	['PromptUnfriendRequest'] = 'PromptUnfriend';
	['PromptBlockRequest'] = 'PromptBlockPlayer';
	['PromptUnblockRequest'] = 'PromptUnblockPlayer';
	['PromptGameInvite'] = 'PromptGameInvite';
	['GetBlocked'] = 'GetBlockedUserIds';
	['PostNotification'] = 'SendNotification';
}

local Loader = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))

local Manager = Loader('Manager')

local Players = Loader['Players']
local StarterGui = Loader['StarterGui']
local TextService = Loader['TextService']
local SocialService = Loader['SocialService']
local TeleportService = Loader['TeleportService']
local ContentProvider = Loader['ContentProvider']

--[=[
	Prompt a friend request to another Player
	
	@param toPlayer Instance -- toPlayer should be a Player Instance
	@return response | boolean
]=]
function Roblox:PromptFriendRequest(toPlayer)
	assert(Manager.IsClient)
	assert(toPlayer ~= nil and toPlayer:IsA('Player'))
	
	local success,response = Manager.rerun(5,function()
		return StarterGui:SetCore(Roblox._SetCoreTypes.PromptFriendRequest,toPlayer)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Prompt an unfriend request to another Player
	
	@param toPlayer Instance -- toPlayer should be a Player Instance
	@return response | boolean
]=]
function Roblox:PromptUnfriendRequest(toPlayer)
	assert(Manager.IsClient)
	assert(toPlayer ~= nil and toPlayer:IsA('Player'))
	
	local success,response = Manager.rerun(5,function()
		return StarterGui:SetCore(Roblox._SetCoreTypes.PromptUnfriendRequest,toPlayer)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Prompt a block request to another Player
	
	@param toPlayer Instance -- toPlayer should be a Player Instance
	@return response | boolean
]=]
function Roblox:PromptBlockRequest(toPlayer)
	assert(Manager.IsClient)
	assert(toPlayer ~= nil and toPlayer:IsA('Player'))
	
	local success,response = Manager.rerun(5,function()
		return StarterGui:SetCore(Roblox._SetCoreTypes.PromptBlockRequest,toPlayer)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Prompt an unblock request to another Player
	
	@param toPlayer Instance -- toPlayer should be a Player Instance
	@return response | boolean
]=]
function Roblox:PromptUnblockRequest(toPlayer)
	assert(Manager.IsClient)
	assert(toPlayer ~= nil and toPlayer:IsA('Player'))
	
	local success,response = Manager.rerun(5,function()
		return StarterGui:SetCore(Roblox._SetCoreTypes.PromptUnblockRequest,toPlayer)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Prompt a SocialService game invites prompt
	
	@param player Instance -- player should be the Player to prompt
	@return response | boolean
]=]
function Roblox:PromptGameInvite(player)
	assert(player:IsA('Player'))
	
	if not Roblox:CanSendGameInviteAsync(player) then return end
	
	local success,response = Manager.rerun(5,function()
		SocialService:PromptGameInvite(player)
		return true
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Get a players friend list
	
	@param player Instance -- player should be a Player Instance
	@return response | boolean
]=]
function Roblox:GetFriends(player)
	assert(player:IsA('Player'))
	
	local success,response = Manager.rerun(5,function()
		local proxy = {}
		local pages = Players:GetFriendsAsync(player.UserId)
		
		while true do
			local current = pages:GetCurrentPage()
			for index,data in pairs(current) do
				table.insert(proxy,data.UserId)
			end
			
			if pages.IsFinished then
				break
			end
			
			pages:AdvanceToNextPageAsync()
		end
		
		return proxy
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Get the local players Blocked list
	
	@return response | boolean
]=]
function Roblox:GetBlocked()
	assert(Manager.IsClient)
	
	if Manager.IsStudio then return {} end
	
	local success,response = Manager.rerun(5,function()
		return StarterGui:GetCore(Roblox._SetCoreTypes.GetBlocked)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Get the rank of a player in a group
	
	@param player Instance -- player should be a Player Instance
	@param group number -- the group Id
	@return response | boolean
]=]
function Roblox:GetRankInGroup(player,group)
	assert(player:IsA('Player'))
	assert(typeof(group) == 'number')
	
	local success,response = Manager.rerun(5,function()
		return player:GetRankInGroup(group)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Get the given number of friends online from a player
	
	@param player Instance -- player should be a Player Instance
	@param num? number -- an optional number of online friends to return (default 200)
	@return response | boolean
]=]
function Roblox:GetFriendsOnline(player,num)
	assert(player:IsA('Player'))
	num = num or 200
	
	local success,response = Manager.rerun(5,function()
		return player:GetFriendsOnline(num)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Get a users headshot image asset url
	
	@param userId number -- the required player userId
	@param enumSize? EnumItem -- optional size argument, default 420x420px (max)
	@return response | boolean
]=]
function Roblox:GetUserHeadshot(userId,enumSize)
	assert(typeof(userId) == 'number')
	enumSize = enumSize == typeof('EnumItem') and enumSize or Enum.ThumbnailSize.Size420x420
	
	local name = 'Headshot_'..userId..'_'..enumSize
	local image = Roblox._ThumbnailCache[name]
	
	if image then
		return image
	end
	
	local success,response = Manager.rerun(5,function()
		image = Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,enumSize)
		return image
	end)
	
	if success then
		Roblox._ThumbnailCache[name] = image
		return image
	end
	
	warn(response)
	return success
end

--[=[
	Get a users bust image asset url
	
	@param userId number -- the required player userId
	@param enumSize? EnumItem -- optional size argument, default 420x420px (max)
	@return response | boolean
]=]
function Roblox:GetUserBust(userId,enumSize)
	assert(typeof(userId) == 'number')
	enumSize = enumSize == typeof('EnumItem') and enumSize or Enum.ThumbnailSize.Size420x420
	
	local name = 'Bust_'..userId..'_'..enumSize
	local image = Roblox._ThumbnailCache[name]
	
	if image then
		return image
	end
	
	local success,response = Manager.rerun(5,function()
		image = Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.AvatarBust,enumSize)
		return image
	end)
	
	if success then
		Roblox._ThumbnailCache[name] = image
		return image
	end
	
	warn(response)
	return success
end

--[=[
	Get a users avatar image asset url
	
	@param userId number -- the required player userId
	@param enumSize? EnumItem -- optional size argument, default 420x420px (max)
	@return response | boolean
]=]
function Roblox:GetUserAvatar(userId,enumSize)
	assert(typeof(userId) == 'number')
	enumSize = enumSize == typeof('EnumItem') and enumSize or Enum.ThumbnailSize.Size420x420
	
	local name = 'Avatar_'..userId..'_'..enumSize
	local image = Roblox._ThumbnailCache[name]
	
	if image then
		return image
	end
	
	local success,response = Manager.rerun(5,function()
		image = Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.AvatarThumbnail,enumSize)
		return image
	end)
	
	if success then
		Roblox._ThumbnailCache[name] = image
		return image
	end
	
	warn(response)
	return success
end

--[=[
	Get the users teleport info, compare the placeId to the game.PlaceId to verify the same game
	
	@param userId number -- the userId of the player to check info on
	@return inServer bool, placeId number, serverId JobId | boolean
]=]
function Roblox:GetUserTeleportInfo(userId)
	assert(Manager.IsServer)
	assert(typeof(userId) == 'number')
	
	local success, current, err, placeId, jobId = pcall(function()
		return TeleportService:GetPlayerPlaceInstanceAsync(userId)
	end)
	
	if success then
		return current, placeId, jobId
	end
	warn(err)
	return success
end

--[=[
	Check if a player is friends with another Players UserId
	
	@param player Instance -- the player Instance to check with
	@param userId number -- the user Id to compare against
	@return response | boolean
]=]
function Roblox:IsFriendsWith(player,userId)
	assert(Manager.IsClient)
	assert(player:IsA('Player'))
	assert(typeof(userId) == 'number')
	
	local success,response = Manager.rerun(5,function()
		return player:IsFriendsWith(userId)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Check if a player is blocking another Player by UserId
	
	@param player Instance -- the player Instance to check with
	@param userId number -- the user Id to compare against
	@return response | boolean
]=]
function Roblox:IsBlockedWith(player,userId)
	assert(Manager.IsClient)
	assert(player:IsA('Player'))
	assert(typeof(userId) == 'number')
	
	local success,response = Manager.rerun(5,function()
		if typeof(player) == 'table' then
			if player:IsBlockedWith(userId) then
				return true
			end
		else
			local blocks = Roblox:GetBlocked()
			if table.find(blocks,userId) then
				return true
			end
		end
		return false
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Check if a player is the game creator (dev)
	
	@param player Instance -- the player Instance to check
	@return response | boolean
]=]
function Roblox:IsGameCreator(player)
	assert(player:IsA('Player'))
	
	local success,response = Manager.rerun(5,function()
		if game.CreatorType == Enum.CreatorType.User then
			if Manager.IsClient and Manager.IsStudio then
				if player.UserId == Players.LocalPlayer.UserId then
					return true
				end
			elseif player.UserId == game.CreatorId then
				return true
			end
		elseif game.CreatorType == Enum.CreatorType.Group then
			if Roblox:GetRankInGroup(player,game.CreatorId) >= 255 then
				return true
	        end
		end
		return false
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Check if a player can send game invites with SocialService
	
	@param player Instance -- the player Instance to check
	@return response | boolean
]=]
function Roblox:CanSendGameInviteAsync(player)
	assert(Manager.IsClient)
	assert(player:IsA('Player'))
	
	local success,response = Manager.rerun(5,function()
		return SocialService:CanSendGameInviteAsync(player)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Filter text with the userId sent by and the opt context
	
	@param text string -- text to filter
	@param userId number -- the userId sent by
	@param context? EnumItem -- the context of the filtering
	@return FilterObject | boolean
]=]
function Roblox:FilterText(text,userId,context)
	assert(Manager.IsServer)
	assert(typeof(text) == 'string')
	assert(typeof(userId) == 'number')
	context = context or Enum.TextFilterContext.PublicChat
	
	local success,response = Manager.rerun(5,function()
		return TextService:FilterStringAsync(text,userId,context)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Using a filter, get the text for a specific user
	
	@param filter FilterObject -- the FilterObject created
	@param userId number -- the userId to filter for
	@return response | boolean
]=]
function Roblox:FilterChatForUser(filter,toUserId)
	assert(Manager.IsServer)
	assert(typeof(filter) == 'Instance')
	assert(typeof(toUserId) == 'number')
	
	local success,response = Manager.rerun(5,function()
		return filter:GetChatForUserAsync(toUserId)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Using a filter, get the text for a specific user
	
	@param filter FilterObject -- the FilterObject created
	@param userId number -- the userId to filter for
	@return response | boolean
]=]
function Roblox:FilterStringForUser(filter,toUserId)
	assert(Manager.IsServer)
	assert(typeof(filter) == 'Instance')
	assert(typeof(toUserId) == 'number')
	
	local success,response = Manager.rerun(5,function()
		return filter:GetNonChatStringForUserAsync(toUserId)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Using a filter, get the text for a broadcast
	
	@param filter FilterObject -- the FilterObject created
	@return response | boolean
]=]
function Roblox:FilterStringForBroadcast(filter)
	assert(Manager.IsServer)
	assert(typeof(filter) == 'Instance')
	
	local success,response = Manager.rerun(5,function()
		return filter:GetNonChatStringForBroadcastAsync()
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Set a CoreGui package enabled/disabled with this safety call
	
	@param enum EnumItem -- the enum to set state
	@param state boolean -- the state to set
	@return response | boolean
]=]
function Roblox:SetCoreGuiEnabled(enum,state)
	assert(typeof(enum) == 'EnumItem')
	state = typeof(state) == 'boolean' and state or false
	
	local success,response = Manager.rerun(5,function()
		return StarterGui:SetCoreGuiEnabled(enum,state)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Set a Core packages enabled/disabled with this safety call
	
	@param enum string -- the enum to set state
	@param state boolean -- the state to set
	@return response | boolean
]=]
function Roblox:SetCoreEnabled(enum,state)
	assert(enum ~= nil)
	state = typeof(state) == 'boolean' and state or false
	
	local success,response = Manager.rerun(5,function()
		return StarterGui:SetCore('ResetButtonCallback',state)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Post notifications to the bottom right
	
	@param properties table -- a dictionary of the notification properties. see devhub 'SendNotification'
	@return response | boolean
]=]
function Roblox:PostNotification(properties)
	local code = typeof(properties.Callback) == 'function'; do
		if code then
			code = Instance.new('BindableFunction')
			code.OnInvoke = properties.Callback	
		end
	end
	
	local params = {
		Title = properties.Title or '';
		Text = properties.Text or '';
		Duration = properties.Duration or 5;
		Icon = properties.Icon;
		Button1 = properties.Button1;
		Button2 = properties.Button2;
		Callback = code;
	}
	
	local success,response = Manager.rerun(5,function()
		return StarterGui:SetCore(Roblox._SetCoreTypes.PostNotification,params)
	end)
	
	if success then return response end
	warn(response)
	return success
end

--[=[
	Preload a table or individual asset with optional callback function
	
	@param assets Instance | table -- either provide a singular Instance or a table of Instances
	@param code? function -- a callback function made on completion
	@return boolean
]=]
function Roblox:PreloadAssets(assets,code)
	assert(Manager.IsClient)
	assets = typeof(assets) == 'table' and assets or {assets}
	
	ContentProvider:PreloadAsync(assets,code)
	return true
end

return Roblox