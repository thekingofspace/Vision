local Symbols = require(script.Symbols)
local Scope = require(script.Scope)
local Types = require(script.Types)

export type CapFunc<v> = Types.CapFunc<v>
export type Vision = Types.Vision
export type Linker = Types.Linker
export type Scope = Types.Scope
export type Declaration = Types.Declaration

local Vision = {
    event = Symbols.event,
    merge = Symbols.merge,
    derive = Symbols.derive,
    ready = Symbols.ready,
    cleanup = Symbols.cleanup,
    mount = Symbols.mount,
}

function Vision.Scope(): Types.Scope
    return (Scope.new() :: any) :: Types.Scope
end

return Vision
