const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")

const Vision = require(ReplicatedStorage.Shared.Vision)
const Modular = require(script.Parent.Modular)
const Palette = require(script.Parent.Palette)

const event = Vision.event
const merge = Vision.merge
const derive = Vision.derive
const ready = Vision.ready
const mount = Vision.mount

const PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

const Coal = Color3.fromRGB(12, 9, 9)
const Char = Color3.fromRGB(28, 21, 20)
const Ash = Color3.fromRGB(150, 132, 126)
const Bone = Color3.fromRGB(240, 228, 216)
const Ember = Color3.fromRGB(255, 122, 47)
const Flame = Color3.fromRGB(255, 194, 74)
const Blood = Color3.fromRGB(196, 58, 34)

const Heat = { Ember, Flame, Blood }

const Menu = { "Continue", "New Run", "Settings", "Quit" }

const Stats = {
    { Key = "Power", Tint = Ember },
    { Key = "Focus", Tint = Flame },
    { Key = "Flow", Tint = Blood },
}

return function()
    const Scope = Vision.Scope()

    local Alive = true
    local Showing = "title"

    local Glow
    local Embers
    local Crest
    local Card
    local Orb
    local Wake
    local Panel
    local Deck
    local Wash

    const Spark = Scope:Capture({
        ClassName = "Frame",
        Name = "Spark",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        BorderSizePixel = 0,
        BackgroundColor3 = Ember,

        { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

        event("Tint", Ember, function(self, Value)
            self.BackgroundColor3 = Value
        end),
    })

    const function Fleck(
        Layer: Instance?,
        Where: UDim2,
        Drift: Vector2,
        Travel: number,
        Hold: number,
        Fade: number,
        Wide: number
    )
        if not Layer then
            return
        end

        const Dot = Spark:Clone()

        Dot.Tint(Heat[math.random(#Heat)])

        const Body = Dot:Open()

        Body.AnchorPoint = Vector2.new(0.5, 0.5)
        Body.Position = Where
        Body.Size = UDim2.fromOffset(Wide, Wide)
        Body.BackgroundTransparency = 0.05
        Body.Parent = Layer

        Scope:PhysicsInstance(Travel, 1, Body, {
            Position = UDim2.new(
                Where.X.Scale,
                Where.X.Offset + Drift.X,
                Where.Y.Scale,
                Where.Y.Offset + Drift.Y
            ),
        })

        task.delay(Hold, function()
            if Alive then
                Scope:PhysicsInstance(Fade, 1, Body, {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(1, 1),
                })
            end
        end)

        task.delay(Hold + Fade * 1.9, function()
            Dot:Cleanup()
        end)
    end

    const Screen = {
        ClassName = "ScreenGui",
        Name = "VisionTitle",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 40,

        mount(PlayerGui),

        {
            ClassName = "Frame",
            Name = "Coal",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Coal,
            BorderSizePixel = 0,

            {
                ClassName = "UIGradient",
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Coal),
                    ColorSequenceKeypoint.new(0.62, Color3.fromRGB(38, 18, 12)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(96, 34, 14)),
                }),
            },
        },

        {
            ClassName = "Frame",
            Name = "Hearth",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 60),
            Size = UDim2.fromOffset(760, 250),
            BackgroundColor3 = Ember,
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,

            { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

            ready(function(self)
                Glow = self
            end),
        },

        {
            ClassName = "Frame",
            Name = "Embers",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,

            ready(function(self)
                Embers = self
            end),
        },

        {
            ClassName = "TextLabel",
            Name = "Crest",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.22),
            Size = UDim2.fromOffset(780, 110),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBlack,
            TextSize = 92,
            TextColor3 = Bone,
            Text = "VISION",

            {
                ClassName = "UIGradient",
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Bone),
                    ColorSequenceKeypoint.new(0.5, Flame),
                    ColorSequenceKeypoint.new(1, Ember),
                }),
            },

            ready(function(self)
                Crest = self
            end),
        },

        {
            ClassName = "TextLabel",
            Name = "Motto",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.325),
            Size = UDim2.fromOffset(620, 22),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 15,
            TextColor3 = Ash,
            Text = "Existence Begins With Perception.",
        },

        {
            ClassName = "TextLabel",
            Name = "Hint",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -24),
            Size = UDim2.fromOffset(460, 18),
            BackgroundTransparency = 1,
            Font = Enum.Font.Code,
            TextSize = 13,
            TextColor3 = Ash,
            Text = "press  K  to switch screens",
        },
    }

    for Index, Label in Menu do
        table.insert(Screen, {
            ClassName = "TextButton",
            Name = `Item{Index}`,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.42, (Index - 1) * 48),
            Size = UDim2.fromOffset(300, 40),
            BackgroundColor3 = Char,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamMedium,
            TextSize = 16,
            TextColor3 = Ash,
            Text = Label,

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 8) },

            MouseEnter = function(self)
                Scope:PhysicsInstance(0.3, 0.4, self, {
                    Size = UDim2.fromOffset(348, 44),
                    TextColor3 = Flame,
                    BackgroundTransparency = 0.08,
                })

                const Spot = self.AbsolutePosition + self.AbsoluteSize / 2

                for _ = 1, 7 do
                    Fleck(
                        Embers,
                        UDim2.fromOffset(Spot.X + math.random(-160, 160), Spot.Y + 14),
                        Vector2.new(math.random(-50, 50), -110 - math.random() * 90),
                        1.2,
                        0.4,
                        0.6,
                        4 + math.random() * 5
                    )
                end
            end,

            MouseLeave = function(self)
                Scope:PhysicsInstance(0.34, 0.6, self, {
                    Size = UDim2.fromOffset(300, 40),
                    TextColor3 = Ash,
                    BackgroundTransparency = 0.35,
                })
            end,
        })
    end

    const Title = Scope:Capture(Screen)

    const Board = {
        ClassName = "ScreenGui",
        Name = "VisionBoard",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 40,

        mount(PlayerGui),

        {
            ClassName = "Frame",
            Name = "Coal",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Coal,
            BorderSizePixel = 0,

            {
                ClassName = "UIGradient",
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Coal),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(54, 22, 14)),
                }),
            },
        },

        {
            ClassName = "Frame",
            Name = "Wake",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,

            ready(function(self)
                Wake = self
            end),
        },

        {
            ClassName = "Frame",
            Name = "Orb",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(22, 22),
            BackgroundColor3 = Ember,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,

            { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

            ready(function(self)
                Orb = self
            end),
        },

        {
            ClassName = "Frame",
            Name = "Card",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(70, 70),
            BackgroundColor3 = Char,
            BorderSizePixel = 0,
            ClipsDescendants = true,

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 16) },

            {
                ClassName = "UIStroke",
                Color = Blood,
                Thickness = 1,
                Transparency = 0.4,
            },

            ready(function(self)
                Card = self
            end),

            {
                ClassName = "TextLabel",
                Name = "Heading",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(26, 20),
                Size = UDim2.new(1, -140, 0, 26),
                Font = Enum.Font.GothamBold,
                TextSize = 20,
                TextColor3 = Bone,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Loadout",
            },

            {
                ClassName = "TextLabel",
                Name = "Visits",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(26, 44),
                Size = UDim2.new(1, -140, 0, 16),
                Font = Enum.Font.Code,
                TextSize = 12,
                TextColor3 = Ash,
                TextXAlignment = Enum.TextXAlignment.Left,

                merge("Visits", function(self, Value)
                    self.Text = `rebuilt {Value}x, state kept`
                end),
            },

            {
                ClassName = "TextLabel",
                Name = "Average",
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -106, 0, 20),
                Size = UDim2.fromOffset(80, 44),
                Font = Enum.Font.GothamBold,
                TextSize = 32,
                TextColor3 = Ember,
                TextXAlignment = Enum.TextXAlignment.Right,

                merge("Average", function(self, Value)
                    self.Text = string.format("%.0f", Value * 100)
                end),
            },
        },
    }

    for Index, Stat in Stats do
        table.insert(Board, {
            ClassName = "Frame",
            Name = `Row{Index}`,
            Position = UDim2.fromOffset(26, 84 + (Index - 1) * 44),
            Size = UDim2.new(1, -52, 0, 32),
            BackgroundTransparency = 1,

            mount("Card"),

            {
                ClassName = "TextLabel",
                Name = "Key",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = Ash,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = Stat.Key,
            },

            {
                ClassName = "TextLabel",
                Name = "Read",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Font = Enum.Font.Code,
                TextSize = 12,
                TextColor3 = Ash,
                TextXAlignment = Enum.TextXAlignment.Right,

                merge(Stat.Key, function(self, Value)
                    self.Text = string.format("%.2f", Value)
                end),
            },

            {
                ClassName = "Frame",
                Name = "Track",
                Position = UDim2.fromOffset(0, 21),
                Size = UDim2.new(1, 0, 0, 7),
                BackgroundColor3 = Color3.fromRGB(48, 34, 30),
                BorderSizePixel = 0,

                { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

                {
                    ClassName = "Frame",
                    Name = "Bar",
                    Size = UDim2.fromScale(0, 1),
                    BackgroundColor3 = Stat.Tint,
                    BorderSizePixel = 0,

                    { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

                    event(Stat.Key, 0.35, function(self, Value)
                        self.Size = UDim2.fromScale(math.clamp(Value, 0, 1), 1)
                    end),
                },
            },
        })
    end

    table.insert(
        Board,
        derive("Average", function(Mode, Read)
            local Sum = 0

            for _, Stat in Stats do
                Sum += Read(Stat.Key)
            end

            return Sum / #Stats
        end)
    )

    table.insert(Board, event("Visits", 0, function() end))

    table.insert(Board, {
        ClassName = "TextButton",
        Name = "Stoke",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -18),
        Size = UDim2.fromOffset(150, 32),
        BackgroundColor3 = Blood,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextColor3 = Bone,
        Text = "Stoke",

        mount("Card"),

        { ClassName = "UICorner", CornerRadius = UDim.new(0, 8) },

        MouseEnter = function(self)
            Scope:PhysicsInstance(0.26, 0.42, self, { Size = UDim2.fromOffset(162, 36) })
        end,

        MouseLeave = function(self)
            Scope:PhysicsInstance(0.3, 0.6, self, { Size = UDim2.fromOffset(150, 32) })
        end,

        Activated = function(self)
            for _, Stat in Stats do
                Scope:PhysicsValue(0.7, 0.42, Panel, Stat.Key, 0.15 + math.random() * 0.8)
            end

            Scope:PhysicsInstance(0.3, 0.28, Card, { Size = UDim2.fromOffset(452, 300) })

            task.delay(0.15, function()
                if Alive and Showing == "board" then
                    Scope:PhysicsInstance(0.46, 0.55, Card, { Size = UDim2.fromOffset(420, 280) })
                end
            end)
        end,
    })

    Panel = Scope:Capture(Board)

    const Order = { "title", "board", "modular", "palette" }

    const function Show(Which: string)
        Showing = Which

        if Which == "title" then
            Title:Mount()

            Crest.Position = UDim2.fromScale(0.5, 0.14)
            Scope:PhysicsInstance(0.85, 0.45, Crest, { Position = UDim2.fromScale(0.5, 0.22) })
        elseif Which == "board" then
            Panel.Visits(Panel.Visits() + 1)
            Panel:Mount()

            Scope:PhysicsInstance(0.62, 0.4, Card, { Size = UDim2.fromOffset(420, 280) })
        elseif Which == "modular" then
            Deck = Deck or Modular()

            Deck.Show()
        else
            Wash = Wash or Palette()

            Wash.Show()
        end
    end

    const function Hide(Which: string)
        if Which == "title" then
            Title:Cleanup()
        elseif Which == "board" then
            Panel:Cleanup()
        elseif Which == "modular" then
            if Deck then
                Deck.Hide()
            end
        elseif Wash then
            Wash.Hide()
        end
    end

    Show("title")

    const Keys = UserInputService.InputBegan:Connect(function(Input, Busy)
        if Busy or not Alive or Input.KeyCode ~= Enum.KeyCode.K then
            return
        end

        const Index = table.find(Order, Showing) or 1

        Hide(Showing)
        Show(Order[Index % #Order + 1])
    end)

    task.spawn(function()
        while Alive do
            if Showing == "title" and Glow then
                Scope:PhysicsInstance(0.4 + math.random() * 0.35, 0.55, Glow, {
                    BackgroundTransparency = 0.42 + math.random() * 0.22,
                    Size = UDim2.fromOffset(700 + math.random() * 150, 220 + math.random() * 80),
                }):Await()
            else
                task.wait(0.12)
            end
        end
    end)

    local Rising = 0
    local Was = UserInputService:GetMouseLocation()
    local Streak = 0

    const Frame = RunService.RenderStepped:Connect(function(Delta)
        if not Alive then
            return
        end

        if Showing == "title" then
            Rising += Delta

            if Rising > 0.055 then
                Rising = 0

                for _ = 1, 2 do
                    Fleck(
                        Embers,
                        UDim2.new(math.random(), 0, 1, 20),
                        Vector2.new(math.random(-80, 80), -460 - math.random() * 420),
                        3.4 + math.random() * 1.4,
                        1.5 + math.random() * 0.9,
                        1.2 + math.random() * 0.7,
                        4 + math.random() * 7
                    )
                end
            end

            return
        end

        const Now = UserInputService:GetMouseLocation()
        const Moved = (Now - Was).Magnitude

        if Moved > 4 and Orb then
            Was = Now

            Scope:PhysicsInstance(0.4, 0.5, Orb, { Position = UDim2.fromOffset(Now.X, Now.Y) })
        end

        Streak += Delta

        if Moved > 5 and Streak > 0.05 then
            Streak = 0

            for _ = 1, 3 do
                Fleck(
                    Wake,
                    UDim2.fromOffset(Now.X + math.random(-12, 12), Now.Y + math.random(-12, 12)),
                    Vector2.new((math.random() - 0.5) * 110, 220 + math.random() * 300),
                    2.4 + math.random() * 0.8,
                    0.7 + math.random() * 0.5,
                    1.2 + math.random() * 0.6,
                    6 + math.random() * 7
                )
            end
        end
    end)

    return function()
        Alive = false

        Keys:Disconnect()
        Frame:Disconnect()

        if Deck then
            Deck.Destroy()
        end

        if Wash then
            Wash.Destroy()
        end

        Scope:Release()
    end
end
