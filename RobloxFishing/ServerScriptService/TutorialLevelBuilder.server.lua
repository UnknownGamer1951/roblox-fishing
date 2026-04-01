-- ============================================================
-- TutorialLevelBuilder.server.lua
--
-- L-SHAPED tutorial map.  G = 4 (terrain top Y).
--
-- Seg1 (+Z):  Spawn(Z=-120) → Arch(Z=-70) → Pond(0,0) → Turn(Z=80)
-- Seg2 (-X):  Z=100, X=-30 → Lodge X=-110 → BaitPond X=-215 → Portal X=-330
--
-- HILL MATH (sphere centre at Y = G - r*0.58; inner terrain edge = centre_X ± r):
--   Seg1 side walls : X = ±62, r=22  → inner terrain edge X=±40  (clear zone ±20 ✓)
--   Seg2 side walls : Z = 45,  r=22  → inner edge Z=67   (clear zone Z 80-120 ✓)
--                     Z = 155, r=22  → inner edge Z=133  (clear zone Z 80-120 ✓)
--   Forward blocker : Z = 178, r=36  → inner edge Z=142  (Seg2 Z=100, gap=42 ✓)
--   Outer ring      : X=±220, Z=-210, Z=290, X=-420 — all 150+ studs from path
-- ============================================================

local Workspace = game:GetService("Workspace")

if Workspace:FindFirstChild("TutorialLevel") then
	print("[TutorialLevelBuilder] Already built — skipping.")
	return
end

for _, obj in ipairs(Workspace:GetChildren()) do
	if obj:IsA("SpawnLocation") then obj:Destroy() end
end

local terrain = Workspace.Terrain
local level   = Instance.new("Model")
level.Name    = "TutorialLevel"
level.Parent  = Workspace

local G = 4  -- terrain top Y (FillBlock centre Y=0, height=8)

-- ── Helpers ──────────────────────────────────────────────────────────

local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored     = true
	p.CanCollide   = props.CanCollide ~= false
	p.CastShadow   = props.CastShadow ~= false
	p.Size         = props.Size   or Vector3.new(4,4,4)
	p.CFrame       = props.CFrame or CFrame.new(0,0,0)
	p.Material     = props.Material or Enum.Material.SmoothPlastic
	p.Color        = props.Color  or Color3.fromRGB(200,200,200)
	p.Transparency = props.Transparency or 0
	p.Name         = props.Name   or "Part"
	p.Parent       = props.Parent or level
	return p
end

local function surfaceSign(part, face, text, col)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face or Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50; sg.Parent = part
	local lbl = Instance.new("TextLabel", sg)
	lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
	lbl.Text = text; lbl.TextColor3 = col or Color3.fromRGB(255,228,118)
	lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold
end

-- Hill — sphere centre sunk to Y = G - r*0.58 so ~65% pokes above ground
-- Inner terrain-effect edge ≈ centre_pos ± r  (below-ground at that exact point)
local function hill(x, z, r, mat)
	terrain:FillBall(Vector3.new(x, G - r*0.58, z), r, mat or Enum.Material.Grass)
end

-- Fishing pond: sand rim → air carve → water Part (Material.Water for FishingServer)
local function makePond(cx, cz, pw, pd, partName)
	terrain:FillBlock(CFrame.new(cx, G-0.2, cz), Vector3.new(pw+18, 0.5, pd+18), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(cx, G-3,   cz), Vector3.new(pw+2,  10,  pd+2),  Enum.Material.Air)
	return makePart({
		Name = partName or "Water", Size = Vector3.new(pw,1,pd),
		CFrame = CFrame.new(cx, G-1.2, cz),
		Material = Enum.Material.Water, Color = Color3.fromRGB(28,90,200),
		Transparency = 0.35, CanCollide = false, CastShadow = false,
	})
end

-- Deco pond (name "PondDeco" → FishingServer won't attach prompt)
local function decoPond(cx, cz, pw, pd)
	terrain:FillBlock(CFrame.new(cx, G-0.2, cz), Vector3.new(pw+14, 0.5, pd+14), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(cx, G-3,   cz), Vector3.new(pw+2,  10,  pd+2),  Enum.Material.Air)
	makePart({ Name="PondDeco", Size=Vector3.new(pw,0.8,pd),
		CFrame=CFrame.new(cx,G-1.2,cz), Material=Enum.Material.SmoothPlastic,
		Color=Color3.fromRGB(30,80,170), Transparency=0.55,
		CanCollide=false, CastShadow=false })
end

local function sideSign(x, z, rotY, text, col)
	makePart({ Name="SignStake", Size=Vector3.new(0.38,3.4,0.38),
		CFrame=CFrame.new(x,G+1.7,z),
		Material=Enum.Material.Wood, Color=Color3.fromRGB(108,68,28) })
	local b = makePart({ Name="SignBoard", Size=Vector3.new(4.8,2.0,0.32),
		CFrame=CFrame.new(x,G+4.2,z)*CFrame.Angles(0,rotY,0),
		Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(42,20,5), CanCollide=false })
	surfaceSign(b,Enum.NormalId.Front,text,col or Color3.fromRGB(255,225,100))
	surfaceSign(b,Enum.NormalId.Back, text,col or Color3.fromRGB(255,225,100))
end

-- Tree root at G+1 so trunk never sinks (terrain may be slightly raised near hills)
local function tree(x, z, tr, th, cr)
	makePart({ Name="TreeTrunk", Size=Vector3.new(tr,th,tr),
		CFrame=CFrame.new(x,G+1+th*.5,z),
		Material=Enum.Material.Wood, Color=Color3.fromRGB(75,44,12) })
	local c1=Instance.new("Part"); c1.Name="Canopy"; c1.Shape=Enum.PartType.Ball
	c1.Size=Vector3.new(cr,cr*.84,cr); c1.Anchored=true; c1.CanCollide=false
	c1.CFrame=CFrame.new(x,G+1+th+cr*.36,z)
	c1.Material=Enum.Material.Grass; c1.Color=Color3.fromRGB(44,120,34); c1.Parent=level
	local c2=Instance.new("Part"); c2.Name="CanopyTop"; c2.Shape=Enum.PartType.Ball
	c2.Size=Vector3.new(cr*.62,cr*.57,cr*.62); c2.Anchored=true; c2.CanCollide=false
	c2.CFrame=CFrame.new(x,G+1+th+cr*.75,z)
	c2.Material=Enum.Material.Grass; c2.Color=Color3.fromRGB(34,102,26); c2.Parent=level
end

local function rock(x, z, sx, sy, sz)
	makePart({ Name="Rock", Size=Vector3.new(sx,sy,sz or sx),
		CFrame=CFrame.new(x,G+sy*.5-.3,z),
		Material=Enum.Material.Slate, Color=Color3.fromRGB(102,104,112) })
end

local function barrel(x, z)
	makePart({ Name="Barrel", Size=Vector3.new(2,2.5,2), CFrame=CFrame.new(x,G+1.25,z),
		Material=Enum.Material.WoodPlanks, Color=Color3.fromRGB(118,74,34) })
end

local function lantern(x, z)
	makePart({ Name="LanternPost", Size=Vector3.new(0.5,8,0.5), CFrame=CFrame.new(x,G+4,z),
		Material=Enum.Material.Metal, Color=Color3.fromRGB(48,50,54) })
	makePart({ Name="LanternHead", Size=Vector3.new(1.3,1.3,1.3), CFrame=CFrame.new(x,G+8.3,z),
		Material=Enum.Material.Neon, Color=Color3.fromRGB(255,218,115) })
end

local function pathZ(xOff, z0, z1, step)
	for pz=z0,z1,step do
		makePart({ Name="PathStone", Size=Vector3.new(7,0.25,6),
			CFrame=CFrame.new(xOff,G+0.13,pz),
			Material=Enum.Material.Cobblestone, Color=Color3.fromRGB(102,102,108) })
	end
end
local function pathX(zOff, x0, x1, step)
	for px=x0,x1,step do
		makePart({ Name="PathStone", Size=Vector3.new(6,0.25,7),
			CFrame=CFrame.new(px,G+0.13,zOff),
			Material=Enum.Material.Cobblestone, Color=Color3.fromRGB(102,102,108) })
	end
end

local function cottage(cx,cz,w,d,wh,roofCol,wallCol)
	makePart({ Name="CottageFloor", Size=Vector3.new(w,.55,d),
		CFrame=CFrame.new(cx,G+.28,cz), Material=Enum.Material.WoodPlanks,
		Color=Color3.fromRGB(100,62,24) })
	for _,wl in ipairs({
		{sz=Vector3.new(w,  wh,.5), cf=CFrame.new(cx,    G+wh*.5+.5,cz-d*.5)},
		{sz=Vector3.new(w,  wh,.5), cf=CFrame.new(cx,    G+wh*.5+.5,cz+d*.5)},
		{sz=Vector3.new(.5, wh,d),  cf=CFrame.new(cx-w*.5,G+wh*.5+.5,cz)},
		{sz=Vector3.new(.5, wh,d),  cf=CFrame.new(cx+w*.5,G+wh*.5+.5,cz)},
	}) do
		makePart({ Name="CottageWall", Size=wl.sz, CFrame=wl.cf,
			Material=Enum.Material.WoodPlanks, Color=wallCol or Color3.fromRGB(80,50,20) })
	end
	makePart({ Name="CottageRoof", Size=Vector3.new(w+2.6,.65,d+2.6),
		CFrame=CFrame.new(cx,G+wh+1.0,cz),
		Material=Enum.Material.Slate, Color=roofCol or Color3.fromRGB(38,40,48) })
end

-- ═══════════════════════════════════════════════════════════════
--  BASE TERRAIN — enormous slabs
-- ═══════════════════════════════════════════════════════════════
terrain:FillBlock(CFrame.new(0,0,-25),    Vector3.new(800,8,450), Enum.Material.Grass)
terrain:FillBlock(CFrame.new(-200,0,100), Vector3.new(500,8,300), Enum.Material.Grass)

-- ═══════════════════════════════════════════════════════════════
--  CORRIDOR SIDE HILLS — mathematically safe from path
--
--  Seg1 walls: X=±62, r=22
--    centre Y = G - 22*0.58 = 4 - 12.76 = -8.76
--    At X=40 (d=22): sphere surface Y=-8.76 → below ground → NO terrain effect
--    Terrain only raised at X=42+ (visible hill, clear of feature zone ±30) ✓
--
--  Seg2 walls: Z=45, r=22  → inner edge Z=67  (clear zone Z=80+) ✓
--              Z=155, r=22 → inner edge Z=133 (clear zone Z=100) ✓
-- ═══════════════════════════════════════════════════════════════

-- Seg1 east wall (X=+62, Z=-120 to +80, every 30 studs)
for z=-120,80,30 do hill( 62,z,22,Enum.Material.Grass) end
-- Seg1 west wall (X=-62)
for z=-120,80,30 do hill(-62,z,22,Enum.Material.Grass) end
-- Double layer for depth
for z=-105,65,30 do
	hill( 76,z,18,Enum.Material.Grass)
	hill(-76,z,18,Enum.Material.Grass)
end

-- Seg2 north wall (Z=45, X=-30 to -340)
for x=-30,-340,-32 do hill(x,45,22,Enum.Material.Grass) end
for x=-46,-340,-32 do hill(x,32,18,Enum.Material.Grass) end
-- Seg2 south wall (Z=155, X=-30 to -340)
for x=-30,-340,-32 do hill(x,155,22,Enum.Material.Grass) end
for x=-46,-340,-32 do hill(x,168,18,Enum.Material.Grass) end

-- ═══════════════════════════════════════════════════════════════
--  OUTER MOUNTAIN RING (150+ studs from path — scenic background)
-- ═══════════════════════════════════════════════════════════════

-- North cap (Z=-210)
for _,c in ipairs({
	{-100,-210,52},{-50,-215,50},{0,-208,50},{50,-213,52},{100,-208,50},{140,-213,48},
	{-75,-200,32},{10,-202,34},{60,-198,30},
	{-20,-216,26,Enum.Material.Rock},{42,-218,24,Enum.Material.Rock},
}) do hill(c[1],c[2],c[3],c[4]) end

-- East wall Seg1 (X=+220, Z=-210 to +80)
for z=-210,80,36 do hill(220,z,52,Enum.Material.Grass) end

-- West wall Seg1 (X=-220, Z=-210 to +80)
for z=-210,80,36 do hill(-220,z,52,Enum.Material.Grass) end

-- Seg1 forward blocker (Z=178, only X=-10 to +10 — MUST NOT affect Seg2 Z=100)
-- r=36: inner edge Z=178-36=142. Seg2 Z=100: gap=42 ✓
for _,c in ipairs({
	{0,178,36},{-14,182,30},{14,182,30},
	{-5,188,22,Enum.Material.Rock},{6,186,20,Enum.Material.Rock},
}) do hill(c[1],c[2],c[3],c[4]) end

-- Seg2 east corner (where Seg1/Seg2 meet, X=0 to -30, Z=100)
-- Blocker on right (+Z side of entrance from Seg1):
hill(14,110,26,Enum.Material.Grass); hill(24,108,22,Enum.Material.Rock)
hill(10,118,24,Enum.Material.Grass); hill(22,116,20,Enum.Material.Rock)
hill(32,106,20,Enum.Material.Rock)

-- Seg2 north outer (Z=-80, X=-30 to -380 — 180 studs from Z=100)
for x=-50,-380,-44 do hill(x,-80,48,Enum.Material.Grass) end

-- Seg2 south outer (Z=280, X=-30 to -380)
for x=-50,-380,-44 do hill(x,280,48,Enum.Material.Grass) end

-- West cap Seg2 (behind portal, X=-405)
for _,c in ipairs({
	{-408,70,50},{-408,100,54},{-408,130,50},
	{-422,84,38},{-422,100,40},{-422,116,38},
	{-400,90,26,Enum.Material.Rock},{-402,108,22,Enum.Material.Rock},
}) do hill(c[1],c[2],c[3],c[4]) end

-- ═══════════════════════════════════════════════════════════════
--  SEGMENT 1  —  SPAWN → ARCH → GUIDE → POND → TURN
-- ═══════════════════════════════════════════════════════════════

local sp = Instance.new("SpawnLocation")
sp.Name="TutorialSpawn"; sp.Size=Vector3.new(8,1,8)
sp.CFrame = CFrame.new(0,G+0.5,-120)*CFrame.Angles(0,math.pi,0)
sp.Anchored=true; sp.Material=Enum.Material.WoodPlanks
sp.BrickColor=BrickColor.new("Bright yellow"); sp.Neutral=true; sp.Duration=0
sp.Parent=level

pathZ(0, -112, 80, 13)

-- Welcome arch
for _,px in ipairs({-10,10}) do
	makePart({ Name="ArchPost", Size=Vector3.new(1.4,13,1.4),
		CFrame=CFrame.new(px,G+7.5,-70),
		Material=Enum.Material.Wood, Color=Color3.fromRGB(88,54,18) })
end
makePart({ Name="ArchBeam", Size=Vector3.new(23,1.6,1.4),
	CFrame=CFrame.new(0,G+14.2,-70),
	Material=Enum.Material.Wood, Color=Color3.fromRGB(88,54,18) })
local banner=makePart({ Name="WelcomeBanner", Size=Vector3.new(17,3.4,.4),
	CFrame=CFrame.new(0,G+10.8,-70), CanCollide=false,
	Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(44,21,6) })
surfaceSign(banner,Enum.NormalId.Front,"Welcome to RoFish!",Color3.fromRGB(255,228,118))
surfaceSign(banner,Enum.NormalId.Back, "Welcome to RoFish!",Color3.fromRGB(255,228,118))

sideSign(28,-60,0,"Press E at water to fish!",Color3.fromRGB(175,238,255))

cottage(-44,-55,11,9,6,Color3.fromRGB(50,28,12),Color3.fromRGB(78,50,20))
barrel(-37,-45); barrel(-50,-45)
rock(-48,-48,3.0,2.0,2.5); rock(-56,-44,2.2,1.5,1.9)
lantern(-40,-38)

-- ── FISHING POND (centre 0,0; 60×50) ──────────────────────────
-- Air cavity: X ±31, Z ±26.  Dock centre Z=-44 (south shore, 18 studs clear of cavity ✓)
makePond(0, 0, 60, 50, "LakeWater")
sideSign(28,-18,0,"Fishing Pond",Color3.fromRGB(155,222,255))

makePart({ Name="DockPlatform", Size=Vector3.new(12,.5,12),
	CFrame=CFrame.new(0,G+.25,-44),
	Material=Enum.Material.WoodPlanks, Color=Color3.fromRGB(112,70,28) })
makePart({ Name="DockRailL",    Size=Vector3.new(.32,1.1,12), CFrame=CFrame.new(-7,G+1.06,-44),
	Material=Enum.Material.Wood, Color=Color3.fromRGB(100,60,20) })
makePart({ Name="DockRailR",    Size=Vector3.new(.32,1.1,12), CFrame=CFrame.new( 7,G+1.06,-44),
	Material=Enum.Material.Wood, Color=Color3.fromRGB(100,60,20) })
makePart({ Name="DockRailBack", Size=Vector3.new(12,1.1,.32), CFrame=CFrame.new(0,G+1.06,-50),
	Material=Enum.Material.Wood, Color=Color3.fromRGB(100,60,20) })

for pz=-50,58,13 do
	makePart({ Name="PathWalkL", Size=Vector3.new(6,.25,6), CFrame=CFrame.new(-42,G+0.13,pz),
		Material=Enum.Material.Cobblestone, Color=Color3.fromRGB(102,102,108) })
	makePart({ Name="PathWalkR", Size=Vector3.new(6,.25,6), CFrame=CFrame.new( 42,G+0.13,pz),
		Material=Enum.Material.Cobblestone, Color=Color3.fromRGB(102,102,108) })
end

cottage(56,48,10,9,6,Color3.fromRGB(44,26,10),Color3.fromRGB(72,46,18))
rock(62,54,2.8,1.9,2.4); rock(72,54,2.0,1.4,1.7); barrel(62,42)

-- Deco ponds far from main pond and Seg2 path
-- deco1: (-70,-90), D from main pond SW corner (-30,-25) = sqrt(40²+65²)=76 ✓
decoPond(-70,-90,18,16)
-- deco2: (68,62), D from main pond NE corner (30,25) = sqrt(38²+37²)=53 ✓
decoPond(68,62,14,14)

-- ═══════════════════════════════════════════════════════════════
--  TURN ZONE  (Z=80 → X=-30 at Z=100)
-- ═══════════════════════════════════════════════════════════════

sideSign(-28,82,0,"← Lodge",Color3.fromRGB(255,218,80))

for pz=82,100,9 do
	makePart({ Name="CornerPath", Size=Vector3.new(7,.25,6),
		CFrame=CFrame.new(0,G+0.13,pz),
		Material=Enum.Material.Cobblestone, Color=Color3.fromRGB(102,102,108) })
end
for cx=-8,-36,-9 do
	makePart({ Name="CornerPath", Size=Vector3.new(6,.25,7),
		CFrame=CFrame.new(cx,G+0.13,100),
		Material=Enum.Material.Cobblestone, Color=Color3.fromRGB(102,102,108) })
end

-- ═══════════════════════════════════════════════════════════════
--  SEGMENT 2  —  Z=100, walking in -X direction
-- ═══════════════════════════════════════════════════════════════

pathX(100, -42, -320, -13)

-- ── FISHING LODGE (X=-110, Z=100) ───────────────────────────────
local CX,CZ = -110,100
makePart({ Name="CabinFloor", Size=Vector3.new(28,.6,22), CFrame=CFrame.new(CX,G+.3,CZ),
	Material=Enum.Material.WoodPlanks, Color=Color3.fromRGB(108,68,28) })
for _,w in ipairs({
	{sz=Vector3.new(28,13,.6), cf=CFrame.new(CX,   G+7,CZ-11)},
	{sz=Vector3.new(28,13,.6), cf=CFrame.new(CX,   G+7,CZ+11)},
	{sz=Vector3.new(.6,13,22), cf=CFrame.new(CX-14,G+7,CZ)},
	{sz=Vector3.new(.6,13,22), cf=CFrame.new(CX+14,G+7,CZ)},
}) do
	makePart({ Name="CabinWall", Size=w.sz, CFrame=w.cf,
		Material=Enum.Material.WoodPlanks, Color=Color3.fromRGB(82,52,20) })
end
makePart({ Name="CabinRoof", Size=Vector3.new(32,.8,26), CFrame=CFrame.new(CX,G+14,CZ),
	Material=Enum.Material.Slate, Color=Color3.fromRGB(36,38,44) })
makePart({ Name="Chimney",   Size=Vector3.new(2.6,8,2.6), CFrame=CFrame.new(CX-6,G+17,CZ-4),
	Material=Enum.Material.Brick, Color=Color3.fromRGB(132,66,46) })
makePart({ Name="LodgeDoor", Size=Vector3.new(3.6,7.2,.26), CFrame=CFrame.new(CX+14.1,G+4,CZ),
	Material=Enum.Material.Wood, Color=Color3.fromRGB(50,28,10) })
local cSign=makePart({ Name="LodgeSign", Size=Vector3.new(14,2.6,.4),
	CFrame=CFrame.new(CX+14.3,G+12.5,CZ)*CFrame.Angles(0,-math.pi*.5,0),
	Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(40,18,4), CanCollide=false })
surfaceSign(cSign,Enum.NormalId.Front,"Fishing Lodge",Color3.fromRGB(255,208,75))

barrel(CX+9,CZ+13); barrel(CX-9,CZ+13)
makePart({ Name="Bench",    Size=Vector3.new(5.5,.42,1.5), CFrame=CFrame.new(CX,G+1.22,CZ+13),
	Material=Enum.Material.WoodPlanks, Color=Color3.fromRGB(110,72,30) })
for _,bx in ipairs({CX-2.5,CX+2.5}) do
	makePart({ Name="BenchLeg", Size=Vector3.new(.42,1.22,1.5),
		CFrame=CFrame.new(bx,G+.72,CZ+13), Material=Enum.Material.Wood, Color=Color3.fromRGB(94,58,22) })
end
rock(CX-16,CZ-14,2.8,1.9,2.4); rock(CX+16,CZ-14,2.2,1.5,1.9)

cottage(CX,CZ+24,10,9,6,Color3.fromRGB(44,26,10),Color3.fromRGB(70,46,18))
lantern(CX-12,CZ+18); rock(CX-10,CZ+20,2.6,1.8,2.2); rock(CX+10,CZ+20,2.0,1.4,1.7)

-- Deco pond south of lodge: centre (-128,140), D from BaitPond (-215,100)=sqrt(87²+40²)=96 ✓
decoPond(-128,140,20,16)

-- ── BAIT POND (X=-215, Z=100; 42×34) ─────────────────────────────
-- Air cavity: X -236 to -194, Z 83 to 117
makePond(-215,100,42,34,"BaitWater")
sideSign(-215,78,-math.pi*.5,"Try your new bait here!",Color3.fromRGB(175,255,175))
-- Dock on east shore, X=-193 centre (air cavity east edge X=-194; dock spans X=-197 to -189 ✓)
makePart({ Name="BaitDock",  Size=Vector3.new(8,.48,12), CFrame=CFrame.new(-193,G+.24,100),
	Material=Enum.Material.WoodPlanks, Color=Color3.fromRGB(110,70,28) })
makePart({ Name="BaitRailN", Size=Vector3.new(.3,1,12),  CFrame=CFrame.new(-189,G+1.12,100),
	Material=Enum.Material.Wood, Color=Color3.fromRGB(100,60,20) })

-- Deco pond before navigator: centre (-300,120), D from bait pond=sqrt(85²+20²)=87 ✓
decoPond(-300,120,16,14)

-- ── NAVIGATOR + PORTAL (X=-335, Z=100) ───────────────────────────
local AX,AZ=-335,100
local glow=Color3.fromRGB(65,255,165)
makePart({ Name="PortalPillarL", Size=Vector3.new(2.4,16,2.4), CFrame=CFrame.new(AX-5,G+8,AZ),  Material=Enum.Material.Neon, Color=glow })
makePart({ Name="PortalPillarR", Size=Vector3.new(2.4,16,2.4), CFrame=CFrame.new(AX+5,G+8,AZ),  Material=Enum.Material.Neon, Color=glow })
makePart({ Name="PortalArchTop", Size=Vector3.new(12,2.4,2.4), CFrame=CFrame.new(AX,G+16.8,AZ), Material=Enum.Material.Neon, Color=glow })
makePart({ Name="PortalFloor",   Size=Vector3.new(9,.3,9),     CFrame=CFrame.new(AX,G+.15,AZ),  Material=Enum.Material.Neon, Color=glow, Transparency=0.4 })
local pSgn=makePart({ Name="PortalSign", Size=Vector3.new(9,2.4,.4),
	CFrame=CFrame.new(AX,G+13.8,AZ+1.5),
	Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(8,14,24), CanCollide=false })
surfaceSign(pSgn,Enum.NormalId.Front,"Main World",Color3.fromRGB(140,255,175))

-- ═══════════════════════════════════════════════════════════════
--  NPCs  (MaxDistance=36 — labels only visible up close)
-- ═══════════════════════════════════════════════════════════════

local function makeNPC(modelName,basePos,torsoColor,label,labelColor)
	local model=Instance.new("Model"); model.Name=modelName; model.Parent=level
	for _,lx in ipairs({-.55,.55}) do
		makePart({ Name="Leg", Size=Vector3.new(.9,1.7,.9),
			CFrame=CFrame.new(basePos+Vector3.new(lx,.85,0)),
			Material=Enum.Material.SmoothPlastic, Color=Color3.fromRGB(40,42,115), Parent=model })
	end
	local torso=makePart({ Name="Torso", Size=Vector3.new(2.2,2.6,1.1),
		CFrame=CFrame.new(basePos+Vector3.new(0,2.45,0)),
		Material=Enum.Material.SmoothPlastic, Color=torsoColor, Parent=model })
	local head=Instance.new("Part"); head.Name="Head"; head.Shape=Enum.PartType.Ball
	head.Size=Vector3.new(1.6,1.6,1.6); head.Anchored=true; head.CanCollide=false
	head.CFrame=CFrame.new(basePos+Vector3.new(0,4.45,0))
	head.Material=Enum.Material.SmoothPlastic; head.Color=Color3.fromRGB(255,205,165)
	head.Parent=model; model.PrimaryPart=torso
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,190,0,44)
	bb.StudsOffset=Vector3.new(0,2.4,0); bb.AlwaysOnTop=false; bb.MaxDistance=36; bb.Parent=head
	local lbl=Instance.new("TextLabel",bb); lbl.Size=UDim2.new(1,0,1,0)
	lbl.BackgroundColor3=Color3.fromRGB(0,0,0); lbl.BackgroundTransparency=0.38
	lbl.Text=label; lbl.TextColor3=labelColor or Color3.fromRGB(255,255,255)
	lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold
	Instance.new("UICorner",lbl).CornerRadius=UDim.new(0,6)
	return model
end

makeNPC("GuideNPC",        Vector3.new(28,G,-52),    Color3.fromRGB(48,128,215), "Guide",     Color3.fromRGB(120,215,255))
makeNPC("TutorialShopNPC", Vector3.new(CX+18,G,CZ),  Color3.fromRGB(215,155,35), "Shop",      Color3.fromRGB(255,222,88))
makeNPC("NavigatorNPC",    Vector3.new(AX+18,G,AZ),  Color3.fromRGB(55,190,108), "Navigator", Color3.fromRGB(140,255,172))

-- ═══════════════════════════════════════════════════════════════
--  TREES
--  Seg1:  X=±36 inner row  (terrain flat here — hills start X=40+) ✓
--         X=±52 outer row
--  Seg2:  Z=68 north row   (hill inner edge Z=67, terrain flat at Z=68) ✓
--         Z=132 south row  (hill inner edge Z=133, terrain flat at Z=132) ✓
-- ═══════════════════════════════════════════════════════════════

-- Seg1 inner tree rows (dense, every 20 studs for visual wall)
for z=-120,80,20 do
	tree( 36,z,2.0,12,11)
	tree(-36,z,2.0,12,11)
end
-- Seg1 outer tree rows (every 36 studs for depth)
for z=-108,68,36 do
	tree( 52,z,2.4,14,13)
	tree(-52,z,2.4,14,13)
end
-- Near right lakeside cottage
tree(62,58,2.2,13,12)
-- Near left starter cottage
tree(-56,-62,2.2,13,12)

-- Seg2 north tree row (Z=68, every 36 studs)
for x=-44,-344,-36 do tree(x,68,2.4,14,13) end
-- Seg2 south tree row (Z=132, every 36 studs)
for x=-44,-344,-36 do tree(x,132,2.4,14,13) end
-- Seg2 outer north (Z=54)
for x=-62,-344,-44 do tree(x,54,2.0,12,11) end
-- Seg2 outer south (Z=146)
for x=-62,-344,-44 do tree(x,146,2.0,12,11) end

-- ═══════════════════════════════════════════════════════════════
--  ACCENT ROCKS (all ≥36 studs from any pond edge)
-- ═══════════════════════════════════════════════════════════════
for _,r in ipairs({
	{-54,-108,3.0,2.0,2.6},{ 54,-108,2.6,1.8,2.2},
	{-54, -55,2.8,1.9,2.4},{ 54,  -55,2.2,1.5,1.9},
	{ 54,  62,3.0,2.0,2.6},{-54,   62,2.4,1.6,2.0},
	{-55, 70,2.8,1.9,2.4},{-55,130,2.6,1.8,2.2},
	{-168,70,3.0,2.0,2.5},{-168,130,2.6,1.8,2.2},
	{-278,70,2.8,1.9,2.4},{-278,130,2.4,1.6,2.0},
}) do rock(r[1],r[2],r[4],r[5],r[6] or r[4]) end

print("[TutorialLevelBuilder] Tutorial world built successfully.")
