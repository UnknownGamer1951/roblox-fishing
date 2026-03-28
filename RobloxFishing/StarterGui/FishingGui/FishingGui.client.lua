     1→-- ============================================================
     2→-- FishingGui.lua  (LocalScript inside StarterGui > FishingGui)
     3→-- Builds ALL fishing UI: status, minigame, tourney, shop
     4→-- ============================================================
     5→
     6→local Players           = game:GetService("Players")
     7→local ReplicatedStorage = game:GetService("ReplicatedStorage")
     8→local RunService        = game:GetService("RunService")
     9→local TweenService      = game:GetService("TweenService")
    10→local Remotes           = require(ReplicatedStorage:WaitForChild("FishingRemotes"))
    11→local UpgradeData       = require(ReplicatedStorage:WaitForChild("UpgradeData"))
    12→local AchievementData   = require(ReplicatedStorage:WaitForChild("AchievementData"))
    13→local BaitData          = require(ReplicatedStorage:WaitForChild("BaitData"))
    14→local RunService        = game:GetService("RunService")
    15→
    16→local hotspotPositions = {}
    17→local HOTSPOT_RADIUS   = 35
    18→
    19→local localPlayer = Players.LocalPlayer
    20→local screenGui   = script.Parent
    21→
    22→-- ============================================================
    23→-- STATUS BAR
    24→-- ============================================================
    25→local statusFrame = Instance.new("Frame")
    26→statusFrame.Name                   = "StatusFrame"
    27→statusFrame.Size                   = UDim2.new(0, 440, 0, 52)
    28→statusFrame.Position               = UDim2.new(0.5, -220, 0, 18)
    29→statusFrame.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    30→statusFrame.BackgroundTransparency = 0.4
    31→statusFrame.BorderSizePixel        = 0
    32→statusFrame.Parent                 = screenGui
    33→Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 10)
    34→
    35→local statusLabel = Instance.new("TextLabel")
    36→statusLabel.Name                   = "StatusLabel"
    37→statusLabel.Size                   = UDim2.new(1, -16, 1, 0)
    38→statusLabel.Position               = UDim2.new(0, 8, 0, 0)
    39→statusLabel.BackgroundTransparency = 1
    40→statusLabel.Text                   = "Walk up to water and press [E] to fish."
    41→statusLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
    42→statusLabel.TextScaled             = true
    43→statusLabel.Font                   = Enum.Font.GothamBold
    44→statusLabel.RichText               = true
    45→statusLabel.Parent                 = statusFrame
    46→
    47→-- ============================================================
    48→-- COINS DISPLAY (top-left)
    49→-- ============================================================
    50→local coinsFrame = Instance.new("Frame")
    51→coinsFrame.Name                   = "CoinsFrame"
    52→coinsFrame.Size                   = UDim2.new(0, 150, 0, 44)
    53→coinsFrame.Position               = UDim2.new(0, 18, 0, 18)
    54→coinsFrame.BackgroundColor3       = Color3.fromRGB(30, 20, 0)
    55→coinsFrame.BackgroundTransparency = 0.25
    56→coinsFrame.BorderSizePixel        = 0
    57→coinsFrame.Parent                 = screenGui
    58→Instance.new("UICorner", coinsFrame).CornerRadius = UDim.new(0, 10)
    59→
    60→local coinsLabel = Instance.new("TextLabel")
    61→coinsLabel.Name                   = "CoinsLabel"
    62→coinsLabel.Size                   = UDim2.new(1, -8, 1, 0)
    63→coinsLabel.Position               = UDim2.new(0, 4, 0, 0)
    64→coinsLabel.BackgroundTransparency = 1
    65→coinsLabel.Text                   = "🪙 0"
    66→coinsLabel.TextColor3             = Color3.fromRGB(255, 220, 60)
    67→coinsLabel.TextScaled             = true
    68→coinsLabel.Font                   = Enum.Font.GothamBold
    69→coinsLabel.TextXAlignment         = Enum.TextXAlignment.Left
    70→coinsLabel.Parent                 = coinsFrame
    71→
    72→-- ============================================================
    73→-- STARS DISPLAY (top-left, below coins)
    74→-- ============================================================
    75→local starsFrame = Instance.new("Frame")
    76→starsFrame.Name                   = "StarsFrame"
    77→starsFrame.Size                   = UDim2.new(0, 150, 0, 44)
    78→starsFrame.Position               = UDim2.new(0, 18, 0, 68)
    79→starsFrame.BackgroundColor3       = Color3.fromRGB(20, 0, 40)
    80→starsFrame.BackgroundTransparency = 0.25
    81→starsFrame.BorderSizePixel        = 0
    82→starsFrame.Parent                 = screenGui
    83→Instance.new("UICorner", starsFrame).CornerRadius = UDim.new(0, 10)
    84→
    85→local starsLabel = Instance.new("TextLabel")
    86→starsLabel.Name                   = "StarsLabel"
    87→starsLabel.Size                   = UDim2.new(1, -8, 1, 0)
    88→starsLabel.Position               = UDim2.new(0, 4, 0, 0)
    89→starsLabel.BackgroundTransparency = 1
    90→starsLabel.Text                   = "⭐ 0"
    91→starsLabel.TextColor3             = Color3.fromRGB(200, 160, 255)
    92→starsLabel.TextScaled             = true
    93→starsLabel.Font                   = Enum.Font.GothamBold
    94→starsLabel.TextXAlignment         = Enum.TextXAlignment.Left
    95→starsLabel.Parent                 = starsFrame
    96→
    97→-- ============================================================
    98→-- HOTSPOT ZONE NOTIFICATION
    99→-- ============================================================
   100→local hotspotFrame = Instance.new("Frame")
   101→hotspotFrame.Name                   = "HotspotFrame"
   102→hotspotFrame.Size                   = UDim2.new(0, 170, 0, 46)
   103→hotspotFrame.Position               = UDim2.new(0, 18, 0, 130)
   104→hotspotFrame.BackgroundColor3       = Color3.fromRGB(0, 60, 100)
   105→hotspotFrame.BackgroundTransparency = 0.2
   106→hotspotFrame.BorderSizePixel        = 0
   107→hotspotFrame.Visible                = false
   108→hotspotFrame.ZIndex                 = 3
   109→hotspotFrame.Parent                 = screenGui
   110→Instance.new("UICorner", hotspotFrame).CornerRadius = UDim.new(0, 10)
   111→local hotspotLabel = Instance.new("TextLabel")
   112→hotspotLabel.Size                   = UDim2.new(1, -8, 1, 0)
   113→hotspotLabel.Position               = UDim2.new(0, 4, 0, 0)
   114→hotspotLabel.BackgroundTransparency = 1
   115→hotspotLabel.Text                   = "** Hotspot Zone"
   116→hotspotLabel.TextColor3             = Color3.fromRGB(100, 220, 255)
   117→hotspotLabel.TextScaled             = true
   118→hotspotLabel.Font                   = Enum.Font.GothamBold
   119→hotspotLabel.ZIndex                 = 3
   120→hotspotLabel.Parent                 = hotspotFrame
   121→
   122→RunService.Heartbeat:Connect(function()
   123→	local char = localPlayer.Character
   124→	local root = char and char:FindFirstChild("HumanoidRootPart")
   125→	if not root or #hotspotPositions == 0 then hotspotFrame.Visible = false; return end
   126→	local pos = root.Position
   127→	local inside = false
   128→	for _, hPos in ipairs(hotspotPositions) do
   129→		if (pos - hPos).Magnitude <= HOTSPOT_RADIUS then inside = true; break end
   130→	end
   131→	hotspotFrame.Visible = inside
   132→end)
   133→
   134→Remotes.HotspotList.OnClientEvent:Connect(function(positions)
   135→	hotspotPositions = positions or {}
   136→end)
   137→task.delay(8, function()
   138→	if #hotspotPositions == 0 then
   139→		warn("[FishingGui] No hotspot positions received yet")
   140→	end
   141→end)
   142→
   143→-- ============================================================
   144→-- ACTION BUTTON (hidden — kept for legacy / mobile fallback)
   145→-- ============================================================
   146→local actionButton = Instance.new("TextButton")
   147→actionButton.Name             = "ActionButton"
   148→actionButton.Size             = UDim2.new(0, 200, 0, 60)
   149→actionButton.Position         = UDim2.new(0.5, -100, 1, -100)
   150→actionButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
   151→actionButton.BorderSizePixel  = 0
   152→actionButton.Text             = "Reel In"
   153→actionButton.TextColor3       = Color3.fromRGB(0, 0, 0)
   154→actionButton.TextScaled       = true
   155→actionButton.Font             = Enum.Font.GothamBold
   156→actionButton.Visible          = false
   157→actionButton.Parent           = screenGui
   158→Instance.new("UICorner", actionButton).CornerRadius = UDim.new(0, 12)
   159→actionButton.Activated:Connect(function() Remotes.ReelIn:FireServer() end)
   160→
   161→-- ============================================================
   162→-- CATCH POPUP
   163→-- ============================================================
   164→local catchPopup = Instance.new("Frame")
   165→catchPopup.Name                   = "CatchPopup"
   166→catchPopup.Size                   = UDim2.new(0, 320, 0, 200)
   167→catchPopup.Position               = UDim2.new(0.5, -160, 0.5, -100)
   168→catchPopup.BackgroundColor3       = Color3.fromRGB(20, 20, 40)
   169→catchPopup.BackgroundTransparency = 0.1
   170→catchPopup.BorderSizePixel        = 0
   171→catchPopup.Visible                = false
   172→catchPopup.Parent                 = screenGui
   173→Instance.new("UICorner", catchPopup).CornerRadius = UDim.new(0, 16)
   174→
   175→local function makeCatchRow(name, text, yFrac, color, font)
   176→	local lbl = Instance.new("TextLabel")
   177→	lbl.Name = name; lbl.Size = UDim2.new(1,0,0.25,0); lbl.Position = UDim2.new(0,0,yFrac,0)
   178→	lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = color
   179→	lbl.TextScaled = true; lbl.Font = font; lbl.Parent = catchPopup
   180→end
   181→makeCatchRow("CaughtHeader",   "You caught a fish! 🎣", 0,    Color3.fromRGB(255,220,60),  Enum.Font.GothamBold)
   182→makeCatchRow("FishNameLabel",  "",                       0.25, Color3.fromRGB(255,255,255), Enum.Font.GothamBold)
   183→makeCatchRow("FishRarityLabel","",                       0.50, Color3.fromRGB(180,220,255), Enum.Font.Gotham)
   184→makeCatchRow("FishSizeLabel",  "",                       0.75, Color3.fromRGB(200,200,200), Enum.Font.Gotham)
   185→
   186→-- ============================================================
   187→-- INVENTORY
   188→-- ============================================================
   189→local invButton = Instance.new("TextButton")
   190→invButton.Name             = "InventoryButton"
   191→invButton.Size             = UDim2.new(0, 130, 0, 46)
   192→invButton.Position         = UDim2.new(0, 18, 1, -68)
   193→invButton.BackgroundColor3 = Color3.fromRGB(40, 80, 160)
   194→invButton.BorderSizePixel  = 0
   195→invButton.Text             = "My Fish"
   196→invButton.TextColor3       = Color3.fromRGB(255, 255, 255)
   197→invButton.TextScaled       = true
   198→invButton.Font             = Enum.Font.GothamBold
   199→invButton.Parent           = screenGui
   200→Instance.new("UICorner", invButton).CornerRadius = UDim.new(0, 10)
   201→
   202→local invPanel = Instance.new("ScrollingFrame")
   203→invPanel.Name                = "InventoryPanel"
   204→invPanel.Size                = UDim2.new(0, 320, 0, 400)
   205→invPanel.Position            = UDim2.new(0, 18, 1, -476)
   206→invPanel.BackgroundColor3    = Color3.fromRGB(15, 15, 30)
   207→invPanel.BackgroundTransparency = 0.1
   208→invPanel.BorderSizePixel     = 0
   209→invPanel.Visible             = false
   210→invPanel.CanvasSize          = UDim2.new(0, 0, 0, 0)
   211→invPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
   212→invPanel.ScrollBarThickness  = 6
   213→invPanel.Parent              = screenGui
   214→Instance.new("UICorner", invPanel).CornerRadius = UDim.new(0, 12)
   215→
   216→local invLayout = Instance.new("UIListLayout")
   217→invLayout.Padding   = UDim.new(0, 4)
   218→invLayout.SortOrder = Enum.SortOrder.LayoutOrder
   219→invLayout.Parent    = invPanel
   220→
   221→local invTitle = Instance.new("TextLabel")
   222→invTitle.Size               = UDim2.new(1, 0, 0, 36)
   223→invTitle.BackgroundTransparency = 1
   224→invTitle.Text               = "Your Catch Log"
   225→invTitle.TextColor3         = Color3.fromRGB(255, 220, 60)
   226→invTitle.TextScaled         = true
   227→invTitle.Font               = Enum.Font.GothamBold
   228→invTitle.LayoutOrder        = 0
   229→invTitle.Parent             = invPanel
   230→
   231→local rarityColors = {
   232→	Common    = Color3.fromRGB(200,200,200),
   233→	Uncommon  = Color3.fromRGB(100,220,100),
   234→	Rare      = Color3.fromRGB(80,140,255),
   235→	Legendary = Color3.fromRGB(255,180,0),
   236→}
   237→
   238→invButton.Activated:Connect(function()
   239→	invPanel.Visible = not invPanel.Visible
   240→	if not invPanel.Visible then return end
   241→	local inv = Remotes.GetInventory:InvokeServer()
   242→	for _, c in ipairs(invPanel:GetChildren()) do
   243→		if (c:IsA("TextLabel") or c:IsA("Frame")) and c ~= invTitle then c:Destroy() end
   244→	end
   245→	if #inv == 0 then
   246→		local e = Instance.new("TextLabel")
   247→		e.Size = UDim2.new(1,-10,0,30); e.BackgroundTransparency = 1
   248→		e.Text = "No fish yet — go cast!"; e.TextColor3 = Color3.fromRGB(180,180,180)
   249→		e.TextScaled = true; e.Font = Enum.Font.Gotham; e.LayoutOrder = 1; e.Parent = invPanel
   250→	else
   251→		for i, entry in ipairs(inv) do
   252→			local row = Instance.new("TextLabel")
   253→			row.Size = UDim2.new(1,-10,0,28); row.BackgroundTransparency = 1
   254→			row.Text = string.format("%d. %s (%s) — %d cm", i, entry.name, entry.rarity, entry.size)
   255→			row.TextColor3 = rarityColors[entry.rarity] or Color3.new(1,1,1)
   256→			row.TextScaled = true; row.Font = Enum.Font.Gotham
   257→			row.TextXAlignment = Enum.TextXAlignment.Left
   258→			row.LayoutOrder = i + 1; row.Parent = invPanel
   259→		end
   260→	end
   261→end)
   262→
   263→-- ============================================================
   264→-- SHOP BUTTON (bottom-left, next to inventory)
   265→-- ============================================================
   266→local shopButton = Instance.new("TextButton")
   267→shopButton.Name             = "ShopButton"
   268→shopButton.Size             = UDim2.new(0, 130, 0, 46)
   269→shopButton.Position         = UDim2.new(0, 158, 1, -68)
   270→shopButton.BackgroundColor3 = Color3.fromRGB(120, 60, 20)
   271→shopButton.BorderSizePixel  = 0
   272→shopButton.Text             = "Shop"
   273→shopButton.TextColor3       = Color3.fromRGB(255, 255, 255)
   274→shopButton.TextScaled       = true
   275→shopButton.Font             = Enum.Font.GothamBold
   276→shopButton.Parent           = screenGui
   277→Instance.new("UICorner", shopButton).CornerRadius = UDim.new(0, 10)
   278→
   279→-- ============================================================
   280→-- SHOP PANEL
   281→-- ============================================================
   282→local shopPanel = Instance.new("Frame")
   283→shopPanel.Name                   = "ShopPanel"
   284→shopPanel.Size                   = UDim2.new(0, 360, 0, 460)
   285→shopPanel.Position               = UDim2.new(0, 18, 1, -542)
   286→shopPanel.BackgroundColor3       = Color3.fromRGB(18, 12, 6)
   287→shopPanel.BackgroundTransparency = 0.05
   288→shopPanel.BorderSizePixel        = 0
   289→shopPanel.Visible                = false
   290→shopPanel.Parent                 = screenGui
   291→Instance.new("UICorner", shopPanel).CornerRadius = UDim.new(0, 14)
   292→
   293→local shopTitle = Instance.new("TextLabel")
   294→shopTitle.Size               = UDim2.new(1, 0, 0, 46)
   295→shopTitle.Position           = UDim2.new(0, 0, 0, 0)
   296→shopTitle.BackgroundTransparency = 1
   297→shopTitle.Text               = "Upgrade Shop"
   298→shopTitle.TextColor3         = Color3.fromRGB(255, 220, 60)
   299→shopTitle.TextScaled         = true
   300→shopTitle.Font               = Enum.Font.GothamBold
   301→shopTitle.Parent             = shopPanel
   302→
   303→local shopCoinsLabel = Instance.new("TextLabel")
   304→shopCoinsLabel.Name              = "ShopCoinsLabel"
   305→shopCoinsLabel.Size              = UDim2.new(1, -20, 0, 28)
   306→shopCoinsLabel.Position          = UDim2.new(0, 10, 0, 46)
   307→shopCoinsLabel.BackgroundTransparency = 1
   308→shopCoinsLabel.Text              = "🪙 0 coins"
   309→shopCoinsLabel.TextColor3        = Color3.fromRGB(255, 210, 60)
   310→shopCoinsLabel.TextScaled        = true
   311→shopCoinsLabel.Font              = Enum.Font.Gotham
   312→shopCoinsLabel.TextXAlignment    = Enum.TextXAlignment.Left
   313→shopCoinsLabel.Parent            = shopPanel
   314→
   315→-- Each upgrade card: yOffset in the panel
   316→local UPGRADE_DEFS = {
   317→	{ type = "Reel", label = "Reel",  desc = "Reduces wait time + slight rarity bonus", yOff = 82  },
   318→	{ type = "Hook", label = "🪝 Hook",  desc = "Slows the fish in minigame",     yOff = 212 },
   319→	{ type = "Rod",  label = "🎣 Rod",   desc = "Bigger catch bar in minigame",   yOff = 342 },
   320→}
   321→
   322→-- Holds refs to buy buttons so we can update them
   323→local buyButtons = {}
   324→
   325→local function makeUpgradeCard(def)
   326→	local card = Instance.new("Frame")
   327→	card.Name             = def.type .. "Card"
   328→	card.Size             = UDim2.new(1, -20, 0, 118)
   329→	card.Position         = UDim2.new(0, 10, 0, def.yOff)
   330→	card.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
   331→	card.BackgroundTransparency = 0.3
   332→	card.BorderSizePixel  = 0
   333→	card.Parent           = shopPanel
   334→	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
   335→
   336→	-- Category label
   337→	local catLabel = Instance.new("TextLabel")
   338→	catLabel.Name  = "CatLabel"
   339→	catLabel.Size  = UDim2.new(1, -10, 0, 28)
   340→	catLabel.Position = UDim2.new(0, 8, 0, 4)
   341→	catLabel.BackgroundTransparency = 1
   342→	catLabel.Text  = def.label .. "  —  " .. def.desc
   343→	catLabel.TextColor3 = Color3.fromRGB(255, 230, 140)
   344→	catLabel.TextScaled = true
   345→	catLabel.Font  = Enum.Font.GothamBold
   346→	catLabel.TextXAlignment = Enum.TextXAlignment.Left
   347→	catLabel.Parent = card
   348→
   349→	-- Current tier display
   350→	local curLabel = Instance.new("TextLabel")
   351→	curLabel.Name  = "CurrentLabel"
   352→	curLabel.Size  = UDim2.new(0.55, -8, 0, 26)
   353→	curLabel.Position = UDim2.new(0, 8, 0, 36)
   354→	curLabel.BackgroundTransparency = 1
   355→	curLabel.Text  = "Current: —"
   356→	curLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
   357→	curLabel.TextScaled = true
   358→	curLabel.Font  = Enum.Font.Gotham
   359→	curLabel.TextXAlignment = Enum.TextXAlignment.Left
   360→	curLabel.Parent = card
   361→
   362→	-- Next tier label
   363→	local nextLabel = Instance.new("TextLabel")
   364→	nextLabel.Name  = "NextLabel"
   365→	nextLabel.Size  = UDim2.new(1, -16, 0, 24)
   366→	nextLabel.Position = UDim2.new(0, 8, 0, 62)
   367→	nextLabel.BackgroundTransparency = 1
   368→	nextLabel.Text  = "Next: —"
   369→	nextLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
   370→	nextLabel.TextScaled = true
   371→	nextLabel.Font  = Enum.Font.Gotham
   372→	nextLabel.TextXAlignment = Enum.TextXAlignment.Left
   373→	nextLabel.Parent = card
   374→
   375→	-- Star cost label
   376→	local starCostLabel = Instance.new("TextLabel")
   377→	starCostLabel.Name  = "StarCostLabel"
   378→	starCostLabel.Size  = UDim2.new(1, -16, 0, 18)
   379→	starCostLabel.Position = UDim2.new(0, 8, 0, 86)
   380→	starCostLabel.BackgroundTransparency = 1
   381→	starCostLabel.Text  = ""
   382→	starCostLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
   383→	starCostLabel.TextScaled = true
   384→	starCostLabel.Font  = Enum.Font.Gotham
   385→	starCostLabel.TextXAlignment = Enum.TextXAlignment.Left
   386→	starCostLabel.Parent = card
   387→
   388→	-- Buy button
   389→	local buyBtn = Instance.new("TextButton")
   390→	buyBtn.Name             = "BuyBtn"
   391→	buyBtn.Size             = UDim2.new(0, 110, 0, 30)
   392→	buyBtn.Position         = UDim2.new(1, -118, 0, 32)
   393→	buyBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
   394→	buyBtn.BorderSizePixel  = 0
   395→	buyBtn.Text             = "Upgrade"
   396→	buyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
   397→	buyBtn.TextScaled       = true
   398→	buyBtn.Font             = Enum.Font.GothamBold
   399→	buyBtn.Parent           = card
   400→	Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)
   401→
   402→	buyButtons[def.type] = { btn = buyBtn, curLabel = curLabel, nextLabel = nextLabel, starCostLabel = starCostLabel }
   403→
   404→	buyBtn.Activated:Connect(function()
   405→		local upgrades = Remotes.GetUpgrades:InvokeServer()
   406→		local levelKey = def.type:lower() .. "Level"
   407→		local currentLvl = upgrades[levelKey] or 1
   408→		local targetLvl  = currentLvl + 1
   409→		local ok, result, newCoins, newStars = Remotes.BuyUpgrade:InvokeServer(def.type, targetLvl)
   410→		if ok then
   411→			coinsLabel.Text     = "🪙 " .. (newCoins or 0)
   412→			starsLabel.Text     = "⭐ " .. (newStars or 0)
   413→			shopCoinsLabel.Text = "🪙 " .. (newCoins or 0) .. "  ⭐ " .. (newStars or 0)
   414→			refreshShop()
   415→		else
   416→			buyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
   417→			task.delay(0.8, function() buyBtn.BackgroundColor3 = Color3.fromRGB(60,160,60) end)
   418→			local prevText = nextLabel.Text
   419→			nextLabel.Text = "✗ " .. tostring(result)
   420→			task.delay(2, function() nextLabel.Text = prevText end)
   421→		end
   422→	end)
   423→
   424→	return card
   425→end
   426→
   427→for _, def in ipairs(UPGRADE_DEFS) do
   428→	makeUpgradeCard(def)
   429→end
   430→
   431→-- Refresh shop display with current levels/coins/stars
   432→function refreshShop()
   433→	local upgrades = Remotes.GetUpgrades:InvokeServer()
   434→	local coins    = upgrades.coins or 0
   435→	local stars    = upgrades.stars or 0
   436→	coinsLabel.Text     = "🪙 " .. coins
   437→	starsLabel.Text     = "⭐ " .. stars
   438→	shopCoinsLabel.Text = "🪙 " .. coins .. "  ⭐ " .. stars
   439→
   440→	local levelKeys = { Reel = "reelLevel", Hook = "hookLevel", Rod = "rodLevel" }
   441→	for upgradeType, refs in pairs(buyButtons) do
   442→		local levelKey = levelKeys[upgradeType]
   443→		local tiers    = UpgradeData[upgradeType]
   444→		local curLvl   = upgrades[levelKey] or 1
   445→		local curTier  = tiers[curLvl]
   446→		local nextTier = tiers[curLvl + 1]
   447→
   448→		refs.curLabel.Text = "Current: " .. (curTier and curTier.name or "?")
   449→
   450→		if nextTier then
   451→			local sc = nextTier.starCost or 0
   452→			refs.nextLabel.Text  = "Next: " .. nextTier.name .. " (🪙 " .. nextTier.cost .. ")"
   453→			refs.starCostLabel.Text = sc > 0 and ("  + ⭐ " .. sc .. " stars required") or ""
   454→			refs.btn.Visible     = true
   455→			refs.btn.Text        = "Upgrade"
   456→			local canAfford      = coins >= nextTier.cost and stars >= sc
   457→			refs.btn.BackgroundColor3 = canAfford
   458→				and Color3.fromRGB(60, 160, 60)
   459→				or  Color3.fromRGB(100, 100, 100)
   460→		else
   461→			refs.nextLabel.Text       = "✨ MAX LEVEL"
   462→			refs.starCostLabel.Text   = ""
   463→			refs.btn.Visible          = false
   464→		end
   465→	end
   466→end
   467→
   468→-- Open/close shop
   469→local function openShop()
   470→	invPanel.Visible = false  -- close inventory if open
   471→	shopPanel.Visible = not shopPanel.Visible
   472→	if shopPanel.Visible then
   473→		refreshShop()
   474→	end
   475→end
   476→
   477→shopButton.Activated:Connect(openShop)
   478→
   479→-- Also open when the NPC ProximityPrompt fires
   480→Remotes.OpenShop.OnClientEvent:Connect(function()
   481→	shopPanel.Visible = true
   482→	refreshShop()
   483→end)
   484→
   485→-- ============================================================
   486→-- MINIGAME PANEL (right side, shown on fish bite)
   487→-- ============================================================
   488→local mgPanel = Instance.new("Frame")
   489→mgPanel.Name             = "MinigamePanel"
   490→mgPanel.Size             = UDim2.new(0, 200, 0, 375)
   491→mgPanel.Position         = UDim2.new(0.5, -100, 0.5, -187)
   492→mgPanel.BackgroundColor3 = Color3.fromRGB(8, 18, 38)
   493→mgPanel.BackgroundTransparency = 0.12
   494→mgPanel.BorderSizePixel  = 0
   495→mgPanel.Visible          = false
   496→mgPanel.Parent           = screenGui
   497→Instance.new("UICorner", mgPanel).CornerRadius = UDim.new(0, 14)
   498→
   499→local mgTitle = Instance.new("TextLabel")
   500→mgTitle.Size     = UDim2.new(1, 0, 0, 34)
   501→mgTitle.Position = UDim2.new(0, 0, 0, 5)
   502→mgTitle.BackgroundTransparency = 1
   503→mgTitle.Text     = "🎣 REEL IT IN!"
   504→mgTitle.TextColor3 = Color3.fromRGB(255, 220, 60)
   505→mgTitle.TextScaled = true
   506→mgTitle.Font     = Enum.Font.GothamBold
   507→mgTitle.Parent   = mgPanel
   508→
   509→-- Water zone container
   510→local mgContainer = Instance.new("Frame")
   511→mgContainer.Name             = "Container"
   512→mgContainer.Size             = UDim2.new(0, 100, 0, 295)
   513→mgContainer.Position         = UDim2.new(0, 12, 0, 44)
   514→mgContainer.BackgroundColor3 = Color3.fromRGB(15, 70, 130)
   515→mgContainer.BackgroundTransparency = 0.25
   516→mgContainer.BorderSizePixel  = 0
   517→mgContainer.ClipsDescendants = true
   518→mgContainer.Parent           = mgPanel
   519→Instance.new("UICorner", mgContainer).CornerRadius = UDim.new(0, 8)
   520→
   521→local catchBar = Instance.new("Frame")
   522→catchBar.Name             = "CatchBar"
   523→catchBar.Size             = UDim2.new(0.9, 0, 0.32, 0)
   524→catchBar.Position         = UDim2.new(0.05, 0, 0.34, 0)
   525→catchBar.BackgroundColor3 = Color3.fromRGB(60, 210, 80)
   526→catchBar.BackgroundTransparency = 0.25
   527→catchBar.BorderSizePixel  = 0
   528→catchBar.Parent           = mgContainer
   529→Instance.new("UICorner", catchBar).CornerRadius = UDim.new(0, 6)
   530→
   531→local fishIcon = Instance.new("Frame")
   532→fishIcon.Name             = "FishIcon"
   533→fishIcon.Size             = UDim2.new(0.8, 0, 0.07, 0)
   534→fishIcon.Position         = UDim2.new(0.1, 0, 0.46, 0)
   535→fishIcon.BackgroundTransparency = 1
   536→fishIcon.BorderSizePixel  = 0
   537→fishIcon.Parent           = mgContainer
   538→local fishEmoji = Instance.new("TextLabel")
   539→fishEmoji.Size             = UDim2.new(1, 0, 1, 0)
   540→fishEmoji.BackgroundTransparency = 1
   541→fishEmoji.Text             = "🐟"
   542→fishEmoji.TextScaled       = true
   543→fishEmoji.Font             = Enum.Font.Gotham
   544→fishEmoji.Parent           = fishIcon
   545→
   546→local holdArea = Instance.new("TextButton")
   547→holdArea.Name             = "HoldArea"
   548→holdArea.Size             = UDim2.new(1, 0, 1, 0)
   549→holdArea.BackgroundTransparency = 1
   550→holdArea.Text             = ""
   551→holdArea.ZIndex           = 10
   552→holdArea.Parent           = mgContainer
   553→
   554→-- Progress bar (right of container)
   555→local pgBg = Instance.new("Frame")
   556→pgBg.Name             = "ProgressBg"
   557→pgBg.Size             = UDim2.new(0, 28, 0, 295)
   558→pgBg.Position         = UDim2.new(0, 122, 0, 44)
   559→pgBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
   560→pgBg.BorderSizePixel  = 0
   561→pgBg.ClipsDescendants = true
   562→pgBg.Parent           = mgPanel
   563→Instance.new("UICorner", pgBg).CornerRadius = UDim.new(0, 6)
   564→
   565→local pgFill = Instance.new("Frame")
   566→pgFill.Name             = "ProgressFill"
   567→pgFill.Size             = UDim2.new(1, 0, 0.5, 0)
   568→pgFill.Position         = UDim2.new(0, 0, 0.5, 0)
   569→pgFill.BackgroundColor3 = Color3.fromRGB(60, 210, 80)
   570→pgFill.BorderSizePixel  = 0
   571→pgFill.Parent           = pgBg
   572→
   573→local holdHint = Instance.new("TextLabel")
   574→holdHint.Size             = UDim2.new(1, -4, 0, 30)
   575→holdHint.Position         = UDim2.new(0, 2, 0, 343)
   576→holdHint.BackgroundTransparency = 1
   577→holdHint.Text             = "HOLD [CLICK] or tap to lift"
   578→holdHint.TextColor3       = Color3.fromRGB(170, 170, 170)
   579→holdHint.TextScaled       = true
   580→holdHint.Font             = Enum.Font.Gotham
   581→holdHint.Parent           = mgPanel
   582→
   583→-- ============================================================
   584→-- TOURNAMENT COUNTDOWN (bottom-right — always visible)
   585→-- Shows "Next tourney in X:XX" or "🏆 TOURNAMENT ACTIVE X:XX"
   586→-- ============================================================
   587→local tourneyCountdownFrame = Instance.new("Frame")
   588→tourneyCountdownFrame.Name             = "TourneyCountdown"
   589→tourneyCountdownFrame.Size             = UDim2.new(0, 200, 0, 52)
   590→tourneyCountdownFrame.Position         = UDim2.new(1, -218, 1, -72)
   591→tourneyCountdownFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
   592→tourneyCountdownFrame.BackgroundTransparency = 0.2
   593→tourneyCountdownFrame.BorderSizePixel  = 0
   594→tourneyCountdownFrame.Parent           = screenGui
   595→Instance.new("UICorner", tourneyCountdownFrame).CornerRadius = UDim.new(0, 10)
   596→
   597→local countdownLabel = Instance.new("TextLabel")
   598→countdownLabel.Name             = "CountdownLabel"
   599→countdownLabel.Size             = UDim2.new(1, -8, 0.55, 0)
   600→countdownLabel.Position         = UDim2.new(0, 4, 0, 2)
   601→countdownLabel.BackgroundTransparency = 1
   602→countdownLabel.Text             = "🏆 Next tourney: --:--"
   603→countdownLabel.TextColor3       = Color3.fromRGB(255, 220, 60)
   604→countdownLabel.TextScaled       = true
   605→countdownLabel.Font             = Enum.Font.GothamBold
   606→countdownLabel.TextXAlignment   = Enum.TextXAlignment.Left
   607→countdownLabel.Parent           = tourneyCountdownFrame
   608→
   609→local countdownSub = Instance.new("TextLabel")
   610→countdownSub.Size             = UDim2.new(1, -8, 0.4, 0)
   611→countdownSub.Position         = UDim2.new(0, 4, 0.58, 0)
   612→countdownSub.BackgroundTransparency = 1
   613→countdownSub.Text             = "server-wide event"
   614→countdownSub.TextColor3       = Color3.fromRGB(160, 140, 200)
   615→countdownSub.TextScaled       = true
   616→countdownSub.Font             = Enum.Font.Gotham
   617→countdownSub.TextXAlignment   = Enum.TextXAlignment.Left
   618→countdownSub.Parent           = tourneyCountdownFrame
   619→
   620→-- "Buy early start" button (shown when countdown is long; uses Robux)
   621→local earlyBtn = Instance.new("TextButton")
   622→earlyBtn.Name             = "EarlyStartBtn"
   623→earlyBtn.Size             = UDim2.new(0, 200, 0, 36)
   624→earlyBtn.Position         = UDim2.new(1, -218, 1, -114)
   625→earlyBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
   626→earlyBtn.BorderSizePixel  = 0
   627→earlyBtn.Text             = "⚡ Buy Early Start (R$)"
   628→earlyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
   629→earlyBtn.TextScaled       = true
   630→earlyBtn.Font             = Enum.Font.GothamBold
   631→earlyBtn.Visible          = false   -- shown only when tourney isn't active
   632→earlyBtn.Parent           = screenGui
   633→Instance.new("UICorner", earlyBtn).CornerRadius = UDim.new(0, 8)
   634→earlyBtn.Activated:Connect(function()
   635→	Remotes.BuyTournament:FireServer()
   636→end)
   637→
   638→-- ============================================================
   639→-- TOURNEY HUD (top-right, active during tournament)
   640→-- ============================================================
   641→local tourneyHUD = Instance.new("Frame")
   642→tourneyHUD.Name             = "TourneyHUD"
   643→tourneyHUD.Size             = UDim2.new(0, 210, 0, 130)
   644→tourneyHUD.Position         = UDim2.new(1, -228, 0, 18)
   645→tourneyHUD.BackgroundColor3 = Color3.fromRGB(12, 12, 45)
   646→tourneyHUD.BackgroundTransparency = 0.15
   647→tourneyHUD.BorderSizePixel  = 0
   648→tourneyHUD.Visible          = false
   649→tourneyHUD.Parent           = screenGui
   650→Instance.new("UICorner", tourneyHUD).CornerRadius = UDim.new(0, 10)
   651→
   652→local timerLabel = Instance.new("TextLabel")
   653→timerLabel.Name = "TimerLabel"; timerLabel.Size = UDim2.new(1,-10,0,36); timerLabel.Position = UDim2.new(0,5,0,4)
   654→timerLabel.BackgroundTransparency = 1; timerLabel.Text = "⏱ 5:00"
   655→timerLabel.TextColor3 = Color3.fromRGB(255,220,60); timerLabel.TextScaled = true
   656→timerLabel.Font = Enum.Font.GothamBold; timerLabel.Parent = tourneyHUD
   657→
   658→local fishCountLabel = Instance.new("TextLabel")
   659→fishCountLabel.Name = "FishCountLabel"; fishCountLabel.Size = UDim2.new(1,-10,0,28); fishCountLabel.Position = UDim2.new(0,5,0,40)
   660→fishCountLabel.BackgroundTransparency = 1; fishCountLabel.Text = "🐟 0 fish caught"
   661→fishCountLabel.TextColor3 = Color3.fromRGB(170,255,170); fishCountLabel.TextScaled = true
   662→fishCountLabel.Font = Enum.Font.Gotham; fishCountLabel.Parent = tourneyHUD
   663→
   664→local rankLabel = Instance.new("TextLabel")
   665→rankLabel.Name = "RankLabel"; rankLabel.Size = UDim2.new(1,-10,0,28); rankLabel.Position = UDim2.new(0,5,0,68)
   666→rankLabel.BackgroundTransparency = 1; rankLabel.Text = "Rank: —"
   667→rankLabel.TextColor3 = Color3.fromRGB(255,245,180); rankLabel.TextScaled = true
   668→rankLabel.Font = Enum.Font.Gotham; rankLabel.Parent = tourneyHUD
   669→
   670→local starChanceLabel = Instance.new("TextLabel")
   671→starChanceLabel.Name = "StarChanceLabel"; starChanceLabel.Size = UDim2.new(1,-10,0,24); starChanceLabel.Position = UDim2.new(0,5,0,97)
   672→starChanceLabel.BackgroundTransparency = 1; starChanceLabel.Text = "⭐ 1/3 star chance!"
   673→starChanceLabel.TextColor3 = Color3.fromRGB(200,160,255); starChanceLabel.TextScaled = true
   674→starChanceLabel.Font = Enum.Font.Gotham; starChanceLabel.Parent = tourneyHUD
   675→
   676→-- ============================================================
   677→-- TOURNEY RESULT POPUP
   678→-- ============================================================
   679→local tourneyResult = Instance.new("Frame")
   680→tourneyResult.Name             = "TourneyResult"
   681→tourneyResult.Size             = UDim2.new(0, 400, 0, 420)
   682→tourneyResult.Position         = UDim2.new(0.5, -200, 0.5, -210)
   683→tourneyResult.BackgroundColor3 = Color3.fromRGB(10, 14, 42)
   684→tourneyResult.BackgroundTransparency = 0.05
   685→tourneyResult.BorderSizePixel  = 0
   686→tourneyResult.Visible          = false
   687→tourneyResult.Parent           = screenGui
   688→Instance.new("UICorner", tourneyResult).CornerRadius = UDim.new(0, 16)
   689→
   690→local trResultTitle = Instance.new("TextLabel")
   691→trResultTitle.Size = UDim2.new(1,-20,0,46); trResultTitle.Position = UDim2.new(0,10,0,8)
   692→trResultTitle.BackgroundTransparency=1; trResultTitle.Text="⏰ TOURNAMENT OVER!"
   693→trResultTitle.TextColor3=Color3.fromRGB(255,220,60); trResultTitle.TextScaled=true
   694→trResultTitle.Font=Enum.Font.GothamBold; trResultTitle.Parent=tourneyResult
   695→
   696→local trTrophyLabel = Instance.new("TextLabel")
   697→trTrophyLabel.Name="TrophyLabel"; trTrophyLabel.Size=UDim2.new(1,-20,0,48); trTrophyLabel.Position=UDim2.new(0,10,0,56)
   698→trTrophyLabel.BackgroundTransparency=1; trTrophyLabel.Text=""
   699→trTrophyLabel.TextColor3=Color3.fromRGB(255,200,0); trTrophyLabel.TextScaled=true
   700→trTrophyLabel.Font=Enum.Font.GothamBold; trTrophyLabel.Parent=tourneyResult
   701→
   702→local trFishLabel = Instance.new("TextLabel")
   703→trFishLabel.Name="FishLabel"; trFishLabel.Size=UDim2.new(1,-20,0,30); trFishLabel.Position=UDim2.new(0,10,0,106)
   704→trFishLabel.BackgroundTransparency=1; trFishLabel.Text=""
   705→trFishLabel.TextColor3=Color3.fromRGB(170,255,170); trFishLabel.TextScaled=true
   706→trFishLabel.Font=Enum.Font.Gotham; trFishLabel.Parent=tourneyResult
   707→
   708→-- Leaderboard (scrolling)
   709→local lbScroll = Instance.new("ScrollingFrame")
   710→lbScroll.Name="LeaderboardScroll"; lbScroll.Size=UDim2.new(1,-20,0,180); lbScroll.Position=UDim2.new(0,10,0,142)
   711→lbScroll.BackgroundColor3=Color3.fromRGB(15,15,35); lbScroll.BackgroundTransparency=0.3
   712→lbScroll.BorderSizePixel=0; lbScroll.CanvasSize=UDim2.new(0,0,0,0)
   713→lbScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; lbScroll.ScrollBarThickness=4; lbScroll.Parent=tourneyResult
   714→Instance.new("UICorner",lbScroll).CornerRadius=UDim.new(0,8)
   715→local lbLayout=Instance.new("UIListLayout",lbScroll); lbLayout.Padding=UDim.new(0,2); lbLayout.SortOrder=Enum.SortOrder.LayoutOrder
   716→
   717→local trCloseBtn = Instance.new("TextButton")
   718→trCloseBtn.Size=UDim2.new(0.5,0,0,42); trCloseBtn.Position=UDim2.new(0.25,0,0,368)
   719→trCloseBtn.BackgroundColor3=Color3.fromRGB(60,60,80); trCloseBtn.BorderSizePixel=0
   720→trCloseBtn.Text="Close"; trCloseBtn.TextColor3=Color3.fromRGB(200,200,200)
   721→trCloseBtn.TextScaled=true; trCloseBtn.Font=Enum.Font.GothamBold; trCloseBtn.Parent=tourneyResult
   722→Instance.new("UICorner",trCloseBtn).CornerRadius=UDim.new(0,10)
   723→trCloseBtn.Activated:Connect(function() tourneyResult.Visible=false end)
   724→
   725→-- ============================================================
   726→-- CURRENCY UPDATES (from server)
   727→-- ============================================================
   728→Remotes.CoinsUpdate.OnClientEvent:Connect(function(coins)
   729→	coinsLabel.Text     = "🪙 " .. coins
   730→	shopCoinsLabel.Text = "🪙 " .. coins .. "  ⭐ " .. (starsLabel.Text:match("%d+") or "0")
   731→end)
   732→
   733→Remotes.StarsUpdate.OnClientEvent:Connect(function(stars)
   734→	starsLabel.Text     = "⭐ " .. stars
   735→	shopCoinsLabel.Text = "🪙 " .. (coinsLabel.Text:match("%d+") or "0") .. "  ⭐ " .. stars
   736→end)
   737→
   738→-- ============================================================
   739→-- TOURNAMENT EVENTS (server-wide)
   740→-- ============================================================
   741→local tourneyActiveTimer = 0
   742→
   743→Remotes.TournamentCountdown.OnClientEvent:Connect(function(secondsLeft, isActive)
   744→	if isActive then
   745→		-- Show active HUD, hide early-buy button
   746→		earlyBtn.Visible = false
   747→		local m = math.floor(secondsLeft / 60)
   748→		local s = secondsLeft % 60
   749→		countdownLabel.Text      = string.format("🏆 ACTIVE — %d:%02d left", m, s)
   750→		countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
   751→		countdownSub.Text        = "⭐ 1/3 star chance!"
   752→		tourneyHUD.Visible       = true
   753→		-- Update active HUD timer
   754→		timerLabel.Text      = string.format("⏱ %d:%02d", m, s)
   755→		timerLabel.TextColor3 = secondsLeft <= 30 and Color3.fromRGB(255,80,80) or Color3.fromRGB(255,220,60)
   756→	else
   757→		tourneyHUD.Visible   = false
   758→		earlyBtn.Visible     = secondsLeft > 60  -- only show buy button if >1 min until start
   759→		local m = math.floor(secondsLeft / 60)
   760→		local s = secondsLeft % 60
   761→		countdownLabel.Text      = string.format("🏆 Next tourney: %d:%02d", m, s)
   762→		countdownLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
   763→		countdownSub.Text        = "server-wide event • 1/5 star chance"
   764→	end
   765→end)
   766→
   767→Remotes.TournamentStart.OnClientEvent:Connect(function(_duration)
   768→	fishCountLabel.Text  = "🐟 0 fish caught"
   769→	rankLabel.Text       = "Rank: —"
   770→	tourneyHUD.Visible   = true
   771→end)
   772→
   773→Remotes.TournamentPoints.OnClientEvent:Connect(function(myFish, leaderboardData)
   774→	fishCountLabel.Text = "🐟 " .. myFish .. " fish caught"
   775→	-- Find local player's rank
   776→	if type(leaderboardData) == "table" then
   777→		local localName = game:GetService("Players").LocalPlayer.Name
   778→		for i, entry in ipairs(leaderboardData) do
   779→			if entry.name == localName then
   780→				local medal = i == 1 and "🥇" or (i <= 3 and "🥈" or "🥉")
   781→				rankLabel.Text = medal .. " Rank #" .. i .. " / " .. #leaderboardData
   782→				break
   783→			end
   784→		end
   785→	end
   786→end)
   787→
   788→Remotes.TournamentEnd.OnClientEvent:Connect(function(data)
   789→	tourneyHUD.Visible = false
   790→	-- Trophy banner
   791→	local trophyStr = data.trophy or "none"
   792→	local bannerText
   793→	if     trophyStr == "Gold"   then bannerText = "🥇 You placed GOLD!"
   794→	elseif trophyStr == "Silver" then bannerText = "🥈 You placed SILVER!"
   795→	elseif trophyStr == "Bronze" then bannerText = "🥉 You placed BRONZE!"
   796→	else                              bannerText = "Better luck next time!"
   797→	end
   798→	trTrophyLabel.Text = bannerText
   799→	trFishLabel.Text   = "You caught " .. (data.fishCaught or 0) .. " fish"
   800→		.. (data.rank and data.rank > 0 and (" • Rank #" .. data.rank) or "")
   801→
   802→	-- Rebuild leaderboard rows
   803→	for _, c in ipairs(lbScroll:GetChildren()) do
   804→		if c:IsA("TextLabel") then c:Destroy() end
   805→	end
   806→	if type(data.leaderboard) == "table" then
   807→		for i, entry in ipairs(data.leaderboard) do
   808→			local medal = i == 1 and "🥇" or (i <= 3 and "🥈" or (entry.count >= 1 and "🥉" or "  "))
   809→			local row = Instance.new("TextLabel")
   810→			row.Size = UDim2.new(1,-8,0,26); row.BackgroundTransparency=1
   811→			row.Text = string.format("%s #%d  %s — %d fish", medal, i, entry.name, entry.count)
   812→			row.TextColor3 = i==1 and Color3.fromRGB(255,220,60)
   813→				or (i<=3 and Color3.fromRGB(200,200,255) or Color3.fromRGB(180,180,180))
   814→			row.TextScaled=true; row.Font=Enum.Font.Gotham
   815→			row.TextXAlignment=Enum.TextXAlignment.Left
   816→			row.LayoutOrder=i; row.Parent=lbScroll
   817→		end
   818→	end
   819→	tourneyResult.Visible = true
   820→end)
   821→
   822→-- ============================================================
   823→-- JOURNAL BUTTON (bottom-left, next to shop)
   824→-- ============================================================
   825→local journalButton = Instance.new("TextButton")
   826→journalButton.Name             = "JournalButton"
   827→journalButton.Size             = UDim2.new(0, 130, 0, 46)
   828→journalButton.Position         = UDim2.new(0, 438, 1, -68)
   829→journalButton.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
   830→journalButton.BorderSizePixel  = 0
   831→journalButton.Text             = "Journal"
   832→journalButton.TextColor3       = Color3.fromRGB(255, 255, 255)
   833→journalButton.TextScaled       = true
   834→journalButton.Font             = Enum.Font.GothamBold
   835→journalButton.Parent           = screenGui
   836→Instance.new("UICorner", journalButton).CornerRadius = UDim.new(0, 10)
   837→
   838→-- ============================================================
   839→-- JOURNAL PANEL
   840→-- ============================================================
   841→local journalPanel = Instance.new("Frame")
   842→journalPanel.Name                   = "JournalPanel"
   843→journalPanel.Size                   = UDim2.new(0, 460, 0, 530)
   844→journalPanel.Position               = UDim2.new(0, 18, 1, -612)
   845→journalPanel.BackgroundColor3       = Color3.fromRGB(14, 10, 28)
   846→journalPanel.BackgroundTransparency = 0.05
   847→journalPanel.BorderSizePixel        = 0
   848→journalPanel.Visible                = false
   849→journalPanel.Parent                 = screenGui
   850→Instance.new("UICorner", journalPanel).CornerRadius = UDim.new(0, 14)
   851→
   852→local journalTitle = Instance.new("TextLabel")
   853→journalTitle.Size               = UDim2.new(1, 0, 0, 46)
   854→journalTitle.Position           = UDim2.new(0, 0, 0, 0)
   855→journalTitle.BackgroundTransparency = 1
   856→journalTitle.Text               = "📓 Quest Journal"
   857→journalTitle.TextColor3         = Color3.fromRGB(200, 170, 255)
   858→journalTitle.TextScaled         = true
   859→journalTitle.Font               = Enum.Font.GothamBold
   860→journalTitle.Parent             = journalPanel
   861→
   862→-- ── Tab buttons ───────────────────────────────────────────────
   863→local tabAchBtn = Instance.new("TextButton")
   864→tabAchBtn.Name             = "TabAch"
   865→tabAchBtn.Size             = UDim2.new(0.5, -10, 0, 36)
   866→tabAchBtn.Position         = UDim2.new(0, 8, 0, 48)
   867→tabAchBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 140)
   868→tabAchBtn.BorderSizePixel  = 0
   869→tabAchBtn.Text             = "🏆 Achievements"
   870→tabAchBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
   871→tabAchBtn.TextScaled       = true
   872→tabAchBtn.Font             = Enum.Font.GothamBold
   873→tabAchBtn.Parent           = journalPanel
   874→Instance.new("UICorner", tabAchBtn).CornerRadius = UDim.new(0, 8)
   875→
   876→local tabGuideBtn = Instance.new("TextButton")
   877→tabGuideBtn.Name             = "TabGuide"
   878→tabGuideBtn.Size             = UDim2.new(0.5, -10, 0, 36)
   879→tabGuideBtn.Position         = UDim2.new(0.5, 2, 0, 48)
   880→tabGuideBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
   881→tabGuideBtn.BorderSizePixel  = 0
   882→tabGuideBtn.Text             = "📖 Guide"
   883→tabGuideBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
   884→tabGuideBtn.TextScaled       = true
   885→tabGuideBtn.Font             = Enum.Font.Gotham
   886→tabGuideBtn.Parent           = journalPanel
   887→Instance.new("UICorner", tabGuideBtn).CornerRadius = UDim.new(0, 8)
   888→
   889→-- ── Achievements tab (scrolling) ──────────────────────────────
   890→local achFrame = Instance.new("ScrollingFrame")
   891→achFrame.Name                = "AchFrame"
   892→achFrame.Size                = UDim2.new(1, -16, 1, -92)
   893→achFrame.Position            = UDim2.new(0, 8, 0, 90)
   894→achFrame.BackgroundTransparency = 1
   895→achFrame.BorderSizePixel     = 0
   896→achFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
   897→achFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
   898→achFrame.ScrollBarThickness  = 6
   899→achFrame.Visible             = true
   900→achFrame.Parent              = journalPanel
   901→
   902→Instance.new("UIListLayout", achFrame).Padding   = UDim.new(0, 6)
   903→
   904→-- ── Guide tab (scrolling) ─────────────────────────────────────
   905→local guideFrame = Instance.new("ScrollingFrame")
   906→guideFrame.Name                = "GuideFrame"
   907→guideFrame.Size                = UDim2.new(1, -16, 1, -92)
   908→guideFrame.Position            = UDim2.new(0, 8, 0, 90)
   909→guideFrame.BackgroundTransparency = 1
   910→guideFrame.BorderSizePixel     = 0
   911→guideFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
   912→guideFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
   913→guideFrame.ScrollBarThickness  = 6
   914→guideFrame.Visible             = false
   915→guideFrame.Parent              = journalPanel
   916→
   917→local guideLayout = Instance.new("UIListLayout")
   918→guideLayout.Padding   = UDim.new(0, 6)
   919→guideLayout.SortOrder = Enum.SortOrder.LayoutOrder
   920→guideLayout.Parent    = guideFrame
   921→
   922→local GUIDE_SECTIONS = {
   923→	{ title = "🎣  How to Fish",
   924→	  body  = "Walk up to any water and press [E] to cast your line. Wait for the bobber to bite, then the minigame starts automatically!" },
   925→	{ title = "🎮  Minigame Controls",
   926→	  body  = "Hold [LEFT CLICK] to lift the catch bar up. Release to let it fall. Keep the fish icon (🐟) inside the green bar. Fill the progress meter on the right to win!" },
   927→	{ title = "🪱🪝🎣  Upgrades",
   928→	  body  = "Visit the 🏪 Shop NPC near the water (or press the Shop button). Bait = better rarity luck. Hook = slower fish movement in minigame. Rod = bigger green catch bar." },
   929→	{ title = "🏆  Tournament",
   930→	  body  = "Press TOURNEY to start a 3-minute fishing sprint! Catch 3+ fish in one run for a +2 bonus. Earn trophies: 🥉 5 pts total, 🥈 15 pts, 🥇 30 pts." },
   931→	{ title = "🪙  Coins & Rewards",
   932→	  body  = "Every fish earns coins — Common: 5, Uncommon: 15, Rare: 50, Legendary: 150. Spend coins on upgrades in the shop." },
   933→	{ title = "📖  Achievements",
   934→	  body  = "Unlock achievements by catching fish, landing rare catches, upgrading gear, and winning tournaments. Check the Achievements tab above for your progress!" },
   935→}
   936→
   937→for i, sec in ipairs(GUIDE_SECTIONS) do
   938→	local titleLbl = Instance.new("TextLabel")
   939→	titleLbl.Size               = UDim2.new(1, -8, 0, 28)
   940→	titleLbl.BackgroundTransparency = 1
   941→	titleLbl.Text               = sec.title
   942→	titleLbl.TextColor3         = Color3.fromRGB(200, 170, 255)
   943→	titleLbl.TextScaled         = true
   944→	titleLbl.Font               = Enum.Font.GothamBold
   945→	titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
   946→	titleLbl.LayoutOrder        = i * 2 - 1
   947→	titleLbl.Parent             = guideFrame
   948→
   949→	local bodyLbl = Instance.new("TextLabel")
   950→	bodyLbl.Size                = UDim2.new(1, -8, 0, 56)
   951→	bodyLbl.BackgroundColor3    = Color3.fromRGB(30, 20, 50)
   952→	bodyLbl.BackgroundTransparency = 0.35
   953→	bodyLbl.Text                = sec.body
   954→	bodyLbl.TextColor3          = Color3.fromRGB(210, 210, 220)
   955→	bodyLbl.TextWrapped         = true
   956→	bodyLbl.TextScaled          = false
   957→	bodyLbl.TextSize            = 13
   958→	bodyLbl.Font                = Enum.Font.Gotham
   959→	bodyLbl.TextXAlignment      = Enum.TextXAlignment.Left
   960→	bodyLbl.TextYAlignment      = Enum.TextYAlignment.Top
   961→	bodyLbl.LayoutOrder         = i * 2
   962→	bodyLbl.Parent              = guideFrame
   963→	Instance.new("UICorner", bodyLbl).CornerRadius = UDim.new(0, 6)
   964→	local pad = Instance.new("UIPadding", bodyLbl)
   965→	pad.PaddingLeft   = UDim.new(0, 6)
   966→	pad.PaddingTop    = UDim.new(0, 4)
   967→	pad.PaddingRight  = UDim.new(0, 6)
   968→	pad.PaddingBottom = UDim.new(0, 4)
   969→end
   970→
   971→-- ── Tab switching ─────────────────────────────────────────────
   972→local function setTab(showAch)
   973→	achFrame.Visible   = showAch
   974→	guideFrame.Visible = not showAch
   975→	if showAch then
   976→		tabAchBtn.BackgroundColor3   = Color3.fromRGB(80, 50, 140)
   977→		tabAchBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
   978→		tabAchBtn.Font               = Enum.Font.GothamBold
   979→		tabGuideBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
   980→		tabGuideBtn.TextColor3       = Color3.fromRGB(200, 200, 200)
   981→		tabGuideBtn.Font             = Enum.Font.Gotham
   982→	else
   983→		tabAchBtn.BackgroundColor3   = Color3.fromRGB(40, 30, 60)
   984→		tabAchBtn.TextColor3         = Color3.fromRGB(200, 200, 200)
   985→		tabAchBtn.Font               = Enum.Font.Gotham
   986→		tabGuideBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 140)
   987→		tabGuideBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
   988→		tabGuideBtn.Font             = Enum.Font.GothamBold
   989→	end
   990→end
   991→
   992→tabAchBtn.Activated:Connect(function()  setTab(true)  end)
   993→tabGuideBtn.Activated:Connect(function() setTab(false) end)
   994→
   995→-- ── Rebuild achievement cards ─────────────────────────────────
   996→local function refreshAchievements()
   997→	for _, c in ipairs(achFrame:GetChildren()) do
   998→		if c:IsA("Frame") then c:Destroy() end
   999→	end
  1000→
  1001→	local stats, completed = Remotes.GetAchievements:InvokeServer()
  1002→	stats     = stats     or {}
  1003→	completed = completed or {}
  1004→
  1005→	local doneCount = 0
  1006→	for _, ach in ipairs(AchievementData) do
  1007→		if completed[ach.id] then doneCount += 1 end
  1008→	end
  1009→
  1010→	-- Summary row at top
  1011→	local summaryLbl = Instance.new("TextLabel")
  1012→	summaryLbl.Size               = UDim2.new(1, -4, 0, 28)
  1013→	summaryLbl.BackgroundTransparency = 1
  1014→	summaryLbl.Text               = ("✅ %d / %d achievements unlocked"):format(doneCount, #AchievementData)
  1015→	summaryLbl.TextColor3         = Color3.fromRGB(180, 255, 180)
  1016→	summaryLbl.TextScaled         = true
  1017→	summaryLbl.Font               = Enum.Font.Gotham
  1018→	summaryLbl.LayoutOrder        = 0
  1019→	summaryLbl.Parent             = achFrame
  1020→
  1021→	for i, ach in ipairs(AchievementData) do
  1022→		local isDone   = completed[ach.id] == true
  1023→		local progress = math.min(stats[ach.statKey] or 0, ach.goal)
  1024→		local pct      = progress / ach.goal
  1025→
  1026→		local card = Instance.new("Frame")
  1027→		card.Name             = "Ach_" .. ach.id
  1028→		card.Size             = UDim2.new(1, -4, 0, 72)
  1029→		card.BackgroundColor3 = isDone
  1030→			and Color3.fromRGB(15, 45, 15)
  1031→			or  Color3.fromRGB(24, 14, 44)
  1032→		card.BackgroundTransparency = 0.2
  1033→		card.BorderSizePixel  = 0
  1034→		card.LayoutOrder      = isDone and (1000 + i) or i
  1035→		card.Parent           = achFrame
  1036→		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
  1037→
  1038→		-- Icon
  1039→		local iconLbl = Instance.new("TextLabel")
  1040→		iconLbl.Size               = UDim2.new(0, 46, 0, 46)
  1041→		iconLbl.Position           = UDim2.new(0, 4, 0.5, -23)
  1042→		iconLbl.BackgroundTransparency = 1
  1043→		iconLbl.Text               = ach.icon
  1044→		iconLbl.TextScaled         = true
  1045→		iconLbl.Font               = Enum.Font.Gotham
  1046→		iconLbl.Parent             = card
  1047→
  1048→		-- Name
  1049→		local nameLbl = Instance.new("TextLabel")
  1050→		nameLbl.Size               = UDim2.new(1, -110, 0, 22)
  1051→		nameLbl.Position           = UDim2.new(0, 54, 0, 7)
  1052→		nameLbl.BackgroundTransparency = 1
  1053→		nameLbl.Text               = (isDone and "✅ " or "") .. ach.name
  1054→		nameLbl.TextColor3         = isDone
  1055→			and Color3.fromRGB(100, 255, 100)
  1056→			or  Color3.fromRGB(255, 255, 255)
  1057→		nameLbl.TextScaled         = true
  1058→		nameLbl.Font               = Enum.Font.GothamBold
  1059→		nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
  1060→		nameLbl.Parent             = card
  1061→
  1062→		-- Desc
  1063→		local descLbl = Instance.new("TextLabel")
  1064→		descLbl.Size               = UDim2.new(1, -110, 0, 18)
  1065→		descLbl.Position           = UDim2.new(0, 54, 0, 29)
  1066→		descLbl.BackgroundTransparency = 1
  1067→		descLbl.Text               = ach.desc
  1068→		descLbl.TextColor3         = Color3.fromRGB(160, 160, 175)
  1069→		descLbl.TextScaled         = true
  1070→		descLbl.Font               = Enum.Font.Gotham
  1071→		descLbl.TextXAlignment     = Enum.TextXAlignment.Left
  1072→		descLbl.Parent             = card
  1073→
  1074→		-- Progress bar bg
  1075→		local pbarBg = Instance.new("Frame")
  1076→		pbarBg.Size               = UDim2.new(1, -60, 0, 10)
  1077→		pbarBg.Position           = UDim2.new(0, 54, 0, 52)
  1078→		pbarBg.BackgroundColor3   = Color3.fromRGB(45, 45, 58)
  1079→		pbarBg.BorderSizePixel    = 0
  1080→		pbarBg.Parent             = card
  1081→		Instance.new("UICorner", pbarBg).CornerRadius = UDim.new(0, 4)
  1082→
  1083→		local pbarFill = Instance.new("Frame")
  1084→		pbarFill.Size             = UDim2.new(pct, 0, 1, 0)
  1085→		pbarFill.BackgroundColor3 = isDone
  1086→			and Color3.fromRGB(60, 210, 80)
  1087→			or  Color3.fromRGB(100, 140, 255)
  1088→		pbarFill.BorderSizePixel  = 0
  1089→		pbarFill.Parent           = pbarBg
  1090→		Instance.new("UICorner", pbarFill).CornerRadius = UDim.new(0, 4)
  1091→
  1092→		-- Progress text (top-right of card)
  1093→		local pctLbl = Instance.new("TextLabel")
  1094→		pctLbl.Size               = UDim2.new(0, 52, 0, 20)
  1095→		pctLbl.Position           = UDim2.new(1, -54, 0, 7)
  1096→		pctLbl.BackgroundTransparency = 1
  1097→		pctLbl.Text               = isDone and "DONE" or (progress .. "/" .. ach.goal)
  1098→		pctLbl.TextColor3         = isDone
  1099→			and Color3.fromRGB(100, 255, 100)
  1100→			or  Color3.fromRGB(180, 180, 200)
  1101→		pctLbl.TextScaled         = true
  1102→		pctLbl.Font               = Enum.Font.Gotham
  1103→		pctLbl.TextXAlignment     = Enum.TextXAlignment.Right
  1104→		pctLbl.Parent             = card
  1105→	end
  1106→end
  1107→
  1108→-- Open / close journal
  1109→journalButton.Activated:Connect(function()
  1110→	invPanel.Visible     = false
  1111→	shopPanel.Visible    = false
  1112→	journalPanel.Visible = not journalPanel.Visible
  1113→	if journalPanel.Visible then refreshAchievements() end
  1114→end)
  1115→
  1116→-- Bait nav button
  1117→local baitButton = Instance.new("TextButton")
  1118→baitButton.Name             = "BaitButton"
  1119→baitButton.Size             = UDim2.new(0, 120, 0, 46)
  1120→baitButton.Position         = UDim2.new(0, 298, 1, -68)
  1121→baitButton.BackgroundColor3 = Color3.fromRGB(40, 110, 50)
  1122→baitButton.BorderSizePixel  = 0
  1123→baitButton.Text             = "Bait"
  1124→baitButton.TextColor3       = Color3.fromRGB(255, 255, 255)
  1125→baitButton.TextScaled       = true
  1126→baitButton.Font             = Enum.Font.GothamBold
  1127→baitButton.ZIndex           = 4
  1128→baitButton.Parent           = screenGui
  1129→Instance.new("UICorner", baitButton).CornerRadius = UDim.new(0, 10)
  1130→
  1131→-- Bait Panel
  1132→local baitPanel = Instance.new("Frame")
  1133→baitPanel.Name                   = "BaitPanel"
  1134→baitPanel.Size                   = UDim2.new(0, 320, 0, 420)
  1135→baitPanel.Position               = UDim2.new(0, 18, 1, -502)
  1136→baitPanel.BackgroundColor3       = Color3.fromRGB(10, 30, 10)
  1137→baitPanel.BackgroundTransparency = 0.05
  1138→baitPanel.BorderSizePixel        = 0
  1139→baitPanel.Visible                = false
  1140→baitPanel.ZIndex                 = 6
  1141→baitPanel.Parent                 = screenGui
  1142→Instance.new("UICorner", baitPanel).CornerRadius = UDim.new(0, 14)
  1143→
  1144→local baitTitle = Instance.new("TextLabel")
  1145→baitTitle.Size               = UDim2.new(1, 0, 0, 44)
  1146→baitTitle.BackgroundTransparency = 1
  1147→baitTitle.Text               = "Bait Selection"
  1148→baitTitle.TextColor3         = Color3.fromRGB(100, 220, 100)
  1149→baitTitle.TextScaled         = true
  1150→baitTitle.Font               = Enum.Font.GothamBold
  1151→baitTitle.ZIndex             = 6
  1152→baitTitle.Parent             = baitPanel
  1153→
  1154→local baitRows = {}
  1155→local function refreshBaitPanel(inv, current)
  1156→	for _, r in ipairs(baitRows) do r:Destroy() end
  1157→	baitRows = {}
  1158→	local baitInv, baitCurrent = inv, current
  1159→	if not baitInv then
  1160→		local ok, res = pcall(function() return Remotes.GetBaitState:InvokeServer() end)
  1161→		if ok and res then baitInv = res.inventory; baitCurrent = res.current end
  1162→	end
  1163→	if not baitInv then return end
  1164→	for i, bait in ipairs(BaitData) do
  1165→		local row = Instance.new("Frame")
  1166→		row.Size             = UDim2.new(1, -16, 0, 58)
  1167→		row.Position         = UDim2.new(0, 8, 0, 44 + (i-1)*62)
  1168→		row.BackgroundColor3 = (baitCurrent == bait.id) and Color3.fromRGB(20,60,20) or Color3.fromRGB(15,35,15)
  1169→		row.BackgroundTransparency = 0.2
  1170→		row.BorderSizePixel  = 0
  1171→		row.ZIndex           = 6
  1172→		row.Parent           = baitPanel
  1173→		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
  1174→		table.insert(baitRows, row)
  1175→		local nameLabel = Instance.new("TextLabel")
  1176→		nameLabel.Size             = UDim2.new(0.55, 0, 0.5, 0)
  1177→		nameLabel.BackgroundTransparency = 1
  1178→		nameLabel.Text             = bait.name
  1179→		nameLabel.TextColor3       = Color3.fromRGB(200, 255, 200)
  1180→		nameLabel.TextScaled       = true
  1181→		nameLabel.Font             = Enum.Font.GothamBold
  1182→		nameLabel.TextXAlignment   = Enum.TextXAlignment.Left
  1183→		nameLabel.Position         = UDim2.new(0, 8, 0, 0)
  1184→		nameLabel.ZIndex           = 6
  1185→		nameLabel.Parent           = row
  1186→		local countLabel = Instance.new("TextLabel")
  1187→		countLabel.Size            = UDim2.new(0.45, 0, 0.5, 0)
  1188→		countLabel.Position        = UDim2.new(0, 8, 0.5, 0)
  1189→		countLabel.BackgroundTransparency = 1
  1190→		countLabel.Text            = "x" .. (baitInv[bait.id] or 0)
  1191→		countLabel.TextColor3      = Color3.fromRGB(180, 180, 180)
  1192→		countLabel.TextScaled      = true
  1193→		countLabel.Font            = Enum.Font.Gotham
  1194→		countLabel.TextXAlignment  = Enum.TextXAlignment.Left
  1195→		countLabel.ZIndex          = 6
  1196→		countLabel.Parent          = row
  1197→		local selBtn = Instance.new("TextButton")
  1198→		selBtn.Size              = UDim2.new(0, 70, 0, 28)
  1199→		selBtn.Position          = UDim2.new(1, -78, 0.5, -14)
  1200→		selBtn.BackgroundColor3  = (baitCurrent == bait.id) and Color3.fromRGB(60,160,60) or Color3.fromRGB(40,100,40)
  1201→		selBtn.BorderSizePixel   = 0
  1202→		selBtn.Text              = (baitCurrent == bait.id) and "Active" or "Select"
  1203→		selBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
  1204→		selBtn.TextScaled        = true
  1205→		selBtn.Font              = Enum.Font.GothamBold
  1206→		selBtn.ZIndex            = 7
  1207→		selBtn.Parent            = row
  1208→		Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 6)
  1209→		local baitId = bait.id
  1210→		selBtn.Activated:Connect(function()
  1211→			Remotes.SelectBait:FireServer(baitId)
  1212→			task.delay(0.3, function() refreshBaitPanel(nil, nil) end)
  1213→		end)
  1214→		local buyBtn = Instance.new("TextButton")
  1215→		buyBtn.Size             = UDim2.new(0, 68, 0, 26)
  1216→		buyBtn.Position         = UDim2.new(1, -78, 1, -32)
  1217→		buyBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 20)
  1218→		buyBtn.BorderSizePixel  = 0
  1219→		buyBtn.Text             = "Buy " .. bait.shopCost .. "c"
  1220→		buyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
  1221→		buyBtn.TextScaled       = true
  1222→		buyBtn.Font             = Enum.Font.GothamBold
  1223→		buyBtn.ZIndex           = 7
  1224→		buyBtn.Parent           = row
  1225→		Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)
  1226→		local bId = bait.id
  1227→		buyBtn.Activated:Connect(function()
  1228→			local ok2, result = pcall(function() return Remotes.BuyBait:InvokeServer(bId) end)
  1229→			if ok2 and result then
  1230→				task.delay(0.2, function() refreshBaitPanel(nil, nil) end)
  1231→			end
  1232→		end)
  1233→	end
  1234→end
  1235→
  1236→Remotes.BaitUpdate.OnClientEvent:Connect(function(inv, current)
  1237→	if baitPanel.Visible then refreshBaitPanel(inv, current) end
  1238→end)
  1239→
  1240→baitButton.Activated:Connect(function()
  1241→	invPanel.Visible     = false
  1242→	shopPanel.Visible    = false
  1243→	journalPanel.Visible = false
  1244→	baitPanel.Visible    = not baitPanel.Visible
  1245→	if baitPanel.Visible then refreshBaitPanel(nil, nil) end
  1246→end)
  1247→
  1248→-- ============================================================
  1249→-- ACHIEVEMENT UNLOCKED TOAST (slides in from top)
  1250→-- ============================================================
  1251→local achToast = Instance.new("Frame")
  1252→achToast.Name                   = "AchToast"
  1253→achToast.Size                   = UDim2.new(0, 330, 0, 72)
  1254→achToast.Position               = UDim2.new(0.5, -165, 0, -90)
  1255→achToast.BackgroundColor3       = Color3.fromRGB(18, 52, 18)
  1256→achToast.BackgroundTransparency = 0.08
  1257→achToast.BorderSizePixel        = 0
  1258→achToast.Visible                = false
  1259→achToast.ZIndex                 = 20
  1260→achToast.Parent                 = screenGui
  1261→Instance.new("UICorner", achToast).CornerRadius = UDim.new(0, 12)
  1262→
  1263→-- Subtle green left-border strip
  1264→local toastStrip = Instance.new("Frame")
  1265→toastStrip.Size             = UDim2.new(0, 5, 1, 0)
  1266→toastStrip.BackgroundColor3 = Color3.fromRGB(60, 220, 80)
  1267→toastStrip.BorderSizePixel  = 0
  1268→toastStrip.ZIndex           = 21
  1269→toastStrip.Parent           = achToast
  1270→Instance.new("UICorner", toastStrip).CornerRadius = UDim.new(0, 4)
  1271→
  1272→local toastHeader = Instance.new("TextLabel")
  1273→toastHeader.Size               = UDim2.new(1, -70, 0, 22)
  1274→toastHeader.Position           = UDim2.new(0, 60, 0, 8)
  1275→toastHeader.BackgroundTransparency = 1
  1276→toastHeader.Text               = "Achievement Unlocked!"
  1277→toastHeader.TextColor3         = Color3.fromRGB(100, 255, 100)
  1278→toastHeader.TextScaled         = true
  1279→toastHeader.Font               = Enum.Font.GothamBold
  1280→toastHeader.TextXAlignment     = Enum.TextXAlignment.Left
  1281→toastHeader.ZIndex             = 21
  1282→toastHeader.Parent             = achToast
  1283→
  1284→local toastIconLbl = Instance.new("TextLabel")
  1285→toastIconLbl.Size               = UDim2.new(0, 50, 0, 50)
  1286→toastIconLbl.Position           = UDim2.new(0, 8, 0.5, -25)
  1287→toastIconLbl.BackgroundTransparency = 1
  1288→toastIconLbl.Text               = "🏅"
  1289→toastIconLbl.TextScaled         = true
  1290→toastIconLbl.Font               = Enum.Font.Gotham
  1291→toastIconLbl.ZIndex             = 21
  1292→toastIconLbl.Parent             = achToast
  1293→
  1294→local toastNameLbl = Instance.new("TextLabel")
  1295→toastNameLbl.Name              = "AchName"
  1296→toastNameLbl.Size              = UDim2.new(1, -70, 0, 34)
  1297→toastNameLbl.Position          = UDim2.new(0, 60, 0, 30)
  1298→toastNameLbl.BackgroundTransparency = 1
  1299→toastNameLbl.Text              = ""
  1300→toastNameLbl.TextColor3        = Color3.fromRGB(230, 230, 240)
  1301→toastNameLbl.TextScaled        = true
  1302→toastNameLbl.Font              = Enum.Font.Gotham
  1303→toastNameLbl.TextXAlignment    = Enum.TextXAlignment.Left
  1304→toastNameLbl.ZIndex            = 21
  1305→toastNameLbl.Parent            = achToast
  1306→
  1307→local toastShowing = false
  1308→local toastQueue   = {}
  1309→
  1310→local function showNextToast()
  1311→	if toastShowing or #toastQueue == 0 then return end
  1312→	toastShowing = true
  1313→	local info = table.remove(toastQueue, 1)
  1314→
  1315→	toastIconLbl.Text = info.icon or "🏅"
  1316→	toastNameLbl.Text = (info.name or "") .. "  —  " .. (info.desc or "")
  1317→	achToast.Position = UDim2.new(0.5, -165, 0, -90)
  1318→	achToast.Visible  = true
  1319→
  1320→	local tweenIn = TweenService:Create(
  1321→		achToast,
  1322→		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
  1323→		{ Position = UDim2.new(0.5, -165, 0, 78) }
  1324→	)
  1325→	tweenIn:Play()
  1326→
  1327→	task.delay(3.8, function()
  1328→		local tweenOut = TweenService:Create(
  1329→			achToast,
  1330→			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
  1331→			{ Position = UDim2.new(0.5, -165, 0, -90) }
  1332→		)
  1333→		tweenOut:Play()
  1334→		tweenOut.Completed:Connect(function()
  1335→			achToast.Visible = false
  1336→			toastShowing     = false
  1337→			showNextToast()
  1338→		end)
  1339→	end)
  1340→end
  1341→
  1342→Remotes.AchievementUnlocked.OnClientEvent:Connect(function(info)
  1343→	table.insert(toastQueue, info)
  1344→	showNextToast()
  1345→	-- If journal is open, refresh it so the new achievement shows immediately
  1346→	if journalPanel.Visible then refreshAchievements() end
  1347→end)
  1348→
  1349→-- ============================================================
  1350→-- DEBUG GIVE COINS (Studio only — purple button top-right)
  1351→-- ============================================================
  1352→if RunService:IsStudio() then
  1353→	local debugBtn = Instance.new("TextButton")
  1354→	debugBtn.Name             = "DebugCoinsBtn"
  1355→	debugBtn.Size             = UDim2.new(0, 165, 0, 38)
  1356→	debugBtn.Position         = UDim2.new(1, -183, 0, 70)
  1357→	debugBtn.BackgroundColor3 = Color3.fromRGB(110, 0, 170)
  1358→	debugBtn.BorderSizePixel  = 0
  1359→	debugBtn.Text             = "🟣 DEBUG +1000🪙"
  1360→	debugBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
  1361→	debugBtn.TextScaled       = true
  1362→	debugBtn.Font             = Enum.Font.GothamBold
  1363→	debugBtn.Parent           = screenGui
  1364→	Instance.new("UICorner", debugBtn).CornerRadius = UDim.new(0, 8)
  1365→
  1366→	debugBtn.Activated:Connect(function()
  1367→		Remotes.DebugGiveCoins:FireServer(1000)
  1368→		debugBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
  1369→		task.delay(0.5, function() debugBtn.BackgroundColor3 = Color3.fromRGB(110, 0, 170) end)
  1370→	end)
  1371→
  1372→	local debugStarsBtn = Instance.new("TextButton")
  1373→	debugStarsBtn.Name             = "DebugStarsBtn"
  1374→	debugStarsBtn.Size             = UDim2.new(0, 165, 0, 38)
  1375→	debugStarsBtn.Position         = UDim2.new(1, -183, 0, 114)
  1376→	debugStarsBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 140)
  1377→	debugStarsBtn.BorderSizePixel  = 0
  1378→	debugStarsBtn.Text             = "🟣 DEBUG +20⭐"
  1379→	debugStarsBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
  1380→	debugStarsBtn.TextScaled       = true
  1381→	debugStarsBtn.Font             = Enum.Font.GothamBold
  1382→	debugStarsBtn.Parent           = screenGui
  1383→	Instance.new("UICorner", debugStarsBtn).CornerRadius = UDim.new(0, 8)
  1384→	debugStarsBtn.Activated:Connect(function()
  1385→		Remotes.DebugGiveStars:FireServer(20)
  1386→		debugStarsBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
  1387→		task.delay(0.5, function() debugStarsBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 140) end)
  1388→	end)
  1389→
  1390→	-- Studio: force-start tournament for testing
  1391→	local debugTourneyBtn = Instance.new("TextButton")
  1392→	debugTourneyBtn.Name             = "DebugTourneyBtn"
  1393→	debugTourneyBtn.Size             = UDim2.new(0, 165, 0, 38)
  1394→	debugTourneyBtn.Position         = UDim2.new(1, -183, 0, 158)
  1395→	debugTourneyBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 0)
  1396→	debugTourneyBtn.BorderSizePixel  = 0
  1397→	debugTourneyBtn.Text             = "🏆 DEBUG TOURNEY"
  1398→	debugTourneyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
  1399→	debugTourneyBtn.TextScaled       = true
  1400→	debugTourneyBtn.Font             = Enum.Font.GothamBold
  1401→	debugTourneyBtn.Parent           = screenGui
  1402→	Instance.new("UICorner", debugTourneyBtn).CornerRadius = UDim.new(0, 8)
  1403→	debugTourneyBtn.Activated:Connect(function()
  1404→		Remotes.BuyTournament:FireServer()
  1405→	end)
  1406→end
  1407→
  1408→print("[FishingGui] UI built and ready!")
  1409→