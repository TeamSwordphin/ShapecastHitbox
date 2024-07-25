--!strict
--!native
--!optimize 2

local RunService = game:GetService("RunService")

local Settings = require(script.Parent.Settings)
local Types = require(script.Parent.Types)
local Solvers = require(script.Parent.Solvers)
local Visualizer = require(script.Parent.Visualizers)

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
