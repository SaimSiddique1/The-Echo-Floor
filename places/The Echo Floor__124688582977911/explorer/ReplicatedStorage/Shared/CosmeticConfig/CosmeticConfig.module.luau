local Cosmetics = {
	{
		id = "classic",
		name = "Classic",
		color = Color3.fromRGB(200, 200, 200),
		material = Enum.Material.Plastic,
		price = 0,
	},
	{
		id = "gold",
		name = "Gold",
		color = Color3.fromRGB(255, 200, 50),
		material = Enum.Material.Metal,
		price = 100,
	},
	{
		id = "neon_blue",
		name = "Neon Blue",
		color = Color3.fromRGB(0, 150, 255),
		material = Enum.Material.Neon,
		price = 150,
	},
	{
		id = "neon_red",
		name = "Neon Red",
		color = Color3.fromRGB(255, 50, 50),
		material = Enum.Material.Neon,
		price = 150,
	},
	{
		id = "neon_green",
		name = "Neon Green",
		color = Color3.fromRGB(50, 255, 50),
		material = Enum.Material.Neon,
		price = 150,
	},
	{
		id = "neon_purple",
		name = "Neon Purple",
		color = Color3.fromRGB(180, 50, 255),
		material = Enum.Material.Neon,
		price = 150,
	},
	{
		id = "ice",
		name = "Ice",
		color = Color3.fromRGB(200, 230, 255),
		material = Enum.Material.Ice,
		price = 300,
	},
	{
		id = "carbon",
		name = "Carbon Fiber",
		color = Color3.fromRGB(40, 40, 45),
		material = Enum.Material.DiamondPlate,
		price = 400,
	},
}

local function getById(id)
	for _, c in ipairs(Cosmetics) do
		if c.id == id then return c end
	end
	return nil
end

return {
	list = Cosmetics,
	getById = getById,
}
