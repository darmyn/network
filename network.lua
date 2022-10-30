local players = game:GetService("Players")
local runService = game:GetService("RunService")

local isServer = runService:IsServer()
local eventProxy = Instance.new("RemoteEvent")
local responseProxy = Instance.new("RemoteFunction")
local getReplicatedNetworkInfo = Instance.new("RemoteFunction")

local topicTypes = {
	event = "event",
	response = "response"
}

local topic = {} :: topicClass
topic.__index = topic

local function executeCallbacks(self: topicClass, ...)
	local finalResult
	for _, callback in ipairs(self.callbacks) do
		finalResult = callback(...)
	end
	return finalResult
end

function topic.new(type: topicType)
	local self = setmetatable({}, topic)
	self.type = type
	self.callbacks = {}
	return self :: topic
end

function topic:connect(callback: callback)
	table.insert(self.callbacks, callback)
	return {
		disconnect = function()
			table.remove(self.callbacks, table.find(self.callbacks, callback))
		end,
	}
end

function topic:fire(...)
	if isServer then
		local args = table.pack(...)
		local player = args[1]
		table.remove(args[1])
		if self.type == topicTypes.event then
			eventProxy:FireClient(player, self.network.id, self.name, table.unpack(args))
		end
	else
		if self.type == topicTypes.event then
			eventProxy:FireServer(self.network.id, self.name, ...)
		elseif self.type == topicTypes.response then
			return responseProxy:InvokeServer(self.network.id, self.name, ...)
		end
	end
end

function topic:fireNearby(location: Vector3, radius: number, ...)
	if isServer then
		for _, player in pairs(players:GetPlayers()) do
			local character = player.Character
			if character then
				local humanoid: Humanoid = character:FindFirstChild("HumanoidRootPart")
				if humanoid and humanoid.Health > 0 then
					local rootPart = humanoid.RootPart
					if (location - rootPart.Position).Magnitude <= radius then
						self:fire(player, ...)
					end
				end
			end
		end 
	end
end

function topic:fireAllExcept(blacklist: memberList, ...)
	if isServer then
		for _, player in pairs(players:GetPlayers()) do
			if not table.find(blacklist, player) then
				self:fire(player, ...)
			end
		end
	end
end

function topic:fireAll(...)
	if isServer then
		for _, player in pairs(players:GetPlayers()) do
			self:fire(player, ...)
		end
	end
end

local function compressTopics(topics: topics)
	local result = {}
	for topicName, t in pairs(topics) do
		result[topicName] = {type = t.type}
	end
	return result
end

local function decompressTopics(topics: compressedTopics)
	local result = {}
	for topicName, t in pairs(topics) do
		result[topicName] = topic.new(t.type)
	end
	return result
end

local function convertMembersToHashMap(members: memberList)
	local result = {}
	for _, member in pairs(members) do
		result[member] = true
	end
	return result
end

local activeNetworks = {} :: {[networkId]: network}
local network = {} :: network
network.__index = network

local function initializeTopics(self: network)
	for topicName, t in pairs(self.topics) do
		t.network = self
		t.name = topicName
	end
end

function network.new(id: networkId, topics: topics?, members: memberList?)
	local self = setmetatable({}, network)
	self.id = id
	if isServer then
		self.topics = (topics)
		if members then
			self.members = convertMembersToHashMap(members)
		end
	else
		local replicatedTopics: compressedTopics, replicatedMembers = getReplicatedNetworkInfo:InvokeServer(id)
		self.topics = decompressTopics(replicatedTopics)
		self.members = replicatedMembers
	end
	initializeTopics(self)
	activeNetworks[id] = self
	return self
end

local function clientSignalHandler(networkId: networkId, topicName: topicName, ...)
	return executeCallbacks(activeNetworks[networkId].topics[topicName], ...)
end

--> the server handler thouroughly checks the data passed through by the client since it can easily be modified by
--> malicious users to slow down the server. Error messages only show when debug is enabled!
local function serverSignalHandler(player: Player, networkId: networkId, topicName: topicName, ...)
	local result
	if networkId and typeof(networkId) == "string" then
		if topicName and typeof(topicName) == "string" then
			local selectedNetwork = activeNetworks[networkId]
			if selectedNetwork then
				if selectedNetwork.members then
					if not selectedNetwork.members[player] then
						return
					end
				end
				local selectedTopic = selectedNetwork.topics[topicName]
				if selectedTopic then
					result = executeCallbacks(selectedTopic, player, ...)
				end
			end
		end
	end

	return result or false --> for responses
end

local function getNetworkInfo(player: Player, networkId: networkId)
	local selectedNetwork = activeNetworks[networkId]
	if selectedNetwork then
		if selectedNetwork.members then
			if not selectedNetwork.members[player] then
				return
			end
		end
		return compressTopics(selectedNetwork.topics), selectedNetwork.members
	end
end

local function newEvent()
	return topic.new(topicTypes.event)
end

local function newResponse()
	return topic.new(topicTypes.response)
end

if isServer then
	eventProxy = Instance.new("RemoteEvent")
	responseProxy = Instance.new("RemoteFunction")
	getReplicatedNetworkInfo = Instance.new("RemoteFunction")

	eventProxy.Name = "eventProxy"
	responseProxy.Name = "responseProxy"
	getReplicatedNetworkInfo.Name = "getReplicatedNetworkInfo"

	eventProxy.OnServerEvent:Connect(serverSignalHandler)
	responseProxy.OnServerInvoke = serverSignalHandler
	getReplicatedNetworkInfo.OnServerInvoke = getNetworkInfo

	eventProxy.Parent = script
	responseProxy.Parent = script
	getReplicatedNetworkInfo.Parent = script
else
	eventProxy = script:FindFirstChild("eventProxy")
	responseProxy = script:FindFirstChild("responseProxy")
	getReplicatedNetworkInfo = script:FindFirstChild("getReplicatedNetworkInfo")
	eventProxy.OnClientEvent:Connect(clientSignalHandler)
end

type network = {
	id: networkId,
	topics: topics,
	members: {[Player]: true},
}
 type networkId = string | Instance
 type memberList = {[number]: Player}
export type type = network
export type topic = {
	type: string,
	name: string,
	connect: (self: any, callback: callback) -> (...any),
	fire: (self: any, ...any) -> (...any),
	fireAll: (self: any, ...any) -> (...any),
	fireNearby: (self: any, location: Vector3, radius: number, ...any) -> (...any),
	fireAllExcept: (self: any, blacklist: memberList, ...any) -> (...any)
}
 type topicClass = topic & {
	network: network,
	callbacks: {[number]: callback}
}
 type topicName = string
 type topicType = string
 type callback = (...any) -> (...any)
 type compressedTopic = {type: string}
 type compressedTopics = {[topicName]: compressedTopic}
 type topics = {[topicName]: topic}

return {
	new = network.new,
	event = newEvent,
	response = newResponse
}
