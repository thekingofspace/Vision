const Symbols = require("./Symbols")

const Reserved = {
    ClassName = true,
    attributes = true,
    Attributes = true,
    tags = true,
    Tags = true,
    AttributeChanged = true,
}

const function Create(Declaration: any): Instance
    const ClassName = Declaration.ClassName

    if type(ClassName) ~= "string" then
        error("Declaration requires a ClassName", 0)
    end

    const Object = Instance.new(ClassName)

    for Key, Value in Declaration do
        if type(Key) ~= "string" or Reserved[Key] then
            continue
        end

        if Symbols.Styled(Value) then
            error(`create cannot resolve the style token on "{Key}", styles need a scope`, 0)
        end

        const Member = Object[Key]

        if typeof(Member) == "RBXScriptSignal" then
            Member:Connect(function(...)
                Value(Object, ...)
            end)
        else
            Object[Key] = Value
        end
    end

    const Attributes = Declaration.attributes or Declaration.Attributes

    if Attributes then
        for Key, Value in Attributes do
            Object:SetAttribute(Key, Value)
        end
    end

    const Tags = Declaration.tags or Declaration.Tags

    if Tags then
        for Key, Value in Tags do
            if type(Key) == "number" then
                Object:AddTag(Value)
            elseif Value then
                Object:AddTag(Key)
            end
        end
    end

    if Declaration.AttributeChanged then
        for Key, Callback in Declaration.AttributeChanged do
            Object:GetAttributeChangedSignal(Key):Connect(function()
                Callback(Object)
            end)
        end
    end

    for _, Entry in ipairs(Declaration) do
        if Symbols.Is(Entry) then
            if Entry.Kind == "Mount" and typeof(Entry.Target) == "Instance" then
                Object.Parent = Entry.Target
            end

            continue
        end

        if type(Entry) == "table" then
            const Child = Create(Entry)

            if Child.Parent == nil then
                Child.Parent = Object
            end
        end
    end

    return Object
end

return Create
