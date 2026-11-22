-- Looks (DaylightUI Plugin), P1. Three frame styles for Daylight UI.
-- Daylight's public API can register a style (AddFrameStyle) and can say which
-- style a frame wears (Parts.style). It has no call that selects one. The
-- private write is ns.SetStyle in DaylightUI_UnitFrames, which saves UnitFrames
-- settings. This file never calls that, and never writes those settings.

local PAGE = "Add frame styles and glow styles to Daylight. Colors stay in Palettes for DaylightUI, or in Daylight if Palettes for DaylightUI is off."
local TOO_OLD = "Looks: Daylight UI is missing the settings Looks needs, so no frame or glow styles were added."

local STYLES = {
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

local ready = false
local view
-- While not ready, slash repeats this instead of offering the styles.
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

local function styleById(id)
    for i = 1, #STYLES do
        if STYLES[i].id == id then return STYLES[i] end
    end
end

local function joinOr(list)
    if #list == 0 then return "" end
    if #list == 1 then return list[1] end
    local head = {}
    for i = 1, #list - 1 do head[i] = list[i] end
    return table.concat(head, ", ") .. ", or " .. list[#list]
end

-- The player frame's style, read through the public parts table.
-- "player" in a raid is the raid tile, which Daylight keeps on its own style.
local function wornId()
    local d = DaylightUI
    local api = type(d) == "table" and d.API
    if type(api) ~= "table" or type(api.GetUnitFrame) ~= "function" or type(api.Parts) ~= "function" then
        return nil
    end
    local ok, frame = pcall(api.GetUnitFrame, "player")
    if not ok or type(frame) ~= "table" then return nil end
    local okParts, parts = pcall(api.Parts, frame)
    if not okParts or type(parts) ~= "table" or type(parts.style) ~= "string" then return nil end
    local prefix = "Looks:"
    if string.sub(parts.style, 1, #prefix) ~= prefix then return nil end
    local found = styleById(string.sub(parts.style, #prefix + 1))
    if found then return found.id, found.name end
end

local function hintLine(id, name)
    local names = {}
    for i = 1, #STYLES do
        if STYLES[i].id ~= id then names[#names + 1] = STYLES[i].id end
    end
    names[#names + 1] = "off"
    if id then
        return "Looks: " .. name .. " is on. Type /looks " .. joinOr(names) .. "."
    end
    return "Looks: off. Type /looks " .. joinOr(names) .. "."
end

local function statusLine()
    local id, name = wornId()
    return hintLine(id, name)
end

-- A documented setter would be me.SetFrameStyle or API.SetFrameStyle.
-- Neither exists in API 1.9. Do not fall through to DaylightUI:Set.
local function setter()
    if type(view) == "table" and type(view.SetFrameStyle) == "function" then
        return function(key) view.SetFrameStyle(key) end
    end
    local api = type(DaylightUI) == "table" and DaylightUI.API
    if type(api) == "table" and type(api.SetFrameStyle) == "function" then
        return function(key)
            if key == "daylight" then api.SetFrameStyle("daylight") else api.SetFrameStyle("Looks:" .. key) end
        end
    end
end

local function pointAtMenu(id)
    if id == "daylight" then
        say("Looks: pick Daylight in the Frame style menu.")
        return
    end
    local found = styleById(id)
    say("Looks: pick " .. (found and found.name or id) .. " in the Frame style menu.")
end

local function applyStyle(id)
    local set = setter()
    if set then
        set(id)
        return
    end
    pointAtMenu(id)
end

local function restore()
    if not ready then
        say(refused or TOO_OLD)
        return
    end
    applyStyle("daylight")
end

local function slash(msg)
    if not ready then
        say(refused or TOO_OLD)
        return
    end
    local arg = string.lower(trim(msg or ""))
    if arg == "" then
        say(statusLine())
        return
    end
    if string.find(arg, "%s") then
        say(statusLine())
        return
    end
    if arg == "off" then
        restore()
        return
    end
    if not styleById(arg) then
        say(statusLine())
        return
    end
    applyStyle(arg)
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
    -- plugin.off is Daylight's own answer when `needs` is not met.
    if type(plugin) ~= "table" or plugin.off then
        refuse(TOO_OLD)
        return
    end

    local api = d.API
    view = type(api.For) == "function" and api.For("Looks") or nil
    if type(view) ~= "table" or type(view.AddFrameStyle) ~= "function" then
        refuse(TOO_OLD)
        return
    end

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
                        {
                            label = "Frame styles",
                            items = {
                                { type = "text", label = "Lintel. A named beam over a solid bar." },
                                { type = "text", label = "Sill. The name tab stays; power sits as a thin sill under the bar." },
                                { type = "text", label = "Stamp. A tight name row and a thin power line, ring kept small." },
                                { type = "button", label = "Restore Daylight look", text = "Restore", func = restore },
                            },
                        },
                    },
                },
            },
        },
    })

    for i = 1, #STYLES do
        view.AddFrameStyle(STYLES[i].id, STYLES[i].spec)
    end
    ready = true
end

if type(SlashCmdList) == "table" then
    SLASH_LOOKS1 = "/looks"
    SlashCmdList.LOOKS = function(msg)
        if not pcall(slash, msg) then
            say("Looks: something went wrong, and no frame style was changed.")
        end
    end
end

if not pcall(boot) then
    ready = false
    refuse("Looks: couldn't start, so no frame styles were added.")
end
