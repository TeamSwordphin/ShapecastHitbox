--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Parent.Types)
local Solver = { Solvers = {} }

function Solver:Cast(segment: Types.Segment, raycastParams: RaycastParams?): RaycastResult?
	local direction: Vector3 = Solver.Solvers[segment.Instance.ClassName]:ToDirection(segment)

	return workspace:Blockcast(
		segment.Instance.WorldCFrame * segment.CastData.CFrame,
		segment.CastData.Size,
		direction,
		raycastParams
	),
		direction
end

return Solver
