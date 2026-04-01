-- ============================================================
-- TutorialManager.server.lua  (Script in ServerScriptService)
-- Manages the 4-step tutorial sequence:
--   0  Start      – auto-shows Guide dialog on first join
--   1  Catch      – player wins a minigame (MinigameWon)
--   2  Sell       – player sells a fish (TutorialFishSold)
--   3  Equip bait – player selects any non-basic bait
--   4  Navigator  – player talks to Navigator NPC → teleport
--   5  Complete   – all done
-- NOTE: "Cast" is not tracked separately because fishing is triggered
-- by a server-side ProximityPrompt; CastLine remote is server→client only.
-- ============================================================

local Players             = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local TeleportService     = game:GetService("TeleportService")

local Remotes    = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

-- ── Configuration ──────────────────────────────────────────────────
-- Set this to your main-world Place ID once you publish it.
-- Leave 0 to skip teleport (useful during development).
local MAIN_WORLD_PLACE_ID = 0

-- Steps: index = tutorialStep value that IS active (not yet completed)
local STEP_LABELS = {
	[1] = "Cast your line and catch a fish",
	[2] = "Sell a fish at the shop",
	[3] = "Equip non-basic bait",
	[4] = "Talk to the Navigator",
}

-- NPC dialog tables — arrays of {speaker, text}
local NPC_DIALOGS = {
	GuideNPC = {
		{ speaker = "Guide", text = "Welcome to RoFish, angler! I'll teach you everything you need to know." },
		{ speaker = "Guide", text = "Step 1: Walk to the water's edge and press E to cast your line." },
		{ speaker = "Guide", text = "Step 2: When the bobber dips, HOLD your mouse button to lift the catch bar — keep it over the fish icon!" },
		{ speaker = "Guide", text = "Once you've caught something, head to the Shop NPC near the Fishing Lodge to sell it for coins. Good luck! 🎣" },
	},
	TutorialShopNPC = {
		{ speaker = "ShopKeeper", text = "Welcome to the shop! I'll buy any fish you've caught." },
		{ speaker = "ShopKeeper", text = "Open your inventory (backpack button) and use the Sell tab to cash in your catch." },
		{ speaker = "ShopKeeper", text = "You can also buy bait here — different baits attract different fish. Try equipping some!" },
	},
	NavigatorNPC = {
		{ speaker = "Navigator", text = "Impressive work, angler! You've mastered the basics of fishing." },
		{ speaker = "Navigator", text = "The main world is full of rare fish, hotspots, tournaments, and much more!" },
		{ speaker = "Navigator", text = "Step through the portal and your real adventure begins. Safe travels!" },
	},
	NavigatorNotReady = {
		{ speaker = "Navigator", text = "You're not quite ready yet! Finish all the tutorial steps first, then come back." },
	},
}

-- ── Helpers ────────────────────────────────────────────────────────

local function getLevel()
	return workspace:WaitForChild("TutorialLevel", 15)
end

local function getNPCTorso(modelName)
	local lvl = getLevel()
	if not lvl then return nil end
	local model = lvl:FindFirstChild(modelName)
	if not model then return nil end
	return model:FindFirstChild("Torso")
end

local function addProximityPrompt(torso, actionText, objectText, distance)
	if not torso then return nil end
	if torso:FindFirstChildOfClass("ProximityPrompt") then
		return torso:FindFirstChildOfClass("ProximityPrompt")
	end
	local pp                    = Instance.new("ProximityPrompt")
	pp.ActionText               = actionText
	pp.ObjectText               = objectText
	pp.MaxActivationDistance    = distance or 8
	pp.HoldDuration             = 0
	pp.RequiresLineOfSight      = false
	pp.Parent                   = torso
	return pp
end

-- Send dialog lines to the client; client renders them as a dialog box
local function sendDialog(player, key)
	local lines = NPC_DIALOGS[key]
	if not lines then return end
	Remotes.TutorialNPCDialog:FireClient(player, lines)
end

-- Advance player to the next step if they are exactly on expectedStep
local function advanceStep(player, expectedStep)
	local data = PlayerData.Get(player)
	if not data then return end
	if data.tutorialStep ~= expectedStep then return end
	data.tutorialStep = expectedStep + 1
	Remotes.TutorialStep:FireClient(player, data.tutorialStep)
	print(("[TutorialManager] %s → step %d (%s)"):format(
		player.Name, data.tutorialStep, STEP_LABELS[data.tutorialStep] or "complete"))
end

-- ── Set up NPC prompts (waits for level to exist) ──────────────────

task.spawn(function()
	local guideTorso = getNPCTorso("GuideNPC")
	local shopTorso  = getNPCTorso("TutorialShopNPC")
	local navTorso   = getNPCTorso("NavigatorNPC")

	-- Guide NPC
	local guidePrompt = addProximityPrompt(guideTorso, "Talk", "Guide", 10)
	if guidePrompt then
		guidePrompt.Triggered:Connect(function(player)
			sendDialog(player, "GuideNPC")
			-- Step 0 → 1 (if player hasn't already been prompted)
			advanceStep(player, 0)
		end)
	end

	-- Shop NPC (dialog + open the shop panel)
	local shopPrompt = addProximityPrompt(shopTorso, "Talk", "Shop", 10)
	if shopPrompt then
		shopPrompt.Triggered:Connect(function(player)
			sendDialog(player, "TutorialShopNPC")
			Remotes.OpenShop:FireClient(player)
		end)
	end

	-- Navigator NPC (gating: must be on step 5)
	local navPrompt = addProximityPrompt(navTorso, "Travel", "Navigator", 10)
	if navPrompt then
		navPrompt.Triggered:Connect(function(player)
			local data = PlayerData.Get(player)
			if not data then return end

			if data.tutorialStep < 4 then
				sendDialog(player, "NavigatorNotReady")
				return
			end

			sendDialog(player, "NavigatorNPC")
			advanceStep(player, 4)  -- marks step 5 = completed

			-- Teleport after the dialog has time to display (~6 s)
			task.delay(6, function()
				if not player or not player.Parent then return end
				if MAIN_WORLD_PLACE_ID ~= 0 then
					local ok, err = pcall(function()
						TeleportService:TeleportAsync(MAIN_WORLD_PLACE_ID, { player })
					end)
					if not ok then
						warn("[TutorialManager] Teleport failed:", err)
					end
				else
					warn("[TutorialManager] MAIN_WORLD_PLACE_ID = 0 — skipping teleport (set it in TutorialManager.server.lua).")
				end
			end)
		end)
	end
end)

-- ── Step event listeners ───────────────────────────────────────────

-- Step 1 → 2: player won the minigame (caught a fish)
-- Note: fishing is initiated via a server-side ProximityPrompt, not a CastLine remote,
-- so we detect completion here instead of at the cast point.
Remotes.MinigameWon.OnServerEvent:Connect(function(player)
	advanceStep(player, 1)
end)

-- Step 2 → 3: player sold a fish (fired from FishingGui sell buttons)
Remotes.TutorialFishSold.OnServerEvent:Connect(function(player)
	advanceStep(player, 2)
end)

-- Step 3 → 4: player equipped non-basic bait
Remotes.SelectBait.OnServerEvent:Connect(function(player, baitId)
	if baitId and baitId ~= "basic" then
		advanceStep(player, 3)
	end
end)

-- ── Player join: restore their progress ───────────────────────────
Players.PlayerAdded:Connect(function(player)
	-- Wait for PlayerData to load (it runs in the same script service)
	task.delay(3, function()
		local data = PlayerData.Get(player)
		if not data then return end

		-- Send current step to populate the checklist UI
		Remotes.TutorialStep:FireClient(player, data.tutorialStep)

		-- New players (step 0) get the Guide dialog automatically
		if data.tutorialStep == 0 then
			task.delay(1.5, function()
				if not player or not player.Parent then return end
				sendDialog(player, "GuideNPC")
				advanceStep(player, 0)
			end)
		end
	end)
end)
