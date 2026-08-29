local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func) 
    return func 
end)

local httprequest = request or http_request or (http and http.request)
local getassetfunc = getcustomasset

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local isfolder, isfile, listfiles = isfolder, isfile, listfiles;

local assert = function(condition, errorMessage) 
    if (not condition) then
        error(if errorMessage then errorMessage else "assert failed", 3)
    end
end

if typeof(clonefunction) == "function" then
    -- Fix is_____ functions for shitsploits, those functions should never error, only return a boolean.

    local
        isfolder_copy,
        isfile_copy,
        listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)

    local isfolder_success, isfolder_error = pcall(function()
        return isfolder_copy("test" .. tostring(math.random(1000000, 9999999)))
    end)

    if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
        isfolder = function(folder)
            local success, data = pcall(isfolder_copy, folder)
            return (if success then data else false)
        end

        isfile = function(file)
            local success, data = pcall(isfile_copy, file)
            return (if success then data else false)
        end

        listfiles = function(folder)
            local success, data = pcall(listfiles_copy, folder)
            return (if success then data else {})
        end
    end
end

local ThemeManager = {} do
	local ThemeFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor", "VideoLink" }
	ThemeManager.Folder = "LinoriaLibSettings"
	-- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Default']       = { 1, { FontColor = "ffffff", MainColor = "1c1c1c", AccentColor = "0055ff", BackgroundColor = "141414", OutlineColor = "323232" } },
		['BBot']          = { 2, { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" } },
		['Fatality']      = { 3, { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" } },
		['Jester']        = { 4, { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
		['Mint']          = { 5, { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
		['Tokyo Night']   = { 6, { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" } },
		['Ubuntu']        = { 7, { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919" } },
		['Quartz']        = { 8, { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" } },
	}

	function ApplyBackgroundVideo(videoLink)
		if
			typeof(videoLink) ~= "string" or
			not (getassetfunc and writefile and readfile and isfile) or
			not (ThemeManager.Library and ThemeManager.Library.InnerVideoBackground)
		then return; end;

		--// Variables \\--
		local videoInstance = ThemeManager.Library.InnerVideoBackground;
		local extension = videoLink:match(".*/(.-)?") or videoLink:match(".*/(.-)$"); extension = tostring(extension);
		local filename = string.sub(extension, 0, -6);
		local _, domain = videoLink:match("^(https?://)([^/]+)"); domain = tostring(domain); -- _ is protocol

		--// Check URL \\--
		if videoLink == "" then
			videoInstance:Pause();
			videoInstance.Video = "";
			videoInstance.Visible = false;
			return
		end
		if #extension > 5 and string.sub(extension, -5) ~= ".webm" then return; end;

		--// Fetch Video Data \\--
		local videoFile = ThemeManager.Folder .. "/themes/" .. string.gsub(domain .. filename, 0, 249) .. ".webm";
		if not isfile(videoFile) then
			local success, requestRes = pcall(httprequest, { Url = videoLink, Method = 'GET' })
			if not (success and typeof(requestRes) == "table" and typeof(requestRes.Body) == "string") then return; end;

			writefile(videoFile, requestRes.Body)
		end

		--// Play Video \\--
		videoInstance.Video = getassetfunc(videoFile);
		videoInstance.Visible = true;
		videoInstance:Play();
	end

	function ThemeManager:SetLibrary(library)
		self.Library = library
	end

	--// Folders \\--
	function ThemeManager:GetPaths()
	    local paths = {}

		local parts = self.Folder:split('/')
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, '/', 1, idx)
		end

		paths[#paths + 1] = self.Folder .. '/themes'
		
		return paths
	end

	function ThemeManager:BuildFolderTree()
		local paths = self:GetPaths()

		for i = 1, #paths do
			local str = paths[i]
			if isfolder(str) then continue end
			makefolder(str)
		end
	end

	function ThemeManager:CheckFolderTree()
		if isfolder(self.Folder) then return end
		self:BuildFolderTree()

		task.wait(0.1)
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end
	
	--// Apply, Update theme \\--
	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		-- custom themes are just regular dictionaries instead of an array with { index, dictionary }
		if self.Library.InnerVideoBackground ~= nil then
			self.Library.InnerVideoBackground.Visible = false
		end
		
		local scheme = data[2]
		for idx, col in next, customThemeData or scheme do
			if idx == "VideoLink" then
				self.Library[idx] = col
				
				if self.Library.Options[idx] then
					self.Library.Options[idx]:SetValue(col)
				end
				
				ApplyBackgroundVideo(col)
			else
				self.Library[idx] = Color3.fromHex(col)
				
				if self.Library.Options[idx] then
					self.Library.Options[idx]:SetValueRGB(Color3.fromHex(col))
				end
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		-- This allows us to force apply themes without loading the themes tab :)
		if self.Library.InnerVideoBackground ~= nil then
			self.Library.InnerVideoBackground.Visible = false
		end

		for i, field in next, ThemeFields do
			if self.Library.Options and self.Library.Options[field] then
				self.Library[field] = self.Library.Options[field].Value

				if field == "VideoLink" then
					ApplyBackgroundVideo(self.Library.Options[field].Value)
				end
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor);
		self.Library:UpdateColorsUsingRegistry()
	end

	--// Get, Load, Save, Delete, Refresh \\--
	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file .. '.json'
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
		
		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:LoadDefault()
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
			theme = self.DefaultTheme
		end

		self.Library.Options.ThemeManager_ThemeList:SetValue(theme)
		self:ApplyTheme(theme)
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			self.Library:Notify('Invalid file name for theme (empty)', 3)
			return
		end

		local theme = {}
		for _, field in next, ThemeFields do
			if field == "VideoLink" then
				theme[field] = self.Library.Options[field].Value
			else
				theme[field] = self.Library.Options[field].Value:ToHex()
			end
		end

		writefile(self.Folder .. '/themes/' .. file .. '.json', HttpService:JSONEncode(theme))
	end

	function ThemeManager:Delete(name)
		if (not name) then
			return false, 'no config file is selected'
		end

		local file = self.Folder .. '/themes/' .. name .. '.json'
		if not isfile(file) then return false, 'invalid file' end

		local success = pcall(delfile, file)
		if not success then return false, 'delete file error' end
		
		return true
	end
	
	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				-- i hate this but it has to be done ...

				local pos = file:find('.json', 1, true)
				local start = pos

				local char = file:sub(pos, pos)
				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1, start - 1))
				end
			end
		end

		return out
	end

	--// GUI \\--
	function ThemeManager:GetAllThemeNames()
		local names = {}

		for name in next, self.BuiltInThemes do
			table.insert(names, name)
		end

		for _, name in next, self:ReloadCustomThemes() do
			table.insert(names, name)
		end

		table.sort(names)
		return names
	end

	function ThemeManager:CreateThemeManager(groupbox)
		groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor });
		groupbox:AddLabel('Main color')	:AddColorPicker('MainColor', { Default = self.Library.MainColor });
		groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor });

		groupbox:AddToggle('ThemeManager_RainbowAccentColor', { Text = 'Rainbow Accent Color', Default = false });

		groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor });
		groupbox:AddLabel('Font color')	:AddColorPicker('FontColor', { Default = self.Library.FontColor });
		groupbox:AddInput('VideoLink', { Text = '.webm Video Background (Link)', Default = self.Library.VideoLink });

		groupbox:AddDivider()

		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Selected Theme', Values = self:GetAllThemeNames(), Default = 1 })
		groupbox:AddButton('Apply Theme', function()
			local name = self.Library.Options.ThemeManager_ThemeList.Value
			if not name or name == '' then
				self.Library:Notify('No theme selected', 2)
				return
			end

			self:ApplyTheme(name)
			self.Library:Notify(string.format('Applied theme %q', name))
		end)
		groupbox:AddButton('Set as Default', function()
			local name = self.Library.Options.ThemeManager_ThemeList.Value
			if not name or name == '' then
				self.Library:Notify('No theme selected', 2)
				return
			end

			self:SaveDefault(name)
			self.Library:Notify(string.format('Set default theme to %q', name))
		end)

		groupbox:AddDivider()

		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
		groupbox:AddButton('Save Current As Theme', function()
			local name = self.Library.Options.ThemeManager_CustomThemeName.Value
			if name:gsub(' ', '') == '' then
				self.Library:Notify('Invalid theme name (empty)', 2)
				return
			end

			self:SaveCustomTheme(name)

			self.Library:Notify(string.format('Saved theme %q', name))
			self.Library.Options.ThemeManager_ThemeList:SetValues(self:GetAllThemeNames())
		end)
		groupbox:AddButton('Delete Theme', function()
			local name = self.Library.Options.ThemeManager_ThemeList.Value
			if not name or name == '' then
				self.Library:Notify('No theme selected', 2)
				return
			end

			if self.BuiltInThemes[name] then
				self.Library:Notify('Cannot delete a built-in theme', 2)
				return
			end

			local success, err = self:Delete(name)
			if not success then
				self.Library:Notify('Failed to delete theme: ' .. err)
				return
			end

			self.Library:Notify(string.format('Deleted theme %q', name))
			self.Library.Options.ThemeManager_ThemeList:SetValues(self:GetAllThemeNames())
			self.Library.Options.ThemeManager_ThemeList:SetValue('Default')
		end)

		groupbox:AddDivider()

		groupbox:AddToggle('ThemeManager_ShowKeybindsMenu', {
			Text = 'Show Keybinds Menu',
			Default = self.Library.KeybindFrame.Visible,
			Callback = function(Value) self.Library.KeybindFrame.Visible = Value end,
		})
		groupbox:AddToggle('ThemeManager_ShowWatermark', {
			Text = 'Show Watermark',
			Default = self.Library.Watermark.Visible,
			Callback = function(Value) self.Library:SetWatermarkVisibility(Value) end,
		})

		self:LoadDefault()

		local function UpdateTheme() self:ThemeUpdate() end
		self.Library.Options.BackgroundColor:OnChanged(UpdateTheme)
		self.Library.Options.MainColor:OnChanged(UpdateTheme)
		self.Library.Options.AccentColor:OnChanged(UpdateTheme)
		self.Library.Options.OutlineColor:OnChanged(UpdateTheme)
		self.Library.Options.FontColor:OnChanged(UpdateTheme)

		local rainbowConnection: RBXScriptConnection? = nil
		self.Library.Toggles.ThemeManager_RainbowAccentColor:OnChanged(function()
			if self.Library.Toggles.ThemeManager_RainbowAccentColor.Value then
				if rainbowConnection then rainbowConnection:Disconnect() end

				rainbowConnection = RunService.Heartbeat:Connect(function()
					self.Library.Options.AccentColor:SetValueRGB(Color3.fromHSV((tick() % 5) / 5, 1, 1))
				end)
			elseif rainbowConnection then
				rainbowConnection:Disconnect()
				rainbowConnection = nil
			end
		end)

		self.Library:OnUnload(function()
			if rainbowConnection then
				rainbowConnection:Disconnect()
				rainbowConnection = nil
			end
		end)
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'ThemeManager:CreateGroupBox -> Must set ThemeManager.Library first!')
		return tab:AddLeftGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'ThemeManager:ApplyToTab -> Must set ThemeManager.Library first!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'ThemeManager:ApplyToGroupbox -> Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

getgenv().LinoriaThemeManager = ThemeManager
return ThemeManager