-- ============================================================
-- TutorialGui.client.lua  (LocalScript in StarterGui/TutorialGui)
-- Shows two UI elements:
--   1. Checklist panel  — top-left, lists all 5 steps
--   2. Dialog box       — bottom-centre, shows NPC conversations
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Remotes   = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
local player    = Players.LocalPlayer
local gui       = script.Parent  -- the ScreenGui

-- ── Step definitions (must match TutorialManager) ─────────────────
local STEPS = {
	{ label = "Cast your line & catch a fish" },
	{ label = "Sell a fish at the shop"       },
	{ label = "Equip non-basic bait"          },
	{ label = "Talk to the Navigator"         },
}
-- tutorialStep value the server sends:
--   0 = before step 1 starts (guide not yet talked to)
--   1 = step 1 active (cast)
--   2 = step 2 active (catch)
--   … etc.
--   6 = all done

local currentStep = 0   -- updated by TutorialStep event

-- ── Colours ────────────────────────────────────────────────────────
local C_BG        = Color3.fromRGB(8,  18, 32)
local C_DONE      = Color3.fromRGB(70, 200, 90)
local C_ACTIVE    = Color3.fromRGB(255, 200, 50)
local C_PENDING   = Color3.fromRGB(130, 130, 130)
local C_TITLE     = Color3.fromRGB(100, 210, 255)
local C_BORDER    = Color3.fromRGB(40,  80, 120)

-- ══════════════════════════════════════════════════════════════════
--  CHECKLIST PANEL
-- ══════════════════════════════════════════════════════════════════

local checkPanel = Instance.new("Frame")
checkPanel.Name              = "TutorialChecklist"
checkPanel.Size              = UDim2.new(0, 230, 0, 144)  -- 38 header + 4 steps * 26
checkPanel.Position          = UDim2.new(0, 14, 0, 70)
checkPanel.BackgroundColor3  = C_BG
checkPanel.BackgroundTransparency = 0.18
checkPanel.BorderSizePixel   = 0
checkPanel.Parent            = gui
Instance.new("UICorner", checkPanel).CornerRadius = UDim.new(0, 10)

local panelStroke = Instance.new("UIStroke", checkPanel)
panelStroke.Color     = C_BORDER
panelStroke.Thickness = 1.5
panelStroke.Transparency = 0.3

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size              = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3  = Color3.fromRGB(15, 35, 65)
titleBar.BorderSizePixel   = 0
titleBar.Parent            = checkPanel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size             = UDim2.new(1, 0, 1, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text             = "Tutorial"
titleLbl.TextColor3       = C_TITLE
titleLbl.TextScaled       = true
titleLbl.Font             = Enum.Font.GothamBold

-- Step rows container
local rowList = Instance.new("Frame")
rowList.Size             = UDim2.new(1, -8, 1, -34)
rowList.Position         = UDim2.new(0, 4, 0, 30)
rowList.BackgroundTransparency = 1
rowList.Parent           = checkPanel
local layout = Instance.new("UIListLayout", rowList)
layout.SortOrder         = Enum.SortOrder.LayoutOrder
layout.Padding           = UDim.new(0, 2)

-- Build one row per step
local stepLabels = {}
for i, step in ipairs(STEPS) do
	local row = Instance.new("Frame")
	row.Name               = "Step" .. i
	row.Size               = UDim2.new(1, 0, 0, 24)
	row.BackgroundTransparency = 1
	row.LayoutOrder        = i
	row.Parent             = rowList

	local icon = Instance.new("TextLabel", row)
	icon.Size              = UDim2.new(0, 22, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text              = "○"
	icon.TextColor3        = C_PENDING
	icon.TextScaled        = true
	icon.Font              = Enum.Font.GothamBold

	local lbl = Instance.new("TextLabel", row)
	lbl.Size              = UDim2.new(1, -26, 1, 0)
	lbl.Position          = UDim2.new(0, 24, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text              = step.label
	lbl.TextColor3        = C_PENDING
	lbl.TextScaled        = true
	lbl.Font              = Enum.Font.Gotham
	lbl.TextXAlignment    = Enum.TextXAlignment.Left

	stepLabels[i] = { icon = icon, lbl = lbl }
end

-- "All done" banner (hidden initially)
local doneLabel = Instance.new("TextLabel")
doneLabel.Size              = UDim2.new(1, 0, 0, 28)
doneLabel.Position          = UDim2.new(0, 0, 1, -30)
doneLabel.BackgroundTransparency = 1
doneLabel.Text              = "Tutorial complete!"
doneLabel.TextColor3        = C_DONE
doneLabel.TextScaled        = true
doneLabel.Font              = Enum.Font.GothamBold
doneLabel.Visible           = false
doneLabel.Parent            = checkPanel

local function refreshChecklist(step)
	-- Resize panel: shrink if done
	local allDone = step >= #STEPS + 1   -- step 6 = completed
	doneLabel.Visible = allDone
	rowList.Visible   = not allDone

	if allDone then
		checkPanel.Size = UDim2.new(0, 230, 0, 60)
		return
	end
	checkPanel.Size = UDim2.new(0, 230, 0, 38 + #STEPS * 26)

	for i, row in ipairs(stepLabels) do
		-- step == i means step i is currently active (1-indexed)
		if i < step then
			-- completed
			row.icon.Text       = "✓"
			row.icon.TextColor3 = C_DONE
			row.lbl.TextColor3  = C_DONE
		elseif i == step then
			-- active
			row.icon.Text       = "▶"
			row.icon.TextColor3 = C_ACTIVE
			row.lbl.TextColor3  = C_ACTIVE
		else
			-- pending
			row.icon.Text       = "○"
			row.icon.TextColor3 = C_PENDING
			row.lbl.TextColor3  = C_PENDING
		end
	end
end

-- ══════════════════════════════════════════════════════════════════
--  NPC DIALOG BOX
-- ══════════════════════════════════════════════════════════════════

local dialogBox = Instance.new("Frame")
dialogBox.Name              = "DialogBox"
dialogBox.Size              = UDim2.new(0, 580, 0, 130)
dialogBox.Position          = UDim2.new(0.5, -290, 1, -150)
dialogBox.BackgroundColor3  = C_BG
dialogBox.BackgroundTransparency = 0.12
dialogBox.BorderSizePixel   = 0
dialogBox.Visible           = false
dialogBox.ZIndex            = 10
dialogBox.Parent            = gui
Instance.new("UICorner", dialogBox).CornerRadius = UDim.new(0, 10)

local dbStroke = Instance.new("UIStroke", dialogBox)
dbStroke.Color     = Color3.fromRGB(60, 130, 200)
dbStroke.Thickness = 2

-- Speaker name label
local speakerLbl = Instance.new("TextLabel", dialogBox)
speakerLbl.Size              = UDim2.new(1, -12, 0, 24)
speakerLbl.Position          = UDim2.new(0, 10, 0, 6)
speakerLbl.BackgroundTransparency = 1
speakerLbl.Text              = "Guide"
speakerLbl.TextColor3        = C_TITLE
speakerLbl.TextScaled        = true
speakerLbl.Font              = Enum.Font.GothamBold
speakerLbl.TextXAlignment    = Enum.TextXAlignment.Left
speakerLbl.ZIndex            = 11

-- Dialog text
local dialogText = Instance.new("TextLabel", dialogBox)
dialogText.Size              = UDim2.new(1, -20, 0, 64)
dialogText.Position          = UDim2.new(0, 10, 0, 32)
dialogText.BackgroundTransparency = 1
dialogText.Text              = ""
dialogText.TextColor3        = Color3.fromRGB(220, 220, 220)
dialogText.TextScaled        = false
dialogText.TextSize          = 18
dialogText.Font              = Enum.Font.Gotham
dialogText.TextXAlignment    = Enum.TextXAlignment.Left
dialogText.TextYAlignment    = Enum.TextYAlignment.Top
dialogText.TextWrapped       = true
dialogText.ZIndex            = 11

-- Next / Done button
local nextBtn = Instance.new("TextButton", dialogBox)
nextBtn.Size             = UDim2.new(0, 90, 0, 28)
nextBtn.Position         = UDim2.new(1, -100, 1, -36)
nextBtn.BackgroundColor3 = Color3.fromRGB(40, 110, 200)
nextBtn.BorderSizePixel  = 0
nextBtn.Text             = "Next ▶"
nextBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
nextBtn.TextScaled       = true
nextBtn.Font             = Enum.Font.GothamBold
nextBtn.ZIndex           = 12
Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 6)

-- Triangle "tail" pointing down
local tail = Instance.new("Frame", dialogBox)
tail.Size              = UDim2.new(0, 14, 0, 10)
tail.Position          = UDim2.new(0.5, -7, 1, 0)
tail.BackgroundColor3  = C_BG
tail.BorderSizePixel   = 0
tail.Rotation          = 0
tail.ZIndex            = 9

-- ── Dialog state machine ───────────────────────────────────────────

local dialogQueue  = {}   -- array of {speaker, text}
local dialogIndex  = 0
local isTyping     = false
local fullText     = ""

local TYPING_SPEED = 0.025  -- seconds per character

local function closeDialog()
	dialogBox.Visible = false
	dialogQueue       = {}
	dialogIndex       = 0
	isTyping          = false
end

local function typeText(target, text, onDone)
	isTyping = true
	target.Text = ""
	local i = 0
	task.spawn(function()
		while i < #text do
			if not isTyping then break end
			i += 1
			target.Text = string.sub(text, 1, i)
			task.wait(TYPING_SPEED)
		end
		isTyping = false
		if onDone then onDone() end
	end)
end

local function showLine(index)
	local line = dialogQueue[index]
	if not line then
		closeDialog()
		return
	end
	speakerLbl.Text = line.speaker
	fullText        = line.text
	dialogText.Text = ""
	nextBtn.Text    = "Next ▶"

	if index == #dialogQueue then
		nextBtn.Text = "Done ✓"
	end

	typeText(dialogText, fullText)
end

local function openDialog(lines)
	dialogQueue  = lines
	dialogIndex  = 1
	dialogBox.Visible = true

	-- Slide in from below
	dialogBox.Position = UDim2.new(0.5, -290, 1, 10)
	TweenService:Create(dialogBox,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -290, 1, -150) }
	):Play()

	showLine(1)
end

nextBtn.Activated:Connect(function()
	if isTyping then
		-- Skip typing animation — show full text immediately
		isTyping = false
		dialogText.Text = fullText
		return
	end
	dialogIndex += 1
	if dialogIndex > #dialogQueue then
		closeDialog()
	else
		showLine(dialogIndex)
	end
end)

-- ── Remote listeners ───────────────────────────────────────────────

Remotes.TutorialStep.OnClientEvent:Connect(function(step)
	currentStep = step
	refreshChecklist(step)
end)

Remotes.TutorialNPCDialog.OnClientEvent:Connect(function(lines)
	if lines and #lines > 0 then
		openDialog(lines)
	end
end)

-- ── Initial state ─────────────────────────────────────────────────
refreshChecklist(0)

-- ── Proximity-based HUD buttons ───────────────────────────────────
-- invButton / journalButton in FishingGui start hidden.
-- Show them only when the player is near the Fishing Lodge NPC.
-- After tutorial completes they stay visible permanently.

local RunService = game:GetService("RunService")

task.spawn(function()
	local playerGui = player:WaitForChild("PlayerGui")
	local fishGui   = playerGui:WaitForChild("FishingGui", 15)
	if not fishGui then return end

	local invBtn     = fishGui:WaitForChild("InventoryButton", 10)
	local journalBtn = fishGui:WaitForChild("JournalButton",   10)
	local shopBtn    = fishGui:FindFirstChild("ShopButton")
	if not invBtn or not journalBtn then return end

	-- If no TutorialLevel, show buttons immediately (main world)
	local lvl = workspace:WaitForChild("TutorialLevel", 10)
	if not lvl then
		invBtn.Visible     = true
		journalBtn.Visible = true
		return
	end

	local SHOW_DIST = 30   -- studs from shop NPC to reveal buttons

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if currentStep >= 5 then
			invBtn.Visible     = true
			journalBtn.Visible = true
			if shopBtn then shopBtn.Visible = true end
			conn:Disconnect()
			return
		end

		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local npc   = lvl:FindFirstChild("TutorialShopNPC")
		local torso = npc and npc:FindFirstChild("Torso")
		if not torso then return end

		local near = (root.Position - torso.Position).Magnitude < SHOW_DIST
		invBtn.Visible     = near
		journalBtn.Visible = near
	end)
end)
