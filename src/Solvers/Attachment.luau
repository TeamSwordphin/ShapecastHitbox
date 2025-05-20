--!strict
--!native
--!optimize 2

local Settings = require(script.Parent.Parent.Settings)
local Types = require(script.Parent.Parent.Types)

local Solver = {}

function Solver:ToPosition(segment: Types.Segment): Vector3
	return segment.Position or segment.Instance.WorldPosition
end

function Solver:ToDirection(segment: Types.Segment): Vector3
	local direction: Vector3 = segment.Instance.WorldPosition - Solver:ToPosition(segment)

	if direction.Magnitude == 0 then
		direction = segment.LastDirection.Unit * Settings.Minimum_Stationary_Length
	end

	return direction
end

function Solver:ToVisual(segment: Types.Segment): CFrame
	return CFrame.lookAt(Solver:ToPosition(segment), segment.Instance.WorldPosition)
end

return Solver
