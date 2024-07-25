--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Parent.Types)
local Solver = {}

function Solver:ToPosition(segment: Types.Segment): Vector3
	return segment.Instance.TransformedWorldCFrame.Position
end

function Solver:ToDirection(segment: Types.Segment): Vector3
	return Solver:ToPosition(segment) - segment.Position
end

function Solver:ToVisual(segment: Types.Segment): CFrame
	return CFrame.lookAt(Solver:ToPosition(segment), segment.Position)
end

return Solver
