const Symbols = require(script.Parent.Symbols)

const Methods = {}

const Tuning = { Looped = "boolean", SmoothLoop = "boolean", Speed = "number", RestageTime = "number" }

const Animation = {
    __index = function(self, Key: string)
        if Key == "Finished" then
            const Link = rawget(self, "Link")

            return if Link then Link.Finished else true
        end

        if Tuning[Key] then
            const Link = rawget(self, "Link")

            return if Link then Link[Key] else rawget(self, "Saved")[Key]
        end

        return Methods[Key]
    end,

    __newindex = function(self, Key: string, Value: any)
        const Want = Tuning[Key]

        if not Want then
            rawset(self, Key, Value)

            return
        end

        if type(Value) ~= Want then
            error(`an animation's {Key} must be a {Want}`, 0)
        end

        if Key == "Speed" and Value < 0 then
            error("an animation's Speed cannot be negative", 0)
        end

        if Key == "RestageTime" and Value < 0 then
            error("an animation's RestageTime cannot be negative", 0)
        end

        rawget(self, "Saved")[Key] = Value

        const Link = rawget(self, "Link")

        if Link then
            Link[Key] = Value
        end
    end,
}

const function Order(Left, Right): boolean
    return Left.Time < Right.Time
end

const function Read(Keyframes: { any })
    if type(Keyframes) ~= "table" or #Keyframes == 0 then
        error("an animation needs at least one keyframe", 0)
    end

    const Sorted = table.clone(Keyframes)

    for Index, Entry in Sorted do
        if not Symbols.Framed(Entry) then
            error(`entry {Index} of the animation is not a Keyframe`, 0)
        end
    end

    table.sort(Sorted, Order)

    const Tracks = {}
    const Named = {}
    const Marks = {}

    local Length = 0

    for _, Frame in Sorted do
        if Frame.Time > Length then
            Length = Frame.Time
        end

        for Property, Value in Frame.Properties do
            local Track = Named[Property]

            if not Track then
                Track = { Property = Property, Stops = {}, Index = 0, From = nil, Springy = false }
                Named[Property] = Track
                table.insert(Tracks, Track)
            end

            table.insert(Track.Stops, { Time = Frame.Time, Value = Value, Easing = Frame.Easing })
        end

        if Frame.Events then
            for Name, Args in Frame.Events do
                table.insert(Marks, { Time = Frame.Time, Name = Name, Args = if type(Args) == "table" then Args else { Args } })
            end
        end
    end

    table.sort(Marks, Order)

    if #Tracks == 0 and #Marks == 0 then
        error("an animation needs at least one property or event", 0)
    end

    return Tracks, Marks, Length
end

function Animation.new(Scope, Keyframes: { any }, Object: Instance)
    if typeof(Object) ~= "Instance" then
        error("an animation needs an instance to play on", 0)
    end

    const Tracks, Marks, Length = Read(Keyframes)

    const Self = setmetatable({}, Animation)

    rawset(Self, "Saved", { Looped = false, SmoothLoop = false, Speed = 1, RestageTime = 0.25 })
    rawset(Self, "Binds", {})
    rawset(Self, "Link", nil)

    const Binds = Self.Binds

    const Fire = function(Name: string, Args: { any })
        const Listeners = Binds[Name]

        if not Listeners then
            return
        end

        for _, Callback in table.clone(Listeners) do
            Callback(Object, table.unpack(Args))
        end
    end

    rawset(Self, "Link", Scope.Runtime:Play(Object, Tracks, Marks, Length, Fire))

    return Self
end

function Methods:Bind(Name: string, Callback: (Instance, ...any) -> ())
    if type(Name) ~= "string" then
        error("an animation event needs a name", 0)
    end

    const Binds = rawget(self, "Binds")

    if not Binds then
        return { Disconnect = function() end }
    end

    local Listeners = Binds[Name]

    if not Listeners then
        Listeners = {}
        Binds[Name] = Listeners
    end

    table.insert(Listeners, Callback)

    return {
        Disconnect = function()
            const Slot = if Listeners then table.find(Listeners, Callback) else nil

            if Slot then
                table.remove(Listeners, Slot)
            end
        end,
    }
end

function Methods:Jump(Time: number)
    if type(Time) ~= "number" then
        error("Jump needs a time in seconds", 0)
    end

    const Link = rawget(self, "Link")

    if Link then
        Link:Seek(Time)
    end

    return self
end

function Methods:Await()
    const Link = rawget(self, "Link")

    if Link and not Link.Finished then
        Link:Await()
    end
end

function Methods:Stop()
    const Link = rawget(self, "Link")

    if Link then
        Link:Cancel()
    end
end

function Methods:Destroy()
    self:Stop()

    const Binds = rawget(self, "Binds")

    if Binds then
        table.clear(Binds)
    end

    rawset(self, "Binds", nil)
    rawset(self, "Link", nil)
end

return Animation
