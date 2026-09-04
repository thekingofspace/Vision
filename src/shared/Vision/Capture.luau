const Symbols = require(script.Parent.Symbols)

const Token = Symbols.Token
const Viewport = require(script.Parent.Viewport)

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
    MountAsync = true,
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
    Event.Set = Write
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
        Fields = nil,
        Painted = nil,
        Children = {},
        Ready = {},
        Receive = {},
        Draw = {},
        Cleanup = {},
        Transient = {},
        Connections = {},
        Pending = {},
        Parent = Parent,
        Target = nil,
        Instance = nil,
    }

    table.insert(State.Nodes, Node)

    const Fields = {}
    const Name = Declaration.Name
    local Painted
    local Slot = 0

    for Key, Value in Declaration do
        if type(Key) ~= "string" or Reserved[Key] then
            continue
        end

        if type(Value) == "table" and getmetatable(Value) == Token then
            if not Painted then
                Painted = {}
            end

            table.insert(Painted, Key)
            table.insert(Painted, Value)
        else
            Fields[Slot + 1] = Key
            Fields[Slot + 2] = Value
            Slot += 2
        end
    end

    Node.Fields = Fields
    Node.Painted = Painted

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
            elseif Kind == "Receive" then
                table.insert(Node.Receive, Entry.Callback)
            elseif Kind == "Cleanup" then
                table.insert(Node.Cleanup, Entry.Callback)
            elseif Kind == "Draw" then
                table.insert(Node.Draw, Entry.Callback)
            elseif Kind == "Mount" then
                Node.Target = Entry.Target
            end
        elseif type(Entry) == "table" then
            table.insert(Node.Children, Parse(State, Entry, Node))
        end
    end

    return Node
end

const Wired = {}

const function Raise(State, Node)
    const ClassName = Node.ClassName
    const Object = Instance.new(ClassName)

    Node.Instance = Object

    const Pending = Node.Pending
    const Fields = Node.Fields

    table.clear(Pending)

    local Known = Wired[ClassName]

    if not Known then
        Known = {}
        Wired[ClassName] = Known
    end

    local Slot = 0

    for Index = 1, #Fields, 2 do
        const Key = Fields[Index]
        const Value = Fields[Index + 1]

        local Signal = Known[Key]

        if Signal == nil then
            Signal = typeof(Object[Key]) == "RBXScriptSignal"
            Known[Key] = Signal
        end

        if Signal then
            Pending[Slot + 1] = Object[Key]
            Pending[Slot + 2] = Value
            Slot += 2
        else
            Object[Key] = Value
        end
    end

    const Painted = Node.Painted

    if Painted then
        const Sheets = State.Scope.Styles
        const Connections = Node.Connections

        for Index = 1, #Painted, 2 do
            const Key = Painted[Index]
            const Token = Painted[Index + 1]
            const Sheet = Sheets[Token.Style]

            if not Sheet then
                error(`style "{Token.Style}" is not loaded on this scope`, 0)
            end

            Object[Key] = Sheet:Get(Token.Field)
            Connections[#Connections + 1] = Sheet:Attach(Object, Key, Token.Field)
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
            Pending[Slot + 1] = Object:GetAttributeChangedSignal(Key)
            Pending[Slot + 2] = Callback
            Slot += 2
        end
    end
end

const function Build(State)
    const Nodes = State.Nodes

    for Index = 1, #Nodes do
        Raise(State, Nodes[Index])
    end
end

const function Offer(Host, Pending: Instance, Source): Instance?
    const Other = Internal[Host]

    if not Other or not Other.Mounted then
        return nil
    end

    for _, Node in Other.Nodes do
        const Object = Node.Instance

        if Object then
            for _, Callback in Node.Receive do
                const Taken = Callback(Object, Pending, Source)

                if typeof(Taken) == "Instance" then
                    return Taken
                end
            end
        end
    end

    return nil
end

const function Graft(State, Node, Target, Source): Instance?
    const Pending = Node.Instance

    if not Pending then
        return nil
    end

    const Handle = State.Handle

    for _, Host in Target.Hosts do
        const Spot = Offer(Host, Pending, Source)

        if Spot then
            table.insert(
                Node.Connections,
                Pending.Destroying:Connect(function()
                    const Owner = Handle[1]

                    if Owner then
                        Owner:Cleanup()
                    end
                end)
            )

            return Spot
        end
    end

    return nil
end

const function Resolve(State, Node, Source): Instance?
    local Target = Node.Target

    if typeof(Target) == "Instance" then
        return Target
    end

    if type(Target) == "string" then
        const Found = State.Mounts[Target]

        return if Found then Found.Instance else nil
    end

    if Symbols.Injected(Target) then
        return Graft(State, Node, Target, Source)
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

const function Paint(Node, Size: Vector2)
    for _, Child in Node.Children do
        Paint(Child, Size)
    end

    for _, Callback in Node.Draw do
        Callback(Node.Instance, Size)
    end
end

const function Observe(Node)
    for _, Child in Node.Children do
        Observe(Child)
    end

    if #Node.Draw == 0 then
        return
    end

    const Object = Node.Instance
    const Draw = Node.Draw

    table.insert(
        Node.Connections,
        Viewport.Listen(function(Size: Vector2)
            for _, Callback in Draw do
                Callback(Object, Size)
            end
        end)
    )
end

local function Ready(Node)
    for _, Child in Node.Children do
        Ready(Child)
    end

    if #Node.Ready == 0 then
        return
    end

    const Later = function(Callback: (Instance) -> ())
        table.insert(Node.Transient, Callback)
    end

    for _, Callback in Node.Ready do
        Callback(Node.Instance, Later)
    end
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

    const Refuse = function(Name: string): any
        error(`Vision value "{Event.Name}" tried to write "{Name}" while computing`, 0)
    end

    local Ok, Result = pcall(Event.Compute, "get", Read, Refuse)

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

const function Finish(State, Source)
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

    Paint(State.Root, Viewport.Current())

    State.Root.Instance.Parent = Resolve(State, State.Root, Source)

    Ready(State.Root)
    Attach(State.Root)
    Observe(State.Root)
end

function Methods:Mount()
    const State = Internal[self]

    if State.Mounted then
        const Root = State.Root.Instance

        if Root and Root.Parent == nil and Symbols.Injected(State.Root.Target) then
            Root.Parent = Resolve(State, State.Root, self)
        end

        return
    end

    State.Mounted = true
    State.Generation += 1
    State.Scope:Adopt(self)

    Build(State)

    for _, Node in State.Nodes do
        if Node ~= State.Root then
            Node.Instance.Parent = Resolve(State, Node, self)
        end
    end

    Finish(State, self)
end

function Methods:MountAsync(Budget: number?)
    const State = Internal[self]

    if State.Mounted then
        return
    end

    State.Mounted = true
    State.Generation += 1
    State.Scope:Adopt(self)

    const Mark = State.Generation
    const Slice = Budget or 0.002
    const Nodes = State.Nodes
    const Built = {}

    local Clock = os.clock()

    const function Spent(): boolean
        if os.clock() - Clock <= Slice then
            return false
        end

        task.wait()

        Clock = os.clock()

        if State.Generation ~= Mark then
            for _, Object in Built do
                Object:Destroy()
            end

            return true
        end

        return false
    end

    for Index = 1, #Nodes do
        Raise(State, Nodes[Index])
        table.insert(Built, Nodes[Index].Instance)

        if Spent() then
            return
        end
    end

    for Index = 1, #Nodes do
        const Node = Nodes[Index]

        if Node ~= State.Root then
            Node.Instance.Parent = Resolve(State, Node, self)
        end

        if Spent() then
            return
        end
    end

    Finish(State, self)
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
    State.Generation += 1

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
        table.clear(Node.Pending)

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
        Handle = setmetatable({}, { __mode = "v" }),
        Root = nil,
        Mounted = false,
        Generation = 0,
    }

    State.Recompute = function(Event)
        Recompute(State, Event)
    end

    Internal[Vision] = State
    State.Handle[1] = Vision
    State.Root = Parse(State, Declaration, nil)

    for _, Event in State.Derived do
        const Compute = Event.Compute

        const Source = function(Name: string)
            const Found = State.Events[Name]

            if not Found then
                error(`Vision value "{Event.Name}" refers to "{Name}", which is not declared`, 0)
            end

            return Found
        end

        const Plain = function(Name: string): any
            return Source(Name).Value
        end

        const Push = function(Name: string, NewValue: any): any
            return Source(Name).Set(NewValue)
        end

        Event.Set = function(NewValue: any?): any
            if NewValue == nil then
                return Event.Value
            end

            Compute("set", Plain, Push, NewValue)

            return Event.Value
        end

        Vision[Event.Name] = Event.Set
    end

    State.Vision = nil

    return Vision
end

return Capture
