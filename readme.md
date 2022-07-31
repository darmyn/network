Server

```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require(replicatedStorage.network)

local buildingNetwork = network.new("buildingNetwork", {
	buildPart = network.event.new()
})

buildingNetwork.topics.buildPart:connect(function(player: Player)
	local character = player.Character
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	local newPart = Instance.new("Part")
	newPart.CFrame = CFrame.new(humanoidRootPart.CFrame.LookVector * 10 + humanoidRootPart.Position, humanoidRootPart.Position)
	newPart.Parent = workspace
end)
```

Client
```lua
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require(replicatedStorage.network)

local buildingNetwork = network.new("buildingNetwork")

userInputService.InputBegan:Connect(function(input, gpe)
	if not gpe then
		if input.KeyCode == Enum.KeyCode.E then
			print("e")
			buildingNetwork.topics.buildPart:fire()
		end
	end
end)
```
