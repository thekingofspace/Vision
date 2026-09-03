local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Vision = require(ReplicatedStorage.Shared.Vision)

local event = Vision.event
local merge = Vision.merge
local derive = Vision.derive
local ready = Vision.ready
local cleanup = Vision.cleanup
local drawcall = Vision.drawcall
local style = Vision.style
local mount = Vision.mount

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local Themes = {
    Dark = {
        Back = Color3.fromRGB(13, 14, 19),
        Card = Color3.fromRGB(26, 28, 38),
        Rail = Color3.fromRGB(44, 47, 62),
        Ink = Color3.fromRGB(232, 236, 248),
        Dim = Color3.fromRGB(136, 144, 170),
        Accent = Color3.fromRGB(122, 162, 255),
    },

    Light = {
        Back = Color3.fromRGB(238, 239, 245),
        Card = Color3.fromRGB(255, 255, 255),
        Rail = Color3.fromRGB(220, 223, 234),
        Ink = Color3.fromRGB(22, 24, 32),
        Dim = Color3.fromRGB(108, 114, 136),
        Accent = Color3.fromRGB(58, 98, 220),
    },
}

local Words = {
    "Cinder", "Harbor", "Lantern", "Meadow", "Quarry",
    "Ripple", "Summit", "Thicket", "Vellum", "Willow",
}

local Order = { "Title", "Values", "Motion", "Reactive", "Effects", "Gradient", "Stack", "List" }

local Digits = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5,
}

return function()
    local Scope = Vision.Scope()

    local Alive = true
    local Index = 1
    local Wearing = "Dark"
    local Toggled = false

    local Title, Values, Motion, Reactive, Effects, Colour, Stack, List, Row
    local Shelf, Handle
    local Rows, Made = {}, 0

    local Skin = Scope:LoadStyle({
        name = "Skin",

        Back = Themes.Dark.Back,
        Card = Themes.Dark.Card,
        Rail = Themes.Dark.Rail,
        Ink = Themes.Dark.Ink,
        Dim = Themes.Dark.Dim,
        Accent = Themes.Dark.Accent,
    })

    -- every page is this shell, so the styling and the mobile reflow live in one place
    local function Page(Name: string, Heading: string, Hint: string, Body: { any })
        local Layout = {
            ClassName = "ScreenGui",
            Name = `Vision{Name}`,
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 40,

            mount(PlayerGui),

            {
                ClassName = "Frame",
                Name = "Back",
                Size = UDim2.fromScale(1, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = style("Skin")["Back"],
            },

            {
                ClassName = "Frame",
                Name = "Card",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(560, 340),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                BackgroundColor3 = style("Skin")["Card"],

                { ClassName = "UICorner", CornerRadius = UDim.new(0, 18) },

                {
                    ClassName = "UIStroke",
                    Transparency = 0.55,
                    Color = style("Skin")["Rail"],
                },

                {
                    ClassName = "UIScale",
                    Scale = 1,

                    -- viewport hook: the whole card grows to fill whatever it is given,
                    -- so the layout below is written once at 560 x 340 and never again
                    drawcall(function(self, Viewport)
                        self.Scale = math.clamp(math.min(Viewport.X / 600, Viewport.Y / 420), 0.45, 2.2)
                    end),
                },

                {
                    ClassName = "TextLabel",
                    Name = "Heading",
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(28, 22),
                    Size = UDim2.new(1, -200, 0, 26),
                    Font = Enum.Font.GothamBold,
                    TextSize = 20,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = Heading,
                    TextColor3 = style("Skin")["Ink"],
                },

                {
                    ClassName = "TextLabel",
                    Name = "Hint",
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 28, 1, -14),
                    Size = UDim2.new(1, -56, 0, 15),
                    Font = Enum.Font.Code,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = Hint,
                    TextColor3 = style("Skin")["Dim"],
                },
            },
        }

        for _, Entry in Body do
            table.insert(Layout, Entry)
        end

        return Layout
    end

    -- buttons mount into the card by name and carry their own signals
    local function Button(Name: string, Text: string, Spot: UDim2, Wide: number, Press: (Instance) -> ())
        return {
            ClassName = "TextButton",
            Name = Name,
            Position = Spot,
            Size = UDim2.fromOffset(Wide, 32),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            Text = Text,
            BackgroundColor3 = style("Skin")["Rail"],
            TextColor3 = style("Skin")["Ink"],

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 8) },

            Activated = function(self)
                Press(self)
            end,

            MouseEnter = function(self)
                Scope:PhysicsInstance(0.22, 0.4, self, { Size = UDim2.fromOffset(Wide + 8, 36) })
            end,

            MouseLeave = function(self)
                Scope:PhysicsInstance(0.28, 0.6, self, { Size = UDim2.fromOffset(Wide, 32) })
            end,
        }
    end

    ------------------------------------------------------------------ title

    Title = Scope:Capture(Page("Title", "Vision", "K  next screen", {
        {
            ClassName = "TextLabel",
            Name = "Mark",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.44),
            Size = UDim2.new(1, -56, 0, 78),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBlack,
            TextSize = 62,
            Text = "VISION",
            TextColor3 = style("Skin")["Ink"],

            mount("Card"),

            ready(function(self, later)
                self.Position = UDim2.fromScale(0.5, 0.34)
                Scope:PhysicsInstance(0.75, 0.5, self, { Position = UDim2.fromScale(0.5, 0.44) })

                later(function()
                    print("[vision] title asleep")
                end)
            end),
        },

        {
            ClassName = "TextLabel",
            Name = "Motto",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.6),
            Size = UDim2.new(1, -56, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),

            event("Motto", "", function(self, Value)
                self.Text = Value
            end),

            -- strings tween, so the motto types itself out
            ready(function()
                Scope:SpringEvent(TweenInfo.new(1.1), Title, { Motto = "Existence Begins With Perception." })
            end),
        },
    }))

    ----------------------------------------------------------------- values

    Values = Scope:Capture(Page("Values", "Values", "T  theme      K  next      state survives both", {
        {
            ClassName = "TextLabel",
            Name = "Readout",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, 58),
            Size = UDim2.fromOffset(220, 58),
            Font = Enum.Font.GothamBold,
            TextSize = 46,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = style("Skin")["Accent"],

            mount("Card"),

            event("Charge", 0.35, function(self, Value)
                self.Text = string.format("%.0f%%", Value * 100)
            end),
        },

        {
            ClassName = "TextLabel",
            Name = "Mirror",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -28, 0, 74),
            Size = UDim2.fromOffset(260, 18),
            Font = Enum.Font.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),

            -- merge reads a value declared somewhere else in the tree
            merge("Doubled", function(self, Value)
                self.Text = `derive Doubled = {string.format("%.2f", Value)}`
            end),
        },

        {
            ClassName = "Frame",
            Name = "Track",
            Position = UDim2.fromOffset(28, 126),
            Size = UDim2.new(1, -56, 0, 10),
            BorderSizePixel = 0,
            BackgroundColor3 = style("Skin")["Rail"],

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

            {
                ClassName = "Frame",
                Name = "Fill",
                Size = UDim2.fromScale(0.35, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = style("Skin")["Accent"],

                { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

                merge("Charge", function(self, Value)
                    self.Size = UDim2.fromScale(math.clamp(Value, 0, 1), 1)
                end),
            },
        },

        {
            ClassName = "TextLabel",
            Name = "Mood",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, 150),
            Size = UDim2.new(1, -56, 0, 18),
            Font = Enum.Font.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),

            attributes = { Mood = "calm" },
            tags = { "VisionShowcase" },

            AttributeChanged = {
                Mood = function(self)
                    self.Text = `attribute Mood = "{self:GetAttribute("Mood")}"      tag = VisionShowcase`
                end,
            },

            ready(function(self)
                self.Text = `attribute Mood = "{self:GetAttribute("Mood")}"      tag = VisionShowcase`
            end),
        },

        -- reading doubles Charge, writing halves straight back into it
        derive("Doubled", function(Mode, Read, Write, Value)
            if Mode == "set" then
                return Write("Charge", Value / 2)
            end

            return Read("Charge") * 2
        end),

        Button("Less", "-20%", UDim2.fromOffset(28, 194), 92, function()
            Scope:SpringEvent(
                TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                Values,
                { Charge = math.max(0, Values.Charge() - 0.2) }
            )
        end),

        Button("More", "+20%", UDim2.fromOffset(128, 194), 92, function()
            Scope:SpringEvent(
                TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                Values,
                { Charge = math.min(1, Values.Charge() + 0.2) }
            )
        end),

        Button("Bounce", "physics", UDim2.fromOffset(228, 194), 96, function()
            Scope:PhysicsEvent(0.55, 0.35, Values, { Charge = if Values.Charge() > 0.5 then 0.1 else 0.9 })
        end),

        Button("Write", "write derive", UDim2.fromOffset(332, 194), 118, function()
            Values.Doubled(1.6)
        end),

        Button("Flip", "flip attribute", UDim2.fromOffset(28, 238), 118, function(self)
            local Label = self.Parent:FindFirstChild("Mood")

            Label:SetAttribute("Mood", if Label:GetAttribute("Mood") == "calm" then "bright" else "calm")
        end),

        Button("Endless", "repeat forever", UDim2.fromOffset(154, 238), 128, function()
            Handle = Scope:SpringEvent(
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                Values,
                { Charge = 1 }
            )
        end),

        Button("Stop", "cancel", UDim2.fromOffset(290, 238), 92, function()
            if not Handle then
                return
            end

            Handle:Cancel()
            print("[vision] cancelled, Finished =", Handle.Finished)

            Handle = nil
        end),

        cleanup(function()
            print("[vision] values asleep, Charge kept at", Values.Charge())
        end),
    }))

    ----------------------------------------------------------------- motion

    -- the cube is captured on its own, so it can be cleaned up without the page
    local Block = Scope:Capture({
        ClassName = "Frame",
        Name = "Dot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.25, 0, 0, 120),
        Size = UDim2.fromOffset(62, 62),
        BorderSizePixel = 0,
        BackgroundColor3 = style("Skin")["Accent"],

        { ClassName = "UICorner", CornerRadius = UDim.new(0, 16) },

        cleanup(function()
            print("[vision] cube cleaned up")
        end),
    })

    -- mounting a cleaned vision builds it again from the same declaration
    local function Cube(): Instance
        local Body = Block:Open()
        Body.Parent = Motion:Open():FindFirstChild("Card")

        return Body
    end

    -- each entry is one animation call, reachable from its button or its number key
    local Acts = {
        {
            Name = "Tween",
            Text = "SpringInstance",
            Spot = UDim2.fromOffset(28, 206),
            Wide = 130,
            Note = "SpringInstance, a real TweenInfo with Back easing",

            Play = function(Dot)
                Scope:SpringInstance(
                    TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    Dot,
                    { Position = UDim2.new(if Dot.Position.X.Scale > 0.5 then 0.25 else 0.75, 0, 0, 120) }
                )
            end,
        },

        {
            Name = "Solve",
            Text = "PhysicsInstance",
            Spot = UDim2.fromOffset(166, 206),
            Wide = 136,
            Note = "PhysicsInstance, interrupt it and it keeps its velocity",

            Play = function(Dot)
                Scope:PhysicsInstance(0.5, 0.5, Dot, {
                    Position = UDim2.new(if Dot.Position.X.Scale > 0.5 then 0.25 else 0.75, 0, 0, 120),
                })
            end,
        },

        {
            Name = "Spin",
            Text = "SpringFunction",
            Spot = UDim2.fromOffset(310, 206),
            Wide = 132,
            Note = "SpringFunction, drive anything you can write to",

            Play = function(Dot)
                Scope:SpringFunction(
                    TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                    function(Value)
                        Dot.Rotation = Value
                    end,
                    Dot.Rotation,
                    Dot.Rotation + 180
                )
            end,
        },

        {
            Name = "Chain",
            Text = "Await chain",
            Spot = UDim2.fromOffset(28, 248),
            Wide = 118,
            Note = "Await, one link and then the next",

            Play = function(Dot)
                task.spawn(function()
                    Scope:PhysicsInstance(0.25, 0.45, Dot, { Size = UDim2.fromOffset(96, 96) }):Await()

                    if Alive then
                        Scope:PhysicsInstance(0.4, 0.5, Dot, { Size = UDim2.fromOffset(62, 62) })
                    end
                end)
            end,
        },

        {
            Name = "Fade",
            Text = "PhysicsFunction",
            Spot = UDim2.fromOffset(154, 248),
            Wide = 136,
            Note = "PhysicsFunction, a spring with no instance at all",

            Play = function(Dot)
                Scope:PhysicsFunction(0.35, 0.25, function(Value)
                    Dot.BackgroundTransparency = Value
                end, 0.75, 0)
            end,
        },
    }

    local function Run(Slot: number)
        local Act = Acts[Slot]

        if not Act or Order[Index] ~= "Motion" then
            return
        end

        Motion.Says(Act.Note)

        -- Cube rebuilds it first if the cleanup button took it away
        Act.Play(Cube())
    end

    local Stage = {
        {
            ClassName = "TextLabel",
            Name = "Note",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, 172),
            Size = UDim2.new(1, -56, 0, 18),
            Font = Enum.Font.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),

            event("Says", "pick one", function(self, Value)
                self.Text = Value
            end),
        },

        cleanup(function()
            print("[vision] motion asleep, note kept as", Motion.Says())
        end),
    }

    for Slot, Act in Acts do
        table.insert(Stage, Button(Act.Name, Act.Text, Act.Spot, Act.Wide, function()
            Run(Slot)
        end))
    end

    -- destroys the cube for real and leaves the page standing
    table.insert(Stage, Button("Sleep", "cleanup cube", UDim2.fromOffset(298, 248), 144, function()
        Motion.Says("cube cleaned up, press 1 to 5 to build it again")
        Block:Cleanup()
    end))

    Motion = Scope:Capture(Page("Motion", "Motion", "1-5  run a motion      K  next screen", Stage))

    --------------------------------------------------------------- reactive

    -- one readout, a small caption above it, bound to whichever value it is given
    local function Stat(Name: string, Title: string, X: number, Bind: any)
        return {
            {
                ClassName = "TextLabel",
                Name = Name .. "Cap",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(X, 58),
                Size = UDim2.fromOffset(172, 14),
                Font = Enum.Font.Code,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = Title,
                TextColor3 = style("Skin")["Dim"],

                mount("Card"),
            },

            {
                ClassName = "TextLabel",
                Name = Name,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(X, 74),
                Size = UDim2.fromOffset(172, 32),
                Font = Enum.Font.GothamBold,
                TextSize = 26,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = style("Skin")["Ink"],

                mount("Card"),

                Bind,
            },
        }
    end

    local function Cell(Name: string, Y: number, Tint: string)
        return {
            ClassName = "Frame",
            Name = Name,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(100, Y),
            Size = UDim2.fromOffset(26, 26),
            BorderSizePixel = 0,
            BackgroundColor3 = style("Skin")[Tint],

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 7) },
        }
    end

    local function Lane(Text: string, Y: number)
        return {
            ClassName = "TextLabel",
            Name = Text,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, Y - 8),
            Size = UDim2.fromOffset(64, 16),
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = Text,
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),
        }
    end

    local Far = false

    local Wires = {
        {
            ClassName = "Frame",
            Name = "Meter",
            Position = UDim2.fromOffset(28, 116),
            Size = UDim2.fromOffset(504, 8),
            BorderSizePixel = 0,
            BackgroundColor3 = style("Skin")["Rail"],

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

            {
                ClassName = "Frame",
                Name = "Level",
                Size = UDim2.fromScale(0.6, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = style("Skin")["Accent"],

                { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

                merge("Total", function(self, Value)
                    self.Size = UDim2.fromScale(math.clamp(Value / 1.5, 0, 1), 1)
                end),
            },
        },

        Lane("tween", 149),
        Cell("Tween", 149, "Dim"),

        Lane("physics", 185),
        Cell("Solid", 185, "Accent"),

        {
            ClassName = "TextLabel",
            Name = "Note",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, 206),
            Size = UDim2.fromOffset(504, 16),
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),

            event("Note", "one write moves the whole graph", function(self, Value)
                self.Text = Value
            end),
        },

        -- half is seed halved, total reads both, so one write settles all three
        derive("Half", function(Mode, Read, Write, Value)
            if Mode == "set" then
                return Write("Seed", Value * 2)
            end

            return Read("Seed") / 2
        end),

        derive("Total", function(Mode, Read)
            if Mode == "set" then
                return
            end

            return Read("Seed") + Read("Half")
        end),

        cleanup(function()
            print("[vision] reactive asleep, seed kept at", Reactive.Seed())
        end),
    }

    local Slots = {
        Stat("Seed", "seed  -  event", 28, event("Seed", 0.4, function(self, Value)
            self.Text = string.format("%.2f", Value)
        end)),

        Stat("Half", "half  -  derive of seed", 208, merge("Half", function(self, Value)
            self.Text = string.format("%.2f", Value)
        end)),

        Stat("Total", "total  -  derive of both", 388, merge("Total", function(self, Value)
            self.Text = string.format("%.2f", Value)
        end)),
    }

    for _, Pair in Slots do
        for _, Entry in Pair do
            table.insert(Wires, Entry)
        end
    end

    table.insert(Wires, Button("Less", "-0.2", UDim2.fromOffset(28, 240), 92, function()
        Reactive.Note("one write to seed, half and total both settle")
        Reactive.Seed(math.max(0, Reactive.Seed() - 0.2))
    end))

    table.insert(Wires, Button("More", "+0.2", UDim2.fromOffset(128, 240), 92, function()
        Reactive.Note("one write to seed, half and total both settle")
        Reactive.Seed(math.min(1, Reactive.Seed() + 0.2))
    end))

    table.insert(Wires, Button("Push", "write half", UDim2.fromOffset(228, 240), 112, function()
        -- writing a derive pushes back into its source, and the graph settles again
        Reactive.Note("wrote half, it pushed back into seed and total followed")
        Reactive.Half(0.5)
    end))

    table.insert(Wires, Button("Race", "retarget both", UDim2.fromOffset(348, 240), 122, function(self)
        Far = not Far

        local Goal = if Far then 476 else 100

        Reactive.Note("press again mid flight - physics keeps its speed, the tween restarts")

        Scope:SpringInstance(
            TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            self.Parent:FindFirstChild("Tween"),
            { Position = UDim2.fromOffset(Goal, 149) }
        )

        Scope:PhysicsInstance(0.55, 0.6, self.Parent:FindFirstChild("Solid"), {
            Position = UDim2.fromOffset(Goal, 185),
        })
    end))

    Reactive = Scope:Capture(Page("Reactive", "Reactive", "K  next screen", Wires))

    ---------------------------------------------------------------- effects

    -- a second sheet, so the switch can be repainted without touching the page
    local Switch = Scope:LoadStyle({
        name = "Switch",

        Track = Themes.Dark.Rail,
        Knob = Themes.Dark.Dim,
    })

    local Trick = {
        {
            ClassName = "Frame",
            Name = "Pill",
            Position = UDim2.fromOffset(28, 184),
            Size = UDim2.fromOffset(76, 30),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            BackgroundColor3 = style("Switch")["Track"],

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

            {
                ClassName = "Frame",
                Name = "Knob",
                Position = UDim2.fromOffset(6, 3),
                Size = UDim2.fromOffset(24, 24),
                BorderSizePixel = 0,
                BackgroundColor3 = style("Switch")["Knob"],

                { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },
            },
        },

        {
            ClassName = "TextLabel",
            Name = "Caption",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(118, 190),
            Size = UDim2.fromOffset(414, 18),
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "a switch on its own style sheet, knob and colour both sprung",
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),
        },

        {
            ClassName = "TextLabel",
            Name = "Note",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, 226),
            Size = UDim2.fromOffset(504, 16),
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),

            event("Beat", "every one of these is a damped spring, nothing else", function(self, Value)
                self.Text = Value
            end),
        },

        cleanup(function()
            print("[vision] effects asleep")
        end),
    }

    for Slot = 1, 6 do
        table.insert(Trick, {
            ClassName = "Frame",
            Name = `Dot{Slot}`,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(90, 72),
            Size = UDim2.fromOffset(20, 20),
            BorderSizePixel = 0,
            BackgroundTransparency = (Slot - 1) * 0.13,
            BackgroundColor3 = style("Skin")["Accent"],

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },
        })
    end

    for Slot = 1, 14 do
        table.insert(Trick, {
            ClassName = "Frame",
            Name = `Bar{Slot}`,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromOffset(28 + (Slot - 1) * 34, 168),
            Size = UDim2.fromOffset(26, 8),
            BorderSizePixel = 0,
            BackgroundColor3 = style("Skin")["Rail"],

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 4) },
        })
    end

    local Swung = false
    local Risen = false

    table.insert(Trick, Button("Whip", "whip", UDim2.fromOffset(28, 250), 96, function(self)
        Swung = not Swung

        local Goal = if Swung then 470 else 90

        Effects.Beat("six springs, each one slower and looser, so the tail cracks past the head")

        -- longer period and less damping the further down the tail you go
        for Slot = 1, 6 do
            Scope:PhysicsInstance(0.2 + Slot * 0.055, 0.8 - Slot * 0.075, self.Parent:FindFirstChild(`Dot{Slot}`), {
                Position = UDim2.fromOffset(Goal, 72),
            })
        end
    end))

    table.insert(Trick, Button("Wave", "wave", UDim2.fromOffset(132, 250), 96, function(self)
        Risen = not Risen

        local Deck = self.Parent

        Effects.Beat("the same spring started one beat apart, so the wave travels")

        for Slot = 1, 14 do
            local Bar = Deck:FindFirstChild(`Bar{Slot}`)
            local High = if Risen then 8 + math.sin(Slot / 15 * math.pi) * 62 else 8

            task.delay(Slot * 0.035, function()
                -- the page can go away mid cascade, so check before starting another
                if Alive and Bar.Parent then
                    Scope:PhysicsInstance(0.32, 0.4, Bar, { Size = UDim2.fromOffset(26, High) })
                end
            end)
        end
    end))

    table.insert(Trick, Button("Flip", "toggle", UDim2.fromOffset(236, 250), 96, function(self)
        Toggled = not Toggled

        Effects.Beat("the knob snaps on one spring, the sheet under it springs on another")

        Scope:PhysicsInstance(0.28, 0.6, self.Parent:FindFirstChild("Pill"):FindFirstChild("Knob"), {
            Position = UDim2.fromOffset(if Toggled then 46 else 6, 3),
        })

        Scope:PhysicsStyle(0.4, 0.9, Switch, {
            Track = if Toggled then Themes[Wearing].Accent else Themes[Wearing].Rail,
            Knob = if Toggled then Themes[Wearing].Card else Themes[Wearing].Dim,
        })
    end))

    table.insert(Trick, Button("Shake", "shake", UDim2.fromOffset(340, 250), 96, function(self)
        local Pill = self.Parent:FindFirstChild("Pill")

        Effects.Beat("almost no damping on Rotation, so it rings out instead of stopping")

        Pill.Rotation = 14

        Scope:PhysicsInstance(0.14, 0.12, Pill, { Rotation = 0 })
    end))

    Effects = Scope:Capture(Page("Effects", "Effects", "K  next screen", Trick))

    --------------------------------------------------------------- gradient

    local Palettes = {
        Sunset = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 94, 87)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 176, 59)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 233, 122)),
        },

        Ocean = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 58, 140)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 150, 205)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(122, 236, 220)),
        },

        Aurora = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(92, 40, 162)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(58, 200, 158)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(182, 240, 118)),
        },
    }

    local Flat = {
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0),
    }

    local Band = {
        NumberSequenceKeypoint.new(0, 0.85),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.85),
    }

    local Swept = false
    local Tipped = false

    local Wash = {
        {
            ClassName = "Frame",
            Name = "Panel",
            Position = UDim2.fromOffset(28, 58),
            Size = UDim2.fromOffset(504, 96),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 12) },

            {
                ClassName = "UIGradient",
                Name = "Paint",
                Rotation = 0,
                Color = ColorSequence.new(Palettes.Sunset),
            },
        },

        {
            ClassName = "Frame",
            Name = "Strip",
            Position = UDim2.fromOffset(28, 172),
            Size = UDim2.fromOffset(504, 16),
            BorderSizePixel = 0,
            BackgroundColor3 = style("Skin")["Accent"],

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

            {
                ClassName = "UIGradient",
                Name = "Mask",
                Transparency = NumberSequence.new(Flat),
            },
        },

        {
            ClassName = "TextLabel",
            Name = "Note",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, 206),
            Size = UDim2.fromOffset(504, 16),
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),

            event("Told", "TweenService cannot tween a sequence at all, this can", function(self, Value)
                self.Text = Value
            end),
        },

        cleanup(function()
            print("[vision] gradient asleep")
        end),
    }

    local function Paints(Name: string, X: number)
        return Button(Name, string.lower(Name), UDim2.fromOffset(X, 250), 94, function(self)
            Colour.Told(`{string.lower(Name)}, every keypoint moving at once`)

            Scope:SpringInstance(
                TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                self.Parent:FindFirstChild("Panel"):FindFirstChild("Paint"),
                { Color = ColorSequence.new(Palettes[Name]) }
            )
        end)
    end

    table.insert(Wash, Paints("Sunset", 28))
    table.insert(Wash, Paints("Ocean", 130))
    table.insert(Wash, Paints("Aurora", 232))

    table.insert(Wash, Button("Sweep", "sweep", UDim2.fromOffset(334, 250), 94, function(self)
        Swept = not Swept

        Colour.Told("a NumberSequence tweening, keypoint by keypoint")

        Scope:SpringInstance(
            TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            self.Parent:FindFirstChild("Strip"):FindFirstChild("Mask"),
            { Transparency = NumberSequence.new(if Swept then Band else Flat) }
        )
    end))

    table.insert(Wash, Button("Tilt", "tilt", UDim2.fromOffset(436, 250), 94, function(self)
        Tipped = not Tipped

        Colour.Told("the gradient angle is only a number, so it springs")

        Scope:PhysicsInstance(0.5, 0.4, self.Parent:FindFirstChild("Panel"):FindFirstChild("Paint"), {
            Rotation = if Tipped then 90 else 0,
        })
    end))

    Colour = Scope:Capture(Page("Gradient", "Gradient", "K  next screen", Wash))

    ------------------------------------------------------------------ stack

    local Lines = {
        "saved to the vault",
        "three files synced",
        "build finished",
        "connection restored",
        "invite accepted",
    }

    local Toast = Scope:Capture({
        ClassName = "Frame",
        Name = "Toast",
        Position = UDim2.fromOffset(560, 58),
        Size = UDim2.fromOffset(236, 44),
        BorderSizePixel = 0,
        BackgroundColor3 = style("Skin")["Rail"],

        { ClassName = "UICorner", CornerRadius = UDim.new(0, 10) },
        { ClassName = "UIPadding", PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) },

        {
            ClassName = "Frame",
            Name = "Pip",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(5, 22),
            BorderSizePixel = 0,
            BackgroundColor3 = style("Skin")["Accent"],

            { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },
        },

        {
            ClassName = "TextLabel",
            Name = "Line",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(16, 0),
            Size = UDim2.new(1, -16, 1, 0),
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = style("Skin")["Ink"],

            event("Line", "notice", function(self, Value)
                self.Text = Value
            end),
        },
    })

    local Notes = {}
    local Rung = 0
    local Deck

    local function Reflow()
        for Slot, Item in Notes do
            Scope:PhysicsInstance(0.42, 0.7, Item:Open(), {
                Position = UDim2.fromOffset(296, 58 + (Slot - 1) * 52),
            })
        end
    end

    local function Dismiss(Item)
        local Slot = table.find(Notes, Item)

        if not Slot then
            return
        end

        table.remove(Notes, Slot)

        local Body = Item:Open()

        Scope:PhysicsInstance(0.3, 0.9, Body, {
            Position = UDim2.fromOffset(560, Body.Position.Y.Offset),
        })

        task.delay(0.45, function()
            Item:Cleanup()
        end)

        Reflow()
    end

    local function Notify()
        if not Deck then
            return
        end

        Rung += 1

        local Item = Toast:Clone()
        Item.Line(`{Lines[(Rung - 1) % #Lines + 1]}`)

        local Body = Item:Open()
        Body.Parent = Deck
        Body.Position = UDim2.fromOffset(560, 58)

        table.insert(Notes, 1, Item)

        if #Notes > 4 then
            Dismiss(Notes[#Notes])
        end

        Reflow()

        task.delay(4, function()
            if Alive then
                Dismiss(Item)
            end
        end)
    end

    local Pile = {
        {
            ClassName = "TextLabel",
            Name = "Blurb",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, 62),
            Size = UDim2.fromOffset(244, 176),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = "Each notice is a clone of one declaration. Adding or removing one"
                .. " retargets every spring in the column, so the stack reflows"
                .. " instead of snapping. They see themselves out after four seconds.",
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),
        },

        cleanup(function()
            print("[vision] stack asleep")
        end),
    }

    table.insert(Pile, Button("Ring", "notify", UDim2.fromOffset(28, 266), 96, function()
        Notify()
    end))

    table.insert(Pile, Button("Clear", "dismiss all", UDim2.fromOffset(132, 266), 110, function()
        for _, Item in table.clone(Notes) do
            Dismiss(Item)
        end
    end))

    Stack = Scope:Capture(Page("Stack", "Stack", "K  next screen", Pile))

    ------------------------------------------------------------------- list

    local Rack = {
        {
            ClassName = "ScrollingFrame",
            Name = "Rows",
            Position = UDim2.fromOffset(28, 58),
            Size = UDim2.new(1, -56, 1, -146),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarImageColor3 = style("Skin")["Rail"],

            mount("Card"),

            {
                ClassName = "UIListLayout",
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            },

            { ClassName = "UIPadding", PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6) },
        },

        {
            ClassName = "TextLabel",
            Name = "Tally",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -28, 0, 22),
            Size = UDim2.fromOffset(150, 26),
            Font = Enum.Font.Code,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = style("Skin")["Dim"],

            mount("Card"),

            event("Count", 0, function(self, Value)
                self.Text = `{Value} rows`
            end),
        },

        cleanup(function()
            print("[vision] list asleep, rows kept:", #Rows)
        end),
    }

    local function Add(Grow: boolean?)
        if not Shelf then
            return
        end

        Made += 1

        local Item = Row:Clone()
        Item.Label(`{Words[(Made - 1) % #Words + 1]}  {Made}`)
        Item.Order(Made)

        local Body = Item:Open()
        Body.Parent = Shelf

        table.insert(Rows, Item)
        List.Count(#Rows)

        if not Grow then
            return
        end

        Body.Size = UDim2.new(1, 0, 0, 4)
        Scope:PhysicsInstance(0.35, 0.5, Body, { Size = UDim2.new(1, 0, 0, 34) })
    end

    local function Take()
        local Item = table.remove(Rows)

        if not Item then
            return
        end

        List.Count(#Rows)

        Scope:PhysicsInstance(0.3, 0.9, Item:Open(), { Size = UDim2.new(1, 0, 0, 0) })

        task.delay(0.4, function()
            -- cleaned and no longer held, so it leaves the scope for good
            Item:Cleanup()
        end)
    end

    local Bar = {
        { "Add", "add row", 28, 96, function()
            Add(true)
        end },

        { "Take", "drop row", 132, 100, function()
            Take()
        end },

        { "Many", "add thirty", 240, 108, function()
            for _ = 1, 30 do
                Add(false)
            end
        end },

        { "Rename", "Scope:Update", 356, 122, function()
            -- one write lands on every mounted vision that owns a Label
            Scope:Update("Label", `renamed at {os.date("%H:%M:%S")}`)
        end },
    }

    for _, Entry in Bar do
        local Slot = Button(Entry[1], Entry[2], UDim2.new(0, Entry[3], 1, -42), Entry[4], Entry[5])
        Slot.AnchorPoint = Vector2.new(0, 1)

        table.insert(Rack, Slot)
    end

    List = Scope:Capture(Page("List", "List", "K  next screen      this page builds with MountAsync", Rack))

    -- one declaration, cloned per row, each clone with its own value
    Row = Scope:Capture({
        ClassName = "Frame",
        Name = "Row",
        Size = UDim2.new(1, 0, 0, 34),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        BackgroundColor3 = style("Skin")["Rail"],

        -- kept as a value, so the order survives a sleep and comes back with it
        event("Order", 0, function(self, Value)
            self.LayoutOrder = Value
        end),

        { ClassName = "UICorner", CornerRadius = UDim.new(0, 6) },
        { ClassName = "UIPadding", PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) },

        {
            ClassName = "TextLabel",
            Name = "Label",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = style("Skin")["Ink"],

            event("Label", "row", function(self, Value)
                self.Text = Value
            end),
        },
    })

    ----------------------------------------------------------------- wiring

    local Pages = {
        Title = Title,
        Values = Values,
        Motion = Motion,
        Reactive = Reactive,
        Effects = Effects,
        Gradient = Colour,
        Stack = Stack,
        List = List,
    }

    local function Show(Which: string)
        local Sheet = Pages[Which]

        if Which == "Motion" then
            Sheet:Mount()
            Cube()

            return
        end

        if Which == "Stack" then
            Sheet:Mount()
            Deck = Sheet:Open():FindFirstChild("Card")

            return
        end

        if Which ~= "List" then
            Sheet:Mount()

            return
        end

        Sheet:MountAsync()

        Shelf = Sheet:Open():FindFirstChild("Card"):FindFirstChild("Rows")

        if #Rows == 0 then
            for _ = 1, 6 do
                Add(false)
            end

            return
        end

        -- the rows were cleaned when the page slept, mounting relinks them
        for _, Item in Rows do
            Item:Open().Parent = Shelf
        end
    end

    local function Hide(Which: string)
        if Which == "Motion" then
            -- the cube goes first, its parent is about to be destroyed
            Block:Cleanup()
        elseif Which == "Stack" then
            for _, Item in table.clone(Notes) do
                Item:Cleanup()
            end

            table.clear(Notes)

            Deck = nil
        elseif Which == "List" then
            for _, Item in Rows do
                Item:Cleanup()
            end

            Shelf = nil
        end

        Pages[Which]:Cleanup()
    end

    Show("Title")

    local Keys = UserInputService.InputBegan:Connect(function(Input, Busy)
        if Busy or not Alive then
            return
        end

        local Slot = Digits[Input.KeyCode]

        if Slot then
            Run(Slot)
        elseif Input.KeyCode == Enum.KeyCode.K then
            Hide(Order[Index])

            Index = Index % #Order + 1

            Show(Order[Index])
        elseif Input.KeyCode == Enum.KeyCode.T then
            Wearing = if Wearing == "Dark" then "Light" else "Dark"

            -- one call repaints every mounted page at once
            Scope:SpringStyle(
                TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                Skin,
                {
                    Back = Themes[Wearing].Back,
                    Card = Themes[Wearing].Card,
                    Rail = Themes[Wearing].Rail,
                    Ink = Themes[Wearing].Ink,
                    Dim = Themes[Wearing].Dim,
                }
            )

            Scope:PhysicsStyle(0.4, 0.45, "Skin", { Accent = Themes[Wearing].Accent })

            -- the switch keeps its own sheet, so it follows the theme in its own state
            Scope:SpringStyle(TweenInfo.new(0.45), Switch, {
                Track = if Toggled then Themes[Wearing].Accent else Themes[Wearing].Rail,
                Knob = if Toggled then Themes[Wearing].Card else Themes[Wearing].Dim,
            })
        end
    end)

    return function()
        Alive = false

        Keys:Disconnect()
        Scope:Release()
    end
end
