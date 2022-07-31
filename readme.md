Server

```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require(replicatedStorage.network)

local myNetwork = network.new("test", {
	sayHello = network.event.new(),
	serverAddition = network.response.new()
})

local topics = myNetwork.topics

topics.sayHello:connect(function(player: Player)
	print("Hello: ".. player.Name)
end)

topics.serverAddition:connect(function(player: Player, num1: number, num2: number)
	return num1 + num2
end)
```

Client
```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require(replicatedStorage.network)

local myNetwork = network.new("test")
local topics = myNetwork.topics

topics.sayHello:fire()
print(topics.serverAddition:fire(5, 10))
```
