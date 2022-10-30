Server
```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(replicatedStorage.network)

local topics = {
	myEvent = Network.event()
	myResponse = Network.response()
}

local myNetwork = network.new("test", topics) 

-- PRO TIP: You can pass a third argument to `network.new`. It expects a list of players which represents who has access to the network.

topics.myEvent:connect(function(player: Player)
	print("Hello: ".. player.Name)
end)

topics.myResponse:connect(function(player: Player, num1: number, num2: number)
	return num1 + num2
end)
```

Client
```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require(replicatedStorage.network)

local myNetwork = network.new("test")
local topics = myNetwork.topics

topics.myEvent:fire()
print(topics.myResponse:fire())
```
