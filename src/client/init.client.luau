local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vision = require(ReplicatedStorage.Shared.Vision)

local event = Vision.event
local merge = Vision.merge
local mount = Vision.mount
local ready = Vision.ready

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local Shows = {
    { Name = "Interface", Note = "thirteen screens of the interface feature set", Load = require(script.Showcase) },
    { Name = "Blast door", Note = "keyframe timelines driving one heavy slab", Load = require(script.Space) },
    { Name = "Entities", Note = "fromInstance and fromClone, side by side", Load = require(script.Entity) },
}

local Ink = Color3.fromRGB(232, 236, 248)
local Dim = Color3.fromRGB(136, 144, 170)
local Card = Color3.fromRGB(26, 28, 38)
local Rail = Color3.fromRGB(44, 47, 62)

local Scope = Vision.Scope()

local Menu, Bar
local Running
local Start, Halt

local function Choice(Entry, Index)
    return {
        ClassName = "TextButton",
        Name = Entry.Name,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 104 + (Index - 1) * 68),
        Size = UDim2.fromOffset(380, 58),
        BackgroundColor3 = Rail,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        Text = Entry.Name,
        TextColor3 = Ink,
        TextYAlignment = Enum.TextYAlignment.Top,

        mount("Card"),

        { ClassName = "UICorner", CornerRadius = UDim.new(0, 10) },
        { ClassName = "UIPadding", PaddingTop = UDim.new(0, 10) },

        {
            ClassName = "TextLabel",
            Name = "Note",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -8),
            Size = UDim2.new(1, -24, 0, 14),
            BackgroundTransparency = 1,
            Font = Enum.Font.Code,
            TextSize = 11,
            Text = Entry.Note,
            TextColor3 = Dim,
        },

        Activated = function()
            Start(Entry)
        end,

        MouseEnter = function(self)
            Scope:PhysicsInstance(0.22, 0.4, self, { Size = UDim2.fromOffset(400, 62) })
        end,

        MouseLeave = function(self)
            Scope:PhysicsInstance(0.28, 0.6, self, { Size = UDim2.fromOffset(380, 58) })
        end,
    }
end

local Sheet = {
    ClassName = "ScreenGui",
    Name = "VisionMenu",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 80,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

    mount(PlayerGui),

    {
        ClassName = "Frame",
        Name = "Back",
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.25,
        BackgroundColor3 = Color3.fromRGB(10, 11, 15),
    },

    {
        ClassName = "Frame",
        Name = "Card",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(440, 330),
        BorderSizePixel = 0,
        BackgroundColor3 = Card,

        { ClassName = "UICorner", CornerRadius = UDim.new(0, 16) },
        { ClassName = "UIStroke", Transparency = 0.55, Color = Rail },

        {
            ClassName = "TextLabel",
            Name = "Mark",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 26),
            Size = UDim2.new(1, -40, 0, 40),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBlack,
            TextSize = 34,
            Text = "VISION",
            TextColor3 = Ink,

            ready(function(self)
                self.Position = UDim2.new(0.5, 0, 0, 12)
                Scope:PhysicsInstance(0.6, 0.5, self, { Position = UDim2.new(0.5, 0, 0, 26) })
            end),
        },

        {
            ClassName = "TextLabel",
            Name = "Motto",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 68),
            Size = UDim2.new(1, -40, 0, 18),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            Text = "pick a showcase",
            TextColor3 = Dim,
        },
    },
}

for Index, Entry in Shows do
    table.insert(Sheet, Choice(Entry, Index))
end

Menu = Scope:Capture(Sheet)

Bar = Scope:Capture({
    ClassName = "ScreenGui",
    Name = "VisionBar",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 90,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

    mount(PlayerGui),

    {
        ClassName = "TextButton",
        Name = "Leave",
        Position = UDim2.fromOffset(20, 20),
        Size = UDim2.fromOffset(150, 34),
        BackgroundColor3 = Rail,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Ink,

        { ClassName = "UICorner", CornerRadius = UDim.new(0, 8) },

        merge("Word", function(self, Value)
            self.Text = Value
        end),

        Activated = function()
            Halt()
        end,

        MouseEnter = function(self)
            Scope:PhysicsInstance(0.22, 0.4, self, { Size = UDim2.fromOffset(160, 38) })
        end,

        MouseLeave = function(self)
            Scope:PhysicsInstance(0.28, 0.6, self, { Size = UDim2.fromOffset(150, 34) })
        end,
    },

    event("Word", "back to the menu", function() end),
})

function Start(Entry)
    if Running then
        return
    end

    Menu:Cleanup()

    Running = Entry.Load()

    Bar.Word(`back to the menu    -    {Entry.Name}`)
    Bar:Mount()
end

function Halt()
    if not Running then
        return
    end

    Running()
    Running = nil

    Bar:Cleanup()
    Menu:Mount()
end

Menu:Mount()
