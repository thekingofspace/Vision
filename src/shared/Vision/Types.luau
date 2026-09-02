export type CapFunc<v> = (i:v?) -> v

export type Vision = {
    Cleanup:(self:Vision) -> (),
    Mount:(self:Vision) -> (),
    Open:(self:Vision) -> Instance,
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

export type event = (Event:string, InitialValue:any, Callback:(self:Instance, Value:any) -> ()) -> Marker
export type merge = (Event:string, Callback:(self:Instance, Value:any) -> ()) -> Marker
export type ready = (Callback:(self:Instance) -> ()) -> Marker
export type cleanup = (Callback:(self:Instance) -> ()) -> Marker?
export type mount = (Target:Instance | string) -> Marker

export type Linker = {
    Cancel:(self:Linker) -> (),
    Await:(self:Linker) -> (),
    Finished:boolean
}

export type Scope = {
    Capture:(Self:Scope, Declaration:Declaration) -> Vision,

    SpringValue:(self:Scope, TweenInfo:TweenInfo, Vision:Vision | {Vision}, ValueName:string, TargetValue:any) -> Linker,
    SpringInstance:(self:Scope, TweenInfo:TweenInfo, Instance:Instance | {Instance}, TargetProps:{[string]:any}) -> Linker,
    SpringFunction:(self:Scope, TweenInfo:TweenInfo, TargetFun:(NewValue:any, dt:number) -> (), InitialValue:any, TargetValue:any) -> Linker,

    Release:(self:Scope) -> ()
}

return nil
