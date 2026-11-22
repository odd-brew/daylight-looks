-- Looks (DaylightUI Plugin). Frame styles and glow styles for Daylight UI.
-- A click applies the current pick. There is no public setter, so Looks uses
-- the same writes Daylight's own menus use, and falls back to a menu line
-- when those are missing. It never changes a palette or the accent.

local PAGE = "Add frame styles and glow styles to Daylight. Colors stay in Palettes for DaylightUI, or in Daylight if Palettes for DaylightUI is off."
local TOO_OLD = "Looks: Daylight UI is missing the settings Looks needs, so no frame or glow styles were added."
local GLOW_HINT = "Glow colour follows your accent colour. Change it in Daylight's accent setting, or with Palettes for DaylightUI."

-- Player, target and focus share a style's heights. Party keeps Daylight's own.
local function unitSizes(spec)
    local frames = { "player", "target", "focus" }
    local sizes = {}
    for i = 1, #frames do sizes[frames[i]] = spec end
    return sizes
end

-- Shares of the way round, clockwise from the top-left corner.
local CORNER = { 0, 0.25, 0.5, 0.75 }

local function wave(at)
    return 0.5 - 0.5 * math.cos(at * math.pi * 2)
end

local function lightSize(size)
    if type(size) == "number" and size > 0 then return size end
    return 8
end

-- Four pools that wax and wane. They stay on the corners.
local function drawWick(g, at, lo, hi, size)
    local s = lightSize(size) * (0.55 + 0.5 * wave(at))
    local alpha = 0.35 + 0.65 * wave(at)
    for i = 1, 4 do
        local color = (i % 2 == 1) and lo or hi
        g:Light(CORNER[i], s, color, alpha)
        g:Trail(CORNER[i], 0.045, alpha * 0.45, lo, hi)
    end
end

-- A band along the top edge. It does not travel the other three sides.
local function drawDraught(g, at, lo, hi)
    local span = 0.62
    local from = (1 - span) * wave(at)
    g:Edge(1, 0, 1, 0.16, 0.16, lo, hi)
    g:Edge(1, from, from + span, 0.2, 0.9, lo, hi)
end

-- A short catch around the edge, then nothing for the rest of the lap.
local function drawLatch(g, at, lo, hi, size)
    if at >= 0.42 then return end
    local alpha
    if at < 0.16 then
        alpha = 0.45 + 0.55 * (at / 0.16)
    else
        alpha = 1 - (at - 0.16) / (0.42 - 0.16)
    end
    g:Edge(1, 0, 1, alpha * 0.45, alpha, lo, hi)
    g:Edge(2, 0, 1, alpha, alpha * 0.3, hi, lo)
    g:Edge(3, 0, 1, alpha * 0.3, alpha * 0.55, lo, hi)
    g:Edge(4, 0, 1, alpha * 0.55, alpha * 0.4, hi, lo)
    g:Light(0, lightSize(size) * 0.7, hi, alpha)
    g:Trail(0.02, 0.08, alpha * 0.5, lo, hi)
end

local FRAMES = {
    {
        id = "lintel",
        name = "Lintel",
        spec = {
            label = "Lintel",
            desc = "A named beam over a solid bar.",
            row = true,
        },
    },
    {
        id = "sill",
        name = "Sill",
        spec = {
            label = "Sill",
            desc = "The name tab stays; power sits as a thin sill under the bar.",
            line = true,
        },
    },
    {
        id = "stamp",
        name = "Stamp",
        spec = {
            label = "Stamp",
            desc = "A tight name row and a thin power line, ring kept small.",
            row = true,
            line = true,
            ring = 0.35,
        },
    },
    {
        id = "trestle",
        name = "Trestle",
        spec = {
            label = "Trestle",
            desc = "A full portrait on a named board, power hung as a rail.",
            row = true,
            line = true,
        },
    },
    {
        id = "flagon",
        name = "Flagon",
        spec = {
            label = "Flagon",
            desc = "A small boss and a deep cup, the name cut into the lip.",
            row = true,
            ring = 0.35,
            sizes = unitSizes({ height = 32 }),
        },
    },
    {
        id = "signboard",
        name = "Signboard",
        spec = {
            label = "Signboard",
            desc = "A hanging boss on a tall board, with a hairline rail along the bottom.",
            row = true,
            ring = 1,
            sizes = unitSizes({ height = 10, tabHeight = 28 }),
        },
    },
    {
        id = "trough",
        name = "Trough",
        spec = {
            label = "Trough",
            desc = "A full boss, a thin health lip, and power carried in a deep trough underneath.",
            line = true,
            ring = 1,
            sizes = unitSizes({ height = 11, powerHeight = 14 }),
        },
    },
}

local GLOWS = {
    {
        id = "wick",
        name = "Wick",
        mood = "A quiet flame gathers at the corners.",
        spec = { label = "Wick", lap = 2, draw = drawWick },
    },
    {
        id = "draught",
        name = "Draught",
        mood = "A soft wash along the rim.",
        spec = { label = "Draught", lap = 2, draw = drawDraught },
    },
    {
        id = "latch",
        name = "Latch",
        mood = "A short catch of light, then still.",
        spec = { label = "Latch", lap = 2, draw = drawLatch },
    },
}

local PRESETS = {
    {
        id = "hearthnight",
        name = "Hearthnight",
        frame = "lintel",
        glow = "wick",
        mood = "A winter hearth: a named beam, a quiet corner flame. Sits well with Palettes for DaylightUI — Ember.",
    },
    {
        id = "harvestide",
        name = "Harvestide",
        frame = "sill",
        glow = "draught",
        mood = "Harvest light along the sill of the bar. Sits well with Palettes for DaylightUI — Vanilla.",
    },
    {
        id = "tidemark",
        name = "Tidemark",
        frame = "stamp",
        glow = "draught",
        mood = "A tight line at the waterline, a soft wash along the rim. Sits well with Palettes for DaylightUI — Tide.",
    },
    {
        id = "oldroad",
        name = "Old Road",
        frame = "lintel",
        glow = "latch",
        mood = "A weathered beam and a short catch of lantern light. Sits well with Palettes for DaylightUI — Forever.",
    },
    {
        id = "vigil",
        name = "Vigil",
        frame = "sill",
        glow = "wick",
        mood = "The name tab stays, and a flame is kept lit at the corners. Sits well with Palettes for DaylightUI — Paladin.",
    },
}

-- Small schematic icons, drawn with flat colour blocks. No game art.
-- Each part is x, y, w, h and a colour, inside a 36 by 18 box.
local BOSS = { 0.72, 0.58, 0.32, 1 }
local NAME = { 0.82, 0.76, 0.66, 1 }
local HEALTH = { 0.55, 0.62, 0.38, 1 }
local POWER = { 0.28, 0.48, 0.72, 1 }
local GLOW = { 0.86, 0.78, 0.62, 1 }

local function block(x, y, w, h, color)
    return { x, y, w, h, color[1], color[2], color[3], color[4] }
end

local ICONS = {
    lintel = {
        block(1, 5, 8, 8, BOSS),
        block(11, 2, 23, 4, NAME),
        block(11, 8, 23, 8, HEALTH),
    },
    sill = {
        block(1, 3, 8, 8, BOSS),
        block(11, 2, 14, 4, NAME),
        block(11, 8, 23, 6, HEALTH),
        block(11, 15, 23, 2, POWER),
    },
    stamp = {
        block(1, 6, 6, 6, BOSS),
        block(9, 2, 25, 3, NAME),
        block(9, 7, 25, 4, HEALTH),
        block(9, 13, 25, 2, POWER),
    },
    trestle = {
        block(1, 2, 12, 12, BOSS),
        block(15, 2, 19, 4, NAME),
        block(15, 8, 19, 5, HEALTH),
        block(15, 15, 19, 2, POWER),
    },
    flagon = {
        block(1, 4, 7, 7, BOSS),
        block(10, 1, 24, 3, NAME),
        block(10, 5, 24, 12, HEALTH),
    },
    signboard = {
        block(1, 1, 12, 12, BOSS),
        block(15, 1, 19, 11, NAME),
        block(15, 14, 19, 2, HEALTH),
    },
    trough = {
        block(1, 2, 12, 12, BOSS),
        block(15, 3, 19, 3, HEALTH),
        block(15, 8, 19, 8, POWER),
    },
    wick = {
        block(2, 2, 4, 4, GLOW),
        block(30, 2, 4, 4, GLOW),
        block(2, 12, 4, 4, GLOW),
        block(30, 12, 4, 4, GLOW),
    },
    draught = {
        block(2, 2, 32, 4, GLOW),
    },
    latch = {
        block(2, 2, 3, 14, GLOW),
        block(2, 2, 12, 3, GLOW),
    },
}

local ORDER = {}
for i = 1, #FRAMES do ORDER[#ORDER + 1] = FRAMES[i] end
for i = 1, #GLOWS do ORDER[#ORDER + 1] = GLOWS[i] end
for i = 1, #PRESETS do ORDER[#ORDER + 1] = PRESETS[i] end

-- Read-only. Main-button glow, then the target nameplate outline.
-- A Cooldown Manager spell keeps its own pick, so it is not one status line.
local GLOW_READS = {
    { "general", "buttonGlow" },
    { "Nameplates", "targetLight" },
}

local ready = false
local view
local refused

local function say(text)
    local frame = DEFAULT_CHAT_FRAME
    if type(frame) == "table" and type(frame.AddMessage) == "function" then
        frame:AddMessage(text)
    elseif type(print) == "function" then
        print(text)
    end
end

local function trim(text)
    if type(text) ~= "string" then return "" end
    return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

local function frameById(id)
    for i = 1, #FRAMES do
        if FRAMES[i].id == id then return FRAMES[i] end
    end
end

local function glowById(id)
    for i = 1, #GLOWS do
        if GLOWS[i].id == id then return GLOWS[i] end
    end
end

local function presetById(id)
    for i = 1, #PRESETS do
        if PRESETS[i].id == id then return PRESETS[i] end
    end
end

local function joinOr(list)
    if #list == 0 then return "" end
    if #list == 1 then return list[1] end
    local head = {}
    for i = 1, #list - 1 do head[i] = list[i] end
    return table.concat(head, ", ") .. ", or " .. list[#list]
end

local function looksId(key)
    local prefix = "Looks:"
    if type(key) ~= "string" or string.sub(key, 1, #prefix) ~= prefix then return nil end
    return string.sub(key, #prefix + 1)
end

local function apiOf()
    local d = DaylightUI
    local api = type(d) == "table" and d.API
    if type(api) == "table" then return api end
end

-- The player frame's style, through the public parts table.
-- "player" in a raid is the raid tile, which Daylight keeps on its own style.
local function wornFrame()
    local api = apiOf()
    if not api or type(api.GetUnitFrame) ~= "function" or type(api.Parts) ~= "function" then
        return nil
    end
    local ok, frame = pcall(api.GetUnitFrame, "player")
    if not ok or type(frame) ~= "table" then return nil end
    local okParts, parts = pcall(api.Parts, frame)
    if not okParts or type(parts) ~= "table" then return nil end
    local found = frameById(looksId(parts.style))
    if found then return found.id, found.name end
end

local function wornGlows()
    local api = apiOf()
    local out, seen = {}, {}
    if not api or type(api.GetSetting) ~= "function" then return out end
    for i = 1, #GLOW_READS do
        local ok, value = pcall(api.GetSetting, GLOW_READS[i][1], GLOW_READS[i][2])
        local found = ok and glowById(looksId(value))
        if found and not seen[found.id] then
            seen[found.id] = true
            out[#out + 1] = found
        end
    end
    return out
end

local function hintLine(name, omit)
    local names = {}
    for i = 1, #ORDER do
        if not omit[ORDER[i].id] then names[#names + 1] = ORDER[i].id end
    end
    names[#names + 1] = "off"
    if name then
        return "Looks: " .. name .. " is on. Type /looks " .. joinOr(names) .. "."
    end
    return "Looks: off. Type /looks " .. joinOr(names) .. "."
end

local function statusLine()
    local id, name = wornFrame()
    local glows = wornGlows()
    local omit = {}
    if id then omit[id] = true end
    for i = 1, #glows do omit[glows[i].id] = true end
    if not name and glows[1] then name = glows[1].name end
    return hintLine(name, omit)
end

-- Route 1: a public setter, if a future Daylight build adds one.
local function frameSetter()
    if type(view) == "table" and type(view.SetFrameStyle) == "function" then
        return function(key) view.SetFrameStyle(key) end
    end
    local api = apiOf()
    if api and type(api.SetFrameStyle) == "function" then
        return function(key)
            if key == "daylight" then api.SetFrameStyle("daylight") else api.SetFrameStyle("Looks:" .. key) end
        end
    end
end

local function glowSetter()
    if type(view) == "table" and type(view.SetGlowStyle) == "function" then
        return function(key) view.SetGlowStyle(key) end
    end
    local api = apiOf()
    if api and type(api.SetGlowStyle) == "function" then
        return function(key)
            if key == "none" then api.SetGlowStyle("none") else api.SetGlowStyle("Looks:" .. key) end
        end
    end
end

-- The only settings Looks writes. Anything else is refused.
local function allowedWrite(scope, path)
    if scope == "UnitFrames" and path == "look.style" then return true end
    if scope == "general" and path == "buttonGlow" then return true end
    if scope == "Nameplates" and path == "targetLight" then return true end
    return false
end

local function readSetting(scope, path)
    local d = DaylightUI
    if type(d) ~= "table" or type(d.Get) ~= "function" then return nil, false end
    local ok, value = pcall(d.Get, d, scope, path)
    if not ok then return nil, false end
    return value, true
end

-- Taken the first time Looks changes a style. Restore writes these back.
-- A missing read stays empty, and Restore uses Daylight's own default for it.
-- Nil means Looks has not changed anything yet.
local original

local function readKnown(scope, path)
    local value, ok = readSetting(scope, path)
    if ok and value ~= nil then return value, true end
    local api = apiOf()
    if api and type(api.GetSetting) == "function" then
        local gotOk, got = pcall(api.GetSetting, scope, path)
        if gotOk and got ~= nil then return got, true end
    end
    return nil, false
end

local function readFrameStyle()
    local value, ok = readKnown("UnitFrames", "look.style")
    if ok then return value, true end
    local api = apiOf()
    if not api or type(api.GetUnitFrame) ~= "function" or type(api.Parts) ~= "function" then
        return nil, false
    end
    local frameOk, frame = pcall(api.GetUnitFrame, "player")
    if not frameOk or type(frame) ~= "table" then return nil, false end
    local partsOk, parts = pcall(api.Parts, frame)
    if not partsOk or type(parts) ~= "table" or type(parts.style) ~= "string" then
        return nil, false
    end
    return parts.style, true
end

local function remember()
    if original then return end
    local frame, frameOk = readFrameStyle()
    local glow, glowOk = readKnown("general", "buttonGlow")
    local light, lightOk = readKnown("Nameplates", "targetLight")
    if not frameOk and not glowOk and not lightOk then return end
    original = {
        frame = frameOk and frame or nil,
        glow = glowOk and glow or nil,
        light = lightOk and light or nil,
    }
end

local function hasWrite()
    local d = DaylightUI
    return type(d) == "table" and type(d.Set) == "function"
end

local function hasMenuStyle()
    local d = DaylightUI
    if type(d) ~= "table" or type(d.GetModule) ~= "function" then return false end
    local ok, mod = pcall(d.GetModule, d, "UnitFrames")
    return ok and type(mod) == "table" and type(mod.ns) == "table" and type(mod.ns.SetStyle) == "function"
end

-- Route 3: DaylightUI.Set writes the saved setting and tells the module,
-- which refreshes. Core.lua DUI.Set. Returns false when it is missing or refuses.
local function writeSetting(scope, path, value)
    if not allowedWrite(scope, path) then return false end
    local d = DaylightUI
    if type(d) ~= "table" or type(d.Set) ~= "function" then return false end
    local ok, result = pcall(d.Set, d, scope, path, value)
    if not ok or result == false then return false end
    local got, readable = readSetting(scope, path)
    if readable and got ~= value then return false end
    return true
end

-- Route 2 for frames: the Frame style menu calls ns.SetStyle. The unit-frames
-- module keeps that table (Module.lua, ns = ns). Units.lua SetStyle swaps
-- heights, then writes look.style. If it does not stick, the caller tries Set.
local function menuSetStyle(value)
    local d = DaylightUI
    if type(d) ~= "table" or type(d.GetModule) ~= "function" then return false end
    local ok, mod = pcall(d.GetModule, d, "UnitFrames")
    if not ok or type(mod) ~= "table" or type(mod.ns) ~= "table" or type(mod.ns.SetStyle) ~= "function" then
        return false
    end
    if not pcall(mod.ns.SetStyle, "look.style", value) then return false end
    local got, readable = readSetting("UnitFrames", "look.style")
    if readable and got ~= value then return false end
    return true
end

local function refreshPage()
    local d = DaylightUI
    local panel = type(d) == "table" and d.OptionsPanel
    if type(panel) ~= "table" or type(panel.Refresh) ~= "function" then return end
    pcall(panel.Refresh, panel)
end

local function pointAtFrame(id)
    if id == "daylight" then
        say("Looks: pick Daylight in the Frame style menu.")
        return
    end
    local found = frameById(id)
    say("Looks: pick " .. (found and found.name or id) .. " in the Frame style menu.")
end

local function pointAtGlow(id)
    if id == "none" then
        say("Looks: pick none in the glow menu.")
        return
    end
    local found = glowById(id)
    say("Looks: pick " .. (found and found.name or id) .. " in the glow menu.")
end

local function frameKey(id)
    if id == "daylight" then return "daylight" end
    return "Looks:" .. id
end

-- quiet: the caller prints the fallback. A thrown setter is not fatal.
-- The snapshot is taken before the first write, so it still holds the
-- settings Looks found, not the style it is about to put on.
local function applyFrame(id, quiet)
    local set = frameSetter()
    if set or hasMenuStyle() or hasWrite() then remember() end
    if set and pcall(set, id) then
        refreshPage()
        return true
    end
    local key = frameKey(id)
    if menuSetStyle(key) or writeSetting("UnitFrames", "look.style", key) then
        refreshPage()
        return true
    end
    if not quiet then pointAtFrame(id) end
    return false
end

-- Glow menus write general.buttonGlow and Nameplates.targetLight.
-- A Cooldown Manager spell keeps its own glowStyle, so Looks does not walk spells.
local function applyGlow(id, quiet)
    local set = glowSetter()
    if set or hasWrite() then remember() end
    if set and pcall(set, id) then
        refreshPage()
        return true
    end
    local buttonKey, lightKey
    if id == "none" then
        buttonKey, lightKey = "circle", "none"
    else
        buttonKey, lightKey = "Looks:" .. id, "Looks:" .. id
    end
    local buttons = writeSetting("general", "buttonGlow", buttonKey)
    local light = writeSetting("Nameplates", "targetLight", lightKey)
    if buttons or light then
        refreshPage()
        return true
    end
    if not quiet then pointAtGlow(id) end
    return false
end

local DAYLIGHT_FRAME = "daylight"
local DAYLIGHT_GLOW = "circle"
local DAYLIGHT_LIGHT = "none"

local function writeFrameValue(value)
    if menuSetStyle(value) or writeSetting("UnitFrames", "look.style", value) then
        return true
    end
    local set = frameSetter()
    if not set then return false end
    if value == DAYLIGHT_FRAME and pcall(set, "daylight") then return true end
    local id = looksId(value)
    if id and frameById(id) and pcall(set, id) then return true end
    return false
end

local function writeGlowValue(buttonValue, lightValue)
    local buttons = writeSetting("general", "buttonGlow", buttonValue)
    local light = writeSetting("Nameplates", "targetLight", lightValue)
    if buttons or light then return true end
    local set = glowSetter()
    if set and buttonValue == lightValue then
        local id = buttonValue == "none" and "none" or looksId(buttonValue)
        if id and (id == "none" or glowById(id)) and pcall(set, id) then return true end
    end
    return false
end

-- A preset is one frame and one glow. It never writes a palette or the accent.
local function applyPreset(preset)
    local frameOk = applyFrame(preset.frame, true)
    local glowOk = applyGlow(preset.glow, true)
    if frameOk and glowOk then return end
    local frame = frameById(preset.frame)
    local glow = glowById(preset.glow)
    say("Looks: " .. preset.name .. " is " .. frame.name .. " and " .. glow.name .. ". It does not change Palettes or the accent.")
    if not frameOk then pointAtFrame(preset.frame) end
    if not glowOk then pointAtGlow(preset.glow) end
end

-- Puts back the frame and glow settings from before Looks first changed
-- them. With no snapshot, those are Daylight's own defaults. Restore does
-- not take a snapshot of its own.
local function restore()
    if not ready then
        say(refused or TOO_OLD)
        return
    end
    local frame = DAYLIGHT_FRAME
    local glow = DAYLIGHT_GLOW
    local light = DAYLIGHT_LIGHT
    if original then
        if original.frame ~= nil then frame = original.frame end
        if original.glow ~= nil then glow = original.glow end
        if original.light ~= nil then light = original.light end
    end
    local frameOk = writeFrameValue(frame)
    local glowOk = writeGlowValue(glow, light)
    if frameOk or glowOk then refreshPage() end
    if not frameOk then pointAtFrame(looksId(frame) or "daylight") end
    if not glowOk then pointAtGlow("none") end
end

local function slash(msg)
    if not ready then
        say(refused or TOO_OLD)
        return
    end
    local arg = string.lower(trim(msg or ""))
    if arg == "" or string.find(arg, "%s") then
        say(statusLine())
        return
    end
    if arg == "off" then
        restore()
        return
    end
    if frameById(arg) then
        applyFrame(arg)
        return
    end
    if glowById(arg) then
        applyGlow(arg)
        return
    end
    local preset = presetById(arg)
    if preset then
        applyPreset(preset)
        return
    end
    say(statusLine())
end

local function pluginSpec()
    return {
        needs = { 1, 9 },
        color = "C4A574",
        short = "Looks",
        blurb = PAGE,
    }
end

local function apiTooOld(d)
    local api = type(d) == "table" and d.API
    if type(api) ~= "table" or api.major ~= 1 or type(api.minor) ~= "number" or api.minor < 9 then
        return true
    end
end

local function refuse(text)
    refused = text
    say(text)
end

local CARD = "Presets & Styles"
local CARD_INTRO = "Presets pair a frame style and a glow style only. They never change colours in Palettes for DaylightUI."
local PAGE_NOTE = "Starts off on first login · /looks"
local FRAME_HEAD = "FRAME STYLES"
local GLOW_HEAD = "GLOW STYLES"
local RESTORE_LABEL = "Restore Daylight look"

local CREAM = { 0.95, 0.91, 0.86, 1 }
local INK = { 0.78, 0.72, 0.62, 1 }
local DIM = { 0.62, 0.56, 0.48, 1 }
local ON_INK = { 0.93, 0.84, 0.68, 1 }
local RED = { 0.48, 0.17, 0.15, 1 }
local CHIP_EDGE = { 0.45, 0.38, 0.30, 1 }
local CHIP_FILL = { 0.16, 0.15, 0.14, 1 }
local BOX_EDGE = { 0.55, 0.50, 0.44, 1 }
local BOX_FILL = { 0.10, 0.10, 0.11, 1 }
local BOX_ON = { 0.62, 0.52, 0.36, 1 }
local ROW_ON = { 0.28, 0.24, 0.20, 0.95 }
local HINT_EDGE = { 0.35, 0.32, 0.28, 1 }

local INTRO_H = 32
local PRESET_H = 74
local STYLE_H = 36
local HEAD_H = 20
local HINT_H = 58

local function sheetHeight()
    local left = INTRO_H + #PRESETS * PRESET_H
    local right = INTRO_H + HEAD_H + #FRAMES * STYLE_H + HEAD_H + #GLOWS * STYLE_H + HINT_H + 8
    if right > left then return right + 8 end
    return left + 8
end

local function uiFont(parent, size, color)
    local d = DaylightUI
    local widgets = type(d) == "table" and d.Widgets
    if type(widgets) == "table" and type(widgets.Font) == "function" and type(widgets.BODY) == "string" then
        return widgets.Font(parent, widgets.BODY, size, color, "LEFT")
    end
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    if color and type(fs.SetTextColor) == "function" then
        fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
    if type(fs.SetJustifyH) == "function" then fs:SetJustifyH("LEFT") end
    return fs
end

local function flat(parent, layer, color)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    if type(t.SetColorTexture) == "function" then
        t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    end
    t:SetAllPoints()
    return t
end

local function redButton(parent, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(72, 22)
    flat(b, "BACKGROUND", RED)
    local fs = uiFont(b, 12, CREAM)
    fs:ClearAllPoints()
    fs:SetPoint("CENTER", b, "CENTER", 0, 0)
    if type(fs.SetJustifyH) == "function" then fs:SetJustifyH("CENTER") end
    fs:SetText(text)
    b:SetScript("OnClick", function() onClick() end)
    return b
end

local function drawIcon(parent, parts)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(36, 18)
    for i = 1, #parts do
        local part = parts[i]
        local t = f:CreateTexture(nil, "ARTWORK")
        if type(t.SetColorTexture) == "function" then
            t:SetColorTexture(part[5], part[6], part[7], part[8] or 1)
        end
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", f, "TOPLEFT", part[1], -part[2])
        t:SetSize(math.max(1, part[3]), math.max(1, part[4]))
    end
    return f
end

local function hookSize(row, place)
    if type(row.GetScript) ~= "function" or type(row.SetScript) ~= "function" then
        place()
        return
    end
    local prev = row:GetScript("OnSizeChanged")
    row:SetScript("OnSizeChanged", function(f)
        if type(prev) == "function" then prev(f) end
        place()
    end)
    place()
end

local function buildRestore(row)
    if row.made or type(CreateFrame) ~= "function" then return end
    row.made = true
    local caption = uiFont(row, 12, DIM)
    caption:SetText(RESTORE_LABEL)
    local button = redButton(row, "Restore", restore)
    hookSize(row, function()
        button:ClearAllPoints()
        caption:ClearAllPoints()
        button:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -4)
        caption:SetPoint("RIGHT", button, "LEFT", -8, 0)
    end)
end

local function buildPage(row, sheet)
    if row.made or type(CreateFrame) ~= "function" then return end
    row.made = true
    row.lines = {}

    local intro = uiFont(row, 12, DIM)
    intro:SetText(CARD_INTRO)
    intro:SetWordWrap(true)
    local note = uiFont(row, 12, DIM)
    note:SetText(PAGE_NOTE)
    if type(note.SetJustifyH) == "function" then note:SetJustifyH("RIGHT") end

    local presetRows = {}
    for i = 1, #sheet.presets do
        local preset = sheet.presets[i]
        local hold = CreateFrame("Frame", nil, row)
        hold:SetHeight(PRESET_H)
        local name = uiFont(hold, 14, CREAM)
        name:SetText(preset.name)
        local chip = CreateFrame("Frame", nil, hold)
        flat(chip, "BACKGROUND", CHIP_EDGE)
        local chipFill = chip:CreateTexture(nil, "BORDER")
        if type(chipFill.SetColorTexture) == "function" then
            chipFill:SetColorTexture(CHIP_FILL[1], CHIP_FILL[2], CHIP_FILL[3], 1)
        end
        chipFill:SetPoint("TOPLEFT", chip, "TOPLEFT", 1, -1)
        chipFill:SetPoint("BOTTOMRIGHT", chip, "BOTTOMRIGHT", -1, 1)
        local chipText = uiFont(chip, 10, ON_INK)
        chipText:SetText(preset.chip)
        chipText:SetPoint("CENTER", chip, "CENTER", 0, 0)
        if type(chipText.SetJustifyH) == "function" then chipText:SetJustifyH("CENTER") end
        local chipW = chipText.GetStringWidth and chipText:GetStringWidth() or 72
        if type(chipW) ~= "number" or chipW < 8 then chipW = 72 end
        chip:SetSize(chipW + 12, 16)
        local mood = uiFont(hold, 11, DIM)
        mood:SetText(preset.mood)
        mood:SetWordWrap(true)
        local button = redButton(hold, "Apply", preset.apply)
        presetRows[#presetRows + 1] = {
            hold = hold, name = name, chip = chip, mood = mood, button = button,
        }
    end

    local function heading(text)
        local fs = uiFont(row, 11, DIM)
        fs:SetText(text)
        return fs
    end

    local frameHead = heading(FRAME_HEAD)
    local glowHead = heading(GLOW_HEAD)

    local function styleLine(entry)
        local hold = CreateFrame("Button", nil, row)
        hold:SetHeight(STYLE_H)
        local hi = hold:CreateTexture(nil, "BACKGROUND")
        if type(hi.SetColorTexture) == "function" then
            hi:SetColorTexture(ROW_ON[1], ROW_ON[2], ROW_ON[3], ROW_ON[4])
        end
        hi:SetAllPoints()
        hi:Hide()
        local box = CreateFrame("Button", nil, hold)
        box:SetSize(14, 14)
        flat(box, "BACKGROUND", BOX_EDGE)
        local boxFill = box:CreateTexture(nil, "BORDER")
        if type(boxFill.SetColorTexture) == "function" then
            boxFill:SetColorTexture(BOX_FILL[1], BOX_FILL[2], BOX_FILL[3], 1)
        end
        boxFill:SetPoint("TOPLEFT", box, "TOPLEFT", 1, -1)
        boxFill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -1, 1)
        local mark = box:CreateTexture(nil, "ARTWORK")
        if type(mark.SetColorTexture) == "function" then
            mark:SetColorTexture(BOX_ON[1], BOX_ON[2], BOX_ON[3], 1)
        end
        mark:SetSize(8, 8)
        mark:SetPoint("CENTER", box, "CENTER", 0, 0)
        mark:Hide()
        local icon = drawIcon(hold, entry.icon)
        local name = uiFont(hold, 13, CREAM)
        name:SetText(entry.name)
        local desc = uiFont(hold, 11, DIM)
        desc:SetText(entry.desc)
        local key = uiFont(hold, 11, DIM)
        key:SetText(entry.key)
        local onText = uiFont(hold, 12, ON_INK)
        onText:SetText("[On]")
        onText:Hide()
        local line = {
            id = entry.id,
            kind = entry.kind,
            hold = hold,
            button = hold,
            box = box,
            selected = false,
        }
        function line.SetOn(on)
            line.selected = on and true or false
            if on then hi:Show() else hi:Hide() end
            if on then mark:Show() else mark:Hide() end
            if on then onText:Show() else onText:Hide() end
            if type(boxFill.SetColorTexture) == "function" then
                local c = on and BOX_ON or BOX_FILL
                boxFill:SetColorTexture(c[1], c[2], c[3], 1)
            end
        end
        local function pick() entry.select() end
        hold:SetScript("OnClick", pick)
        box:SetScript("OnClick", pick)
        line.click = pick
        row.lines[#row.lines + 1] = line
        return {
            hold = hold, box = box, icon = icon, name = name, desc = desc,
            key = key, onText = onText, line = line,
        }
    end

    local frameRows, glowRows = {}, {}
    for i = 1, #sheet.frames do frameRows[#frameRows + 1] = styleLine(sheet.frames[i]) end
    for i = 1, #sheet.glows do glowRows[#glowRows + 1] = styleLine(sheet.glows[i]) end

    local hint = CreateFrame("Frame", nil, row)
    hint:SetHeight(HINT_H)
    flat(hint, "BACKGROUND", HINT_EDGE)
    local hintFill = hint:CreateTexture(nil, "BORDER")
    if type(hintFill.SetColorTexture) == "function" then
        hintFill:SetColorTexture(0.12, 0.12, 0.13, 1)
    end
    hintFill:SetPoint("TOPLEFT", hint, "TOPLEFT", 1, -1)
    hintFill:SetPoint("BOTTOMRIGHT", hint, "BOTTOMRIGHT", -1, 1)
    local hintText = uiFont(hint, 11, DIM)
    hintText:SetText(GLOW_HINT)
    hintText:SetWordWrap(true)

    local function place()
        local w = row:GetWidth()
        if type(w) ~= "number" or w < 120 then w = 760 end
        local gap = 22
        local leftW = math.floor((w - gap) * 0.50)
        local rightX = leftW + gap
        local rightW = w - rightX
        intro:ClearAllPoints()
        intro:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        intro:SetWidth(leftW)
        note:ClearAllPoints()
        note:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -2)
        local y = INTRO_H
        for i = 1, #presetRows do
            local p = presetRows[i]
            p.hold:ClearAllPoints()
            p.hold:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -y)
            p.hold:SetWidth(leftW)
            p.name:ClearAllPoints()
            p.name:SetPoint("TOPLEFT", p.hold, "TOPLEFT", 0, -4)
            p.chip:ClearAllPoints()
            p.chip:SetPoint("LEFT", p.name, "RIGHT", 8, 0)
            p.button:ClearAllPoints()
            p.button:SetPoint("TOPRIGHT", p.hold, "TOPRIGHT", 0, -4)
            p.mood:ClearAllPoints()
            p.mood:SetPoint("TOPLEFT", p.hold, "TOPLEFT", 0, -26)
            p.mood:SetWidth(leftW - 84)
            y = y + PRESET_H
        end
        local function placeHead(fs, at)
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", row, "TOPLEFT", rightX, -at)
        end
        local function placeStyle(list, at)
            for i = 1, #list do
                local s = list[i]
                s.hold:ClearAllPoints()
                s.hold:SetPoint("TOPLEFT", row, "TOPLEFT", rightX, -at)
                s.hold:SetWidth(rightW)
                s.box:ClearAllPoints()
                s.box:SetPoint("LEFT", s.hold, "LEFT", 0, 0)
                s.icon:ClearAllPoints()
                s.icon:SetPoint("LEFT", s.box, "RIGHT", 8, 0)
                s.name:ClearAllPoints()
                s.name:SetPoint("TOPLEFT", s.hold, "TOPLEFT", 64, -2)
                s.desc:ClearAllPoints()
                s.desc:SetPoint("TOPLEFT", s.hold, "TOPLEFT", 64, -16)
                s.desc:SetWidth(math.max(40, rightW - 64 - 150))
                s.key:ClearAllPoints()
                s.key:SetPoint("RIGHT", s.hold, "RIGHT", -4, 0)
                s.onText:ClearAllPoints()
                s.onText:SetPoint("RIGHT", s.key, "LEFT", -8, 0)
                at = at + STYLE_H
            end
            return at
        end
        local ry = INTRO_H
        placeHead(frameHead, ry)
        ry = placeStyle(frameRows, ry + HEAD_H)
        placeHead(glowHead, ry)
        ry = placeStyle(glowRows, ry + HEAD_H)
        hint:ClearAllPoints()
        hint:SetPoint("TOPLEFT", row, "TOPLEFT", rightX, -(ry + 6))
        hint:SetWidth(rightW)
        hintText:ClearAllPoints()
        hintText:SetPoint("TOPLEFT", hint, "TOPLEFT", 8, -8)
        hintText:SetWidth(math.max(40, rightW - 16))
    end

    function row.UpdateLooks()
        for i = 1, #row.lines do
            local line = row.lines[i]
            local on = line.kind == "frame" and sheet.frameOn(line.id) or sheet.glowOn(line.id)
            line.SetOn(on and true or false)
        end
    end
    hookSize(row, place)
    row.UpdateLooks()
end

local function boot()
    local d = DaylightUI
    if type(d) ~= "table" or type(d.RegisterPlugin) ~= "function" or type(d.RegisterModule) ~= "function" then
        refuse(TOO_OLD)
        return
    end
    if apiTooOld(d) then
        refuse(TOO_OLD)
        d.RegisterPlugin("Looks", pluginSpec())
        return
    end

    local plugin = d.RegisterPlugin("Looks", pluginSpec())
    if type(plugin) ~= "table" or plugin.off then
        refuse(TOO_OLD)
        return
    end

    local api = d.API
    view = type(api.For) == "function" and api.For("Looks") or nil
    if type(view) ~= "table" or type(view.AddFrameStyle) ~= "function" or type(view.AddGlowStyle) ~= "function" then
        refuse(TOO_OLD)
        return
    end

    local function frameOn(id)
        local worn = wornFrame()
        return worn == id
    end
    local function glowOn(id)
        local glows = wornGlows()
        for i = 1, #glows do
            if glows[i].id == id then return true end
        end
        return false
    end

    local presets = {}
    for i = 1, #PRESETS do
        local preset = PRESETS[i]
        local frame = frameById(preset.frame)
        local glow = glowById(preset.glow)
        presets[#presets + 1] = {
            id = preset.id,
            name = preset.name,
            chip = frame.name .. " + " .. glow.name,
            mood = preset.mood,
            frame = preset.frame,
            glow = preset.glow,
            apply = function() applyPreset(preset) end,
        }
    end
    local frames = {}
    for i = 1, #FRAMES do
        local frame = FRAMES[i]
        frames[#frames + 1] = {
            kind = "frame",
            id = frame.id,
            name = frame.name,
            desc = frame.spec.desc,
            key = "Looks:" .. frame.id,
            icon = ICONS[frame.id],
            select = function() applyFrame(frame.id) end,
        }
    end
    local glows = {}
    for i = 1, #GLOWS do
        local glow = GLOWS[i]
        glows[#glows + 1] = {
            kind = "glow",
            id = glow.id,
            name = glow.name,
            desc = glow.mood,
            key = "Looks:" .. glow.id,
            icon = ICONS[glow.id],
            select = function() applyGlow(glow.id) end,
        }
    end
    local sheet = {
        card = CARD,
        intro = CARD_INTRO,
        note = PAGE_NOTE,
        frameHeading = FRAME_HEAD,
        glowHeading = GLOW_HEAD,
        hint = GLOW_HINT,
        presets = presets,
        frames = frames,
        glows = glows,
        frameOn = frameOn,
        glowOn = glowOn,
    }

    local function restoreItem(place)
        return {
            type = "custom",
            label = RESTORE_LABEL,
            place = place,
            restore = restore,
            caption = RESTORE_LABEL,
            button = "Restore",
            build = buildRestore,
            height = function() return 32 end,
        }
    end
    local body = {
        type = "custom",
        label = CARD,
        sheet = sheet,
        build = function(row) buildPage(row, sheet) end,
        update = function(row)
            if type(row.UpdateLooks) == "function" then row.UpdateLooks() end
        end,
        height = function() return sheetHeight() end,
    }

    d:RegisterModule("Looks", {
        label = "Looks",
        plugin = "Looks",
        defaults = {},
        options = {
            pages = {
                {
                    id = "main",
                    label = "Looks",
                    desc = PAGE,
                    groups = {
                        { label = "Restore", bare = true, wide = true, items = { restoreItem("header") } },
                        { label = CARD, wide = true, items = { body } },
                        { label = "Restore", bare = true, wide = true, items = { restoreItem("footer") } },
                    },
                },
            },
        },
    })

    for i = 1, #FRAMES do
        view.AddFrameStyle(FRAMES[i].id, FRAMES[i].spec)
    end
    for i = 1, #GLOWS do
        view.AddGlowStyle(GLOWS[i].id, GLOWS[i].spec)
    end
    ready = true
end

if type(SlashCmdList) == "table" then
    SLASH_LOOKS1 = "/looks"
    SlashCmdList.LOOKS = function(msg)
        if not pcall(slash, msg) then
            say("Looks: something went wrong, and no style was changed.")
        end
    end
end

if not pcall(boot) then
    ready = false
    refuse("Looks: couldn't start, so no frame or glow styles were added.")
end
