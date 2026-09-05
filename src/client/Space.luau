local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Vision = require(ReplicatedStorage.Shared.Vision)

local event = Vision.event
local merge = Vision.merge
local mount = Vision.mount
local Keyframe = Vision.Keyframe

local Away = -26
local Face = Away + 0.5
local Shut = CFrame.new(0, 6, Away)
local Clear = 12.4

local Steel = Color3.fromRGB(152, 158, 168)
local Dark = Color3.fromRGB(78, 82, 90)
local Stone = Color3.fromRGB(120, 118, 112)
local Glass = Color3.fromRGB(190, 40, 44)

local Start = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local Steady = TweenInfo.new(0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local Settle = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local Slip = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local Nudge = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local Creep = TweenInfo.new(0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local Rise = {
    Keyframe(Start, 0, { Lift = 0 }, { Say = { "opening" } }),
    Keyframe(Start, 0.55, { Lift = 0.7 }),
    Keyframe(Steady, 2.8, { Lift = Clear }),
    Keyframe(Settle, 2.94, { Lift = Clear - 0.22 }),
    Keyframe(Settle, 3.12, { Lift = Clear }, { Say = { "open" } }),
}

local Stutter = {
    Keyframe(Start, 0, { Lift = 0 }, { Say = { "straining" } }),
    Keyframe(Start, 0.5, { Lift = 0.6 }),
    Keyframe(Steady, 1.05, { Lift = 3.2 }),
    Keyframe(Slip, 1.18, { Lift = 2.85 }, { Say = { "too heavy" } }),
    Keyframe(Settle, 1.34, { Lift = 2.85 }),
    Keyframe(Steady, 1.95, { Lift = 6 }),
    Keyframe(Slip, 2.08, { Lift = 5.65 }, { Say = { "slipping" } }),
    Keyframe(Settle, 2.24, { Lift = 5.65 }),
    Keyframe(Steady, 2.85, { Lift = 9.2 }),
    Keyframe(Slip, 2.98, { Lift = 8.9 }),
    Keyframe(Settle, 3.14, { Lift = 8.9 }),
    Keyframe(Steady, 3.8, { Lift = Clear }, { Say = { "open, eventually" } }),
}

local Slam = {
    Keyframe(Start, 0, { Lift = 0 }, { Say = { "lifting" } }),
    Keyframe(Start, 0.45, { Lift = 0.6 }),
    Keyframe(Steady, 1.05, { Lift = 2.8 }),
    Keyframe(Nudge, 1.15, { Lift = 3.05 }, { Say = { "the winch is slipping" } }),
    Keyframe(Creep, 1.29, { Lift = 3.15 }),
    Keyframe(Nudge, 1.39, { Lift = 3.5 }),
    Keyframe(Creep, 1.53, { Lift = 3.6 }),
    Keyframe(Nudge, 1.63, { Lift = 3.95 }),
    Keyframe(Creep, 1.77, { Lift = 4.05 }),
    Keyframe(Steady, 2.35, { Lift = 6 }),
    Keyframe(Creep, 2.45, { Lift = 6.05 }, { Say = { "slam" } }),
    Keyframe(Slip, 2.72, { Lift = 0 }),
    Keyframe(Settle, 2.79, { Lift = 0.22 }),
    Keyframe(Slip, 2.88, { Lift = 0 }),
    Keyframe(Settle, 2.93, { Lift = 0.06 }),
    Keyframe(Slip, 2.99, { Lift = 0 }),
    Keyframe(Slip, 3.05, { Lift = 0 }, { Say = { "shut" } }),
}

local Tap = {
    Keyframe(TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 0, { Push = 0 }),
    Keyframe(TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 0.05, { Push = 0.22 }),
    Keyframe({ Damping = 0.85, Period = 0.34 }, 0.16, { Push = 0 }),
}

local Pads = {
    { Name = "Rise", Text = "open", Reel = Rise, X = -11 },
    { Name = "Stutter", Text = "stutter", Reel = Stutter, X = -8 },
    { Name = "Slam", Text = "slam", Reel = Slam, X = -5 },
}

return function()
    local Scope = Vision.Scope()

    local Door, Roll
    local Play

    Door = Scope:Capture({
        ClassName = "Part",
        Name = "Door",
        Anchored = true,
        Size = Vector3.new(6, 12, 1),
        Color = Steel,
        Material = Enum.Material.DiamondPlate,
        Reflectance = 0.15,
        CFrame = Shut,

        mount(Workspace),

        event("Lift", 0, function(self, Value)
            self.CFrame = Shut * CFrame.new(0, math.max(Value, 0), 0)
        end),

        {
            ClassName = "Part",
            Name = "Sign",
            Anchored = true,
            CanCollide = false,
            Transparency = 1,
            Size = Vector3.new(1, 1, 1),
            CFrame = CFrame.new(0, 14.5, Away + 3),

            mount(Workspace),

            {
                ClassName = "BillboardGui",
                Name = "Tag",
                Size = UDim2.fromOffset(300, 46),
                AlwaysOnTop = true,

                {
                    ClassName = "TextLabel",
                    Name = "Note",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 24,
                    TextStrokeTransparency = 0.4,
                    TextColor3 = Color3.fromRGB(255, 255, 255),

                    merge("Say", function(self, Value)
                        self.Text = Value
                    end),
                },
            },
        },

        event("Say", "closed", function() end),
    })

    local Wall = Scope:Capture({
        ClassName = "Model",
        Name = "Wall",

        mount(Workspace),

        {
            ClassName = "Part",
            Name = "Left",
            Anchored = true,
            Size = Vector3.new(10, 12, 1),
            CFrame = CFrame.new(-8, 6, Away),
            Color = Stone,
            Material = Enum.Material.Concrete,
        },

        {
            ClassName = "Part",
            Name = "Right",
            Anchored = true,
            Size = Vector3.new(10, 12, 1),
            CFrame = CFrame.new(8, 6, Away),
            Color = Stone,
            Material = Enum.Material.Concrete,
        },

        {
            ClassName = "Part",
            Name = "Housing",
            Anchored = true,
            Size = Vector3.new(6.6, 13, 2),
            CFrame = CFrame.new(0, 18.6, Away),
            Color = Dark,
            Material = Enum.Material.Metal,
        },

        {
            ClassName = "Part",
            Name = "Sill",
            Anchored = true,
            Size = Vector3.new(6.6, 0.4, 2),
            CFrame = CFrame.new(0, 0.2, Away + 1.4),
            Color = Dark,
            Material = Enum.Material.Metal,
        },
    })

    local function Pad(Spot: any, Cell: any)
        const Home = Vector3.new(Spot.X, 5, Face + 0.45)

        return {
            ClassName = "Part",
            Name = Spot.Name,
            Anchored = true,
            CanCollide = false,
            Size = Vector3.new(2.6, 2.6, 0.3),
            CFrame = CFrame.new(Spot.X, 5, Face + 0.15),
            Color = Dark,
            Material = Enum.Material.Metal,

            mount(Workspace),

            {
                ClassName = "Part",
                Name = "Dot",
                Anchored = true,
                CanCollide = false,
                Shape = Enum.PartType.Cylinder,
                Size = Vector3.new(0.4, 1.8, 1.8),
                Color = Glass,
                Material = Enum.Material.Glass,
                Transparency = 0.2,
                Reflectance = 0.25,

                event("Push", 0, function(self, Value)
                    self.CFrame = CFrame.new(Home.X, Home.Y, Home.Z - Value)
                        * CFrame.Angles(0, math.rad(90), 0)
                end),

                {
                    ClassName = "ClickDetector",
                    MaxActivationDistance = 96,

                    MouseClick = function()
                        Cell.Press()
                        Play(Spot.Reel)
                    end,
                },
            },

            {
                ClassName = "BillboardGui",
                Name = "Tag",
                Size = UDim2.fromOffset(200, 40),
                StudsOffset = Vector3.new(0, 2, 0),
                AlwaysOnTop = true,

                {
                    ClassName = "TextLabel",
                    Name = "Label",
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 20,
                    Text = Spot.Text,
                    TextStrokeTransparency = 0.4,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                },
            },
        }
    end

    local Cells = {}

    for _, Spot in Pads do
        local Cell = {}

        Cell.Vision = Scope:Capture(Pad(Spot, Cell))

        Cell.Press = function()
            if Cell.Roll then
                Cell.Roll:Destroy()
            end

            Cell.Roll = Scope:Animate(Tap, Cell.Vision)
            Cell.Roll:Play()
        end

        table.insert(Cells, Cell)
    end

    function Play(Reel)
        if Roll then
            Roll:Destroy()
        end

        Door.Lift(0)

        Roll = Scope:Animate(Reel, Door)

        Roll:Bind("Say", function(_, Word)
            Door.Say(Word)
        end)

        Roll:Play()
    end

    Door:Mount()
    Wall:Mount()

    for _, Cell in Cells do
        Cell.Vision:Mount()
    end

    return function()
        if Roll then
            Roll:Destroy()
            Roll = nil
        end

        for _, Cell in Cells do
            if Cell.Roll then
                Cell.Roll:Destroy()
                Cell.Roll = nil
            end
        end

        Scope:Release()
    end
end
