## 29.08.2026
```diff
+ Forked
+ ThemeManager: merged built-in and custom themes into a single "Selected Theme" dropdown with an explicit "Apply Theme" button
+ ThemeManager: added "Rainbow Accent Color" toggle that continuously cycles the accent color's hue
+ ThemeManager: added "Show Keybinds Menu" / "Show Watermark" toggles to the theme groupbox
+ ThemeManager: added GetAllThemeNames(), Delete Theme now guards against deleting built-in themes
+ SaveManager: added Export()/Import() plus "Import Config" / "Export Config" buttons that round-trip a config through the clipboard
+ SaveManager: renamed "Overwrite config" to "Save Config", renamed "Configuration" groupbox to "Config"
+ Trimmed both default GUIs down to match a reference layout exactly: ThemeManager dropped the video-background input, "Set as Default", and custom-theme create/delete buttons (still available programmatically); SaveManager dropped "Refresh List" and the autoload buttons/label (still available programmatically); ThemeManager's groupbox is now titled "Theme" (was "Themes") and its color labels are Title Case
```
