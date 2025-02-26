--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Parent.Types)
local Solver = { Solvers = {} }

function Solver:Cast(segment: Types.Segment, raycastParams: RaycastParams?): RaycastResult?
	local solver = Solver.Solvers[segment.Instance.ClassName]
	local direction: Vector3 = solver:ToDirection(segment)
	local position: Vector3 = solver:ToPosition(segment)
	local result: RaycastResult = workspace:Spherecast(position, segment.CastData.Radius, direction, raycastParams)

	return result, direction
end

return Solver
