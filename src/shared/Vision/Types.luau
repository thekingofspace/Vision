export type CapFunc<v> = (i:v?) -> v

export type Vision = {
    Cleanup:(self:Vision) -> (),
    Mount:(self:Vision) -> (),
    Open:(self:Vision) -> Instance,
    MountAsync:(self:Vision, Budget:number?) -> (),
    Clone:(self:Vision) -> Vision
} & {[string]:CapFunc<any>}

export type Marker = {
    Kind:string,
    Name:string?,
    Initial:any,
    Callback:any,
    Target:(Instance | string)?
}

export type Declaration = {[any]:any}

export type Style = {
    Name:string,
    Get:(self:Style, Field:string) -> any,
    Set:(self:Style, Field:string, Value:any) -> ()
}

export type event = (Event:string, InitialValue:any, Callback:(self:Instance, Value:any) -> ()) -> Marker
export type merge = (Event:string, Callback:(self:Instance, Value:any) -> ()) -> Marker
export type derive = (Event:string, Compute:(Mode:string, Read:(Event:string) -> any, Write:(Event:string, Value:any) -> any, Value:any) -> any) -> Marker
export type ready = (Callback:(self:Instance, cleanup:(Callback:(self:Instance) -> ()) -> ()) -> ()) -> Marker
export type cleanup = (Callback:(self:Instance) -> ()) -> Marker
export type drawcall = (Callback:(self:Instance, Viewport:Vector2) -> ()) -> Marker
export type mount = (Target:Instance | string) -> Marker
export type style = (Name:string) -> {[string]:any}

export type Linker = {
    Cancel:(self:Linker) -> (),
    Await:(self:Linker) -> (),
    Finished:boolean
}

export type Scope = {
    Capture:(Self:Scope, Declaration:Declaration) -> Vision,
    LoadStyle:(self:Scope, Declaration:Declaration) -> Style,
    
    ---@deprecaited
    SpringValue:(self:Scope, TweenInfo:TweenInfo, Vision:Vision | {Vision}, ValueName:string, TargetValue:any) -> Linker,
    ---@deprecaited
    PhysicsValue:(self:Scope, Period:number, Damping:number, Vision:Vision | {Vision}, ValueName:string, TargetValue:any) -> Linker,

    SpringEvent:(self:Scope, TweenInfo:TweenInfo, Vision:Vision | {Vision}, TargetEvents:{[string]:any}) -> Linker,
    SpringStyle:(self:Scope, TweenInfo:TweenInfo, Style:Style | string | {Style | string}, TargetFields:{[string]:any}) -> Linker,
    SpringInstance:(self:Scope, TweenInfo:TweenInfo, Instance:Instance | {Instance}, TargetProps:{[string]:any}) -> Linker,
    SpringFunction:(self:Scope, TweenInfo:TweenInfo, TargetFun:(NewValue:any, dt:number) -> (), InitialValue:any, TargetValue:any) -> Linker,

    PhysicsEvent:(self:Scope, Period:number, Damping:number, Vision:Vision | {Vision}, TargetEvents:{[string]:any}) -> Linker,
    PhysicsStyle:(self:Scope, Period:number, Damping:number, Style:Style | string | {Style | string}, TargetFields:{[string]:any}) -> Linker,
    PhysicsInstance:(self:Scope, Period:number, Damping:number, Instance:Instance | {Instance}, TargetProps:{[string]:any}) -> Linker,
    PhysicsFunction:(self:Scope, Period:number, Damping:number, TargetFun:(NewValue:any) -> (), InitialValue:any, TargetValue:any) -> Linker,

    Update:(self:Scope, EventName:string, Value:any) -> (),
    Release:(self:Scope) -> ()
}

return nil
