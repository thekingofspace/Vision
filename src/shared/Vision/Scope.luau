local Runtime = require(script.Parent.Link)
const Capture = require(script.Parent.Capture)
const Interpolate = require(script.Parent.Interpolate)

const Scope = {}
Scope.__index = Scope

const function AsList(Value: any): { any }
    if typeof(Value) == "Instance" or Capture.Is(Value) then
        return { Value }
    end

    return Value
end

function Scope.new()
    return setmetatable({
        Runtime = Runtime.new(),
        Visions = {},
        Owned = setmetatable({}, { __mode = "k" }),
    }, Scope)
end

function Scope:Capture(Declaration: any)
    const Vision = Capture.new(self, Declaration)

    self.Owned[Vision] = true

    return Vision
end

function Scope:Update(EventName: string, Value: any)
    for Vision in self.Owned do
        if type(Vision[EventName]) == "function" then
            Vision[EventName](Value)
        end
    end
end

function Scope:Adopt(Vision: any)
    self.Owned[Vision] = true

    if not table.find(self.Visions, Vision) then
        table.insert(self.Visions, Vision)
    end
end

function Scope:Forget(Vision: any)
    self.Owned[Vision] = nil

    const Index = table.find(self.Visions, Vision)

    if Index then
        table.remove(self.Visions, Index)
    end
end

function Scope:SpringValue(Info: TweenInfo, Vision: any, ValueName: string, TargetValue: any)
    const Targets = AsList(Vision)
    const Starts = {}
    const Slots = {}

    for _, Item in Targets do
        const Cap = Item[ValueName]

        if type(Cap) ~= "function" then
            error(`Vision has no value named "{ValueName}"`, 0)
        end

        Starts[Item] = Cap()
        table.insert(Slots, { Item, ValueName })
    end

    return self.Runtime:Create(Info, function(Alpha: number)
        for _, Item in Targets do
            Item[ValueName](Interpolate.Value(Starts[Item], TargetValue, Alpha))
        end
    end, Slots)
end

function Scope:SpringEvent(Info: TweenInfo, Vision: any, TargetEvents: { [string]: any })
    const Targets = AsList(Vision)
    const Tracks = {}
    const Slots = {}

    for _, Item in Targets do
        for Name, Goal in TargetEvents do
            const Cap = Item[Name]

            if type(Cap) ~= "function" then
                error(`Vision has no value named "{Name}"`, 0)
            end

            table.insert(Tracks, { Cap = Cap, Start = Cap(), Goal = Goal })
            table.insert(Slots, { Item, Name })
        end
    end

    return self.Runtime:Create(Info, function(Alpha: number)
        for _, Track in Tracks do
            Track.Cap(Interpolate.Value(Track.Start, Track.Goal, Alpha))
        end
    end, Slots)
end

function Scope:SpringInstance(Info: TweenInfo, Object: any, TargetProps: { [string]: any })
    const Targets = AsList(Object)
    const Starts = {}
    const Slots = {}

    for _, Item in Targets do
        const Values = {}

        for Key in TargetProps do
            Values[Key] = Item[Key]
            table.insert(Slots, { Item, Key })
        end

        Starts[Item] = Values
    end

    return self.Runtime:Create(Info, function(Alpha: number)
        for _, Item in Targets do
            const Values = Starts[Item]

            for Key, Goal in TargetProps do
                Item[Key] = Interpolate.Value(Values[Key], Goal, Alpha)
            end
        end
    end, Slots)
end

function Scope:SpringFunction(
    Info: TweenInfo,
    TargetFun: (any, number) -> (),
    InitialValue: any,
    TargetValue: any
)
    return self.Runtime:Create(Info, function(Alpha: number, DeltaTime: number)
        TargetFun(Interpolate.Value(InitialValue, TargetValue, Alpha), DeltaTime)
    end, { { TargetFun, "" } })
end

const function Channel(Owner: any, Name: string, Current: any, Goal: any, Write: (any) -> ())
    local Kind = typeof(Current)

    if Kind ~= typeof(Goal) then
        error(`cannot solve {Kind} toward {typeof(Goal)}`, 0)
    end

    local Position = Interpolate.Components(Current)
    const Target = Interpolate.Components(Goal)

    if not Position or not Target then
        error(`{Kind} cannot be solved by a physics spring, use a tween instead`, 0)
    end

    local Velocity = table.create(#Position, 0)

    for Index = 1, #Position do
        Velocity[Index] = 0
    end

    return {
        Owner = Owner,
        Name = Name,
        Kind = Kind,
        Position = Position,
        Velocity = Velocity,
        Goal = Target,
        Write = Write,
    }
end

function Scope:PhysicsValue(Period: number, Damping: number, Vision: any, ValueName: string, TargetValue: any)
    const Targets = AsList(Vision)
    const Channels = {}

    for _, Item in Targets do
        const Cap = Item[ValueName]

        if type(Cap) ~= "function" then
            error(`Vision has no value named "{ValueName}"`, 0)
        end

        table.insert(Channels, Channel(Item, ValueName, Cap(), TargetValue, Cap))
    end

    return self.Runtime:Solve(Period, Damping, Channels)
end

function Scope:PhysicsEvent(Period: number, Damping: number, Vision: any, TargetEvents: { [string]: any })
    const Targets = AsList(Vision)
    const Channels = {}

    for _, Item in Targets do
        for Name, Goal in TargetEvents do
            const Cap = Item[Name]

            if type(Cap) ~= "function" then
                error(`Vision has no value named "{Name}"`, 0)
            end

            table.insert(Channels, Channel(Item, Name, Cap(), Goal, Cap))
        end
    end

    return self.Runtime:Solve(Period, Damping, Channels)
end

function Scope:PhysicsInstance(Period: number, Damping: number, Object: any, TargetProps: { [string]: any })
    const Targets = AsList(Object)
    const Channels = {}

    for _, Item in Targets do
        for Key, Goal in TargetProps do
            table.insert(
                Channels,
                Channel(Item, Key, Item[Key], Goal, function(Value)
                    Item[Key] = Value
                end)
            )
        end
    end

    return self.Runtime:Solve(Period, Damping, Channels)
end

function Scope:PhysicsFunction(
    Period: number,
    Damping: number,
    TargetFun: (any) -> (),
    InitialValue: any,
    TargetValue: any
)
    return self.Runtime:Solve(Period, Damping, {
        Channel(TargetFun, "", InitialValue, TargetValue, TargetFun),
    })
end

function Scope:Release()
    for _, Vision in table.clone(self.Visions) do
        Vision:Cleanup()
    end

    table.clear(self.Visions)
    table.clear(self.Owned)
    self.Runtime:Release()
end

return Scope
