local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Vision = require(ReplicatedStorage.Shared.Vision)

local Vendored = ReplicatedStorage.Shared:FindFirstChild("vide")

if not Vendored then
    return function()
        warn("[compare] vide is not present, skipping the comparison")
        warn("[compare] vide is gitignored, clone it into src/shared/vide to run this")
    end
end

local Vide = require(Vendored)

Vide.strict = false

local event = Vision.event
local cleanup = Vision.cleanup
local mount = Vision.mount

local create = Vide.create
local source = Vide.source

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local Rows = 100
local Writes = 100
local Rounds = 3

local Dark = Color3.fromRGB(22, 23, 30)
local Line = Color3.fromRGB(150, 156, 185)
local Body = Color3.fromRGB(198, 204, 226)
local Accent = Color3.fromRGB(88, 101, 242)

local Motion = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local Report = {}

local function Record(Label: string, Left: any, Middle: any, Right: any)
    table.insert(Report, {
        Label = Label,
        Left = tostring(Left),
        Middle = tostring(Middle),
        Right = tostring(Right),
    })
end

local function Clock(Callback: () -> ()): number
    local Start = os.clock()

    Callback()

    return (os.clock() - Start) * 1000
end

local function Ms(Value: number): string
    return string.format("%.2f ms", Value)
end

local function Count(Object: Instance?): number
    return if Object then #Object:GetDescendants() else 0
end

local function Row(Index: number, Value: any): string
    return `row {Index} :: {Value}`
end

local function CompareStaging()
    local Scope = Vision.Scope()
    local Host = Instance.new("Folder")
    Host.Parent = PlayerGui

    local VisionFires = 0

    local Interface = Scope:Capture({
        ClassName = "Frame",
        Name = "Staged",

        mount(Host),

        event("Value", 0, function(self, Value)
            VisionFires += 1
            self.Name = `Staged{Value}`
        end),
    })

    local VisionBuilt = Count(Host)
    local VisionIdle = VisionFires

    for Index = 1, 5 do
        Interface.Value(Index)
    end

    local VisionWrites = VisionFires - VisionIdle

    Interface:Mount()

    local VisionRevealed = Count(Host) - VisionBuilt
    local VisionTotal = VisionFires

    local VideFires = 0
    local Value = source(0)
    local Holder = Instance.new("Folder")
    Holder.Parent = PlayerGui

    local Destroy, Object = Vide.root(function()
        return create("Frame")({
            Name = function()
                VideFires += 1
                return `Staged{Value()}`
            end,
        })
    end)

    local VideBuilt = if Object then 1 + Count(Object) else 0
    local VideIdle = VideFires

    for Index = 1, 5 do
        Value(Index)
    end

    local VideWrites = VideFires - VideIdle

    Object.Parent = Holder

    local Plain = Instance.new("Frame")
    local RawWrites = 0

    for Index = 1, 5 do
        Plain.Name = `Staged{Index}`
        RawWrites += 1
    end

    Record("instances before reveal", VisionBuilt, VideBuilt, 1)
    Record("updates at declaration", VisionIdle, VideIdle, 0)
    Record("updates for 5 writes", VisionWrites, VideWrites, RawWrites)
    Record("instances at reveal", VisionRevealed, 0, 0)
    Record("updates total", VisionTotal, VideFires, RawWrites)

    Destroy()
    Scope:Release()
    Plain:Destroy()
    Host:Destroy()
    Holder:Destroy()
end

local function VisionDeclaration(Parent: Instance)
    local Declaration = {
        ClassName = "Frame",
        Name = "Tree",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,

        mount(Parent),
    }

    for Index = 1, Rows do
        table.insert(Declaration, {
            ClassName = "TextLabel",
            Name = `Row{Index}`,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Font = Enum.Font.Code,
            TextSize = 11,
            TextColor3 = Line,
            TextXAlignment = Enum.TextXAlignment.Left,

            event("Tick", 0, function(self, Value)
                self.Text = Row(Index, Value)
            end),
        })
    end

    return Declaration
end

local function VideComponent(Tick: () -> number)
    local Children = {
        Name = "Tree",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }

    for Index = 1, Rows do
        table.insert(
            Children,
            create("TextLabel")({
                Name = `Row{Index}`,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Font = Enum.Font.Code,
                TextSize = 11,
                TextColor3 = Line,
                TextXAlignment = Enum.TextXAlignment.Left,

                Text = function()
                    return Row(Index, Tick())
                end,
            })
        )
    end

    return create("Frame")(Children)
end

local function RawTree(Parent: Instance)
    local Root = Instance.new("Frame")
    Root.Name = "Tree"
    Root.Size = UDim2.fromScale(1, 1)
    Root.BackgroundTransparency = 1

    local Labels = table.create(Rows)

    for Index = 1, Rows do
        local Text = Instance.new("TextLabel")
        Text.Name = `Row{Index}`
        Text.BackgroundTransparency = 1
        Text.Size = UDim2.new(1, 0, 0, 14)
        Text.Font = Enum.Font.Code
        Text.TextSize = 11
        Text.TextColor3 = Line
        Text.TextXAlignment = Enum.TextXAlignment.Left
        Text.Text = Row(Index, 0)
        Text.Parent = Root

        Labels[Index] = Text
    end

    Root.Parent = Parent

    return Labels
end

local function CompareThroughput()
    local Scope = Vision.Scope()

    local VisionHost = Instance.new("Folder")
    local VideHost = Instance.new("Folder")
    local RawHost = Instance.new("Folder")

    VisionHost.Parent = PlayerGui
    VideHost.Parent = PlayerGui
    RawHost.Parent = PlayerGui

    local Declaration
    local Declare = Clock(function()
        Declaration = VisionDeclaration(VisionHost)
    end)

    local Interface
    local Capture = Clock(function()
        Interface = Scope:Capture(Declaration)
    end)

    local Reveal = Clock(function()
        Interface:Mount()
    end)

    task.wait()

    local Tick = source(0)
    local Destroy
    local Build = Clock(function()
        Destroy = Vide.mount(function()
            return VideComponent(Tick)
        end, VideHost)
    end)

    task.wait()

    local Labels
    local Raw = Clock(function()
        Labels = RawTree(RawHost)
    end)

    Record(`declare {Rows} rows`, Ms(Declare), "n/a", "n/a")
    Record(`capture {Rows} rows`, Ms(Capture), "n/a", "n/a")
    Record(`instantiate {Rows} rows`, Ms(Reveal), Ms(Build), Ms(Raw))
    Record("total to on screen", Ms(Declare + Capture + Reveal), Ms(Build), Ms(Raw))
    Record("descendants built", Count(VisionHost), Count(VideHost), Count(RawHost))

    local VisionWrite = math.huge
    local VideWrite = math.huge
    local RawWrite = math.huge

    local function TimeVision()
        VisionWrite = math.min(VisionWrite, Clock(function()
            for Index = 1, Writes do
                Interface.Tick(Index)
            end
        end))
    end

    local function TimeVide()
        VideWrite = math.min(VideWrite, Clock(function()
            for Index = 1, Writes do
                Tick(Index)
            end
        end))
    end

    local function TimeRaw()
        RawWrite = math.min(RawWrite, Clock(function()
            for Index = 1, Writes do
                for Line = 1, Rows do
                    Labels[Line].Text = Row(Line, Index)
                end
            end
        end))
    end

    local Order = {
        { TimeVision, TimeVide, TimeRaw },
        { TimeVide, TimeRaw, TimeVision },
        { TimeRaw, TimeVision, TimeVide },
    }

    for Round = 1, Rounds do
        for _, Measure in Order[(Round - 1) % 3 + 1] do
            task.wait()
            Measure()
        end
    end

    task.wait()

    Record(`{Writes} writes x {Rows} rows`, Ms(VisionWrite), Ms(VideWrite), Ms(RawWrite))
    Record("per write", Ms(VisionWrite / Writes), Ms(VideWrite / Writes), Ms(RawWrite / Writes))
    Record("cost over raw", Ms(VisionWrite - RawWrite), Ms(VideWrite - RawWrite), "baseline")

    local VisionDown = Clock(function()
        Scope:Release()
    end)

    task.wait()

    local VideDown = Clock(function()
        Destroy()
    end)

    task.wait()

    local RawDown = Clock(function()
        RawHost:ClearAllChildren()
    end)

    Record("teardown", Ms(VisionDown), Ms(VideDown), Ms(RawDown))
    Record("descendants left", Count(VisionHost), Count(VideHost), Count(RawHost))

    VisionHost:Destroy()
    VideHost:Destroy()
    RawHost:Destroy()
end

local function Column(Title: string, Offset: number, Build: (Instance) -> ())
    local Frame = Instance.new("Frame")
    Frame.Name = Title
    Frame.Position = UDim2.fromOffset(Offset, 0)
    Frame.Size = UDim2.new(0, 290, 1, -46)
    Frame.BackgroundColor3 = Dark
    Frame.BorderSizePixel = 0

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(58, 62, 84)
    Stroke.Transparency = 0.4
    Stroke.Parent = Frame

    local Header = Instance.new("TextLabel")
    Header.Name = "Header"
    Header.BackgroundTransparency = 1
    Header.Position = UDim2.fromOffset(18, 14)
    Header.Size = UDim2.new(1, -36, 0, 24)
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 18
    Header.TextColor3 = Accent
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.Text = Title
    Header.Parent = Frame

    local Content = Instance.new("Frame")
    Content.Name = "Body"
    Content.BackgroundTransparency = 1
    Content.Position = UDim2.fromOffset(18, 48)
    Content.Size = UDim2.new(1, -36, 1, -66)
    Content.Parent = Frame

    Build(Content)

    return Frame
end

local function Notes(Parent: Instance, Lines: { string })
    local Text = Instance.new("TextLabel")
    Text.Name = "Notes"
    Text.BackgroundTransparency = 1
    Text.Position = UDim2.fromOffset(0, 62)
    Text.Size = UDim2.new(1, 0, 1, -62)
    Text.Font = Enum.Font.Code
    Text.TextSize = 13
    Text.LineHeight = 1.55
    Text.TextColor3 = Line
    Text.TextXAlignment = Enum.TextXAlignment.Left
    Text.TextYAlignment = Enum.TextYAlignment.Top
    Text.TextWrapped = true
    Text.Text = table.concat(Lines, "\n")
    Text.Parent = Parent

    return Text
end

local function CompareLive()
    local Gui = Instance.new("ScreenGui")
    Gui.Name = "VisionVsVide"
    Gui.ResetOnSpawn = false
    Gui.IgnoreGuiInset = false

    local Root = Instance.new("Frame")
    Root.Name = "Root"
    Root.AnchorPoint = Vector2.new(0.5, 0.5)
    Root.Position = UDim2.fromScale(0.5, 0.5)
    Root.Size = UDim2.fromOffset(930, 400)
    Root.BackgroundTransparency = 1

    local Scope = Vision.Scope()
    local Interface
    local Goal = source(0.2)
    local RawBar
    local RawReadout

    local Left = Column("Vision", 0, function(Content)
        Interface = Scope:Capture({
            ClassName = "Frame",
            Name = "Panel",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,

            mount(Content),

            {
                ClassName = "TextLabel",
                Name = "Readout",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Font = Enum.Font.Code,
                TextSize = 15,
                TextColor3 = Body,
                TextXAlignment = Enum.TextXAlignment.Left,

                event("Fill", 0.2, function(self, Value)
                    self.Text = string.format("fill %.3f", Value)
                end),
            },

            {
                ClassName = "Frame",
                Name = "Track",
                Position = UDim2.fromOffset(0, 32),
                Size = UDim2.new(1, 0, 0, 14),
                BackgroundColor3 = Color3.fromRGB(38, 40, 52),
                BorderSizePixel = 0,

                {
                    ClassName = "Frame",
                    Name = "Bar",
                    Size = UDim2.fromScale(0.2, 1),
                    BackgroundColor3 = Accent,
                    BorderSizePixel = 0,

                    event("Fill", 0.2, function(self, Value)
                        self.Size = UDim2.fromScale(Value, 1)
                    end),
                },
            },

            {
                ClassName = "TextLabel",
                Name = "Notes",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 62),
                Size = UDim2.new(1, 0, 1, -62),
                Font = Enum.Font.Code,
                TextSize = 13,
                LineHeight = 1.55,
                TextColor3 = Line,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                Text = table.concat({
                    "nothing exists until Mount()",
                    "writes coalesce while staged",
                    "one value drives both labels",
                    "SpringValue drives the value",
                    "Back Out, peaks at 1.100",
                    "Linker cancels and Awaits",
                }, "\n"),

                cleanup(function(self)
                    print("[compare] vision notes released:", self.Name)
                end),
            },
        })

        Interface:Mount()
    end)

    local Destroy

    local Middle = Column("Vide", 320, function(Content)
        Destroy = Vide.mount(function()
            local Fill = Vide.spring(Goal, 0.6, 0.59)

            return create("Frame")({
                Name = "Panel",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

                create("TextLabel")({
                    Name = "Readout",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = Enum.Font.Code,
                    TextSize = 15,
                    TextColor3 = Body,
                    TextXAlignment = Enum.TextXAlignment.Left,

                    Text = function()
                        return string.format("fill %.3f", Fill())
                    end,
                }),

                create("Frame")({
                    Name = "Track",
                    Position = UDim2.fromOffset(0, 32),
                    Size = UDim2.new(1, 0, 0, 14),
                    BackgroundColor3 = Color3.fromRGB(38, 40, 52),
                    BorderSizePixel = 0,

                    create("Frame")({
                        Name = "Bar",
                        BackgroundColor3 = Accent,
                        BorderSizePixel = 0,

                        Size = function()
                            return UDim2.fromScale(Fill(), 1)
                        end,
                    }),
                }),

                create("TextLabel")({
                    Name = "Notes",
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 62),
                    Size = UDim2.new(1, 0, 1, -62),
                    Font = Enum.Font.Code,
                    TextSize = 13,
                    LineHeight = 1.55,
                    TextColor3 = Line,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    Text = table.concat({
                        "instances exist from mount()",
                        "every write reruns effects",
                        "one source read by both",
                        "spring wraps the source",
                        "damping 0.59, peaks at 1.098",
                        "carries velocity on retarget",
                    }, "\n"),
                }),
            })
        end, Content)
    end)

    local Right = Column("No module", 640, function(Content)
        RawReadout = Instance.new("TextLabel")
        RawReadout.Name = "Readout"
        RawReadout.BackgroundTransparency = 1
        RawReadout.Size = UDim2.new(1, 0, 0, 20)
        RawReadout.Font = Enum.Font.Code
        RawReadout.TextSize = 15
        RawReadout.TextColor3 = Body
        RawReadout.TextXAlignment = Enum.TextXAlignment.Left
        RawReadout.Text = "fill 0.200"
        RawReadout.Parent = Content

        local Rail = Instance.new("Frame")
        Rail.Name = "Track"
        Rail.Position = UDim2.fromOffset(0, 32)
        Rail.Size = UDim2.new(1, 0, 0, 14)
        Rail.BackgroundColor3 = Color3.fromRGB(38, 40, 52)
        Rail.BorderSizePixel = 0
        Rail.Parent = Content

        RawBar = Instance.new("Frame")
        RawBar.Name = "Bar"
        RawBar.Size = UDim2.fromScale(0.2, 1)
        RawBar.BackgroundColor3 = Accent
        RawBar.BorderSizePixel = 0
        RawBar.Parent = Rail

        Notes(Content, {
            "instances exist from Instance.new",
            "you assign every property",
            "readout and bar kept in sync by hand",
            "TweenService:Create per target",
            "Back Out, peaks at 1.100",
            "Tween has Play, Pause, Cancel",
        })
    end)

    Left.Parent = Root
    Middle.Parent = Root
    Right.Parent = Root

    local Toggle = Instance.new("TextButton")
    Toggle.Name = "Toggle"
    Toggle.Position = UDim2.new(0, 0, 1, -34)
    Toggle.Size = UDim2.new(1, 0, 0, 34)
    Toggle.BackgroundColor3 = Accent
    Toggle.BorderSizePixel = 0
    Toggle.AutoButtonColor = false
    Toggle.Font = Enum.Font.GothamMedium
    Toggle.TextSize = 15
    Toggle.TextColor3 = Color3.new(1, 1, 1)
    Toggle.Text = "Animate all three"
    Toggle.Parent = Root

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = Toggle

    Root.Parent = Gui

    local Flip = false
    local RawTween
    local Mirror

    Toggle.Activated:Connect(function()
        Flip = not Flip

        local Target = if Flip then 0.8 else 0.2

        Scope:SpringValue(Motion, Interface, "Fill", Target)

        Goal(Target)

        if RawTween then
            RawTween:Cancel()
        end

        if Mirror then
            task.cancel(Mirror)
        end

        RawTween = TweenService:Create(RawBar, Motion, { Size = UDim2.fromScale(Target, 1) })
        RawTween:Play()

        Mirror = task.spawn(function()
            while RawTween.PlaybackState == Enum.PlaybackState.Playing do
                RawReadout.Text = string.format("fill %.3f", RawBar.Size.X.Scale)
                task.wait()
            end

            RawReadout.Text = string.format("fill %.3f", RawBar.Size.X.Scale)
        end)
    end)

    Gui.Parent = PlayerGui

    return function()
        if Mirror then
            task.cancel(Mirror)
        end

        Scope:Release()
        Destroy()
        Gui:Destroy()
    end
end

return function()
    CompareStaging()

    task.wait()

    CompareThroughput()

    local Width = 0

    for _, Entry in Report do
        Width = math.max(Width, #Entry.Label)
    end

    local Format = `%-{Width}s  %-14s  %-14s  %s`

    print("")
    print(`vide strict = {Vide.strict}, best of {Rounds} rounds, rotating order`)
    print("")
    print(string.format(Format, "measure", "Vision", "Vide", "No module"))
    print(string.rep("-", Width + 48))

    for _, Entry in Report do
        print(string.format(Format, Entry.Label, Entry.Left, Entry.Middle, Entry.Right))
    end

    print("")

    return CompareLive()
end
