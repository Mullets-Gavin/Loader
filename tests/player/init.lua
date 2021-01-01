--[=[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: A custom PlayerClass object
]=]

--[=[
[DOCUMENTATION]:
	This PlayerClass class simulates a player instance which you can use to utilize for testing
	and simulating players for performance & general tests
	
	PlayerClass.generate(num) -- generate a unique random player
	PlayerClass.new({properties}) -- create a player with properties
	
	local plr = PlayerClass.new({
		['Name'] = 'name';
		['DisplayName'] = 'display name';
		['UserId'] = 1;
		['AccountAge'] = 1;
		['MembershipType'] = Enum.MembershipType.None;
		['Team'] = 'name'
		['TeamColor'] = Color3;
		['Neutral'] = true;
		
		['Groups'] = {
			[5018486] = 255
		};
		['Friends'] = {
			[5520567] = true
		};
		['Blocks'] = {
			[5520567] = true
		};
	})
]=]

local PlayerClass = {}
PlayerClass.__index = PlayerClass

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Loader"))
local UserIds = require(script:WaitForChild("userid"))

local Teams = game:GetService("Teams")
local Players = game:GetService("Players")

local Claimed = {}
local Chances = {
	["Premium"] = 10, -- 10% chance to get premium
	["Group"] = 10, -- 10% chance to be in a group
	["Friend"] = 10, -- 20% chance to be a local player friend
	["Block"] = 5, -- 5% chance to block the local player
	["AccountAge"] = { 1, 3650 }, -- the randomization min/max for account age (10 years max)
}

local Groups = {
	["GroupId"] = { 5018486, 1200769, 2868472, 4199740 },
	["GroupRole"] = {
		[5018486] = 254,
		[1200769] = 1,
		[2868472] = 1,
		[4199740] = 1,
	},
}

local function GetName(id)
	local success, response = pcall(function()
		return Players:GetNameFromUserIdAsync(id)
	end)

	if success then
		return response
	end

	return "Player"
end

local function GetUID()
	local id = UserIds[math.random(1, #UserIds)]

	while table.find(Claimed, id) do
		id = UserIds[math.random(1, #UserIds)]
	end
	table.insert(Claimed, id)

	return id
end

local function GetGroup()
	if math.random() <= Chances.Group / 100 then
		local id = Groups.GroupId[math.random(1, #Groups.GroupId)]
		return {
			["GroupId"] = id,
			["GroupRole"] = Groups.GroupRole[id],
		}
	end

	return {
		["GroupId"] = 0,
		["GroupRole"] = 0,
	}
end

local function GetTeam()
	local get = Teams:GetChildren()
	if #get > 0 then
		local id = get[math.random(1, #get)]
		return {
			["TeamName"] = id.Name,
			["TeamColor"] = id.TeamColor,
			["TeamNeutral"] = false,
		}
	end

	return {
		["TeamName"] = false,
		["TeamColor"] = false,
		["TeamNeutral"] = true,
	}
end

local function GetAge()
	return math.random(Chances.AccountAge[1], Chances.AccountAge[2])
end

local function GetPremium()
	return math.random() <= Chances.Premium / 100 and Enum.MembershipType.Premium or Enum.MembershipType.None
end

local function GetFriendship()
	return math.random() <= Chances.Friend / 100 and true or false
end

local function GetBlocked()
	return math.random() <= Chances.Block / 100 and true or false
end

function PlayerClass.generate(num)
	num = num or 1

	local proxy = {}
	for index = 1, num do
		local id = GetUID()
		local relation = GetUID()
		local name = GetName(id)
		local display = GetName(id)
		local age = GetAge()
		local premium = GetPremium()
		local team = GetTeam()
		local group = GetGroup()
		local friend = GetFriendship()
		local block = GetBlocked()

		local plr = PlayerClass.new({
			["Name"] = name,
			["DisplayName"] = display,
			["UserId"] = id,
			["AccountAge"] = age,
			["MembershipType"] = premium,
			["Team"] = team.TeamName,
			["TeamColor"] = team.TeamColor,
			["Neutral"] = team.TeamNeutral,

			["Groups"] = {
				[group.GroupId] = group.GroupRole,
			},
			["Friends"] = {
				[relation] = friend,
			},
			["Blocks"] = {
				[relation] = block,
			},
		})

		table.insert(proxy, plr)
	end

	if #proxy == 1 then
		return proxy[1]
	end

	return proxy
end

function PlayerClass.new(props)
	return setmetatable(
		{
			["Name"] = props["Name"] or "Roblox",
			["DisplayName"] = props["DisplayName"] or props["Name"],
			["UserId"] = props["UserId"] or 1,
			["AccountAge"] = props["AccountAge"] or 1,
			["MembershipType"] = props["MembershipType"] or Enum.MembershipType.Premium,
			["Team"] = props["Team"] or false,
			["TeamColor"] = props["TeamColor"] or false,
			["Neutral"] = props["Neutral"] or true,

			["Groups"] = props["Groups"] or {},
			["Friends"] = props["Friends"] or {},
			["Blocks"] = props["Blocks"] or {},
		},
		PlayerClass
	)
end

function PlayerClass:IsFriendsWith(userId)
	return self.Friends[userId]
end

function PlayerClass:IsBlockedWith(userId)
	return self.Blocks[userId]
end

function PlayerClass:IsInGroup(groupId)
	return self.Groups[groupId] and true or false
end

function PlayerClass:GetRankInGroup(groupId)
	return self.Groups[groupId] or 0
end

function PlayerClass:IsA(type)
	return type == "Player"
end

return PlayerClass
