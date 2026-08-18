local Compkiller = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/CompKiller/refs/heads/main/src/source.luau"))();

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Notifier = Compkiller.newNotify();

local ConfigManager = Compkiller:ConfigManager({
	Directory = "Compkiller-UI",
	Config = "Example-Configs"
});

Compkiller:Loader("rbxassetid://72322195986989" , 5).yield();

local Window = Compkiller.new({
	Name = "Intervals HUB",
	Keybind = "LeftAlt",
	Logo = "rbxassetid://72322195986989",
	TextSize = 15,
});

-- ==================== [ VARIABLES ] ====================
local MenuKey = Enum.KeyCode.LeftAlt
local CurrentSpeed = 16
local SpeedEnabled = false
local AutoFuseEnabled = false
local AntiAfkEnabled = true
local FuseTargets = {}
local FuseLock = 5
local SellBelowOVR = 70

-- ==================== [ CONFIG ] ====================
local CONFIG = {
	FuseRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerEconomy"):WaitForChild("MachineInteract"),
	SellRequestRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerEconomy"):WaitForChild("RequestSellOffer"),
	SellRespondRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerEconomy"):WaitForChild("RespondSellOffer"),
}

-- ==================== [ NEW ANTI AFK ] ====================
local function SetupAntiAfk()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if AntiAfkEnabled then
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
end
SetupAntiAfk()

-- ==================== [ GET CARDS FROM PLOTINVENTORY ] ====================
local function GetInventoryCards()
	local cards = {}
	local PlotInventory = LocalPlayer:FindFirstChild("PlotInventory")
	if not PlotInventory then return cards end
	
	for _, item in pairs(PlotInventory:GetChildren()) do
		if item:IsA("StringValue") then
			local cardData = {
				Name = item.Name,
				ItemId = item:GetAttribute("InventoryCardId") or item:GetAttribute("CardToolId"),
				PlayerName = item:GetAttribute("PlayerName"),
				LeagueId = item:GetAttribute("LeagueId"),
				OVR = item:GetAttribute("OVR"),
				IsFused = item:GetAttribute("IsFused"),
			}
			table.insert(cards, cardData)
		end
	end
	return cards
end

-- ==================== [ FILTER CARDS FOR FUSE ] ====================
local function GetFuseCards()
	local allCards = GetInventoryCards()
	local filtered = {}
	
	for _, card in pairs(allCards) do
		if not card.ItemId then continue end
		if card.IsFused then continue end
		if string.find(string.lower(card.Name), "coach") then continue end
		
		if #FuseTargets > 0 then
			local matched = false
			local cardNameLower = string.lower(card.Name)
			for _, target in pairs(FuseTargets) do
				if string.find(cardNameLower, string.lower(target)) then
					matched = true
					break
				end
			end
			if not matched then continue end
		else
			continue
		end
		
		table.insert(filtered, card)
	end
	
	return filtered
end

-- ==================== [ FILTER CARDS FOR SELL ] ====================
local function GetSellCards()
	local allCards = GetInventoryCards()
	local filtered = {}
	
	for _, card in pairs(allCards) do
		if not card.ItemId then continue end
		if card.IsFused then continue end
		if string.find(string.lower(card.Name), "coach") then continue end
		
		-- OVR Filter only
		if card.OVR and card.OVR >= SellBelowOVR then continue end
		
		table.insert(filtered, card)
	end
	
	return filtered
end

-- ==================== [ AUTO FUSE FUNCTIONS ] ====================
local function GetMyPlot()
	local CreatedPlots = workspace:WaitForChild("CreatedPlots")
	local UserId = tostring(LocalPlayer.UserId)
	
	for _, plot in pairs(CreatedPlots:GetChildren()) do
		if string.find(plot.Name, UserId) then
			return plot
		end
	end
	return nil
end

local function DoAutoFuse()
	if not AutoFuseEnabled then return end
	
	local MyPlot = GetMyPlot()
	if not MyPlot then
		Notifier.new({
			Title = "Auto Fuse",
			Content = "Plot not found!",
			Duration = 3,
			Icon = "rbxassetid://72322195986989"
		});
		return
	end
	
	if #FuseTargets == 0 then
		Notifier.new({
			Title = "Auto Fuse",
			Content = "Select at least 1 target!",
			Duration = 3,
			Icon = "rbxassetid://72322195986989"
		});
		return
	end
	
	local PlayerToAdd = MyPlot:WaitForChild("FuseMachine"):WaitForChild("PlayerToAdd")
	local cards = GetFuseCards()
	
	if #cards < FuseLock then
		Notifier.new({
			Title = "Auto Fuse",
			Content = "Not enough cards! (" .. #cards .. "/" .. FuseLock .. ")",
			Duration = 3,
			Icon = "rbxassetid://72322195986989"
		});
		return
	end
	
	Notifier.new({
		Title = "Auto Fuse",
		Content = "Adding " .. FuseLock .. " cards...",
		Duration = 2,
		Icon = "rbxassetid://72322195986989"
	});
	
	for i = 1, FuseLock do
		if not AutoFuseEnabled then break end
		
		local card = cards[i]
		local args = {
			[1] = "AddPlayer",
			[2] = PlayerToAdd,
			[3] = {
				["PlayerName"] = card.PlayerName or card.Name,
				["LeagueId"] = card.LeagueId or "unknown",
				["OVR"] = card.OVR or 0,
				["ItemId"] = card.ItemId,
			}
		}
		
		local success, err = pcall(function()
			CONFIG.FuseRemote:InvokeServer(unpack(args))
		end)
		
		if not success then
			Notifier.new({
				Title = "Auto Fuse",
				Content = "Error: " .. tostring(err),
				Duration = 3,
				Icon = "rbxassetid://72322195986989"
			});
			break
		end
		
		task.wait(0.3)
	end
	
	if AutoFuseEnabled then
		task.wait(0.5)
		local success2, err2 = pcall(function()
			local StartFuse = MyPlot:WaitForChild("FuseMachine"):WaitForChild("StartFuse")
			local args = {
				[1] = "RunFuse",
				[2] = StartFuse
			}
			CONFIG.FuseRemote:InvokeServer(unpack(args))
		end)
		
		if success2 then
			Notifier.new({
				Title = "Auto Fuse",
				Content = "Fuse Started!",
				Duration = 3,
				Icon = "rbxassetid://72322195986989"
			});
		else
			Notifier.new({
				Title = "Auto Fuse",
				Content = "Error: " .. tostring(err2),
				Duration = 3,
				Icon = "rbxassetid://72322195986989"
			});
		end
	end
	
	task.wait(8)
end

-- ==================== [ MAIN LOOP ] ====================
task.spawn(function()
	while true do
		task.wait(1)
		if AutoFuseEnabled then DoAutoFuse() end
	end
end)

-- ==================== [ UI SETUP ] ====================

local UserSettings = Window.UserSettings:Create();

UserSettings:AddColorPicker({
	Name = "Menu Color",
	Default = Compkiller.Colors.Highlight,
	Callback = function(f)
		Compkiller.Colors.Highlight = f;
		Compkiller:RefreshCurrentColor();
	end,
});

UserSettings:AddKeybind({
	Name = "Menu Key",
	Default = MenuKey,
	Callback = function(f)
		MenuKey = f;
		Window:SetMenuKey(MenuKey)
	end,
});

UserSettings:AddDropdown({
	Name = "Menu Language",
	Values = {"English","Russian","Chinese"},
	Default = "English",
	Callback = print
});

UserSettings:AddDropdown({
	Name = "Menu Theme",
	Values = {
		"Default",
		"Dark Green",
		"Dark Blue",
		"Purple Rose",
		"Skeet"
	},
	Default = "Default",
	Callback = function(f)
		Compkiller:SetTheme(f)
	end,
});

UserSettings:AddDropdown({
	Name = "Visible Widgets",
	Values = {"Watermark","Keybinds","Double Tab"},
	Multi = true,
	Default = {"Watermark"},
	Callback = function(f)
		print(f)
	end,
});

Notifier.new({
	Title = "Notification",
	Content = "Thank you for use this script!",
	Duration = 5,
	Icon = "rbxassetid://72322195986989"
});

local Watermark = Window:Watermark();

Watermark:AddText({
	Icon = "user",
	Text = LocalPlayer.Name,
});

Watermark:AddText({
	Icon = "clock",
	Text = Compkiller:GetDate(),
});

task.spawn(function()
	while true do task.wait(1)
		Time:SetText(Compkiller:GetTimeNow());
	end
end)

Window:DrawCategory({
	Name = "Make Soccer Players"
});

local NormalTab = Window:DrawTab({
	Name = "MAIN",
	EnableScrolling = true
});

local NormalSection = NormalTab:DrawSection({
	Name = "General",
	Position = 'left'	
});

-- ==================== [ FUSE TARGET (MULTI) ] ====================
NormalSection:AddDropdown({
	Name = "Fuse Target",
	Values = {
		"Super Ballon d'Or",
		"Ballon d'Or",
		"Icons Player",
		"Premier League",
		"La Liga",
		"Serie A",
		"Bundesliga",
		"Ligue 1",
		"Liga MX"
	},
	Multi = true,
	Default = {},
	Callback = function(v)
		FuseTargets = {}
		if type(v) == "table" then
			for key, val in pairs(v) do
				if val == true then
					table.insert(FuseTargets, key)
				end
			end
		end
	end,
});

-- ==================== [ FUSE LOCK ] ====================
NormalSection:AddSlider({
	Name = "Fuse Lock",
	Min = 2,
	Max = 100,
	Default = 5,
	Round = 0,
	Flag = "Slider_FuseLock",
	Callback = function(v)
		FuseLock = v
	end
})

-- ==================== [ TOGGLES ] ====================

NormalSection:AddToggle({
	Name = "Auto Fuse",
	Flag = "Toggle_AutoFuse",
	Default = false,
	Callback = function(v)
		AutoFuseEnabled = v
	end,
}); 

NormalSection:AddToggle({
	Name = "Anti AFK",
	Flag = "Toggle_AntiAfk",
	Default = true,
	Callback = function(v)
		AntiAfkEnabled = v
	end,
});

NormalSection:AddToggle({
	Name = "Set Speed",
	Flag = "Toggle_Speed",
	Default = false,
	Callback = function(v)
		SpeedEnabled = v
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			if SpeedEnabled then
				LocalPlayer.Character.Humanoid.WalkSpeed = CurrentSpeed
			else
				LocalPlayer.Character.Humanoid.WalkSpeed = 16
			end
		end
	end,
})

NormalSection:AddSlider({
	Name = "Speed",
	Min = 0,
	Max = 200,
	Default = 16,
	Round = 0,
	Flag = "Slider_Speed",
	Callback = function(v)
		CurrentSpeed = v
		if SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			LocalPlayer.Character.Humanoid.WalkSpeed = CurrentSpeed
		end
	end
})

-- ==================== [ MISC TAB ] ====================
Window:DrawCategory({
	Name = "Misc"
});

local SettingTab = Window:DrawTab({
	Icon = "settings-3",
	Name = "Settings",
	Type = "Single",
	EnableScrolling = true
});

local ThemeTab = Window:DrawTab({
	Icon = "paintbrush",
	Name = "Themes",
	Type = "Single"
});

local Settings = SettingTab:DrawSection({
	Name = "UI Settings",
});

Settings:AddToggle({
	Name = "Alway Show Frame",
	Default = false,
	Callback = function(v)
		Window.AlwayShowTab = v;
	end,
});

Settings:AddColorPicker({
	Name = "Highlight",
	Default = Compkiller.Colors.Highlight,
	Callback = function(v)
		Compkiller.Colors.Highlight = v;
		Compkiller:RefreshCurrentColor();
	end,
});

Settings:AddColorPicker({
	Name = "Toggle Color",
	Default = Compkiller.Colors.Toggle,
	Callback = function(v)
		Compkiller.Colors.Toggle = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Drop Color",
	Default = Compkiller.Colors.DropColor,
	Callback = function(v)
		Compkiller.Colors.DropColor = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Risky",
	Default = Compkiller.Colors.Risky,
	Callback = function(v)
		Compkiller.Colors.Risky = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Mouse Enter",
	Default = Compkiller.Colors.MouseEnter,
	Callback = function(v)
		Compkiller.Colors.MouseEnter = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Block Color",
	Default = Compkiller.Colors.BlockColor,
	Callback = function(v)
		Compkiller.Colors.BlockColor = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Background Color",
	Default = Compkiller.Colors.BGDBColor,
	Callback = function(v)
		Compkiller.Colors.BGDBColor = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Block Background Color",
	Default = Compkiller.Colors.BlockBackground,
	Callback = function(v)
		Compkiller.Colors.BlockBackground = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Stroke Color",
	Default = Compkiller.Colors.StrokeColor,
	Callback = function(v)
		Compkiller.Colors.StrokeColor = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "High Stroke Color",
	Default = Compkiller.Colors.HighStrokeColor,
	Callback = function(v)
		Compkiller.Colors.HighStrokeColor = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Switch Color",
	Default = Compkiller.Colors.SwitchColor,
	Callback = function(v)
		Compkiller.Colors.SwitchColor = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Line Color",
	Default = Compkiller.Colors.LineColor,
	Callback = function(v)
		Compkiller.Colors.LineColor = v;
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddButton({
	Name = "Get Theme",
	Callback = function()
		print(Compkiller:GetTheme())

		Notifier.new({
			Title = "Notification",
			Content = "Copied Them Color to your clipboard",
			Duration = 5,
			Icon = "rbxassetid://72322195986989"
		});
	end,
});

ThemeTab:DrawSection({
	Name = "UI Themes"
}):AddDropdown({
	Name = "Select Theme",
	Default = "Default",
	Values = {
		"Default",
		"Dark Green",
		"Dark Blue",
		"Purple Rose",
		"Skeet"
	},
	Callback = function(v)
		Compkiller:SetTheme(v)
	end,
})

local ConfigUI = Window:DrawConfig({
	Name = "Config",
	Icon = "folder",
	Config = ConfigManager
});

ConfigUI:Init();
