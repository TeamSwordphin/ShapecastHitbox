--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Parent.Types)
local Solver = {}

function Solver:ToPosition(segment: Types.Segment): Vector3
	return segment.Instance.TransformedWorldCFrame.Position
end

function Solver:ToDirection(segment: Types.Segment): Vector3
	if segment.Position then
		return Solver:ToPosition(segment) - segment.Position
	end

	return Vector3.zero
end

function Solver:ToVisual(segment: Types.Segment): CFrame
	return CFrame.lookAt(Solver:ToPosition(segment), segment.Position or Vector3.zero)
end

return Solver
