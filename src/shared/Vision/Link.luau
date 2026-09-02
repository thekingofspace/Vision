local RunService = game:GetService("RunService")

local Interpolate = require(script.Parent.Interpolate)

local Link = {}
Link.__index = Link

local Runtime = {}
Runtime.__index = Runtime

function Link.new(Owner, Info: TweenInfo, Apply: (number, number) -> ())
    return setmetatable({
        Runtime = Owner,
        Info = Info,
        Apply = Apply,
        Elapsed = 0,
        Cycle = 0,
        Finished = false,
        Claims = {},
        Threads = {},
    }, Link)
end

function Link:Step(DeltaTime: number)
    if self.Finished then
        return
    end

    self.Elapsed += DeltaTime

    local Info = self.Info
    local Alpha, Ended = Interpolate.Cycle(Info, self.Elapsed)

    self.Apply(Alpha, DeltaTime)

    if not Ended then
        return
    end

    local Repeats = Info.RepeatCount

    if Repeats >= 0 and self.Cycle >= Repeats then
        self:Cancel()

        return
    end

    self.Cycle += 1
    self.Elapsed = 0
end

function Link:Cancel()
    if self.Finished then
        return
    end

    self.Finished = true

    local Owner = self.Runtime

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

    local Existing = Slots[Name]

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

    local Doomed = {}

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
    local Index = table.find(self.Links, Target)

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

    local Signal = if RunService:IsClient() then RunService.RenderStepped else RunService.Heartbeat

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

function Runtime:Create(Info: TweenInfo, Apply: (number, number) -> (), Slots: { { any } })
    local Target = Link.new(self, Info, Apply)

    for _, Slot in Slots do
        self:Claim(Slot[1], Slot[2], Target)
    end

    Target:Step(0)

    if not Target.Finished then
        self:Add(Target)
    end

    return Target
end

return Runtime
