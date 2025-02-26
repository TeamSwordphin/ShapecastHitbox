--!strict
--!native
--!optimize 2

local Types = require(script.Parent.Parent.Types)
local Solver = { Solvers = {} }

function Solver:Cast(segment: Types.Segment, raycastParams: RaycastParams?): RaycastResult?
	local direction: Vector3 = Solver.Solvers[segment.Instance.ClassName]:ToDirection(segment)
	local lastCFrame: CFrame? = segment.CastData._LastCFrameBlockCast

	local result: RaycastResult = workspace:Blockcast(
		(lastCFrame or segment.Instance.WorldCFrame) * segment.CastData.CFrame,
		segment.CastData.Size,
		direction,
		raycastParams
	)

	-- Since Blockcast has an offset, we'll need to defer the lastCFrame position to determine where it is at
	task.defer(function()
		lastCFrame = segment.Instance.WorldCFrame
	end)

	return result, direction
end

return Solver
