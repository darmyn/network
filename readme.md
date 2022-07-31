As someone who writes thier Roblox code in Visual Studio, I found networking to be very annoying.
I would prefer to manage networking VIA code, so that was the initial reason for creating this.

In the backend, networks are all ran through the same remotes. Initializing a new network essentially just creates a new group of topics

Server

```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local network = require(replicatedStorage.network)

local myNetwork = network.new("test", {
	sayHello = network.event.new(),
	serverAddition = network.response.new()
}) 

-- PRO TIP: You can pass a third argument to `network.new`. It expects a list of players which represents who has access to the network.

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
