local Solvers = {}

for _, solver in script:GetChildren() do
	local load = require(solver)
	load.Solvers = Solvers
	Solvers[solver.Name] = load
end

return Solvers
