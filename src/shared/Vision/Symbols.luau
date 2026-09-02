local Symbols = {}

local Marker = {}
Marker.__index = Marker

function Symbols.Is(Value: any): boolean
    return type(Value) == "table" and getmetatable(Value) == Marker
end

function Symbols.event(Event: string, InitialValue: any, Callback: (Instance, any) -> ())
    return setmetatable({
        Kind = "Event",
        Name = Event,
        Initial = InitialValue,
        Callback = Callback,
    }, Marker)
end

function Symbols.merge(Event: string, Callback: (Instance, any) -> ())
    return setmetatable({
        Kind = "Merge",
        Name = Event,
        Callback = Callback,
    }, Marker)
end

function Symbols.ready(Callback: (Instance) -> ())
    return setmetatable({
        Kind = "Ready",
        Callback = Callback,
    }, Marker)
end

function Symbols.cleanup(Callback: (Instance) -> ())
    if Symbols.Sink then
        Symbols.Sink(Callback)

        return nil
    end

    return setmetatable({
        Kind = "Cleanup",
        Callback = Callback,
    }, Marker)
end

function Symbols.mount(Target: Instance | string)
    return setmetatable({
        Kind = "Mount",
        Target = Target,
    }, Marker)
end

return Symbols
