--!strict
--!native
--!optimize 2

local RunService = game:GetService("RunService")

local Settings = require(script.Parent.Settings)
local Types = require(script.Parent.Types)
local Solvers = require(script.Parent.Solvers)
local Visualizer = require(script.Parent.Visualizers)

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
	Gets all segments of a hitbox. Segments refers to each individual
	point that are being raycasted out of.
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

function CreateHitbox(instance: Instance?, raycastParams: RaycastParams?): Types.Hitbox
	local hitbox = {
		Scheduler = RunService.PostSimulation,
		Instance = instance,
		RaycastParams = raycastParams or RaycastParams.new(),
		CastData = { CastType = "Raycast", Size = Vector3.zero, CFrame = CFrame.identity, Radius = 0 },
		Active = false,
		Resolution = 60,
		Callbacks = {},
		Attributes = {},
		_callbacksStart = {},
		_callbacksUpdate = {},
		_callbacksHits = {},
		_callbacksStopped = {},
		_activeTimer = 0,
		_lastClock = 0,
	}

	local postSimulation: RBXScriptConnection = RunService.PostSimulation
	local segments: { [Instance]: Types.Segment } = {}

	function hitbox:GetAllSegments(): { [Instance]: Types.Segment }
		return segments
	end

	function hitbox:GetSegment(instance: Instance): Types.Segment
		return segments[instance]
	end

	function hitbox:SetResolution(resolution: number): Types.Hitbox
		hitbox.Resolution = resolution
		return hitbox
	end

	function hitbox:SetCastData(castData: Types.CastData): Types.Hitbox
		hitbox.CastData = {
			CastType = castData.CastType or "Raycast",
			Size = castData.Size or Vector3.zero,
			CFrame = castData.CFrame or CFrame.identity,
			Radius = castData.Radius or 0,
		}

		for _, segment in hitbox:GetAllSegments() do
			segment.CastData = {
				CastType = segment.Instance:GetAttribute("CastType") or hitbox.CastData.CastType,
				Size = segment.Instance:GetAttribute("CastSize") or hitbox.CastData.Size,
				CFrame = segment.Instance:GetAttribute("CastCFrame") or hitbox.CastData.CFrame,
				Radius = segment.Instance:GetAttribute("CastRadius") or hitbox.CastData.Radius,
			}
		end

		return hitbox
	end

	function hitbox:BeforeStart(startCallback: Types.StartCallback): Types.Hitbox
		table.insert(hitbox._callbacksStart, startCallback)
		return hitbox
	end

	function hitbox:OnUpdate(updateCallback: Types.UpdateCallback): Types.Hitbox
		table.insert(hitbox._callbacksUpdate, updateCallback)
		return hitbox
	end

	function hitbox:OnHit(hitCallback: Types.HitCallback): Types.Hitbox
		table.insert(hitbox._callbacksHits, hitCallback)
		return hitbox
	end

	function hitbox:OnStopped(stopCallback: Types.StopCallback): Types.Hitbox
		table.insert(hitbox._callbacksStopped, stopCallback)
		return hitbox
	end

	function hitbox:Reconcile(): Types.Hitbox
		assert(hitbox.Instance ~= nil, "No instance tied to this hitbox! Please set with Hitbox.Instance!")
		table.clear(segments)

		for _, descendant: any in hitbox.Instance:GetDescendants() do
			if descendant:HasTag(Settings.Tag) or descendant.Name == Settings.Tag then
				local solver = Solvers[descendant.ClassName]

				if not solver then
					error(
						`{descendant:GetFullName()}'s class type {descendant.ClassName} is not supported by ShapecastHitbox`
					)
				end

				local segment = {}
				segment.Distance = 0
				segment.Instance = descendant
				segment.Position = solver:ToPosition(segment)
				segment.CastData = {
					CastType = segment.Instance:GetAttribute("CastType") or hitbox.CastData.CastType,
					Size = segment.Instance:GetAttribute("CastSize") or hitbox.CastData.Size,
					CFrame = segment.Instance:GetAttribute("CastCFrame") or hitbox.CastData.CFrame,
					Radius = segment.Instance:GetAttribute("CastRadius") or hitbox.CastData.Radius,
				}

				function segment:_move()
					if segment.Instance.Parent == nil then
						segments[descendant] = nil
						return
					end

					local castType: Types.CastData = segment.CastData.CastType
					local result, dir: Vector3 = Solvers[castType]:Cast(segment, hitbox.RaycastParams)
					local magnitude: number = dir.Magnitude

					if result then
						hitbox.RaycastResult = result

						for _, callback in hitbox._callbacksHits do
							callback(result, segment)
						end
					end

					if Settings.Debug_Visible then
						local adornment: Types.AdornmentData? = Visualizer[castType]:GetAdornment()

						if adornment then
							Visualizer[castType]:ToRender(
								adornment,
								segment,
								solver:ToVisual(segment),
								magnitude,
								result
							)
							task.delay(
								Settings[`Debug_Instance_{castType}_Destroy_Time`],
								Visualizer[castType].ReturnAdornment,
								Visualizer[castType],
								adornment
							)
						end
					end

					segment.Distance += magnitude
					segment.Position = solver:ToPosition(segment)
				end

				segments[descendant] = segment
			end
		end

		return hitbox
	end

	function hitbox:HitStart(timer: number?, overrideParams: RaycastParams?): Types.Hitbox
		for _, segment in hitbox:GetAllSegments() do
			segment.Position = Solvers[segment.Instance.ClassName]:ToPosition(segment)
			segment.Distance = 0
		end

		for _, callback in hitbox._callbacksStart do
			callback()
		end

		hitbox.RaycastResult = nil
		hitbox.RaycastParams = overrideParams or hitbox.RaycastParams
		hitbox.Active = true
		hitbox._lastClock = os.clock()
		hitbox._activeTimer = timer or math.huge

		return hitbox
	end

	function hitbox:HitStop(): Types.Hitbox
		if hitbox.Active then
			hitbox._activeTimer = 0
			hitbox.Active = false

			for _, callback in hitbox._callbacksStopped do
				callback(function()
					table.clear(hitbox._callbacksStart)
					table.clear(hitbox._callbacksUpdate)
					table.clear(hitbox._callbacksHits)
					table.clear(hitbox._callbacksStopped)
				end)
			end
		end

		return hitbox
	end

	function hitbox:Destroy()
		postSimulation:Disconnect()
	end

	postSimulation = hitbox.Scheduler:Connect(function()
		if hitbox._activeTimer > 0 then
			local currentClock: number = os.clock()
			local delta: number = currentClock - hitbox._lastClock

			if delta > 1 / hitbox.Resolution then
				hitbox._lastClock = currentClock

				for _, segment in hitbox:GetAllSegments() do
					task.defer(function()
						for _, callback in hitbox._callbacksUpdate do
							callback(delta)
						end

						segment:_move()
					end)
				end
			end

			hitbox._activeTimer -= delta
		end

		if hitbox._activeTimer <= 0 then
			hitbox:HitStop()
		end
	end)

	hitbox:Reconcile()

	return hitbox
end

return CreateHitbox
