local Themes = {}

local function G(a: string, b: string, rot: number?)
	return { a, b, Rotation = rot or 0 }
end



Themes.Gruvbox = {
	Colors = {
		Bg = Color3.fromHex("#1D2021"),
		Panel = Color3.fromHex("#282828"),
		Surface = Color3.fromHex("#3C3836"),
		Surface2 = Color3.fromHex("#504945"),
		Surface3 = Color3.fromHex("#665C54"),

		Stroke = Color3.fromHex("#504945"),
		Divider = Color3.fromHex("#3C3836"),

		Text = Color3.fromHex("#EBDBB2"),
		TextMuted = Color3.fromHex("#A89984"),

		Accent = Color3.fromHex("#D79921"),
		AccentHover = Color3.fromHex("#FABD2F"),

		Success = Color3.fromHex("#98971A"),
		Warning = Color3.fromHex("#D79921"),
		Danger = Color3.fromHex("#CC241D"),

		Shadow = Color3.fromHex("#000000"),
	},

	Gradients = {
		PanelGradient = G("#282828", "#1D2021", 90),
		SurfaceGradient = G("#3C3836", "#282828", 90),
		AccentGradient = G("#D79921", "#FABD2F", 0),
		HeaderGradient = G("#3C3836", "#1D2021", 90),
		ButtonGradient = G("#D79921", "#B57614", 0),
	},

	Name = "Gruvbox",

	ImageID = "108367677259387",
	ImageSize = UDim2.new(0.904, 0, 0.962, 0),
	ImagePosition = UDim2.new(0.554, 0, 0.617, 0),
	ImageScaleType = Enum.ScaleType.Fit,
}

Themes.TokyoNight = {
	Colors = {
		Bg = Color3.fromHex("#1A1B26"),
		Panel = Color3.fromHex("#24283B"),
		Surface = Color3.fromHex("#2F334D"),
		Surface2 = Color3.fromHex("#3B4261"),
		Surface3 = Color3.fromHex("#414868"),

		Stroke = Color3.fromHex("#3B4261"),
		Divider = Color3.fromHex("#2F334D"),

		Text = Color3.fromHex("#C0CAF5"),
		TextMuted = Color3.fromHex("#9AA5CE"),

		Accent = Color3.fromHex("#7AA2F7"),
		AccentHover = Color3.fromHex("#9ECE6A"),

		Success = Color3.fromHex("#9ECE6A"),
		Warning = Color3.fromHex("#E0AF68"),
		Danger = Color3.fromHex("#F7768E"),

		Shadow = Color3.fromHex("#000000"),
	},

	Gradients = {
		PanelGradient = G("#24283B", "#1A1B26", 90),
		SurfaceGradient = G("#2F334D", "#24283B", 90),
		AccentGradient = G("#7AA2F7", "#9ECE6A", 0),
		HeaderGradient = G("#2F334D", "#1A1B26", 90),
		ButtonGradient = G("#7AA2F7", "#4F6AAE", 0),
	},

	Name = "TokyoNight",

	ImageID = "118415034110061",
	ImageSize = UDim2.new(1, 0, 1, 0),
	ImagePosition = UDim2.new(0.5, 0, 0.5, 0),
	ImageScaleType = Enum.ScaleType.Crop,
}

Themes["Scarlet Red"] = {
	Colors = {
		Bg = Color3.fromHex("#0b0002"),
		Panel = Color3.fromHex("#140003"),
		Surface = Color3.fromHex("#1c0206"),
		Surface2 = Color3.fromHex("#260308"),
		Surface3 = Color3.fromHex("#30040a"),

		Stroke = Color3.fromHex("#4a060c"),
		Divider = Color3.fromHex("#1a0204"),

		Text = Color3.fromHex("#f2d6d6"),
		TextMuted = Color3.fromHex("#a87474"),

		Accent = Color3.fromHex("#7a0c12"),
		AccentHover = Color3.fromHex("#a1121a"),

		Success = Color3.fromHex("#6fa36b"),
		Warning = Color3.fromHex("#b8873c"),
		Danger = Color3.fromHex("#c1121f"),

		Shadow = Color3.fromHex("#050001"),
	},

	Gradients = {
		PanelGradient = G("#140003", "#050001", 90),
		SurfaceGradient = G("#30040a", "#140003", 90),
		AccentGradient = G("#a1121a", "#5c090e", 0),
		HeaderGradient = G("#4a060c", "#140003", 90),
		ButtonGradient = G("#7a0c12", "#3a0508", 0),
	},
	
	ImageID = "137685347553217",
	Name = "Scarlet Red",

}

Themes.NordDark = {
	Colors = {
		Bg = Color3.fromHex("#2E3440"),
		Panel = Color3.fromHex("#3B4252"),
		Surface = Color3.fromHex("#434C5E"),
		Surface2 = Color3.fromHex("#4C566A"),
		Surface3 = Color3.fromHex("#5E677A"),

		Stroke = Color3.fromHex("#4C566A"),
		Divider = Color3.fromHex("#434C5E"),

		Text = Color3.fromHex("#ECEFF4"),
		TextMuted = Color3.fromHex("#D8DEE9"),

		Accent = Color3.fromHex("#88C0D0"),
		AccentHover = Color3.fromHex("#81A1C1"),

		Success = Color3.fromHex("#A3BE8C"),
		Warning = Color3.fromHex("#EBCB8B"),
		Danger = Color3.fromHex("#BF616A"),

		Shadow = Color3.fromHex("#000000"),
	},

	Gradients = {
		PanelGradient = G("#3B4252", "#2E3440", 90),
		SurfaceGradient = G("#434C5E", "#3B4252", 90),
		AccentGradient = G("#88C0D0", "#81A1C1", 0),
		HeaderGradient = G("#434C5E", "#2E3440", 90),
		ButtonGradient = G("#88C0D0", "#5E81AC", 0),
	},

	Name = "NordDark",

}

Themes.NordLight = {
	Colors = {
		Bg = Color3.fromHex("#ECEFF4"),
		Panel = Color3.fromHex("#E5E9F0"),
		Surface = Color3.fromHex("#D8DEE9"),
		Surface2 = Color3.fromHex("#CED6E0"),
		Surface3 = Color3.fromHex("#C5CDD8"),

		Stroke = Color3.fromHex("#D8DEE9"),
		Divider = Color3.fromHex("#CED6E0"),

		Text = Color3.fromHex("#2E3440"),
		TextMuted = Color3.fromHex("#4C566A"),

		Accent = Color3.fromHex("#5E81AC"),
		AccentHover = Color3.fromHex("#81A1C1"),

		Success = Color3.fromHex("#A3BE8C"),
		Warning = Color3.fromHex("#EBCB8B"),
		Danger = Color3.fromHex("#BF616A"),

		Shadow = Color3.fromHex("#AAAAAA"),
	},

	Gradients = {
		PanelGradient = G("#E5E9F0", "#ECEFF4", 90),
		SurfaceGradient = G("#D8DEE9", "#E5E9F0", 90),
		AccentGradient = G("#5E81AC", "#81A1C1", 0),
		HeaderGradient = G("#D8DEE9", "#ECEFF4", 90),
		ButtonGradient = G("#5E81AC", "#4C6B90", 0),
	},

	Name = "NordLight",

}

Themes.Catppuccin = {
	Colors = {
		Bg = Color3.fromHex("#1E1E2E"),
		Panel = Color3.fromHex("#313244"),
		Surface = Color3.fromHex("#45475A"),
		Surface2 = Color3.fromHex("#585B70"),
		Surface3 = Color3.fromHex("#6C7086"),

		Stroke = Color3.fromHex("#585B70"),
		Divider = Color3.fromHex("#45475A"),

		Text = Color3.fromHex("#CDD6F4"),
		TextMuted = Color3.fromHex("#BAC2DE"),

		Accent = Color3.fromHex("#89B4FA"),
		AccentHover = Color3.fromHex("#B4BEFE"),

		Success = Color3.fromHex("#A6E3A1"),
		Warning = Color3.fromHex("#F9E2AF"),
		Danger = Color3.fromHex("#F38BA8"),

		Shadow = Color3.fromHex("#000000"),
	},

	Gradients = {
		PanelGradient = G("#313244", "#1E1E2E", 90),
		SurfaceGradient = G("#45475A", "#313244", 90),
		AccentGradient = G("#89B4FA", "#B4BEFE", 0),
		HeaderGradient = G("#45475A", "#1E1E2E", 90),
		ButtonGradient = G("#89B4FA", "#7287FD", 0),
	},

	Name = "Catppuccin",

}

return Themes
