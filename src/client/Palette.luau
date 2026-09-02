const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Vision = require(ReplicatedStorage.Shared.Vision)

const event = Vision.event
const merge = Vision.merge
const ready = Vision.ready
const mount = Vision.mount

const PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

const Night = Color3.fromRGB(9, 12, 24)
const Deep = Color3.fromRGB(18, 24, 44)
const Glass = Color3.fromRGB(26, 34, 60)
const Mist = Color3.fromRGB(132, 148, 186)
const Frost = Color3.fromRGB(226, 235, 250)

const Cyan = Color3.fromRGB(86, 214, 230)
const Violet = Color3.fromRGB(158, 122, 248)
const Mint = Color3.fromRGB(96, 226, 176)
const Rose = Color3.fromRGB(238, 124, 172)
const Amber = Color3.fromRGB(240, 196, 108)

const Swatches = {
    { Key = "Cyan", Tint = Cyan },
    { Key = "Violet", Tint = Violet },
    { Key = "Mint", Tint = Mint },
    { Key = "Rose", Tint = Rose },
    { Key = "Amber", Tint = Amber },
}

const Across = 8
const Down = 4

return function()
    const Scope = Vision.Scope()

    local Grid
    local Shell
    local Template

    const Tiles = {}
    const Words = {}

    const Layout = {
        ClassName = "ScreenGui",
        Name = "VisionPalette",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 40,

        mount(PlayerGui),

        {
            ClassName = "Frame",
            Name = "Night",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Night,
            BorderSizePixel = 0,

            {
                ClassName = "UIGradient",
                Rotation = 65,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Night),
                    ColorSequenceKeypoint.new(0.55, Deep),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 20, 52)),
                }),
            },
        },

        {
            ClassName = "Frame",
            Name = "Card",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(560, 400),
            BackgroundColor3 = Glass,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 18) },

            {
                ClassName = "UIStroke",
                Name = "Edge",
                Color = Cyan,
                Thickness = 1,
                Transparency = 0.55,

                ready(function(self)
                    table.insert(Words, self)
                end),
            },

            {
                ClassName = "TextLabel",
                Name = "Heading",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(28, 24),
                Size = UDim2.new(1, -56, 0, 28),
                Font = Enum.Font.GothamBold,
                TextSize = 22,
                TextColor3 = Frost,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Aurora",
            },

            {
                ClassName = "TextLabel",
                Name = "Note",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(28, 50),
                Size = UDim2.new(1, -56, 0, 16),
                Font = Enum.Font.Code,
                TextSize = 12,
                TextColor3 = Mist,
                TextXAlignment = Enum.TextXAlignment.Left,

                merge("Call", function(self, Value)
                    self.Text = Value
                end),
            },

            {
                ClassName = "Frame",
                Name = "Grid",
                Position = UDim2.fromOffset(28, 82),
                Size = UDim2.new(1, -56, 0, 208),
                BackgroundTransparency = 1,

                {
                    ClassName = "UIGridLayout",
                    CellSize = UDim2.fromOffset(56, 44),
                    CellPadding = UDim2.fromOffset(8, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                },

                ready(function(self)
                    Grid = self
                end),
            },
        },

        event("Call", "press a swatch", function() end),
    }

    for Index, Swatch in Swatches do
        table.insert(Layout, {
            ClassName = "TextButton",
            Name = Swatch.Key,
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, (Index - 3) * 100, 1, -28),
            Size = UDim2.fromOffset(92, 38),
            BackgroundColor3 = Swatch.Tint,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = Night,
            Text = Swatch.Key,

            mount("Card"),

            { ClassName = "UICorner", CornerRadius = UDim.new(0, 9) },

            MouseEnter = function(self)
                Scope:PhysicsInstance(0.26, 0.4, self, {
                    Size = UDim2.fromOffset(102, 42),
                    BackgroundTransparency = 0,
                })
            end,

            MouseLeave = function(self)
                Scope:PhysicsInstance(0.3, 0.6, self, {
                    Size = UDim2.fromOffset(92, 38),
                    BackgroundTransparency = 0.15,
                })
            end,
        })
    end

    table.insert(Layout, {
        ClassName = "TextButton",
        Name = "Scatter",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -74),
        Size = UDim2.fromOffset(160, 26),
        BackgroundColor3 = Glass,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = Mist,
        Text = "scatter individually",

        mount("Card"),

        { ClassName = "UICorner", CornerRadius = UDim.new(0, 7) },

        MouseEnter = function(self)
            Scope:PhysicsInstance(0.24, 0.5, self, { TextColor3 = Frost })
        end,

        MouseLeave = function(self)
            Scope:PhysicsInstance(0.3, 0.7, self, { TextColor3 = Mist })
        end,
    })

    Shell = Scope:Capture(Layout)

    const function Paint(Tint: Color3)
        Scope:PhysicsValue(0.65, 0.5, Tiles, "Tint", Tint)

        Scope:PhysicsInstance(0.6, 0.6, Words, {
            Color = Tint,
            Transparency = 0.3,
        })

        Shell.Call(`one call, {#Tiles} visions`)
    end

    const function Scatter()
        for _, Tile in Tiles do
            Scope:PhysicsValue(0.7, 0.45, Tile, "Tint", Color3.fromHSV(math.random(), 0.55, 0.95))
        end

        Shell.Call(`{#Tiles} calls, one vision each`)
    end

    const Deck = {}

    function Deck.Show()
        table.clear(Words)

        Shell:Mount()

        const Face = Shell:Open()
        const Card = Face:FindFirstChild("Card")

        if #Tiles == 0 then
            Template = Scope:Capture({
                ClassName = "Frame",
                Name = "Tile",
                BackgroundColor3 = Glass,
                BorderSizePixel = 0,

                { ClassName = "UICorner", CornerRadius = UDim.new(0, 7) },

                event("Tint", Cyan, function(self, Value)
                    self.BackgroundColor3 = Value
                end),

                {
                    ClassName = "Frame",
                    Name = "Pip",
                    AnchorPoint = Vector2.new(0.5, 1),
                    Position = UDim2.new(0.5, 0, 1, -6),
                    Size = UDim2.new(0.55, 0, 0, 3),
                    BorderSizePixel = 0,

                    { ClassName = "UICorner", CornerRadius = UDim.new(1, 0) },

                    merge("Tint", function(self, Value)
                        self.BackgroundColor3 = Value:Lerp(Frost, 0.6)
                    end),
                },
            })

            for Index = 1, Across * Down do
                const Tile = Template:Clone()

                Tile.Tint(Color3.fromHSV((Index / (Across * Down)) * 0.6 + 0.45, 0.5, 0.9))

                table.insert(Tiles, Tile)
            end
        end

        for Index, Tile in Tiles do
            Tile:Mount()

            const Body = Tile:Open()

            Body.LayoutOrder = Index
            Body.Parent = Grid
            Body.Size = UDim2.fromOffset(56, 44)
        end

        for _, Swatch in Swatches do
            Card:FindFirstChild(Swatch.Key).Activated:Connect(function()
                Paint(Swatch.Tint)
            end)
        end

        Card:FindFirstChild("Scatter").Activated:Connect(Scatter)
    end

    function Deck.Hide()
        for _, Tile in Tiles do
            Tile:Cleanup()
        end

        Grid = nil
        Shell:Cleanup()
    end

    function Deck.Destroy()
        Scope:Release()
    end

    Deck.Scatter = Scatter
    Deck.Paint = Paint

    return Deck
end
