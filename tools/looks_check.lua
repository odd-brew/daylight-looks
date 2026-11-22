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
    local modules = {}
    local plugins = {}
    local writes = {}
    local frame = { parts = { style = "daylight" } }
    local api = {
        major = 1,
        minor = minor,
        GetUnitFrame = function(unit)
            if unit == "player" then return frame end
        end,
        Parts = function(f) return f.parts end,
        For = function(name)
            return {
                AddFrameStyle = function(key, spec)
                    styles[#styles + 1] = { owner = name, id = key, key = name .. ":" .. key, spec = spec }
                    return true
                end,
            }
        end,
    }
    local d = { API = api, styles = styles, modules = modules, plugins = plugins, writes = writes, frame = frame }
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

local OFF = "Looks: off. Type /looks lintel, sill, stamp, or off."
local LINTEL_ON = "Looks: Lintel is on. Type /looks sill, stamp, or off."
local SILL_ON = "Looks: Sill is on. Type /looks lintel, stamp, or off."
local STAMP_ON = "Looks: Stamp is on. Type /looks lintel, sill, or off."
local TOO_OLD = "Looks: Daylight UI is missing the settings Looks needs, so no frame or glow styles were added."
local PICK_LINTEL = "Looks: pick Lintel in the Frame style menu."
local PICK_SILL = "Looks: pick Sill in the Frame style menu."
local PICK_STAMP = "Looks: pick Stamp in the Frame style menu."
local PICK_DAYLIGHT = "Looks: pick Daylight in the Frame style menu."

local function checkToc()
    local toc = readFile("Looks/Looks.toc")
    local function has(line)
        if not string.find(toc, line, 1, true) then fail("toc missing " .. line) end
    end
    has("## Interface: 16001")
    has("## Title: Looks (DaylightUI Plugin)")
    has("## Author: odd-brew")
    has("## Version: 0.1.0")
    has("## Dependencies: DaylightUI")
    if string.find(toc, "SavedVariables", 1, true) then
        fail("toc must not own SavedVariables; settings stay in the Looks module")
    end
end

local function checkSource()
    local src = readFile("Looks/Looks.lua")
    local banned = { ":Set(", "Override", "Paint", "healthFill", "powerFill", "windowTint", "AddGlowStyle", "GetSetting" }
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
    eq(d.frame.parts.style, "daylight", "fresh install leaves the frame on Daylight")
    noWrites(d, "fresh install")
    eq(d.plugins[1].name, "Looks", "plugin name")
    eq(d.plugins[1].spec.needs[1], 1, "needs major")
    eq(d.plugins[1].spec.needs[2], 9, "needs minor")
    eq(d.plugins[1].spec.short, "Looks", "short name")
    eq(d.plugins[1].off, false, "plugin starts available")
    local page = d.modules.Looks.options.pages[1]
    eq(page.label, "Looks", "page title")
    eq(page.desc, "Add frame styles and glow styles to Daylight. Colors stay in Palettes, or in Daylight if Palettes is off.", "page desc")
    local button = page.groups[1].items[4]
    eq(button.text, "Restore", "button text")
    eq(button.label, "Restore Daylight look", "button meaning")
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
    eq(last(chat), OFF, "unknown word reprints the off line")
    slash(env, "off")
    eq(last(chat), PICK_DAYLIGHT, "off is Restore")
    noWrites(d, "Restore")
    eq(d.frame.parts.style, "daylight", "Restore did not write a style")
    button.func()
    eq(last(chat), PICK_DAYLIGHT, "Restore button")
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
    local applied
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
        return v
    end
    local env, chat = loadLooks(d)
    slash(env, "lintel")
    eq(applied, "lintel", "public setter receives lintel")
    eq(#chat, 0, "a real setter does not print the menu line")
    eq(d.frame.parts.style, "Looks:lintel", "setter updated the worn style")
    noWrites(d, "setter path")
    slash(env, "")
    eq(last(chat), LINTEL_ON, "after the setter, status says Lintel")
    slash(env, "off")
    eq(applied, "daylight", "Restore uses the setter")
    eq(d.frame.parts.style, "daylight", "Restore put Daylight back")
    eq(last(chat), LINTEL_ON, "Restore from slash stays quiet when the setter works")
    -- The last chat line is still the status line from before Restore.
    local page = d.modules.Looks.options.pages[1]
    local before = #chat
    page.groups[1].items[4].func()
    eq(#chat, before, "Restore button stays quiet when the setter works")
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
