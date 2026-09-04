const Symbols = require("./Symbols")

const Protected = {
    Mount = true,
    MountAsync = true,
    Open = true,
    Cleanup = true,
    Clone = true,
}

const function Walk(Declaration: any, Trail: string, Found: any)
    const ClassName = Declaration.ClassName
    const Named = if type(ClassName) == "string" then ClassName else "?"
    const Label = if type(Declaration.Name) == "string" then `{Named}({Declaration.Name})` else Named
    const Path = if Trail == "" then Label else `{Trail} > {Label}`

    if type(ClassName) ~= "string" then
        table.insert(Found.Notes, `{Path} has no ClassName, mounting it will error`)
    end

    if type(Declaration.Name) == "string" then
        const Seen = Found.Names[Declaration.Name]

        if Seen then
            table.insert(
                Found.Notes,
                `two nodes are both named "{Declaration.Name}" ({Seen} and {Path}), mount by name reaches only the last one`
            )
        else
            Found.Names[Declaration.Name] = Path
        end
    end

    for _, Entry in ipairs(Declaration) do
        if Symbols.Is(Entry) then
            const Kind = Entry.Kind
            const Name = Entry.Name

            if Kind == "Event" then
                if Found.Declared[Name] then
                    table.insert(Found.Notes, `value "{Name}" is declared by event twice, the later initial value wins`)
                end

                Found.Declared[Name] = true
                Found.Used[Name] = true

                if type(Entry.Initial) == "table" then
                    table.insert(
                        Found.Notes,
                        `value "{Name}" starts as a table, every clone will share that same table`
                    )
                end
            elseif Kind == "Merge" then
                Found.Used[Name] = true
                Found.Read[Name] = Path
            elseif Kind == "Derive" then
                if Found.Derived[Name] then
                    table.insert(Found.Notes, `value "{Name}" is derived twice, capturing this will error`)
                end

                Found.Derived[Name] = true
                Found.Declared[Name] = true
                Found.Used[Name] = true
            elseif Kind == "Mount" then
                if type(Entry.Target) == "string" then
                    table.insert(Found.Wants, { Name = Entry.Target, Path = Path })
                elseif Symbols.Injected(Entry.Target) and #Entry.Target.Hosts == 0 then
                    table.insert(Found.Notes, `{Path} injects into nothing, it will never be parented`)
                end
            end

            if type(Name) == "string" and Protected[Name] then
                table.insert(Found.Notes, `value "{Name}" collides with a reserved method, capturing this will error`)
            end
        elseif type(Entry) == "table" then
            Walk(Entry, Path, Found)
        end
    end
end

const function Lint(Declaration: any): { string }
    if type(Declaration) ~= "table" then
        error("lint expects a declaration table", 0)
    end

    const Found = {
        Notes = {},
        Names = {},
        Declared = {},
        Derived = {},
        Used = {},
        Read = {},
        Wants = {},
    }

    Walk(Declaration, "", Found)

    for Name, Path in Found.Read do
        if not Found.Declared[Name] then
            table.insert(Found.Notes, `{Path} merges "{Name}", which nothing declares, so it stays nil`)
        end
    end

    for _, Want in Found.Wants do
        if not Found.Names[Want.Name] then
            table.insert(
                Found.Notes,
                `{Want.Path} mounts to "{Want.Name}", which is not a name in this declaration`
            )
        end
    end

    table.sort(Found.Notes)

    const Shout = if type(warn) == "function" then warn else print

    for _, Note in Found.Notes do
        Shout(`[vision lint] {Note}`)
    end

    return Found.Notes
end

return Lint
