-- Mock Daylight and prove the P1 done-when lines.
-- Run from the repo root: lua5.1 tools/looks_check.lua

local fails = 0

local function fail(msg)
    fails = fails + 1
    io.stderr:write("looks_check: " .. msg .. "\n")
end

local function eq(got, want, msg)
    if got ~= want then
        fail(msg .. "\n  got:  " .. tostring(got) .. "\n  want: " .. tostring(want))
    end
end

local function readFile(path)
    local f = assert(io.open(path, "r"))
    local text = f:read("*a")
    f:close()
    return text
end

local function loadLooks(daylight, saved)
    local env = {
        DaylightUI = daylight,
        SlashCmdList = {},
        LooksDB = saved,
    }
    local chat = {}
    env.DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, text) chat[#chat + 1] = text end,
    }
    setmetatable(env, { __index = _G })
    local chunk, err = loadfile("Looks/Looks.lua")
    if not chunk then error(err) end
    setfenv(chunk, env)
    local ok, runErr = pcall(chunk)
    if not ok then
        fail("Looks.lua raised: " .. tostring(runErr))
    end
    return env, chat
end

local function newDaylight(minor)
    local styles = {}
    local glows = {}
    local modules = {}
    local plugins = {}
    local writes = {}
    local reads = {}
    local frame = { parts = { style = "daylight" } }
    local d = {
        styles = styles,
        glows = glows,
        modules = modules,
        plugins = plugins,
        writes = writes,
        reads = reads,
        frame = frame,
        buttonGlow = "circle",
        targetLight = "none",
    }
    local api = {
        major = 1,
        minor = minor,
        GetUnitFrame = function(unit)
            if unit == "player" then return frame end
        end,
        Parts = function(f) return f.parts end,
        GetSetting = function(scope, path)
            reads[#reads + 1] = tostring(scope) .. "." .. tostring(path)
            if scope == "general" and path == "buttonGlow" then return d.buttonGlow end
            if scope == "Nameplates" and path == "targetLight" then return d.targetLight end
        end,
        For = function(name)
            return {
                AddFrameStyle = function(key, spec)
                    styles[#styles + 1] = { owner = name, id = key, key = name .. ":" .. key, spec = spec }
                    return true
                end,
                AddGlowStyle = function(key, spec)
                    glows[#glows + 1] = { owner = name, id = key, key = name .. ":" .. key, spec = spec }
                    return true
                end,
            }
        end,
    }
    d.API = api
    function d.RegisterPlugin(name, spec)
        local p = { name = name, spec = spec, off = false }
        plugins[#plugins + 1] = p
        return p
    end
    function d:RegisterModule(name, spec)
        modules[name] = spec
    end
    return d
end

local function armApply(d, mode)
    d.settings = {
        ["UnitFrames.look.style"] = "daylight",
        ["general.buttonGlow"] = "circle",
        ["Nameplates.targetLight"] = "none",
    }
    function d:Get(scope, path)
        return d.settings[tostring(scope) .. "." .. tostring(path)]
    end
    function d:Set(scope, path, value)
        if mode == "throw" then error("set failed") end
        if mode == "refuse" then return false end
        d.writes[#d.writes + 1] = { scope = scope, path = path, value = value }
        d.settings[tostring(scope) .. "." .. tostring(path)] = value
        if scope == "UnitFrames" and path == "look.style" then d.frame.parts.style = value end
        if scope == "general" and path == "buttonGlow" then d.buttonGlow = value end
        if scope == "Nameplates" and path == "targetLight" then d.targetLight = value end
        return true
    end
    if mode == "menu" or mode == "menu-noop" then
        function d:GetModule(name)
            if name ~= "UnitFrames" then return nil end
            return {
                ns = {
                    SetStyle = function(path, value)
                        d.menu = { path = path, value = value }
                        if mode == "menu-noop" then return end
                        d.settings["UnitFrames." .. path] = value
                        if path == "look.style" then d.frame.parts.style = value end
                    end,
                },
            }
        end
    end
end

local function allowedWrite(scope, path)
    if scope == "UnitFrames" and path == "look.style" then return true end
    if scope == "general" and path == "buttonGlow" then return true end
    if scope == "Nameplates" and path == "targetLight" then return true end
    return false
end

local function assertWrites(d, msg)
    for i = 1, #d.writes do
        local w = d.writes[i]
        if not allowedWrite(w.scope, w.path) then
            fail(msg .. " wrote " .. tostring(w.scope) .. " " .. tostring(w.path))
        end
        if w.path == "accent" or w.path == "accentColor" or w.path == "accentGradient" then
            fail(msg .. " wrote the accent")
        end
    end
end

local function noWrites(d, msg)
    if #d.writes ~= 0 then
        fail(msg .. " wrote " .. tostring(d.writes[1].scope) .. " " .. tostring(d.writes[1].path))
    end
end

local function slash(env, msg)
    env.SlashCmdList.LOOKS(msg)
end

local function last(chat)
    return chat[#chat]
end

local WORDS = {
    "lintel", "sill", "stamp", "trestle", "flagon", "signboard", "trough",
    "wick", "draught", "latch",
    "hearthnight", "harvestide", "tidemark", "oldroad", "vigil",
}

local function statusFor(name, omit)
    local names = {}
    for i = 1, #WORDS do
        local skip = false
        for j = 1, #omit do
            if WORDS[i] == omit[j] then skip = true end
        end
        if not skip then names[#names + 1] = WORDS[i] end
    end
    names[#names + 1] = "off"
    local list
    if #names == 1 then
        list = names[1]
    else
        local head = {}
        for i = 1, #names - 1 do head[i] = names[i] end
        list = table.concat(head, ", ") .. ", or " .. names[#names]
    end
    if name then
        return "Looks: " .. name .. " is on. Type /looks " .. list .. "."
    end
    return "Looks: off. Type /looks " .. list .. "."
end

local OFF = statusFor(nil, {})
local LINTEL_ON = statusFor("Lintel", { "lintel" })
local SILL_ON = statusFor("Sill", { "sill" })
local STAMP_ON = statusFor("Stamp", { "stamp" })
local WICK_ON = statusFor("Wick", { "wick" })
local DRAUGHT_ON = statusFor("Draught", { "draught" })
local LATCH_ON = statusFor("Latch", { "latch" })
local LINTEL_WICK = statusFor("Lintel", { "lintel", "wick" })
local TOO_OLD = "Looks: Daylight UI is missing the settings Looks needs, so no frame or glow styles were added."
local GLOW_HINT = "Glow colour follows your accent colour. Change it in Daylight's accent setting, or with Palettes for DaylightUI."
local PICK_LINTEL = "Looks: pick Lintel in the Frame style menu."
local PICK_SILL = "Looks: pick Sill in the Frame style menu."
local PICK_STAMP = "Looks: pick Stamp in the Frame style menu."
local PICK_DAYLIGHT = "Looks: pick Daylight in the Frame style menu."
local PICK_WICK = "Looks: pick Wick in the glow menu."
local PICK_DRAUGHT = "Looks: pick Draught in the glow menu."
local PICK_LATCH = "Looks: pick Latch in the glow menu."
local PICK_NONE = "Looks: pick none in the glow menu."

local function sameColor(got, lo, hi)
    return got == lo or got == hi
end

local function checkDraws(d)
    local lo, hi = { 0.1, 0.2, 0.3 }, { 0.4, 0.5, 0.6 }
    local function recorder()
        local calls = {}
        local g = {
            Light = function(_, at, size, color, alpha)
                calls[#calls + 1] = { kind = "Light", at = at, size = size, color = color, alpha = alpha }
            end,
            Trail = function(_, at, length, alpha, tail, head)
                calls[#calls + 1] = { kind = "Trail", at = at, length = length, alpha = alpha, tail = tail, head = head }
            end,
            Edge = function(_, side, from, to, a0, a1, c0, c1)
                calls[#calls + 1] = { kind = "Edge", side = side, from = from, to = to, a0 = a0, a1 = a1, c0 = c0, c1 = c1 }
            end,
        }
        return g, calls
    end
    local function colorsOk(calls, msg)
        for i = 1, #calls do
            local c = calls[i]
            if c.kind == "Light" and not sameColor(c.color, lo, hi) then fail(msg .. " light color") end
            if c.kind == "Trail" and not (sameColor(c.tail, lo, hi) and sameColor(c.head, lo, hi)) then
                fail(msg .. " trail color")
            end
            if c.kind == "Edge" and not (sameColor(c.c0, lo, hi) and sameColor(c.c1, lo, hi)) then
                fail(msg .. " edge color")
            end
        end
    end
    local function run(spec, at, msg)
        local g, calls = recorder()
        local ok, err = pcall(spec.draw, g, at, lo, hi, 12)
        if not ok then fail(msg .. " draw raised: " .. tostring(err)) end
        colorsOk(calls, msg)
        return calls
    end

    local wick = run(d.glows[1].spec, 0.5, "wick")
    local corners = {}
    for i = 1, #wick do
        if wick[i].kind == "Light" then corners[#corners + 1] = wick[i].at end
    end
    eq(#corners, 4, "wick lights the four corners")
    eq(corners[1], 0, "wick top-left")
    eq(corners[2], 0.25, "wick top-right")
    eq(corners[3], 0.5, "wick bottom-right")
    eq(corners[4], 0.75, "wick bottom-left")

    local draught = run(d.glows[2].spec, 0.35, "draught")
    if #draught == 0 then fail("draught draws nothing") end
    for i = 1, #draught do
        if draught[i].kind ~= "Edge" or draught[i].side ~= 1 then
            fail("draught should be a wash on the top edge")
        end
    end

    local catch = run(d.glows[3].spec, 0.05, "latch catch")
    if #catch == 0 then fail("latch catch draws nothing") end
    local still = run(d.glows[3].spec, 0.8, "latch still")
    eq(#still, 0, "latch is still after the catch")
end

local function checkToc()
    local toc = readFile("Looks/Looks.toc")
    local function has(line)
        if not string.find(toc, line, 1, true) then fail("toc missing " .. line) end
    end
    has("## Interface: 16001")
    has("## Title: Looks (DaylightUI Plugin)")
    has("## Author: odd-brew")
    has("## Version: 0.2.0")
    has("## Dependencies: DaylightUI")
    has("## SavedVariables: LooksDB")
end

local function checkSource()
    local src = readFile("Looks/Looks.lua")
    local banned = { ":Set(", "Override", "Paint", "healthFill", "powerFill", "windowTint", "GetActionButton" }
    if not string.find(src, "AddGlowStyle", 1, true) then fail("Looks.lua does not register glow styles") end
    if not string.find(src, "GetSetting", 1, true) then fail("Looks.lua does not read the current glow") end
    for i = 1, #banned do
        if string.find(src, banned[i], 1, true) then
            fail("Looks.lua contains " .. banned[i])
        end
    end
end

local function checkFresh()
    local d = newDaylight(9)
    local env, chat = loadLooks(d)
    eq(#chat, 0, "fresh install is silent")
    eq(#d.styles, 7, "seven frame styles registered")
    eq(d.styles[1].key, "Looks:lintel", "lintel key")
    eq(d.styles[2].key, "Looks:sill", "sill key")
    eq(d.styles[3].key, "Looks:stamp", "stamp key")
    eq(d.styles[1].spec.row, true, "lintel row")
    eq(d.styles[1].spec.line, nil, "lintel has no line")
    eq(d.styles[1].spec.ring, nil, "lintel ring omitted")
    eq(d.styles[1].spec.sizes, nil, "lintel sizes omitted")
    eq(d.styles[1].spec.desc, "A named beam over a solid bar.", "lintel desc")
    eq(d.styles[2].spec.row, nil, "sill has no row")
    eq(d.styles[2].spec.line, true, "sill line")
    eq(d.styles[2].spec.ring, nil, "sill ring omitted")
    eq(d.styles[2].spec.desc, "The name tab stays; power sits as a thin sill under the bar.", "sill desc")
    eq(d.styles[3].spec.row, true, "stamp row")
    eq(d.styles[3].spec.line, true, "stamp line")
    eq(d.styles[3].spec.ring, 0.35, "stamp ring")
    if not (d.styles[3].spec.ring < 0.56) then fail("stamp ring must stay under Ribbon's 0.56") end
    eq(d.styles[3].spec.sizes, nil, "stamp sizes omitted")
    eq(d.styles[3].spec.desc, "A tight name row and a thin power line, ring kept small.", "stamp desc")
    eq(d.styles[4].key, "Looks:trestle", "trestle key")
    eq(d.styles[4].spec.row, true, "trestle row")
    eq(d.styles[4].spec.line, true, "trestle line")
    eq(d.styles[4].spec.ring, nil, "trestle ring omitted")
    eq(d.styles[4].spec.sizes, nil, "trestle keeps Daylight heights")
    eq(d.styles[5].key, "Looks:flagon", "flagon key")
    eq(d.styles[5].spec.ring, 0.35, "flagon ring")
    eq(d.styles[5].spec.line, nil, "flagon has no line")
    eq(d.styles[5].spec.sizes.player.height, 32, "flagon tall bar")
    eq(d.styles[5].spec.sizes.target.height, 32, "flagon target height")
    eq(d.styles[6].key, "Looks:signboard", "signboard key")
    eq(d.styles[6].spec.ring, 1, "signboard ring")
    eq(d.styles[6].spec.sizes.player.height, 10, "signboard hairline bar")
    eq(d.styles[6].spec.sizes.player.tabHeight, 28, "signboard tall board")
    eq(d.styles[7].key, "Looks:trough", "trough key")
    eq(d.styles[7].spec.row, nil, "trough has no row")
    eq(d.styles[7].spec.line, true, "trough line")
    eq(d.styles[7].spec.ring, 1, "trough ring")
    eq(d.styles[7].spec.sizes.player.height, 11, "trough short bar")
    eq(d.styles[7].spec.sizes.player.powerHeight, 14, "trough power thicker than the bar")
    eq(d.styles[7].spec.sizes.player.powerHeight > d.styles[7].spec.sizes.player.height, true, "trough is not clamped")
    eq(#d.glows, 3, "three glows registered")
    eq(d.glows[1].key, "Looks:wick", "wick key")
    eq(d.glows[2].key, "Looks:draught", "draught key")
    eq(d.glows[3].key, "Looks:latch", "latch key")
    eq(d.glows[1].spec.label, "Wick", "wick label")
    eq(d.glows[1].spec.lap, 2, "wick lap")
    eq(d.glows[2].spec.lap, 2, "draught lap")
    eq(d.glows[3].spec.lap, 2, "latch lap")
    eq(d.glows[1].spec.desc, nil, "glow mood stays off the style record")
    checkDraws(d)
    eq(d.frame.parts.style, "daylight", "fresh install leaves the frame on Daylight")
    eq(d.buttonGlow, "circle", "fresh install leaves the built-in glow")
    eq(d.targetLight, "none", "fresh install leaves the nameplate light")
    noWrites(d, "fresh install")
    eq(d.plugins[1].name, "Looks", "plugin name")
    eq(d.plugins[1].spec.needs[1], 1, "needs major")
    eq(d.plugins[1].spec.needs[2], 9, "needs minor")
    eq(d.plugins[1].spec.short, "Looks", "short name")
    eq(d.plugins[1].off, false, "plugin starts available")
    local page = d.modules.Looks.options.pages[1]
    eq(page.label, "Looks", "page title")
    eq(page.desc, "Add frame styles and glow styles to Daylight. Colors stay in Palettes for DaylightUI, or in Daylight if Palettes for DaylightUI is off.", "page desc")
    local header = page.groups[1].items[1]
    local body = page.groups[2].items[1]
    local footer = page.groups[3].items[1]
    eq(page.groups[1].bare, true, "header sits outside the card")
    eq(page.groups[2].label, "Presets & Styles", "two-column card")
    eq(page.groups[2].wide, true, "card spans the page")
    eq(page.groups[3].bare, true, "footer sits outside the card")
    eq(header.place, "header", "restore in the header")
    eq(footer.place, "footer", "restore in the footer")
    eq(header.caption, "Restore Daylight look", "header restore label")
    eq(header.button, "Restore", "header restore button")
    eq(footer.caption, "Restore Daylight look", "footer restore label")
    eq(footer.button, "Restore", "footer restore button")
    local sheet = body.sheet
    eq(sheet.note, "Starts off on first login · /looks", "top-right note")
    eq(sheet.notePlace, "title", "note sits on the Presets & Styles title row")
    eq(sheet.presetHeading, "PRESETS", "PRESETS label")
    eq(sheet.intro, "Presets pair a frame style and a glow style only. They never change colours in Palettes for DaylightUI.", "card intro")
    eq(sheet.frameHeading, "FRAME STYLES", "frame heading")
    eq(sheet.glowHeading, "GLOW STYLES", "glow heading")
    eq(sheet.hint, GLOW_HINT, "accent hint")
    eq(#sheet.presets, 5, "five presets")
    eq(sheet.presets[1].chip, "Lintel + Wick", "hearthnight chip")
    eq(sheet.presets[1].mood, "A winter hearth: a named beam, a quiet corner flame. Sits well with Palettes for DaylightUI — Ember.", "hearthnight mood")
    eq(sheet.presets[2].chip, "Sill + Draught", "harvestide chip")
    eq(sheet.presets[2].mood, "Harvest light along the sill of the bar. Sits well with Palettes for DaylightUI — Vanilla.", "harvestide mood")
    eq(sheet.presets[3].chip, "Stamp + Draught", "tidemark chip")
    eq(sheet.presets[3].mood, "A tight line at the waterline, a soft wash along the rim. Sits well with Palettes for DaylightUI — Tide.", "tidemark mood")
    eq(sheet.presets[4].chip, "Lintel + Latch", "old road chip")
    eq(sheet.presets[4].mood, "A weathered beam and a short catch of lantern light. Sits well with Palettes for DaylightUI — Forever.", "old road mood")
    eq(sheet.presets[5].chip, "Sill + Wick", "vigil chip")
    eq(sheet.presets[5].mood, "The name tab stays, and a flame is kept lit at the corners. Sits well with Palettes for DaylightUI — Paladin.", "vigil mood")
    eq(#sheet.frames, 7, "seven frame rows")
    eq(sheet.frames[4].name, "Trestle", "trestle row")
    eq(sheet.frames[4].desc, "A full portrait on a named board, power hung as a rail.", "trestle mood")
    eq(sheet.frames[4].key, "Looks:trestle", "trestle key on the row")
    eq(sheet.frames[7].desc, "A full boss, a thin health lip, and power carried in a deep trough underneath.", "trough mood")
    local function tallest(icon, pred)
        local best = 0
        for p = 1, #icon do
            if pred(icon[p]) and icon[p][4] > best then best = icon[p][4] end
        end
        return best
    end
    local troughIcon = sheet.frames[7].icon
    eq(tallest(troughIcon, function(p) return p[1] >= 14 and p[2] >= 7 end)
        > tallest(troughIcon, function(p) return p[1] >= 14 and p[2] < 7 end),
        true, "trough icon power is deeper than the bar")
    eq(#sheet.glows, 3, "three glow rows")
    eq(sheet.glows[1].desc, "A quiet flame gathers at the corners.", "wick mood")
    eq(sheet.glows[1].key, "Looks:wick", "wick key on the row")
    local function corners(icon)
        local q = { false, false, false, false }
        for p = 1, #icon do
            if icon[p][3] <= 3 and icon[p][4] <= 1 then
                local x, y = icon[p][1], icon[p][2]
                if x < 18 and y < 9 then q[1] = true
                elseif x >= 18 and y < 9 then q[2] = true
                elseif x < 18 then q[3] = true
                else q[4] = true end
            end
        end
        return q[1] and q[2] and q[3] and q[4]
    end
    eq(corners(sheet.glows[1].icon), true, "wick icon marks four corners")
    eq(sheet.glows[2].desc, "A soft wash along the rim.", "draught mood")
    eq(sheet.glows[3].desc, "A short catch of light, then still.", "latch mood")
    for i = 1, #sheet.frames do
        local icon = sheet.frames[i].icon
        if type(icon) ~= "table" or #icon < 1 then fail(sheet.frames[i].id .. " has no preview icon") end
        for p = 1, #icon do
            if not (icon[p][3] <= 1 or icon[p][4] <= 1) then
                fail(sheet.frames[i].id .. " icon is a filled block")
            end
        end
        for p = 1, #icon do
            for k = 1, 8 do
                if type(icon[p][k]) ~= "number" then fail(sheet.frames[i].id .. " icon is not drawn from numbers") end
            end
        end
    end
    for i = 1, #sheet.glows do
        local icon = sheet.glows[i].icon
        if type(icon) ~= "table" or #icon < 1 then fail(sheet.glows[i].id .. " has no preview icon") end
        for p = 1, #icon do
            if not (icon[p][3] <= 1 or icon[p][4] <= 1) then
                fail(sheet.glows[i].id .. " icon is a filled block")
            end
        end
    end
    eq(env.SLASH_LOOKS1, "/looks", "slash")
    slash(env, "")
    eq(last(chat), OFF, "nothing on")
    slash(env, "   ")
    eq(last(chat), OFF, "blank message")
    slash(env, "lintel")
    eq(last(chat), PICK_LINTEL, "lintel points at the menu")
    eq(d.frame.parts.style, "daylight", "lintel did not change the frame")
    noWrites(d, "/looks lintel")
    slash(env, "Sill")
    eq(last(chat), PICK_SILL, "sill points at the menu")
    slash(env, "stamp")
    eq(last(chat), PICK_STAMP, "stamp points at the menu")
    slash(env, "wick")
    eq(last(chat), PICK_WICK, "wick points at the glow menu")
    slash(env, "draught")
    eq(last(chat), PICK_DRAUGHT, "draught points at the glow menu")
    slash(env, "latch")
    eq(last(chat), PICK_LATCH, "latch points at the glow menu")
    slash(env, "trestle")
    eq(last(chat), "Looks: pick Trestle in the Frame style menu.", "trestle points at the frame menu")
    local beforePreset = #chat
    slash(env, "hearthnight")
    eq(chat[beforePreset + 1], "Looks: Hearthnight is Lintel and Wick. It does not change Palettes or the accent.", "hearthnight says the pair")
    eq(chat[beforePreset + 2], PICK_LINTEL, "hearthnight points at the frame")
    eq(chat[beforePreset + 3], PICK_WICK, "hearthnight points at the glow")
    eq(d.frame.parts.style, "daylight", "hearthnight did not write the frame")
    eq(d.buttonGlow, "circle", "hearthnight did not write the glow")
    noWrites(d, "hearthnight")
    beforePreset = #chat
    slash(env, "vigil")
    eq(chat[beforePreset + 1], "Looks: Vigil is Sill and Wick. It does not change Palettes or the accent.", "vigil says the pair")
    eq(chat[beforePreset + 2], PICK_SILL, "vigil points at Sill")
    eq(chat[beforePreset + 3], PICK_WICK, "vigil points at Wick")
    beforePreset = #chat
    sheet.presets[5].apply()
    eq(chat[beforePreset + 1], "Looks: Vigil is Sill and Wick. It does not change Palettes or the accent.", "Apply Vigil")
    eq(d.buttonGlow, "circle", "glow words did not change the glow")
    eq(d.targetLight, "none", "glow words did not change the outline")
    slash(env, "nope")
    eq(last(chat), OFF, "unknown word reprints the off line")
    local beforeOff = #chat
    slash(env, "off")
    eq(chat[beforeOff + 1], PICK_DAYLIGHT, "off points at the frame menu")
    eq(chat[beforeOff + 2], PICK_NONE, "off points at the glow menu")
    noWrites(d, "Restore")
    eq(d.frame.parts.style, "daylight", "Restore did not write a style")
    eq(d.buttonGlow, "circle", "Restore did not write a glow")
    local beforeButton = #chat
    header.restore()
    eq(chat[beforeButton + 1], PICK_DAYLIGHT, "Restore button, frame")
    eq(chat[beforeButton + 2], PICK_NONE, "Restore button, glow")
    noWrites(d, "Restore button")
    beforeButton = #chat
    footer.restore()
    eq(chat[beforeButton + 1], PICK_DAYLIGHT, "footer Restore, frame")
    eq(chat[beforeButton + 2], PICK_NONE, "footer Restore, glow")
    local beforeSelect = #chat
    sheet.frames[1].select()
    eq(chat[beforeSelect + 1], PICK_LINTEL, "select box falls back to the frame menu")
    beforeSelect = #chat
    sheet.glows[1].select()
    eq(chat[beforeSelect + 1], PICK_WICK, "select box falls back to the glow menu")

    d.frame.parts.style = "Looks:lintel"
    slash(env, "")
    eq(last(chat), LINTEL_ON, "lintel on")
    slash(env, "nope")
    eq(last(chat), LINTEL_ON, "unknown reprints the on line")
    d.frame.parts.style = "Looks:sill"
    slash(env, nil)
    eq(last(chat), SILL_ON, "sill on")
    d.frame.parts.style = "Looks:stamp"
    slash(env, "")
    eq(last(chat), STAMP_ON, "stamp on")
    d.frame.parts.style = "ribbon"
    slash(env, "")
    eq(last(chat), OFF, "Ribbon is not a Looks style")
    d.frame.parts.style = "daylight"
    d.buttonGlow = "Looks:wick"
    slash(env, "")
    eq(last(chat), WICK_ON, "wick on")
    d.buttonGlow = "circle"
    d.targetLight = "Looks:draught"
    slash(env, "")
    eq(last(chat), DRAUGHT_ON, "draught on the target outline")
    d.targetLight = "Looks:latch"
    slash(env, "")
    eq(last(chat), LATCH_ON, "latch on the target outline")
    d.frame.parts.style = "Looks:lintel"
    d.buttonGlow = "Looks:wick"
    d.targetLight = "none"
    slash(env, "")
    eq(last(chat), LINTEL_WICK, "frame and glow both on, glow left out of the list")
    d.frame.parts.style = "daylight"
    d.buttonGlow = "circle"
end

local function checkNoFrameYet()
    local d = newDaylight(9)
    d.API.GetUnitFrame = function() return nil end
    local env, chat = loadLooks(d)
    slash(env, "")
    eq(last(chat), OFF, "no player frame yet still reads as off")
    noWrites(d, "no frame")
end

local function checkPluginOff()
    local d = newDaylight(9)
    function d.RegisterPlugin(name, spec)
        local p = { name = name, spec = spec, off = true }
        d.plugins[#d.plugins + 1] = p
        return p
    end
    local env, chat = loadLooks(d)
    eq(#d.styles, 0, "plugin off adds no styles")
    eq(#d.glows, 0, "plugin off adds no glows")
    eq(d.modules.Looks, nil, "plugin off adds no page")
    noWrites(d, "plugin off")
    eq(chat[1], TOO_OLD, "plugin off tells the player")
    slash(env, "lintel")
    eq(last(chat), TOO_OLD, "plugin off does not pretend the menu has styles")
end

local function checkTooOld(minor, label)
    local d = newDaylight(minor)
    local env, chat = loadLooks(d)
    eq(chat[1], TOO_OLD, label .. " prints the too-old line")
    eq(#d.styles, 0, label .. " adds no styles")
    eq(#d.glows, 0, label .. " adds no glows")
    eq(d.modules.Looks, nil, label .. " adds no page")
    eq(d.plugins[1].spec.needs[2], 9, label .. " still declares needs 1.9")
    noWrites(d, label)
    local n = #chat
    slash(env, "lintel")
    eq(chat[n + 1], TOO_OLD, label .. " slash repeats the too-old line")
    slash(env, "off")
    eq(last(chat), TOO_OLD, label .. " Restore does not write")
    noWrites(d, label .. " slash")
end

local function checkMissing()
    local env, chat = loadLooks({})
    eq(chat[1], TOO_OLD, "missing API prints the too-old line")
    local ok = pcall(function() slash(env, "lintel") end)
    if not ok then fail("missing API slash threw") end
    eq(last(chat), TOO_OLD, "missing API slash")
end

local function checkSetter()
    local d = newDaylight(9)
    local applied, glowApplied
    local realFor = d.API.For
    d.API.For = function(name)
        local v = realFor(name)
        function v.SetFrameStyle(key)
            applied = key
            if key == "daylight" then
                d.frame.parts.style = "daylight"
            else
                d.frame.parts.style = "Looks:" .. key
            end
        end
        function v.SetGlowStyle(key)
            glowApplied = key
            if key == "none" then
                d.buttonGlow = "circle"
                d.targetLight = "none"
            else
                d.buttonGlow = "Looks:" .. key
                d.targetLight = "Looks:" .. key
            end
        end
        return v
    end
    function d:Set(scope, path, value)
        d.writes[#d.writes + 1] = { scope = scope, path = path, value = value }
        if scope == "UnitFrames" and path == "look.style" then d.frame.parts.style = value end
        if scope == "general" and path == "buttonGlow" then d.buttonGlow = value end
        if scope == "Nameplates" and path == "targetLight" then d.targetLight = value end
        return true
    end
    local env, chat = loadLooks(d)
    slash(env, "lintel")
    eq(applied, "lintel", "public setter receives lintel")
    eq(#chat, 0, "a real setter does not print the menu line")
    eq(d.frame.parts.style, "Looks:lintel", "setter updated the worn style")
    noWrites(d, "setter path")
    slash(env, "wick")
    eq(glowApplied, "wick", "public glow setter receives wick")
    eq(#chat, 0, "a real glow setter does not print the menu line")
    eq(d.buttonGlow, "Looks:wick", "setter updated the worn glow")
    noWrites(d, "glow setter path")
    slash(env, "")
    eq(last(chat), LINTEL_WICK, "after both setters, status names the frame and drops the glow")
    slash(env, "off")
    eq(applied, "lintel", "Restore keeps the snapshot instead of calling the frame setter again")
    eq(glowApplied, "wick", "Restore keeps the snapshot instead of calling the glow setter again")
    eq(d.frame.parts.style, "daylight", "Restore put the original frame back")
    eq(d.buttonGlow, "circle", "Restore put the original glow back")
    eq(d.targetLight, "none", "Restore put the original outline back")
    eq(last(chat), LINTEL_WICK, "Restore from slash stays quiet when the write works")
    local page = d.modules.Looks.options.pages[1]
    local before = #chat
    d.frame.parts.style = "Looks:sill"
    d.buttonGlow = "Looks:latch"
    page.groups[1].items[1].restore()
    eq(#chat, before, "Restore button stays quiet when the write works")
    eq(d.frame.parts.style, "daylight", "Restore button uses the first snapshot")
    eq(d.buttonGlow, "circle", "Restore button uses the first glow snapshot")
    d.writes = {}
    slash(env, "vigil")
    eq(applied, "sill", "a preset sets its frame through the setter")
    eq(glowApplied, "wick", "a preset sets its glow through the setter")
    eq(#chat, before, "a preset with both setters stays quiet")
    noWrites(d, "preset setter")
end

local function wrote(d, scope, path, value, msg)
    for i = 1, #d.writes do
        local w = d.writes[i]
        if w.scope == scope and w.path == path and w.value == value then return end
    end
    fail(msg .. " did not write " .. scope .. " " .. path .. " " .. tostring(value))
end

local function newNode()
    local f = { kids = {}, scripts = {}, w = 760, h = 20 }
    function f:SetSize(w, h) f.w, f.h = w, h end
    function f:SetWidth(w) f.w = w end
    function f:SetHeight(h) f.h = h end
    function f:GetWidth() return f.w end
    function f:SetPoint(...)
        local args = {}
        for i = 1, select("#", ...) do args[i] = select(i, ...) end
        f.point = args
    end
    function f:ClearAllPoints() end
    function f:SetAllPoints() end
    function f:SetScript(name, fn) f.scripts[name] = fn end
    function f:GetScript(name) return f.scripts[name] end
    function f:Hide() f.shown = false end
    function f:Show() f.shown = true end
    function f:SetShown(on) f.shown = on and true or false end
    function f:SetAlpha() end
    function f:CreateTexture()
        local t = newNode()
        t.kind = "texture"
        function t:SetColorTexture(r, g, b, a) t.colored = { r, g, b, a } end
        return t
    end
    function f:CreateFontString()
        local s = newNode()
        s.kind = "font"
        s.text = ""
        function s:SetText(v) s.text = v end
        function s:SetTextColor() end
        function s:SetWordWrap() end
        function s:SetJustifyH() end
        function s:GetStringWidth() return 48 end
        return s
    end
    return f
end

local function checkApply()
    local d = newDaylight(9)
    armApply(d, "set")
    local env, chat = loadLooks(d)
    local sheet = d.modules.Looks.options.pages[1].groups[2].items[1].sheet
    slash(env, "lintel")
    eq(#chat, 0, "apply lintel stays quiet")
    wrote(d, "UnitFrames", "look.style", "Looks:lintel", "lintel")
    eq(d.frame.parts.style, "Looks:lintel", "lintel is worn")
    eq(sheet.frameOn("lintel"), true, "lintel row is the current pick")
    eq(sheet.frameOn("sill"), false, "sill is not the current pick")
    slash(env, "wick")
    eq(#chat, 0, "apply wick stays quiet")
    wrote(d, "general", "buttonGlow", "Looks:wick", "wick buttons")
    wrote(d, "Nameplates", "targetLight", "Looks:wick", "wick outline")
    eq(sheet.glowOn("wick"), true, "wick row is the current pick")
    slash(env, "")
    eq(last(chat), LINTEL_WICK, "status follows the applied pair")
    local n = #d.writes
    slash(env, "hearthnight")
    eq(#chat, 1, "a preset that applies does not print the menu lines")
    wrote(d, "UnitFrames", "look.style", "Looks:lintel", "hearthnight frame")
    wrote(d, "general", "buttonGlow", "Looks:wick", "hearthnight glow")
    eq(sheet.frameOn("lintel"), true, "hearthnight highlights Lintel")
    eq(sheet.glowOn("wick"), true, "hearthnight highlights Wick")
    sheet.presets[5].apply()
    wrote(d, "UnitFrames", "look.style", "Looks:sill", "vigil frame")
    wrote(d, "general", "buttonGlow", "Looks:wick", "vigil glow")
    eq(sheet.frameOn("sill"), true, "vigil highlights Sill")
    local before = #chat
    slash(env, "off")
    eq(#chat, before, "Restore stays quiet when the write works")
    wrote(d, "UnitFrames", "look.style", "daylight", "restore frame")
    wrote(d, "general", "buttonGlow", "circle", "restore puts Circling back")
    wrote(d, "Nameplates", "targetLight", "none", "restore clears the outline")
    eq(d.frame.parts.style, "daylight", "Daylight is worn again")
    eq(sheet.frameOn("sill"), false, "no frame row stays highlighted")
    eq(sheet.glowOn("wick"), false, "no glow row stays highlighted")
    assertWrites(d, "apply")
    if n > #d.writes then fail("restore dropped writes") end

    local function prior(style, glow, light)
        local day = newDaylight(9)
        armApply(day, "set")
        day.settings["UnitFrames.look.style"] = style
        day.settings["general.buttonGlow"] = glow
        day.settings["Nameplates.targetLight"] = light
        day.frame.parts.style = style
        day.buttonGlow = glow
        day.targetLight = light
        return day, loadLooks(day)
    end

    local plain, plainEnv, plainChat = prior("ribbon", "comet", "shine")
    slash(plainEnv, "off")
    wrote(plain, "UnitFrames", "look.style", "daylight", "no snapshot, frame default")
    wrote(plain, "general", "buttonGlow", "circle", "no snapshot, glow default")
    wrote(plain, "Nameplates", "targetLight", "none", "no snapshot, outline default")
    eq(plain.frame.parts.style, "daylight", "Restore with no snapshot puts Daylight's frame back")
    eq(plain.buttonGlow, "circle", "Restore with no snapshot puts Circling back")
    eq(plain.targetLight, "none", "Restore with no snapshot clears the outline")
    eq(#plainChat, 0, "default restore stays quiet")
    slash(plainEnv, "lintel")
    slash(plainEnv, "off")
    eq(plain.settings["UnitFrames.look.style"], "daylight", "a restore does not snapshot the style it replaced")

    local kept, keptEnv, keptChat = prior("ribbon", "comet", "shine")
    slash(keptEnv, "lintel")
    slash(keptEnv, "wick")
    slash(keptEnv, "hearthnight")
    slash(keptEnv, "off")
    eq(#keptChat, 0, "snapshot restore stays quiet")
    eq(kept.settings["UnitFrames.look.style"], "ribbon", "restore puts the original frame back")
    eq(kept.settings["general.buttonGlow"], "comet", "restore puts the original glow back")
    eq(kept.settings["Nameplates.targetLight"], "shine", "restore puts the original outline back")
    eq(kept.frame.parts.style, "ribbon", "the worn frame follows the snapshot")
    eq(keptEnv.LooksDB.original, nil, "a successful restore clears the snapshot")
    assertWrites(kept, "snapshot")

    local again, envA = prior("ribbon", "comet", "shine")
    slash(envA, "lintel")
    eq(envA.LooksDB.original.frame, "ribbon", "the snapshot keeps the frame across the saved table")
    eq(envA.LooksDB.original.glow, "comet", "the snapshot keeps the glow across the saved table")
    eq(envA.LooksDB.original.light, "shine", "the snapshot keeps the outline across the saved table")
    local envB = loadLooks(again, envA.LooksDB)
    slash(envB, "off")
    eq(again.settings["UnitFrames.look.style"], "ribbon", "a reload still restores the frame")
    eq(again.settings["general.buttonGlow"], "comet", "a reload still restores the glow")
    eq(again.settings["Nameplates.targetLight"], "shine", "a reload still restores the outline")
    eq(envB.LooksDB.original, nil, "the reloaded restore clears the snapshot")
    slash(envB, "off")
    eq(again.settings["UnitFrames.look.style"], "daylight", "after the snapshot is cleared, restore uses Daylight")
    eq(again.settings["general.buttonGlow"], "circle", "after the snapshot is cleared, restore uses Circling")

    local stuck, envStuck, chatStuck = prior("ribbon", "comet", "shine")
    slash(envStuck, "lintel")
    local stuckSet = stuck.Set
    function stuck:Set(scope, path, value)
        if scope == "general" or scope == "Nameplates" then return false end
        return stuckSet(self, scope, path, value)
    end
    slash(envStuck, "off")
    eq(last(chatStuck), "Looks: pick comet in the glow menu.", "a failed glow restore names the saved glow")
    eq(type(envStuck.LooksDB.original), "table", "a failed glow restore keeps the snapshot")

    local half = newDaylight(9)
    armApply(half, "set")
    local halfSet = half.Set
    function half:Set(scope, path, value)
        if scope == "Nameplates" then return false end
        return halfSet(self, scope, path, value)
    end
    local envHalf, chatHalf = loadLooks(half)
    slash(envHalf, "wick")
    eq(last(chatHalf), PICK_WICK, "a glow apply reports success only when both settings stick")
    eq(half.buttonGlow, "Looks:wick", "the button glow still writes")
    eq(half.targetLight, "none", "the outline stayed put")
    eq(envHalf.LooksDB.original.glow, "circle", "a partial glow write still keeps the snapshot")

    local row = newNode()
    env.CreateFrame = function(kind)
        local f = newNode()
        f.kind = kind
        return f
    end
    local body = d.modules.Looks.options.pages[1].groups[2].items[1]
    body.build(row)
    if type(row.lines) ~= "table" or #row.lines < 10 then
        fail("the page did not build a select row for every style")
    end
    d.frame.parts.style = "Looks:lintel"
    d.buttonGlow = "Looks:wick"
    body.update(row)
    local lintel, wick
    for i = 1, #row.lines do
        if row.lines[i].id == "lintel" then lintel = row.lines[i] end
        if row.lines[i].id == "wick" then wick = row.lines[i] end
    end
    eq(lintel.selected, true, "built row highlights the worn frame")
    eq(wick.selected, true, "built row highlights the worn glow")
    eq(row.presetHead.text, "PRESETS", "the page draws the PRESETS label")
    eq(row.note.point[1], "TOPRIGHT", "the note is right-aligned")
    eq(row.note.point[5], 22, "the note sits on the Presets & Styles title row")
    eq(row.presets[1].hold.card, true, "a preset row is a card")
    eq(row.presets[1].hold.h, 80, "a preset card keeps padding")
    eq(lintel.name.point[1], "LEFT", "the frame name sits on the row")
    eq(lintel.desc.point[1], "LEFT", "the description sits on the same line")
    local beforeClick = #d.writes
    lintel.box.scripts.OnClick()
    if #d.writes <= beforeClick then fail("clicking the select box did not apply") end
    wrote(d, "UnitFrames", "look.style", "Looks:lintel", "select box")

    local missing = newDaylight(9)
    local envMissing, chatMissing = loadLooks(missing)
    local sheetMissing = missing.modules.Looks.options.pages[1].groups[2].items[1].sheet
    local ok = pcall(function() sheetMissing.frames[4].select() end)
    if not ok then fail("missing setter threw from the select box") end
    eq(last(chatMissing), "Looks: pick Trestle in the Frame style menu.", "missing setter falls back")
    noWrites(missing, "missing setter")

    local boom = newDaylight(9)
    armApply(boom, "throw")
    local envBoom, chatBoom = loadLooks(boom)
    local okBoom = pcall(function() slash(envBoom, "flagon") end)
    if not okBoom then fail("a failing write escaped /looks") end
    eq(last(chatBoom), "Looks: pick Flagon in the Frame style menu.", "a failing write falls back")

    local refused = newDaylight(9)
    armApply(refused, "refuse")
    local envRefused, chatRefused = loadLooks(refused)
    slash(envRefused, "signboard")
    eq(last(chatRefused), "Looks: pick Signboard in the Frame style menu.", "a refused write falls back")
    noWrites(refused, "refused write")
    eq(envRefused.LooksDB, nil, "a refused write does not take a snapshot")

    local menu = newDaylight(9)
    armApply(menu, "menu")
    function menu:Set()
        menu.writes[#menu.writes + 1] = { scope = "Set", path = "called", value = true }
        return true
    end
    local envMenu, chatMenu = loadLooks(menu)
    slash(envMenu, "trough")
    eq(#chatMenu, 0, "the menu path stays quiet")
    eq(menu.menu.path, "look.style", "menu path writes look.style")
    eq(menu.menu.value, "Looks:trough", "menu path writes the Looks key")
    eq(menu.frame.parts.style, "Looks:trough", "menu path wears Trough")
    noWrites(menu, "menu path does not also call Set")

    local noop = newDaylight(9)
    armApply(noop, "menu-noop")
    local envNoop = loadLooks(noop)
    slash(envNoop, "stamp")
    wrote(noop, "UnitFrames", "look.style", "Looks:stamp", "menu noop falls through to Set")
    assertWrites(noop, "menu noop")
end

checkToc()
checkSource()
checkFresh()
checkNoFrameYet()
checkPluginOff()
checkTooOld(8, "API 1.8")
checkTooOld(0, "API 1.0")
checkMissing()
checkSetter()
checkApply()

if fails > 0 then
    io.stderr:write("looks_check: " .. fails .. " failed\n")
    os.exit(1)
end
print("looks_check: ok")
