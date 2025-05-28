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
		Instance = instance,
		RaycastParams = raycastParams or RaycastParams.new(),
		CastData = { CastType = "Raycast", Size = Vector3.zero, CFrame = CFrame.identity, Radius = 0 },
		Active = false,
		Resolution = 60,
		Callbacks = {},
		Attributes = {},
		FilterPartsHit = false,
	}

	local filterList: { [Instance]: boolean } = {}
	local callbacksStart: { Types.StartCallback } = {}
	local callbacksUpdate: { Types.UpdateCallback } = {}
	local callbacksHits: { Types.HitCallback } = {}
	local callbacksStopped: { Types.StopCallback } = {}

	local activeTimer: number = 0
	local lastClock: number = 0

	local postSimulation: RBXScriptConnection
	local segments: { [Instance]: Types.Segment } = {}

	local function ReturnHitboxAfterCallbackInsertion(
		list: {
			Types.HitCallback
			| Types.StartCallback
			| Types.UpdateCallback
			| Types.StopCallback
		},
		callback: Types.HitCallback | Types.StartCallback | Types.UpdateCallback | Types.StopCallback
	): Types.Hitbox
		table.insert(list, callback)
		return hitbox
	end

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

	function hitbox:BeforeStart(callback: Types.StartCallback): Types.Hitbox
		return ReturnHitboxAfterCallbackInsertion(callbacksStart, callback)
	end

	function hitbox:OnUpdate(callback: Types.UpdateCallback): Types.Hitbox
		return ReturnHitboxAfterCallbackInsertion(callbacksUpdate, callback)
	end

	function hitbox:OnHit(callback: Types.HitCallback): Types.Hitbox
		return ReturnHitboxAfterCallbackInsertion(callbacksHits, callback)
	end

	function hitbox:OnStopped(callback: Types.StopCallback): Types.Hitbox
		return ReturnHitboxAfterCallbackInsertion(callbacksStopped, callback)
	end

	function hitbox:RemoveSegment(descendant: any): Types.Hitbox
		if segments[descendant] then
			segments[descendant] = nil
		end

		return hitbox
	end

	function hitbox:AddSegment(descendant: any): Types.Segment
		local segment = {}

		if descendant:HasTag(Settings.Tag) or descendant.Name == Settings.Tag then
			local solver = Solvers[descendant.ClassName]

			if not solver then
				error(
					`{descendant:GetFullName()}'s class type {descendant.ClassName} is not supported by ShapecastHitbox`
				)
			end

			segment.Distance = 0
			segment.Instance = descendant
			segment.Position = solver:ToPosition(segment)
			segment.LastDirection = -Vector3.one
			segment.CastData = {
				CastType = segment.Instance:GetAttribute("CastType") or hitbox.CastData.CastType,
				Size = segment.Instance:GetAttribute("CastSize") or hitbox.CastData.Size,
				CFrame = segment.Instance:GetAttribute("CastCFrame") or hitbox.CastData.CFrame,
				Radius = segment.Instance:GetAttribute("CastRadius") or hitbox.CastData.Radius,
			}

			function segment:_update()
				if segment.Instance.Parent == nil then
					segments[descendant] = nil
					return
				end

				local castType: Types.CastData = segment.CastData.CastType
				local result, dir: Vector3 = Solvers[castType]:Cast(segment, hitbox.RaycastParams)
				local magnitude: number = dir.Magnitude

				if result then
					hitbox.RaycastResult = result

					if hitbox.FilterPartsHit then
						local currentFilter = hitbox.RaycastParams.FilterDescendantsInstances
						table.insert(currentFilter, result.Instance)

						filterList[result.Instance] = true
						hitbox.RaycastParams.FilterDescendantsInstances = currentFilter
					end

					for _, callback in callbacksHits do
						task.defer(callback, result, segment)
					end
				end

				if Settings.Debug_Visible then
					local adornment: Types.AdornmentData? = Visualizer[castType]:GetAdornment()

					if adornment then
						Visualizer[castType]:ToRender(adornment, segment, solver:ToVisual(segment), magnitude, result)
						task.delay(
							Settings[`Debug_Instance_{castType}_Destroy_Time`],
							Visualizer[castType].ReturnAdornment,
							Visualizer[castType],
							adornment
						)
					end
				end

				if magnitude > 0 then
					segment.LastDirection = dir
					segment.Distance += magnitude
				end

				segment.Position = segment.Instance.WorldPosition
			end

			segments[descendant] = segment
		end

		return segment
	end

	function hitbox:Reconcile(): Types.Hitbox
		assert(hitbox.Instance ~= nil, "No instance tied to this hitbox! Please set with Hitbox.Instance!")
		table.clear(segments)

		for _, descendant: any in hitbox.Instance:GetDescendants() do
			hitbox:AddSegment(descendant)
		end

		return hitbox
	end

	function hitbox:HitStart(timer: number?, overrideParams: RaycastParams?): Types.Hitbox
		for _, segment in hitbox:GetAllSegments() do
			segment.Position = nil -- Reset its state
			segment.Position = Solvers[segment.Instance.ClassName]:ToPosition(segment)
			segment.Distance = 0
		end

		for _, callback in callbacksStart do
			callback()
		end

		hitbox.RaycastResult = nil
		hitbox.RaycastParams = overrideParams or hitbox.RaycastParams
		hitbox.Active = true

		lastClock = os.clock()
		activeTimer = timer or math.huge

		return hitbox
	end

	function hitbox:HitStop(): Types.Hitbox
		if hitbox.Active then
			activeTimer = 0
			hitbox.Active = false

			for _, callback in callbacksStopped do
				callback(function()
					table.clear(callbacksStart)
					table.clear(callbacksUpdate)
					table.clear(callbacksHits)
					table.clear(callbacksStopped)
				end)
			end

			if hitbox.FilterPartsHit then
				local currentFilter = hitbox.RaycastParams.FilterDescendantsInstances

				for instance in filterList do
					local index = table.find(currentFilter, instance)

					if index then
						table.remove(currentFilter, index)
					end
				end

				table.clear(filterList)
				hitbox.RaycastParams.FilterDescendantsInstances = currentFilter
			end
		end

		return hitbox
	end

	function hitbox:Destroy()
		postSimulation:Disconnect()
	end

	local function Init()
		postSimulation = RunService.PostSimulation:Connect(function()
			if activeTimer > 0 then
				local currentClock: number = os.clock()
				local delta: number = currentClock - lastClock

				if delta >= (1 / hitbox.Resolution) then
					lastClock = currentClock

					for _, callback in callbacksUpdate do
						callback(delta)
					end

					for _, segment in hitbox:GetAllSegments() do
						task.defer(segment._update, segment)
					end
				end

				activeTimer -= delta
			end

			if activeTimer <= 0 then
				hitbox:HitStop()
			end
		end)

		hitbox:Reconcile()
	end

	Init()
	return hitbox
end

return CreateHitbox
