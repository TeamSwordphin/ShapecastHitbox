export type StartCallback = () -> ()
export type UpdateCallback = (delta: number) -> ()
export type HitCallback = (raycastResult: RaycastResult, segmentHit: Segment) -> ()
export type StopCallback = typeof(function(clearCallbacks) end)

export type AdornmentData = {
	Adornment: LineHandleAdornment,
	LastUse: number,
}

export type SphereAdornmentData = {
	Adornment: SphereHandleAdornment,
	LastUse: number,
}

export type BoxAdornmentData = {
	Adornment: BoxHandleAdornment,
	LastUse: number,
}

export type Segment = {
	Instance: any,
	Distance: number,
	Position: Vector3,
	RaycastResult: RaycastResult?,
	CastData: CastData,
	_move: (self: Segment) -> (),
}

export type CastData = {
	CastType: string,
	CFrame: CFrame,
	Size: Vector3,
	Radius: number,
}

export type Hitbox = {
	Instance: Instance?,
	RaycastParams: RaycastParams?,
	RaycastResult: RaycastResult?,
	Active: boolean,
	Resolution: number,
	CastData: CastData,
	Attributes: { [any]: any },
	_callbacksStart: { StartCallback },
	_callbacksUpdate: { UpdateCallback },
	_callbacksHits: { HitCallback },
	_callbacksStopped: { StopCallback },
	_activeTimer: number,
	_lastClock: number,
	GetAllSegments: (self: Hitbox) -> { [any]: Segment },
	GetSegment: (self: Hitbox, instance: Instance) -> Segment,
	Reconcile: (self: Hitbox) -> (),
	HitStart: (self: Hitbox, timer: number?, raycastParams: RaycastParams?) -> (),
	HitStop: (self: Hitbox) -> (),
	Destroy: (self: Hitbox) -> (),
	SetResolution: (self: Hitbox, resolution: number) -> (),
	SetCastData: (self: Hitbox, castData: CastData) -> (),
	BeforeStart: (self: Hitbox, startCallback: StartCallback) -> (),
	OnUpdate: (self: Hitbox, updateCallback: UpdateCallback) -> (),
	OnHit: (self: Hitbox, hitCallback: HitCallback) -> (),
	OnStopped: (self: Hitbox, stopCallback: StopCallback) -> (),
}

return {}
