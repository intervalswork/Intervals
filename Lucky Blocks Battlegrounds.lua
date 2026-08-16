local Compkiller = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/CompKiller/refs/heads/main/src/source.luau"))();

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Notifier = Compkiller.newNotify();

local ConfigManager = Compkiller:ConfigManager({
	Directory = "LuckyBlocks-Hub",
	Config = "Main-Config"
});

Compkiller:Loader("rbxassetid://72322195986989", 5).yield();

local Window = Compkiller.new({
	Name = "Lucky Blocks Hub",
	Keybind = "LeftAlt",
	Logo = "rbxassetid://72322195986989",
	TextSize = 15,
});

local Watermark = Window:Watermark();
Watermark:AddText({Icon = "user", Text = LocalPlayer.Name});
Watermark:AddText({Icon = "clock", Text = Compkiller:GetDate()});

task.spawn(function()
	while true do task.wait(1) end
end)

local MainTab = Window:DrawTab({Name = "Main", EnableScrolling = true});
local PlayerTab = Window:DrawTab({Name = "Player", EnableScrolling = true});
local VisualTab = Window:DrawTab({Name = "Visual", EnableScrolling = true});
local MiscTab = Window:DrawTab({Name = "Misc", EnableScrolling = true});

local BlockSection = MainTab:DrawSection({Name = "Auto Spawn", Position = 'left'});
local CharSection = PlayerTab:DrawSection({Name = "Character", Position = 'left'});
local MovSection = PlayerTab:DrawSection({Name = "Movement", Position = 'right'});
local EspSection = VisualTab:DrawSection({Name = "ESP", Position = 'left'});
local MiscSection = MiscTab:DrawSection({Name = "Misc", Position = 'left'});

local Remotes = {
	Lucky = ReplicatedStorage:WaitForChild("SpawnLuckyBlock"),
	Super = ReplicatedStorage:WaitForChild("SpawnSuperBlock"),
	Diamond = ReplicatedStorage:WaitForChild("SpawnDiamondBlock"),
	Rainbow = ReplicatedStorage:WaitForChild("SpawnRainbowBlock"),
	Galaxy = ReplicatedStorage:WaitForChild("SpawnGalaxyBlock")
}

local Flags = {
	AutoLucky = false, AutoSuper = false, AutoDiamond = false,
	AutoRainbow = false, AutoGalaxy = false,
	Speed = false, Jump = false,
	InfJump = false, Noclip = false, Fly = false,
	AntiAFK = false, PlayerESP = false,
	BlockESP = false
}

local Values = {Speed = 16, Jump = 50, FlySpeed = 50}

local function getChar()
	return LocalPlayer.Character
end

local function getHum()
	local char = getChar()
	return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function getRoot()
	local char = getChar()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function notify(title, content)
	Notifier.new({
		Title = title or "Notification",
		Content = content or "",
		Duration = 5,
		Icon = "rbxassetid://72322195986989"
	});
end

BlockSection:AddToggle({
	Name = "Auto Lucky Block",
	Flag = "AutoLucky",
	Default = false,
	Callback = function(v)
		Flags.AutoLucky = v
		if v then
			task.spawn(function()
				while Flags.AutoLucky do
					pcall(function() Remotes.Lucky:FireServer() end)
					task.wait(0.3)
				end
			end)
		end
	end
});

BlockSection:AddToggle({
	Name = "Auto Super Block",
	Flag = "AutoSuper",
	Default = false,
	Callback = function(v)
		Flags.AutoSuper = v
		if v then
			task.spawn(function()
				while Flags.AutoSuper do
					pcall(function() Remotes.Super:FireServer() end)
					task.wait(0.3)
				end
			end)
		end
	end
});

BlockSection:AddToggle({
	Name = "Auto Diamond Block",
	Flag = "AutoDiamond",
	Default = false,
	Callback = function(v)
		Flags.AutoDiamond = v
		if v then
			task.spawn(function()
				while Flags.AutoDiamond do
					pcall(function() Remotes.Diamond:FireServer() end)
					task.wait(0.3)
				end
			end)
		end
	end
});

BlockSection:AddToggle({
	Name = "Auto Rainbow Block",
	Flag = "AutoRainbow",
	Default = false,
	Callback = function(v)
		Flags.AutoRainbow = v
		if v then
			task.spawn(function()
				while Flags.AutoRainbow do
					pcall(function() Remotes.Rainbow:FireServer() end)
					task.wait(0.3)
				end
			end)
		end
	end
});

BlockSection:AddToggle({
	Name = "Auto Galaxy Block",
	Flag = "AutoGalaxy",
	Default = false,
	Callback = function(v)
		Flags.AutoGalaxy = v
		if v then
			task.spawn(function()
				while Flags.AutoGalaxy do
					pcall(function() Remotes.Galaxy:FireServer() end)
					task.wait(0.3)
				end
			end)
		end
	end
});

CharSection:AddToggle({
	Name = "Speed Hack",
	Flag = "SpeedHack",
	Default = false,
	Callback = function(v)
		Flags.Speed = v
		local hum = getHum()
		if hum then hum.WalkSpeed = v and Values.Speed or 16 end
	end
});

CharSection:AddSlider({
	Name = "Speed Value",
	Min = 16, Max = 200, Default = 16, Round = 0,
	Flag = "SpeedValue",
	Callback = function(v)
		Values.Speed = v
		if Flags.Speed then
			local hum = getHum()
			if hum then hum.WalkSpeed = v end
		end
	end
});

CharSection:AddToggle({
	Name = "Jump Power",
	Flag = "JumpPower",
	Default = false,
	Callback = function(v)
		Flags.Jump = v
		local hum = getHum()
		if hum then hum.JumpPower = v and Values.Jump or 50 end
	end
});

CharSection:AddSlider({
	Name = "Jump Value",
	Min = 50, Max = 200, Default = 50, Round = 0,
	Flag = "JumpValue",
	Callback = function(v)
		Values.Jump = v
		if Flags.Jump then
			local hum = getHum()
			if hum then hum.JumpPower = v end
		end
	end
});

CharSection:AddToggle({
	Name = "Infinite Jump",
	Flag = "InfJump",
	Default = false,
	Callback = function(v) Flags.InfJump = v end
});

UserInputService.JumpRequest:Connect(function()
	if Flags.InfJump then
		local hum = getHum()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end);

local NoclipConnection
CharSection:AddToggle({
	Name = "Noclip",
	Flag = "Noclip",
	Default = false,
	Callback = function(v)
		Flags.Noclip = v
		if v then
			NoclipConnection = RunService.Stepped:Connect(function()
				local char = getChar()
				if char then
					for _, p in pairs(char:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = false end
					end
				end
			end)
		else
			if NoclipConnection then NoclipConnection:Disconnect() NoclipConnection = nil end
			local char = getChar()
			if char then
				for _, p in pairs(char:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = true end
				end
			end
		end
	end
});

local FlyConn, FlyDown, FlyUp
local FlyVec = {F = 0, B = 0, L = 0, R = 0, U = 0, D = 0}
local Flying = false

MovSection:AddToggle({
	Name = "Fly",
	Flag = "Fly",
	Default = false,
	Callback = function(v)
		Flags.Fly = v
		local hrp = getRoot()
		if not hrp then return end
		if v then
			local bv = Instance.new("BodyVelocity")
			bv.Name = "FlyVel"
			bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			bv.Velocity = Vector3.zero
			bv.Parent = hrp
			local bg = Instance.new("BodyGyro")
			bg.Name = "FlyGyro"
			bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			bg.P = 9e4
			bg.Parent = hrp
			Flying = true
			FlyConn = RunService.RenderStepped:Connect(function()
				if not Flying or not hrp.Parent then return end
				local cam = Workspace.CurrentCamera
				bv.Velocity = (cam.CFrame.LookVector * (FlyVec.F - FlyVec.B) +
					cam.CFrame.RightVector * (FlyVec.R - FlyVec.L) +
					cam.CFrame.UpVector * (FlyVec.U - FlyVec.D)) * Values.FlySpeed
				bg.CFrame = cam.CFrame
			end)
			FlyDown = UserInputService.InputBegan:Connect(function(inp, gpe)
				if gpe then return end
				if inp.KeyCode == Enum.KeyCode.W then FlyVec.F = 1 end
				if inp.KeyCode == Enum.KeyCode.S then FlyVec.B = 1 end
				if inp.KeyCode == Enum.KeyCode.A then FlyVec.L = 1 end
				if inp.KeyCode == Enum.KeyCode.D then FlyVec.R = 1 end
				if inp.KeyCode == Enum.KeyCode.Space then FlyVec.U = 1 end
				if inp.KeyCode == Enum.KeyCode.LeftShift then FlyVec.D = 1 end
			end)
			FlyUp = UserInputService.InputEnded:Connect(function(inp)
				if inp.KeyCode == Enum.KeyCode.W then FlyVec.F = 0 end
				if inp.KeyCode == Enum.KeyCode.S then FlyVec.B = 0 end
				if inp.KeyCode == Enum.KeyCode.A then FlyVec.L = 0 end
				if inp.KeyCode == Enum.KeyCode.D then FlyVec.R = 0 end
				if inp.KeyCode == Enum.KeyCode.Space then FlyVec.U = 0 end
				if inp.KeyCode == Enum.KeyCode.LeftShift then FlyVec.D = 0 end
			end)
		else
			Flying = false
			if FlyConn then FlyConn:Disconnect() end
			if FlyDown then FlyDown:Disconnect() end
			if FlyUp then FlyUp:Disconnect() end
			if hrp:FindFirstChild("FlyVel") then hrp.FlyVel:Destroy() end
			if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
		end
	end
});

MovSection:AddSlider({
	Name = "Fly Speed",
	Min = 10, Max = 200, Default = 50, Round = 0,
	Flag = "FlySpeed",
	Callback = function(v) Values.FlySpeed = v end
});

local function createESP(parent, text, color)
	if parent:FindFirstChild("LBEsp") then return end
	local bg = Instance.new("BillboardGui")
	bg.Name = "LBEsp"
	bg.Size = UDim2.new(0, 120, 0, 40)
	bg.AlwaysOnTop = true
	bg.Adornee = parent
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = color or Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0
	tl.Text = text or ""
	tl.TextSize = 14
	tl.Parent = bg
	bg.Parent = parent
end

local function clearESP(name)
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("BillboardGui") and obj.Name == name then
			obj:Destroy()
		end
	end
end

EspSection:AddToggle({
	Name = "Player ESP",
	Flag = "PlayerESP",
	Default = false,
	Callback = function(v)
		Flags.PlayerESP = v
		if v then
			task.spawn(function()
				while Flags.PlayerESP do
					pcall(function()
						for _, plr in pairs(Players:GetPlayers()) do
							if plr ~= LocalPlayer and plr.Character then
								local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
								if hrp then createESP(hrp, plr.Name, Color3.fromRGB(255, 0, 0)) end
							end
						end
					end)
					task.wait(2)
				end
			end)
		else
			clearESP("LBEsp")
		end
	end
});

EspSection:AddToggle({
	Name = "Block ESP",
	Flag = "BlockESP",
	Default = false,
	Callback = function(v)
		Flags.BlockESP = v
		if v then
			task.spawn(function()
				while Flags.BlockESP do
					pcall(function()
						for _, obj in pairs(Workspace:GetDescendants()) do
							if obj:IsA("BasePart") and (obj.Name:lower():match("block") or obj.Name:lower():match("lucky")) then
								createESP(obj, obj.Name, Color3.fromRGB(0, 255, 255))
							end
						end
					end)
					task.wait(3)
				end
			end)
		else
			clearESP("LBEsp")
		end
	end
});

MiscSection:AddToggle({
	Name = "Anti-AFK",
	Flag = "AntiAFK",
	Default = false,
	Callback = function(v)
		Flags.AntiAFK = v
		if v then
			local vu = game:GetService("VirtualUser")
			LocalPlayer.Idled:Connect(function()
				if Flags.AntiAFK then
					vu:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
					task.wait(1)
					vu:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
				end
			end)
		end
	end
});

MiscSection:AddButton({
	Name = "Rejoin Server",
	Callback = function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
	end
});

MiscSection:AddButton({
	Name = "Server Hop",
	Callback = function()
		local http = game:GetService("HttpService")
		local ts = game:GetService("TeleportService")
		local servers = {}
		local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
		local data = http:JSONDecode(req)
		for _, s in pairs(data.data) do
			if s.playing < s.maxPlayers and s.id ~= game.JobId then
				table.insert(servers, s.id)
			end
		end
		if #servers > 0 then
			ts:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
		else
			notify("Server Hop", "No servers found")
		end
	end
});

local ConfigUI = Window:DrawConfig({
	Name = "Config",
	Icon = "folder",
	Config = ConfigManager
});
ConfigUI:Init();

LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	local hum = char:WaitForChild("Humanoid")
	if Flags.Speed then hum.WalkSpeed = Values.Speed end
	if Flags.Jump then hum.JumpPower = Values.Jump end
end);

notify("Loaded", "Lucky Blocks Hub Loaded Successfully!")
