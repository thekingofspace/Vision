const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Vision = require(ReplicatedStorage.Shared.Vision)

const event = Vision.event
const merge = Vision.merge
const derive = Vision.derive
const ready = Vision.ready
const cleanup = Vision.cleanup
const mount = Vision.mount

const PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

const Coal = Color3.fromRGB(12, 9, 9)
const Char = Color3.fromRGB(28, 21, 20)
const Slate = Color3.fromRGB(40, 30, 28)
const Ash = Color3.fromRGB(150, 132, 126)
const Bone = Color3.fromRGB(240, 228, 216)
const Ember = Color3.fromRGB(255, 122, 47)
const Flame = Color3.fromRGB(255, 194, 74)
const Blood = Color3.fromRGB(196, 58, 34)

const Names = {
    "Cinder", "Torch", "Kiln", "Pyre", "Forge",
    "Scorch", "Blaze", "Wick", "Char", "Flint",
}

const Tags = { "hot", "lit", "raw", "spent", "cured" }

return function()
    const Scope = Vision.Scope()

    local Alive = true
    local List
    local Count = 0
    local Made = 0
    local Seeded = false

    const Rows = {}

    const Layout = {
        ClassName = "ScreenGui",
        Name = "VisionModular",
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
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(48, 20, 13)),
                }),
            },
        },

        {
            ClassName = "Frame",
            Name = "Card",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(460, 470),
            BackgroundColor3 = Char,
            BorderSizePixel = 0,

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 16) },

            {
                ClassName = "UIStroke",
                Color = Blood,
                Thickness = 1,
                Transparency = 0.45,
            },

            {
                ClassName = "TextLabel",
                Name = "Heading",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(24, 20),
                Size = UDim2.new(1, -140, 0, 26),
                Font = Enum.Font.GothamBold,
                TextSize = 20,
                TextColor3 = Bone,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Modular",
            },

            {
                ClassName = "TextLabel",
                Name = "Note",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(24, 44),
                Size = UDim2.new(1, -140, 0, 16),
                Font = Enum.Font.Code,
                TextSize = 12,
                TextColor3 = Ash,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "every row is a clone of one template",
            },

            {
                ClassName = "TextLabel",
                Name = "Tally",
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -104, 0, 18),
                Size = UDim2.fromOffset(80, 44),
                Font = Enum.Font.GothamBold,
                TextSize = 30,
                TextColor3 = Ember,
                TextXAlignment = Enum.TextXAlignment.Right,

                merge("Rows", function(self, Value)
                    self.Text = tostring(Value)
                end),
            },

            {
                ClassName = "ScrollingFrame",
                Name = "List",
                Position = UDim2.fromOffset(20, 76),
                Size = UDim2.new(1, -40, 1, -142),
                BackgroundColor3 = Coal,
                BackgroundTransparency = 0.4,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = Blood,
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,

                { ClassName = "UICorner", CornerRadius = UDim.new(0, 10) },
                { ClassName = "UIPadding", PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) },

                {
                    ClassName = "UIListLayout",
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                },

                ready(function(self)
                    List = self
                end),
            },

            {
                ClassName = "TextLabel",
                Name = "Empty",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(20, 76),
                Size = UDim2.new(1, -40, 1, -142),
                Font = Enum.Font.Code,
                TextSize = 13,
                TextColor3 = Ash,
                Text = "nothing here yet, press Add",

                merge("Rows", function(self, Value)
                    self.Visible = Value == 0
                end),
            },
        },

        event("Rows", 0, function() end),
    }

    const Actions = {
        { Key = "Add", Tint = Ember, Spot = -150 },
        { Key = "Remove", Tint = Slate, Spot = 0 },
        { Key = "Clear", Tint = Blood, Spot = 150 },
    }

    for _, Action in Actions do
        table.insert(Layout, {
            ClassName = "TextButton",
            Name = Action.Key,
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, Action.Spot, 1, -20),
            Size = UDim2.fromOffset(140, 34),
            BackgroundColor3 = Action.Tint,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = Bone,
            Text = Action.Key,

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 8) },

            MouseEnter = function(self)
                Scope:PhysicsInstance(0.26, 0.4, self, { Size = UDim2.fromOffset(152, 38) })
            end,

            MouseLeave = function(self)
                Scope:PhysicsInstance(0.3, 0.6, self, { Size = UDim2.fromOffset(140, 34) })
            end,
        })
    end

    const Shell = Scope:Capture(Layout)

    const Template = Scope:Capture({
        ClassName = "Frame",
        Name = "Row",
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Slate,
        BorderSizePixel = 0,
        ClipsDescendants = true,

        { ClassName = "UICorner", CornerRadius = UDim.new(0, 8) },
        { ClassName = "UIPadding", PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) },

        {
            ClassName = "TextLabel",
            Name = "Label",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 8),
            Size = UDim2.new(1, -110, 0, 16),
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = Bone,
            TextXAlignment = Enum.TextXAlignment.Left,

            event("Label", "Row", function(self, Value)
                self.Text = Value
            end),
        },

        {
            ClassName = "TextLabel",
            Name = "Read",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -104, 0, 8),
            Size = UDim2.fromOffset(60, 16),
            Font = Enum.Font.Code,
            TextSize = 12,
            TextColor3 = Ash,
            TextXAlignment = Enum.TextXAlignment.Right,

            merge("Heat", function(self, Value)
                self.Text = string.format("%.2f", Value)
            end),
        },

        {
            ClassName = "Frame",
            Name = "Track",
            Position = UDim2.fromOffset(0, 32),
            Size = UDim2.new(1, -44, 0, 6),
            BackgroundColor3 = Coal,
            BorderSizePixel = 0,

            { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

            {
                ClassName = "Frame",
                Name = "Bar",
                Size = UDim2.fromScale(0, 1),
                BackgroundColor3 = Ember,
                BorderSizePixel = 0,

                { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

                event("Heat", 0.2, function(self, Value)
                    self.Size = UDim2.fromScale(math.clamp(Value, 0, 1), 1)
                end),
            },
        },

        {
            ClassName = "TextButton",
            Name = "Tag",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 28),
            Size = UDim2.fromOffset(34, 16),
            BackgroundColor3 = Char,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.Code,
            TextSize = 11,
            TextColor3 = Flame,
            Text = "+ tag",

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 4) },
        },

        cleanup(function(self)
            print("[modular] released", self.Name)
        end),
    })

    const function Badge(Body: Instance, Text: string)
        const Pin = Scope:Capture({
            ClassName = "TextLabel",
            Name = "Badge",
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.fromOffset(4, 14),
            Position = UDim2.new(1, 0, 1, -4),
            BackgroundColor3 = Blood,
            BorderSizePixel = 0,
            Font = Enum.Font.Code,
            TextSize = 10,
            TextColor3 = Bone,
            Text = Text,

            mount(Body),

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 3) },
        })

        Scope:PhysicsInstance(0.4, 0.4, Pin:Open(), { Size = UDim2.fromOffset(44, 14) })

        return Pin
    end

    const function Attach(Entry)
        Entry.Vision:Mount()

        const Body = Entry.Vision:Open()

        Entry.Body = Body
        Body.LayoutOrder = Entry.Order
        Body.Parent = List

        table.clear(Entry.Pins)

        for _, Text in Entry.Tags do
            table.insert(Entry.Pins, Badge(Body, Text))
        end

        Body.Tag.Activated:Connect(function()
            const Text = Tags[math.random(#Tags)]

            table.insert(Entry.Tags, Text)
            table.insert(Entry.Pins, Badge(Entry.Body, Text))
        end)
    end

    const function Add()
        if not List then
            return
        end

        Made += 1
        Count += 1

        const Item = Template:Clone()

        Item.Label(`{Names[(Made - 1) % #Names + 1]} {Made}`)
        Item.Heat(0.05)

        const Entry = { Vision = Item, Order = Made, Tags = {}, Pins = {} }

        table.insert(Rows, Entry)
        Attach(Entry)

        Entry.Body.BackgroundTransparency = 1
        Entry.Body.Size = UDim2.new(1, 0, 0, 10)

        Scope:PhysicsInstance(0.45, 0.45, Entry.Body, {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundTransparency = 0,
        })

        Scope:PhysicsValue(0.7, 0.5, Item, "Heat", 0.15 + math.random() * 0.8)

        Shell.Rows(Count)
    end

    const function Release(Entry)
        for _, Pin in Entry.Pins do
            Pin:Cleanup()
        end

        table.clear(Entry.Pins)
        Entry.Vision:Cleanup()
    end

    const function Drop()
        const Entry = table.remove(Rows)

        if not Entry then
            return
        end

        Count -= 1
        Shell.Rows(Count)

        const Body = Entry.Body

        Scope:PhysicsInstance(0.3, 0.9, Body, {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
        })

        for _, Part in Body:GetDescendants() do
            if Part:IsA("TextLabel") or Part:IsA("TextButton") then
                Scope:PhysicsInstance(0.22, 1, Part, { TextTransparency = 1, BackgroundTransparency = 1 })
            elseif Part:IsA("Frame") then
                Scope:PhysicsInstance(0.22, 1, Part, { BackgroundTransparency = 1 })
            end
        end

        task.delay(0.5, function()
            Release(Entry)
        end)
    end

    const Deck = {}

    function Deck.Show()
        Shell:Mount()

        const Face = Shell:Open()

        List = Face:FindFirstChild("Card"):FindFirstChild("List")

        for _, Entry in Rows do
            Attach(Entry)
        end

        const Panel = Face:FindFirstChild("Card")

        Panel:FindFirstChild("Add").Activated:Connect(Add)
        Panel:FindFirstChild("Remove").Activated:Connect(Drop)

        Panel:FindFirstChild("Clear").Activated:Connect(function()
            while #Rows > 0 do
                Drop()
            end
        end)

        if not Seeded then
            Seeded = true

            for _ = 1, 4 do
                Add()
            end
        end
    end

    function Deck.Hide()
        for _, Entry in Rows do
            for _, Pin in Entry.Pins do
                Pin:Cleanup()
            end

            table.clear(Entry.Pins)
            Entry.Vision:Cleanup()
        end

        List = nil
        Shell:Cleanup()
    end

    function Deck.Destroy()
        Alive = false

        Scope:Release()
    end

    return Deck
end
