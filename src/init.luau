--!strict
--!native
--!optimize 2

-- ShapecastHitbox
-- Phin
-- August 2024

--[=[
	Documentation of the hitbox can be found inside at ShapecastHitbox/Types.luau.
	This module is still relatively new and experimental, use at your own risk for 
	production-level projects.
]=]

local Types = require(script.Types)

export type Segment = Types.Segment
export type CastData = Types.CastData
export type Hitbox = Types.Hitbox
export type UpdateCallback = Types.UpdateCallback
export type HitCallback = Types.HitCallback
export type StopCallback = Types.StopCallback
export type AdornmentData = Types.AdornmentData
export type SphereAdornmentData = Types.SphereAdornmentData
export type BoxAdornmentData = Types.BoxAdornmentData

return {
	new = require(script.Hitbox),
	Settings = require(script.Settings),
	CastTypes = {
		Raycast = "Raycast",
		Blockcast = "Blockcast",
		Spherecast = "Spherecast",
	},
}
