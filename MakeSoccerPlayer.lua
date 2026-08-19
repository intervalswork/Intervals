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

local MenuKey = Enum.KeyCode.LeftAlt
local CurrentSpeed = 16
local SpeedEnabled = false
local AutoFuseEnabled = false
local AutoSellEnabled = false
local SellRunning = false
local AntiAfkEnabled = true
local FuseTargets = {}
local FuseLock = 5
local SellBelowOVR = 70
local SellDelay = 1
local SoldIds = {}
local FailedIds = {}


local CONFIG = {
	FuseRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerEconomy"):WaitForChild("MachineInteract"),
	SellRequestRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerEconomy"):WaitForChild("RequestSellOffer"),
	SellRespondRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerEconomy"):WaitForChild("RespondSellOffer"),
}

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

local function GetInventoryCards()
	local cards = {}
	local PlotInventory = LocalPlayer:FindFirstChild("PlotInventory")
	if not PlotInventory then return cards end

	for _, item in pairs(PlotInventory:GetChildren()) do
		if item:IsA("StringValue") then
			local amount = tonumber(item:GetAttribute("Amount"))
				or tonumber(item:GetAttribute("Quantity"))
				or tonumber(item:GetAttribute("Count"))
				or 1

			local base = {
				Name = item.Name,
				ItemId = item:GetAttribute("InventoryCardId") or item:GetAttribute("CardToolId"),
				PlayerName = item:GetAttribute("PlayerName"),
				LeagueId = item:GetAttribute("LeagueId"),
				OVR = item:GetAttribute("OVR"),
				IsFused = item:GetAttribute("IsFused"),
			}
			for _ = 1, amount do
				table.insert(cards, base)
			end
		end
	end
	return cards
end

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

local GUID_PATTERN = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

local function IsGuid(v)
	return type(v) == "string" and string.match(v, GUID_PATTERN) ~= nil
end

local function FindCardId(item)

	for _, key in ipairs({"ItemId", "CardId", "CardToolId", "InventoryCardId", "UniqueId", "UID", "Guid", "GUID", "Id"}) do
		local v = item:GetAttribute(key)
		if IsGuid(v) then return v end
	end

	for _, v in pairs(item:GetAttributes()) do
		if IsGuid(v) then return v end
	end

	for _, child in ipairs(item:GetDescendants()) do
		if child:IsA("StringValue") and IsGuid(child.Value) then
			return child.Value
		end
	end

	if IsGuid(item.Name) then return item.Name end
	return nil
end

local RecentOfferIds = {}
local LastSellRequest = 0

local function RememberOfferId(id, src)
	if not IsGuid(id) then return end
	for _, rec in ipairs(RecentOfferIds) do
		if rec.Id == id then
			rec.Time = tick()
			return
		end
	end
	table.insert(RecentOfferIds, 1, {Id = id, Time = tick(), Src = src})
	if #RecentOfferIds > 25 then table.remove(RecentOfferIds) end
end

local function ScanForGuid(v, cb, depth)
	depth = depth or 0
	if IsGuid(v) then
		cb(v)
	elseif typeof(v) == "Instance" then
		if v:IsA("StringValue") and IsGuid(v.Value) then cb(v.Value) end
		if IsGuid(v.Name) then cb(v.Name) end
	elseif type(v) == "table" and depth < 4 then
		for _, v2 in pairs(v) do
			ScanForGuid(v2, cb, depth + 1)
		end
	end
end

task.spawn(function()
	local function HookRemoteEvent(re)
		re.OnClientEvent:Connect(function(...)
			if tick() - LastSellRequest > 8 then return end
			for _, a in ipairs({...}) do
				ScanForGuid(a, function(g) RememberOfferId(g, "RE:" .. re.Name) end)
			end
		end)
	end
	for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
		if d:IsA("RemoteEvent") then
			pcall(HookRemoteEvent, d)
		end
	end
	ReplicatedStorage.DescendantAdded:Connect(function(d)
		if d:IsA("RemoteEvent") then pcall(HookRemoteEvent, d) end
	end)
end)

LocalPlayer.DescendantAdded:Connect(function(d)
	if tick() - LastSellRequest > 8 then return end
	if d:IsA("StringValue") then
		if IsGuid(d.Value) then RememberOfferId(d.Value, "SV:" .. d.Name) end
		if IsGuid(d.Name) then RememberOfferId(d.Name, "SV-name:" .. d.Name) end
	end
end)

local LEAGUE_KEYWORDS = {"league", "la liga", "serie a", "bundesliga", "ligue 1", "liga mx", "coach", "pack"}

local function GetSellableOVR(item)
	local ovr = item:GetAttribute("OVR")
	if type(ovr) == "string" then ovr = tonumber(ovr) end
	if type(ovr) ~= "number" then return nil end

	local hasPlayerAttr = item:GetAttribute("PlayerId") ~= nil
		or item:GetAttribute("SourceCardKey") ~= nil
		or item:GetAttribute("WorldCupCardKey") ~= nil
		or item:GetAttribute("Valuation") ~= nil
	if not hasPlayerAttr then return nil end

	if item:GetAttribute("LeagueId") ~= nil and item:GetAttribute("PlayerId") == nil then return nil end
	local n = string.lower(item.Name)
	for _, kw in ipairs(LEAGUE_KEYWORDS) do
		if string.find(n, kw, 1, true) then return nil end
	end

	return ovr
end

local function GetBackpackCards()
	local cards = {}
	local Backpack = LocalPlayer:FindFirstChild("Backpack")
	if not Backpack then return cards end

	for _, item in pairs(Backpack:GetChildren()) do

		local ovr = GetSellableOVR(item)
		if ovr then
			table.insert(cards, {
				Tool = item,
				Name = item.Name,
				OVR = ovr,
				PlayerName = item:GetAttribute("PlayerName") or item.Name,
				CardId = FindCardId(item),
			})
		end
	end
	return cards
end

local function CollectCandidateIds(cardId, retValues)
	local cands, seen = {}, {}
	local function add(id)
		if IsGuid(id) and not seen[id] then
			seen[id] = true
			table.insert(cands, id)
		end
	end

	for _, r in ipairs(retValues) do
		ScanForGuid(r, function(g)
			if g ~= cardId then add(g) end
		end)
	end

	for _, rec in ipairs(RecentOfferIds) do
		if (tick() - rec.Time) < 8 and rec.Id ~= cardId then
			add(rec.Id)
		end
	end

	add(cardId)
	return cands
end

local function IsCardGone(item)
	local Backpack = LocalPlayer:FindFirstChild("Backpack")
	if not Backpack then return true end
	if not item then return true end
	local ok, res = pcall(function()
		return item:IsDescendantOf(Backpack)
	end)
	return not ok or not res
end

local function SellOneCard(card)
	local item = card.Tool
	if not item or not item.Parent then return false, "card removed" end

	local cardId = card.CardId or FindCardId(item)
	if not cardId then
		local attrs = {}
		for k, v in pairs(item:GetAttributes()) do
			table.insert(attrs, tostring(k) .. "=" .. tostring(v))
		end
		warn("[Auto Sell] No GUID found on '" .. tostring(item.Name) .. "' -> " .. table.concat(attrs, ", "))
		return false, "no card id"
	end

	if SoldIds[cardId] then return false, "already sold" end

	LastSellRequest = tick()
	local packed = table.pack(pcall(function()
		return CONFIG.SellRequestRemote:InvokeServer(cardId)
	end))
	local ok = table.remove(packed, 1)
	if not ok then return false, tostring(packed[1]) end

	task.wait(0.4)

	local cands = CollectCandidateIds(cardId, {packed[1], packed[2], packed[3], packed[4]})

	for _, offerId in ipairs(cands) do
		local ok2, err2 = pcall(function()
			CONFIG.SellRespondRemote:InvokeServer(offerId, true)
		end)
		if not ok2 then
			warn("[Auto Sell] RespondSellOffer error:", tostring(err2))
		end
		task.wait(0.7)
		if IsCardGone(item) then
			SoldIds[cardId] = true
			return true
		end
	end

	task.wait(1)
	for _, offerId in ipairs(cands) do
		pcall(function()
			CONFIG.SellRespondRemote:InvokeServer(offerId, true)
		end)
		task.wait(0.7)
		if IsCardGone(item) then
			SoldIds[cardId] = true
			return true
		end
	end

	warn("[Auto Sell] Sell failed:", card.Name, "| cardId:", cardId, "| tried", #cands, "offer ids")
	return false, "respond failed"
end

local function DoAutoSell(manual)
	if SellRunning then return end
	if not manual and not AutoSellEnabled then return end

	local cards = {}
	for _, card in ipairs(GetBackpackCards()) do
		if card.OVR < SellBelowOVR then
			local skip = false
			if card.CardId and SoldIds[card.CardId] then skip = true end
			if card.CardId and FailedIds[card.CardId] and (tick() - FailedIds[card.CardId]) < 30 then skip = true end
			if not skip then table.insert(cards, card) end
		end
	end

	if #cards == 0 then
		if manual then
			Notifier.new({
				Title = "Auto Sell",
				Content = "No fused cards below OVR " .. SellBelowOVR,
				Duration = 3,
				Icon = "rbxassetid://72322195986989"
			});
		end
		return
	end

	SellRunning = true

	Notifier.new({
		Title = "Auto Sell",
		Content = "Selling " .. #cards .. " cards (OVR < " .. SellBelowOVR .. ")...",
		Duration = 3,
		Icon = "rbxassetid://72322195986989"
	});

	local sold, failed = 0, 0
	for _, card in ipairs(cards) do
		if not manual and not AutoSellEnabled then break end
		local ok, err = SellOneCard(card)
		if ok then
			sold += 1
		else
			failed += 1
			if card.CardId then FailedIds[card.CardId] = tick() end
			warn("[Auto Sell] Failed:", card.Name, "|", err)
		end
		task.wait(SellDelay)
	end

	if sold > 0 or manual then
		Notifier.new({
			Title = "Auto Sell",
			Content = "Sold " .. sold .. "/" .. #cards .. " cards" .. (failed > 0 and " (" .. failed .. " failed)" or ""),
			Duration = 4,
			Icon = "rbxassetid://72322195986989"
		});
	end

	SellRunning = false
end

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

task.spawn(function()
	while true do
		task.wait(1)
		if AutoFuseEnabled then DoAutoFuse() end
	end
end)

task.spawn(function()
	while true do
		task.wait(2)
		if AutoSellEnabled then
			local ok, err = pcall(DoAutoSell)
			if not ok then
				SellRunning = false
				warn("[Auto Sell] Error:", err)
			end
		end
	end
end)

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

NormalSection:AddToggle({
	Name = "Auto Fuse",
	Flag = "Toggle_AutoFuse",
	Default = false,
	Callback = function(v)
		AutoFuseEnabled = v
	end,
});

NormalSection:AddSlider({
	Name = "Sell Below OVR",
	Min = 1,
	Max = 125,
	Default = 70,
	Round = 0,
	Flag = "Slider_SellBelowOVR",
	Callback = function(v)
		SellBelowOVR = v
	end
})

NormalSection:AddSlider({
	Name = "Sell Delay",
	Min = 0.3,
	Max = 5,
	Default = 1,
	Round = 1,
	Flag = "Slider_SellDelay",
	Callback = function(v)
		SellDelay = v
	end
})

NormalSection:AddToggle({
	Name = "Auto Sell ( Wait 10-60s )",
	Flag = "Toggle_AutoSell",
	Default = false,
	Callback = function(v)
		AutoSellEnabled = v
		if v then
			Notifier.new({
				Title = "Auto Sell",
				Content = "Enabled (sell OVR < " .. SellBelowOVR .. ")",
				Duration = 3,
				Icon = "rbxassetid://72322195986989"
			});
		else
			SellRunning = false
		end
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
		Compkiller:RefreshCurrentColor(v);
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
