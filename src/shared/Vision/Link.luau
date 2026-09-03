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

        Channel.Write(Interpolate.Rebuild(Channel.Kind, Position))
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
    for _, Target in table.clone(self.Links) do
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
