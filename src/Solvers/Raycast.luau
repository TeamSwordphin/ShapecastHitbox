--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Parent.Types)
local Solver = { Solvers = {} }

function Solver:Cast(segment: Types.Segment, raycastParams: RaycastParams?): RaycastResult?
	local solver = Solver.Solvers[segment.Instance.ClassName]
	local origin: Vector3 = solver:ToPosition(segment)
	local direction: Vector3 = solver:ToDirection(segment)

	return workspace:Raycast(origin, direction, raycastParams), direction
end

return Solver
