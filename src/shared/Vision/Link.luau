const RunService = game:GetService("RunService")

const Interpolate = require(script.Parent.Interpolate)

const Link = {}
Link.__index = Link

local Runtime = {}
Runtime.__index = Runtime

const Epsilon = 0.0005
const Critical = 1e-4

const function Coefficients(Omega: number, Damping: number, DeltaTime: number)
    const Decay = Damping * Omega

    if Damping < 1 - Critical then
        const Ring = Omega * math.sqrt(1 - Damping * Damping)
        const Fade = math.exp(-Decay * DeltaTime)
        const Cos = math.cos(Ring * DeltaTime)
        const Sin = math.sin(Ring * DeltaTime) / Ring

        return Fade * (Cos + Decay * Sin), Fade * Sin, -Fade * Omega * Omega * Sin, Fade * (Cos - Decay * Sin)
    end

    if Damping <= 1 + Critical then
        const Fade = math.exp(-Omega * DeltaTime)
        const Span = Fade * DeltaTime

        return Fade + Omega * Span, Span, -Omega * Omega * Span, Fade - Omega * Span
    end

    const Root = Omega * math.sqrt(Damping * Damping - 1)
    const Fast = math.exp((Root - Decay) * DeltaTime)
    const Slow = math.exp((-Root - Decay) * DeltaTime)
    const Cosh = (Fast + Slow) * 0.5
    const Sinh = (Fast - Slow) * 0.5 / Root

    return Cosh + Decay * Sinh, Sinh, -Omega * Omega * Sinh, Cosh - Decay * Sinh
end

const function Springs(Easing: any): boolean
    return type(Easing) == "table"
        and typeof(Easing) ~= "TweenInfo"
        and (Easing.Damping ~= nil or Easing.Dampening ~= nil or Easing.Period ~= nil)
end

const function Solve(Track: any, Object: Instance, DeltaTime: number): boolean
    const Carry, Push, Pull, Keep = Coefficients(Track.Omega, Track.Damping, DeltaTime)
    const Position = Track.Position
    const Velocity = Track.Velocity
    const Goal = Track.Goal
    const Count = #Position

    local Done = true

    for Index = 1, Count do
        const Offset = Position[Index] - Goal[Index]
        const Speed = Velocity[Index]

        Position[Index] = Goal[Index] + Carry * Offset + Push * Speed
        Velocity[Index] = Pull * Offset + Keep * Speed

        const Scale = math.max(1, math.abs(Goal[Index]))

        if
            math.abs(Position[Index] - Goal[Index]) > Epsilon * Scale
            or math.abs(Velocity[Index]) > Epsilon * Scale
        then
            Done = false
        end
    end

    if Done then
        for Index = 1, Count do
            Position[Index] = Goal[Index]
            Velocity[Index] = 0
        end
    end

    Object[Track.Property] = Track.Make(Position)

    return Done
end

const function Enter(Track: any, Object: Instance, Head: any, Tail: any)
    Track.From = if Track.Springy then Object[Track.Property] else Head.Value

    const Easing = Tail.Easing

    if not Springs(Easing) then
        Track.Springy = false

        return
    end

    const Span = Tail.Time - Head.Time
    const Period = Easing.Period or (if Span > 0 then Span else 0.5)

    Track.Springy = true
    Track.Omega = 2 * math.pi / math.max(Period, 1e-4)
    Track.Damping = math.max(Easing.Damping or Easing.Dampening or 0, 0)

    const Start = Interpolate.Components(Track.From)
    const Goal = Interpolate.Components(Tail.Value)

    if not Start or not Goal then
        error(`{Track.Property} cannot be solved by a physics keyframe, use a TweenInfo instead`, 0)
    end

    if Track.Position then
        for Index = 1, math.min(#Track.Position, #Goal) do
            Track.Goal[Index] = Goal[Index]
        end
    else
        Track.Position = Start
        Track.Velocity = table.create(#Start, 0)
        Track.Goal = Goal
        Track.Make = Interpolate.Maker(typeof(Track.From))
    end
end

const function Rewind(Self)
    Self.Elapsed = if Self.Length > 0 then Self.Elapsed % Self.Length else 0
    Self.Cursor = 1

    for _, Track in Self.Tracks do
        Track.Index = 0
        Track.From = nil
        Track.Blend = nil
        Track.Springy = false
        Track.Position = nil
        Track.Velocity = nil
        Track.Goal = nil
    end
end

const function Restage(Self)
    const Object = Self.Object
    const Span = math.max(Self.RestageTime, 1e-4)

    Self.Elapsed = 0
    Self.Cursor = 1
    Self.Restaging = true
    Self.Staged = 0

    for _, Track in Self.Tracks do
        const Stops = Track.Stops
        const Home = Stops[1].Value
        const Style = Stops[#Stops].Easing

        Track.Index = 0
        Track.From = nil
        Track.Home = Home
        Track.Curve = Style

        Enter(Track, Object, { Time = 0, Value = Object[Track.Property] }, { Time = Span, Value = Home, Easing = Style })
    end
end

const function Timeline(Self, DeltaTime: number): boolean
    const Tick = DeltaTime * Self.Speed

    if Self.Restaging then
        Self.Staged += Tick

        const Span = Self.RestageTime
        const Raw = if Span > 0 then math.min(Self.Staged / Span, 1) else 1
        const Home = Self.Object

        local Ready = Raw >= 1

        for _, Track in Self.Tracks do
            if Track.Springy then
                if not Solve(Track, Home, DeltaTime) then
                    Ready = false
                end
            else
                const Shape = Track.Curve
                const Curve = if Shape and typeof(Shape) == "TweenInfo" then Interpolate.Curve(Shape, Raw) else Raw

                Home[Track.Property] = Interpolate.Value(Track.From, Track.Home, Curve)
            end
        end

        if Ready then
            Self.Restaging = false

            for _, Track in Self.Tracks do
                Track.From = nil
                Track.Home = nil
                Track.Curve = nil
            end
        end

        return false
    end

    Self.Elapsed += Tick

    if Self.Looped and Self.Length > 0 and Self.Elapsed >= Self.Length then
        if Self.SmoothLoop and Self.RestageTime > 0 then
            Restage(Self)

            return false
        end

        Rewind(Self)
    end

    const Now = Self.Elapsed
    const Object = Self.Object
    const Marks = Self.Marks
    const Total = #Marks

    const Fresh = not Self.Primed

    Self.Primed = true

    if not Fresh then
        local Cursor = Self.Cursor

        while Cursor <= Total and Marks[Cursor].Time <= Now do
            const Mark = Marks[Cursor]

            Cursor += 1
            Self.Cursor = Cursor
            Self.Fire(Mark.Name, Mark.Args)
        end

        Self.Cursor = Cursor
    end

    local Resting = Now >= Self.Length

    for _, Track in Self.Tracks do
        const Stops = Track.Stops
        const Count = #Stops
        local Index = Track.Index

        while Index < Count and Now >= Stops[Index + 1].Time do
            Index += 1
            Track.Index = Index
            Track.From = nil
        end

        if Index == 0 then
            Resting = false

            continue
        end

        if Index >= Count then
            if Track.Springy then
                if not Solve(Track, Object, DeltaTime) then
                    Resting = false
                end
            elseif Track.From == nil then
                const Last = Stops[Count].Value

                Object[Track.Property] = Last
                Track.From = Last
            end

            continue
        end

        Resting = false

        const Head = Stops[Index]
        const Tail = Stops[Index + 1]

        if Track.From == nil then
            Enter(Track, Object, Head, Tail)
        end

        if Track.Springy then
            Solve(Track, Object, DeltaTime)

            continue
        end

        const Span = Tail.Time - Head.Time
        const Alpha = if Span > 0 then (Now - Head.Time) / Span else 1
        const Curve = if Tail.Easing then Interpolate.Curve(Tail.Easing, Alpha) else math.clamp(Alpha, 0, 1)

        Object[Track.Property] = Interpolate.Value(Track.From, Tail.Value, Curve)
    end

    return Resting and not Fresh
end

const function Flip(Self, DeltaTime: number): boolean
    Self.Elapsed += DeltaTime * Self.Speed

    const Count = Self.Count
    const Span = 1 / Self.Rate

    local Index = math.floor(Self.Elapsed / Span) + 1
    local Done = false

    if Index > Count then
        if Self.Looped then
            Index = (Index - 1) % Count + 1
        else
            Index = Count
            Done = true
        end
    end

    if Index ~= Self.Index then
        Self.Index = Index
        Self.Show(Index)
    end

    return Done
end

const function Tween(Self, DeltaTime: number): boolean
    Self.Elapsed += DeltaTime

    const Info = Self.Info
    const Alpha, Ended = Interpolate.Cycle(Info, Self.Elapsed)

    Self.Apply(Alpha, DeltaTime)

    if not Ended then
        return false
    end

    const Repeats = Info.RepeatCount

    if Repeats >= 0 and Self.Cycle >= Repeats then
        return true
    end

    Self.Cycle += 1
    Self.Elapsed = 0

    return false
end

const function Physics(Self, DeltaTime: number): boolean
    const Carry, Push, Pull, Keep = Coefficients(Self.Omega, Self.Damping, DeltaTime)
    local Settled = true

    for _, Channel in Self.Channels do
        const Position = Channel.Position
        const Velocity = Channel.Velocity
        const Goal = Channel.Goal
        const Count = #Position

        for Index = 1, Count do
            const Offset = Position[Index] - Goal[Index]
            const Speed = Velocity[Index]

            Position[Index] = Goal[Index] + Carry * Offset + Push * Speed
            Velocity[Index] = Pull * Offset + Keep * Speed
        end

        local Done = true

        for Index = 1, Count do
            const Scale = math.max(1, math.abs(Goal[Index]))

            if
                math.abs(Position[Index] - Goal[Index]) > Epsilon * Scale
                or math.abs(Velocity[Index]) > Epsilon * Scale
            then
                Done = false
                break
            end
        end

        if Done then
            for Index = 1, Count do
                Position[Index] = Goal[Index]
                Velocity[Index] = 0
            end
        else
            Settled = false
        end

        Channel.Write(Channel.Make(Position))
    end

    return Settled
end

function Link.new(Owner, Update)
    return setmetatable({
        Runtime = Owner,
        Update = Update,
        Elapsed = 0,
        Cycle = 0,
        Finished = false,
        Claims = {},
        Threads = {},
        Watchers = {},
    }, Link)
end

function Link:Seek(Time: number)
    if self.Finished or not self.Tracks then
        return
    end

    const Now = math.clamp(Time, 0, self.Length)
    const Marks = self.Marks
    const Total = #Marks

    self.Elapsed = Now
    self.Restaging = false
    self.Staged = 0

    local Cursor = 1

    while Cursor <= Total and Marks[Cursor].Time <= Now do
        Cursor += 1
    end

    self.Cursor = Cursor

    for _, Track in self.Tracks do
        Track.Index = 0
        Track.From = nil
        Track.Home = nil
        Track.Curve = nil
        Track.Springy = false
        Track.Position = nil
        Track.Velocity = nil
        Track.Goal = nil
    end

    Timeline(self, 0)
end

function Link:Step(DeltaTime: number)
    if self.Finished then
        return
    end

    if self.Update(self, DeltaTime) then
        self:Cancel()
    end
end

function Link:Cancel()
    if self.Finished then
        return
    end

    self.Finished = true

    const Owner = self.Runtime

    for _, Watcher in self.Watchers do
        Watcher:Disconnect()
    end

    table.clear(self.Watchers)

    for _, Claim in self.Claims do
        Owner:Unclaim(Claim[1], Claim[2], self)
    end

    Owner:Remove(self)

    local Threads = self.Threads

    self.Apply = nil
    self.Tracks = nil
    self.Marks = nil
    self.Fire = nil
    self.Show = nil
    self.Object = nil
    self.Claims = nil
    self.Threads = nil
    self.Runtime = nil
    self.Info = nil
    self.Channels = nil
    self.Watchers = nil

    for _, Thread in Threads do
        task.spawn(Thread)
    end
end

function Link:Await()
    if self.Finished then
        return
    end

    table.insert(self.Threads, coroutine.running())
    coroutine.yield()
end

function Runtime.new()
    return setmetatable({
        Links = {},
        Buffer = {},
        Claims = setmetatable({}, { __mode = "k" }),
        Connection = nil,
    }, Runtime)
end

function Runtime:Claim(Owner: any, Name: string, Target)
    local Slots = self.Claims[Owner]

    if not Slots then
        Slots = {}
        self.Claims[Owner] = Slots
    end

    const Existing = Slots[Name]

    if Existing and Existing ~= Target then
        Existing:Cancel()
        Slots = self.Claims[Owner]

        if not Slots then
            Slots = {}
            self.Claims[Owner] = Slots
        end
    end

    Slots[Name] = Target
    table.insert(Target.Claims, { Owner, Name })
end

function Runtime:Unclaim(Owner: any, Name: string, Target)
    local Slots = self.Claims[Owner]

    if not Slots then
        return
    end

    if Slots[Name] == Target then
        Slots[Name] = nil
    end

    if next(Slots) == nil then
        self.Claims[Owner] = nil
    end
end

function Runtime:CancelOwner(Owner: any)
    local Slots = self.Claims[Owner]

    if not Slots then
        return
    end

    const Doomed = {}

    for _, Target in Slots do
        table.insert(Doomed, Target)
    end

    for _, Target in Doomed do
        Target:Cancel()
    end
end

function Runtime:Add(Target)
    table.insert(self.Links, Target)
    self:Start()
end

function Runtime:Remove(Target)
    const Index = table.find(self.Links, Target)

    if Index then
        table.remove(self.Links, Index)
    end

    if #self.Links == 0 then
        self:Stop()
    end
end

function Runtime:Start()
    if self.Connection then
        return
    end

    const Signal = if RunService:IsClient() then RunService.RenderStepped else RunService.Heartbeat

    self.Connection = Signal:Connect(function(DeltaTime: number)
        self:Step(DeltaTime)
    end)
end

function Runtime:Stop()
    if not self.Connection then
        return
    end

    self.Connection:Disconnect()
    self.Connection = nil
end

function Runtime:Step(DeltaTime: number)
    const Links = self.Links
    const Count = #Links

    if Count == 0 then
        return
    end

    const Buffer = self.Buffer

    table.move(Links, 1, Count, 1, Buffer)

    for Index = 1, Count do
        const Target = Buffer[Index]

        Buffer[Index] = nil

        if not Target.Finished then
            Target:Step(DeltaTime)
        end
    end
end

function Runtime:Release()
    for _, Target in table.clone(self.Links) do
        Target:Cancel()
    end

    table.clear(self.Links)
    self:Stop()
end

const function Guard(Target, Owners)
    const Seen = {}

    for _, Owner in Owners do
        if typeof(Owner) == "Instance" and not Seen[Owner] then
            Seen[Owner] = true

            table.insert(
                Target.Watchers,
                Owner.Destroying:Connect(function()
                    Target:Cancel()
                end)
            )
        end
    end
end

function Runtime:Create(Info: TweenInfo, Apply: (number, number) -> (), Slots: { { any } })
    const Target = Link.new(self, Tween)

    Target.Info = Info
    Target.Apply = Apply

    const Owners = {}

    for _, Slot in Slots do
        self:Claim(Slot[1], Slot[2], Target)
        table.insert(Owners, Slot[1])
    end

    Guard(Target, Owners)

    Target:Step(0)

    if not Target.Finished then
        self:Add(Target)
    end

    return Target
end

function Runtime:Velocity(Owner: any, Name: string): { number }?
    local Slots = self.Claims[Owner]

    if not Slots then
        return nil
    end

    const Existing = Slots[Name]

    if not Existing or not Existing.Channels then
        return nil
    end

    for _, Channel in Existing.Channels do
        if Channel.Owner == Owner and Channel.Name == Name then
            return Channel.Velocity
        end
    end

    return nil
end

function Runtime:Flip(Object: Instance, Count: number, Rate: number, Show: (number) -> ())
    const Target = Link.new(self, Flip)

    Target.Object = Object
    Target.Count = Count
    Target.Rate = Rate
    Target.Show = Show
    Target.Index = 0
    Target.Speed = 1
    Target.Looped = false

    self:Claim(Object, "ImageRectOffset", Target)
    Guard(Target, { Object })

    Target:Step(0)

    if not Target.Finished then
        self:Add(Target)
    end

    return Target
end

function Runtime:Play(Object: Instance, Tracks: { any }, Marks: { any }, Length: number, Fire: (string, { any }) -> ())
    const Target = Link.new(self, Timeline)

    Target.Object = Object
    Target.Tracks = Tracks
    Target.Marks = Marks
    Target.Length = Length
    Target.Fire = Fire
    Target.Cursor = 1
    Target.Speed = 1
    Target.Looped = false
    Target.SmoothLoop = false
    Target.RestageTime = 0.25
    Target.Restaging = false
    Target.Staged = 0
    Target.Primed = false

    for _, Track in Tracks do
        self:Claim(Object, Track.Property, Target)
    end

    Guard(Target, { Object })

    Target:Step(0)

    if not Target.Finished then
        self:Add(Target)
    end

    return Target
end

function Runtime:Solve(Period: number, Damping: number, Channels: { any })
    const Target = Link.new(self, Physics)

    Target.Omega = 2 * math.pi / math.max(Period, 1e-4)
    Target.Damping = math.max(Damping, 0)
    Target.Channels = Channels

    for _, Channel in Channels do
        const Carried = self:Velocity(Channel.Owner, Channel.Name)

        if Carried then
            for Index = 1, math.min(#Carried, #Channel.Velocity) do
                Channel.Velocity[Index] = Carried[Index]
            end
        end
    end

    const Owners = {}

    for _, Channel in Channels do
        self:Claim(Channel.Owner, Channel.Name, Target)
        table.insert(Owners, Channel.Owner)
    end

    Guard(Target, Owners)

    Target:Step(0)

    if not Target.Finished then
        self:Add(Target)
    end

    return Target
end

return Runtime
