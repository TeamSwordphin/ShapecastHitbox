--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Parent.Types)
local Solver = {}

function Solver:ToPosition(segment: Types.Segment): Vector3
	return segment.Position or segment.Instance.WorldPosition
end

function Solver:ToDirection(segment: Types.Segment): Vector3
	return segment.Instance.WorldPosition - Solver:ToPosition(segment)
end

function Solver:ToVisual(segment: Types.Segment): CFrame
	return CFrame.lookAt(Solver:ToPosition(segment), segment.Instance.WorldPosition)
end

return Solver
