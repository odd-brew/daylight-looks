-- Looks (DaylightUI Plugin). Frame styles and glow styles for Daylight UI.
-- Daylight can register both (AddFrameStyle, AddGlowStyle). It has no public
-- call that selects either one. The private writes live in Daylight's own
-- saved settings. This file never calls those, and never changes the accent.

local PAGE = "Add frame styles and glow styles to Daylight. Colors stay in Palettes for DaylightUI, or in Daylight if Palettes for DaylightUI is off."
local TOO_OLD = "Looks: Daylight UI is missing the settings Looks needs, so no frame or glow styles were added."
local GLOW_HINT = "Glow colour follows your accent colour. Change it in Daylight's accent setting, or with Palettes for DaylightUI."

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

local ORDER = { FRAMES[1], FRAMES[2], FRAMES[3], GLOWS[1], GLOWS[2], GLOWS[3] }

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

-- A documented frame setter would be me.SetFrameStyle or API.SetFrameStyle.
-- Neither exists in API 1.9. Do not fall through to DaylightUI:Set.
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

-- Same rule for glows. API 1.9 has AddGlowStyle and no setter.
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

local function applyFrame(id)
    local set = frameSetter()
    if set then set(id) else pointAtFrame(id) end
end

local function applyGlow(id)
    local set = glowSetter()
    if set then set(id) else pointAtGlow(id) end
end

local function restore()
    if not ready then
        say(refused or TOO_OLD)
        return
    end
    applyFrame("daylight")
    applyGlow("none")
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

local function textRow(name, line)
    return { type = "text", label = name .. ". " .. line }
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

    local frameItems = {}
    for i = 1, #FRAMES do
        frameItems[#frameItems + 1] = textRow(FRAMES[i].name, FRAMES[i].spec.desc)
    end
    frameItems[#frameItems + 1] = { type = "button", label = "Restore Daylight look", text = "Restore", func = restore }

    local glowItems = {}
    for i = 1, #GLOWS do
        glowItems[#glowItems + 1] = textRow(GLOWS[i].name, GLOWS[i].mood)
    end
    glowItems[#glowItems + 1] = { type = "text", label = GLOW_HINT }

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
                        { label = "Frame styles", items = frameItems },
                        { label = "Glow styles", items = glowItems },
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
