-- ============================================================
-- WeatherService.lua  (ModuleScript in ServerScriptService)
-- Periodic rain every RAIN_INTERVAL seconds, lasts RAIN_DURATION.
-- During rain, fishing wait time is halved (double speed).
-- FishingServer requires this and calls WeatherService.IsRaining().
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")

local Remotes = require(ReplicatedStorage:WaitForChild("FishingRemotes"))

local WeatherService = {}

local isRaining = false

local RAIN_INTERVAL = 30 * 60  -- 30 minutes between rain bursts
local RAIN_DURATION = 5  * 60  -- rain lasts 5 minutes

function WeatherService.IsRaining()
	return isRaining
end

-- Apply / remove Lighting atmosphere changes for rain
local function setRainAtmosphere(on)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		atmo.Density    = on and 0.72  or 0.35
		atmo.Offset     = on and 0.05  or 0.25
		atmo.Color      = on and Color3.fromRGB(170,185,200) or Color3.fromRGB(199,199,199)
	end
	-- Dim ambient & sky colour during rain
	Lighting.Ambient          = on and Color3.fromRGB(90, 90, 110) or Color3.fromRGB(127,127,127)
	Lighting.OutdoorAmbient   = on and Color3.fromRGB(80, 90, 105) or Color3.fromRGB(140,140,140)
end

task.spawn(function()
	task.wait(15)   -- let server finish loading before first check
	while true do
		task.wait(RAIN_INTERVAL)

		-- Start rain
		isRaining = true
		setRainAtmosphere(true)
		Remotes.WeatherChange:FireAllClients(true)
		print("[WeatherService] Rain started — fishing speed x2 for", RAIN_DURATION, "s")

		task.wait(RAIN_DURATION)

		-- Stop rain
		isRaining = false
		setRainAtmosphere(false)
		Remotes.WeatherChange:FireAllClients(false)
		print("[WeatherService] Rain stopped")
	end
end)

return WeatherService
