# NekoHub UI Library

A modern, themeable Roblox UI library focused on flexibility, clean visuals, and smooth animations.

---

## Badges

![Status](https://img.shields.io/badge/status-active-success)
![Roblox](https://img.shields.io/badge/platform-Roblox-red)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## Features

* Fully themeable UI system with gradients and role-based styling
* Modular structure (pages, sections, controls)
* Smooth animations and transitions
* Dependency system for reactive UI logic
* Built-in settings page and theme switcher
* Keybind system with overlay support
* Notification system
* Search and filtering support
* Tooltips for contextual help
* Progress bars for visual feedback

---

## Getting Started

```lua
local Themes = loadstring(game:HttpGet("https://raw.githubusercontent.com/Shirozy/NekoHub-UI-Lib/refs/heads/main/themes.lua"))()
local UILibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/Shirozy/NekoHub-UI-Lib/refs/heads/main/RobloxUILibraryShell.lua"))()

local ui = UILibrary.new({
	Themes = Themes,
	DefaultTheme = "Gruvbox",
})
```

---

## Creating Tabs and Sections

```lua
local demo = ui:AddTab({
	Name = "Demo"
})

local section = demo:AddSection({
	Name = "Main Controls",
	Description = "Basic interaction elements"
})
```

---

## Controls

### Toggle

```lua
local toggle = section:AddToggle({
	Name = "Enable Feature",
	Default = true,
	Callback = function(state)
		print("Toggle state:", state)
	end
})
```

---

### Slider

```lua
local slider = section:AddSlider({
	Name = "Speed",
	Min = 0,
	Max = 100,
	Default = 50,
	Increment = 1,
	Callback = function(value)
		print("Speed:", value)
	end
})
```

---

### Button

```lua
section:AddButton({
	Name = "Execute",
	Callback = function()
		print("Button clicked")
	end
})
```

---

### Textbox

```lua
section:AddTextbox({
	Name = "Input",
	Placeholder = "Type something...",
	Callback = function(text, submitted)
		print("Text:", text, "Submitted:", submitted)
	end
})
```

---

### Dropdown

```lua
local dropdown = section:AddDropdown({
	Name = "Select Option",
	Items = {"A", "B", "C"},
	Default = "A",
	Callback = function(value)
		print("Selected:", value)
	end
})
```

---

### Multi Dropdown

```lua
local multi = section:AddMultiDropdown({
	Name = "Select Multiple",
	Items = {"One", "Two", "Three"},
	Default = {"One"},
	Callback = function(values)
		print("Selected:", table.concat(values, ", "))
	end
})
```

---

### Color Picker

```lua
local color = section:AddColorPicker({
	Name = "Pick Color",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(value)
		print("Color:", value)
	end
})
```

---

### Label

```lua
section:AddLabel({
	Text = "This is a label"
})
```

---

### Paragraph

```lua
section:AddParagraph({
	Name = "Information",
	Text = "This is a longer description block."
})
```

---

### Player Selector

```lua
section:AddPlayerSelector({
	Name = "Select Player",
	Callback = function(player, name)
		print("Selected player:", name)
	end
})
```

---

## Additional Controls

### Search Bar

The search bar allows you to dynamically filter controls within a section.

```lua
local search = section:AddSearchBox({
	Name = "Search",
	Placeholder = "Search controls..."
})
```

**Behavior**

* Filters controls in real time
* Matches based on control names
* Automatically excludes itself

---

### Progress Bar

The progress bar is a visual indicator for values between `0` and `1`.

```lua
local progress = section:AddProgressBar({
	Name = "Loading",
	Value = 0.25
})
```

**Update value**

```lua
progress:SetValue(0.75)
```

**Example with slider**

```lua
local progress = section:AddProgressBar({
	Name = "Power Level",
	Value = 0.5
})

section:AddSlider({
	Name = "Adjust Power",
	Min = 0,
	Max = 100,
	Default = 50,
	Callback = function(value)
		progress:SetValue(value / 100)
	end
})
```

**Notes**

* Range is `0 → 1`
* Automatically animates
* Displays percentage

---

### Tooltips

Tooltips provide additional context when hovering over controls.

```lua
section:AddButton({
	Name = "Delete",
	Tooltip = "This action cannot be undone",
	Callback = function()
		print("Deleted")
	end
})
```

**Behavior**

* Appears on hover
* Follows the cursor
* Uses current theme styling

---

## Keybinds

### Basic Keybind

```lua
ui:AddKeybind({
	Name = "Do Action",
	Section = section,
	Default = Enum.KeyCode.F,
	Callback = function()
		print("Key pressed")
	end
})
```

---

### Keybind Modes

```lua
ui:AddKeybind({
	Name = "Sprint",
	Section = section,
	Default = Enum.KeyCode.LeftShift,
	Mode = "Hold",
	Callback = function(isHolding)
		print("Holding:", isHolding)
	end
})
```

Modes:

* `Press`
* `Toggle`
* `Hold`

---

### Toggle UI Keybind

```lua
ui:AddToggleKeybind({
	Name = "Toggle UI",
	Section = section,
	Default = Enum.KeyCode.RightShift
})
```

---

## Dependency System

```lua
local advancedToggle = demo:AddToggle({
	Name = "Show Advanced",
	Default = false,
})

local powerSlider = demo:AddSlider({
	Name = "Power",
	Min = 0,
	Max = 100,
	Default = 35,
	Increment = 1,
	Callback = function(value)
		print("Power:", value)
	end,
})

ui:BindDependency(advancedToggle, powerSlider, function(state)
	return state == true
end)
```

---

## Notifications

```lua
ui:Notify({
	Title = "Success",
	Content = "Action completed",
	Duration = 3
})
```

---

## Themes

```lua
ui:SetTheme("TokyoNight")
```

---

## Settings Page

```lua
ui:GoToSettings()
```

```lua
local section = ui:AddSettingsSection({
	Name = "Custom Settings"
})
```

```lua
ui:AddToSettings("Toggle", {
	Name = "Example Setting",
	Section = "General",
	Default = true,
	Callback = function(value)
		print(value)
	end
})
```

---

## UI Control

```lua
ui:Open()
ui:Close()
ui:Toggle()
```

---

## Prompt

```lua
ui:SetPromptText("Press RightShift to open UI")
ui:ShowPrompt(true)
```

---

## Keybind Overlay

```lua
ui:SetKeybindOverlayEnabled(true)
```

---

## Cleanup

```lua
ui:Destroy()
```
