return {
	-- The tag or name of the object to find.
	Tag = "DmgPoint",

	Minimum_Stationary_Length = 1,

	-- Reveal if the debug lines should be visible or not.
	Debug_Visible = false,
	Debug_Instance_Raycast_Destroy_Time = 1,
	Debug_Instance_Spherecast_Destroy_Time = 0.1,
	Debug_Instance_Blockcast_Destroy_Time = 0.1,

	Debug_Instance_Transparency = 0.3,
	Debug_Instance_Color = Color3.fromRGB(255, 0, 0),
	Debug_Instance_Hit_Color = Color3.fromRGB(0, 255, 0),
	Debug_Instance_Raycast_Width = 10, --- Only applies to Raycast lines
	Debug_Instance_Derender_Location = CFrame.new(0, math.huge, 0),
}
