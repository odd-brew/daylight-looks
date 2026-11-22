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

local function loadLooks(daylight)
    local env = {
        DaylightUI = daylight,
        SlashCmdList = {},
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
    function d:Set(scope, path, value)
        writes[#writes + 1] = { scope = scope, path = path, value = value }
    end
    return d
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

local OFF = "Looks: off. Type /looks lintel, sill, stamp, wick, draught, latch, or off."
local LINTEL_ON = "Looks: Lintel is on. Type /looks sill, stamp, wick, draught, latch, or off."
local SILL_ON = "Looks: Sill is on. Type /looks lintel, stamp, wick, draught, latch, or off."
local STAMP_ON = "Looks: Stamp is on. Type /looks lintel, sill, wick, draught, latch, or off."
local WICK_ON = "Looks: Wick is on. Type /looks lintel, sill, stamp, draught, latch, or off."
local DRAUGHT_ON = "Looks: Draught is on. Type /looks lintel, sill, stamp, wick, latch, or off."
local LATCH_ON = "Looks: Latch is on. Type /looks lintel, sill, stamp, wick, draught, or off."
local LINTEL_WICK = "Looks: Lintel is on. Type /looks sill, stamp, draught, latch, or off."
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
    if string.find(toc, "SavedVariables", 1, true) then
        fail("toc must not own SavedVariables; settings stay in the Looks module")
    end
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
    eq(#d.styles, 3, "three styles registered")
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
    local button = page.groups[1].items[4]
    eq(button.text, "Restore", "button text")
    eq(button.label, "Restore Daylight look", "button meaning")
    eq(page.groups[2].label, "Glow styles", "glow group")
    eq(page.groups[2].items[1].label, "Wick. A quiet flame gathers at the corners.", "wick mood")
    eq(page.groups[2].items[2].label, "Draught. A soft wash along the rim.", "draught mood")
    eq(page.groups[2].items[3].label, "Latch. A short catch of light, then still.", "latch mood")
    eq(page.groups[2].items[4].label, GLOW_HINT, "accent hint")
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
    button.func()
    eq(chat[beforeButton + 1], PICK_DAYLIGHT, "Restore button, frame")
    eq(chat[beforeButton + 2], PICK_NONE, "Restore button, glow")
    noWrites(d, "Restore button")

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
    eq(applied, "daylight", "Restore uses the frame setter")
    eq(glowApplied, "none", "Restore uses the glow setter")
    eq(d.frame.parts.style, "daylight", "Restore put Daylight back")
    eq(d.buttonGlow, "circle", "Restore cleared the Looks glow")
    eq(last(chat), LINTEL_WICK, "Restore from slash stays quiet when the setters work")
    local page = d.modules.Looks.options.pages[1]
    local before = #chat
    page.groups[1].items[4].func()
    eq(#chat, before, "Restore button stays quiet when the setters work")
    noWrites(d, "setter restore")
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

if fails > 0 then
    io.stderr:write("looks_check: " .. fails .. " failed\n")
    os.exit(1)
end
print("looks_check: ok")
