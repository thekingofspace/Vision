local fs = require("@lune/fs")
local process = require("@lune/process")

local Project = "model.project.json"

local Outputs = {
    { Path = "Vision.rbxm", Note = "binary model, upload this" },
    { Path = "Vision.rbxmx", Note = "xml model, readable in diffs" },
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
    if not fs.isFile(Project) then
        error(`missing {Project}, run this from the repository root`, 0)
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

        local Result = process.exec(Rojo, { "build", Project, "--output", Output.Path })

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

    print("upload Vision.rbxm to a release, or drag it into Studio to test")
    print("")
end

Main()
