const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")

const Vision = require(ReplicatedStorage.Shared.Vision)

const event = Vision.event
const merge = Vision.merge
const derive = Vision.derive
const ready = Vision.ready
const mount = Vision.mount

const PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

const Ink = Color3.fromRGB(14, 15, 21)
const Panel = Color3.fromRGB(26, 28, 38)
const Rail = Color3.fromRGB(44, 47, 62)
const Ivory = Color3.fromRGB(228, 231, 244)
const Muted = Color3.fromRGB(138, 144, 166)
const Accent = Color3.fromRGB(88, 101, 242)
const Warm = Color3.fromRGB(236, 118, 92)
const Mint = Color3.fromRGB(86, 214, 168)

const Palette = { Accent, Warm, Mint }

const Stats = {
    { Key = "Power", Tint = Accent },
    { Key = "Focus", Tint = Mint },
    { Key = "Flow", Tint = Warm },
}

const Actions = {
    { Key = "Pulse", Tint = Accent },
    { Key = "Burst", Tint = Warm },
    { Key = "Shuffle", Tint = Mint },
}

const Open = UDim2.fromOffset(420, 316)
const Wide = UDim2.fromOffset(454, 340)

return function()
    const Scope = Vision.Scope()

    local Alive = true
    local Card
    local Glow
    local Orb
    local Layer

    const Spark = Scope:Capture({
        ClassName = "Frame",
        Name = "Spark",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BorderSizePixel = 0,
        BackgroundColor3 = Accent,

        { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

        event("Tint", Accent, function(self, Value)
            self.BackgroundColor3 = Value
        end),
    })

    const Declaration = {
        ClassName = "ScreenGui",
        Name = "VisionShowcase",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 50,

        mount(PlayerGui),

        {
            ClassName = "Frame",
            Name = "Backdrop",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Ink,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
        },

        {
            ClassName = "Frame",
            Name = "Layer",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,

            ready(function(self)
                Layer = self
            end),
        },

        {
            ClassName = "Frame",
            Name = "Card",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(70, 70),
            BackgroundColor3 = Panel,
            BorderSizePixel = 0,
            ClipsDescendants = true,

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 18) },

            {
                ClassName = "UIStroke",
                Color = Rail,
                Thickness = 1,
                Transparency = 0.25,
            },

            ready(function(self)
                Card = self
            end),

            {
                ClassName = "Frame",
                Name = "Glow",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromOffset(48, 46),
                Size = UDim2.fromOffset(26, 26),
                BackgroundColor3 = Accent,
                BorderSizePixel = 0,

                { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

                ready(function(self)
                    Glow = self
                end),
            },

            {
                ClassName = "TextLabel",
                Name = "Title",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(72, 26),
                Size = UDim2.new(1, -160, 0, 24),
                Font = Enum.Font.GothamBold,
                TextSize = 21,
                TextColor3 = Ivory,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Vision",
            },

            {
                ClassName = "TextLabel",
                Name = "Motto",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(72, 48),
                Size = UDim2.new(1, -160, 0, 16),
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Existence Begins With Perception.",
            },

            {
                ClassName = "TextLabel",
                Name = "Average",
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -104, 0, 24),
                Size = UDim2.fromOffset(78, 44),
                Font = Enum.Font.GothamBold,
                TextSize = 32,
                TextColor3 = Accent,
                TextXAlignment = Enum.TextXAlignment.Right,

                merge("Average", function(self, Value)
                    self.Text = string.format("%.0f", Value * 100)
                end),
            },
        },
    }

    for Index, Stat in Stats do
        table.insert(Declaration, {
            ClassName = "Frame",
            Name = `Row{Index}`,
            Position = UDim2.fromOffset(28, 92 + (Index - 1) * 46),
            Size = UDim2.new(1, -56, 0, 34),
            BackgroundTransparency = 1,

            mount("Card"),

            {
                ClassName = "TextLabel",
                Name = "Key",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = Muted,
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
                TextColor3 = Muted,
                TextXAlignment = Enum.TextXAlignment.Right,

                merge(Stat.Key, function(self, Value)
                    self.Text = string.format("%.2f", Value)
                end),
            },

            {
                ClassName = "Frame",
                Name = "Track",
                Position = UDim2.fromOffset(0, 22),
                Size = UDim2.new(1, 0, 0, 8),
                BackgroundColor3 = Rail,
                BorderSizePixel = 0,

                { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

                {
                    ClassName = "Frame",
                    Name = "Bar",
                    Size = UDim2.fromScale(0, 1),
                    BackgroundColor3 = Stat.Tint,
                    BorderSizePixel = 0,

                    { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

                    event(Stat.Key, 0, function(self, Value)
                        self.Size = UDim2.fromScale(math.clamp(Value, 0, 1), 1)
                    end),
                },
            },
        })
    end

    table.insert(
        Declaration,
        derive("Average", function(Read)
            local Sum = 0

            for _, Stat in Stats do
                Sum += Read(Stat.Key)
            end

            return Sum / #Stats
        end)
    )

    for Index, Action in Actions do
        table.insert(Declaration, {
            ClassName = "TextButton",
            Name = Action.Key,
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, (Index - 2) * 122, 1, -22),
            Size = UDim2.fromOffset(110, 34),
            BackgroundColor3 = Action.Tint,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = Color3.new(1, 1, 1),
            Text = Action.Key,

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 10) },

            MouseEnter = function(self)
                Scope:PhysicsInstance(0.26, 0.42, self, { Size = UDim2.fromOffset(120, 38) })
            end,

            MouseLeave = function(self)
                Scope:PhysicsInstance(0.3, 0.6, self, { Size = UDim2.fromOffset(110, 34) })
            end,
        })
    end

    table.insert(Declaration, {
        ClassName = "Frame",
        Name = "Orb",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = Accent,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,

        { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

        {
            ClassName = "UIStroke",
            Color = Accent,
            Thickness = 2,
            Transparency = 0.35,
        },

        ready(function(self)
            Orb = self
        end),
    })

    const Interface = Scope:Capture(Declaration)

    Interface:Mount()

    const function Fleck(Where: UDim2, Drift: Vector2, Fall: number, Hold: number, Fade: number, Wide: number)
        const Dot = Spark:Clone()

        Dot.Tint(Palette[math.random(#Palette)])

        const Body = Dot:Open()

        Body.AnchorPoint = Vector2.new(0.5, 0.5)
        Body.Position = Where
        Body.Size = UDim2.fromOffset(Wide, Wide)
        Body.BackgroundTransparency = 0.08
        Body.Parent = Layer

        Scope:PhysicsInstance(Fall, 1, Body, {
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

    const function Scatter(Where: UDim2, Count: number)
        for Index = 1, Count do
            const Angle = (Index / Count) * math.pi * 2 + math.random() * 0.5
            const Reach = 160 + math.random() * 220

            Fleck(
                Where,
                Vector2.new(math.cos(Angle) * Reach, math.sin(Angle) * Reach + 120),
                0.9,
                0.5 + math.random() * 0.4,
                0.9 + math.random() * 0.5,
                11 + math.random() * 7
            )
        end
    end

    const function Trailer(Where: UDim2)
        for _ = 1, 3 do
            Fleck(
                UDim2.new(
                    Where.X.Scale,
                    Where.X.Offset + math.random(-14, 14),
                    Where.Y.Scale,
                    Where.Y.Offset + math.random(-14, 14)
                ),
                Vector2.new((math.random() - 0.5) * 120, 240 + math.random() * 320),
                2.4 + math.random() * 0.8,
                0.7 + math.random() * 0.5,
                1.2 + math.random() * 0.6,
                7 + math.random() * 8
            )
        end
    end

    const function Pulse()
        Scope:PhysicsInstance(0.3, 0.28, Card, { Size = Wide })

        task.delay(0.14, function()
            if Alive then
                Scope:PhysicsInstance(0.46, 0.55, Card, { Size = Open })
            end
        end)
    end

    const function Shuffle()
        for _, Stat in Stats do
            Scope:PhysicsValue(0.7, 0.42, Interface, Stat.Key, 0.12 + math.random() * 0.85)
        end
    end

    const Root = Interface:Open()
    const Face = Root.Card

    Face.Pulse.Activated:Connect(Pulse)
    Face.Shuffle.Activated:Connect(Shuffle)

    Face.Burst.Activated:Connect(function()
        const Middle = Root.Card.AbsolutePosition + Root.Card.AbsoluteSize / 2

        Scatter(UDim2.fromOffset(Middle.X, Middle.Y), 30)
        Pulse()
    end)

    Scope:PhysicsInstance(0.62, 0.4, Card, { Size = Open })

    task.spawn(function()
        while Alive do
            Scope:PhysicsInstance(0.9, 0.26, Glow, { Size = UDim2.fromOffset(36, 36) }):Await()

            if not Alive then
                break
            end

            Scope:PhysicsInstance(0.9, 0.26, Glow, { Size = UDim2.fromOffset(24, 24) }):Await()
        end
    end)

    task.spawn(function()
        for Index, Stat in Stats do
            task.wait(0.1)

            if not Alive then
                break
            end

            Scope:PhysicsValue(0.8, 0.38, Interface, Stat.Key, 0.3 + Index * 0.19)
        end
    end)

    local Was = UserInputService:GetMouseLocation()
    local Trail = 0

    const Follow = RunService.RenderStepped:Connect(function(Delta)
        if not Alive then
            return
        end

        const Now = UserInputService:GetMouseLocation()
        const Moved = (Now - Was).Magnitude

        if Moved > 4 then
            Was = Now

            Scope:PhysicsInstance(0.4, 0.5, Orb, { Position = UDim2.fromOffset(Now.X, Now.Y) })
        end

        Trail += Delta

        if Moved > 5 and Trail > 0.05 then
            Trail = 0

            Trailer(UDim2.fromOffset(Now.X, Now.Y))
        end
    end)

    return function()
        Alive = false

        Follow:Disconnect()
        Scope:Release()
    end
end
