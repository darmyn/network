local runService = game:GetService("RunService")

type enumValue = number
type enum = {[string]: enumValue}

local topicTypes: enum = {
    event = 1,
    response = 2
}

local isServer = runService:IsServer()
local eventProxy: RemoteEvent
local responseProxy: RemoteFunction
local activeNetworks = {} :: {[networkId]: network}

local function handleIncomingServer(player: Player, networkId: networkId, topicName: string, ...)
    local specifiedNetwork = activeNetworks[networkId]
    if specifiedNetwork then
        if specifiedNetwork:canPlayerAccess(player) then
            local topic = specifiedNetwork.topics[topicName]
            if topic then
                if topic.type == topicTypes.event then
                    topic = topic :: event
                    topic:fireConnections(player, ...)
                elseif topic.type == topicTypes.response then
                    topic = topic :: response
                    return topic.callback(player, ...)
                end
            end
        end
    end
end

local function handleIncomingClient(networkId: networkId, topicName: string, ...)
    local specifiedNetwork = activeNetworks[networkId]
    if specifiedNetwork then
        local topic = specifiedNetwork.topics[topicName]
        if topic then
            if topic.type == topicTypes.event then
                topic = topic :: event
                topic:fireConnections(...)
            end
        end        
    end
end

local function initializeProxies()
    if isServer then
        eventProxy = Instance.new("RemoteEvent")
        eventProxy.Name = "eventProxy"
        eventProxy.Parent = script
        
        responseProxy = Instance.new("RemoteFunction")
        responseProxy.Name = "responseProxy"
        responseProxy.Parent = script
    else
        eventProxy = script:FindFirstChild("eventProxy")
        responseProxy = script:FindFirstChild("responseProxy")
    end
end

local function connectProxies()
    if isServer then
        eventProxy.OnServerEvent:Connect(handleIncomingServer)
        responseProxy.OnServerInvoke = handleIncomingServer
    else
        eventProxy.OnClientEvent:Connect(handleIncomingClient)
    end
end

type callback = (...any) -> (any)
type topic = {
    type: enumValue,
    name: string,
    networkId: networkId,
    fire: (self: any, ...any) -> (any),
    connect: (self: any, callback: callback) -> (any)
}

local event = {} :: event
event.__index = event

function event.new()
    local self = setmetatable({}, event)
    self.connections = {}
    self.type = topicTypes.event
    return self
end

function event:fireConnections(...)
    for _, callback in pairs(self.connections) do
        callback(...)
    end
end

function event:fire(...)
    if isServer then
        local args = table.pack(...)
        local player = args[1]
        table.remove(args, 1)
        eventProxy:FireClient(player, self.networkId, self.name, table.unpack(args))
    else
        eventProxy:FireServer(self.networkId, self.name, ...)
    end
end

function event:connect(callback: callback)
    table.insert(self.connections, callback)
    return {
        disconnect = function()
            local idx = table.find(self.connections, callback)
            if idx then
                table.remove(self.connections, idx)
            end           
        end
    }
end

type event = topic & typeof(event.new())

local response = {} :: response
response.__index = response

function response.new()
    local self = setmetatable({}, response)
    self.type = topicTypes.response
    return self
end

function response:fire(...)
    if not isServer then
        return responseProxy:InvokeServer(self.networkId, self.name, ...)
    end
end

function response:connect(callback: callback)
    self.callback = callback
end

type response = topic & typeof(response.new()) & {
    callback: (player: Player, ...any) -> (any) | nil
}

type networkId = string | number | Instance
local network = {} :: network
network.__index = network

local function compressTopics(topics)
    local compressedTopics = {}
    for topicName, topic: topic in pairs(topics) do
        compressedTopics[topicName] = topic.type
    end
    return compressedTopics
end

local function decompressTopics(compressedTopics)
    local decompressedTopics = {}
    for topicName, topicType in pairs(compressedTopics) do
        if topicType == topicTypes.event then
            decompressedTopics[topicName] = event.new()
        elseif topicType == topicTypes.response then
            decompressedTopics[topicName] = response.new()
        end
    end
    return decompressedTopics
end

function network.new(networkId: networkId, topics:{[string]: topic}?, members: {Player}?)
    local self = setmetatable({}, network)
    self.networkId = networkId
    self.topics = topics
    self.members = members

    if isServer then
        local compressedTopics = compressTopics(self.topics)

        local fetchCompressedTopics = response.new()
        self.topics.fetchCompressedTopics = fetchCompressedTopics
        fetchCompressedTopics:connect(function()
            return compressedTopics
        end)
    else
        local fetchedCompressedTopics = responseProxy:InvokeServer(self.networkId, "fetchCompressedTopics")
        if fetchedCompressedTopics then
            self.topics = decompressTopics(fetchedCompressedTopics)
        end
    end

    for topicName, topic: topic in pairs(self.topics) do
        topic.name = topicName
        topic.networkId = networkId
    end

    activeNetworks[networkId] = self
    return self
end

function network:canPlayerAccess(player: Player)
    if self.members then
        if not table.find(self.members, player) then
            return false
        end
    end
    return true
end

type network = typeof(network.new(0))

initializeProxies()
connectProxies()
return {
    new = network.new,
    event = event,
    response = response
}