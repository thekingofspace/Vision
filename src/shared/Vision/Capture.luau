local Symbols = require(script.Parent.Symbols)

local Capture = {}

local Internal = setmetatable({}, { __mode = "k" })

local Methods = {}

local Meta = { __index = Methods }

local Reserved = {
    ClassName = true,
    attributes = true,
    Attributes = true,
    tags = true,
    Tags = true,
    AttributeChanged = true,
}

local Protected = {
    Mount = true,
    Open = true,
    Cleanup = true,
    Clone = true,
}

local function Register(State, Name: string)
    local Event = State.Events[Name]

    if Event then
        return Event
    end

    if Protected[Name] then
        error(`Vision event "{Name}" collides with a reserved method name`, 0)
    end

    Event = {
        Name = Name,
        Value = nil,
        Declared = false,
        Bindings = {},
        Targets = {},
        Handlers = {},
    }

    State.Events[Name] = Event

    local Targets = Event.Targets
    local Handlers = Event.Handlers

    State.Vision[Name] = function(NewValue: any?): any
        if NewValue == nil then
            return Event.Value
        end

        if NewValue == Event.Value and (type(NewValue) ~= "table" or table.isfrozen(NewValue)) then
            return NewValue
        end

        Event.Value = NewValue

        for Index = 1, #Handlers do
            Handlers[Index](Targets[Index], NewValue)
        end

        return NewValue
    end

    return Event
end

local function Parse(State, Declaration, Parent)
    local ClassName = Declaration.ClassName

    if type(ClassName) ~= "string" then
        error("Declaration requires a ClassName", 0)
    end

    local Node = {
        ClassName = ClassName,
        Attributes = Declaration.attributes or Declaration.Attributes,
        AttributeChanged = Declaration.AttributeChanged,
        Tags = Declaration.tags or Declaration.Tags,
        Properties = {},
        Children = {},
        Ready = {},
        Cleanup = {},
        Transient = {},
        Connections = {},
        Parent = Parent,
        Target = nil,
        Instance = nil,
    }

    table.insert(State.Nodes, Node)

    for Key, Value in Declaration do
        if type(Key) ~= "string" or Reserved[Key] then
            continue
        end

        Node.Properties[Key] = Value
    end

    local Name = Node.Properties.Name

    if type(Name) == "string" then
        State.Mounts[Name] = Node
    end

    for _, Entry in ipairs(Declaration) do
        if Symbols.Is(Entry) then
            local Kind = Entry.Kind

            if Kind == "Event" then
                local Event = Register(State, Entry.Name)

                if not Event.Declared then
                    Event.Declared = true
                    Event.Value = Entry.Initial
                end

                table.insert(Event.Bindings, { Node = Node, Callback = Entry.Callback })
            elseif Kind == "Merge" then
                local Event = Register(State, Entry.Name)

                table.insert(Event.Bindings, { Node = Node, Callback = Entry.Callback })
            elseif Kind == "Ready" then
                table.insert(Node.Ready, Entry.Callback)
            elseif Kind == "Cleanup" then
                table.insert(Node.Cleanup, Entry.Callback)
            elseif Kind == "Mount" then
                Node.Target = Entry.Target
            end
        elseif type(Entry) == "table" then
            table.insert(Node.Children, Parse(State, Entry, Node))
        end
    end

    return Node
end

local function Build(Node)
    local Object = Instance.new(Node.ClassName)

    Node.Instance = Object

    for Key, Value in Node.Properties do
        local Member = Object[Key]

        if typeof(Member) == "RBXScriptSignal" then
            table.insert(
                Node.Connections,
                Member:Connect(function(...)
                    Value(Object, ...)
                end)
            )
        else
            Object[Key] = Value
        end
    end

    if Node.Attributes then
        for Key, Value in Node.Attributes do
            Object:SetAttribute(Key, Value)
        end
    end

    if Node.Tags then
        for Key, Value in Node.Tags do
            if type(Key) == "number" then
                Object:AddTag(Value)
            elseif Value then
                Object:AddTag(Key)
            end
        end
    end

    if Node.AttributeChanged then
        for Key, Callback in Node.AttributeChanged do
            table.insert(
                Node.Connections,
                Object:GetAttributeChangedSignal(Key):Connect(function(...)
                    Callback(Object, ...)
                end)
            )
        end
    end

    for _, Child in Node.Children do
        Build(Child)
    end
end

local function Resolve(State, Node): Instance?
    local Target = Node.Target

    if typeof(Target) == "Instance" then
        return Target
    end

    if type(Target) == "string" then
        local Found = State.Mounts[Target]

        return if Found then Found.Instance else nil
    end

    return if Node.Parent then Node.Parent.Instance else nil
end

local function Ready(Node)
    for _, Child in Node.Children do
        Ready(Child)
    end

    if #Node.Ready == 0 then
        return
    end

    local Previous = Symbols.Sink

    Symbols.Sink = function(Callback)
        table.insert(Node.Transient, Callback)
    end

    for _, Callback in Node.Ready do
        Callback(Node.Instance)
    end

    Symbols.Sink = Previous
end

local function Activate(State)
    for _, Event in State.Events do
        local Bindings = Event.Bindings
        local Targets = Event.Targets
        local Handlers = Event.Handlers

        table.clear(Targets)
        table.clear(Handlers)

        for Index = 1, #Bindings do
            local Binding = Bindings[Index]

            Targets[Index] = Binding.Node.Instance
            Handlers[Index] = Binding.Callback
        end
    end
end

local function Deactivate(State)
    for _, Event in State.Events do
        table.clear(Event.Targets)
        table.clear(Event.Handlers)
    end
end

local function Teardown(Node)
    for _, Child in Node.Children do
        Teardown(Child)
    end

    if not Node.Instance then
        return
    end

    for Index = #Node.Transient, 1, -1 do
        Node.Transient[Index](Node.Instance)
    end

    table.clear(Node.Transient)

    for Index = #Node.Cleanup, 1, -1 do
        Node.Cleanup[Index](Node.Instance)
    end
end

function Methods:Mount()
    local State = Internal[self]

    if State.Mounted then
        return
    end

    State.Mounted = true
    State.Scope:Adopt(self)

    Build(State.Root)

    for _, Node in State.Nodes do
        if Node ~= State.Root then
            Node.Instance.Parent = Resolve(State, Node)
        end
    end

    Activate(State)

    for _, Event in State.Events do
        local Targets = Event.Targets
        local Handlers = Event.Handlers
        local Value = Event.Value

        for Index = 1, #Handlers do
            Handlers[Index](Targets[Index], Value)
        end
    end

    State.Root.Instance.Parent = Resolve(State, State.Root)

    Ready(State.Root)
end

function Methods:Open(): Instance
    self:Mount()

    return Internal[self].Root.Instance
end

function Methods:Cleanup()
    local State = Internal[self]

    State.Scope:Forget(self)

    if not State.Mounted then
        return
    end

    State.Mounted = false

    Teardown(State.Root)

    local Runtime = State.Scope.Runtime
    local Linked = next(Runtime.Claims) ~= nil

    if Linked then
        Runtime:CancelOwner(self)
    end

    for _, Node in State.Nodes do
        for _, Connection in Node.Connections do
            Connection:Disconnect()
        end

        table.clear(Node.Connections)

        if Linked and Node.Instance then
            Runtime:CancelOwner(Node.Instance)
        end
    end

    if State.Root.Instance then
        State.Root.Instance:Destroy()
    end

    for _, Node in State.Nodes do
        Node.Instance = nil
    end

    Deactivate(State)
end

function Methods:Clone()
    local State = Internal[self]
    local Copy = State.Scope:Capture(State.Declaration)
    local Fresh = Internal[Copy]

    for Name, Event in State.Events do
        local Other = Fresh.Events[Name]

        if Other then
            Other.Value = Event.Value
        end
    end

    return Copy
end

function Capture.Is(Value: any): boolean
    return type(Value) == "table" and Internal[Value] ~= nil
end

function Capture.new(Scope, Declaration)
    local Vision = setmetatable({}, Meta)

    local State = {
        Scope = Scope,
        Vision = Vision,
        Declaration = Declaration,
        Events = {},
        Mounts = {},
        Nodes = {},
        Root = nil,
        Mounted = false,
    }

    Internal[Vision] = State
    State.Root = Parse(State, Declaration, nil)

    return Vision
end

return Capture
