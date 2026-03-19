local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local UILibrary = {}
UILibrary.__index = UILibrary

local DEFAULT_THEME_IMAGE = "rbxassetid://108367677259387"

local DEFAULT_OPTIONS = { 
	ScreenGuiName = "NekoHub by Vixiie & Kyee!",
	WindowTitle = "NekoHub <3",
	VersionText = "v1.4.12",
	ToggleKey = Enum.KeyCode.RightShift,
	DefaultTheme = "Gruvbox",
	Parent = nil,
	PromptText = "Press RShift To Toggle UI",
	Size = UDim2.new(0.75, 0, 0.65, 0),
	AspectRatio = 1.78,
	UseBlur = true,
	OpenFOV = 80,
	AnimationTime = 0.4,
	BackgroundImageTransparency = 0.92,
	PageTransparency = 0.35,
	ContentItemTransparency = 0.6,
	ButtonTransparency = 0.4,
	NotificationDuration = 3,
	ShowKeybindOverlay = false,
	PromptEnabled = true,
	OpenOnStart = false,
	Sounds = {
		Swoosh = nil,
		Swoosh2 = nil,
	},
}

local function deepCopy(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			new[k] = deepCopy(v)
		else
			new[k] = v
		end
	end
	return new
end

local function mergeDefaults(options)
	local merged = deepCopy(DEFAULT_OPTIONS)
	for k, v in pairs(options or {}) do
		if type(v) == "table" and type(merged[k]) == "table" then
			for subK, subV in pairs(v) do
				merged[k][subK] = subV
			end
		else
			merged[k] = v
		end
	end
	return merged
end

local function safeCallback(callback, ...)
	if type(callback) ~= "function" then return end
	local ok, err = pcall(callback, ...)
	if not ok then
		warn("[UILibrary] Callback error:", err)
	end
end

local function createRipple(parent, x, y)
	if not parent or not parent:IsA("GuiObject") then
		return
	end

	local ripple = Instance.new("Frame")
	ripple.Name = "Ripple"
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.Position = UDim2.fromOffset(x - parent.AbsolutePosition.X, y - parent.AbsolutePosition.Y)
	ripple.Size = UDim2.fromOffset(0, 0)
	ripple.BackgroundTransparency = 0.35
	ripple.BorderSizePixel = 0
	ripple.ZIndex = parent.ZIndex + 1
	ripple.ClipsDescendants = true
	ripple.Parent = parent
	ripple.BackgroundColor3 = Color3.new(1, 1, 1)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ripple

	local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 1.8

	local tween = TweenService:Create(ripple, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(maxSize, maxSize),
		BackgroundTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		if ripple.Parent then
			ripple:Destroy()
		end
	end)
end

local function create(className, props, children)
	local inst = Instance.new(className)
	for prop, value in pairs(props or {}) do
		if prop == "Attributes" then
			for attrName, attrValue in pairs(value) do
				inst:SetAttribute(attrName, attrValue)
			end
		else
			inst[prop] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function getOrCreateBlur()
	local blur = Lighting:FindFirstChild("UILibraryBlur")
	if blur and blur:IsA("BlurEffect") then
		return blur
	end

	blur = Instance.new("BlurEffect")
	blur.Name = "UILibraryBlur"
	blur.Size = 0
	blur.Parent = Lighting
	return blur
end

local function setVisibleTree(inst, visible)
	if inst:IsA("GuiObject") then
		inst.Visible = visible
	end
	for _, child in ipairs(inst:GetChildren()) do
		if child:IsA("GuiObject") then
			child.Visible = visible
		end
	end
end

local function applyThemeImage(imageLabel, theme, targetTransparency)
	if not imageLabel then return end
	if theme and theme.ImageID then
		imageLabel.Image = "rbxassetid://" .. tostring(theme.ImageID)
	else
		imageLabel.Image = DEFAULT_THEME_IMAGE
	end

	imageLabel.Size = theme and theme.ImageSize or UDim2.new(0.904, 0, 0.962, 0)
	imageLabel.Position = theme and theme.ImagePosition or UDim2.new(0.554, 0, 0.617, 0)
	imageLabel.ScaleType = theme and theme.ImageScaleType or Enum.ScaleType.Fit
	imageLabel.ImageTransparency = targetTransparency or 0.92
end

local function formatKeyCode(keyCode)
	local text = tostring(keyCode)
	return text:gsub("Enum.KeyCode.", "")
end

local function roundToStep(value, step)
	step = step or 1
	if step == 0 then
		return value
	end
	return math.floor((value / step) + 0.5) * step
end

local function invokeThemeManager(themeManager, methodName, ...)
	if type(themeManager) ~= "table" then
		warn("[UILibrary] ThemeManager is not a table")
		return nil
	end

	local fn = themeManager[methodName]
	if type(fn) ~= "function" then
		warn(string.format("[UILibrary] ThemeManager.%s is missing", tostring(methodName)))
		return nil
	end

	local ok, result = pcall(fn, ...)
	if not ok then
		warn(string.format("[UILibrary] ThemeManager.%s failed: %s", tostring(methodName), tostring(result)))
		return nil
	end

	return result
end

local function getControlRoot(control)
	if type(control) ~= "table" then
		return nil
	end
	return control.Frame or control.Container or control.Instance
end

local function setControlVisible(control, visible)
	local root = getControlRoot(control)
	if root and root:IsA("GuiObject") then
		root.Visible = visible
	end
end

local function color3ToRGB(color)
	return math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5)
end

local function rgbToColor3(r, g, b)
	return Color3.fromRGB(
		math.clamp(math.floor(r + 0.5), 0, 255),
		math.clamp(math.floor(g + 0.5), 0, 255),
		math.clamp(math.floor(b + 0.5), 0, 255)
	)
end

local function bindHoverScale(guiObject, normalSize, hoverSize)
	if not guiObject then return end

	guiObject.MouseEnter:Connect(function()
		TweenService:Create(guiObject, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = hoverSize,
		}):Play()
	end)

	guiObject.MouseLeave:Connect(function()
		TweenService:Create(guiObject, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = normalSize,
		}):Play()
	end)
end

local ThemeManager = {}

local DEBUG = 0

local function themeLog(level, ...)
	if DEBUG < level then return end
	local prefix = "[ThemeManager]"
	if level == 1 then warn(prefix, "ERROR:", ...) return end
	if level == 2 then warn(prefix, "WARN:", ...) return end
	print(prefix, ...)
end

ThemeManager.TweenEnabled = true
ThemeManager.TweenTime = 0.35
ThemeManager.TweenStyle = Enum.EasingStyle.Quad
ThemeManager.TweenDirection = Enum.EasingDirection.Out

local currentTheme = nil
local themeConnections = {}
local themeAttributeConnections = {}
local themedRoots = {}

local activeTweens = {}
local activeGradientTweens = {}

local CLASS_DEFAULT_PROP = {
	Frame = "BackgroundColor3",
	ScrollingFrame = "BackgroundColor3",
	TextButton = "BackgroundColor3",
	ImageButton = "BackgroundColor3",
	TextLabel = "TextColor3",
	TextBox = "TextColor3",
	ViewportFrame = "BackgroundColor3",
	ImageLabel = "ImageColor3",
	UIStroke = "Color",
}

local function cleanToken(v)
	if type(v) ~= "string" then return nil end
	v = v:gsub("^%s*(.-)%s*$", "%1")
	v = v:gsub('^"(.*)"$', "%1")
	v = v:gsub("^'(.*)'$", "%1")
	v = v:gsub("^%s*(.-)%s*$", "%1")
	if v == "" then return nil end
	return v
end

local function trackThemeConn(conn)
	table.insert(themeConnections, conn)
end

local function trackThemeAttrConn(conn)
	table.insert(themeAttributeConnections, conn)
end

local function disconnectThemeAll()
	for _, c in ipairs(themeConnections) do
		c:Disconnect()
	end
	table.clear(themeConnections)

	for _, c in ipairs(themeAttributeConnections) do
		c:Disconnect()
	end
	table.clear(themeAttributeConnections)
end

local function getDefaultPropFor(inst)
	local prop = CLASS_DEFAULT_PROP[inst.ClassName]
	if prop then return prop end
	if inst:IsA("UIStroke") then return "Color" end
	if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then return "ImageColor3" end
	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then return "TextColor3" end
	if inst:IsA("GuiObject") then return "BackgroundColor3" end
	return nil
end

local function getThemeColors()
	if not currentTheme then return nil end
	return currentTheme.Colors
end

local function getThemeGradients()
	if not currentTheme then return nil end
	return currentTheme.Gradients
end

local function getThemeColor(token)
	local colors = getThemeColors()
	if not colors then return nil end
	return colors[token]
end

local function themeTweenInfo()
	return TweenInfo.new(ThemeManager.TweenTime, ThemeManager.TweenStyle, ThemeManager.TweenDirection)
end

local function cancelPropTween(inst, prop)
	local instTweens = activeTweens[inst]
	if not instTweens then return end

	local existing = instTweens[prop]
	if not existing then return end

	existing:Cancel()
	instTweens[prop] = nil

	if next(instTweens) == nil then
		activeTweens[inst] = nil
	end
end

local function tweenProperty(inst, prop, value)
	if not ThemeManager.TweenEnabled then
		local ok, err = pcall(function()
			inst[prop] = value
		end)
		if not ok then themeLog(1, "Failed set", inst:GetFullName(), prop, err) end
		return
	end

	local okRead, current = pcall(function()
		return inst[prop]
	end)
	if not okRead then
		themeLog(1, "Failed read", inst:GetFullName(), prop)
		return
	end

	if current == value then return end
	if typeof(value) == "ColorSequence" then return end

	cancelPropTween(inst, prop)

	local okTween, tw = pcall(function()
		return TweenService:Create(inst, themeTweenInfo(), { [prop] = value })
	end)
	if not okTween or not tw then
		themeLog(1, "Failed tween create", inst:GetFullName(), prop)
		return
	end

	activeTweens[inst] = activeTweens[inst] or {}
	activeTweens[inst][prop] = tw

	tw.Completed:Connect(function()
		local instTweens = activeTweens[inst]
		if instTweens and instTweens[prop] == tw then
			instTweens[prop] = nil
			if next(instTweens) == nil then
				activeTweens[inst] = nil
			end
		end
	end)

	tw:Play()
end

local function lerpColor3(a, b, t)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function readTwoStop(seq)
	local k = seq.Keypoints
	local first = k[1].Value
	local last = k[#k].Value
	return first, last
end

local function stopGradientTween(grad)
	local state = activeGradientTweens[grad]
	if not state then return end
	if state.conn then state.conn:Disconnect() end
	if state.tween then state.tween:Cancel() end
	state.token:Destroy()
	activeGradientTweens[grad] = nil
end

local function tweenGradientColor(grad, targetSeq)
	if not ThemeManager.TweenEnabled then
		grad.Color = targetSeq
		return
	end

	stopGradientTween(grad)

	local fromA, fromB = readTwoStop(grad.Color)
	local toA, toB = readTwoStop(targetSeq)

	local token = Instance.new("NumberValue")
	token.Value = 0

	local state = { token = token, conn = nil, tween = nil }
	activeGradientTweens[grad] = state

	state.conn = RunService.RenderStepped:Connect(function()
		if not grad.Parent then
			stopGradientTween(grad)
			return
		end
		local t = token.Value
		local a = lerpColor3(fromA, toA, t)
		local b = lerpColor3(fromB, toB, t)
		grad.Color = ColorSequence.new(a, b)
	end)

	local tw = TweenService:Create(token, themeTweenInfo(), { Value = 1 })
	state.tween = tw

	tw.Completed:Connect(function()
		if grad.Parent then
			grad.Color = targetSeq
		end
		stopGradientTween(grad)
	end)

	tw:Play()
end

local function buildColorSequence(def)
	if type(def) ~= "table" then return nil end
	local a = def[1]
	local b = def[2]
	if type(a) ~= "string" or type(b) ~= "string" then return nil end
	return ColorSequence.new(Color3.fromHex(a), Color3.fromHex(b))
end

local function applyGradient(grad)
	local key = cleanToken(grad:GetAttribute("ThemeGradient"))
	if not key then return end

	local gradients = getThemeGradients()
	if not gradients then
		themeLog(2, "Theme missing Gradients table")
		return
	end

	local def = gradients[key]
	if not def then
		themeLog(2, "Gradient not found:", key, grad:GetFullName())
		return
	end

	local seq = buildColorSequence(def)
	if not seq then
		themeLog(1, "Invalid gradient def:", key, grad:GetFullName())
		return
	end

	tweenGradientColor(grad, seq)

	local rot = def.Rotation
	if type(rot) == "number" then
		tweenProperty(grad, "Rotation", rot)
	end
end

local function applyRoleToProperty(inst, role, prop)
	local color = getThemeColor(role)
	if not color then
		themeLog(1, "No theme color for role:", role, "at", inst:GetFullName())
		return
	end
	tweenProperty(inst, prop, color)
end

local function applyInstance(inst)
	if inst:IsA("UIGradient") then
		if inst:GetAttribute("ThemeGradient") == nil then return end
		applyGradient(inst)
		return
	end

	local role = cleanToken(inst:GetAttribute("ThemeRole"))
	if not role then return end

	local prop = cleanToken(inst:GetAttribute("ThemeProp"))
	if not prop then
		prop = getDefaultPropFor(inst)
	end
	if not prop then
		themeLog(2, "No default prop for", inst.ClassName, inst:GetFullName())
		return
	end

	applyRoleToProperty(inst, role, prop)
end

local function applyTree(root)
	applyInstance(root)
	for _, inst in ipairs(root:GetDescendants()) do
		applyInstance(inst)
	end
end

local function watchAttributes(inst)
	if inst:IsA("UIGradient") then
		trackThemeAttrConn(inst:GetAttributeChangedSignal("ThemeGradient"):Connect(function()
			applyInstance(inst)
		end))
		return
	end

	trackThemeAttrConn(inst:GetAttributeChangedSignal("ThemeRole"):Connect(function()
		applyInstance(inst)
	end))

	trackThemeAttrConn(inst:GetAttributeChangedSignal("ThemeProp"):Connect(function()
		applyInstance(inst)
	end))
end

function ThemeManager.SetDebugLevel(level)
	DEBUG = math.max(0, math.floor(level))
	themeLog(3, "Debug level set to", DEBUG)
end

function ThemeManager.SetTheme(theme)
	if type(theme) ~= "table" then
		themeLog(1, "SetTheme non-table:", typeof(theme))
		return
	end

	if type(theme.Colors) ~= "table" then
		themeLog(1, "Theme missing .Colors table")
		return
	end

	currentTheme = theme
	themeLog(3, "Theme set")

	for _, root in ipairs(themedRoots) do
		if root and root.Parent then
			applyTree(root)
		end
	end
end

function ThemeManager.BindRoot(root)
	if not root then
		themeLog(1, "BindRoot nil root")
		return
	end

	table.insert(themedRoots, root)
	themeLog(3, "Bound root:", root:GetFullName())

	applyTree(root)

	watchAttributes(root)
	for _, inst in ipairs(root:GetDescendants()) do
		watchAttributes(inst)
	end

	trackThemeConn(root.DescendantAdded:Connect(function(inst)
		watchAttributes(inst)
		applyInstance(inst)
	end))
end

function ThemeManager.UnbindAll()
	disconnectThemeAll()
	table.clear(themedRoots)

	for grad, _ in pairs(activeGradientTweens) do
		stopGradientTween(grad)
	end
end

function ThemeManager.ApplyNow(root)
	if not root then
		themeLog(1, "ApplyNow nil root")
		return
	end
	applyTree(root)
end

function UILibrary.new(options)
	local self = setmetatable({}, UILibrary)
	self.Options = mergeDefaults(options)
	self.ThemeManager = ThemeManager
	self.Themes = self.Options.Themes or self.Options.themes
	assert(self.Themes, "Themes table is required")
	self.PlayerGui = self.Options.Parent or player:WaitForChild("PlayerGui")
	self.ScreenGui = nil
	self.Refs = {}
	self.Pages = {}
	self.TabButtons = {}
	self.Sections = {}
	self.SettingsSections = {}
	self.KeybindObjects = {}
	self.DependencyConnections = {}
	self.Connections = {}
	self.IsOpen = false
	self.IsAnimating = false
	self.ActivePage = nil
	self.ActiveThemeName = self.Options.DefaultTheme
	self._previousFOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
	self._promptDismissed = false

	self:_build()
	self:_bindSignals()
	self:_buildSettingsThemeButtons()
	self:_applyInitialTheme()

	self.Refs.WindowGroup.Position = UDim2.new(0.5, 0, 1.5, 0)
	self.Refs.WindowGroup.GroupTransparency = 0.5
	self.Refs.WindowGroup.Visible = false

	if self.Options.PromptEnabled then
		self:ShowPrompt(true)
	end

	if self.Options.OpenOnStart then
		task.defer(function()
			self:Open(true)
		end)
	end

	return self
end

function UILibrary:_build()
	local screenGui = create("ScreenGui", {
		Name = self.Options.ScreenGuiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = self.PlayerGui,
	})

	local windowGroup = create("CanvasGroup", {
		Name = "WindowGroup",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1.5, 0),
		Size = self.Options.Size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 10,
		GroupTransparency = 0.5,
		Visible = true,
		Parent = screenGui,
	})

	create("UIAspectRatioConstraint", {
		AspectRatio = self.Options.AspectRatio,
		Parent = windowGroup,
	})

	create("UICorner", {
		CornerRadius = UDim.new(0, 10),
		Parent = windowGroup,
	})

	create("UIStroke", {
		Transparency = 0.8,
		Thickness = 2,
		Parent = windowGroup,
		Attributes = {
			ThemeRole = "Stroke",
		},
	})

	create("UIStroke", {
		Transparency = 0.9,
		Thickness = 4.5,
		Parent = windowGroup,
		Attributes = {
			ThemeRole = "Stroke",
		},
	})

	create("UIStroke", {
		Parent = windowGroup,
		Attributes = {
			ThemeRole = "Accent",
		},
	})

	local root = create("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.02,
		Parent = windowGroup,
		Attributes = {
			ThemeRole = "Panel",
		},
	})

	create("UIGradient", {
		Rotation = 45,
		Parent = root,
		Attributes = {
			ThemeGradient = "PanelGradient",
		},
	})

	local backgroundNoise = create("ImageLabel", {
		Name = "Noise",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "rbxassetid://130815752026252",
		ImageTransparency = 0.98,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = root,
	})

	local backgroundImage = create("ImageLabel", {
		Name = "BackgroundImage",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.554, 0, 0.617, 0),
		Size = UDim2.new(0.904, 0, 0.962, 0),
		ScaleType = Enum.ScaleType.Fit,
		ImageTransparency = self.Options.BackgroundImageTransparency,
		Image = DEFAULT_THEME_IMAGE,
		Parent = root,
	})

	local topPanel = create("Frame", {
		Name = "TopBar",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.047, 0),
		Size = UDim2.new(1, 0, 0.094, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.3,
		Parent = root,
		Attributes = {
			ThemeRole = "Panel",
		},
	})

	local title = create("TextLabel", {
		Name = "TitleLabel",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.078, 0, 0.25, 0),
		Size = UDim2.new(0.16, 0, 0.5, 0),
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = self.Options.WindowTitle,
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = topPanel,
		Attributes = {
			ThemeRole = "Text",
		},
	})

	local versionChip = create("Frame", {
		Name = "VersionChip",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.235, 0, 0.5, 0),
		Size = UDim2.new(0.07, 0, 0.4, 0),
		BorderSizePixel = 0,
		Parent = topPanel,
		Attributes = {
			ThemeRole = "Surface2",
		},
	})
	create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = versionChip })

	local versionText = create("TextLabel", {
		Name = "VersionText",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.8, 0, 0.6, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = self.Options.VersionText,
		TextScaled = true,
		TextWrapped = true,
		Parent = versionChip,
		Attributes = {
			ThemeRole = "TextMuted",
		},
	})

	local infoFrame = create("Frame", {
		Name = "InfoFrame",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.47, 0, 0.5, 0),
		Size = UDim2.new(0.31, 0, 0.65, 0),
		BorderSizePixel = 0,
		Parent = topPanel,
		Attributes = {
			ThemeRole = "Surface",
		},
	})
	create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = infoFrame })

	local serverText = create("TextLabel", {
		Name = "ServerText",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.06, 0, 0.28, 0),
		Size = UDim2.new(0.2, 0, 0.44, 0),
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = "Server:",
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = infoFrame,
		Attributes = {
			ThemeRole = "Text",
		},
	})

	local serverId = create("TextLabel", {
		Name = "ServerId",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.27, 0, 0.28, 0),
		Size = UDim2.new(0.22, 0, 0.44, 0),
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = tostring(game.PlaceId or "Studio"),
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = infoFrame,
		Attributes = {
			ThemeRole = "TextMuted",
		},
	})

	local playersText = create("TextLabel", {
		Name = "PlayersText",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.53, 0, 0.28, 0),
		Size = UDim2.new(0.2, 0, 0.44, 0),
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = "Players:",
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = infoFrame,
		Attributes = {
			ThemeRole = "Text",
		},
	})

	local playerCount = create("TextLabel", {
		Name = "PlayerCount",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.74, 0, 0.28, 0),
		Size = UDim2.new(0.2, 0, 0.44, 0),
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = tostring(#Players:GetPlayers()),
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = infoFrame,
		Attributes = {
			ThemeRole = "TextMuted",
		},
	})

	local settingsButton = create("ImageButton", {
		Name = "SettingsButton",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.91, 0, 0.5, 0),
		Size = UDim2.new(0.024, 0, 0.44, 0),
		Image = "rbxassetid://115032584243979",
		AutoButtonColor = false,
		Parent = topPanel,
		Attributes = {
			ThemeRole = "Accent",
			ThemeProp = "ImageColor3",
		},
	})
	create("UIAspectRatioConstraint", { Parent = settingsButton })

	local closeButton = create("ImageButton", {
		Name = "CloseButton",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.952, 0, 0.5, 0),
		Size = UDim2.new(0.024, 0, 0.44, 0),
		Image = "rbxassetid://73838471832902",
		AutoButtonColor = false,
		Parent = topPanel,
		Attributes = {
			ThemeRole = "Accent",
			ThemeProp = "ImageColor3",
		},
	})
	create("UIAspectRatioConstraint", { Parent = closeButton })

	local sidebar = create("Frame", {
		Name = "Sidebar",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.136, 0, 0.547, 0),
		Size = UDim2.new(0.272, 0, 0.906, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = root,
	})

	local tabList = create("ScrollingFrame", {
		Name = "TabList",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Active = true,
		Parent = sidebar,
	})

	create("UIPadding", {
		PaddingTop = UDim.new(0.025, 0),
		Parent = tabList,
	})

	local tabLayout = create("UIListLayout", {
		Padding = UDim.new(0.025, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabList,
	})

	local divider = create("Frame", {
		Name = "Divider",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.00342, 0, 0.4996, 0),
		Size = UDim2.new(0.003, 0, 1, 0),
		BorderSizePixel = 0,
		Parent = root,
		Attributes = {
			ThemeRole = "Divider",
		},
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = divider })

	local contentRoot = create("Frame", {
		Name = "ContentRoot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.636, 0, 0.547, 0),
		Size = UDim2.new(0.728, 0, 0.906, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = root,
	})

	local pages = create("Folder", {
		Name = "Pages",
		Parent = contentRoot,
	})

	local overlayContainer = create("Folder", {
		Name = "Overlays",
		Parent = contentRoot,
	})

	local notificationContainer = create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.16, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = screenGui,
	})
	create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		Parent = notificationContainer,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notificationContainer,
	})

	local tooltipContainer = create("Folder", {
		Name = "Tooltips",
		Parent = screenGui,
	})

	local popupContainer = create("Folder", {
		Name = "Popups",
		Parent = screenGui,
	})

	local keybindOverlay = create("CanvasGroup", {
		Name = "KeybindOverlay",
		Visible = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0.985, 0, 0.5, 0),
		Size = UDim2.new(0, 220, 0, 260),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = screenGui,
	})
	local keybindOverlayBg = create("Frame", {
		Name = "Background",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Parent = keybindOverlay,
		Attributes = {
			ThemeRole = "Surface",
		},
	})
	create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = keybindOverlayBg })
	create("UIStroke", {
		Transparency = 0.45,
		Parent = keybindOverlayBg,
		Attributes = { ThemeRole = "Stroke" },
	})
	create("TextLabel", {
		Name = "Header",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0, 10),
		Size = UDim2.new(1, -24, 0, 18),
		Text = "Keybinds",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Parent = keybindOverlayBg,
		Attributes = { ThemeRole = "Text" },
	})
	local keybindOverlayList = create("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0, 34),
		Size = UDim2.new(1, -20, 1, -44),
		Parent = keybindOverlayBg,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = keybindOverlayList,
	})

	local prompt = create("CanvasGroup", {
		Name = "Prompt",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1.5, 0),
		Size = UDim2.new(0, 360, 0, 74),
		BorderSizePixel = 0,
		GroupTransparency = 0,
		Parent = screenGui,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = prompt })
	create("UIStroke", {
		ZIndex = 4,
		Transparency = 0.2,
		Thickness = 1.5,
		Parent = prompt,
		Attributes = {
			ThemeRole = "Accent",
		},
	})
	create("UIStroke", {
		Transparency = 0.82,
		Thickness = 4,
		Parent = prompt,
		Attributes = {
			ThemeRole = "Stroke",
		},
	})

	local promptBg = create("Frame", {
		Name = "Background",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.02,
		Parent = prompt,
		Attributes = {
			ThemeRole = "Surface",
		},
	})
	create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = promptBg })
	create("UIGradient", {
		Parent = promptBg,
		Attributes = {
			ThemeGradient = "PanelGradient",
		},
	})
	create("ImageLabel", {
		Name = "Noise",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "rbxassetid://130815752026252",
		ImageTransparency = 0.985,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Parent = promptBg,
	})
	create("ImageLabel", {
		Name = "Vignette",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "rbxassetid://79954606936794",
		ImageTransparency = 0.86,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		Parent = promptBg,
		Attributes = {
			ThemeRole = "Surface2",
			ThemeProp = "ImageColor3",
		},
	})

	local promptKey = create("Frame", {
		Name = "KeyChip",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.new(0, 72, 0, 44),
		BorderSizePixel = 0,
		Parent = promptBg,
		Attributes = {
			ThemeRole = "Surface2",
		},
	})
	create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = promptKey })
	create("UIStroke", {
		Transparency = 0.45,
		Parent = promptKey,
		Attributes = { ThemeRole = "Stroke" },
	})
	create("UIGradient", {
		Parent = promptKey,
		Attributes = {
			ThemeGradient = "SurfaceGradient",
		},
	})
	local promptKeyText = create("TextLabel", {
		Name = "KeyText",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.86, 0, 0.7, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = "RSHIFT",
		TextSize = 16,
		Parent = promptKey,
		Attributes = {
			ThemeRole = "Accent",
		},
	})

	local promptText = create("TextLabel", {
		Name = "PromptText",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 100, 0.38, 0),
		Size = UDim2.new(1, -114, 0, 20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = self.Options.PromptText,
		TextSize = 17,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = promptBg,
		Attributes = {
			ThemeRole = "Text",
		},
	})

	local promptSubtext = create("TextLabel", {
		Name = "PromptSubtext",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 100, 0.68, 0),
		Size = UDim2.new(1, -114, 0, 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Text = "Open the menu once to remove.",
		TextSize = 13,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = promptBg,
		Attributes = {
			ThemeRole = "TextMuted",
		},
	})

	local tabTemplate = self:_createTabTemplate()
	local sectionTemplate = self:_createSectionTemplate()
	local themeButtonTemplate = self:_createThemeButtonTemplate()

	self.ScreenGui = screenGui
	self.Refs = {
		ScreenGui = screenGui,
		WindowGroup = windowGroup,
		Root = root,
		TopBar = topPanel,
		TitleLabel = title,
		VersionText = versionText,
		InfoFrame = infoFrame,
		ServerId = serverId,
		PlayerCount = playerCount,
		Sidebar = sidebar,
		TabList = tabList,
		TabLayout = tabLayout,
		Divider = divider,
		ContentRoot = contentRoot,
		Pages = pages,
		OverlayContainer = overlayContainer,
		SettingsButton = settingsButton,
		CloseButton = closeButton,
		BackgroundImage = backgroundImage,
		BackgroundNoise = backgroundNoise,
		Prompt = prompt,
		PromptBackground = promptBg,
		PromptText = promptText,
		PromptSubtext = promptSubtext,
		PromptKeyText = promptKeyText,
		Notifications = notificationContainer,
		Tooltips = tooltipContainer,
		Popups = popupContainer,
		KeybindOverlay = keybindOverlay,
		KeybindOverlayList = keybindOverlayList,
		Templates = {
			TabButton = tabTemplate,
			Section = sectionTemplate,
			ThemeButton = themeButtonTemplate,
		},
	}

	local settingsPage = self:CreatePage({
		Name = "Settings",
		Id = "__settings",
		Hidden = true,
		LayoutOrder = 9999,
	})
	self.Refs.SettingsPage = settingsPage.Frame

	local settingsHeader = settingsPage:AddSection({
		Name = "Settings",
		Description = "Change the look and feel of the library.",
	})
	settingsHeader.Container.Name = "SettingsIntro"
	self.Refs.SettingsIntroSection = settingsHeader.Container

	local themeSection = settingsPage:AddSection({
		Name = "Theme",
		Description = "Pick a theme below.",
	})
	self.Refs.ThemeSelector = themeSection.Content
	self.Refs.ThemeSection = themeSection.Container
	self.Refs.SettingsPageObject = settingsPage
	self.SettingsSections.General = settingsHeader
	self.SettingsSections.Theme = themeSection
end

function UILibrary:GetSettingsPage()
	return self.Refs.SettingsPageObject
end

function UILibrary:GetSettingsSection(name)
	if not name then
		return self.SettingsSections
	end
	return self.SettingsSections[name]
end

function UILibrary:AddSettingsSection(sectionConfig)
	sectionConfig = sectionConfig or {}
	local page = self:GetSettingsPage()
	assert(page, "Settings page has not been created")

	local section = page:AddSection({
		Name = sectionConfig.Name or "Settings Section",
		Description = sectionConfig.Description or "",
	})
	if sectionConfig.Id then
		section.Container.Name = sectionConfig.Id
	end

	section.Container:SetAttribute("ThemeRole", "Surface")
	if section.Container:FindFirstChild("UIStroke") then
		section.Container.UIStroke:SetAttribute("ThemeRole", "Stroke")
	end
	if section.Header then
		section.Header:SetAttribute("ThemeRole", "Text")
	end
	if section.Description then
		section.Description:SetAttribute("ThemeRole", "TextMuted")
	end

	self.SettingsSections[sectionConfig.Key or sectionConfig.Name or section.Container.Name] = section
	if self.ThemeManager then
		invokeThemeManager(self.ThemeManager, "ApplyNow", section.Container)
	end
	return section
end

function UILibrary:AddToSettings(controlType, config)
	assert(type(controlType) == "string", "AddToSettings requires a control type")
	config = config or {}

	local section = config.Section
	if type(section) == "string" then
		section = self:GetSettingsSection(section)
	elseif section == nil then
		section = self:GetSettingsSection("General")
	end

	assert(section, "Settings section not found")
	local method = section["Add" .. controlType]
	assert(type(method) == "function", "Unsupported settings control: " .. tostring(controlType))
	return method(section, config)
end

function UILibrary:_createTabTemplate()
	local button = create("TextButton", {
		Name = "TabButtonTemplate",
		Visible = false,
		AutoButtonColor = false,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.new(0.9, 0, 0, 42),
		Text = "",
		Parent = self.Refs and self.Refs.TabList or nil,
		Attributes = {
			ThemeRole = "Surface",
		},
	})
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = button })
	create("UIStroke", {
		Transparency = 0.55,
		Parent = button,
		Attributes = { ThemeRole = "Stroke" },
	})

	create("Frame", {
		Name = "AccentBar",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.03, 0, 0.5, 0),
		Size = UDim2.new(0, 4, 0.6, 0),
		BorderSizePixel = 0,
		Parent = button,
		Attributes = {
			ThemeRole = "Accent",
		},
	})

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.09, 0, 0.5, 0),
		Size = UDim2.new(0.8, 0, 0.55, 0),
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = "Tab",
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = button,
		Attributes = {
			ThemeRole = "Text",
		},
	})

	return button
end

function UILibrary:_createSectionTemplate()
	local section = create("Frame", {
		Name = "SectionTemplate",
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Attributes = {
			ThemeRole = "Surface",
		},
	})
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = section })
	create("UIStroke", {
		Transparency = 0.6,
		Parent = section,
		Attributes = { ThemeRole = "Stroke" },
	})
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		Parent = section,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = section,
	})
	create("TextLabel", {
		Name = "Header",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "Section",
		TextSize = 18,
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = section,
		Attributes = { ThemeRole = "Text" },
	})
	create("TextLabel", {
		Name = "Description",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		TextSize = 14,
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = section,
		Attributes = { ThemeRole = "TextMuted" },
	})
	local content = create("Frame", {
		Name = "Content",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = section,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = content,
	})
	return section
end

function UILibrary:_createThemeButtonTemplate()
	local button = create("Frame", {
		Name = "ThemeButtonTemplate",
		Visible = false,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 150, 0, 42),
		Attributes = {
			ThemeRole = "Surface2",
		},
	})
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = button })
	create("UIStroke", {
		Transparency = 0.6,
		Parent = button,
		Attributes = { ThemeRole = "Stroke" },
	})

	local hitbox = create("TextButton", {
		Name = "Hitbox",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = button,
	})

	create("TextLabel", {
		Name = "ThemeText",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.82, 0, 0.55, 0),
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = "Theme",
		TextSize = 16,
		TextWrapped = true,
		Parent = button,
		Attributes = { ThemeRole = "Text" },
	})

	return button
end

function UILibrary:_createPageFrame(pageId)
	local page = create("CanvasGroup", {
		Name = pageId,
		Visible = false,
		GroupTransparency = 1,
		Position = UDim2.new(0.5, 0, 1.15, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = self.Refs.Pages,
	})

	local scroll = create("ScrollingFrame", {
		Name = "Scroll",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		Parent = page,
		Attributes = {
			ThemeRole = "Surface",
		},
	})

	create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = scroll,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroll,
	})

	return page, scroll
end

function UILibrary:CreatePage(config)
	config = config or {}
	local pageId = config.Id or (config.Name or ("Page" .. tostring(#self.Pages + 1)))
	local pageFrame, scroll = self:_createPageFrame(pageId)

	local pageObject = {}
	pageObject.Id = pageId
	pageObject.Name = config.Name or pageId
	pageObject.Hidden = config.Hidden == true
	pageObject.Frame = pageFrame
	pageObject.Scroll = scroll
	pageObject.Library = self
	pageObject.Sections = {}

	function pageObject:AddSection(sectionConfig)
		sectionConfig = sectionConfig or {}
		local section = self.Library.Refs.Templates.Section:Clone()
		section.Name = sectionConfig.Id or sectionConfig.Name or ("Section" .. tostring(#self.Sections + 1))
		section.Visible = true
		section.LayoutOrder = sectionConfig.LayoutOrder or (#self.Sections + 1)
		section.Parent = self.Scroll

		section.Header.Text = sectionConfig.Name or "Section"
		section.Header.Active = true
		section.Description.Text = sectionConfig.Description or ""
		section.Description.Visible = section.Description.Text ~= ""

		local sectionObj = {
			Container = section,
			Content = section.Content,
			Header = section.Header,
			Description = section.Description,
			Page = self,
			Library = self.Library,
		}
		
		sectionObj.Collapsed = false

		function sectionObj:SetCollapsed(collapsed, instant)
			self.Collapsed = collapsed == true

			if self.Collapsed then
				if instant then
					self.Content.Visible = false
					if self.Description then
						self.Description.Visible = false
					end
				else
					TweenService:Create(self.Content, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 1,
					}):Play()
					task.delay(0.18, function()
						if self.Content then
							self.Content.Visible = false
						end
						if self.Description then
							self.Description.Visible = false
						end
					end)
				end
			else
				self.Content.Visible = true
				if self.Description and self.Description.Text ~= "" then
					self.Description.Visible = true
				end
			end
		end
		
		section.Header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				sectionObj:SetCollapsed(not sectionObj.Collapsed)
			end
		end)

		function sectionObj:AddFrame(childConfig)
			childConfig = childConfig or {}
			local frame = create("Frame", {
				Name = childConfig.Name or "Item",
				AutomaticSize = childConfig.AutomaticSize or Enum.AutomaticSize.None,
				Size = childConfig.Size or UDim2.new(1, 0, 0, childConfig.Height or 40),
				BackgroundTransparency = childConfig.BackgroundTransparency == nil and self.Library.Options.ContentItemTransparency or childConfig.BackgroundTransparency,
				BorderSizePixel = 0,
				ClipsDescendants = childConfig.ClipsDescendants == true,
				Parent = self.Content,
				Attributes = childConfig.Attributes or {
					ThemeRole = "Surface2",
				},
			})
			create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
			if childConfig.Stroke ~= false then
				create("UIStroke", {
					Transparency = childConfig.StrokeTransparency or 0.6,
					Parent = frame,
					Attributes = {
						ThemeRole = childConfig.StrokeRole or "Stroke",
					},
				})
			end
			return frame
		end
		
		function sectionObj:AddSearchBox(config)
			config = config or {}

			local input = self:AddTextbox({
				Name = config.Name or "Search",
				Placeholder = config.Placeholder or "Search...",
			})

			input.Input:GetPropertyChangedSignal("Text"):Connect(function()
				local query = string.lower(input.Input.Text)

				for _, child in ipairs(self.Content:GetChildren()) do
					if child:IsA("Frame") then
						local name = string.lower(child.Name or "")
						child.Visible = query == "" or string.find(name, query)
					end
				end
			end)

			return input
		end
		
		function sectionObj:AddSearchBox(childConfig)
			childConfig = childConfig or {}

			local searchObj = self:AddTextbox({
				Name = childConfig.Name or "Search",
				Placeholder = childConfig.Placeholder or "Search...",
				Default = childConfig.Default or "",
			})

			local searchFrame = searchObj.Frame
			searchFrame:SetAttribute("IsSearchBox", true)

			local function getSearchText(guiObject)
				local parts = {}

				table.insert(parts, string.lower(guiObject.Name or ""))

				for _, desc in ipairs(guiObject:GetDescendants()) do
					if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
						table.insert(parts, string.lower(desc.Text or ""))
					end
				end

				return table.concat(parts, " ")
			end

			local function applySearch()
				local query = string.lower(searchObj.Input.Text or "")

				for _, child in ipairs(self.Content:GetChildren()) do
					if child:IsA("GuiObject") then
						if child == searchFrame then
							child.Visible = true
						else
							local haystack = getSearchText(child)
							local matches = query == "" or string.find(haystack, query, 1, true) ~= nil
							child.Visible = matches
						end
					end
				end
			end

			searchObj.Input:GetPropertyChangedSignal("Text"):Connect(applySearch)
			applySearch()

			return searchObj
		end

		function sectionObj:AddLabel(childConfig)
			childConfig = childConfig or {}
			local label = create("TextLabel", {
				Name = childConfig.Id or childConfig.Name or "Label",
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = childConfig.Text or childConfig.Name or "Label",
				TextSize = childConfig.TextSize or 15,
				TextWrapped = true,
				TextXAlignment = childConfig.TextXAlignment or Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Parent = self.Content,
				Attributes = {
					ThemeRole = childConfig.ThemeRole or "Text",
				},
			})
			return {
				Instance = label,
				SetText = function(_, value)
					label.Text = tostring(value)
				end,
			}
		end

		function sectionObj:AddParagraph(childConfig)
			childConfig = childConfig or {}
			local frame = self:AddFrame({
				Name = childConfig.Id or childConfig.Name or "Paragraph",
				Height = childConfig.Height or 72,
			})

			local title = create("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.new(0.04, 0, 0.18, 0),
				Size = UDim2.new(0.92, 0, 0, 18),
				Text = childConfig.Name or "Paragraph",
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Parent = frame,
				Attributes = { ThemeRole = "Text" },
			})

			local body = create("TextLabel", {
				Name = "Body",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.new(0.04, 0, 0.46, 0),
				Size = UDim2.new(0.92, 0, 0, 28),
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				Text = childConfig.Text or childConfig.Description or "",
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Parent = frame,
				Attributes = { ThemeRole = "TextMuted" },
			})

			return {
				Frame = frame,
				Title = title,
				Body = body,
				SetText = function(_, value)
					body.Text = tostring(value)
				end,
			}
		end

		function sectionObj:AddButton(childConfig)
			childConfig = childConfig or {}
			local frame = self:AddFrame({
				Name = childConfig.Id or childConfig.Name or "Button",
				Height = childConfig.Height or 44,
				BackgroundTransparency = childConfig.ContainerTransparency == nil and self.Library.Options.ContentItemTransparency or childConfig.ContainerTransparency,
			})

			local initialButtonTransparency = childConfig.ButtonTransparency == nil and self.Library.Options.ButtonTransparency or childConfig.ButtonTransparency
			local button = create("TextButton", {
				Name = "Button",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0.96, 0, 0, 32),
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				Parent = frame,
				BackgroundTransparency = initialButtonTransparency,
				Attributes = {
					ThemeRole = childConfig.Role or "Surface3",
				},
			})
			create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = button })
			create("UIStroke", {
				Transparency = 0.55,
				Parent = button,
				Attributes = { ThemeRole = "Stroke" },
			})

			local label = create("TextLabel", {
				Name = "Label",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0.92, 0, 0.7, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = childConfig.Name or "Button",
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Center,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Parent = button,
				Attributes = { ThemeRole = "Text" },
			})
			
			if childConfig.Tooltip then
				self.Library:BindTooltip(button, childConfig.Tooltip)
			end

			local baseButtonTransparency = initialButtonTransparency
			local hoverButtonTransparency = math.clamp(baseButtonTransparency - 0.12, 0, 1)

			button.MouseEnter:Connect(function()
				TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = hoverButtonTransparency,
				}):Play()
			end)

			button.MouseLeave:Connect(function()
				TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = baseButtonTransparency,
				}):Play()
			end)

			button.MouseButton1Click:Connect(function()
				local mousePos = UserInputService:GetMouseLocation()
				button.ClipsDescendants = true
				createRipple(button, mousePos.X, mousePos.Y)
				safeCallback(childConfig.Callback)
			end)

			return {
				Frame = frame,
				Button = button,
				Label = label,
				SetText = function(_, value)
					label.Text = tostring(value)
				end,
			}
		end

		function sectionObj:AddToggle(childConfig)
			childConfig = childConfig or {}
			local state = childConfig.Default == true

			local frame = self:AddFrame({
				Name = childConfig.Id or childConfig.Name or "Toggle",
				Height = childConfig.Height or 44,
			})

			local label = create("TextLabel", {
				Name = "ToggleText",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0.04, 0, 0.5, 0),
				Size = UDim2.new(0.58, 0, 0.6, 0),
				Text = childConfig.Name or "Toggle",
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Parent = frame,
				Attributes = { ThemeRole = "Text" },
			})

			local track = create("Frame", {
				Name = "Track",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.96, 0, 0.5, 0),
				Size = UDim2.new(0, 58, 0, 24),
				BorderSizePixel = 0,
				Parent = frame,
				Attributes = { ThemeRole = "Accent" },
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
			create("UIStroke", { Transparency = 0.55, Parent = track, Attributes = { ThemeRole = "Stroke" } })

			local knob = create("Frame", {
				Name = "Knob",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.new(0, 20, 0, 20),
				BorderSizePixel = 0,
				Parent = track,
				Attributes = { ThemeRole = state and "Success" or "Danger" },
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

			local button = create("TextButton", {
				Name = "Hitbox",
				BackgroundTransparency = 1,
				Text = "",
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = track,
			})

			local toggleObj = {}

			local function render(skipCallback)
				TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				}):Play()
				knob:SetAttribute("ThemeRole", state and "Success" or "Danger")
				if toggleObj.Library and toggleObj.Library.ThemeManager then
					invokeThemeManager(toggleObj.Library.ThemeManager, "ApplyNow", knob)
				end
				if not skipCallback then
					safeCallback(childConfig.Callback, state)
				end
			end

			function toggleObj:SetValue(value, skipCallback)
				state = value == true
				render(skipCallback)
			end

			function toggleObj:GetValue()
				return state
			end

			toggleObj.Frame = frame
			toggleObj.Track = track
			toggleObj.Knob = knob
			toggleObj.Label = label
			toggleObj.Library = self.Library

			button.MouseButton1Click:Connect(function()
				toggleObj:SetValue(not state)
			end)

			render(true)

			return toggleObj
		end

		function sectionObj:AddSlider(childConfig)
			childConfig = childConfig or {}
			local minValue = childConfig.Min or 0
			local maxValue = childConfig.Max or 100
			local increment = childConfig.Increment or childConfig.Step or 1
			local value = childConfig.Default
			if value == nil then
				value = minValue
			end
			value = math.clamp(roundToStep(value, increment), minValue, maxValue)

			local frame = self:AddFrame({
				Name = childConfig.Id or childConfig.Name or "Slider",
				Height = childConfig.Height or 50,
			})

			local label = create("TextLabel", {
				Name = "SliderText",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0.04, 0, 0.5, 0),
				Size = UDim2.new(0.38, 0, 0.6, 0),
				Text = childConfig.Name or "Slider",
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Parent = frame,
				Attributes = { ThemeRole = "Text" },
			})

			local valueLabel = create("TextLabel", {
				Name = "ValueLabel",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.96, 0, 0.28, 0),
				Size = UDim2.new(0, 68, 0, 14),
				Text = tostring(value),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Parent = frame,
				Attributes = { ThemeRole = "TextMuted" },
			})

			local track = create("Frame", {
				Name = "Track",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.96, 0, 0.68, 0),
				Size = UDim2.new(0.52, 0, 0, 10),
				BorderSizePixel = 0,
				Parent = frame,
				Attributes = { ThemeRole = "Surface3" },
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
			create("UIStroke", { Transparency = 0.55, Parent = track, Attributes = { ThemeRole = "Stroke" } })

			local fill = create("Frame", {
				Name = "Fill",
				Size = UDim2.new(0.01, 0, 1, 0),
				BorderSizePixel = 0,
				Parent = track,
				Attributes = { ThemeRole = "Accent" },
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

			local knob = create("Frame", {
				Name = "Knob",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16),
				BorderSizePixel = 0,
				Parent = track,
				Attributes = { ThemeRole = "Danger" },
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

			local hitbox = create("TextButton", {
				Name = "Hitbox",
				BackgroundTransparency = 1,
				Text = "",
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = track,
			})

			local dragging = false
			local sliderObj = {}

			local function alphaFromValue(v)
				if maxValue == minValue then
					return 0
				end
				return math.clamp((v - minValue) / (maxValue - minValue), 0, 1)
			end

			local function valueFromAlpha(alpha)
				local raw = minValue + ((maxValue - minValue) * alpha)
				return math.clamp(roundToStep(raw, increment), minValue, maxValue)
			end

			local function render(skipCallback)
				local alpha = alphaFromValue(value)
				valueLabel.Text = tostring(value)
				TweenService:Create(fill, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(math.max(alpha, 0.01), 0, 1, 0),
				}):Play()
				TweenService:Create(knob, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(alpha, 0, 0.5, 0),
				}):Play()
				if not skipCallback then
					safeCallback(childConfig.Callback, value)
				end
			end
			
			function sectionObj:AddProgressBar(childConfig)
				childConfig = childConfig or {}
				local value = math.clamp(childConfig.Value or 0, 0, 1)

				local frame = self:AddFrame({
					Name = childConfig.Id or childConfig.Name or "ProgressBar",
					Height = childConfig.Height or 42,
				})

				local label = create("TextLabel", {
					Name = "Label",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0, 0.5),
					TextSize = 15,
					Position = UDim2.new(0.04, 0, 0.25, 0),
					Size = UDim2.new(0.92, 0, 0, 14),
					Text = childConfig.Name or "Progress",
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = frame,
					Attributes = { ThemeRole = "Text" },
				})

				local track = create("Frame", {
					Name = "Track",
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 0.86, 0),
					Size = UDim2.new(0.92, 0, 0, 10),
					BorderSizePixel = 0,
					Parent = frame,
					Attributes = { ThemeRole = "Surface3" },
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

				local fill = create("Frame", {
					Name = "Fill",
					Size = UDim2.new(value, 0, 1, 0),
					BorderSizePixel = 0,
					Parent = track,
					Attributes = { ThemeRole = "Accent" },
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

				local valueText = create("TextLabel", {
					Name = "ValueText",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(0.96, 0, 0.28, 0),
					Size = UDim2.new(0, 50, 0, 14),
					Text = string.format("%d%%", math.floor(value * 100)),
					FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = frame,
					Attributes = { ThemeRole = "TextMuted" },
				})

				local progressObj = {
					Frame = frame,
					Track = track,
					Fill = fill,
					Label = label,
					ValueText = valueText,
				}

				function progressObj:SetValue(newValue)
					value = math.clamp(newValue or 0, 0, 1)
					valueText.Text = string.format("%d%%", math.floor(value * 100))
					TweenService:Create(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(value, 0, 1, 0),
					}):Play()
				end

				function progressObj:GetValue()
					return value
				end

				return progressObj
			end

			local function setFromInput(xPos, skipCallback)
				local absolutePos = track.AbsolutePosition.X
				local absoluteSize = track.AbsoluteSize.X
				if absoluteSize <= 0 then
					return
				end
				local alpha = math.clamp((xPos - absolutePos) / absoluteSize, 0, 1)
				value = valueFromAlpha(alpha)
				render(skipCallback)
			end

			function sliderObj:SetValue(newValue, skipCallback)
				value = math.clamp(roundToStep(newValue, increment), minValue, maxValue)
				render(skipCallback)
			end

			function sliderObj:GetValue()
				return value
			end

			sliderObj.Frame = frame
			sliderObj.Track = track
			sliderObj.Fill = fill
			sliderObj.Knob = knob
			sliderObj.Label = label
			sliderObj.ValueLabel = valueLabel

			hitbox.MouseButton1Down:Connect(function()
				dragging = true
				local location = UserInputService:GetMouseLocation()
				setFromInput(location.X, false)
			end)

			table.insert(self.Library.Connections, UserInputService.InputChanged:Connect(function(input)
				if not dragging then return end
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					setFromInput(input.Position.X, false)
				end
			end))

			table.insert(self.Library.Connections, UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end))

			render(true)

			return sliderObj
		end

		function sectionObj:AddTextbox(childConfig)
			childConfig = childConfig or {}
			local frame = self:AddFrame({
				Name = childConfig.Id or childConfig.Name or "Textbox",
				Height = childConfig.Height or 44,
			})

			local label = create("TextLabel", {
				Name = "Label",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0.04, 0, 0.5, 0),
				Size = UDim2.new(0.38, 0, 0.6, 0),
				Text = childConfig.Name or "Textbox",
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Parent = frame,
				Attributes = { ThemeRole = "Text" },
			})

			local bg = create("Frame", {
				Name = "InputBackground",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.96, 0, 0.5, 0),
				Size = UDim2.new(0.48, 0, 0, 28),
				BorderSizePixel = 0,
				Parent = frame,
				Attributes = { ThemeRole = "Surface3" },
			})
			create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = bg })
			create("UIStroke", { Transparency = 0.55, Parent = bg, Attributes = { ThemeRole = "Stroke" } })

			local input = create("TextBox", {
				Name = "Input",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0.92, 0, 0.8, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = childConfig.Default or "",
				PlaceholderText = childConfig.Placeholder or "",
				ClearTextOnFocus = false,
				TextSize = 14,
				Parent = bg,
				Attributes = { ThemeRole = "Text", ThemeProp = "TextColor3" },
			})

			local function fire(submitted)
				safeCallback(childConfig.Callback, input.Text, submitted)
			end
			
			input.Focused:Connect(function()
				TweenService:Create(bg, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0.5,
				}):Play()
			end)

			input.FocusLost:Connect(function(enterPressed)
				TweenService:Create(bg, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0,
				}):Play()
				fire(enterPressed)
			end)

			input.FocusLost:Connect(function(enterPressed)
				fire(enterPressed)
			end)

			return {
				Frame = frame,
				Input = input,
				SetText = function(_, value)
					input.Text = tostring(value)
				end,
				GetText = function()
					return input.Text
				end,
			}
		end

		function sectionObj:AddDropdown(childConfig)
			childConfig = childConfig or {}
			local items = childConfig.Items or childConfig.Options or {}
			local selected = childConfig.Default or items[1] or "Select"
			local isOpen = false
			local closeWatcher = nil

			local frame = self:AddFrame({
				Name = childConfig.Id or childConfig.Name or "Dropdown",
				Height = childConfig.Height or 44,
				ClipsDescendants = false,
			})

			local label = create("TextLabel", {
				Name = "Label",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0.04, 0, 0.5, 0),
				Size = UDim2.new(0.36, 0, 0.6, 0),
				Text = childConfig.Name or "Dropdown",
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Parent = frame,
				Attributes = { ThemeRole = "Text" },
			})

			local button = create("TextButton", {
				Name = "Button",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.96, 0, 0.5, 0),
				Size = UDim2.new(0.48, 0, 0, 28),
				Text = "",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Parent = frame,
				Attributes = { ThemeRole = "Surface3" },
			})
			create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = button })
			create("UIStroke", { Transparency = 0.55, Parent = button, Attributes = { ThemeRole = "Stroke" } })

			local buttonText = create("TextLabel", {
				Name = "ValueText",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0.08, 0, 0.5, 0),
				Size = UDim2.new(0.74, 0, 0.7, 0),
				Text = tostring(selected),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = button,
				Attributes = { ThemeRole = "Text" },
			})

			local arrow = create("TextLabel", {
				Name = "Arrow",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.92, 0, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16),
				Text = "▼",
				TextSize = 12,
				Parent = button,
				Attributes = { ThemeRole = "TextMuted" },
			})

			local backdrop = create("TextButton", {
				Name = "DropdownBackdrop",
				Visible = false,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 49,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = self.Library.Refs.Popups or self.Library.ScreenGui,
			})

			local popup = create("Frame", {
				Name = "DropdownPopup_" .. tostring(frame.Name),
				Visible = false,
				BorderSizePixel = 0,
				BackgroundTransparency = 0.04,
				ZIndex = 50,
				Size = UDim2.fromOffset(0, 0),
				Parent = self.Library.Refs.Popups or self.Library.ScreenGui,
				Attributes = { ThemeRole = "Surface3" },
			})
			create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = popup })
			create("UIStroke", { Transparency = 0.45, Parent = popup, Attributes = { ThemeRole = "Stroke" } })
			create("UIPadding", {
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
				Parent = popup,
			})
			local searchBg = create("Frame", {
				Name = "SearchBackground",
				Size = UDim2.new(1, 0, 0, 24),
				BorderSizePixel = 0,
				ZIndex = 51,
				Parent = popup,
				Attributes = { ThemeRole = "Surface2" },
			})
			create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = searchBg })
			create("UIStroke", {
				Transparency = 0.55,
				Parent = searchBg,
				Attributes = { ThemeRole = "Stroke" },
			})

			local searchBox = create("TextBox", {
				Name = "SearchBox",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0.92, 0, 0.8, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				PlaceholderText = "Search...",
				ClearTextOnFocus = false,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 52,
				Parent = searchBg,
				Attributes = { ThemeRole = "Text", ThemeProp = "TextColor3" },
			})
			local popupLayout = create("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = popup,
			})

			local optionButtons = {}
			local optionMap = {}
			
			local dropdownObj = {}

			local function cleanupWatcher()
				if closeWatcher then
					closeWatcher:Disconnect()
					closeWatcher = nil
				end
			end

			local function popupHeight()
				local count = #items
				return math.max(0, (count * 24) + math.max(0, count - 1) * 4 + 12)
			end

			local function repositionPopup()
				local pos = button.AbsolutePosition
				local size = button.AbsoluteSize
				popup.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 6)
				popup.Size = UDim2.fromOffset(size.X, popupHeight())
			end

			local function setOpen(open)
				isOpen = open == true
				arrow.Text = isOpen and "▲" or "▼"

				if isOpen then
					repositionPopup()
					backdrop.Visible = true
					popup.Visible = true
					popup.BackgroundTransparency = 1
					for _, option in ipairs(optionButtons) do
						option.BackgroundTransparency = 1
					end
					TweenService:Create(popup, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0.04,
					}):Play()
					for _, option in ipairs(optionButtons) do
						TweenService:Create(option, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							BackgroundTransparency = 0,
						}):Play()
					end
					cleanupWatcher()
					closeWatcher = UserInputService.InputBegan:Connect(function(input, gameProcessed)
						if gameProcessed then return end
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							local p = UserInputService:GetMouseLocation()
							local insidePopup = p.X >= popup.AbsolutePosition.X and p.X <= popup.AbsolutePosition.X + popup.AbsoluteSize.X and p.Y >= popup.AbsolutePosition.Y and p.Y <= popup.AbsolutePosition.Y + popup.AbsoluteSize.Y
							local insideButton = p.X >= button.AbsolutePosition.X and p.X <= button.AbsolutePosition.X + button.AbsoluteSize.X and p.Y >= button.AbsolutePosition.Y and p.Y <= button.AbsolutePosition.Y + button.AbsoluteSize.Y
							if not insidePopup and not insideButton then
								setOpen(false)
							end
						end
					end)
				else
					cleanupWatcher()
					backdrop.Visible = false
					popup.Visible = false
				end
			end

			local function setValue(newValue, skipCallback)
				selected = newValue
				buttonText.Text = tostring(newValue)
				setOpen(false)
				if not skipCallback then
					safeCallback(childConfig.Callback, newValue)
				end
			end

			for index, item in ipairs(items) do
				local option = create("TextButton", {
					Name = tostring(item),
					Size = UDim2.new(1, 0, 0, 24),
					LayoutOrder = index,
					Text = "",
					AutoButtonColor = false,
					BorderSizePixel = 0,
					ZIndex = 51,
					Parent = popup,
					Attributes = { ThemeRole = "Surface2" },
				})
				table.insert(optionButtons, option)
				create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = option })

				create("TextLabel", {
					Name = "Text",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0.9, 0, 0.7, 0),
					Text = tostring(item),
					TextSize = 13,
					ZIndex = 52,
					Parent = option,
					Attributes = { ThemeRole = "Text" },
				})

				option.MouseEnter:Connect(function()
					TweenService:Create(option, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0.08,
					}):Play()
				end)

				option.MouseLeave:Connect(function()
					TweenService:Create(option, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0,
					}):Play()
				end)

				option.MouseButton1Click:Connect(function()
					setValue(item, false)
				end)
			end

			backdrop.MouseButton1Click:Connect(function()
				setOpen(false)
			end)

			button.MouseButton1Click:Connect(function()
				setOpen(not isOpen)
			end)

			dropdownObj.Frame = frame
			dropdownObj.Button = button
			dropdownObj.Popup = popup
			dropdownObj.GetValue = function()
				return selected
			end
			dropdownObj.SetValue = function(_, newValue, skipCallback)
				setValue(newValue, skipCallback)
			end
			dropdownObj.Destroy = function()
				cleanupWatcher()
				if backdrop.Parent then backdrop:Destroy() end
				if popup.Parent then popup:Destroy() end
				if frame.Parent then frame:Destroy() end
			end

			setValue(selected, true)

			return dropdownObj
		end

		function sectionObj:AddMultiDropdown(childConfig)
			childConfig = childConfig or {}
			local items = childConfig.Items or childConfig.Options or {}
			local selectedMap = {}
			for _, value in ipairs(childConfig.Default or {}) do
				selectedMap[value] = true
			end
			local isOpen = false
			local closeWatcher = nil
			local optionButtons = {}

			local frame = self:AddFrame({
				Name = childConfig.Id or childConfig.Name or "MultiDropdown",
				Height = childConfig.Height or 44,
				ClipsDescendants = false,
			})

			local label = create("TextLabel", {
				Name = "Label",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0.04, 0, 0.5, 0),
				Size = UDim2.new(0.34, 0, 0.6, 0),
				Text = childConfig.Name or "MultiDropdown",
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Parent = frame,
				Attributes = { ThemeRole = "Text" },
			})

			local button = create("TextButton", {
				Name = "Button",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.96, 0, 0.5, 0),
				Size = UDim2.new(0.5, 0, 0, 28),
				Text = "",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Parent = frame,
				Attributes = { ThemeRole = "Surface3" },
			})
			create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = button })
			create("UIStroke", { Transparency = 0.55, Parent = button, Attributes = { ThemeRole = "Stroke" } })

			local valueText = create("TextLabel", {
				Name = "ValueText",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0.08, 0, 0.5, 0),
				Size = UDim2.new(0.72, 0, 0.7, 0),
				Text = "None",
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = button,
				Attributes = { ThemeRole = "Text" },
			})

			local arrow = create("TextLabel", {
				Name = "Arrow",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.92, 0, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16),
				Text = "▼",
				TextSize = 12,
				Parent = button,
				Attributes = { ThemeRole = "TextMuted" },
			})

			local backdrop = create("TextButton", {
				Name = "MultiDropdownBackdrop",
				Visible = false,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 49,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = self.Library.Refs.Popups or self.Library.ScreenGui,
			})

			local popup = create("Frame", {
				Name = "MultiDropdownPopup_" .. tostring(frame.Name),
				Visible = false,
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				ZIndex = 50,
				Size = UDim2.fromOffset(0, 0),
				Parent = self.Library.Refs.Popups or self.Library.ScreenGui,
				Attributes = { ThemeRole = "Surface3" },
			})
			create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = popup })
			create("UIStroke", { Transparency = 0.45, Parent = popup, Attributes = { ThemeRole = "Stroke" } })
			create("UIPadding", {
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
				Parent = popup,
			})
			create("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = popup,
			})

			local multiObj = { Frame = frame, Button = button, Popup = popup }

			local function currentValues()
				local values = {}
				for _, item in ipairs(items) do
					if selectedMap[item] then
						table.insert(values, item)
					end
				end
				return values
			end

			local function refreshText()
				local values = currentValues()
				if #values == 0 then
					valueText.Text = "None"
				elseif #values <= 2 then
					valueText.Text = table.concat(values, ", ")
				else
					valueText.Text = string.format("%d selected", #values)
				end
			end

			local function cleanupWatcher()
				if closeWatcher then
					closeWatcher:Disconnect()
					closeWatcher = nil
				end
			end

			local function popupHeight()
				local count = #items
				return math.max(0, (count * 24) + math.max(0, count - 1) * 4 + 12)
			end

			local function repositionPopup()
				local pos = button.AbsolutePosition
				local size = button.AbsoluteSize
				popup.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 6)
				popup.Size = UDim2.fromOffset(size.X, popupHeight())
			end

			local function animateOpen()
				popup.Visible = true
				popup.BackgroundTransparency = 1
				local startPos = popup.Position
				popup.Position = UDim2.fromOffset(startPos.X.Offset, startPos.Y.Offset - 8)
				for _, option in ipairs(optionButtons) do
					option.BackgroundTransparency = 1
				end
				TweenService:Create(popup, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = startPos,
					BackgroundTransparency = 0.04,
				}):Play()
				for _, option in ipairs(optionButtons) do
					TweenService:Create(option, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0,
					}):Play()
				end
			end

			local function animateClose()
				local startPos = popup.Position
				local tween = TweenService:Create(popup, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = UDim2.fromOffset(startPos.X.Offset, startPos.Y.Offset - 8),
					BackgroundTransparency = 1,
				})
				for _, option in ipairs(optionButtons) do
					TweenService:Create(option, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						BackgroundTransparency = 1,
					}):Play()
				end
				tween:Play()
				tween.Completed:Connect(function()
					if not isOpen and popup.Parent then
						popup.Visible = false
						popup.Position = startPos
					end
				end)
			end

			local function setOpen(open)
				isOpen = open == true
				arrow.Text = isOpen and "▲" or "▼"
				if isOpen then
					repositionPopup()
					backdrop.Visible = true
					animateOpen()
					cleanupWatcher()
					closeWatcher = UserInputService.InputBegan:Connect(function(input, gp)
						if gp then return end
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							local p = UserInputService:GetMouseLocation()
							local insidePopup = p.X >= popup.AbsolutePosition.X and p.X <= popup.AbsolutePosition.X + popup.AbsoluteSize.X and p.Y >= popup.AbsolutePosition.Y and p.Y <= popup.AbsolutePosition.Y + popup.AbsoluteSize.Y
							local insideButton = p.X >= button.AbsolutePosition.X and p.X <= button.AbsolutePosition.X + button.AbsoluteSize.X and p.Y >= button.AbsolutePosition.Y and p.Y <= button.AbsolutePosition.Y + button.AbsoluteSize.Y
							if not insidePopup and not insideButton then
								setOpen(false)
							end
						end
					end)
				else
					cleanupWatcher()
					backdrop.Visible = false
					if popup.Visible then
						animateClose()
					end
				end
			end

			function multiObj:SetValue(values, skipCallback)
				selectedMap = {}
				for _, value in ipairs(values or {}) do
					selectedMap[value] = true
				end
				refreshText()
				if not skipCallback then
					safeCallback(childConfig.Callback, currentValues())
				end
			end

			function multiObj:GetValue()
				return currentValues()
			end

			for index, item in ipairs(items) do
				local option = create("TextButton", {
					Name = tostring(item),
					Size = UDim2.new(1, 0, 0, 28),
					LayoutOrder = index,
					Text = "",
					AutoButtonColor = false,
					BorderSizePixel = 0,
					ZIndex = 51,
					Parent = popup,
					BackgroundTransparency = 1,
					Attributes = { ThemeRole = "Surface2" },
				})

				table.insert(optionButtons, option)

				create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = option })

				local label = create("TextLabel", {
					Name = "Text",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 10, 0.5, 0),
					Size = UDim2.new(1, -40, 0.7, 0),
					Text = tostring(item),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 52,
					Parent = option,
					Attributes = { ThemeRole = "Text" },
				})

				local check = create("TextLabel", {
					Name = "Check",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.new(0, 16, 0, 16),
					Text = "✓",
					TextTransparency = selectedMap[item] and 0 or 1,
					TextSize = 14,
					ZIndex = 52,
					Parent = option,
					Attributes = { ThemeRole = "Accent" },
				})

				local function animateSelect(on)
					TweenService:Create(option, TweenInfo.new(0.15), {
						BackgroundTransparency = on and 0.08 or 0.15,
					}):Play()

					TweenService:Create(check, TweenInfo.new(0.15), {
						TextTransparency = on and 0 or 1,
					}):Play()

					TweenService:Create(option, TweenInfo.new(0.12, Enum.EasingStyle.Back), {
						Size = UDim2.new(1, 0, 0, on and 30 or 28),
					}):Play()
				end

				-- hover
				option.MouseEnter:Connect(function()
					TweenService:Create(option, TweenInfo.new(0.1), {
						BackgroundTransparency = 0.08,
					}):Play()
				end)

				option.MouseLeave:Connect(function()
					if not selectedMap[item] then
						TweenService:Create(option, TweenInfo.new(0.1), {
							BackgroundTransparency = 0.15,
						}):Play()
					end
				end)

				-- click animation
				option.MouseButton1Click:Connect(function()
					selectedMap[item] = not selectedMap[item]

					animateSelect(selectedMap[item])
					refreshText()

					-- click pulse
					local pulse = TweenService:Create(option, TweenInfo.new(0.1), {
						Size = UDim2.new(1, 0, 0, 32),
					})
					pulse:Play()
					pulse.Completed:Connect(function()
						TweenService:Create(option, TweenInfo.new(0.1), {
							Size = UDim2.new(1, 0, 0, 28),
						}):Play()
					end)

					safeCallback(childConfig.Callback, currentValues())
				end)

				-- initial state
				if selectedMap[item] then
					animateSelect(true)
				end
			end

			backdrop.MouseButton1Click:Connect(function()
				setOpen(false)
			end)

			button.MouseButton1Click:Connect(function()
				setOpen(not isOpen)
			end)

			refreshText()
			return multiObj
		end

		function sectionObj:AddColorPicker(childConfig)
			childConfig = childConfig or {}
			local value = childConfig.Default or Color3.fromRGB(255, 255, 255)
			local isOpen = false

			local frame = self:AddFrame({
				Name = childConfig.Id or childConfig.Name or "ColorPicker",
				Height = childConfig.Height or 44,
				ClipsDescendants = false,
			})

			local label = create("TextLabel", {
				Name = "Label",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0.04, 0, 0.5, 0),
				Size = UDim2.new(0.32, 0, 0.6, 0),
				Text = childConfig.Name or "Color",
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Parent = frame,
				Attributes = { ThemeRole = "Text" },
			})

			local button = create("TextButton", {
				Name = "Button",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0.96, 0, 0.5, 0),
				Size = UDim2.new(0.48, 0, 0, 28),
				Text = "",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Parent = frame,
				Attributes = { ThemeRole = "Surface3" },
			})
			create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = button })
			create("UIStroke", { Transparency = 0.55, Parent = button, Attributes = { ThemeRole = "Stroke" } })

			local swatch = create("Frame", {
				Name = "Swatch",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				Size = UDim2.new(0, 18, 0, 18),
				BorderSizePixel = 0,
				Parent = button,
				BackgroundColor3 = value,
			})
			create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = swatch })

			local valueText = create("TextLabel", {
				Name = "ValueText",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 32, 0.5, 0),
				Size = UDim2.new(1, -38, 0.7, 0),
				Text = "RGB",
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = button,
				Attributes = { ThemeRole = "Text" },
			})

			local backdrop = create("TextButton", {
				Name = "ColorPickerBackdrop",
				Visible = false,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 49,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = self.Library.Refs.Popups or self.Library.ScreenGui,
			})

			local popupWidth = 240
			local popupHeight = 132

			local popup = create("Frame", {
				Name = "ColorPickerPopup_" .. tostring(frame.Name),
				Visible = false,
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				ZIndex = 50,
				Size = UDim2.fromOffset(popupWidth, popupHeight),
				Parent = self.Library.Refs.Popups or self.Library.ScreenGui,
				Attributes = { ThemeRole = "Surface3" },
			})
			create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = popup })
			create("UIStroke", { Transparency = 0.45, Parent = popup, Attributes = { ThemeRole = "Stroke" } })

			local preview = create("Frame", {
				Name = "Preview",
				Position = UDim2.new(0, 12, 0, 12),
				Size = UDim2.new(1, -24, 0, 22),
				BorderSizePixel = 0,
				Parent = popup,
				BackgroundColor3 = value,
			})
			create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = preview })

			local pickerObj = { Frame = frame, Button = button, Popup = popup }

			local function refreshText()
				local r, g, b = color3ToRGB(value)
				valueText.Text = string.format("%d, %d, %d", r, g, b)
				swatch.BackgroundColor3 = value
				preview.BackgroundColor3 = value
			end

			local function repositionPopup()
				local pos = button.AbsolutePosition
				local size = button.AbsoluteSize
				popup.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 6)
			end

			local function animateOpen()
				popup.Visible = true
				popup.BackgroundTransparency = 1
				local startPos = popup.Position
				popup.Position = UDim2.fromOffset(startPos.X.Offset, startPos.Y.Offset - 8)
				local tween = TweenService:Create(popup, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = startPos,
					BackgroundTransparency = 0.04,
				})
				tween:Play()
			end

			local function animateClose()
				local startPos = popup.Position
				local tween = TweenService:Create(popup, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = UDim2.fromOffset(startPos.X.Offset, startPos.Y.Offset - 8),
					BackgroundTransparency = 1,
				})
				tween:Play()
				tween.Completed:Connect(function()
					if not isOpen and popup.Parent then
						popup.Visible = false
						popup.Position = startPos
					end
				end)
			end

			local function setOpen(open)
				isOpen = open == true
				if isOpen then
					repositionPopup()
					backdrop.Visible = true
					animateOpen()
				else
					backdrop.Visible = false
					if popup.Visible then
						animateClose()
					end
				end
			end

			function pickerObj:SetValue(newValue, skipCallback)
				value = newValue
				refreshText()
				if not skipCallback then
					safeCallback(childConfig.Callback, value)
				end
			end

			function pickerObj:GetValue()
				return value
			end

			local sliders = {
				{ name = "R", color = Color3.fromRGB(255, 80, 80), getter = function() local r= color3ToRGB(value); return r end, setter = function(v) local _,g,b = color3ToRGB(value); value = rgbToColor3(v,g,b) end },
				{ name = "G", color = Color3.fromRGB(80, 255, 80), getter = function() local _,g = color3ToRGB(value); return g end, setter = function(v) local r,_,b = color3ToRGB(value); value = rgbToColor3(r,v,b) end },
				{ name = "B", color = Color3.fromRGB(80, 80, 255), getter = function() local _,_,b = color3ToRGB(value); return b end, setter = function(v) local r,g,_ = color3ToRGB(value); value = rgbToColor3(r,g,v) end },
			}

			for i, info in ipairs(sliders) do
				local rowY = 42 + ((i - 1) * 28)
				create("TextLabel", {
					Name = info.name .. "Label",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 12, 0, rowY),
					Size = UDim2.new(0, 16, 0, 16),
					Text = info.name,
					TextSize = 13,
					Parent = popup,
					Attributes = { ThemeRole = "Text" },
				})
				local track = create("Frame", {
					Name = info.name .. "Track",
					Position = UDim2.new(0, 34, 0, rowY + 3),
					Size = UDim2.new(1, -86, 0, 10),
					BorderSizePixel = 0,
					Parent = popup,
					Attributes = { ThemeRole = "Surface2" },
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
				local fill = create("Frame", {
					Name = "Fill",
					Size = UDim2.new(info.getter() / 255, 0, 1, 0),
					BorderSizePixel = 0,
					Parent = track,
					BackgroundColor3 = info.color,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
				local hit = create("TextButton", {
					Name = "Hit",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = "",
					Size = UDim2.new(1, 0, 1, 0),
					Parent = track,
				})
				local valueLabel = create("TextLabel", {
					Name = info.name .. "Value",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0, rowY + 8),
					Size = UDim2.new(0, 28, 0, 14),
					Text = tostring(info.getter()),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = popup,
					Attributes = { ThemeRole = "TextMuted" },
				})

				local dragging = false
				local function updateFromX(x, skipCallback)
					local alpha = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
					local num = math.floor(alpha * 255 + 0.5)
					info.setter(num)
					fill.Size = UDim2.new(num / 255, 0, 1, 0)
					valueLabel.Text = tostring(num)
					refreshText()
					if not skipCallback then
						safeCallback(childConfig.Callback, value)
					end
				end

				hit.MouseButton1Down:Connect(function()
					dragging = true
					updateFromX(UserInputService:GetMouseLocation().X, false)
				end)
				table.insert(self.Library.Connections, UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						updateFromX(input.Position.X, false)
					end
				end))
				table.insert(self.Library.Connections, UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end))
			end

			backdrop.MouseButton1Click:Connect(function()
				setOpen(false)
			end)
			button.MouseButton1Click:Connect(function()
				setOpen(not isOpen)
			end)

			refreshText()
			return pickerObj
		end

		function sectionObj:AddPlayerSelector(childConfig)
			childConfig = childConfig or {}

			local dropdown
			local function getPlayers()
				local list = {}
				for _, plr in ipairs(Players:GetPlayers()) do
					table.insert(list, plr.Name)
				end
				return list
			end

			dropdown = self:AddDropdown({
				Name = childConfig.Name or "Player",
				Items = getPlayers(),
				Default = childConfig.Default,
				Callback = function(value)
					local plr = Players:FindFirstChild(value)
					safeCallback(childConfig.Callback, plr, value)
				end,
			})

			local function rebuild()
				if dropdown and dropdown.Destroy then
					local parent = dropdown.Frame.Parent
					dropdown:Destroy()

					dropdown = self:AddDropdown({
						Name = childConfig.Name or "Player",
						Items = getPlayers(),
						Default = childConfig.Default,
						Callback = function(value)
							local plr = Players:FindFirstChild(value)
							safeCallback(childConfig.Callback, plr, value)
						end,
					})
				end
			end

			table.insert(self.Library.Connections, Players.PlayerAdded:Connect(rebuild))
			table.insert(self.Library.Connections, Players.PlayerRemoving:Connect(rebuild))

			return dropdown
		end

		function sectionObj:AddKeybind(childConfig)
			childConfig = childConfig or {}
			childConfig.Section = self
			return self.Library:AddKeybind(childConfig)
		end

		table.insert(self.Sections, sectionObj)
		table.insert(self.Library.Sections, sectionObj)
		return sectionObj
	end

	self.Pages[pageId] = pageObject
	return pageObject
end

function UILibrary:AddTab(config)
	config = config or {}
	assert(config.Name, "AddTab requires a Name")

	local page = self:CreatePage({
		Id = config.Id or config.Name,
		Name = config.Name,
		Hidden = false,
		LayoutOrder = config.LayoutOrder,
	})

	local button = self.Refs.Templates.TabButton:Clone()
	button.Name = (config.Id or config.Name) .. "TabButton"
	button.Title.Text = config.Name
	button.Visible = true
	button.LayoutOrder = config.LayoutOrder or (#self.TabButtons + 1)
	button.Parent = self.Refs.TabList

	local tabObj = {
		Button = button,
		Page = page,
		Id = page.Id,
		Name = config.Name,
	}

	button.MouseButton1Click:Connect(function()
		self:SelectPage(page.Id)
	end)

	table.insert(self.TabButtons, tabObj)

	if not self.ActivePage then
		self:SelectPage(page.Id, true)
	end

	return page, tabObj
end

function UILibrary:_setTabActive(tabButton, isActive)
	if not tabButton then return end
	local accent = tabButton:FindFirstChild("AccentBar")
	if accent then
		TweenService:Create(accent, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = isActive and UDim2.new(0, 4, 0.6, 0) or UDim2.new(0, 0, 0.6, 0),
		}):Play()
	end
	TweenService:Create(tabButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = isActive and 0.05 or 0.2,
	}):Play()
end

function UILibrary:SelectPage(pageId, instant)
	local nextPage = self.Pages[pageId]
	if not nextPage then
		warn("[UILibrary] Attempted to select missing page:", pageId)
		return
	end

	if self.ActivePage == nextPage then
		return
	end

	local previous = self.ActivePage
	self.ActivePage = nextPage

	for _, tabData in ipairs(self.TabButtons) do
		self:_setTabActive(tabData.Button, tabData.Page == nextPage)
	end

	if previous then
		if instant then
			previous.Frame.Visible = false
			previous.Frame.GroupTransparency = 1
		else
			local tweenOut = TweenService:Create(previous.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0.5, 0, 1.15, 0),
				GroupTransparency = 1,
			})
			tweenOut:Play()
			tweenOut.Completed:Once(function()
				if previous ~= self.ActivePage then
					previous.Frame.Visible = false
				end
			end)
		end
	end

	nextPage.Frame.Visible = true
	if instant then
		nextPage.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		nextPage.Frame.GroupTransparency = 0
	else
		nextPage.Frame.Position = UDim2.new(0.5, 0, 1.15, 0)
		nextPage.Frame.GroupTransparency = 1
		TweenService:Create(nextPage.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			GroupTransparency = 0,
		}):Play()
	end
end

function UILibrary:_createThemeButton(theme)
	local button = self.Refs.Templates.ThemeButton:Clone()
	button.Name = theme.Name or "Theme"
	button.Visible = true
	button.ThemeText.Text = theme.Name or "Theme"
	button.Parent = self.Refs.ThemeSelector

	button.Hitbox.MouseButton1Click:Connect(function()
		self:SetTheme(theme.Name)
	end)

	return button
end

function UILibrary:_buildSettingsThemeButtons()
	local layout = create("UIGridLayout", {
		CellSize = UDim2.new(0.32, -6, 0, 42),
		CellPadding = UDim2.new(0, 8, 0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Refs.ThemeSelector,
	})
	layout.FillDirectionMaxCells = 3

	for _, child in ipairs(self.Refs.ThemeSelector:GetChildren()) do
		if child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	for _, theme in pairs(self.Themes) do
		self:_createThemeButton(theme)
	end
end


function UILibrary:_applyInitialTheme()
	self:SetTheme(self.Options.DefaultTheme, true)
	invokeThemeManager(self.ThemeManager, "BindRoot", self.ScreenGui)
	invokeThemeManager(self.ThemeManager, "ApplyNow", self.ScreenGui)
end

function UILibrary:SetTheme(themeName, instant)
	local theme = self.Themes[themeName]
	if not theme then
		warn("[UILibrary] Unknown theme:", themeName)
		return
	end

	self.ActiveThemeName = themeName

	local bg = self.Refs.BackgroundImage
	if bg then
		local fadeOut = TweenService:Create(bg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			ImageTransparency = 1,
		})
		fadeOut:Play()
		fadeOut.Completed:Once(function()
			applyThemeImage(bg, theme, 1)
			TweenService:Create(bg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				ImageTransparency = self.Options.BackgroundImageTransparency,
			}):Play()
		end)
	else
		applyThemeImage(bg, theme, self.Options.BackgroundImageTransparency)
	end

	invokeThemeManager(self.ThemeManager, "SetTheme", theme)
	if instant then
		invokeThemeManager(self.ThemeManager, "ApplyNow", self.ScreenGui)
	end
end

function UILibrary:GoToSettings()
	self:SelectPage("__settings")
end

function UILibrary:PlaySound(sound)
	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

function UILibrary:_dismissPrompt(callback)
	if self._promptDismissed or not self.Refs.Prompt or not self.Refs.Prompt.Parent then
		self._promptDismissed = true
		if callback then
			callback()
		end
		return
	end

	local prompt = self.Refs.Prompt
	local tween = TweenService:Create(prompt, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Position = UDim2.new(0.5, 0, 1.08, 0),
		GroupTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		if prompt and prompt.Parent then
			prompt:Destroy()
		end
		self._promptDismissed = true
		if callback then
			callback()
		end
	end)
end

function UILibrary:Open(skipAnimation)
	if self.IsAnimating or self.IsOpen then return end

	if not self._promptDismissed and self.Refs.Prompt and self.Refs.Prompt.Parent then
		self.IsAnimating = true
		self:_dismissPrompt(function()
			self.IsAnimating = false
			self:Open(skipAnimation)
		end)
		return
	end

	self.IsAnimating = true
	self.IsOpen = true

	local camera = workspace.CurrentCamera
	if camera then
		self._previousFOV = camera.FieldOfView
	end

	self.Refs.WindowGroup.Visible = true

	if skipAnimation then
		self.Refs.WindowGroup.Position = UDim2.new(0.5, 0, 0.5, 0)
		self.Refs.WindowGroup.GroupTransparency = 0
		if self.Options.UseBlur then
			getOrCreateBlur().Size = 10
		end
		if camera then
			camera.FieldOfView = self.Options.OpenFOV
		end
		self.IsAnimating = false
		return
	end

	local tweenInfo = TweenInfo.new(self.Options.AnimationTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local openTween = TweenService:Create(self.Refs.WindowGroup, tweenInfo, {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		GroupTransparency = 0,
	})

	if self.Options.UseBlur then
		TweenService:Create(getOrCreateBlur(), tweenInfo, { Size = 10 }):Play()
	end
	if camera then
		TweenService:Create(camera, tweenInfo, { FieldOfView = self.Options.OpenFOV }):Play()
	end

	self:PlaySound(self.Options.Sounds.Swoosh2)
	openTween:Play()
	openTween.Completed:Connect(function()
		self.IsAnimating = false
	end)
end

function UILibrary:Close(skipAnimation)
	if self.IsAnimating or not self.IsOpen then return end
	self.IsAnimating = true
	self.IsOpen = false

	local camera = workspace.CurrentCamera
	if skipAnimation then
		self.Refs.WindowGroup.Position = UDim2.new(0.5, 0, 1.5, 0)
		self.Refs.WindowGroup.GroupTransparency = 0.5
		self.Refs.WindowGroup.Visible = false
		local blur = Lighting:FindFirstChild("Blur")
		if blur then blur.Size = 0 blur:Destroy() end
		if camera then camera.FieldOfView = self._previousFOV end
		self.IsAnimating = false
		return
	end

	local tweenInfo = TweenInfo.new(self.Options.AnimationTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local closeTween = TweenService:Create(self.Refs.WindowGroup, tweenInfo, {
		Position = UDim2.new(0.5, 0, 1.5, 0),
		GroupTransparency = 0.5,
	})
	closeTween:Play()

	local blur = Lighting:FindFirstChild("UILibraryBlur")
	if blur then
		local blurTween = TweenService:Create(blur, tweenInfo, { Size = 0 })
		blurTween:Play()
		blurTween.Completed:Once(function()
			if blur.Parent then
				blur:Destroy()
			end
		end)
	end

	if camera then
		TweenService:Create(camera, tweenInfo, { FieldOfView = self._previousFOV }):Play()
	end

	self:PlaySound(self.Options.Sounds.Swoosh2)
	closeTween.Completed:Once(function()
		self.Refs.WindowGroup.Visible = false
		self.IsAnimating = false
	end)
end

function UILibrary:Toggle()
	if self.IsOpen then
		self:Close()
	else
		self:Open()
	end
end

function UILibrary:ShowPrompt(show)
	if not self.Refs.Prompt or not self.Refs.Prompt.Parent then
		return
	end
	local target = show and UDim2.new(0.5, 0, 0.93, 0) or UDim2.new(0.5, 0, 1.5, 0)
	local transparency = show and 0 or 1
	TweenService:Create(self.Refs.Prompt, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Position = target,
		GroupTransparency = transparency,
	}):Play()
end

function UILibrary:SetPromptText(text)
	self.Refs.PromptText.Text = text
end

function UILibrary:_bindSignals()
	table.insert(self.Connections, self.Refs.SettingsButton.MouseButton1Click:Connect(function()
		self:GoToSettings()
	end))

	table.insert(self.Connections, self.Refs.CloseButton.MouseButton1Click:Connect(function()
		self:Close()
	end))

	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == self.Options.ToggleKey then
			self:Toggle()
		end
	end))

	table.insert(self.Connections, Players.PlayerAdded:Connect(function()
		self.Refs.PlayerCount.Text = tostring(#Players:GetPlayers())
	end))
	table.insert(self.Connections, Players.PlayerRemoving:Connect(function()
		self.Refs.PlayerCount.Text = tostring(#Players:GetPlayers())
	end))
end


function UILibrary:SetKeybindOverlayEnabled(enabled, skipAnimation)
	self.Options.ShowKeybindOverlay = enabled == true
	if not self.Refs.KeybindOverlay then
		return
	end

	local hasEntries = #self.KeybindObjects > 0
	if not self.Options.ShowKeybindOverlay or not hasEntries then
		if skipAnimation then
			self.Refs.KeybindOverlay.Visible = false
			self.Refs.KeybindOverlay.GroupTransparency = 1
			self.Refs.KeybindOverlay.Position = UDim2.new(1.04, 0, 0.5, 0)
		else
			local tween = TweenService:Create(self.Refs.KeybindOverlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				GroupTransparency = 1,
				Position = UDim2.new(1.04, 0, 0.5, 0),
			})
			tween:Play()
			tween.Completed:Connect(function()
				if self.Refs.KeybindOverlay then
					self.Refs.KeybindOverlay.Visible = false
				end
			end)
		end
		return
	end

	self.Refs.KeybindOverlay.Visible = true
	if skipAnimation then
		self.Refs.KeybindOverlay.GroupTransparency = 0
		self.Refs.KeybindOverlay.Position = UDim2.new(0.985, 0, 0.5, 0)
	else
		self.Refs.KeybindOverlay.GroupTransparency = 1
		self.Refs.KeybindOverlay.Position = UDim2.new(1.04, 0, 0.5, 0)
		TweenService:Create(self.Refs.KeybindOverlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
			Position = UDim2.new(0.985, 0, 0.5, 0),
		}):Play()
	end
end

function UILibrary:CreateTooltip(text)
	local tooltip = create("TextLabel", {
		Name = "Tooltip",
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Text = tostring(text or ""),
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 200,
		Parent = self.Refs.Tooltips,
		Attributes = { ThemeRole = "Surface2" },
	})
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tooltip })
	create("UIStroke", {
		Transparency = 0.45,
		Parent = tooltip,
		Attributes = { ThemeRole = "Stroke" },
	})
	create("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = tooltip,
	})

	tooltip:SetAttribute("ThemeRole", "Text")
	tooltip:SetAttribute("ThemeProp", "TextColor3")

	return tooltip
end

function UILibrary:BindTooltip(guiObject, text)
	if not guiObject or not text or text == "" then
		return nil
	end

	local tooltip = self:CreateTooltip(text)

	local moveConn
	local enterConn
	local leaveConn

	enterConn = guiObject.MouseEnter:Connect(function()
		tooltip.Visible = true
	end)

	leaveConn = guiObject.MouseLeave:Connect(function()
		tooltip.Visible = false
	end)

	moveConn = UserInputService.InputChanged:Connect(function(input)
		if tooltip.Visible and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local mousePos = UserInputService:GetMouseLocation()
			tooltip.Position = UDim2.fromOffset(mousePos.X + 14, mousePos.Y + 14)
		end
	end)

	table.insert(self.Connections, enterConn)
	table.insert(self.Connections, leaveConn)
	table.insert(self.Connections, moveConn)

	return tooltip
end

function UILibrary:Notify(config)
	if type(config) == "string" then
		config = { Title = config }
	end
	config = config or {}
	local duration = config.Duration or self.Options.NotificationDuration

	local toast = create("CanvasGroup", {
		Name = "Toast",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 30, 0, 0),
		Size = UDim2.new(1, -10, 0, config.Height or 60),
		GroupTransparency = 1,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = self.Refs.Notifications,
	})

	local bg = create("Frame", {
		Name = "Background",
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.15,
		Parent = toast,
		Attributes = { ThemeRole = config.Role or "Surface" },
	})
	create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = bg })
	create("UIStroke", {
		Transparency = 0.45,
		Parent = bg,
		Attributes = { ThemeRole = "Stroke" },
	})
	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -24, 0, 18),
		Text = config.Title or "Notification",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Parent = bg,
		Attributes = { ThemeRole = "Text" },
	})
	create("TextLabel", {
		Name = "Body",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0, 28),
		Size = UDim2.new(1, -24, 1, -34),
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = config.Content or config.Text or "",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Parent = bg,
		Attributes = { ThemeRole = "TextMuted" },
	})

	local inTween = TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, 0, 0, 0),
		GroupTransparency = 0,
	})
	inTween:Play()

	task.delay(duration, function()
		if not toast.Parent then return end
		local outTween = TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 30, 0, 0),
			GroupTransparency = 1,
		})
		outTween:Play()
		outTween.Completed:Connect(function()
			if toast.Parent then
				toast:Destroy()
			end
		end)
	end)

	return toast
end

function UILibrary:_refreshKeybindOverlay()
	if not self.Refs.KeybindOverlay or not self.Refs.KeybindOverlayList then
		return
	end

	for _, child in ipairs(self.Refs.KeybindOverlayList:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local count = 0
	for _, entry in ipairs(self.KeybindObjects) do
		if entry and entry.Name and entry.GetValue then
			count += 1
			local row = create("Frame", {
				Name = entry.Name,
				Size = UDim2.new(1, 0, 0, 28),
				BorderSizePixel = 0,
				BackgroundTransparency = 0.18,
				Parent = self.Refs.KeybindOverlayList,
				Attributes = { ThemeRole = "Surface2" },
			})
			create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
			create("TextLabel", {
				Name = "Name",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -80, 1, 0),
				Text = entry.Name,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
				Attributes = { ThemeRole = "Text" },
			})
			create("TextLabel", {
				Name = "Key",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 64, 0, 16),
				Text = formatKeyCode(entry:GetValue()),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
				Attributes = { ThemeRole = "TextMuted" },
			})
		end
	end

	self:SetKeybindOverlayEnabled(self.Options.ShowKeybindOverlay, true)
end

function UILibrary:BindDependency(controller, dependent, predicate)
	assert(controller, "BindDependency requires a controller")
	assert(dependent, "BindDependency requires a dependent control")
	predicate = predicate or function(value)
		return not not value
	end

	local conn = RunService.Heartbeat:Connect(function()
		local currentValue
		if type(controller) == "table" and type(controller.GetValue) == "function" then
			currentValue = controller:GetValue()
		else
			currentValue = controller
		end
		local visible = predicate(currentValue)
		setControlVisible(dependent, visible)
	end)
	table.insert(self.DependencyConnections, conn)

	local currentValue
	if type(controller) == "table" and type(controller.GetValue) == "function" then
		currentValue = controller:GetValue()
	else
		currentValue = controller
	end
	setControlVisible(dependent, predicate(currentValue))
	return conn
end

function UILibrary:AddToggleKeybind(config)
	config = config or {}
	config.Name = config.Name or "Toggle UI"
	config.Default = config.Default or self.Options.ToggleKey or Enum.KeyCode.RightShift

	local changedCallback = config.Callback
	config.Callback = nil
	config.Changed = function(newKey)
		self.Options.ToggleKey = newKey
		safeCallback(changedCallback, newKey)
	end

	local bind = self:AddKeybind(config)
	local originalSetValue = bind.SetValue
	local originalGetValue = bind.GetValue

	function bind:SetValue(newKey, skipCallback)
		originalSetValue(self, newKey, true)
		self.Library.Options.ToggleKey = newKey
		if not skipCallback then
			safeCallback(changedCallback, newKey)
		end
	end

	function bind:GetValue()
		if originalGetValue then
			return originalGetValue(self)
		end
		return self.CurrentKey or self.Library.Options.ToggleKey
	end

	self.Options.ToggleKey = bind:GetValue()
	return bind
end

function UILibrary:AddKeybind(config)
	config = config or {}
	assert(config.Name, "AddKeybind requires Name")
	assert(config.Section, "AddKeybind requires Section")
	config.Mode = config.Mode or "Press"

	local frame = config.Section:AddFrame({
		Name = config.Name,
		Height = 44,
	})

	local label = create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.04, 0, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0.5, 0),
		FontFace = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = config.Name,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
		Attributes = { ThemeRole = "Text" },
	})

	local button = create("TextButton", {
		Name = "BindButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0.96, 0, 0.5, 0),
		Size = UDim2.new(0, 120, 0, 28),
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Parent = frame,
		Attributes = {
			ThemeRole = "Surface3",
		},
	})
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = button })
	create("UIStroke", { Transparency = 0.55, Parent = button, Attributes = { ThemeRole = "Stroke" } })

	local bindText = create("TextLabel", {
		Name = "BindText",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.9, 0, 0.7, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = formatKeyCode(config.Default or Enum.KeyCode.Unknown),
		TextSize = 14,
		Parent = button,
		Attributes = {
			ThemeRole = "Text",
		},
	})

	local currentKey = config.Default or Enum.KeyCode.Unknown
	local listening = false

	local keybindObj = {
		Name = config.Name,
		Frame = frame,
		Label = label,
		Button = button,
		BindText = bindText,
		Library = self,
		CurrentKey = currentKey,
	}

	function keybindObj:SetValue(newKey, skipChangedCallback)
		currentKey = newKey or Enum.KeyCode.Unknown
		self.CurrentKey = currentKey
		bindText.Text = formatKeyCode(currentKey)
		self.Library:_refreshKeybindOverlay()
		if not skipChangedCallback then
			safeCallback(config.Changed, currentKey)
		end
	end

	function keybindObj:GetValue()
		return currentKey
	end

	button.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true
		bindText.Text = "Press key..."
		local conn
		conn = UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				keybindObj:SetValue(input.KeyCode, false)
				listening = false
				conn:Disconnect()
			end
		end)
	end)

	if config.Mode == "Hold" then
		table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gp)
			if gp or listening then return end
			if input.KeyCode == currentKey then
				safeCallback(config.Callback, true, currentKey)
			end
		end))

		table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input, gp)
			if gp or listening then return end
			if input.KeyCode == currentKey then
				safeCallback(config.Callback, false, currentKey)
			end
		end))
	elseif config.Mode == "Toggle" then
		local toggled = false
		table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gp)
			if gp or listening then return end
			if input.KeyCode == currentKey then
				toggled = not toggled
				safeCallback(config.Callback, toggled, currentKey)
			end
		end))
	else
		table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gp)
			if gp or listening then return end
			if input.KeyCode == currentKey then
				safeCallback(config.Callback, currentKey)
			end
		end))
	end

	table.insert(self.KeybindObjects, keybindObj)
	self:_refreshKeybindOverlay()

	return keybindObj
end

function UILibrary:Destroy()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	table.clear(self.Connections)

	for _, conn in ipairs(self.DependencyConnections) do
		conn:Disconnect()
	end
	table.clear(self.DependencyConnections)

	self.ThemeManager.UnbindAll()

	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

return UILibrary
