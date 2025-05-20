--[=[
	@class Hitbox
	Create easy hitboxes using Raycasts and Shapecasts.
	
	To start using ShapecastHitbox, first initialize your hitbox via
	ShapecastHitbox.new(instance). After you have configured it, you
	can activate the hitbox by calling `Hitbox:HitStart()`.

	To stop the Hitbox, call `Hitbox:HitStop()`. If you are done using
	the hitbox, it is recommended to call `Hitbox:Destroy()` to clean
	up any connections left behind.

	Example usage:
	```lua
	local hitbox = ShapecastHitbox.new(swordHandle, raycastParams)

	-- The hitbox will automatically disable itself after 3 seconds
	-- The duration field is optional and will last indefinitely otherwise
	local duration = 3 

	-- HitStart is chainable into OnUpdate. You can alternatively use
	-- `Hitbox:OnUpdate()` on a new line if you prefer multi-lined usage.
	hitbox:HitStart(duration):OnUpdate(function()

		-- We hit something!
		if hitbox.RaycastResult then 

			-- HitStop is chainable into OnUpdate or HitStart.
			-- For this example, we'll destroy the hitbox right
			-- after hitting something.
			hitbox:HitStop():Destroy()
		end
	end)

	-- Alternative, we can manually destroy the hitbox at some other time.
	task.delay(10, hitbox.Destroy, hitbox)
	```
]=]

--[=[
	@function new
	@param instance Instance
	@param raycastParams? RaycastParams
	@within Hitbox
	Creates a new hitbox.
]=]

--[=[
	@function GetAllSegments
	@return { [Instance]: Types.Segment }
	@within Hitbox
	Gets all segments of a hitbox. Segments refers to each individual
	point that are being raycasted out of.
]=]

--[=[
	@function GetSegment
	@param instance Instance
	@return Types.Segment
	@within Hitbox
	Gets one segment from the hitbox using the original instance
	as the reference.
]=]

--[=[
	@function SetResolution
	@param resolution number
	@return Types.Hitbox
	@within Hitbox
	Sets the resolution of the hitbox's raycasting. This resolution is capped to
	the user's current frame rate (lower frames = less accurate). Lower accuracy
	can result in better ShapecastHitbox performance so adjust according to the
	context of your project.

	Default: 60
]=]

--[=[
	@function SetCastData
	@param castData Types.CastData
	@return Types.Hitbox
	@within Hitbox
	Sets the current CastData of this hitbox. This is where you can set if the Hitbox should use
	Raycast, Blockcast, or Spherecast. There is also additional funtionality (read the devforum post)
	on `only` adjusting specific segments to use those raycast types.

	Default: { CastType = "Raycast", Size = Vector3.zero, CFrame = CFrame.identity, Radius = 0 }

	Example usage:
	```lua
	hitbox:SetCastData({ CastType = "Blockcast", CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(90), 0, 0) })
	hitbox:SetCastData({ CastType = "Spherecast", Radius = 10 })
	```
]=]

--[=[
	@function BeforeStart
	@param startCallback Types.StartCallback
	@return Types.Hitbox
	@within Hitbox
	This callback runs before `HitStart` activates the hitbox.
	Use OnStopped to clean up these callbacks or alternatively use
	`Hitbox:Destroy()`.

	Example usage:
	```lua
	local damage = 0

	hitbox:BeforeStart(function()
		damage = 5
	end):HitStart():OnHit(function(raycastResult, segmentHit)
		raycastResult.Instance.Parent.Humanoid:TakeDamage(damage)
	end)
	```
]=]

--[=[
	@function OnUpdate
	@param updateCallback Types.UpdateCallback
	@return Types.Hitbox
	@within Hitbox
	This callback runs per frame while the hitbox exists. Do note that 
	it will still run even if the hitbox is stopped. You can use 
	`Hitbox.Active` to determine if a hitbox is active or not. Use OnStopped 
	to clean up these callbacks or alternatively `Hitbox:Destroy()`.

	Example usage:
	```lua
	hitbox:HitStart():OnUpdate(function(deltaTime: number)
		if hitbox.Active then
			if hitbox.RaycastResult then
				hitbox:HitStop()
				print("We hit something!")
			end
		else
			--- Hitbox is inactive.
		end
	end)
	```
]=]

--[=[
	@function OnHit
	@param hitCallback Types.HitCallback
	@return Types.Hitbox
	@within Hitbox
	This callback is activated upon the hitbox returning a RaycastResult.
	Use OnStopped to clean up these callbacks or alternatively `Hitbox:Destroy()`.

	Example usage:
	```lua
	hitbox:HitStart():OnHit(function(raycastResult, segmentHit)
		raycastResult.Instance.Parent.Humanoid:TakeDamage(20)

		--- Place a part at the specific place hit
		local part = Instance.new("Part")
		part.Position = raycastResult.Position
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Anchored = true
		part.Size = Vector3.one
		part.Color = Color3.fromRGB(0, 255, 0)
		part.Parent = workspace

		task.delay(5, part.Destroy, part)
	end)
	```
]=]

--[=[
	@function OnStopped
	@param stopCallback Types.StopCallback
	@return Types.Hitbox
	@within Hitbox
	This callback runs after HitStop has activated. Do note that
	`Hitbox:Destroy()` does not automatically run this function. This callback
	has a parameter which helps you auto-cleanup every callback used so far.
	If you don't clean up, you may end up having duplicate callback calls
	when reusing the hitbox.

	Example usage:
	```lua
	local damage = 0
	local duration = 3

	hitbox:BeforeStart(function()
		damage = 5
	end):HitStart(duration):OnHit(function(raycastResult, segmentHit)
		raycastResult.Instance.Parent.Humanoid:TakeDamage(damage)
	end):OnUpdate(function(deltaTime)
		damage += (0.1 * deltaTime)
	end):OnStopped(function(cleanCallbacks)
		cleanCallbacks() --- This will clean up this chain
		hitbox:Destroy()
	end)
	```
]=]

--[=[
	@function Reconcile
	@return Types.Hitbox
	@within Hitbox
	Runs automatically the first time a hitbox is initialized. Can be re-ran
	again to make the hitbox re-search the instance for any new changes in the
	hitbox. Do not run frequently as it is not performant.

	Example usage:
	```lua
	local weapon = sword.Handle
	local hitbox = ShapecastHitbox.new(weapon)

	local attachment = Instance.new("Attachment")
	attachment:AddTag("DmgPoint")
	attachment.Parent = weapon

	hitbox:Reconcile()
	```
]=]

--[=[
	@function HitStart
	@param timer? number
	@param overrideParams? RaycastParams
	@return Types.Hitbox
	@within Hitbox
	Activates the hitbox. Can be given an optional timer parameter to make
	the hitbox automatically stop after a certain amount of seconds. OverrideParams
	can be used to switch RaycastParams on the fly (which the hitbox will default to).
	Will activate all BeforeStart callbacks before activating the hitbox.

	Example usage:
	```lua
	local raycastParams = RaycastParams.new()

	hitbox:HitStart(5, raycastParams)
	```
]=]

--[=[
	@function HitStop
	@return Types.Hitbox
	@within Hitbox
	Deactivates the hitbox. Will call all OnStopped callbacks after deactivation.
]=]

--[=[
	@function Destroy
	@within Hitbox
	Disconnects the scheduler. When no references to the hitbox remain, it will be
	automatically garbage collected.
]=]

export type Hitbox = {
	Instance: Instance?,
	RaycastParams: RaycastParams?,
	RaycastResult: RaycastResult?,
	Active: boolean,
	Resolution: number,
	CastData: CastData,
	Attributes: { [any]: any },
	FilterPartsHit: boolean,
	GetAllSegments: (self: Hitbox) -> { [any]: Segment },
	GetSegment: (self: Hitbox, instance: Instance) -> Segment,
	AddSegment: (self: Hitbox, descendant: any) -> Segment,
	RemoveSegment: (self: Hitbox, descendant: any) -> Hitbox,
	Reconcile: (self: Hitbox) -> (),
	HitStart: (self: Hitbox, timer: number?, raycastParams: RaycastParams?) -> Hitbox,
	HitStop: (self: Hitbox) -> Hitbox,
	Destroy: (self: Hitbox) -> (),
	SetResolution: (self: Hitbox, resolution: number) -> Hitbox,
	SetCastData: (self: Hitbox, castData: CastData) -> Hitbox,
	BeforeStart: (self: Hitbox, startCallback: StartCallback) -> Hitbox,
	OnUpdate: (self: Hitbox, updateCallback: UpdateCallback) -> Hitbox,
	OnHit: (self: Hitbox, hitCallback: HitCallback) -> Hitbox,
	OnStopped: (self: Hitbox, stopCallback: StopCallback) -> Hitbox,
}

--[=[
	@class Segment
]=]

--[=[
	@within Segment
	@prop Instance any
	The instance that this segment belongs to.
]=]

--[=[
	@within Segment
	@prop Distance number
	How far this segment has traveled while the hitbox is active.
]=]

--[=[
	@within Segment
	@prop Position Vector3
	The current position of this segment in the frame.
]=]

--[=[
	@within Segment
	@prop RaycastResult? RaycastResult
	The last RaycastResult returned by this segment.
]=]

--[=[
	@within Segment
	@prop CastData CastData
	The current CastData of the segment. Defaults to the parent Hitbox's
	CastData. Can be individually modified to cast differently than other
	segments.
]=]

export type Segment = {
	Instance: any,
	Distance: number,
	Position: Vector3?,
	LastDirection: Vector3,
	RaycastResult: RaycastResult?,
	CastData: CastData,
	_update: (self: Segment) -> (),
}

--[=[
	@class CastData
]=]

--[=[
	@within CastData
	@prop CastType string
	The current cast to use. Can be Blockcast, Spherecast, or Raycast.

	Defaults to `Raycast`.
]=]

--[=[
	@within CastData
	@prop CFrame CFrame
	The current CFrame of Blockcast. Does nothing if it is not this CastType.

	Defaults to `CFrame.identity`.
]=]

--[=[
	@within CastData
	@prop Size Vector3
	The current size of Blockcast. Does nothing if it is not this CastType.

	Defaults to `Vector3.zero`.
]=]

--[=[
	@within CastData
	@prop Radius number
	The current radius size of Spherecast. Does nothing if it is not this CastType.

	Defaults to `0`.
]=]

export type CastData = {
	CastType: string,
	CFrame: CFrame,
	Size: Vector3,
	Radius: number,
	_LastCFrameBlockCast: CFrame?,
}

--[=[
	@class AdornmentData
]=]

--[=[
	@within AdornmentData
	@prop Adornment LineHandleAdornment
]=]

export type AdornmentData = {
	Adornment: LineHandleAdornment,
	LastUse: number,
}

--[=[
	@class SphereAdornmentData
]=]

--[=[
	@within SphereAdornmentData
	@prop Adornment SphereHandleAdornment
]=]

export type SphereAdornmentData = {
	Adornment: SphereHandleAdornment,
	LastUse: number,
}

--[=[
	@class BoxAdornmentData
]=]

--[=[
	@within BoxAdornmentData
	@prop Adornment BoxHandleAdornment
]=]

export type BoxAdornmentData = {
	Adornment: BoxHandleAdornment,
	LastUse: number,
}

export type StartCallback = () -> ()
export type UpdateCallback = (delta: number) -> ()
export type HitCallback = (raycastResult: RaycastResult, segmentHit: Segment) -> ()
export type StopCallback = typeof(function(clearCallbacks) end)

return {}
