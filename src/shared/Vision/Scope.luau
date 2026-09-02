local Runtime = require(script.Parent.Link)
local Capture = require(script.Parent.Capture)
local Interpolate = require(script.Parent.Interpolate)

local Scope = {}
Scope.__index = Scope

local function AsList(Value: any): { any }
    if typeof(Value) == "Instance" or Capture.Is(Value) then
        return { Value }
    end

    return Value
end

function Scope.new()
    return setmetatable({
        Runtime = Runtime.new(),
        Visions = {},
    }, Scope)
end

function Scope:Capture(Declaration: any)
    local Vision = Capture.new(self, Declaration)

    table.insert(self.Visions, Vision)

    return Vision
end

function Scope:Adopt(Vision: any)
    if not table.find(self.Visions, Vision) then
        table.insert(self.Visions, Vision)
    end
end

function Scope:Forget(Vision: any)
    local Index = table.find(self.Visions, Vision)

    if Index then
        table.remove(self.Visions, Index)
    end
end

function Scope:SpringValue(Info: TweenInfo, Vision: any, ValueName: string, TargetValue: any)
    local Targets = AsList(Vision)
    local Starts = {}
    local Slots = {}

    for _, Item in Targets do
        local Cap = Item[ValueName]

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

function Scope:SpringInstance(Info: TweenInfo, Object: any, TargetProps: { [string]: any })
    local Targets = AsList(Object)
    local Starts = {}
    local Slots = {}

    for _, Item in Targets do
        local Values = {}

        for Key in TargetProps do
            Values[Key] = Item[Key]
            table.insert(Slots, { Item, Key })
        end

        Starts[Item] = Values
    end

    return self.Runtime:Create(Info, function(Alpha: number)
        for _, Item in Targets do
            local Values = Starts[Item]

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

function Scope:Release()
    for _, Vision in table.clone(self.Visions) do
        Vision:Cleanup()
    end

    table.clear(self.Visions)
    self.Runtime:Release()
end

return Scope
