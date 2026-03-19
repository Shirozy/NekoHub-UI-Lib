# NekoHub UI Library

A modern, themeable Roblox UI library focused on flexibility, clean visuals, and smooth animations.

---

## Features

* Fully themeable UI system with gradients and role-based styling
* Modular structure (pages, sections, controls)
* Smooth animations and transitions
* Dependency system for reactive UI logic
* Built-in settings page and theme switcher
* Wide range of controls (toggles, sliders, dropdowns, etc.)
* Keybind system with overlay support
* Notification system

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

<img width="1713" height="987" alt="image" src="https://github.com/user-attachments/assets/27860b1e-df20-48fe-b927-ae35894b2625" />

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

You can dynamically show or hide controls based on other control values.

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

This will only show the slider when the toggle is enabled.

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

Themes are defined externally and passed into the library.

### Switching Theme

```lua
ui:SetTheme("TokyoNight")
```

---

## Settings Page

The library automatically creates a settings page.

### Open Settings

```lua
ui:GoToSettings()
```

### Add Custom Settings Section

```lua
local section = ui:AddSettingsSection({
	Name = "Custom Settings"
})
```

### Add Controls to Settings

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

### Open / Close

```lua
ui:Open()
ui:Close()
ui:Toggle()
```

---

### Prompt

```lua
ui:SetPromptText("Press RightShift to open UI")
ui:ShowPrompt(true)
```

---

### Keybind Overlay

```lua
ui:SetKeybindOverlayEnabled(true)
```

---

## Cleanup

```lua
ui:Destroy()
```
