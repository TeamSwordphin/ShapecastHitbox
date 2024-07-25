--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Parent.Types)
local Solver = { Solvers = {} }

function Solver:Cast(segment: Types.Segment, raycastParams: RaycastParams?): RaycastResult?
	local solver = Solver.Solvers[segment.Instance.ClassName]
	local direction: Vector3 = solver:ToDirection(segment)

	return workspace:Spherecast(solver:ToPosition(segment), segment.CastData.Radius, direction, raycastParams),
		direction
end

return Solver
