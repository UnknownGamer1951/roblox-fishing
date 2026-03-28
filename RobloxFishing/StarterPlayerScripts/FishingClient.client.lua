-- ============================================================
-- FishingClient.lua  (LocalScript in StarterPlayerScripts)
-- Stardew-style minigame + AC tourney countdown
-- Hold LEFT CLICK to lift the catch bar
-- ============================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes     = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
local localPlayer = Players.LocalPlayer

-- ── State ─────────────────────────────────────────────────────
local RARITY_COLORS = {
	Common    = Color3.fromRGB(200, 200, 200),
	Uncommon  = Color3.fromRGB(100, 220, 100),
	Rare      = Color3.fromRGB(80, 140, 255),
	Legendary = Color3.fromRGB(255, 180, 0),
}

local isFishing      = false
local isBiting       = false
local minigameActive = false
local isHoldingBar   = false

-- ── Base difficulty per rarity (modified by server upgrade params) ──
local DIFFICULTY = {
	Common    = { barHeight=0.34, fishAccel=3.0,  fishDamping=4.5, drainRate=0.09, fillRate=0.24 },
	Uncommon  = { barHeight=0.28, fishAccel=4.5,  fishDamping=4.5, drainRate=0.13, fillRate=0.21 },
	Rare      = { barHeight=0.22, fishAccel=6.0,  fishDamping=5.0, drainRate=0.17, fillRate=0.18 },
	Legendary = { barHeight=0.16, fishAccel=8.5,  fishDamping=5.5, drainRate=0.22, fillRate=0.16 },
}

local RARITY_HEX = {
	Common    = "#C8C8C8",
	Uncommon  = "#64DC64",
	Rare      = "#508CFF",
	Legendary = "#FFB400",
}
local function coloredName(rarity, name)
	local hex = RARITY_HEX[rarity] or "#FFFFFF"
	return '<font color="' .. hex .. '">' .. (name or "Fish") .. '</font>'
end

local mg = { barY=0.33, fishY=0.5, fishVel=0, fishTarget=0.5, targetTimer=0, progress=0.3, difficulty=nil }
local minigameConn = nil

-- ── Helpers ───────────────────────────────────────────────────
local function getGui()
	return localPlayer.PlayerGui:FindFirstChild("FishingGui")
end

local function setStatus(text)
	local gui = getGui()
	if not gui then return end
	local label = gui:FindFirstChild("StatusLabel", true)
	if label then label.Text = text end
end

-- ── End minigame ──────────────────────────────────────────────
local function endMinigame(win)
	if not minigameActive then return end
	minigameActive = false
	isHoldingBar   = false
	if minigameConn then minigameConn:Disconnect(); minigameConn = nil end
	local gui = getGui()
	if gui then
		local p = gui:FindFirstChild("MinigamePanel")
		if p then p.Visible = false end
	end
	isFishing = false
	isBiting  = false
	if win then Remotes.MinigameWon:FireServer()
	else        Remotes.MinigameLost:FireServer() end
end

-- ── Start minigame ────────────────────────────────────────────
local function startMinigame(rarity, fishSpeedMult, barBonus)
	local base = DIFFICULTY[rarity] or DIFFICULTY.Common
	local diff = {
		barHeight   = math.clamp(base.barHeight + (barBonus or 0), 0.10, 0.60),
		fishAccel   = base.fishAccel   * (fishSpeedMult or 1),
		fishDamping = base.fishDamping * (fishSpeedMult or 1),
		drainRate   = base.drainRate,
		fillRate    = base.fillRate,
	}
	mg.difficulty  = diff
	mg.barY        = 0.33
	mg.fishY       = math.random() * 0.5 + 0.25
	mg.fishVel     = 0
	mg.fishTarget  = math.random() * 0.6 + 0.2
	mg.targetTimer = 0
	mg.progress    = 0.3
	minigameActive = true

	local gui = getGui()
	if not gui then return end
	local panel = gui:FindFirstChild("MinigamePanel")
	if not panel then return end

	local container = panel:FindFirstChild("Container")
	if container then
		local bar = container:FindFirstChild("CatchBar")
		if bar then bar.Size = UDim2.new(0.9, 0, diff.barHeight, 0) end
		local holdArea = container:FindFirstChild("HoldArea")
		if holdArea then
			holdArea.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch then
					isHoldingBar = true
				end
			end)
			holdArea.InputEnded:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch then
					isHoldingBar = false
				end
			end)
		end
	end
	panel.Visible = true

	if minigameConn then minigameConn:Disconnect() end
	minigameConn = RunService.Heartbeat:Connect(function(dt)
		if not minigameActive then return end
		local d = mg.difficulty

		mg.targetTimer -= dt
		if mg.targetTimer <= 0 then
			mg.fishTarget  = math.random() * 0.80 + 0.10
			mg.targetTimer = math.random() * 1.4  + 0.6
		end

		local err  = mg.fishTarget - mg.fishY
		mg.fishVel = mg.fishVel + err * d.fishAccel * dt * 10
		mg.fishVel = mg.fishVel * (1 - d.fishDamping * dt)
		mg.fishY   = math.clamp(mg.fishY + mg.fishVel * dt, 0.02, 0.97)

		if isHoldingBar then
			mg.barY = math.clamp(mg.barY - 0.65 * dt, 0, 1 - d.barHeight)
		else
			mg.barY = math.clamp(mg.barY + 0.85 * dt, 0, 1 - d.barHeight)
		end

		local inside = mg.fishY >= mg.barY and mg.fishY <= mg.barY + d.barHeight
		if inside then
			mg.progress = math.clamp(mg.progress + d.fillRate  * dt, 0, 1)
		else
			mg.progress = math.clamp(mg.progress - d.drainRate * dt, 0, 1)
		end

		local gui2   = getGui()
		if not gui2 then return end
		local panel2 = gui2:FindFirstChild("MinigamePanel")
		if not panel2 then return end

		local cont = panel2:FindFirstChild("Container")
		if cont then
			local bar2 = cont:FindFirstChild("CatchBar")
			if bar2 then
				bar2.Position         = UDim2.new(0.05, 0, mg.barY, 0)
				bar2.Size             = UDim2.new(0.9,  0, d.barHeight, 0)
				bar2.BackgroundColor3 = inside and Color3.fromRGB(60,210,80) or Color3.fromRGB(255,150,30)
			end
			local fishEl = cont:FindFirstChild("FishIcon")
			if fishEl then fishEl.Position = UDim2.new(0.1, 0, mg.fishY - 0.035, 0) end
		end
		local pgBg = panel2:FindFirstChild("ProgressBg")
		if pgBg then
			local fill = pgBg:FindFirstChild("ProgressFill")
			if fill then
				fill.Size             = UDim2.new(1, 0, mg.progress, 0)
				fill.Position         = UDim2.new(0, 0, 1 - mg.progress, 0)
				fill.BackgroundColor3 = inside and Color3.fromRGB(60,210,80) or Color3.fromRGB(255,80,50)
			end
		end

		if     mg.progress >= 1 then endMinigame(true)
		elseif mg.progress <= 0 then endMinigame(false) end
	end)
end

-- ── Input ─────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(inp, gp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 and minigameActive then
		isHoldingBar = true
	end
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.Escape and minigameActive then
		endMinigame(false)
	end
end)

UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		isHoldingBar = false
	end
end)

-- ── Server → Client events ────────────────────────────────────
Remotes.BobberLanded.OnClientEvent:Connect(function(pos)
	isFishing = true; isBiting = false
	setStatus("Line in water... wait for a bite!")
	print("[FishingClient] Bobber landed at", pos)
end)

Remotes.FishBiting.OnClientEvent:Connect(function(rarity, fishName, fishSpeedMult, barBonus)
	isBiting = true
	setStatus(coloredName(rarity, fishName) .. " is on the line!")
	local gui = getGui()
	if gui then
		local panel = gui:FindFirstChild("MinigamePanel")
		if panel then
			local title = panel:FindFirstChild("TitleLabel")
			if title then title.Text = (fishName or "Fish") .. " on the line!" end
		end
	end
	startMinigame(rarity or "Common", fishSpeedMult, barBonus)
end)

Remotes.FishCaught.OnClientEvent:Connect(function(info)
	isFishing = false; isBiting = false
	setStatus(string.format("Caught a %s %s (%d cm)! Sell at the shop.", info.rarity, info.name, info.size))
	local gui = getGui()
	if gui then
		local popup = gui:FindFirstChild("CatchPopup")
		if popup then
			local rarColor = RARITY_COLORS[info.rarity] or Color3.new(1,1,1)
			local n = popup:FindFirstChild("FishNameLabel")
			if n then n.Text = info.name; n.TextColor3 = rarColor end
			local r = popup:FindFirstChild("FishRarityLabel")
			if r then r.Text = info.rarity; r.TextColor3 = rarColor end
			local s = popup:FindFirstChild("FishSizeLabel")
			if s then s.Text = info.size .. " cm" end
			popup.Visible = true
			task.delay(4, function() if popup then popup.Visible = false end end)
		end
	end
	task.delay(4, function()
		if not isFishing then setStatus("Walk up to water and press [E] to fish.") end
	end)
end)

Remotes.FishMissed.OnClientEvent:Connect(function()
	isFishing = false; isBiting = false
	setStatus("The fish got away!")
	task.delay(2, function()
		if not isFishing then setStatus("Walk up to water and press [E] to fish.") end
	end)
end)

-- ── Tournament events ─────────────────────────────────────────
Remotes.TournamentStart.OnClientEvent:Connect(function(duration)
	local gui = getGui()
	if not gui then return end
	local hud = gui:FindFirstChild("TourneyHUD")
	if not hud then return end
	hud.Visible = true
	local tlbl = hud:FindFirstChild("TimerLabel")
	local flbl = hud:FindFirstChild("FishCountLabel")
	if flbl then flbl.Text = "0 fish this run" end
	local t = duration
	while t > 0 and hud.Visible do
		task.wait(1); t -= 1
		if tlbl then
			tlbl.Text       = string.format("%d:%02d", math.floor(t/60), t%60)
			tlbl.TextColor3 = t <= 30 and Color3.fromRGB(255,80,80) or Color3.fromRGB(255,220,60)
		end
	end
end)

Remotes.TournamentPoints.OnClientEvent:Connect(function(fishRun, totalPts)
	local gui = getGui()
	if not gui then return end
	local hud = gui:FindFirstChild("TourneyHUD")
	if not hud then return end
	local f = hud:FindFirstChild("FishCountLabel")
	local p = hud:FindFirstChild("PointsLabel")
	if f then f.Text = string.format("%d fish%s", fishRun, fishRun >= 3 and " BONUS!" or "") end
	if p then p.Text = string.format("%d pts total", totalPts) end
end)

Remotes.TournamentEnd.OnClientEvent:Connect(function(data)
	local gui = getGui()
	if not gui then return end
	local hud = gui:FindFirstChild("TourneyHUD")
	if hud then hud.Visible = false end
	local res = gui:FindFirstChild("TourneyResult")
	if not res then return end
	local tl = res:FindFirstChild("TrophyLabel")
	if tl then tl.Text = data.trophy ~= "none" and data.trophy or "Keep fishing for a trophy!" end
	local fl = res:FindFirstChild("FishLabel")
	if fl then fl.Text = string.format("Caught %d fish this round", data.fishCaught) end
	local bl = res:FindFirstChild("BonusLabel")
	if bl then
		bl.Text       = data.bonus and "+2 Bonus for catching 3+ fish!" or "Catch 3+ next round for a bonus!"
		bl.TextColor3 = data.bonus and Color3.fromRGB(255,210,60) or Color3.fromRGB(140,140,140)
	end
	local ttl = res:FindFirstChild("TotalLabel")
	if ttl then ttl.Text = string.format("Total: %d points this session", data.totalPoints) end
	res.Visible = true
end)

task.delay(1, function() setStatus("Walk up to water and press [E] to fish.") end)
print("[FishingClient] Loaded!")
