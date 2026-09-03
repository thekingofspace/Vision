const Symbols = require(script.Symbols)
const Scope = require(script.Scope)
const Types = require(script.Types)

export type CapFunc<v> = Types.CapFunc<v>
export type Vision = Types.Vision
export type Linker = Types.Linker
export type Scope = Types.Scope
export type Declaration = Types.Declaration

const Vision = {
    event = Symbols.event,
    merge = Symbols.merge,
    derive = Symbols.derive,
    ready = Symbols.ready,
    cleanup = Symbols.cleanup,
    drawcall = Symbols.drawcall,
    style = Symbols.style,
    mount = Symbols.mount,
}

function Vision.Scope(): Types.Scope
    return (Scope.new() :: any) :: Types.Scope
end

return Vision
