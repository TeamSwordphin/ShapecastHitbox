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

local ActiveHitboxes = {}

local function NewHitbox(...): Hitbox
	local hitbox = require(script.Hitbox)(...)
	local instance = select(1, ...)

	if not ActiveHitboxes[instance] then
		ActiveHitboxes[instance] = {}
	end

	table.insert(ActiveHitboxes[instance], hitbox)

	hitbox:OnDestroying(function()
		if not ActiveHitboxes[instance] then
			return
		end

		local totalHitboxes: number = #ActiveHitboxes[instance]

		for i = totalHitboxes, 1, -1 do
			if ActiveHitboxes[instance][i] == hitbox then
				table.remove(ActiveHitboxes[instance], i)

				if totalHitboxes == 1 then
					ActiveHitboxes[instance] = nil
				end
			end
		end
	end)

	return hitbox
end

local ShapecastHitbox = {
	new = NewHitbox,
	Settings = require(script.Settings),
	CastTypes = {
		Raycast = "Raycast",
		Blockcast = "Blockcast",
		Spherecast = "Spherecast",
	},
}

function ShapecastHitbox:GetHitboxesFromInstance(instance: Instance): { Hitbox }
	return ActiveHitboxes[instance] or {}
end

function ShapecastHitbox:GetActiveInstances(): { [Instance]: { Hitbox } }
	return ActiveHitboxes
end

return ShapecastHitbox
