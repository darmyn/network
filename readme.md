Server
```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(replicatedStorage.network)

local topics = {
	myEvent = Network.event(),
	myResponse = Network.response()
}

topics.myEvent:connect(function(player: Player)
	print("Hello: ".. player.Name)
end)

topics.myResponse:connect(function(player: Player, num1: number, num2: number)
	return num1 + num2
end)

Network.new("test", topics) --> you can also pass a third arugment representing a list of players
				-- who will have access to the topics inside of this network.

print(require(replicatedStorage.ServerClient).new())
```

Client
```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(replicatedStorage.network)

local network = Network.new("test")
local topics = network.topics :: {
	--> you can optionally define your own types to provide autocomplete on the client side
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
			test = Network.response()
		}
		self.network = Network.new(owner.UserId.."_myClass", self.topics, {owner})
	else
		self.network = Network.new(owner.UserId)
		self.topics = self.network.topics
	end
	self:testMethod()
	return self
end

function myClass:init()
	if isServer then
		self.topics.test:connect(function()
			return true
		end)
	elseif self.topics.test:fire() then
		--[[
			the best part about this module when it comes to
			coupling your client server code is you do not have to explicitely type
			the topics on the client side if you want autocomplete. self.topics will show autocomplete
			based on the infered type from the server side declaration of self.topics even on the client :)
		]]
		print("success")
	end
end

type myClass = typeof(myClass.new())

return myClass
```
