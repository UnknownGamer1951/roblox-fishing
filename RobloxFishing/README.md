# Roblox Fishing Game - Starter Project

A Webfishing-inspired fishing game scaffold for Roblox Studio.  
Written in Lua with heavy comments so a beginner can read and modify it.

Test test hello
---

## File Overview

```
RobloxFishing/
│
├── ReplicatedStorage/
│   ├── FishData.lua          ← All fish types, rarities, and weights
│   └── FishingRemotes.lua    ← Network events (client ↔ server communication)
│
├── ServerScriptService/
│   ├── FishingServer.lua     ← Server-side fishing loop (cast, bite, catch logic)
│   └── InventoryServer.lua   ← Stores each player's caught fish on the server
│
├── StarterPlayerScripts/
│   └── FishingClient.lua     ← Detects player input, talks to server, updates UI
│
└── StarterGui/
    └── FishingGui.lua        ← Builds the HUD (status bar, reel button, catch popup, inventory)
```

---

## How to Set It Up in Roblox Studio

Open Roblox Studio and create a new **Baseplate** place.  
Then follow these steps one file at a time.

---

### Step 1 — FishData (ModuleScript in ReplicatedStorage)

1. In the **Explorer** panel, click `ReplicatedStorage`.
2. Click the **+** button and choose **ModuleScript**.
3. Rename it `FishData`.
4. Delete the default code inside it.
5. Paste the contents of `ReplicatedStorage/FishData.lua` into it.

---

### Step 2 — FishingRemotes (ModuleScript in ReplicatedStorage)

1. Right-click `ReplicatedStorage` → Insert Object → **ModuleScript**.
2. Rename it `FishingRemotes`.
3. Paste the contents of `ReplicatedStorage/FishingRemotes.lua` into it.

---

### Step 3 — FishingServer (Script in ServerScriptService)

1. Click `ServerScriptService`.
2. Insert a **Script** (NOT a LocalScript).
3. Rename it `FishingServer`.
4. Paste the contents of `ServerScriptService/FishingServer.lua` into it.

---

### Step 4 — InventoryServer (ModuleScript in ServerScriptService)

1. Right-click `ServerScriptService` → Insert Object → **ModuleScript**.
2. Rename it `InventoryServer`.
3. Paste the contents of `ServerScriptService/InventoryServer.lua` into it.

---

### Step 5 — FishingClient (LocalScript in StarterPlayerScripts)

1. In the Explorer, expand **StarterPlayer** → click **StarterPlayerScripts**.
2. Insert a **LocalScript**.
3. Rename it `FishingClient`.
4. Paste the contents of `StarterPlayerScripts/FishingClient.lua` into it.

---

### Step 6 — FishingGui (ScreenGui + LocalScript in StarterGui)

1. Click **StarterGui**.
2. Insert a **ScreenGui** and rename it `FishingGui`.
3. Inside `FishingGui`, insert a **LocalScript** and rename it `FishingGui`.
4. Paste the contents of `StarterGui/FishingGui.lua` into the LocalScript.

> The LocalScript builds all buttons and labels automatically — you do not
> need to create any UI elements by hand.

---

### Step 7 — Add Water to the Map

The fishing scripts work with any water surface. The simplest option:

1. In the **Toolbox** (View → Toolbox), search for "Water" or use the terrain editor.
2. Or just insert a large blue Part and rename it `Water` — the game will work fine.
3. Players click toward the water to cast.

---

### Step 8 — Play Test

1. Press **F5** (or the Play button) to start a local play test.
2. Click anywhere in front of your character to cast.
3. Wait for "A fish is biting! CLICK NOW!" — then click again.
4. Open "My Fish" in the bottom-left to see your catch log.

---

## How the Game Works (Plain English)

```
Player clicks
    → FishingClient sends "CastLine" to FishingServer
    → FishingServer spawns a red bobber ball in the world
    → FishingServer waits 3–12 seconds (random)
    → FishingServer picks a random fish (weighted by rarity)
    → FishingServer sends "FishBiting" to FishingClient
    → The UI flashes and shows a REEL IN button
    → Player clicks within the time window
    → FishingClient sends "ReelIn" to FishingServer
    → FishingServer adds the fish to InventoryServer
    → FishingServer sends "FishCaught" back to FishingClient
    → The UI shows a catch popup
```

---

## Adding More Fish

Open `ReplicatedStorage/FishData.lua` and add a new entry to the `FishData.Fish`
table following the same pattern:

```lua
{
    name    = "Swordfish",
    rarity  = "Rare",
    weight  = 6,        -- lower = appears less often
    minSize = 80,
    maxSize = 200,
    color   = "Bright blue",
},
```

That's all you need to do. The rest of the code picks it up automatically.

---

## Rarity Tiers

| Rarity    | Catch window | Weight (default) |
|-----------|-------------|------------------|
| Common    | 4 seconds   | 40–50            |
| Uncommon  | 3 seconds   | 20–25            |
| Rare      | 2.5 seconds | 5–8              |
| Legendary | 2 seconds   | 1                |

Adjust `weight` values in `FishData.lua` to change how often each fish appears.  
Adjust the `windowSeconds` values in `FishingServer.lua` to change difficulty.

---

## Next Steps (Ideas)

- Add a **rod / tool** so players must equip it before casting
- Add **fish sounds** (bite splash, reel-in sound)
- Add a **leaderboard** showing who caught the biggest fish
- Add **different fishing spots** with different fish pools
- Add a **day/night cycle** that changes which fish appear
- Save inventory with **DataStoreService** so it persists between sessions
