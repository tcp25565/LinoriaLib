# LinoriaLib Documentation

> This is a maintained fork of LinoriaLib (originally by mstudio45 / violin-suzutsuki, based on
> Splix/BBot). This document covers how to load and use the library, its addons, and every
> element type it exposes. For a runnable end-to-end example, see [Example.luau](Example.luau).

## Table of Contents

- [Loading the library](#loading-the-library)
- [Creating a window](#creating-a-window)
- [Tabs, Groupboxes, and Tabboxes](#tabs-groupboxes-and-tabboxes)
- [Elements](#elements)
  - [Toggle](#toggle)
  - [Button](#button)
  - [Label](#label)
  - [Divider](#divider)
  - [Slider](#slider)
  - [Input (Textbox)](#input-textbox)
  - [Dropdown](#dropdown)
  - [ColorPicker](#colorpicker)
  - [KeyPicker](#keypicker)
  - [DependencyBox](#dependencybox)
- [Library-level features](#library-level-features)
  - [Notifications](#notifications)
  - [Watermark](#watermark)
  - [Keybind menu](#keybind-menu)
  - [Unloading](#unloading)
  - [Icons](#icons)
  - [DPI scaling](#dpi-scaling)
- [Accessing elements later (`Toggles` / `Options` / `Labels`)](#accessing-elements-later)
- [SaveManager addon](#savemanager-addon)
- [ThemeManager addon](#thememanager-addon)
- [Wally / Rojo usage](#wally--rojo-usage)

## Loading the library

The library is a single Luau module, plus two optional addon modules. In an executor/loadstring
environment they're typically pulled straight from GitHub:

```lua
local repo = "https://raw.githubusercontent.com/tcp25565/LinoriaLib/master/"

local Library = loadstring(game:HttpGet(repo .. "Library.luau"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.luau"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.luau"))()
```

`Library.luau` returns the `Library` table itself — there's nothing else to call to initialize it.

If you're consuming this as a Wally/Rojo package instead (see
[Wally / Rojo usage](#wally--rojo-usage)), `init.luau` exposes all three modules from one require:

```lua
local LinoriaLib = require(path.to.package)
local Library, SaveManager, ThemeManager = LinoriaLib.Library, LinoriaLib.SaveManager, LinoriaLib.ThemeManager
```

Two tables are attached to the library and used throughout your script to reference elements by
their index (`Idx`) after creation:

```lua
local Options = Library.Options -- sliders, dropdowns, inputs, color pickers, keybinds
local Toggles = Library.Toggles -- toggles only
```

There is also `Library.Labels`, containing every label created via `AddLabel` that was given an
index.

Global settings you can set right after loading, before or after `CreateWindow`:

```lua
Library.ShowToggleFrameInKeybinds = true -- show a toggle in the keybind list for Toggle-mode keybinds (good on mobile)
Library.ShowCustomCursor = true          -- use Linoria's custom cursor instead of the OS cursor
Library.NotifySide = "Left"              -- "Left" or "Right" - which side notifications appear on
Library.NotifyOnError = false            -- if true, SafeCallback errors also show as a Notify() in addition to a console warn
```

## Creating a window

```lua
local Window = Library:CreateWindow({
    Title = "Example menu",
    Center = true,             -- center the window on screen (ignores Position)
    AutoShow = true,           -- show immediately instead of requiring Library:Toggle... to be called
    Resizable = true,          -- allow in-game resizing of the window
    ShowCustomCursor = true,
    UnlockMouseWhileOpen = true,
    NotifySide = "Left",       -- "Left" | "Right"
    TabPadding = 8,
    MenuFadeTime = 0.2,

    -- Position / Size are UDim2 and only need to be set if you don't want the defaults
    -- Position = UDim2.fromOffset(175, 50),
    -- Size = UDim2.fromOffset(550, 600),
})
```

`CreateWindow` also accepts the old positional form `Library:CreateWindow(Title, AutoShow)` for
backwards compatibility, but the table form above is recommended.

All `Window` options and their defaults (from `Templates.Window`):

| Option | Default | Notes |
|---|---|---|
| `Title` | `"No Title"` | Window title text |
| `AutoShow` | `false` | Show window immediately on creation |
| `Position` | `UDim2.fromOffset(175, 50)` | Ignored if `Center = true` |
| `Size` | `UDim2.fromOffset(0, 0)` | `0,0` triggers an automatic default size (550×600 desktop, or clamped to viewport on mobile) |
| `AnchorPoint` | `Vector2.zero` | |
| `TabPadding` | `1` | Spacing between tab buttons (values `<= 0` are clamped to `1`) |
| `MenuFadeTime` | `0.2` | Seconds for open/close fade |
| `NotifySide` | `"Left"` | `"Left"` \| `"Right"` |
| `ShowCustomCursor` | `true` | |
| `UnlockMouseWhileOpen` | `true` | |
| `Center` | `false` | Overrides `Position` to center the window |
| `Resizable` | *(not in template, opt-in)* | Pass `Resizable = true` to allow window resizing (min size is `Library.MinSize`) |

`Library:CreateWindow` returns a `Window` object with:

- `Window.Tabs` — a table of every tab added via `AddTab`, keyed by name.
- `Window:AddTab(Name)` — creates and returns a new `Tab`.

## Tabs, Groupboxes, and Tabboxes

```lua
local Tab = Window:AddTab("Main")

local LeftGroupBox = Tab:AddLeftGroupbox("Groupbox")
local RightGroupBox = Tab:AddRightGroupbox("Groupbox")

local TabBox = Tab:AddLeftTabbox()  -- or Tab:AddRightTabbox()
local SubTab1 = TabBox:AddTab("Tab 1")
local SubTab2 = TabBox:AddTab("Tab 2")
```

- A `Tab` has two columns; `AddLeftGroupbox`/`AddRightGroupbox` and `AddLeftTabbox`/`AddRightTabbox`
  add content to the left or right column respectively.
- A `Groupbox` and a `Tabbox`'s sub-`Tab` share the exact same element-creation methods
  (`AddToggle`, `AddSlider`, `AddButton`, ...) — anything you can do on a Groupbox, you can do
  inside a Tabbox tab.
- The UI automatically becomes scrollable per-column whenever a column has too many elements to
  fit.

Every `Add*` element method returns the created element object, and (except dividers/dependency
boxes) supports chaining further `Add*` calls directly off of it — e.g. adding a `ColorPicker` or
`KeyPicker` onto a `Label`, or a sub-`Button` onto a `Button` (see below).

## Elements

Every element accepts (where applicable):

- `Text` — display text
- `Tooltip` — text shown on hover
- `DisabledTooltip` — text shown on hover while disabled
- `Disabled` — `boolean`, disables interaction (defaults `false`)
- `Visible` — `boolean`, shows/hides the element (defaults `true`)
- `Callback` — function invoked on value/state change (initial creation does not invoke it)

All elements that hold a value give you an object with:

- `.Value` — current value (read)
- `:SetValue(...)` — set the value programmatically (also invokes callbacks)
- `:OnChanged(fn)` — register a listener for value changes (the recommended way to react to
  changes, since it decouples UI setup from logic)
- `:SetVisible(bool)` / `:SetDisabled(bool)` / `:SetText(text)` where applicable

### Toggle

```lua
Groupbox:AddToggle("MyToggle", {
    Text = "This is a toggle",
    Tooltip = "This is a tooltip",
    DisabledTooltip = "I am disabled!",

    Default = true,
    Disabled = false,
    Visible = true,
    Risky = false, -- makes the label text red (color configurable via Library.RiskColor)

    Callback = function(Value) end
})
```

Access later via `Library.Toggles.MyToggle`:

```lua
Toggles.MyToggle.Value
Toggles.MyToggle:SetValue(false)
Toggles.MyToggle:OnChanged(function() print(Toggles.MyToggle.Value) end)
```

A `Toggle` can have a `ColorPicker` and/or `KeyPicker` chained onto it (see those sections).

### Button

```lua
local MyButton = Groupbox:AddButton({
    Text = "Button",
    Func = function() end,
    DoubleClick = false, -- if true, requires two clicks to fire Func

    Tooltip = "This is the main button",
    DisabledTooltip = "I am disabled!",
    Disabled = false,
    Visible = true,
})
```

A button can have sub-buttons chained onto it via `:AddButton(...)` with the same options —
useful for grouping a primary action with related secondary actions:

```lua
MyButton:AddButton({ Text = "Sub button", Func = function() end, DoubleClick = true })
```

Or chained directly off the parent's return value:

```lua
Groupbox:AddButton({ Text = "Kill all", Func = KillAll })
    :AddButton({ Text = "Kick all", Func = KickAll })
```

Buttons expose `:SetVisible`, `:SetText`, `:SetDisabled` — there is no `.Value`/`OnChanged` since
buttons are momentary actions, not stateful.

### Label

```lua
-- Positional form: Groupbox:AddLabel(Text, DoesWrap, Idx)
Groupbox:AddLabel("This is a label")
Groupbox:AddLabel("This is a label\n\nwhich wraps its text!", true)
Groupbox:AddLabel("This is a label exposed to Labels", true, "TestLabel")

-- Table form: Groupbox:AddLabel(Idx, Options)
Groupbox:AddLabel("SecondTestLabel", {
    Text = "This is a label made with table options and an index",
    DoesWrap = true, -- defaults to false
})
```

Labels given an index are stored in `Library.Labels`:

```lua
Library.Labels.TestLabel:SetText("first changed!")
```

Labels are also the attachment point for compact inline `ColorPicker`, `KeyPicker`, and
`Dropdown` widgets:

```lua
Groupbox:AddLabel("Color"):AddColorPicker("ColorPicker", { Default = Color3.new(0, 1, 0) })
Groupbox:AddLabel("Keybind"):AddKeyPicker("KeyPicker", { Default = "MB2", Mode = "Toggle" })
Groupbox:AddLabel("Dropdown"):AddDropdown("MyDropdown", { Values = { "Addon", "Dropdown" }, Default = 1 })
```

### Divider

```lua
Groupbox:AddDivider() -- no arguments, purely visual separation
```

### Slider

```lua
Groupbox:AddSlider("MySlider", {
    Text = "This is my slider!",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 1,      -- decimal places of precision
    Suffix = "",       -- optional, appended after the value
    Prefix = "",       -- optional, prepended before the value
    Compact = false,   -- hides the title label above the slider
    HideMax = false,   -- shows only the current value instead of "value / max"

    Callback = function(Value) end,
    Tooltip = "I am a slider!",
    DisabledTooltip = "I am disabled!",
    Disabled = false,
    Visible = true,
})
```

`Text`, `Default`, `Min`, `Max`, and `Rounding` are required — the library asserts on missing
values.

You can fully customize the displayed value with `FormatDisplayValue`:

```lua
Groupbox:AddSlider("MySlider2", {
    Text = "This is my custom display slider!",
    Default = 0, Min = 0, Max = 5, Rounding = 1,

    FormatDisplayValue = function(slider, value)
        if value == slider.Max then return "Everything" end
        if value == slider.Min then return "Nothing" end
        -- returning nil falls back to the default "value / max" formatting
    end,
})
```

Access later via `Options.MySlider`, same `.Value` / `:SetValue` / `:OnChanged` pattern as other
`Options` entries.

### Input (Textbox)

```lua
Groupbox:AddInput("MyTextbox", {
    Default = "My textbox!",
    Numeric = false,          -- restrict to numeric input only
    Finished = false,         -- only fire Callback when Enter is pressed (instead of on every keystroke)
    ClearTextOnFocus = true,  -- clear the box's text when it gains focus
    MaxLength = nil,          -- optional max character length

    Text = "This is a textbox",
    Placeholder = "Placeholder text",
    Tooltip = "This is a tooltip",

    Callback = function(Value) end
})
```

Accessed via `Options.MyTextbox`.

### Dropdown

```lua
Groupbox:AddDropdown("MyDropdown", {
    Values = { "This", "is", "a", "dropdown" },
    Default = 1,          -- numeric index into Values, OR the string value itself
    Multi = false,        -- allow multiple selections
    Searchable = false,   -- adds a search box, useful for long lists
    AllowNull = false,    -- allow no selection (nil value)
    DisabledValues = {},  -- list of values that are shown but not selectable
    MaxVisibleDropdownItems = 8, -- how many items are visible before scrolling (default 8)

    Text = "A dropdown",
    Tooltip = "This is a tooltip",
    DisabledTooltip = "I am disabled!",

    FormatDisplayValue = function(Value) return Value end, -- change display text without changing the underlying Value

    Callback = function(Value) end,
    Disabled = false,
    Visible = true,
})
```

Special auto-populated dropdowns (no `Values` needed):

```lua
Groupbox:AddDropdown("MyPlayerDropdown", {
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Text = "A player dropdown",
    Callback = function(Value) end,
})

Groupbox:AddDropdown("MyTeamDropdown", {
    SpecialType = "Team",
    Text = "A team dropdown",
    Callback = function(Value) end,
})
```

Usage of the created dropdown:

```lua
Options.MyDropdown:OnChanged(function() print(Options.MyDropdown.Value) end)
Options.MyDropdown:SetValue("This")           -- single-select: pass the string (or its index)
Options.MyDropdown:SetValues({...})           -- replace the Values list entirely (used by SaveManager/ThemeManager)

-- Multi-select dropdowns store their value as a set: { [value] = true, ... }
Options.MyMultiDropdown:SetValue({ This = true, is = true })
for key, value in next, Options.MyMultiDropdown.Value do
    print(key, value)
end
```

### ColorPicker

```lua
Groupbox:AddColorPicker("ColorPicker1", {
    Default = Color3.new(1, 0, 0),
    Title = "Some color1",     -- optional custom title shown when the picker popup opens
    Transparency = 0,          -- optional; omit/nil disables transparency editing entirely

    Callback = function(Value, Transparency) end
})
```

Usually chained off a `Toggle`, `Label`, or another element rather than added to the groupbox
directly.

```lua
Options.ColorPicker1:OnChanged(function()
    print(Options.ColorPicker1.Value, Options.ColorPicker1.Transparency)
end)

Options.ColorPicker1:SetValueRGB(Color3.fromRGB(0, 255, 140)) -- set by RGB Color3
Options.ColorPicker1:SetValue(hsvColor, transparency)         -- set by HSV Color3
```

Users can right-click the swatch to copy/paste hex or RGB values.

### KeyPicker

```lua
Groupbox:AddLabel("Keybind"):AddKeyPicker("KeyPicker", {
    Default = "MB2",              -- key name string; "MB1"/"MB2"/"MB3" for mouse buttons
    SyncToggleState = false,      -- only valid with Toggle mode; ties the keybind's active-state to its parent Toggle's value
    Mode = "Toggle",              -- "Always" | "Toggle" | "Hold" | "Press"
    Text = "Auto lockpick safes", -- shown in the keybind list menu
    NoUI = false,                 -- hide this keybind from the keybind list menu

    Callback = function(Value) end,               -- fires on click; for Toggle mode, Value is the new toggled bool
    ChangedCallback = function(NewKey, NewModifiers) end, -- fires when the bound key itself is changed by the user
})
```

`Mode = "Press"` can only be used on a `Label` (i.e. `Label:AddKeyPicker`, not directly on a
Groupbox), since it has no persistent on/off state to render elsewhere.

```lua
Options.KeyPicker:OnClick(function() end)     -- only fires for Toggle mode's click event
Options.KeyPicker:OnChanged(function() end)   -- fires when .Value / .Modifiers changes
Options.KeyPicker:GetState()                  -- returns current active state (bool) — poll this for Hold/Always/Press modes
Options.KeyPicker:SetValue({ "MB2", "Hold" }) -- { Key, Mode, Modifiers? }
```

`Library.ToggleKeybind` can be set to a `KeyPicker` `Options` object to make it the key that
opens/closes the whole menu:

```lua
Groupbox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true })
Library.ToggleKeybind = Options.MenuKeybind
```

### DependencyBox

Dependency boxes let you show/hide a group of elements based on the state of other elements
(toggles, dropdown selections, etc.) — e.g. only show a feature's settings while its "enabled"
toggle is on.

```lua
Groupbox:AddToggle("ControlToggle", { Text = "Dependency box toggle" })

local Depbox = Groupbox:AddDependencyBox()
Depbox:AddToggle("DepboxToggle", { Text = "Sub-dependency box toggle" })

-- Dependency boxes can be nested; a nested box automatically depends on its parent's
-- visibility on top of whatever dependencies you add for it.
local SubDepbox = Depbox:AddDependencyBox()
SubDepbox:AddSlider("DepboxSlider", { Text = "Slider", Default = 50, Min = 0, Max = 100, Rounding = 0 })
SubDepbox:AddDropdown("DepboxDropdown", { Text = "Dropdown", Default = 1, Values = { "a", "b", "c" } })

Depbox:SetupDependencies({
    { Toggles.ControlToggle, true } -- pass `false` to show only when the toggle is OFF
})

SubDepbox:SetupDependencies({
    { Toggles.DepboxToggle, true }
})

-- For dropdowns, the second value is checked against the currently selected value:
SecretDepbox:SetupDependencies({
    { Options.DepboxDropdown, "someValue" }
})
```

A `DependencyBox` supports the same `Add*` element methods as a `Groupbox`.

## Library-level features

### Notifications

```lua
Library:Notify("This is a notification")                        -- (Text, Time?, SoundId?)
Library:Notify("This is a notification with sound", 5, 4590657391)

-- Table form for more control:
Library:Notify({
    Title = "Title",
    Description = "Description text",
    Time = 5,          -- seconds, or an Instance — the notification is removed when that Instance is destroyed
    SoundId = nil,
    Steps = nil,
    Persist = nil,
    Icon = nil,
    IconColor = nil,
})

Library:SetNotifySide("Right") -- or set Library.NotifySide directly
```

### Watermark

```lua
Library:SetWatermarkVisibility(true)
Library:SetWatermark("MyScript | 60 fps | 40 ms")
```

A common pattern is updating it every frame with live stats (see `Example.luau` for an FPS/ping
watermark loop using `RunService.RenderStepped`).

### Keybind menu

`Library.KeybindFrame` is the frame listing all non-`NoUI` keybinds; toggling its `.Visible`
shows/hides that list independently of the main window:

```lua
Groupbox:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value) Library.KeybindFrame.Visible = value end
})
```

### Unloading

```lua
Library:OnUnload(function()
    print("Unloaded!")
end)

Groupbox:AddButton("Unload", function() Library:Unload() end)
```

Register cleanup (disconnecting `RBXScriptConnection`s not already owned by a Linoria UI element,
stopping loops, etc.) inside `Library:OnUnload`.

### Icons

```lua
Library:SetIconModule(iconModule) -- a module matching the IconModule type, providing icon lookups
Library:GetIcon("IconName")
Library:GetCustomIcon("IconName") -- falls back to GetIcon if no custom module/icon is set
```

### DPI scaling

```lua
Library:SetDPIScale(125) -- percentage; scales element sizes/positions and Library.MinSize accordingly
```

## Accessing elements later

Every element created with an `Idx` (first argument to `AddToggle`/`AddSlider`/etc.) is registered
into one of these tables so you can reference it anywhere else in your script without holding onto
the object returned at creation time:

| Table | Contains |
|---|---|
| `Library.Toggles` | All `Toggle` elements |
| `Library.Options` | Sliders, Dropdowns, Inputs, ColorPickers, KeyPickers |
| `Library.Labels` | Labels created with an index |

```lua
Toggles.MyToggle.Value
Options.MySlider:SetValue(3)
Library.Labels.TestLabel:SetText("updated")
```

## SaveManager addon

`SaveManager` persists `Toggles`/`Options` values to JSON config files on disk (via the executor's
file functions), plus an optional "autoload" config.

```lua
SaveManager:SetLibrary(Library)          -- required before using any other SaveManager method

SaveManager:IgnoreThemeSettings()        -- don't save theme-related keys into configs
SaveManager:SetIgnoreIndexes({ "MenuKeybind" }) -- also ignore any other Idx you don't want saved

SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place") -- optional: separates configs by e.g. game place ID
                                            -- results in MyScriptHub/specific-game/settings/specific-place

SaveManager:BuildConfigSection(Tabs["UI Settings"]) -- builds a ready-made "Configuration" groupbox
                                                     -- (create / load / overwrite / delete / autoload) on the given Tab

SaveManager:LoadAutoloadConfig() -- call once at the end of your script, after the UI is fully built
```

Manual API (used internally by `BuildConfigSection`, but callable directly too):

```lua
SaveManager:Save(name)     --> success, err
SaveManager:Load(name)     --> success, err
SaveManager:Delete(name)   --> success, err
SaveManager:RefreshConfigList() --> array of config names
SaveManager:SaveAutoloadConfig(name)
SaveManager:GetAutoloadConfig() --> name or "none"
SaveManager:DeleteAutoLoadConfig()
SaveManager:SetLoadingOrder(true, { "Dropdown", "Toggle", ... }) -- control the order option types are Loaded, e.g. so dependent dropdowns exist before values relying on them
```

Only `Toggle`, `Slider`, `Dropdown`, `ColorPicker`, `KeyPicker`, and `Input` elements are saved —
these are the types with entries in `SaveManager.Parser`.

## ThemeManager addon

`ThemeManager` manages `Library.MainColor` / `AccentColor` / `BackgroundColor` / `OutlineColor` /
`FontColor` (and an optional `.webm` background video), with a set of built-in themes plus
user-saved custom themes.

```lua
ThemeManager:SetLibrary(Library) -- required first
ThemeManager:SetFolder("MyScriptHub") -- where themes are stored (defaults to "LinoriaLibSettings")

ThemeManager:ApplyToTab(Tabs["UI Settings"])       -- builds a full "Themes" groupbox on a Tab
-- or:
ThemeManager:ApplyToGroupbox(someGroupbox)         -- build directly into an existing groupbox
```

Built-in themes: `Default`, `BBot`, `Fatality`, `Jester`, `Mint`, `Tokyo Night`, `Ubuntu`,
`Quartz`.

Manual API:

```lua
ThemeManager:ApplyTheme("Mint")       -- apply a built-in or custom theme by name
ThemeManager:SaveCustomTheme(name)
ThemeManager:GetCustomTheme(name)     --> theme table or nil
ThemeManager:Delete(name)             --> success, err
ThemeManager:ReloadCustomThemes()     --> array of custom theme names
ThemeManager:SaveDefault(name)        -- persist which theme loads automatically next time
ThemeManager:LoadDefault()            -- called automatically by CreateThemeManager
```

Since `ThemeManager` writes color values into `Library.Options` (`BackgroundColor`, `MainColor`,
`AccentColor`, `OutlineColor`, `FontColor`), always pair it with
`SaveManager:IgnoreThemeSettings()` so your regular configs don't also try to save/restore theme
colors.

## Wally / Rojo usage

This fork is published to the Wally registry as `tcp25565/linorialib` (see
[wally.toml](wally.toml)). Add it as a dependency and require it via `init.luau`:

```toml
[dependencies]
LinoriaLib = "tcp25565/linorialib@0.1.0"
```

```lua
local LinoriaLib = require(ReplicatedStorage.Packages.LinoriaLib)
local Library, SaveManager, ThemeManager = LinoriaLib.Library, LinoriaLib.SaveManager, LinoriaLib.ThemeManager
```
