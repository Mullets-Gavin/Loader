# Unit Testing

## About
These unit tests were created with Boatbomber's testing utility plugin. You can run them yourself by setting up
modules in correspondence to the ones within this folder.

Testing includes:
- Loader
- DataSync

## Default Test

```lua
local Loader = require(game:GetService('ReplicatedStorage'):WaitForChild('Loader'))
local Player = Loader('player')

return {
	['ParameterGenerator'] = function()
		return nil
	end;
	
	['Functions'] = {
		['Sample A'] = function(profiler)
			
		end;
		
		['Sample B'] = function(profiler)
			
		end;
	};
}
```

## PlayerClass
The 'player' module is a PlayerClass utility which simulates players with their according properties & methods.

PlayerClass structure:
```lua
local Player = PlayerClass.generate(1) -- create a randomized player
local Player = PlayerClass.new({ -- create a player with given parameters
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
```