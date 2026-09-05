local fs = require("@lune/fs")
local process = require("@lune/process")

local Outputs = {
    { Path = "Vision.rbxm", Project = "model.project.json", Note = "binary model, upload this" },
    { Path = "Vision.rbxmx", Project = "model.project.json", Note = "xml model, readable in diffs" },
    { Path = "Vision.rbxl", Project = "default.project.json", Note = "test place, showcases included" },
}

local function Bytes(Count: number): string
    if Count >= 1024 * 1024 then
        return string.format("%.2f MB", Count / 1024 / 1024)
    end

    if Count >= 1024 then
        return string.format("%.1f KB", Count / 1024)
    end

    return `{Count} B`
end

local function FindRojo(): string
    local Home = process.env.HOME or process.env.USERPROFILE
    local Candidates = { "rojo" }

    if Home then
        table.insert(Candidates, `{Home}/.rokit/bin/rojo`)
    end

    for _, Candidate in Candidates do
        local Result = process.exec(Candidate, { "--version" }, { stdio = "none" })

        if Result.ok then
            return Candidate
        end
    end

    error("could not run rojo, try `rokit install`", 0)
end

local function Main()
    for _, Output in Outputs do
        if not fs.isFile(Output.Project) then
            error(`missing {Output.Project}, run this from the repository root`, 0)
        end
    end

    local Rojo = FindRojo()
    local Version = process.exec(Rojo, { "--version" })

    print("")
    print(`building with {(Version.stdout :: string):gsub("%s+$", "")}`)
    print("")

    local Failed = false

    for _, Output in Outputs do
        if fs.isFile(Output.Path) then
            fs.removeFile(Output.Path)
        end

        local Result = process.exec(Rojo, { "build", Output.Project, "--output", Output.Path })

        if not Result.ok then
            Failed = true

            print(`  FAIL  {Output.Path}`)
            print((Result.stderr :: string):gsub("%s+$", ""))

            continue
        end

        if not fs.isFile(Output.Path) then
            Failed = true

            print(`  FAIL  {Output.Path} was not written`)

            continue
        end

        local Size = #fs.readFile(Output.Path)

        print(string.format("  ok    %-14s %9s   %s", Output.Path, Bytes(Size), Output.Note))
    end

    print("")

    if Failed then
        process.exit(1)
    end

    print("upload Vision.rbxm to a release, or open Vision.rbxl to try the showcases")
    print("")
end

Main()
