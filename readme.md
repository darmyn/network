Server
```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(replicatedStorage.network)

local topics = {
	myEvent = Network.event(),
	myResponse = Network.response()
}

-- PRO TIP: You can pass a third argument to `network.new`. It expects a list of players which represents who has access to the network.

topics.myEvent:connect(function(player: Player)
	print("Hello: ".. player.Name)
end)

topics.myResponse:connect(function(player: Player, num1: number, num2: number)
	return num1 + num2
end)

Network.new("test", topics)

print(require(replicatedStorage.ServerClient).new())
```

Client
```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(replicatedStorage.network)

local network = Network.new("test")
--> you can optionally define your own types to provide autocomplete on the client side
local topics = network.topics :: {
	myEvent: Network.topic,
	myResponse: Network.topic
}

topics.myEvent:fire()
print(topics.myResponse:fire(5, 7))
```
Server/Client

Often times I find myself coupling client and server code into a single module. Network is supportive of this paradigm.
```lua
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local isServer = runService:IsServer()

local Network = require(replicatedStorage.network)

local myClass = {} :: myClass
myClass.__index = myClass

function myClass.new(owner: Player)
	local self = setmetatable({}, myClass)
	if isServer then
		self.topics = {
			test = Network.event()
		}
		self.network = Network.new(owner.UserId.."_myClass", self.topics, {owner})
	else
		self.network = Network.new(owner.UserId)
		self.topics = self.network.topics
	end
	self:testMethod()
	return self
end

function myClass:testMethod()
	self.topics.test --> still get autocomplete for all of your topics :)
end

type myClass = typeof(myClass.new())

return myClass
```
