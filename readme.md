As someone who writes thier Roblox code in Visual Studio, I found networking to be very annoying.
I would prefer to manage networking in code, so that was the initial reason for creating this.

In the backend, networks are all ran through the same remotes. Initializing a new network essentially just creates a new group of topics.
Networks have Ids and each topic has a name. These are used to delegate requests accordinly.

Also, this module also supports the ability to link to a client using an Instance. In theory you could have an Instance, say for example the players weapon. The weapon could spawn it's own network where two classes (one on client, one on server) would communicate with eachother to manage said
weapon. This network can easily be locked by passing an array containing the specified player(s) to the third argument of network.new

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
