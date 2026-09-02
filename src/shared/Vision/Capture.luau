const Symbols = require(script.Parent.Symbols)

const Capture = {}

const Internal = setmetatable({}, { __mode = "k" })

const Methods = {}

const Meta = { __index = Methods }

const Reserved = {
    ClassName = true,
    attributes = true,
    Attributes = true,
    tags = true,
    Tags = true,
    AttributeChanged = true,
}

const Settling = 64

const Protected = {
    Mount = true,
    Open = true,
    Cleanup = true,
    Clone = true,
}

const function Register(State, Name: string)
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
        Dependents = {},
        Sources = {},
    }

    State.Events[Name] = Event

    local Targets = Event.Targets
    local Handlers = Event.Handlers
    local Dependents = Event.Dependents

    const Write = function(NewValue: any?): any
        if NewValue == nil then
            return Event.Value
        end

        if NewValue == Event.Value and (type(NewValue) ~= "table" or table.isfrozen(NewValue)) then
            return NewValue
        end

        Event.Value = NewValue

        if Event.Firing then
            Event.Pending = true

            return NewValue
        end

        Event.Firing = true

        const Ok, Err = pcall(function()
            local Rounds = 0

            repeat
                Rounds += 1

                if Rounds > Settling then
                    error(`Vision value "{Name}" kept changing while its handlers ran`, 0)
                end

                Event.Pending = false

                const Current = Event.Value

                for Index = 1, #Handlers do
                    const Handler = Handlers[Index]

                    if not Handler then
                        break
                    end

                    Handler(Targets[Index], Current)
                end
            until not Event.Pending
        end)

        Event.Firing = false

        if not Ok then
            error(Err, 0)
        end

        for Derived in Dependents do
            State.Recompute(Derived)
        end

        return NewValue
    end

    Event.Write = Write
    State.Vision[Name] = Write

    return Event
end

const function Parse(State, Declaration, Parent)
    local ClassName = Declaration.ClassName

    if type(ClassName) ~= "string" then
        error("Declaration requires a ClassName", 0)
    end

    const Node = {
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
        Pending = {},
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
            const Kind = Entry.Kind

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
            elseif Kind == "Derive" then
                local Event = Register(State, Entry.Name)

                if Event.Compute then
                    error(`Vision value "{Entry.Name}" is derived more than once`, 0)
                end

                Event.Compute = Entry.Callback
                table.insert(State.Derived, Event)
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

const function Build(Node)
    const Object = Instance.new(Node.ClassName)

    Node.Instance = Object

    const Pending = Node.Pending

    table.clear(Pending)

    for Key, Value in Node.Properties do
        const Member = Object[Key]

        if typeof(Member) == "RBXScriptSignal" then
            table.insert(Pending, Member)
            table.insert(Pending, Value)
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
            table.insert(Pending, Object:GetAttributeChangedSignal(Key))
            table.insert(Pending, Callback)
        end
    end

    for _, Child in Node.Children do
        Build(Child)
    end
end

const function Resolve(State, Node): Instance?
    local Target = Node.Target

    if typeof(Target) == "Instance" then
        return Target
    end

    if type(Target) == "string" then
        const Found = State.Mounts[Target]

        return if Found then Found.Instance else nil
    end

    return if Node.Parent then Node.Parent.Instance else nil
end

const function Attach(Node)
    for _, Child in Node.Children do
        Attach(Child)
    end

    const Object = Node.Instance
    const Pending = Node.Pending
    const Connections = Node.Connections

    for Index = 1, #Pending, 2 do
        const Callback = Pending[Index + 1]

        table.insert(
            Connections,
            Pending[Index]:Connect(function(...)
                Callback(Object, ...)
            end)
        )
    end

    table.clear(Pending)
end

local function Ready(Node)
    for _, Child in Node.Children do
        Ready(Child)
    end

    if #Node.Ready == 0 then
        return
    end

    const Previous = Symbols.Sink

    Symbols.Sink = function(Callback)
        table.insert(Node.Transient, Callback)
    end

    for _, Callback in Node.Ready do
        Callback(Node.Instance)
    end

    Symbols.Sink = Previous
end

const function Recompute(State, Event, Silent: boolean?)
    if Event.Running then
        error(`Vision value "{Event.Name}" depends on itself`, 0)
    end

    Event.Running = true

    for Source in Event.Sources do
        Source.Dependents[Event] = nil
    end

    table.clear(Event.Sources)

    const Read = function(Name: string): any
        const Source = State.Events[Name]

        if not Source then
            error(`Vision value "{Event.Name}" reads "{Name}", which is not declared`, 0)
        end

        if Source == Event then
            error(`Vision value "{Event.Name}" reads itself`, 0)
        end

        Event.Sources[Source] = true
        Source.Dependents[Event] = true

        return Source.Value
    end

    local Ok, Result = pcall(Event.Compute, Read)

    if not Ok then
        Event.Running = false

        error(Result, 0)
    end

    local Wrote = true

    if Silent then
        Event.Value = Result
    else
        Wrote, Result = pcall(Event.Write, Result)
    end

    Event.Running = false

    if not Wrote then
        error(Result, 0)
    end

    return Result
end

const function Settle(State)
    local Derived = State.Derived

    if #Derived == 0 then
        return
    end

    for _ = 1, #Derived + 1 do
        local Changed = false

        for _, Event in Derived do
            const Before = Event.Value

            Recompute(State, Event, true)

            if Event.Value ~= Before then
                Changed = true
            end
        end

        if not Changed then
            return
        end
    end
end

const function Activate(State)
    for _, Event in State.Events do
        local Bindings = Event.Bindings
        local Targets = Event.Targets
        local Handlers = Event.Handlers

        table.clear(Targets)
        table.clear(Handlers)

        for Index = 1, #Bindings do
            const Binding = Bindings[Index]

            Targets[Index] = Binding.Node.Instance
            Handlers[Index] = Binding.Callback
        end
    end
end

const function Deactivate(State)
    for _, Event in State.Events do
        table.clear(Event.Targets)
        table.clear(Event.Handlers)
    end
end

const function Teardown(Node)
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
    const State = Internal[self]

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
    Settle(State)

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
    Attach(State.Root)
end

function Methods:Open(): Instance
    self:Mount()

    return Internal[self].Root.Instance
end

function Methods:Cleanup()
    const State = Internal[self]

    State.Scope:Forget(self)

    if not State.Mounted then
        return
    end

    State.Mounted = false

    Teardown(State.Root)

    const Runtime = State.Scope.Runtime
    const Linked = next(Runtime.Claims) ~= nil

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
    const State = Internal[self]
    const Copy = State.Scope:Capture(State.Declaration)
    const Fresh = Internal[Copy]

    for Name, Event in State.Events do
        const Other = Fresh.Events[Name]

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

    const State = {
        Scope = Scope,
        Vision = Vision,
        Declaration = Declaration,
        Events = {},
        Derived = {},
        Mounts = {},
        Nodes = {},
        Root = nil,
        Mounted = false,
    }

    State.Recompute = function(Event)
        Recompute(State, Event)
    end

    Internal[Vision] = State
    State.Root = Parse(State, Declaration, nil)

    for _, Event in State.Derived do
        Vision[Event.Name] = function(NewValue: any?): any
            if NewValue == nil then
                return Event.Value
            end

            error(`Vision value "{Event.Name}" is derived and cannot be written to`, 0)
        end
    end

    State.Vision = nil

    return Vision
end

return Capture
