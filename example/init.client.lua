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