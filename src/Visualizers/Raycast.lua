--!native
--!strict
--!optimize 2

--- While using Trails as debugging lines would be nice (and more performant!), they are susceptible to frame drops and are inaccurate
--- at low graphic settings which can create false results
-- @author Phin

local Types = require(script.Parent.Parent.Types)
local Settings = require(script.Parent.Parent.Settings)

local cache = {}
cache.__index = cache
cache.__type = `ShapecastHitbox_{script.Name}`
cache._AdornmentInUse = {}
cache._AdornmentInReserve = {}

--- AdornmentData type

--- Internal function to create an AdornmentData type
--- Creates a LineHandleAdornment and a timer value
function cache:_CreateAdornment(): Types.AdornmentData
	local line: LineHandleAdornment = Instance.new("LineHandleAdornment")
	line.Name = "_ShapecastHitboxDebugger"
	line.Color3 = Settings.Debug_Instance_Color
	line.Thickness = Settings.Debug_Instance_Raycast_Width
	line.Transparency = Settings.Debug_Instance_Transparency

	line.Length = 0
	line.CFrame = Settings.Debug_Instance_Derender_Location

	line.Adornee = workspace.Terrain
	line.Parent = workspace.Terrain

	return {
		Adornment = line,
		LastUse = 0,
	}
end

--- Gets an AdornmentData type. Creates one if there isn't one currently available.
function cache:GetAdornment(): Types.AdornmentData?
	if #cache._AdornmentInReserve <= 0 then
		--- Create a new LineAdornmentHandle if none are in reserve
		local adornment: Types.AdornmentData = cache:_CreateAdornment()
		table.insert(cache._AdornmentInReserve, adornment)
	end

	local adornment: Types.AdornmentData? = table.remove(cache._AdornmentInReserve, 1)

	if adornment then
		adornment.Adornment.Visible = true
		adornment.LastUse = os.clock()
		table.insert(cache._AdornmentInUse, adornment)
	end

	return adornment
end

function cache:ToRender(
	adornment: Types.AdornmentData,
	segment: Types.Segment,
	cframe: CFrame,
	magnitude: number,
	raycastResult: RaycastResult
)
	adornment.Adornment.Length = magnitude
	adornment.Adornment.CFrame = cframe
	adornment.Adornment.Color3 = raycastResult and Settings.Debug_Instance_Hit_Color or Settings.Debug_Instance_Color
	adornment.Adornment.ZIndex = raycastResult and 999 or -1
end

--- Returns an AdornmentData back into the cache.
-- @param AdornmentData
function cache:ReturnAdornment(adornment: Types.AdornmentData)
	adornment.Adornment.Length = 0
	adornment.Adornment.Visible = false
	adornment.Adornment.CFrame = Settings.Debug_Instance_Derender_Location
	table.insert(cache._AdornmentInReserve, adornment)
end

--- Clears the cache in reserve. Should only be used if you want to free up some memory.
--- If you end up turning on the visualizer again for this session, the cache will fill up again.
--- Does not clear adornments that are currently in use.
function cache:Clear()
	for i: number = #cache._AdornmentInReserve, 1, -1 do
		if cache._AdornmentInReserve[i].Adornment then
			cache._AdornmentInReserve[i].Adornment:Destroy()
		end

		table.remove(cache._AdornmentInReserve, i)
	end
end

return cache
