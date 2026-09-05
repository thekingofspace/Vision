local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Vision = require(ReplicatedStorage.Shared.Vision)

local event = Vision.event
local merge = Vision.merge
local mount = Vision.mount
local fromClone = Vision.fromClone
local fromInstance = Vision.fromInstance
local Keyframe = Vision.Keyframe

local Away = -20

local Brass = Color3.fromRGB(196, 158, 90)
local Slate = Color3.fromRGB(118, 132, 168)
local Lid = Color3.fromRGB(86, 98, 132)
local Mark = Color3.fromRGB(120, 235, 180)

local Linear = TweenInfo.new(0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local Wander = {
    Keyframe(Linear, 0, { Sway = 0 }),
    Keyframe(Linear, 4, { Sway = 1 }),
}

local function Drift(Home: Vector3, Value: number, Lift: number): CFrame
    const Angle = Value * math.pi * 2

    return CFrame.new(
        Home.X + math.sin(Angle) * 2.6,
        Home.Y + math.sin(Angle * 2) * 0.7 + Lift,
        Home.Z + math.cos(Angle) * 1.4
    )
end

local function Stray(): Instance
    local Block = Instance.new("Part")
    Block.Name = "Relic"
    Block.Anchored = true
    Block.CanCollide = false
    Block.Size = Vector3.new(3.4, 3.4, 3.4)
    Block.CFrame = CFrame.new(-11, 3, Away)
    Block.Color = Brass
    Block.Material = Enum.Material.Metal
    Block.Parent = Workspace

    return Block
end

local function Stamp(): Instance
    local Block = Instance.new("Part")
    Block.Name = "Drone"
    Block.Anchored = true
    Block.CanCollide = false
    Block.Size = Vector3.new(3.4, 3.4, 3.4)
    Block.Color = Slate
    Block.Material = Enum.Material.Metal

    local Cap = Instance.new("Part")
    Cap.Name = "Cap"
    Cap.Anchored = true
    Cap.CanCollide = false
    Cap.Size = Vector3.new(3.7, 0.35, 3.7)
    Cap.Color = Lid
    Cap.Parent = Block

    return Block
end

local Spots = {
    { Name = "One", X = -3 },
    { Name = "Two", X = 3 },
    { Name = "Three", X = 9 },
}

return function()
    local Scope = Vision.Scope()

    local Relic = Stray()
    local Model = Stamp()

    local Cells = {}
    local Board
    local Kill, Wake, Tally

    local function Crown(Home: Vector3)
        return {
            ClassName = "Part",
            Name = "Badge",
            Anchored = true,
            CanCollide = false,
            Size = Vector3.new(1.2, 1.2, 1.2),
            CFrame = CFrame.new(Home.X, Home.Y + 3.6, Home.Z),
            Color = Mark,
            Material = Enum.Material.Neon,

            merge("Sway", function(self, Value)
                self.CFrame = Drift(Home, Value, 3.6)
            end),
        }
    end

    local function Sign(Text: string)
        return {
            ClassName = "BillboardGui",
            Name = "Tag",
            Size = UDim2.fromOffset(240, 36),
            StudsOffset = Vector3.new(0, 2.6, 0),
            AlwaysOnTop = true,

            {
                ClassName = "TextLabel",
                Name = "Note",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize = 17,
                TextStrokeTransparency = 0.4,
                Text = Text,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            },
        }
    end

    local Home = Vector3.new(-11, 3, Away)

    local Kept = Scope:Capture({
        fromInstance(Relic),

        Reflectance = 0.15,

        event("Sway", 0, function(self, Value)
            self.CFrame = Drift(Home, Value, 0) * CFrame.Angles(0, Value * math.pi * 2, 0)
        end),

        Crown(Home),
        Sign("fromInstance"),

        {
            ClassName = "ClickDetector",
            MaxActivationDistance = 120,

            MouseClick = function()
                Kill(Cells[1])
            end,
        },
    })

    table.insert(Cells, { Vision = Kept, Home = Home, Owned = false, Name = "Relic" })

    for Index, Spot in Spots do
        const Seat = Vector3.new(Spot.X, 3, Away)

        local Made = Scope:Capture({
            fromClone(Model),

            Name = `Drone{Spot.Name}`,

            event("Sway", 0, function(self, Value)
                self.CFrame = Drift(Seat, Value, 0) * CFrame.Angles(0, Value * math.pi * 2, 0)
            end),

            {
                FromParent = "Cap",
                Material = Enum.Material.Neon,

                merge("Sway", function(self, Value)
                    self.CFrame = Drift(Seat, Value, 1.9)
                end),
            },

            Crown(Seat),
            Sign(`fromClone {Index}`),

            mount(Workspace),

            {
                ClassName = "ClickDetector",
                MaxActivationDistance = 120,

                MouseClick = function()
                    Kill(Cells[Index + 1])
                end,
            },
        })

        table.insert(Cells, { Vision = Made, Home = Seat, Owned = true, Name = `Drone{Spot.Name}` })
    end

    Board = Scope:Capture({
        ClassName = "Part",
        Name = "Board",
        Anchored = true,
        CanCollide = false,
        Transparency = 1,
        Size = Vector3.new(1, 1, 1),
        CFrame = CFrame.new(-1, 10, Away),

        mount(Workspace),

        {
            ClassName = "BillboardGui",
            Name = "Tag",
            Size = UDim2.fromOffset(420, 44),
            AlwaysOnTop = true,

            {
                ClassName = "TextLabel",
                Name = "Note",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize = 20,
                TextStrokeTransparency = 0.4,
                TextColor3 = Color3.fromRGB(255, 255, 255),

                merge("Word", function(self, Value)
                    self.Text = Value
                end),
            },
        },

        event("Word", "click one to clean it up      R  bring them all back", function() end),
    })

    function Tally()
        local Alive = 0

        for _, Cell in Cells do
            if Cell.Live then
                Alive += 1
            end
        end

        Board.Word(`{Alive} of {#Cells} alive      R  bring them all back`)
    end

    local function Roll(Cell, Offset: number)
        if Cell.Roll then
            Cell.Roll:Destroy()
        end

        Cell.Roll = Scope:Animate(Wander, Cell.Vision)
        Cell.Roll.Looped = true
        Cell.Roll:Jump(Offset)
        Cell.Roll:Play()
    end

    function Wake()
        for Index, Cell in Cells do
            if not Cell.Live then
                Cell.Vision:Mount()
                Cell.Live = true

                Roll(Cell, (Index - 1) * 0.9)
            end
        end

        Tally()
    end

    function Kill(Cell)
        if not Cell.Live then
            return
        end

        if Cell.Roll then
            Cell.Roll:Destroy()
            Cell.Roll = nil
        end

        Cell.Vision:Cleanup()
        Cell.Live = false

        Tally()
    end

    Board:Mount()
    Wake()

    const Keys = UserInputService.InputBegan:Connect(function(Input, Busy)
        if not Busy and Input.KeyCode == Enum.KeyCode.R then
            Wake()
        end
    end)

    return function()
        Keys:Disconnect()

        for _, Cell in Cells do
            if Cell.Roll then
                Cell.Roll:Destroy()
                Cell.Roll = nil
            end
        end

        Scope:Release()

        Relic:Destroy()
        Model:Destroy()
    end
end
