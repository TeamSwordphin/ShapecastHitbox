local Visualizers = {}

for _, visualizer in script:GetChildren() do
	local load = require(visualizer)
	Visualizers[visualizer.Name] = load
end

return Visualizers
