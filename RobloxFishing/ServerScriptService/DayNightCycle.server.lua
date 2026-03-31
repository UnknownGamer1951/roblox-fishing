-- ============================================================
-- DayNightCycle.server.lua  (Script in ServerScriptService)
-- Advances Lighting.ClockTime at a configurable pace.
-- One full day = CYCLE_MINUTES real minutes.
-- Lighting replicates to clients automatically.
--
-- Day   = ClockTime  6 → 20  (14 game-hours of daylight)
-- Night = ClockTime 20 →  6  (10 game-hours of darkness, wraps at 24)
-- ============================================================

local Lighting = game:GetService("Lighting")

local CYCLE_MINUTES = 20          -- one full in-game day = 20 real minutes
local SECONDS_PER_CYCLE = CYCLE_MINUTES * 60
-- How many ClockTime units advance per real second
local CLOCK_SPEED = 24 / SECONDS_PER_CYCLE  -- ≈ 0.02 units/s

-- Start at 8:00 (morning)
Lighting.ClockTime = 8

-- Set up sky / ambient colours for day vs night
local function applyTimeColors()
	local t = Lighting.ClockTime
	local isNight = (t >= 20 or t < 6)
	if isNight then
		Lighting.Ambient        = Color3.fromRGB(50, 50, 80)
		Lighting.OutdoorAmbient = Color3.fromRGB(35, 35, 60)
		Lighting.Brightness     = 0.4
	else
		Lighting.Ambient        = Color3.fromRGB(127, 127, 127)
		Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
		Lighting.Brightness     = 2
	end
end

applyTimeColors()

-- Advance clock every second
local TICK_RATE = 1  -- seconds between updates
while true do
	task.wait(TICK_RATE)
	local newTime = (Lighting.ClockTime + CLOCK_SPEED * TICK_RATE) % 24
	Lighting.ClockTime = newTime
	applyTimeColors()
end
