const Symbols = {}

const Marker = {}
Marker.__index = Marker

const Token = {}
const Graft = {}

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

function Symbols.derive(
    Name: string,
    Compute: (Mode: string, Read: (string) -> any, Write: (string, any) -> any, Value: any) -> any
)
    return setmetatable({
        Kind = "Derive",
        Name = Name,
        Callback = Compute,
    }, Marker)
end

function Symbols.ready(Callback: (Instance) -> ())
    return setmetatable({
        Kind = "Ready",
        Callback = Callback,
    }, Marker)
end

function Symbols.cleanup(Callback: (Instance) -> ())
    return setmetatable({
        Kind = "Cleanup",
        Callback = Callback,
    }, Marker)
end

function Symbols.drawcall(Callback: (Instance, Vector2) -> ())
    return setmetatable({
        Kind = "Draw",
        Callback = Callback,
    }, Marker)
end

function Symbols.receive(Callback: (Instance, Instance, any) -> Instance?)
    return setmetatable({
        Kind = "Receive",
        Callback = Callback,
    }, Marker)
end

function Symbols.Injected(Value: any): boolean
    return type(Value) == "table" and getmetatable(Value) == Graft
end

function Symbols.inject(...: any)
    return setmetatable({ Hosts = { ... } }, Graft)
end

function Symbols.Styled(Value: any): boolean
    return type(Value) == "table" and getmetatable(Value) == Token
end

function Symbols.style(Name: string)
    return setmetatable({}, {
        __index = function(_, Field: string)
            return setmetatable({ Style = Name, Field = Field }, Token)
        end,
    })
end

function Symbols.mount(Target: Instance | string)
    return setmetatable({
        Kind = "Mount",
        Target = Target,
    }, Marker)
end

return Symbols
