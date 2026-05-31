script_name("Ghetto Discord Assistant")
script_version("10.1")
script_author("Casual Alvarez")
script_description("Капт хелпер")

require "lib.moonloader"
require "lib.sampfuncs"

local sampev   = require("lib.samp.events")
local encoding = require("encoding")
local bit      = require("bit")
local imgui    = require("imgui")
local effil    = require("effil")

encoding.default = "CP1251"
u8 = encoding.UTF8

local function cp1251_to_utf8(str)
    return tostring(u8(str or ""))
end

local function utf8_to_cp1251(str)
    return u8:decode(tostring(str or ""))
end

local function stripZeroBytes(str)
    return tostring(str or ""):gsub("%z", "")
end

local function sanitizeWebhookUrl(str)
    str = stripZeroBytes(str)
    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    return str
end

local APP = {}
local UI = {}
local CFG = {}
local PATHS = {}
local COLORS = {}
local DATA = {}
local CONST = {}
local BUFF = {}
local BOOLS = {}
local INTS = {}
local STATE = {}
local FOLLOW = {}
local GANGS = {}
local ADMIN_KEYWORDS = {}
local WEAPON_NAMES = {}
local STREAK_MESSAGES = {}
local THREADS = {
    active = {},
    shuttingDown = false,
    nextId = 0
}

APP.ffi = require("ffi")
APP.memory = require("memory")
APP.moonloaderRuntime = require("moonloader")
APP.fontFlag = APP.moonloaderRuntime.font_flag or {
    NONE = 0x0,
    BOLD = 0x1,
    ITALICS = 0x2,
    BORDER = 0x4,
    SHADOW = 0x8,
    UNDERLINE = 0x10,
    STRIKEOUT = 0x20
}
APP.getBonePositionFn = APP.ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)

APP.ffi.cdef[[
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);
]]

PATHS.BASE_DIR                   = getWorkingDirectory() .. "\\ghetto_discord_assistant\\"
PATHS.MAIN_SETTINGS_FILE         = PATHS.BASE_DIR .. "main.ini"
PATHS.FRAG_SETTINGS_FILE         = PATHS.BASE_DIR .. "fraglist.ini"
PATHS.PUNISH_SETTINGS_FILE       = PATHS.BASE_DIR .. "punishments.ini"
PATHS.ONLINE_SETTINGS_FILE       = PATHS.BASE_DIR .. "online.ini"
PATHS.BANTACHKA_SETTINGS_FILE    = PATHS.BASE_DIR .. "bantachka.ini"
PATHS.PRIORITY_SETTINGS_FILE     = PATHS.BASE_DIR .. "priority.ini"
PATHS.FOLLOW_SETTINGS_FILE       = PATHS.BASE_DIR .. "follow.ini"
PATHS.STATS_FILE                 = PATHS.BASE_DIR .. "kill_stats_db.txt"
PATHS.LOG_FILE                   = PATHS.BASE_DIR .. "kill_log.txt"
PATHS.CAPTURE_LOG                = PATHS.BASE_DIR .. "capture_log.txt"
PATHS.PUNISH_LOG                 = PATHS.BASE_DIR .. "punishments_log.txt"
PATHS.CAPTURE_SESSIONS_FILE      = PATHS.BASE_DIR .. "capture_sessions.txt"
PATHS.ACTIVE_CAPTURE_STATE_FILE  = PATHS.BASE_DIR .. "capture_recovery.txt"
PATHS.LAST_CAPTURE_STATE_FILE    = PATHS.BASE_DIR .. "last_capture_state.txt"
PATHS.PENDING_CAPTURE_STATE_FILE = PATHS.BASE_DIR .. "pending_capture_state.txt"
PATHS.DISCORD_DEBUG_LOG          = PATHS.BASE_DIR .. "discord_debug.log"
PATHS.CAPTURE_IGNORE_NICKS_FILE  = PATHS.BASE_DIR .. "pe4enitos.txt"
PATHS.UPDATER_TEMP_FILE          = PATHS.BASE_DIR .. "CaptureDiscordAssistant.update.tmp.lua"

COLORS.SCRIPT_TAG = "[Ghetto Discord Assistant]"
COLORS.CHAT_COLOR = 0xFFFFFFFF
COLORS.WHITE      = "{FFFFFF}"
COLORS.ACCENT     = "{6FA8FF}"
COLORS.PURPLE     = "{C77DFF}"
COLORS.RED        = "{FF3B3B}"
COLORS.GREEN      = "{00FF00}"
COLORS.GOLD       = "{FFD700}"
COLORS.ERROR      = "{FF5555}"
COLORS.LINE       = "{6FA8FF}"
COLORS.INFO       = COLORS.ACCENT
COLORS.BLUE       = COLORS.ACCENT

CONST.LINE_TEXT                = "========================================"
CONST.SCRIPT_VERSION           = "10.1"
CONST.UPDATER_REPO_URL         = "https://github.com/ameskrillex/ghetto-helper-arp"
CONST.UPDATER_SCRIPT_URL       = "https://raw.githubusercontent.com/ameskrillex/ghetto-helper-arp/main/CaptureDiscordAssistant.lua"
CONST.UPDATER_VERSION_URL      = "https://raw.githubusercontent.com/ameskrillex/ghetto-helper-arp/main/version.json"
CONST.UPDATER_COMMAND          = "ghettoupdate"
CONST.SESSION_SEPARATOR        = "================================="
CONST.MAX_RECOVERY_AGE_SECONDS = 4 * 60 * 60
CONST.STREAK_WINDOW_SECONDS    = 7 * 60
CONST.STREAK_MAX_ANNOUNCE      = 10
CONST.MAX_PLAYER_ID            = 1003
CONST.MAX_DEATH_EVENTS_PER_TICK = 20
CONST.DISCORD_CHUNK_SEND_DELAY_MS = 1100
CONST.DISCORD_SENDING_DISABLED = false
CONST.CAPTURE_DISCORD_SAFE_MODE = false
CONST.CAPTURE_DISCORD_MAX_TAIL_SECONDS = 20
CONST.ONLINE_INITIAL_WARMUP_SECONDS = 6.0
CONST.ONLINE_PREPARE_RETRY_MS = 900
CONST.ONLINE_PREPARE_MAX_WAIT_SECONDS = 6.0
CONST.ONLINE_MONOCOLOR_GUARD_MIN_PLAYERS = 5
CONST.ONLINE_SEND_GUARD_SECONDS = 4.0
CONST.INVALID_PLAYER_ID = 65535
CONST.INVALID_VEHICLE_ID = 65535
CONST.LONG_RANGE_LABEL_DISTANCE = 1000.0
CONST.LONG_RANGE_LABEL_FORCE_WALLHACK = true
CONST.LONG_RANGE_LABEL_ONLY_ATTACHED = true
CONST.CUSTOM_NAMETAGS_MAX_DISTANCE = 1488.0
CONST.CUSTOM_NAMETAGS_FONT_NAME = "Arial"
CONST.CUSTOM_NAMETAGS_FONT_SIZE = 10
CONST.CUSTOM_NAMETAGS_FONT_FLAGS = APP.fontFlag.BOLD + APP.fontFlag.BORDER
CONST.CUSTOM_NAMETAGS_FONT_CHARSET = 204
CONST.CUSTOM_NAMETAGS_UPDATE_PATCH_DELAY = 500
CONST.CUSTOM_NAMETAGS_TEXT_DEFAULT_COLOR = 0xFFFFB347
CONST.CUSTOM_NAMETAGS_HP_BAR_ENABLED = true
CONST.CUSTOM_NAMETAGS_HP_BAR_WIDTH_MIN = 52.0
CONST.CUSTOM_NAMETAGS_HP_BAR_HEIGHT = 5.0
CONST.CUSTOM_NAMETAGS_HP_BAR_SPACING = 2.0
CONST.CUSTOM_NAMETAGS_HP_BAR_BORDER_COLOR = 0xFF111111
CONST.CUSTOM_NAMETAGS_HP_BAR_BACKGROUND_COLOR = 0xC0202020
CONST.CUSTOM_NAMETAGS_HP_BAR_FILL_COLOR = 0xFFD94A3A
CONST.CUSTOM_NAMETAGS_ARMOR_BAR_ENABLED = true
CONST.CUSTOM_NAMETAGS_ARMOR_BAR_HEIGHT = 4.0
CONST.CUSTOM_NAMETAGS_ARMOR_BAR_SPACING = 2.0
CONST.CUSTOM_NAMETAGS_ARMOR_BAR_BORDER_COLOR = 0xFF111111
CONST.CUSTOM_NAMETAGS_ARMOR_BAR_BACKGROUND_COLOR = 0xC0202020
CONST.CUSTOM_NAMETAGS_ARMOR_BAR_FILL_COLOR = 0xFF69D7FF
CONST.CUSTOM_NAMETAGS_SERVER_OFFSETS = {
    draw_distance = 0x27,
    wallhack = 0x2F,
    show_nametags = 0x38
}
CONST.CUSTOM_NAMETAGS_RENDER_NICK_HOOK_OFFSET = 0x70F4E
CONST.CUSTOM_NAMETAGS_DRAW_HEALTH_BAR_OFFSET = 0x6FC30
CONST.CUSTOM_NAMETAGS_PAGE_EXECUTE_READWRITE = 0x40
CONST.SKELETAL_DISTANCE = 1488.0
CONST.SKELETAL_BONE_SEGMENTS = {
    {2, 3},
    {3, 4},
    {4, 5},
    {5, 51},
    {51, 52},
    {3, 31},
    {31, 32},
    {32, 33},
    {3, 41},
    {41, 42},
    {42, 43},
    {2, 21},
    {21, 22},
    {22, 23}
}

CFG.main = {
    gui_hotkey_vk = 0x77,
    developer_mode = false,
    save_stats = true,
    local_chat_feed = true,
    streak_alerts = true,
    long_range_labels_enabled = false,
    custom_nametags_enabled = false,
    skeletal_enabled = false,
    max_top_players = 10,
    discord_time_offset_minutes = 0,
    capture_overlay_enabled = true,
    capture_overlay_x = 22,
    capture_overlay_y = 120,
    capture_overlay_width = 420,
    capture_overlay_height = 360,
    capture_overlay_gap = 48,
    capture_top_overlay_enabled = true,
    capture_top_overlay_x = 520,
    capture_top_overlay_y = 120
}
CFG.fraglist = {
    webhook_url = "",
    send_summary = true,
    send_top = true,
    send_details = true,
    embed_color = 16729344,
    show_status_messages_in_chat = true,
    show_kills_in_chat = true
}
CFG.punishments = {
    webhook_url = "",
    enabled = true,
    embed_color = 15158332,
    show_success_in_chat = true
}
CFG.online = {
    webhook_url = "",
    embed_color = 16729344,
    auto_send_on_capture_start = true
}
CFG.bantachka = {
    accounts_serialized = ""
}
CFG.priority = {
    enabled = false,
    admins_serialized = "",
    ask_confirmation = true
}
CFG.follow = {
    enabled = false,
    hotkey_vk = 0x48,
    use_ctrl = false,
    use_alt = false,
    use_shift = false,
    prompt_seconds = 8,
    command_template = "/sp %d"
}

DATA.stats = {}
DATA.streaks = {}
DATA.sessionKills = 0
DATA.lastCapture = nil
DATA.pendingCaptureToSend = nil
DATA.recoveryFileInfo = nil
DATA.overlayTestActive = false
DATA.overlayTestEntries = {}
DATA.overlayTestRefreshAt = 0
DATA.pendingDeathEvents = {}
DATA.captureTopOverlayEntries = {}
DATA.playerNamesById = {}
DATA.onlinePlayersById = {}
DATA.playerColorsById = {}
DATA.playerColorSourceById = {}
DATA.captureIgnoreNicks = {}
DATA.captureIgnoreReloadAt = 0
DATA.dialog66WhiteScan = {
    active = false,
    pages = 0,
    nicks = {},
    order = {},
    greenNicks = {}
}
DATA.onlineSnapshotRefreshAt = 0
DATA.onlineWarmupUntil = 0
DATA.onlineColorEventCount = 0
DATA.onlineStatsStabilized = false
DATA.onlineStatsCollectActive = false
DATA.onlineStatsCollectCallbacks = {}
DATA.onlineSendGuardUntil = 0
DATA.deferredCaptureAutoSend = nil
DATA.discordLastStatusText = ""
DATA.discordLastErrorText = ""
DATA.discordDisabledNoticeShown = false
DATA.scriptTerminating = false
DATA.captureDiscordClosed = false
DATA.captureDiscordDeadline = 0
DATA.postCaptureMuted = false
DATA.discordPendingRequests = 0
DATA.discordSequenceWorkers = 0
DATA.forceUnloadAfterDiscord = false
DATA.forceUnloadScheduled = false
DATA.pendingSelfReload = false
DATA.updater = {
    checking = false,
    downloading = false,
    updateAvailable = false,
    latestVersion = "",
    latestScriptUrl = "",
    changelog = "",
    lastError = "",
    lastCheckedAt = 0
}
DATA.customNametags = {
    active = false,
    font = nil,
    originalSettings = nil,
    lastPatchTime = 0,
    renderNickCallAddr = nil,
    renderNickOriginalRel = nil,
    renderNickCallback = nil,
    renderNickHookInstalled = false,
    drawHealthBarAddr = nil,
    drawHealthBarOriginalByte = nil,
    drawHealthBarPatchInstalled = false
}
DATA.skeletal = {
    active = false
}

STATE.capture = {
    active = false,
    startAt = 0,
    startDt = "",
    startLine = "",
    initiatorLine = "",
    endLine = "",
    kills = {},
    stats = {},
    total = 0,
    participants = {},
    deadPlayers = {},
    overlayEntries = {},
    overlayRefreshAt = 0,
    onlineSent = false,
    manualAssistMode = false,
    sendLogsOnFinish = true,
    punishLogging = false,
    punishes = {},
    bantachkaNotified = false
}

FOLLOW.prompt = {
    active = false,
    killerId = -1,
    killerName = "",
    expireAt = 0
}
FOLLOW.hotkeyLatch = false

UI.window_state = imgui.ImBool(false)
UI.active_tab = 0
UI.webhookEdit = {
    frag = false,
    punish = false,
    online = false
}
imgui.Process = false

GANGS.list = {
    { key = "ballas",  color = 0xFFCC00FF, name = "BALLAS", display = "The Ballas",
      keywords = {"ballas", "Ballas", "BALLAS", "баллас", "Баллас", "БАЛЛАС", "балас", "Балас", "БАЛАС"} },
    { key = "grove",   color = 0xFF009900, name = "GROVE", display = "Grove Street",
      keywords = {"grove", "Grove", "GROVE", "грув", "Грув", "ГРУВ"} },
    { key = "vagos",   color = 0xFFFFCD00, name = "VAGOS", display = "Los Santos Vagos",
      keywords = {"vagos", "Vagos", "VAGOS", "вагос", "Вагос", "ВАГОС"} },
    { key = "rifa",    color = 0xFF6666FF, name = "RIFA", display = "The Rifa",
      keywords = {"rifa", "Rifa", "RIFA", "рифа", "Рифа", "РИФА"} },
    { key = "aztecas", color = 0xFF00CCFF, name = "AZTEC", display = "Varios Loz Aztecas",
      keywords = {"aztec", "Aztec", "AZTEC", "aztecas", "Aztecas", "AZTECAS", "ацтек", "Ацтек", "АЦТЕК", "varios loz aztecas", "Varios Loz Aztecas"} }
}

ADMIN_KEYWORDS.list = {
    "Администратор",
    "администратор",
    "АДМИНИСТРАТОР",
    "Administrator",
    "administrator",
    "ADMINISTRATOR"
}

WEAPON_NAMES.map = {
    [0] = "кулак", [1] = "кастет", [2] = "клюшка", [3] = "дубинка", [4] = "нож",
    [5] = "бита", [6] = "лопата", [7] = "кий", [8] = "катана", [9] = "бензопила",
    [10] = "фиолетовый дилдо", [11] = "белый дилдо", [12] = "короткий вибратор",
    [13] = "длинный вибратор", [14] = "цветы", [15] = "трость", [16] = "граната",
    [17] = "слезоточивый газ", [18] = "коктейль молотова", [22] = "Colt 45",
    [23] = "Silenced", [24] = "Deagle", [25] = "Shotgun", [26] = "Sawn-Off",
    [27] = "SPAS-12", [28] = "UZI", [29] = "MP5", [30] = "AK-47", [31] = "M4",
    [32] = "TEC-9", [33] = "Rifle", [34] = "Sniper Rifle", [35] = "Rocket Launcher",
    [36] = "Heat-Seeking RPG", [37] = "Flamethrower", [38] = "Minigun",
    [39] = "Satchel Charge", [40] = "Detonator", [41] = "Spraycan",
    [42] = "Fire Extinguisher", [43] = "Camera", [44] = "Night Vision",
    [45] = "Thermal Goggles", [46] = "Parachute", [49] = "удар транспортом",
    [50] = "вертолёт", [51] = "взрыв", [53] = "утопление", [54] = "падение"
}

STREAK_MESSAGES.map = {
    [2] = "[!] УЖЕ ДВА ФРАГА [!]",
    [3] = "[!] УЖЕ ТРИ ФРАГА [!]",
    [4] = "[!] УЖЕ ЧЕТЫРЕ ФРАГА [!]",
    [5] = "[!] УЖЕ ПЯТЬ ФРАГОВ [!]",
    [6] = "[!] УЖЕ ШЕСТЬ ФРАГОВ [!]",
    [7] = "[!] УЖЕ СЕМЬ ФРАГОВ [!]",
    [8] = "[!] УЖЕ ВОСЕМЬ ФРАГОВ [!]",
    [9] = "[!] УЖЕ ДЕВЯТЬ ФРАГОВ [!]",
    [10] = "[!] УЖЕ ДЕСЯТЬ ФРАГОВ [!]"
}

local function chat(text, color)
    sampAddChatMessage(utf8_to_cp1251(text), color or COLORS.CHAT_COLOR)
end

local function chatInfo(text)
    chat(COLORS.ACCENT .. COLORS.SCRIPT_TAG .. COLORS.WHITE .. " " .. text)
end

local function chatError(text)
    chat(COLORS.ERROR .. COLORS.SCRIPT_TAG .. COLORS.WHITE .. " " .. text)
end

local function chatSuccess(text)
    chat(COLORS.GREEN .. "[УСПЕХ]" .. COLORS.WHITE .. " " .. text)
end

local function ensureDir(path)
    if not doesDirectoryExist(path) then
        createDirectory(path)
    end
end

local function registerManagedThread(threadObj)
    if not threadObj then
        return nil
    end

    THREADS.nextId = tonumber(THREADS.nextId or 0) + 1
    local id = THREADS.nextId
    THREADS.active[id] = threadObj
    return id
end

local function unregisterManagedThread(threadId)
    if threadId ~= nil then
        THREADS.active[threadId] = nil
    end
end

local function isCaptureDiscordTailExpired()
    local deadline = tonumber(DATA.captureDiscordDeadline) or 0
    return deadline > 0 and os.clock() > deadline
end

local function tryUnloadAfterDiscordFlush()
    if DATA.scriptTerminating or not DATA.forceUnloadAfterDiscord or DATA.forceUnloadScheduled then
        return
    end

    if (tonumber(DATA.discordPendingRequests) or 0) > 0 then
        return
    end

    if (tonumber(DATA.discordSequenceWorkers) or 0) > 0 then
        return
    end

    DATA.forceUnloadScheduled = true
    DATA.pendingSelfReload = true
end

local function finishDiscordRequest()
    DATA.discordPendingRequests = math.max(0, (tonumber(DATA.discordPendingRequests) or 0) - 1)
    tryUnloadAfterDiscordFlush()
end

local function finishDiscordSequenceWorker()
    DATA.discordSequenceWorkers = math.max(0, (tonumber(DATA.discordSequenceWorkers) or 0) - 1)
    tryUnloadAfterDiscordFlush()
end

local function enterPostCaptureQuietMode()
    DATA.postCaptureMuted = true
    DATA.overlayTestActive = false
    DATA.overlayTestEntries = {}
    DATA.overlayTestRefreshAt = 0
    DATA.deferredCaptureAutoSend = nil
    DATA.pendingCaptureToSend = nil
    DATA.onlineStatsCollectActive = false
    DATA.onlineStatsCollectCallbacks = {}
    STATE.capture.overlayRefreshAt = 0
    FOLLOW.prompt.active = false
    FOLLOW.prompt.killerId = -1
    FOLLOW.prompt.killerName = ""
    FOLLOW.prompt.expireAt = 0
end

local function trim(text)
    text = tostring(text or "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

local function normalizeSpaces(text)
    text = tostring(text or "")
    text = text:gsub("[%z\1-\31]", "")
    text = text:gsub("%s+", " ")
    return trim(text)
end

local function removeBrackets(text)
    return tostring(text or ""):gsub("{[^}]*}", "")
end

local function splitByLines(text)
    local lines = {}
    text = tostring(text or ""):gsub("\r", "")
    for line in text:gmatch("[^\n]+") do
        line = trim(line)
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    return lines
end

local function splitByTabs(text)
    local cols = {}
    text = tostring(text or "") .. "\t"
    for col in text:gmatch("([^\t]*)\t") do
        table.insert(cols, col)
    end
    return cols
end

local function stripHexColorTags(text)
    return tostring(text or ""):gsub("{%x%x%x%x%x%x}", "")
end

local function getTimeString()
    return os.date("%d.%m.%Y %H:%M:%S")
end

local function getCaptureDateTimeString(ts)
    return os.date("%d-%m-%Y, %H:%M:%S", ts or os.time())
end

local function getNow()
    return os.time()
end

local function getDiscordTimeHeader()
    local offsetMinutes = tonumber(CFG.main.discord_time_offset_minutes) or 0
    local ts = os.time() + (offsetMinutes * 60)
    local dateTable = os.date("*t", ts)
    return string.format("%02d.%02d.%04d\n%02d:%02d", dateTable.day, dateTable.month, dateTable.year, dateTable.hour, dateTable.min)
end

local function withDiscordTimeHeader(description)
    local body = tostring(description or "")
    return string.format("%s\n\n%s", getDiscordTimeHeader(), body)
end

local function withTimestamp(text)
    return string.format("[%s] %s", getTimeString(), text)
end

local function getWeaponName(id)
    return WEAPON_NAMES.map[id] or ("ID " .. tostring(id))
end

local function normalizeNick(name)
    if not name or name == "" then
        return "Unknown"
    end
    return tostring(name)
end

local function loadCaptureIgnoreNicks(force)
    local now = os.clock()
    if not force and now < (tonumber(DATA.captureIgnoreReloadAt) or 0) then
        return
    end

    DATA.captureIgnoreReloadAt = now + 5.0
    local loaded = {}
    local file = io.open(PATHS.CAPTURE_IGNORE_NICKS_FILE, "r")
    if file then
        for line in file:lines() do
            local nick = trim(line)
            if nick ~= "" then
                loaded[normalizeNick(nick):lower()] = true
            end
        end
        file:close()
    end

    DATA.captureIgnoreNicks = loaded
end

local function isCaptureNickIgnored(nick)
    return (DATA.captureIgnoreNicks or {})[normalizeNick(nick):lower()] == true
end

local function resetDialog66WhiteScan()
    DATA.dialog66WhiteScan = {
        active = false,
        pages = 0,
        nicks = {},
        order = {},
        greenNicks = {}
    }
end

local function saveDialog66WhiteScanResults()
    local merged = {}
    local mergedOrder = {}
    local existingCount = 0
    local addedCount = 0
    local removedCount = 0

    local existingFile = io.open(PATHS.CAPTURE_IGNORE_NICKS_FILE, "r")
    if existingFile then
        for line in existingFile:lines() do
            local nick = trim(line)
            local nickKey = normalizeNick(nick):lower()
            if nick ~= "" and not merged[nickKey] then
                merged[nickKey] = nick
                table.insert(mergedOrder, nick)
                existingCount = existingCount + 1
            end
        end
        existingFile:close()
    end

    local greenNicks = (DATA.dialog66WhiteScan and DATA.dialog66WhiteScan.greenNicks) or {}
    if next(greenNicks) ~= nil then
        local filteredOrder = {}
        for i = 1, #mergedOrder do
            local nick = mergedOrder[i]
            local nickKey = normalizeNick(nick):lower()
            if greenNicks[nickKey] then
                merged[nickKey] = nil
                removedCount = removedCount + 1
            else
                table.insert(filteredOrder, nick)
            end
        end
        mergedOrder = filteredOrder
    end

    local order = (DATA.dialog66WhiteScan and DATA.dialog66WhiteScan.order) or {}
    for i = 1, #order do
        local nick = trim(tostring(order[i] or ""))
        local nickKey = normalizeNick(nick):lower()
        if nick ~= "" and not greenNicks[nickKey] and not merged[nickKey] then
            merged[nickKey] = nick
            table.insert(mergedOrder, nick)
            addedCount = addedCount + 1
        end
    end

    local file = io.open(PATHS.CAPTURE_IGNORE_NICKS_FILE, "w")
    if not file then
        return false, 0, existingCount, 0
    end

    for i = 1, #mergedOrder do
        file:write(tostring(mergedOrder[i] or "") .. "\n")
    end

    file:close()
    loadCaptureIgnoreNicks(true)
    return true, addedCount, #mergedOrder, removedCount
end

local function extractDialog66Nick(cellText)
    local nick = trim(stripHexColorTags(cellText))
    nick = nick:gsub("^%d+%.%s*", "")
    return trim(nick)
end

function APP.extractDialog66ColorHex(text)
    local raw = tostring(text or "")
    local hex8 = raw:match("{(%x%x%x%x%x%x%x%x)}")
    if hex8 and #hex8 == 8 then
        return hex8:sub(3, 8)
    end

    local hex6 = raw:match("{(%x%x%x%x%x%x)}")
    if hex6 and #hex6 == 6 then
        return hex6
    end

    return nil
end

local function isDialog66WhiteNickColor(hex)
    if not hex or hex == "" then
        return true
    end

    if #hex ~= 6 then
        return false
    end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then
        return false
    end

    local minValue = math.min(r, g, b)
    local maxValue = math.max(r, g, b)
    return minValue >= 210 and (maxValue - minValue) <= 30
end

local function isDialog66GreenNickColor(hex)
    if not hex or #hex ~= 6 then
        return false
    end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then
        return false
    end

    return g >= 120 and g > r + 20 and g > b + 20
end

local function collectDialog66WhiteNicks(text)
    local scan = DATA.dialog66WhiteScan
    if not scan or not scan.active then
        return 0
    end

    local added = 0
    local lines = splitByLines(text)
    for i = 2, #lines do
        local cols = splitByTabs(lines[i])
        local rawNick = cols[1] or ""
        local color = APP.extractDialog66ColorHex(rawNick)
        local nick = extractDialog66Nick(rawNick)
        local nickKey = normalizeNick(nick):lower()

        if nick ~= "" and color and isDialog66GreenNickColor(color) then
            scan.greenNicks[nickKey] = true
            scan.nicks[nickKey] = nil
        elseif nick ~= "" and isDialog66WhiteNickColor(color) and not scan.nicks[nickKey] and not scan.greenNicks[nickKey] then
            scan.nicks[nickKey] = nick
            table.insert(scan.order, nick)
            added = added + 1
        end
    end

    return added
end

local function dialog66HasNextPage(button2)
    local text = stripHexColorTags(button2 or "")
    return text:find(">>", 1, true) ~= nil
end

local function requestDialog66NextPage()
    lua_thread.create(function()
        wait(0)
        sampSendDialogResponse(66, 0, 0, "")
    end)
end

local function finishDialog66WhiteScan()
    local scanned = #((DATA.dialog66WhiteScan and DATA.dialog66WhiteScan.order) or {})
    local ok, addedCount, totalSaved, removedCount = saveDialog66WhiteScanResults()
    if ok then
        chatSuccess(string.format("Белые ники обработаны: %d | добавлено: %d | удалено зелёных: %d | всего в файле: %d", scanned, tonumber(addedCount) or 0, tonumber(removedCount) or 0, tonumber(totalSaved) or 0))
    else
        chatError("Не удалось сохранить исключения белых ников из диалога 66.")
    end

    STATE.capture.overlayRefreshAt = 0
    DATA.overlayTestRefreshAt = 0

    resetDialog66WhiteScan()
end

local function startDialog66WhiteScan()
    resetDialog66WhiteScan()
    DATA.dialog66WhiteScan.active = true
    chatInfo("Скан белых ников активирован. Открой диалог 66.")
end

local function getFallbackPlayerName(id)
    id = tonumber(id)
    if not id or id < 0 or id == 65535 then
        return "Неизвестно"
    end
    return "Игрок_" .. tostring(id)
end

local function migrateCapturePlaceholderNick(id, actualNick)
    local c = STATE.capture
    if not c or not c.active then
        return
    end

    local fallbackNick = getFallbackPlayerName(id)
    if actualNick == "" or actualNick == "Unknown" or actualNick == fallbackNick then
        return
    end

    local fallbackKills = tonumber(c.stats[fallbackNick])
    if fallbackKills ~= nil then
        c.stats[actualNick] = (tonumber(c.stats[actualNick]) or 0) + fallbackKills
        c.stats[fallbackNick] = nil
    end

    local fallbackDeadKey = normalizeNick(fallbackNick):lower()
    local actualDeadKey = normalizeNick(actualNick):lower()
    if c.deadPlayers[fallbackDeadKey] then
        c.deadPlayers[fallbackDeadKey] = nil
        c.deadPlayers[actualDeadKey] = true
    end
end

local function tryGetLivePlayerNickname(id)
    id = tonumber(id)
    if not id or id < 0 or id == 65535 then
        return nil
    end

    if type(sampGetPlayerNickname) ~= "function" then
        return nil
    end

    if not sampIsPlayerConnected(id) then
        return nil
    end

    local ok, nickname = pcall(sampGetPlayerNickname, id)
    if not ok or not nickname or nickname == "" then
        return nil
    end

    return nickname
end

local function cachePlayerNameById(id, nickname)
    id = tonumber(id)
    if not id or id < 0 then
        return
    end

    local normalized = normalizeNick(cp1251_to_utf8(nickname or ""))
    if normalized ~= "" and normalized ~= "Unknown" then
        migrateCapturePlaceholderNick(id, normalized)
        DATA.playerNamesById[id] = normalized
    end
end

local function cachePlayerColorById(id, color, source)
    id = tonumber(id)
    color = tonumber(color)
    if not id or id < 0 or not color then
        return
    end

    source = tostring(source or "live")
    local previousColor = tonumber((DATA.playerColorsById or {})[id])
    DATA.playerColorsById[id] = color
    DATA.playerColorSourceById[id] = source

    if source == "live" and previousColor ~= color then
        DATA.onlineColorEventCount = (tonumber(DATA.onlineColorEventCount) or 0) + 1
    end
end

local function markPlayerOnlineById(id, isOnline)
    id = tonumber(id)
    if not id or id < 0 then
        return
    end

    if isOnline then
        DATA.onlinePlayersById[id] = true
    else
        DATA.onlinePlayersById[id] = nil
    end
end

local function isCachedPlayerOnline(id)
    id = tonumber(id)
    if not id or id < 0 then
        return false
    end

    return (DATA.onlinePlayersById or {})[id] == true
end

local function getCachedPlayerColor(id)
    id = tonumber(id)
    if not id or id < 0 then
        return nil
    end

    local color = (DATA.playerColorsById or {})[id]
    if color == nil then
        return nil
    end

    return tonumber(color)
end

local resolveGangKeyByColor
local isSafeGameRenderState

local function refreshOnlinePlayersSnapshot(force, ignoreGameState)
    if DATA.scriptTerminating then
        return
    end

    local now = os.clock()
    if not force and now < (tonumber(DATA.onlineSnapshotRefreshAt) or 0) then
        return
    end

    if not ignoreGameState and not isSafeGameRenderState() then
        DATA.onlineSnapshotRefreshAt = now + 2.5
        return
    end

    local refreshedOnline = {}
    local refreshedColors = {}
    local refreshedSources = {}
    local knownOnline = DATA.onlinePlayersById or {}
    if next(knownOnline) == nil then
        DATA.onlineSnapshotRefreshAt = now + 0.75
        return
    end

    for id in pairs(knownOnline) do
        id = tonumber(id)
        if id and id >= 0 and id ~= 65535 and sampIsPlayerConnected(id) then
            refreshedOnline[id] = true

            local liveNickname = tryGetLivePlayerNickname(id)
            if liveNickname then
                cachePlayerNameById(id, liveNickname)
            end

            local color = tonumber(sampGetPlayerColor(id))
            local cachedColor = tonumber((DATA.playerColorsById or {})[id])
            local cachedSource = tostring((DATA.playerColorSourceById or {})[id] or "")

            if color ~= nil then
                refreshedColors[id] = color
                refreshedSources[id] = "scan"
            elseif cachedColor ~= nil then
                refreshedColors[id] = cachedColor
                refreshedSources[id] = cachedSource ~= "" and cachedSource or "cache"
            end
        end
    end

    DATA.onlinePlayersById = refreshedOnline
    DATA.playerColorsById = refreshedColors
    DATA.playerColorSourceById = refreshedSources
    DATA.onlineSnapshotRefreshAt = now + 2.5
end

local function getPlayerNameById(id)
    if id == 65535 or id == -1 then
        return "Неизвестно"
    end

    local cache = DATA.playerNamesById or {}
    local cached = cache[id]
    if cached and cached ~= "" then
        return cached
    end

    local liveNickname = tryGetLivePlayerNickname(id)
    if liveNickname then
        cachePlayerNameById(id, liveNickname)
        local refreshed = (DATA.playerNamesById or {})[id]
        if refreshed and refreshed ~= "" then
            return refreshed
        end
    end

    return getFallbackPlayerName(id)
end

local function getMyNick()
    local ok, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if ok and myId ~= nil then
        return getPlayerNameById(myId)
    end
    return nil
end

local function getMyId()
    local ok, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if ok and myId ~= nil then
        return myId
    end
    return -1
end

isSafeGameRenderState = function()
    return isGameWindowForeground() and not isPauseMenuActive() and not isGamePaused()
end

local function intToHexColor(color)
    color = tonumber(color) or 0xFFFFFFFF
    return string.format("%06X", bit.band(color, 0xFFFFFF))
end

local function getPlayerChatHexColor(id)
    if id == 65535 or id == -1 then
        return "FFFFFF"
    end

    local color = getCachedPlayerColor(id)
    if color then
        return intToHexColor(color)
    end

    return "FFFFFF"
end

local function colorizeName(id, nick)
    return string.format("{%s}%s[%d]{FFFFFF}", getPlayerChatHexColor(id), nick, id)
end

resolveGangKeyByColor = function(color)
    color = tonumber(color)
    if not color then
        return nil
    end

    local rgb = bit.band(color, 0xFFFFFF)
    for _, gang in ipairs(GANGS.list) do
        if rgb == bit.band(tonumber(gang.color), 0xFFFFFF) then
            return gang.key
        end
    end

    return nil
end

local function jsonEscape(str)
    str = tostring(str or "")
    str = str:gsub("\\", "\\\\")
    str = str:gsub("\"", "\\\"")
    str = str:gsub("\r", "")
    str = str:gsub("\n", "\\n")
    return str
end

local function boolValue(boolObj, default)
    if type(boolObj) == "table" and boolObj.v ~= nil then
        return boolObj.v == true
    end
    return default == true
end

local function intValue(intObj, default)
    if type(intObj) == "table" and intObj.v ~= nil then
        return tonumber(intObj.v) or tonumber(default) or 0
    end
    return tonumber(default) or 0
end

local function bufferValue(bufferObj, default)
    if type(bufferObj) == "table" and bufferObj.v ~= nil then
        return stripZeroBytes(bufferObj.v or "")
    end
    return stripZeroBytes(default or "")
end

local function reportDiscordQueueError(message)
    message = trim(tostring(message or "неизвестная ошибка"))
    if message == "" or DATA.scriptTerminating then
        return
    end

    DATA.discordLastStatusText = "error"
    if DATA.discordLastErrorText ~= message then
        DATA.discordLastErrorText = message
        chatError("Discord отправка: " .. message)
    end
end

local function containsAnyKeyword(text, keywords)
    text = tostring(text or "")
    for _, keyword in ipairs(keywords) do
        if string.find(text, keyword, 1, true) then
            return true
        end
    end
    return false
end

local function buildAllGangKeywords()
    local all = {}
    for _, gang in ipairs(GANGS.list) do
        for _, keyword in ipairs(gang.keywords) do
            table.insert(all, keyword)
        end
    end
    return all
end

GANGS.allKeywords = buildAllGangKeywords()
local rebuildCaptureOverlayEntries
local markCapturePlayerDead
local drawOverlayHud
local processPendingDeathEvents

local function requestCaptureOverlayRefresh()
    if STATE.capture and STATE.capture.active then
        STATE.capture.overlayRefreshAt = 0
    end
    if DATA.overlayTestActive then
        DATA.overlayTestRefreshAt = 0
    end
end

local function containsPunishmentByLegacyPrinciple(text)
    text = tostring(text or "")
    return containsAnyKeyword(text, ADMIN_KEYWORDS.list) and containsAnyKeyword(text, GANGS.allKeywords)
end

local function cleanupPunishmentLine(text)
    local line = normalizeSpaces(removeBrackets(text))
    if line == "" then
        return ""
    end

    line = line:gsub("^Администратор%s+", "")
    line = line:gsub("^администратор%s+", "")
    line = line:gsub("^ADMINISTRATOR%s+", "")
    return normalizeSpaces(line)
end

local function buildPunishmentGangWarnSummary(captureData)
    local counts = {}
    local participants = (captureData and captureData.participants) or {}
    for _, gang in ipairs(GANGS.list) do
        if participants[gang.key] then
            counts[gang.key] = 0
        end
    end

    local punishes = captureData and captureData.punishes or nil
    if not punishes then
        return {}
    end

    for i = 1, #punishes do
        local line = tostring(punishes[i] or "")
        local lower = line:lower()
        if string.find(lower, "выдал предупреждение", 1, true) then
            for _, gang in ipairs(GANGS.list) do
                if participants[gang.key] then
                    for _, keyword in ipairs(gang.keywords) do
                        if string.find(lower, tostring(keyword):lower(), 1, true) then
                            counts[gang.key] = (counts[gang.key] or 0) + 1
                            break
                        end
                    end
                end
            end
        end
    end

    local lines = {}
    for _, gang in ipairs(GANGS.list) do
        if participants[gang.key] then
            table.insert(lines, string.format("%s: %d", gang.display, counts[gang.key]))
        end
    end

    return lines
end

local function appendLine(path, line)
    local f = io.open(path, "a")
    if f then
        f:write(line .. "\n")
        f:close()
    end
end

local function normalizeDiscordDebugText(text)
    text = stripZeroBytes(tostring(text or ""))
    text = text:gsub("\r", "\\r")
    text = text:gsub("\n", "\\n")
    return text
end

local function previewDiscordDebugText(text, limit)
    text = normalizeDiscordDebugText(text)
    limit = tonumber(limit) or 300
    if #text > limit then
        return text:sub(1, limit) .. "..."
    end
    return text
end

local function appendDiscordDebugLog(stage, message)
    local line = string.format(
        "[%s] [%s] %s",
        os.date("%Y-%m-%d %H:%M:%S"),
        tostring(stage or "stage"),
        normalizeDiscordDebugText(message or "")
    )
    appendLine(PATHS.DISCORD_DEBUG_LOG, line)
end

local function fileExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local function deleteFileSafe(path)
    if fileExists(path) then
        os.remove(path)
    end
end

local function encodeValue(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\")
    value = value:gsub("\n", "\\n")
    value = value:gsub("\r", "")
    return value
end

local function decodeValue(value)
    value = tostring(value or "")
    value = value:gsub("\\n", "\n")
    value = value:gsub("\\\\", "\\")
    return value
end

local function saveSectionFile(path, section)
    local f = io.open(path, "w")
    if not f then
        chatError("Не удалось сохранить файл: " .. path)
        return false
    end

    for key, value in pairs(section) do
        f:write(tostring(key) .. "=" .. encodeValue(value) .. "\n")
    end

    f:close()
    return true
end

local function loadSectionFile(path, section)
    local f = io.open(path, "r")
    if not f then
        return false
    end

    for line in f:lines() do
        local clean = trim(line)
        if clean ~= "" and clean:sub(1, 1) ~= ";" and clean:sub(1, 1) ~= "#" then
            local key, value = clean:match("^([^=]+)=(.*)$")
            if key then
                key = trim(key)
                value = decodeValue(value)
                if section[key] ~= nil then
                    if type(section[key]) == "boolean" then
                        local v = value:lower()
                        section[key] = (v == "true" or v == "1")
                    elseif type(section[key]) == "number" then
                        section[key] = tonumber(value) or section[key]
                    else
                        section[key] = tostring(value)
                    end
                end
            end
        end
    end

    f:close()
    return true
end

local function loadAllSettings()
    loadSectionFile(PATHS.MAIN_SETTINGS_FILE, CFG.main)
    loadSectionFile(PATHS.FRAG_SETTINGS_FILE, CFG.fraglist)
    loadSectionFile(PATHS.PUNISH_SETTINGS_FILE, CFG.punishments)
    loadSectionFile(PATHS.ONLINE_SETTINGS_FILE, CFG.online)
    loadSectionFile(PATHS.BANTACHKA_SETTINGS_FILE, CFG.bantachka)
    loadSectionFile(PATHS.PRIORITY_SETTINGS_FILE, CFG.priority)
    loadSectionFile(PATHS.FOLLOW_SETTINGS_FILE, CFG.follow)
end

local function saveAllSettings()
    local ok1 = saveSectionFile(PATHS.MAIN_SETTINGS_FILE, CFG.main)
    local ok2 = saveSectionFile(PATHS.FRAG_SETTINGS_FILE, CFG.fraglist)
    local ok3 = saveSectionFile(PATHS.PUNISH_SETTINGS_FILE, CFG.punishments)
    local ok4 = saveSectionFile(PATHS.ONLINE_SETTINGS_FILE, CFG.online)
    local ok5 = saveSectionFile(PATHS.BANTACHKA_SETTINGS_FILE, CFG.bantachka)
    local ok6 = saveSectionFile(PATHS.PRIORITY_SETTINGS_FILE, CFG.priority)
    local ok7 = saveSectionFile(PATHS.FOLLOW_SETTINGS_FILE, CFG.follow)
    return ok1 and ok2 and ok3 and ok4 and ok5 and ok6 and ok7
end

local function appendCaptureSessionBlock(captureData)
    local f = io.open(PATHS.CAPTURE_SESSIONS_FILE, "a")
    if not f then
        return
    end

    f:write(CONST.SESSION_SEPARATOR .. "\n")
    f:write("Дата, время: " .. tostring(captureData.start_dt or getCaptureDateTimeString()) .. "\n")
    f:write(tostring(captureData.start_line or "") .. "\n")
    f:write(tostring(captureData.initiator_line or "") .. "\n")
    f:write(CONST.SESSION_SEPARATOR .. "\n")

    if captureData.punishes and #captureData.punishes > 0 then
        for i = 1, #captureData.punishes do
            f:write(tostring(captureData.punishes[i]) .. "\n")
        end
    end

    f:write(tostring(captureData.end_line or "") .. "\n")
    f:write(CONST.SESSION_SEPARATOR .. "\n")
    f:write("\n\n")
    f:close()
end

local function cloneArray(src)
    local out = {}
    if not src then return out end
    for i = 1, #src do
        out[i] = src[i]
    end
    return out
end

local function cloneMap(src)
    local out = {}
    if not src then return out end
    for k, v in pairs(src) do
        out[k] = v
    end
    return out
end

local function hasMeaningfulCaptureData(data)
    if not data then
        return false
    end
    if (data.start_line and data.start_line ~= "") or (data.end_line and data.end_line ~= "") then
        return true
    end
    if data.kills and #data.kills > 0 then
        return true
    end
    if data.punishes and #data.punishes > 0 then
        return true
    end
    if data.stats then
        for _, _ in pairs(data.stats) do
            return true
        end
    end
    return (tonumber(data.total) or 0) > 0
end

local function saveCaptureDataToFile(path, data)
    if not data or not hasMeaningfulCaptureData(data) then
        deleteFileSafe(path)
        return false
    end

    local f = io.open(path, "w")
    if not f then
        return false
    end

    f:write("[meta]\n")
    f:write("active=" .. encodeValue(data.active and "true" or "false") .. "\n")
    f:write("online_sent=" .. encodeValue(data.online_sent and "true" or "false") .. "\n")
    f:write("punish_logging=" .. encodeValue(data.punish_logging and "true" or "false") .. "\n")
    f:write("manual_assist_mode=" .. encodeValue(data.manual_assist_mode and "true" or "false") .. "\n")
    f:write("send_logs_on_finish=" .. encodeValue(data.send_logs_on_finish and "true" or "false") .. "\n")
    f:write("start_at=" .. encodeValue(data.start_at or 0) .. "\n")
    f:write("start_dt=" .. encodeValue(data.start_dt or "") .. "\n")
    f:write("start_line=" .. encodeValue(data.start_line or "") .. "\n")
    f:write("initiator_line=" .. encodeValue(data.initiator_line or "") .. "\n")
    f:write("end_line=" .. encodeValue(data.end_line or "") .. "\n")
    f:write("total=" .. encodeValue(data.total or 0) .. "\n")
    f:write("duration=" .. encodeValue(data.duration or 0) .. "\n")
    f:write("[/meta]\n")

    f:write("[kills]\n")
    if data.kills then
        for i = 1, #data.kills do
            f:write(encodeValue(data.kills[i]) .. "\n")
        end
    end
    f:write("[/kills]\n")

    f:write("[stats]\n")
    if data.stats then
        for nick, kills in pairs(data.stats) do
            f:write(encodeValue(nick) .. "\t" .. tostring(tonumber(kills) or 0) .. "\n")
        end
    end
    f:write("[/stats]\n")

    f:write("[punishes]\n")
    if data.punishes then
        for i = 1, #data.punishes do
            f:write(encodeValue(data.punishes[i]) .. "\n")
        end
    end
    f:write("[/punishes]\n")

    f:write("[participants]\n")
    if data.participants then
        for key, value in pairs(data.participants) do
            if value then
                f:write(encodeValue(key) .. "\n")
            end
        end
    end
    f:write("[/participants]\n")

    f:write("[dead_players]\n")
    if data.dead_players then
        for key, value in pairs(data.dead_players) do
            if value then
                f:write(encodeValue(key) .. "\n")
            end
        end
    end
    f:write("[/dead_players]\n")

    f:close()
    return true
end

function APP.stripUtf8Bom(text)
    text = tostring(text or "")
    if text:sub(1, 3) == "\239\187\191" then
        return text:sub(4)
    end
    return text
end

function APP.getSelfScriptPath()
    local ok, script = pcall(function()
        return thisScript()
    end)
    if ok and script and script.path and tostring(script.path) ~= "" then
        return tostring(script.path)
    end
    return getWorkingDirectory() .. "\\CaptureDiscordAssistant.lua"
end

function APP.readAllText(path, binaryMode)
    local mode = binaryMode and "rb" or "r"
    local file = io.open(path, mode)
    if not file then
        return nil
    end

    local text = file:read("*a")
    file:close()
    return text
end

function APP.writeAllText(path, text, binaryMode)
    local mode = binaryMode and "wb" or "w"
    local file = io.open(path, mode)
    if not file then
        return false
    end

    file:write(text or "")
    file:close()
    return true
end

function APP.jsonExtractString(text, key)
    text = APP.stripUtf8Bom(tostring(text or ""))
    key = tostring(key or "")
    if key == "" then
        return nil
    end

    local pattern = "\"" .. key:gsub("([^%w_])", "%%%1") .. "\"%s*:%s*\"(.-)\""
    local value = text:match(pattern)
    if not value then
        return nil
    end

    value = value:gsub("\\/", "/")
    value = value:gsub("\\n", "\n")
    value = value:gsub("\\r", "\r")
    value = value:gsub("\\t", "\t")
    value = value:gsub("\\\"", "\"")
    value = value:gsub("\\\\", "\\")
    return value
end

function APP.parseUpdaterVersionJson(text)
    text = APP.stripUtf8Bom(tostring(text or ""))
    if text == "" then
        return nil, "version.json пустой"
    end

    local version = APP.jsonExtractString(text, "version")
    local scriptUrl = APP.jsonExtractString(text, "script_url")
    local versionUrl = APP.jsonExtractString(text, "version_url")
    local repoUrl = APP.jsonExtractString(text, "repo_url")
    local changelog = APP.jsonExtractString(text, "changelog") or ""

    if not version or version == "" then
        return nil, "в version.json нет поля version"
    end
    if not scriptUrl or scriptUrl == "" then
        return nil, "в version.json нет поля script_url"
    end

    return {
        version = trim(version),
        script_url = trim(scriptUrl),
        version_url = trim(versionUrl or ""),
        repo_url = trim(repoUrl or ""),
        changelog = trim(changelog)
    }, nil
end

function APP.splitVersionParts(version)
    local parts = {}
    version = tostring(version or "")
    for piece in version:gmatch("[^%.%-_]+") do
        table.insert(parts, tonumber(piece) or 0)
    end
    if #parts == 0 then
        table.insert(parts, 0)
    end
    return parts
end

function APP.compareVersions(left, right)
    local a = APP.splitVersionParts(left)
    local b = APP.splitVersionParts(right)
    local maxCount = math.max(#a, #b)

    for i = 1, maxCount do
        local av = tonumber(a[i]) or 0
        local bv = tonumber(b[i]) or 0
        if av > bv then
            return 1
        elseif av < bv then
            return -1
        end
    end

    return 0
end

function APP.parseVersionFromLuaScript(text)
    text = APP.stripUtf8Bom(tostring(text or ""))
    local version = text:match("script_version%s*%(%s*\"([^\"]+)\"%s*%)")
    if not version then
        version = text:match("script_version%s*%(%s*'([^']+)'%s*%)")
    end
    return trim(version or "")
end

function APP.isValidUpdaterScriptBody(text)
    text = APP.stripUtf8Bom(tostring(text or ""))
    if #text < 256 then
        return false, "файл обновления слишком маленький"
    end
    if not text:find("script_name%s*%(") then
        return false, "в скачанном файле нет script_name"
    end
    if not text:find("script_version%s*%(") then
        return false, "в скачанном файле нет script_version"
    end
    return true, nil
end

function APP.asyncUpdaterHttpGet(url, resolve, reject)
    resolve = type(resolve) == "function" and resolve or function() end
    reject = type(reject) == "function" and reject or function() end
    url = tostring(url or "")

    if url == "" then
        reject("пустой URL")
        return
    end
    if type(effil) ~= "table" or type(effil.thread) ~= "function" then
        reject("effil unavailable")
        return
    end

    local okThread, requestThread = pcall(function()
        return effil.thread(function(urlArg)
            local https = require("ssl.https")
            local ltn12 = require("ltn12")
            local responseBody = {}

            https.TIMEOUT = 15

            local ok, code, responseHeaders, statusLine = https.request({
                url = urlArg,
                method = "GET",
                protocol = "tlsv1_2",
                options = { "all", "no_sslv2", "no_sslv3", "no_tlsv1", "no_tlsv1_1" },
                verify = "none",
                sink = ltn12.sink.table(responseBody),
                redirect = false
            })

            local body = table.concat(responseBody)
            if ok and tonumber(code) then
                return true, tonumber(code) or 0, body, tostring(statusLine or "")
            end

            return false, tonumber(code) or 0, body, tostring(statusLine or ""), tostring(code or "https request failed")
        end)(url)
    end)

    if not okThread or requestThread == nil then
        reject(tostring(requestThread or "не удалось создать поток обновления"))
        return
    end

    local managedThreadId = registerManagedThread(requestThread)
    lua_thread.create(function()
        while true do
            if DATA.scriptTerminating or THREADS.shuttingDown then
                pcall(function()
                    requestThread:cancel()
                end)
                unregisterManagedThread(managedThreadId)
                return
            end

            local okStatus, status = pcall(function()
                return requestThread:status()
            end)
            if not okStatus then
                unregisterManagedThread(managedThreadId)
                reject(tostring(status or "ошибка статуса потока обновления"))
                return
            end

            if status == "completed" then
                local okGet, ok, statusCode, body, statusLine, errText = pcall(function()
                    return requestThread:get()
                end)
                unregisterManagedThread(managedThreadId)
                if not okGet then
                    reject(tostring(ok or "ошибка получения ответа обновления"))
                    return
                end
                if ok then
                    resolve(statusCode, body, statusLine)
                else
                    reject(tostring(errText or statusLine or ("HTTP " .. tostring(statusCode))))
                end
                return
            elseif status == "canceled" then
                unregisterManagedThread(managedThreadId)
                reject("canceled")
                return
            end

            wait(0)
        end
    end)
end

function APP.finishUpdateCheck(versionData, manualMode)
    local updater = DATA.updater
    updater.checking = false
    updater.lastCheckedAt = os.clock()

    local remoteVersion = trim(versionData.version or "")
    local remoteScriptUrl = trim(versionData.script_url or "")
    local changelog = trim(versionData.changelog or "")

    updater.latestVersion = remoteVersion
    updater.latestScriptUrl = remoteScriptUrl
    updater.changelog = changelog
    updater.lastError = ""

    local compareResult = APP.compareVersions(remoteVersion, CONST.SCRIPT_VERSION)
    updater.updateAvailable = compareResult > 0

    if compareResult > 0 then
        local message = string.format(
            "Доступно обновление: %s -> %s. Команда: /%s",
            CONST.SCRIPT_VERSION,
            remoteVersion,
            CONST.UPDATER_COMMAND
        )
        chatInfo(message)
        if changelog ~= "" then
            chatInfo("Что нового: " .. changelog)
        end
        if manualMode == "download_if_new" then
            APP.downloadLatestUpdate()
        end
    else
        updater.updateAvailable = false
        if manualMode == "download_if_new" then
            chatSuccess("У вас уже актуальная версия: " .. CONST.SCRIPT_VERSION)
        else
            chatSuccess("Используется актуальная версия: " .. CONST.SCRIPT_VERSION)
        end
    end
end

function APP.failUpdateCheck(errorText)
    local updater = DATA.updater
    updater.checking = false
    updater.lastCheckedAt = os.clock()
    updater.lastError = tostring(errorText or "неизвестная ошибка")
    if updater.downloading then
        updater.downloading = false
    end
    chatError("Не удалось проверить обновление: " .. updater.lastError)
end

function APP.checkForUpdates(manualMode)
    local updater = DATA.updater
    if updater.checking then
        chatInfo("Проверка обновления уже выполняется.")
        return
    end
    if updater.downloading then
        chatInfo("Сейчас уже идёт скачивание обновления.")
        return
    end

    updater.checking = true
    updater.lastError = ""

    APP.asyncUpdaterHttpGet(
        CONST.UPDATER_VERSION_URL,
        function(statusCode, body)
            if tonumber(statusCode) ~= 200 then
                APP.failUpdateCheck("HTTP " .. tostring(statusCode) .. " при загрузке version.json")
                return
            end

            local versionData, parseError = APP.parseUpdaterVersionJson(body)
            if not versionData then
                APP.failUpdateCheck(parseError or "битый version.json")
                return
            end

            if versionData.version_url ~= "" and trim(versionData.version_url) ~= trim(CONST.UPDATER_VERSION_URL) then
                APP.failUpdateCheck("version.json ссылается на другой version.json")
                return
            end

            APP.finishUpdateCheck(versionData, manualMode)
        end,
        function(errText)
            APP.failUpdateCheck(errText)
        end
    )
end

function APP.downloadLatestUpdate()
    local updater = DATA.updater
    if updater.downloading then
        chatInfo("Скачивание обновления уже выполняется.")
        return
    end

    local scriptUrl = trim(updater.latestScriptUrl or "")
    local latestVersion = trim(updater.latestVersion or "")
    if scriptUrl == "" or latestVersion == "" then
        chatError("Нет данных об обновлении. Сначала дождитесь успешной проверки.")
        return
    end

    updater.downloading = true
    APP.asyncUpdaterHttpGet(
        scriptUrl,
        function(statusCode, body)
            updater.downloading = false

            if tonumber(statusCode) ~= 200 then
                chatError("Не удалось скачать обновление: HTTP " .. tostring(statusCode))
                return
            end

            body = APP.stripUtf8Bom(tostring(body or ""))
            local okBody, validationError = APP.isValidUpdaterScriptBody(body)
            if not okBody then
                chatError("Скачанный файл отклонён: " .. tostring(validationError or "невалидный Lua"))
                return
            end

            local downloadedVersion = APP.parseVersionFromLuaScript(body)
            if downloadedVersion == "" then
                chatError("В скачанном файле не удалось определить script_version.")
                return
            end
            if APP.compareVersions(downloadedVersion, latestVersion) ~= 0 then
                chatError("version.json и .lua рассинхронизированы: json=" .. latestVersion .. ", lua=" .. downloadedVersion)
                return
            end

            if not APP.writeAllText(PATHS.UPDATER_TEMP_FILE, body, true) then
                chatError("Не удалось записать временный файл обновления.")
                return
            end

            local tempBody = APP.readAllText(PATHS.UPDATER_TEMP_FILE, true)
            if tempBody ~= body then
                deleteFileSafe(PATHS.UPDATER_TEMP_FILE)
                chatError("Проверка записанного обновления не прошла.")
                return
            end

            local selfScriptPath = APP.getSelfScriptPath()
            if not APP.writeAllText(selfScriptPath, body, true) then
                deleteFileSafe(PATHS.UPDATER_TEMP_FILE)
                chatError("Не удалось заменить текущий файл скрипта.")
                return
            end

            deleteFileSafe(PATHS.UPDATER_TEMP_FILE)
            chatSuccess("Обновление скачано: " .. downloadedVersion)
            chatInfo("Перезагрузите скрипт или игру, чтобы применить обновление.")
        end,
        function(errText)
            updater.downloading = false
            chatError("Не удалось скачать обновление: " .. tostring(errText or "неизвестная ошибка"))
        end
    )
end

function APP.clampNumber(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

function APP.isLongRangeLabelsEnabled()
    if BOOLS.longRangeLabelsBool ~= nil then
        return BOOLS.longRangeLabelsBool.v == true
    end
    return CFG.main.long_range_labels_enabled == true
end

function APP.isCustomNametagsEnabled()
    if BOOLS.customNametagsBool ~= nil then
        return BOOLS.customNametagsBool.v == true
    end
    return CFG.main.custom_nametags_enabled == true
end

function APP.isSkeletalEnabled()
    if BOOLS.skeletalBool ~= nil then
        return BOOLS.skeletalBool.v == true
    end
    return CFG.main.skeletal_enabled == true
end

function APP.shouldModifyLongRangeLabel(text, attachedPlayerId, attachedVehicleId)
    if not APP.isLongRangeLabelsEnabled() then
        return false
    end
    if not text or text == "" then
        return false
    end
    if not CONST.LONG_RANGE_LABEL_ONLY_ATTACHED then
        return true
    end
    return tonumber(attachedPlayerId) ~= CONST.INVALID_PLAYER_ID or tonumber(attachedVehicleId) ~= CONST.INVALID_VEHICLE_ID
end

function APP.rebuildLongRangeLabel(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
    if APP.shouldModifyLongRangeLabel(text, attachedPlayerId, attachedVehicleId) then
        return {
            id,
            color,
            position,
            CONST.LONG_RANGE_LABEL_DISTANCE,
            CONST.LONG_RANGE_LABEL_FORCE_WALLHACK and false or testLOS,
            attachedPlayerId,
            attachedVehicleId,
            text
        }
    end
end

function APP.recreateCustomNametagFont()
    local state = DATA.customNametags
    if state.font ~= nil then
        renderReleaseFont(state.font)
        state.font = nil
    end

    state.font = renderCreateFont(
        CONST.CUSTOM_NAMETAGS_FONT_NAME,
        CONST.CUSTOM_NAMETAGS_FONT_SIZE,
        CONST.CUSTOM_NAMETAGS_FONT_FLAGS,
        CONST.CUSTOM_NAMETAGS_FONT_CHARSET
    )
end

function APP.getCustomNametagServerSettingsPtr()
    if not isSampAvailable() then
        return nil
    end

    local ptr = sampGetServerSettingsPtr()
    if ptr == nil or ptr == 0 then
        return nil
    end

    return ptr
end

function APP.cacheOriginalCustomNametagSettings()
    local state = DATA.customNametags
    if state.originalSettings ~= nil then
        return
    end

    local ptr = APP.getCustomNametagServerSettingsPtr()
    if ptr == nil then
        return
    end

    state.originalSettings = {
        draw_distance = APP.memory.getfloat(ptr + CONST.CUSTOM_NAMETAGS_SERVER_OFFSETS.draw_distance, true),
        wallhack = APP.memory.getint8(ptr + CONST.CUSTOM_NAMETAGS_SERVER_OFFSETS.wallhack, true),
        show_nametags = APP.memory.getint8(ptr + CONST.CUSTOM_NAMETAGS_SERVER_OFFSETS.show_nametags, true)
    }
end

function APP.applyCustomNametagSettings()
    local ptr = APP.getCustomNametagServerSettingsPtr()
    if ptr == nil then
        return
    end

    APP.cacheOriginalCustomNametagSettings()
    APP.memory.setfloat(ptr + CONST.CUSTOM_NAMETAGS_SERVER_OFFSETS.draw_distance, CONST.CUSTOM_NAMETAGS_MAX_DISTANCE, true)
    APP.memory.setint8(ptr + CONST.CUSTOM_NAMETAGS_SERVER_OFFSETS.wallhack, 0, true)
    APP.memory.setint8(ptr + CONST.CUSTOM_NAMETAGS_SERVER_OFFSETS.show_nametags, 1, true)
end

function APP.restoreCustomNametagSettings()
    if DATA.skeletal and DATA.skeletal.active then
        return
    end

    local ptr = APP.getCustomNametagServerSettingsPtr()
    local original = DATA.customNametags.originalSettings
    if ptr == nil or original == nil then
        return
    end

    APP.memory.setfloat(ptr + CONST.CUSTOM_NAMETAGS_SERVER_OFFSETS.draw_distance, original.draw_distance, true)
    APP.memory.setint8(ptr + CONST.CUSTOM_NAMETAGS_SERVER_OFFSETS.wallhack, original.wallhack, true)
    APP.memory.setint8(ptr + CONST.CUSTOM_NAMETAGS_SERVER_OFFSETS.show_nametags, original.show_nametags, true)
end

function APP.patchCustomNametagRel32Call(callAddr, newTargetAddr)
    local oldProtect = APP.ffi.new("unsigned long[1]")
    APP.ffi.C.VirtualProtect(APP.ffi.cast("void*", callAddr), 5, CONST.CUSTOM_NAMETAGS_PAGE_EXECUTE_READWRITE, oldProtect)
    APP.ffi.cast("int32_t*", callAddr + 1)[0] = newTargetAddr - (callAddr + 5)
    APP.ffi.C.VirtualProtect(APP.ffi.cast("void*", callAddr), 5, oldProtect[0], oldProtect)
end

function APP.installCustomNametagRenderHook()
    local state = DATA.customNametags
    if state.renderNickHookInstalled then
        return true
    end

    local samp = getModuleHandle("samp.dll")
    if samp == 0 then
        return false
    end

    state.renderNickCallAddr = samp + CONST.CUSTOM_NAMETAGS_RENDER_NICK_HOOK_OFFSET
    if APP.ffi.cast("uint8_t*", state.renderNickCallAddr)[0] ~= 0xE8 then
        return false
    end

    state.renderNickOriginalRel = APP.ffi.cast("int32_t*", state.renderNickCallAddr + 1)[0]
    state.renderNickCallback = APP.ffi.cast(
        "int(__cdecl*)(char*, const char*, const char*, int)",
        function(buf, fmt, nick, id)
            if buf ~= nil then
                APP.ffi.cast("char*", buf)[0] = 0
            end
            return 0
        end
    )

    APP.patchCustomNametagRel32Call(
        state.renderNickCallAddr,
        tonumber(APP.ffi.cast("intptr_t", state.renderNickCallback))
    )

    state.renderNickHookInstalled = true
    return true
end

function APP.removeCustomNametagRenderHook()
    local state = DATA.customNametags
    if not state.renderNickHookInstalled or state.renderNickCallAddr == nil or state.renderNickOriginalRel == nil then
        return
    end

    local oldProtect = APP.ffi.new("unsigned long[1]")
    APP.ffi.C.VirtualProtect(APP.ffi.cast("void*", state.renderNickCallAddr), 5, CONST.CUSTOM_NAMETAGS_PAGE_EXECUTE_READWRITE, oldProtect)
    APP.ffi.cast("int32_t*", state.renderNickCallAddr + 1)[0] = state.renderNickOriginalRel
    APP.ffi.C.VirtualProtect(APP.ffi.cast("void*", state.renderNickCallAddr), 5, oldProtect[0], oldProtect)

    state.renderNickHookInstalled = false
    state.renderNickCallback = nil
end

function APP.installCustomNametagHealthBarPatch()
    local state = DATA.customNametags
    if state.drawHealthBarPatchInstalled then
        return true
    end

    local samp = getModuleHandle("samp.dll")
    if samp == 0 then
        return false
    end

    state.drawHealthBarAddr = samp + CONST.CUSTOM_NAMETAGS_DRAW_HEALTH_BAR_OFFSET
    state.drawHealthBarOriginalByte = APP.ffi.cast("uint8_t*", state.drawHealthBarAddr)[0]

    local oldProtect = APP.ffi.new("unsigned long[1]")
    APP.ffi.C.VirtualProtect(APP.ffi.cast("void*", state.drawHealthBarAddr), 1, CONST.CUSTOM_NAMETAGS_PAGE_EXECUTE_READWRITE, oldProtect)
    APP.ffi.cast("uint8_t*", state.drawHealthBarAddr)[0] = 0xC3
    APP.ffi.C.VirtualProtect(APP.ffi.cast("void*", state.drawHealthBarAddr), 1, oldProtect[0], oldProtect)

    state.drawHealthBarPatchInstalled = true
    return true
end

function APP.removeCustomNametagHealthBarPatch()
    local state = DATA.customNametags
    if not state.drawHealthBarPatchInstalled or state.drawHealthBarAddr == nil or state.drawHealthBarOriginalByte == nil then
        return
    end

    local oldProtect = APP.ffi.new("unsigned long[1]")
    APP.ffi.C.VirtualProtect(APP.ffi.cast("void*", state.drawHealthBarAddr), 1, CONST.CUSTOM_NAMETAGS_PAGE_EXECUTE_READWRITE, oldProtect)
    APP.ffi.cast("uint8_t*", state.drawHealthBarAddr)[0] = state.drawHealthBarOriginalByte
    APP.ffi.C.VirtualProtect(APP.ffi.cast("void*", state.drawHealthBarAddr), 1, oldProtect[0], oldProtect)

    state.drawHealthBarPatchInstalled = false
end

function APP.ensureCustomNametagRuntimePatches()
    local state = DATA.customNametags
    local now = os.clock() * 1000
    if now - (tonumber(state.lastPatchTime) or 0) < CONST.CUSTOM_NAMETAGS_UPDATE_PATCH_DELAY then
        return
    end

    APP.applyCustomNametagSettings()
    APP.installCustomNametagRenderHook()
    APP.installCustomNametagHealthBarPatch()
    state.lastPatchTime = now
end

function APP.getCustomNametagPlayerWorldPosition(playerId)
    local result, ped = sampGetCharHandleBySampPlayerId(playerId)
    if result and doesCharExist(ped) then
        local zOffset = isCharInAnyCar(ped) and 1.02 or 0.82
        local x, y, z = getOffsetFromCharInWorldCoords(ped, 0.0, 0.0, zOffset)
        return true, x, y, z, ped
    end

    local streamed, x, y, z = sampGetStreamedOutPlayerPos(playerId)
    if streamed then
        return true, x, y, z + 0.82, nil
    end

    return false, nil, nil, nil, nil
end

function APP.getCustomNametagColor(playerId)
    local originalColor = sampGetPlayerColor(playerId)
    originalColor = bit.bor(bit.band(originalColor, 0x00FFFFFF), 0xFF000000)
    if originalColor == 0xFFFFFFFF or originalColor == 0xFF000000 then
        return CONST.CUSTOM_NAMETAGS_TEXT_DEFAULT_COLOR
    end
    return originalColor
end

function APP.drawCustomNametagShadowedText(text, posX, posY, color)
    local font = DATA.customNametags.font
    if font == nil then
        return
    end

    local textCp1251 = utf8_to_cp1251(text)
    renderFontDrawText(font, textCp1251, posX + 1, posY + 1, 0xD0000000)
    renderFontDrawText(font, textCp1251, posX, posY, color)
end

function APP.drawCustomHpBar(drawX, drawY, width, health)
    local hpRatio = APP.clampNumber(health, 0, 100) / 100
    local innerWidth = width - 2
    local innerHeight = CONST.CUSTOM_NAMETAGS_HP_BAR_HEIGHT - 2
    local fillWidth = math.floor(innerWidth * hpRatio)

    renderDrawBox(drawX, drawY, width, CONST.CUSTOM_NAMETAGS_HP_BAR_HEIGHT, CONST.CUSTOM_NAMETAGS_HP_BAR_BORDER_COLOR)
    renderDrawBox(drawX + 1, drawY + 1, innerWidth, innerHeight, CONST.CUSTOM_NAMETAGS_HP_BAR_BACKGROUND_COLOR)
    if fillWidth > 0 then
        renderDrawBox(drawX + 1, drawY + 1, fillWidth, innerHeight, CONST.CUSTOM_NAMETAGS_HP_BAR_FILL_COLOR)
    end
end

function APP.drawCustomArmorBar(drawX, drawY, width, armor)
    local armorRatio = APP.clampNumber(armor, 0, 100) / 100
    local innerWidth = width - 2
    local innerHeight = CONST.CUSTOM_NAMETAGS_ARMOR_BAR_HEIGHT - 2
    local fillWidth = math.floor(innerWidth * armorRatio)

    renderDrawBox(drawX, drawY, width, CONST.CUSTOM_NAMETAGS_ARMOR_BAR_HEIGHT, CONST.CUSTOM_NAMETAGS_ARMOR_BAR_BORDER_COLOR)
    renderDrawBox(drawX + 1, drawY + 1, innerWidth, innerHeight, CONST.CUSTOM_NAMETAGS_ARMOR_BAR_BACKGROUND_COLOR)
    if fillWidth > 0 then
        renderDrawBox(drawX + 1, drawY + 1, fillWidth, innerHeight, CONST.CUSTOM_NAMETAGS_ARMOR_BAR_FILL_COLOR)
    end
end

function APP.renderSingleCustomNametag(playerId, myX, myY, myZ)
    local ok, x, y, z, ped = APP.getCustomNametagPlayerWorldPosition(playerId)
    if not ok then
        return
    end
    if ped ~= nil and not isCharOnScreen(ped) then
        return
    end

    local distance = getDistanceBetweenCoords3d(myX, myY, myZ, x, y, z)
    if distance > CONST.CUSTOM_NAMETAGS_MAX_DISTANCE then
        return
    end

    local screenX, screenY = convert3DCoordsToScreen(x, y, z)
    if screenX == nil or screenY == nil then
        return
    end

    local nick = sampGetPlayerNickname(playerId)
    if not nick or nick == "" then
        return
    end

    local displayText = cp1251_to_utf8(nick) .. string.format(" (%d)", tonumber(playerId) or 0)
    local textCp1251 = utf8_to_cp1251(displayText)
    local font = DATA.customNametags.font
    if font == nil then
        return
    end

    local textWidth = renderGetFontDrawTextLength(font, textCp1251)
    local textHeight = renderGetFontDrawHeight(font)
    local barWidth = math.max(textWidth, CONST.CUSTOM_NAMETAGS_HP_BAR_WIDTH_MIN)
    local health = sampGetPlayerHealth(playerId)
    local armor = sampGetPlayerArmor(playerId)
    local showArmorBar = CONST.CUSTOM_NAMETAGS_ARMOR_BAR_ENABLED and armor > 0
    local barX = screenX - (barWidth / 2)
    local textY = screenY - textHeight - CONST.CUSTOM_NAMETAGS_HP_BAR_SPACING - CONST.CUSTOM_NAMETAGS_HP_BAR_HEIGHT - 2
    local hpY = textY + textHeight + CONST.CUSTOM_NAMETAGS_HP_BAR_SPACING
    local armorY = hpY + CONST.CUSTOM_NAMETAGS_HP_BAR_HEIGHT + CONST.CUSTOM_NAMETAGS_ARMOR_BAR_SPACING
    local drawX = screenX - (textWidth / 2)

    if CONST.CUSTOM_NAMETAGS_HP_BAR_ENABLED then
        APP.drawCustomHpBar(barX, hpY, barWidth, health)
    end
    if showArmorBar then
        APP.drawCustomArmorBar(barX, armorY, barWidth, armor)
    end

    APP.drawCustomNametagShadowedText(displayText, drawX, textY, APP.getCustomNametagColor(playerId))
end

function APP.renderCustomNametagsFrame()
    if not APP.isCustomNametagsEnabled() then
        return
    end
    if sampGetGamestate() ~= 3 or not sampIsLocalPlayerSpawned() then
        return
    end

    APP.ensureCustomNametagRuntimePatches()

    if DATA.customNametags.font == nil then
        APP.recreateCustomNametagFont()
    end
    if DATA.customNametags.font == nil then
        return
    end

    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
    local maxPlayerId = sampGetMaxPlayerId(false)

    for playerId = 0, maxPlayerId do
        if playerId ~= myId and sampIsPlayerConnected(playerId) then
            APP.renderSingleCustomNametag(playerId, myX, myY, myZ)
        end
    end
end

function APP.setCustomNametagsState(enabled, silent)
    local state = DATA.customNametags
    enabled = enabled == true
    if state.active == enabled then
        return
    end

    state.active = enabled
    state.lastPatchTime = 0

    if enabled then
        if state.font == nil then
            APP.recreateCustomNametagFont()
        end
        APP.cacheOriginalCustomNametagSettings()
        APP.applyCustomNametagSettings()
        APP.installCustomNametagRenderHook()
        APP.installCustomNametagHealthBarPatch()
        if not silent then
            chatSuccess("Кастомные никнеймы включены.")
        end
    else
        APP.removeCustomNametagHealthBarPatch()
        APP.removeCustomNametagRenderHook()
        APP.restoreCustomNametagSettings()
        if state.font ~= nil then
            renderReleaseFont(state.font)
            state.font = nil
        end
        if not silent then
            chatInfo("Кастомные никнеймы выключены.")
        end
    end
end

function APP.syncCustomNametagsState(silent)
    APP.setCustomNametagsState(APP.isCustomNametagsEnabled(), silent)
end

function APP.shutdownCustomNametags()
    APP.setCustomNametagsState(false, true)
end

function APP.getSkeletalBoneCoordinates(boneId, charHandle)
    local pedPtr = getCharPointer(charHandle)
    local vec = APP.ffi.new("float[3]")
    APP.getBonePositionFn(APP.ffi.cast("void*", pedPtr), vec, boneId, true)
    return vec[0], vec[1], vec[2]
end

function APP.renderSkeletalFrame()
    if not APP.isSkeletalEnabled() then
        return
    end
    if sampGetGamestate() ~= 3 or not sampIsLocalPlayerSpawned() then
        return
    end
    if isPauseMenuActive() or isKeyDown(VK_F8) then
        return
    end

    APP.applyCustomNametagSettings()

    local maxPlayerId = sampGetMaxPlayerId(false)
    for playerId = 0, maxPlayerId do
        if sampIsPlayerConnected(playerId) then
            local result, charHandle = sampGetCharHandleBySampPlayerId(playerId)
            if result and doesCharExist(charHandle) and isCharOnScreen(charHandle) then
                local color = sampGetPlayerColor(playerId)
                local alpha = bit.band(bit.rshift(color, 24), 0xFF)
                local red = bit.band(bit.rshift(color, 16), 0xFF)
                local green = bit.band(bit.rshift(color, 8), 0xFF)
                local blue = bit.band(color, 0xFF)
                local drawColor = bit.bor(bit.lshift(255, 24), bit.lshift(red, 16), bit.lshift(green, 8), blue)

                for i = 1, #CONST.SKELETAL_BONE_SEGMENTS do
                    local segment = CONST.SKELETAL_BONE_SEGMENTS[i]
                    local x1, y1, z1 = APP.getSkeletalBoneCoordinates(segment[1], charHandle)
                    local x2, y2, z2 = APP.getSkeletalBoneCoordinates(segment[2], charHandle)
                    local sx1, sy1 = convert3DCoordsToScreen(x1, y1, z1)
                    local sx2, sy2 = convert3DCoordsToScreen(x2, y2, z2)
                    if sx1 ~= nil and sy1 ~= nil and sx2 ~= nil and sy2 ~= nil then
                        renderDrawLine(sx1, sy1, sx2, sy2, 1, drawColor)
                    end
                end
            end
        end
    end
end

function APP.setSkeletalState(enabled, silent)
    enabled = enabled == true
    if DATA.skeletal.active == enabled then
        return
    end

    DATA.skeletal.active = enabled

    if enabled then
        APP.cacheOriginalCustomNametagSettings()
        APP.applyCustomNametagSettings()
        if not silent then
            chatSuccess("Skeletal включен.")
        end
    else
        if not APP.isCustomNametagsEnabled() then
            APP.restoreCustomNametagSettings()
        end
        if not silent then
            chatInfo("Skeletal выключен.")
        end
    end
end

function APP.syncSkeletalState(silent)
    APP.setSkeletalState(APP.isSkeletalEnabled(), silent)
end

function APP.shutdownSkeletal()
    APP.setSkeletalState(false, true)
end

local function loadCaptureDataFromFile(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end

    local data = {
        active = false,
        online_sent = false,
        punish_logging = false,
        start_at = 0,
        start_dt = "",
        start_line = "",
        initiator_line = "",
        end_line = "",
        total = 0,
        duration = 0,
        kills = {},
        stats = {},
        punishes = {},
        participants = {},
        dead_players = {}
    }

    local mode = nil

    for rawLine in f:lines() do
        local line = tostring(rawLine or "")

        if line == "[meta]" then
            mode = "meta"
        elseif line == "[/meta]" then
            mode = nil
        elseif line == "[kills]" then
            mode = "kills"
        elseif line == "[/kills]" then
            mode = nil
        elseif line == "[stats]" then
            mode = "stats"
        elseif line == "[/stats]" then
            mode = nil
        elseif line == "[punishes]" then
            mode = "punishes"
        elseif line == "[/punishes]" then
            mode = nil
        elseif line == "[participants]" then
            mode = "participants"
        elseif line == "[/participants]" then
            mode = nil
        elseif line == "[dead_players]" then
            mode = "dead_players"
        elseif line == "[/dead_players]" then
            mode = nil
        else
            if mode == "meta" then
                local key, value = line:match("^([^=]+)=(.*)$")
                key = trim(key or "")
                value = decodeValue(value or "")

                if key == "active" then
                    data.active = (value == "true" or value == "1")
                elseif key == "online_sent" then
                    data.online_sent = (value == "true" or value == "1")
                elseif key == "punish_logging" then
                    data.punish_logging = (value == "true" or value == "1")
                elseif key == "manual_assist_mode" then
                    data.manual_assist_mode = (value == "true" or value == "1")
                elseif key == "send_logs_on_finish" then
                    data.send_logs_on_finish = (value == "true" or value == "1")
                elseif key == "start_at" then
                    data.start_at = tonumber(value) or 0
                elseif key == "start_dt" then
                    data.start_dt = tostring(value or "")
                elseif key == "start_line" then
                    data.start_line = tostring(value or "")
                elseif key == "initiator_line" then
                    data.initiator_line = tostring(value or "")
                elseif key == "end_line" then
                    data.end_line = tostring(value or "")
                elseif key == "total" then
                    data.total = tonumber(value) or 0
                elseif key == "duration" then
                    data.duration = tonumber(value) or 0
                end
            elseif mode == "kills" then
                if line ~= "" then
                    table.insert(data.kills, decodeValue(line))
                end
            elseif mode == "stats" then
                if line ~= "" then
                    local nick, kills = line:match("^(.-)\t(%-?%d+)$")
                    if nick then
                        data.stats[decodeValue(nick)] = tonumber(kills) or 0
                    end
                end
            elseif mode == "punishes" then
                if line ~= "" then
                    table.insert(data.punishes, decodeValue(line))
                end
            elseif mode == "participants" then
                if line ~= "" then
                    data.participants[decodeValue(line)] = true
                end
            elseif mode == "dead_players" then
                if line ~= "" then
                    data.dead_players[decodeValue(line)] = true
                end
            end
        end
    end

    f:close()

    if not hasMeaningfulCaptureData(data) and not data.active then
        return nil
    end

    return data
end

local function buildCurrentCaptureData(endLine)
    local c = STATE.capture
    local duration = 0
    if c.startAt > 0 then
        duration = os.time() - c.startAt
    end

    return {
        start_at = c.startAt,
        start_dt = c.startDt,
        start_line = c.startLine or "",
        initiator_line = c.initiatorLine or "",
        end_line = endLine or c.endLine or "",
        kills = cloneArray(c.kills or {}),
        stats = cloneMap(c.stats or {}),
        total = c.total or 0,
        punishes = cloneArray(c.punishes or {}),
        duration = duration,
        participants = cloneMap(c.participants or {}),
        dead_players = cloneMap(c.deadPlayers or {}),
        manual_assist_mode = c.manualAssistMode == true,
        send_logs_on_finish = c.sendLogsOnFinish ~= false
    }
end

local function saveLastCaptureSnapshot()
    if DATA.lastCapture and hasMeaningfulCaptureData(DATA.lastCapture) then
        saveCaptureDataToFile(PATHS.LAST_CAPTURE_STATE_FILE, DATA.lastCapture)
    else
        deleteFileSafe(PATHS.LAST_CAPTURE_STATE_FILE)
    end
end

local function savePendingCaptureSnapshot()
    if DATA.pendingCaptureToSend and hasMeaningfulCaptureData(DATA.pendingCaptureToSend) then
        saveCaptureDataToFile(PATHS.PENDING_CAPTURE_STATE_FILE, DATA.pendingCaptureToSend)
    else
        deleteFileSafe(PATHS.PENDING_CAPTURE_STATE_FILE)
    end
end

local function clearActiveCaptureState()
    deleteFileSafe(PATHS.ACTIVE_CAPTURE_STATE_FILE)
end

local function persistActiveCaptureState()
    local c = STATE.capture
    if not c.active then
        clearActiveCaptureState()
        return
    end

    local data = buildCurrentCaptureData(c.endLine)
    data.active = true
    data.online_sent = c.onlineSent
    data.punish_logging = c.punishLogging
    saveCaptureDataToFile(PATHS.ACTIVE_CAPTURE_STATE_FILE, data)
end

local function restoreCaptureFromData(data)
    if not data then
        return false
    end

    local c = STATE.capture
    c.active = data.active == true
    c.startAt = tonumber(data.start_at) or 0
    c.startDt = tostring(data.start_dt or "")
    c.startLine = tostring(data.start_line or "")
    c.initiatorLine = tostring(data.initiator_line or "")
    c.endLine = tostring(data.end_line or "")
    c.kills = cloneArray(data.kills or {})
    c.stats = cloneMap(data.stats or {})
    c.total = tonumber(data.total) or 0
    c.punishes = cloneArray(data.punishes or {})
    c.participants = cloneMap(data.participants or {})
    c.deadPlayers = cloneMap(data.dead_players or {})
    c.overlayEntries = {}
    c.overlayRefreshAt = 0
    c.onlineSent = data.online_sent == true
    c.manualAssistMode = data.manual_assist_mode == true
    c.sendLogsOnFinish = data.send_logs_on_finish ~= false
    c.punishLogging = data.punish_logging == true
    c.bantachkaNotified = false
    if rebuildCaptureOverlayEntries then
        rebuildCaptureOverlayEntries()
    end
    return true
end

local function resetCapture()
    local c = STATE.capture
    c.active = false
    c.startAt = 0
    c.startDt = ""
    c.startLine = ""
    c.initiatorLine = ""
    c.endLine = ""
    c.kills = {}
    c.stats = {}
    c.total = 0
    c.participants = {}
    c.deadPlayers = {}
    c.overlayEntries = {}
    c.overlayRefreshAt = 0
    c.onlineSent = false
    c.manualAssistMode = false
    c.sendLogsOnFinish = true
    c.punishLogging = false
    c.punishes = {}
    c.bantachkaNotified = false
    DATA.captureTopOverlayEntries = {}
end

local function initBuffers()
    BUFF.fragWebhookBuffer     = imgui.ImBuffer(2048)
    BUFF.punishWebhookBuffer   = imgui.ImBuffer(2048)
    BUFF.onlineWebhookBuffer   = imgui.ImBuffer(2048)
    BUFF.bantachkaAccountsBuffer = imgui.ImBuffer(4096)
    BUFF.priorityAdminsBuffer  = imgui.ImBuffer(4096)
    BUFF.followCommandBuffer   = imgui.ImBuffer(256)

    BUFF.fragWebhookBuffer.v    = sanitizeWebhookUrl(CFG.fraglist.webhook_url or "")
    BUFF.punishWebhookBuffer.v  = sanitizeWebhookUrl(CFG.punishments.webhook_url or "")
    BUFF.onlineWebhookBuffer.v  = sanitizeWebhookUrl(CFG.online.webhook_url or "")
    BUFF.bantachkaAccountsBuffer.v = tostring(CFG.bantachka.accounts_serialized or ""):gsub("|", "\n")
    BUFF.priorityAdminsBuffer.v = tostring(CFG.priority.admins_serialized or ""):gsub("|", "\n")
    BUFF.followCommandBuffer.v  = tostring(CFG.follow.command_template or "/sp %d")

    INTS.maxTopBuffer              = imgui.ImInt(tonumber(CFG.main.max_top_players) or 10)
    INTS.discordTimeOffsetBuffer   = imgui.ImInt(tonumber(CFG.main.discord_time_offset_minutes) or 0)
    INTS.captureOverlayXBuffer     = imgui.ImInt(tonumber(CFG.main.capture_overlay_x) or 22)
    INTS.captureOverlayYBuffer     = imgui.ImInt(tonumber(CFG.main.capture_overlay_y) or 120)
    INTS.captureOverlayWidthBuffer = imgui.ImInt(tonumber(CFG.main.capture_overlay_width) or 420)
    INTS.captureOverlayHeightBuffer= imgui.ImInt(tonumber(CFG.main.capture_overlay_height) or 360)
    INTS.captureOverlayGapBuffer   = imgui.ImInt(tonumber(CFG.main.capture_overlay_gap) or 48)
    INTS.captureTopOverlayXBuffer  = imgui.ImInt(tonumber(CFG.main.capture_top_overlay_x) or 520)
    INTS.captureTopOverlayYBuffer  = imgui.ImInt(tonumber(CFG.main.capture_top_overlay_y) or 120)
    INTS.fragEmbedColorBuffer      = imgui.ImInt(tonumber(CFG.fraglist.embed_color) or 16729344)
    INTS.punishEmbedColorBuffer    = imgui.ImInt(tonumber(CFG.punishments.embed_color) or 15158332)
    INTS.onlineEmbedColorBuffer    = imgui.ImInt(tonumber(CFG.online.embed_color) or 16729344)
    INTS.followHotkeyBuffer        = imgui.ImInt(tonumber(CFG.follow.hotkey_vk) or 0x48)
    INTS.followPromptSecondsBuffer = imgui.ImInt(tonumber(CFG.follow.prompt_seconds) or 8)

    BOOLS.saveStatsBool             = imgui.ImBool(CFG.main.save_stats ~= false)
    BOOLS.developerModeBool         = imgui.ImBool(CFG.main.developer_mode == true)
    BOOLS.localFeedBool             = imgui.ImBool(CFG.main.local_chat_feed ~= false)
    BOOLS.streakAlertsBool          = imgui.ImBool(CFG.main.streak_alerts ~= false)
    BOOLS.longRangeLabelsBool       = imgui.ImBool(CFG.main.long_range_labels_enabled == true)
    BOOLS.customNametagsBool        = imgui.ImBool(CFG.main.custom_nametags_enabled == true)
    BOOLS.skeletalBool              = imgui.ImBool(CFG.main.skeletal_enabled == true)
    BOOLS.captureOverlayEnabledBool = imgui.ImBool(CFG.main.capture_overlay_enabled ~= false)
    BOOLS.captureTopOverlayEnabledBool = imgui.ImBool(CFG.main.capture_top_overlay_enabled ~= false)

    BOOLS.fragSendSummaryBool       = imgui.ImBool(CFG.fraglist.send_summary ~= false)
    BOOLS.fragSendTopBool           = imgui.ImBool(CFG.fraglist.send_top ~= false)
    BOOLS.fragSendDetailsBool       = imgui.ImBool(CFG.fraglist.send_details ~= false)
    BOOLS.fragShowMessagesBool      = imgui.ImBool(CFG.fraglist.show_status_messages_in_chat ~= false)
    BOOLS.fragShowKillsBool         = imgui.ImBool(CFG.fraglist.show_kills_in_chat ~= false)

    BOOLS.punishEnabledBool         = imgui.ImBool(CFG.punishments.enabled ~= false)
    BOOLS.punishShowInChatBool      = imgui.ImBool(CFG.punishments.show_success_in_chat ~= false)

    BOOLS.autoOnlineOnCaptureStartBool = imgui.ImBool(CFG.online.auto_send_on_capture_start ~= false)

    BOOLS.priorityEnabledBool       = imgui.ImBool(CFG.priority.enabled == true)
    BOOLS.priorityAskConfirmBool    = imgui.ImBool(CFG.priority.ask_confirmation ~= false)

    BOOLS.followEnabledBool         = imgui.ImBool(CFG.follow.enabled == true)
    BOOLS.followUseCtrlBool         = imgui.ImBool(CFG.follow.use_ctrl == true)
    BOOLS.followUseAltBool          = imgui.ImBool(CFG.follow.use_alt == true)
    BOOLS.followUseShiftBool        = imgui.ImBool(CFG.follow.use_shift == true)

    APP.finishWebhookSave("frag", BUFF.fragWebhookBuffer)
    APP.finishWebhookSave("punish", BUFF.punishWebhookBuffer)
    APP.finishWebhookSave("online", BUFF.onlineWebhookBuffer)
end

function APP.serializePriorityAdmins()
    local lines = splitByLines(BUFF.priorityAdminsBuffer and BUFF.priorityAdminsBuffer.v or "")
    return table.concat(lines, "|")
end

function APP.serializeBantachkaAccounts()
    local lines = splitByLines(BUFF.bantachkaAccountsBuffer and BUFF.bantachkaAccountsBuffer.v or "")
    return table.concat(lines, "|")
end

function APP.getBantachkaAccountsList()
    return splitByLines(BUFF.bantachkaAccountsBuffer and BUFF.bantachkaAccountsBuffer.v or "")
end

function APP.getPriorityAdminsList()
    return splitByLines(BUFF.priorityAdminsBuffer and BUFF.priorityAdminsBuffer.v or "")
end

local function applyBuffersToCfg()
    CFG.main.gui_hotkey_vk      = tonumber(CFG.main.gui_hotkey_vk) or 0x77
    CFG.main.developer_mode     = BOOLS.developerModeBool.v
    CFG.main.save_stats         = BOOLS.saveStatsBool.v
    CFG.main.local_chat_feed    = BOOLS.localFeedBool.v
    CFG.main.streak_alerts      = BOOLS.streakAlertsBool.v
    CFG.main.long_range_labels_enabled = BOOLS.longRangeLabelsBool.v
    CFG.main.custom_nametags_enabled = BOOLS.customNametagsBool.v
    CFG.main.skeletal_enabled = BOOLS.skeletalBool.v
    CFG.main.max_top_players    = tonumber(INTS.maxTopBuffer.v) or 10
    CFG.main.discord_time_offset_minutes = tonumber(INTS.discordTimeOffsetBuffer.v) or 0
    CFG.main.capture_overlay_enabled = BOOLS.captureOverlayEnabledBool.v
    CFG.main.capture_overlay_x = tonumber(INTS.captureOverlayXBuffer.v) or 22
    CFG.main.capture_overlay_y = tonumber(INTS.captureOverlayYBuffer.v) or 120
    CFG.main.capture_overlay_width = tonumber(INTS.captureOverlayWidthBuffer.v) or 420
    CFG.main.capture_overlay_height = tonumber(INTS.captureOverlayHeightBuffer.v) or 360
    CFG.main.capture_overlay_gap = tonumber(INTS.captureOverlayGapBuffer.v) or 48
    CFG.main.capture_top_overlay_enabled = BOOLS.captureTopOverlayEnabledBool.v
    CFG.main.capture_top_overlay_x = tonumber(INTS.captureTopOverlayXBuffer.v) or 520
    CFG.main.capture_top_overlay_y = tonumber(INTS.captureTopOverlayYBuffer.v) or 120

    CFG.fraglist.webhook_url                  = sanitizeWebhookUrl(BUFF.fragWebhookBuffer.v or "")
    CFG.fraglist.send_summary                 = BOOLS.fragSendSummaryBool.v
    CFG.fraglist.send_top                     = BOOLS.fragSendTopBool.v
    CFG.fraglist.send_details                 = BOOLS.fragSendDetailsBool.v
    CFG.fraglist.embed_color                  = tonumber(INTS.fragEmbedColorBuffer.v) or 16729344
    CFG.fraglist.show_status_messages_in_chat = BOOLS.fragShowMessagesBool.v
    CFG.fraglist.show_kills_in_chat           = BOOLS.fragShowKillsBool.v

    CFG.punishments.webhook_url          = sanitizeWebhookUrl(BUFF.punishWebhookBuffer.v or "")
    CFG.punishments.enabled              = BOOLS.punishEnabledBool.v
    CFG.punishments.embed_color          = tonumber(INTS.punishEmbedColorBuffer.v) or 15158332
    CFG.punishments.show_success_in_chat = BOOLS.punishShowInChatBool.v

    CFG.online.webhook_url                = sanitizeWebhookUrl(BUFF.onlineWebhookBuffer.v or "")
    CFG.online.embed_color                = tonumber(INTS.onlineEmbedColorBuffer.v) or 16729344
    CFG.online.auto_send_on_capture_start = BOOLS.autoOnlineOnCaptureStartBool.v

    CFG.bantachka.accounts_serialized = APP.serializeBantachkaAccounts()

    CFG.priority.enabled           = BOOLS.priorityEnabledBool.v
    CFG.priority.ask_confirmation  = BOOLS.priorityAskConfirmBool.v
    CFG.priority.admins_serialized = APP.serializePriorityAdmins()

    CFG.follow.enabled          = BOOLS.followEnabledBool.v
    CFG.follow.hotkey_vk        = tonumber(INTS.followHotkeyBuffer.v) or 0x48
    CFG.follow.use_ctrl         = BOOLS.followUseCtrlBool.v
    CFG.follow.use_alt          = BOOLS.followUseAltBool.v
    CFG.follow.use_shift        = BOOLS.followUseShiftBool.v
    CFG.follow.prompt_seconds   = tonumber(INTS.followPromptSecondsBuffer.v) or 8
    CFG.follow.command_template = tostring(BUFF.followCommandBuffer.v or "/sp %d")
end

local function saveConfig()
    if not BUFF.fragWebhookBuffer or not BOOLS.saveStatsBool or not INTS.maxTopBuffer then
        return false
    end
    applyBuffersToCfg()
    return saveAllSettings()
end

local function saveStats()
    if not boolValue(BOOLS.saveStatsBool, true) then return end
    local f = io.open(PATHS.STATS_FILE, "w")
    if not f then return end
    for nick, kills in pairs(DATA.stats) do
        f:write(string.format("%s\t%d\n", nick, kills or 0))
    end
    f:close()
end

local function loadStats()
    local f = io.open(PATHS.STATS_FILE, "r")
    if not f then return end
    for line in f:lines() do
        local nick, kills = line:match("^(.-)\t(%d+)$")
        if nick then
            DATA.stats[nick] = tonumber(kills) or 0
        end
    end
    f:close()
end

local function sortedStats(src)
    local arr = {}
    for nick, kills in pairs(src) do
        table.insert(arr, { nick = nick, kills = kills or 0 })
    end
    table.sort(arr, function(a, b)
        if a.kills ~= b.kills then
            return a.kills > b.kills
        end
        return a.nick:lower() < b.nick:lower()
    end)
    return arr
end

local function addKillToGlobalStats(killerName)
    if killerName and killerName ~= "Неизвестно" then
        DATA.stats[killerName] = (DATA.stats[killerName] or 0) + 1
        local myNick = getMyNick()
        if myNick and killerName == myNick then
            DATA.sessionKills = DATA.sessionKills + 1
        end
        saveStats()
    end
end

local function cleanupOldStreaks(nick)
    if not DATA.streaks[nick] then
        DATA.streaks[nick] = {}
        return
    end

    local now = getNow()
    local fresh = {}
    for i = 1, #DATA.streaks[nick] do
        if now - DATA.streaks[nick][i] <= CONST.STREAK_WINDOW_SECONDS then
            table.insert(fresh, DATA.streaks[nick][i])
        end
    end
    DATA.streaks[nick] = fresh
end

local function registerKillInStreak(nick)
    nick = normalizeNick(nick)
    cleanupOldStreaks(nick)
    if not DATA.streaks[nick] then
        DATA.streaks[nick] = {}
    end
    table.insert(DATA.streaks[nick], getNow())
    return #DATA.streaks[nick]
end

local function showStreakMessageIfNeeded(killerId, killerName, count)
    if not boolValue(BOOLS.streakAlertsBool, true) then return end
    if count < 2 then return end
    local shown = count > CONST.STREAK_MAX_ANNOUNCE and CONST.STREAK_MAX_ANNOUNCE or count
    local msg = STREAK_MESSAGES.map[shown] or string.format("[!] УЖЕ %d ФРАГОВ [!]", shown)
    chat(string.format("%s {FFFFFF}%s", COLORS.RED .. msg, colorizeName(killerId, killerName)))
end

local function markGangParticipantsFromText(text)
    text = tostring(text or "")
    local participants = STATE.capture.participants
    for _, gang in ipairs(GANGS.list) do
        for _, keyword in ipairs(gang.keywords) do
            if string.find(text, keyword, 1, true) then
                participants[gang.key] = true
                break
            end
        end
    end
end

local function normalizeDiscordErrorText(value, depth)
    depth = tonumber(depth) or 0
    local valueType = type(value)

    if value == nil then
        return ""
    end

    if valueType == "string" then
        return value
    end

    if valueType == "number" or valueType == "boolean" then
        return tostring(value)
    end

    if valueType ~= "table" then
        return tostring(value)
    end

    if depth >= 2 then
        return "[table]"
    end

    local preferredKeys = {
        "message", "error", "description", "reason", "status",
        "status_code", "code", "errno", "name", "body"
    }

    local chunks = {}
    for i = 1, #preferredKeys do
        local key = preferredKeys[i]
        local item = rawget(value, key)
        if item ~= nil then
            chunks[#chunks + 1] = tostring(key) .. "=" .. normalizeDiscordErrorText(item, depth + 1)
        end
    end

    if #chunks == 0 then
        for key, item in pairs(value) do
            chunks[#chunks + 1] = tostring(key) .. "=" .. normalizeDiscordErrorText(item, depth + 1)
            if #chunks >= 8 then
                break
            end
        end
    end

    local text = table.concat(chunks, ", ")
    if text == "" then
        text = "[table]"
    end
    return text
end

local function asyncDiscordHttpRequest(method, url, args, resolve, reject)
    resolve = type(resolve) == "function" and resolve or function() end
    reject = type(reject) == "function" and reject or function() end

    local payloadText = stripZeroBytes(tostring(args and args.data or ""))
    local requestHeaders = {}
    if type(args) == "table" and type(args.headers) == "table" then
        for key, value in pairs(args.headers) do
            requestHeaders[tostring(key)] = tostring(value)
        end
    end
    requestHeaders["Content-Length"] = tostring(#payloadText)
    appendDiscordDebugLog("enter", "method=" .. tostring(method) .. " | url=" .. tostring(url))
    appendDiscordDebugLog("payload_meta", "length=" .. tostring(#payloadText) .. " | preview=" .. previewDiscordDebugText(payloadText, 300))

    if type(effil) ~= "table" or type(effil.thread) ~= "function" then
        local errText = "effil unavailable"
        appendDiscordDebugLog("effil_unavailable", errText)
        reject(errText)
        return
    end

    appendDiscordDebugLog("effil_prepare", "creating effil worker")
    local okThread, requestThread = pcall(function()
        return effil.thread(function(methodArg, urlArg, headersArg, dataArg)
            local https = require("ssl.https")
            local ltn12 = require("ltn12")
            local responseBody = {}

            https.TIMEOUT = 12

            local ok, code, responseHeaders, statusLine = https.request({
                url = urlArg,
                method = methodArg,
                protocol = "tlsv1_2",
                options = { "all", "no_sslv2", "no_sslv3", "no_tlsv1", "no_tlsv1_1" },
                verify = "none",
                mode = "client",
                headers = headersArg,
                source = ltn12.source.string(dataArg),
                sink = ltn12.sink.table(responseBody)
            })

            local body = table.concat(responseBody)

            if ok then
                return true, tonumber(code) or 0, body, tostring(statusLine or ""), ""
            end

            return false, tonumber(code) or 0, body, tostring(statusLine or ""), tostring(code or "https request failed")
        end)(method, url, requestHeaders, payloadText)
    end)

    if not okThread or requestThread == nil then
        local errText = normalizeDiscordErrorText(requestThread)
        appendDiscordDebugLog("effil_prepare_error", errText)
        reject(errText)
        return
    end

    local managedThreadId = registerManagedThread(requestThread)

    appendDiscordDebugLog("effil_started", "worker created")
    lua_thread.create(function()
        local lastStatus = nil
        local lastErr = nil
        while true do
            if DATA.scriptTerminating or THREADS.shuttingDown or isCaptureDiscordTailExpired() then
                pcall(function()
                    requestThread:cancel()
                end)
                unregisterManagedThread(managedThreadId)
                return
            end

            local okStatus, status, err = pcall(function()
                return requestThread:status()
            end)
            if not okStatus then
                local normalizedErrText = normalizeDiscordErrorText(status)
                appendDiscordDebugLog("effil_status_error", normalizedErrText)
                unregisterManagedThread(managedThreadId)
                reject(normalizedErrText)
                return
            end
            local statusText = tostring(status)
            local errText = tostring(err)
            if statusText ~= tostring(lastStatus) or errText ~= tostring(lastErr) then
                appendDiscordDebugLog("effil_status", "status=" .. statusText .. " | err=" .. errText)
                lastStatus = statusText
                lastErr = errText
            end
            if err then
                local normalizedErrText = normalizeDiscordErrorText(err)
                appendDiscordDebugLog("effil_status_error", normalizedErrText)
                unregisterManagedThread(managedThreadId)
                reject(normalizedErrText)
                return
            end

            if status == "completed" then
                local okGet, ok, statusCode, body, statusLine, requestErr = pcall(function()
                    return requestThread:get()
                end)
                if not okGet then
                    local normalizedErrText = normalizeDiscordErrorText(ok)
                    appendDiscordDebugLog("effil_get_error", normalizedErrText)
                    unregisterManagedThread(managedThreadId)
                    reject(normalizedErrText)
                    return
                end
                appendDiscordDebugLog("effil_completed", "ok=" .. tostring(ok) .. " | status_code=" .. tostring(statusCode) .. " | status=" .. tostring(statusLine))
                unregisterManagedThread(managedThreadId)
                if ok then
                    resolve(statusCode, body, statusLine)
                else
                    appendDiscordDebugLog("response_body", tostring(body or ""))
                    local errText = trim(normalizeDiscordErrorText(requestErr))
                    if errText == "" then
                        errText = trim(normalizeDiscordErrorText(statusLine))
                    end
                    if errText == "" then
                        errText = "https request failed"
                    end
                    appendDiscordDebugLog("effil_request_error", errText)
                    reject(errText)
                end
                return
            elseif status == "canceled" then
                appendDiscordDebugLog("effil_canceled", "canceled")
                unregisterManagedThread(managedThreadId)
                reject("canceled")
                return
            end

            wait(0)
        end
    end)
end

local function sendDiscordPayload(url, payload)
    if DATA.scriptTerminating then
        return false, "script terminating"
    end

    if CONST.DISCORD_SENDING_DISABLED then
        return false, "отправка временно отключена"
    end

    url = sanitizeWebhookUrl(url)
    payload = stripZeroBytes(tostring(payload or ""))
    local requestPayload = payload

    if url == "" then
        return false, "Пустой webhook"
    end

    if payload == "" then
        return false, "Пустой payload"
    end

    DATA.discordLastStatusText = "running"
    DATA.discordPendingRequests = (tonumber(DATA.discordPendingRequests) or 0) + 1
    appendDiscordDebugLog("send_start", "url=" .. tostring(url))
    appendDiscordDebugLog("send_payload", "length=" .. tostring(#payload) .. " | preview=" .. previewDiscordDebugText(payload, 300))
    appendDiscordDebugLog("send_payload_request", "length=" .. tostring(#requestPayload) .. " | preview=" .. previewDiscordDebugText(requestPayload, 300))

    asyncDiscordHttpRequest(
        "POST",
        url,
        {
            headers = {
                ["content-type"] = "application/json; charset=utf-8"
            },
            data = requestPayload
        },
        function(statusCode, body, statusLine)
            finishDiscordRequest()
            if DATA.scriptTerminating then
                return
            end

            statusCode = tonumber(statusCode) or 204
            body = trim(tostring(body or "")):gsub("[\r\n]+", " ")
            appendDiscordDebugLog("response_status", "status_code=" .. tostring(statusCode))
            appendDiscordDebugLog("response_status_line", tostring(statusLine or ""))
            appendDiscordDebugLog("response_body", body)

            if statusCode >= 200 and statusCode < 300 then
                DATA.discordLastStatusText = "ok"
                DATA.discordLastErrorText = ""
                appendDiscordDebugLog("send_success", "status_code=" .. tostring(statusCode) .. " | body=" .. normalizeDiscordDebugText(body))
            else
                local errorText = "HTTP " .. tostring(statusCode)
                if body ~= "" then
                    errorText = errorText .. ": " .. body
                end
                DATA.discordLastStatusText = "failed"
                DATA.discordLastErrorText = errorText
                appendDiscordDebugLog("send_http_error", "status_code=" .. tostring(statusCode) .. " | body=" .. normalizeDiscordDebugText(body))
                reportDiscordQueueError("Discord send failed: " .. errorText)
            end
        end,
        function(err)
            finishDiscordRequest()
            if DATA.scriptTerminating then
                return
            end

            local errorText = trim(normalizeDiscordErrorText(err))
            if errorText == "" then
                errorText = "неизвестная ошибка"
            end

            DATA.discordLastStatusText = "failed"
            DATA.discordLastErrorText = errorText
            appendDiscordDebugLog("send_runtime_error", errorText)
            reportDiscordQueueError("Discord send failed: " .. errorText)
        end
    )

    return true, "started"
end

local function buildDiscordEmbedPayload(title, description, color, footerText)
    local finalDescription = withDiscordTimeHeader(description)
    return string.format(
        '{"content":null,"embeds":[{"title":"%s","description":"%s","color":%d,"footer":{"text":"%s"}}],"attachments":[]}',
        jsonEscape(title),
        jsonEscape(finalDescription),
        tonumber(color) or 16729344,
        jsonEscape(footerText or "Ghetto Discord Assistant")
    )
end

sendDiscordEmbed = function(url, title, description, color, footerText)
    local payload = buildDiscordEmbedPayload(title, description, color, footerText)
    local ok, result = sendDiscordPayload(url, payload)
    if not ok then
        reportDiscordQueueError(tostring(result or "не удалось запустить Discord отправку"))
    end
    return ok, result
end

sendDiscordEmbedsSequential = function(url, chunks, titleBase, color, footerText)
    if not url or url == "" then
        return
    end

    DATA.discordSequenceWorkers = (tonumber(DATA.discordSequenceWorkers) or 0) + 1
    lua_thread.create(function()
        for i = 1, #chunks do
            if DATA.scriptTerminating or THREADS.shuttingDown or DATA.captureDiscordClosed or isCaptureDiscordTailExpired() then
                finishDiscordSequenceWorker()
                return
            end

            local title = titleBase
            if #chunks > 1 then
                title = string.format("%s [%d/%d]", titleBase, i, #chunks)
            end

            local ok, result = sendDiscordEmbed(
                url,
                title,
                "```" .. chunks[i] .. "```",
                color,
                footerText
            )
            if not ok then
                reportDiscordQueueError(tostring(result or "не удалось запустить Discord отправку"))
                finishDiscordSequenceWorker()
                return
            end

            if i < #chunks then
                wait(CONST.DISCORD_CHUNK_SEND_DELAY_MS or 1100)
                if DATA.scriptTerminating or THREADS.shuttingDown or DATA.captureDiscordClosed or isCaptureDiscordTailExpired() then
                    finishDiscordSequenceWorker()
                    return
                end
            end
        end
        finishDiscordSequenceWorker()
    end)
end

local function buildTopText(src)
    local arr = sortedStats(src)
    if #arr == 0 then
        return "ТОП ИГРОКОВ:\n\nНет фрагов"
    end

    local lines = { "ТОП ИГРОКОВ:", "" }
    local limit = intValue(INTS.maxTopBuffer, CFG.main.max_top_players or 10)
    if limit < 1 then limit = 10 end
    if limit > 20 then limit = 20 end

    for i = 1, math.min(#arr, limit) do
        table.insert(lines, string.format("%s - %d фрагов", arr[i].nick, arr[i].kills))
    end

    return table.concat(lines, "\n")
end

local function getOnlineGangStatsSnapshot()
    local result = {
        ballas = 0,
        grove = 0,
        vagos = 0,
        rifa = 0,
        aztecas = 0
    }
    local meta = {
        totalOnline = 0,
        totalResolved = 0,
        totalLiveResolved = 0,
        uniqueGangCount = 0,
        dominantGangKey = nil,
        dominantCount = 0
    }
    local uniqueGangs = {}

    for id in pairs(DATA.onlinePlayersById or {}) do
        meta.totalOnline = meta.totalOnline + 1
        local gangKey = resolveGangKeyByColor(getCachedPlayerColor(id))
        if gangKey then
            result[gangKey] = (result[gangKey] or 0) + 1
            meta.totalResolved = meta.totalResolved + 1
            if tostring((DATA.playerColorSourceById or {})[id] or "") == "live" then
                meta.totalLiveResolved = meta.totalLiveResolved + 1
            end
            if not uniqueGangs[gangKey] then
                uniqueGangs[gangKey] = true
                meta.uniqueGangCount = meta.uniqueGangCount + 1
            end
            if (result[gangKey] or 0) > (meta.dominantCount or 0) then
                meta.dominantCount = result[gangKey] or 0
                meta.dominantGangKey = gangKey
            end
        end
    end

    return result, meta
end

local function isOnlineGangSnapshotStable(meta)
    meta = type(meta) == "table" and meta or {}

    if os.clock() < (tonumber(DATA.onlineWarmupUntil) or 0) then
        return false
    end

    local totalOnline = tonumber(meta.totalOnline) or 0
    local totalResolved = tonumber(meta.totalResolved) or 0
    local totalLiveResolved = tonumber(meta.totalLiveResolved) or 0
    local uniqueGangCount = tonumber(meta.uniqueGangCount) or 0

    if totalOnline <= 0 then
        return false
    end

    if totalResolved <= 0 then
        return false
    end

    if totalLiveResolved < math.min(3, totalOnline) then
        return false
    end

    if uniqueGangCount <= 1 and totalLiveResolved < totalOnline then
        return false
    end

    return true
end

local function getOnlineGangStats()
    local result, meta = getOnlineGangStatsSnapshot()
    if isOnlineGangSnapshotStable(meta) then
        DATA.onlineStatsStabilized = true
    end
    return result
end

local function getOnlineGangStatsDirect()
    local result = {
        ballas = 0,
        grove = 0,
        vagos = 0,
        rifa = 0,
        aztecas = 0
    }

    local myId = -1
    local ok, playerId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if ok and playerId ~= nil then
        myId = tonumber(playerId) or -1
    end

    for id = 0, CONST.MAX_PLAYER_ID do
        if id == myId or sampIsPlayerConnected(id) then
            local gangKey = resolveGangKeyByColor(tonumber(sampGetPlayerColor(id)))
            if gangKey then
                result[gangKey] = (result[gangKey] or 0) + 1
            end
        end
    end

    return result
end

function APP.getDirectOnlineGangPlayers()
    local rows = {}

    local myId = -1
    local ok, playerId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if ok and playerId ~= nil then
        myId = tonumber(playerId) or -1
    end

    for id = 0, CONST.MAX_PLAYER_ID do
        if id == myId or sampIsPlayerConnected(id) then
            local nick = tryGetLivePlayerNickname(id) or getPlayerNameById(id)
            local gangKey = resolveGangKeyByColor(tonumber(sampGetPlayerColor(id)))
            if nick and nick ~= "" and not string.find(nick, "Игрок_", 1, true) then
                table.insert(rows, {
                    id = id,
                    nick = nick,
                    gangKey = gangKey
                })
            end
        end
    end

    return rows
end

local function collectStableOnlineGangStatsAsync(onReady)
    if type(onReady) ~= "function" then
        return false
    end

    if DATA.onlineStatsCollectActive then
        table.insert(DATA.onlineStatsCollectCallbacks, onReady)
        return true
    end

    DATA.onlineStatsCollectActive = true
    DATA.onlineStatsCollectCallbacks = { onReady }

    lua_thread.create(function()
        local deadline = os.clock() + (tonumber(CONST.ONLINE_PREPARE_MAX_WAIT_SECONDS) or 6.0)
        local lastStats, lastMeta = getOnlineGangStatsSnapshot()
        local timedOut = false

        while not DATA.scriptTerminating do
            refreshOnlinePlayersSnapshot(true, true)
            lastStats, lastMeta = getOnlineGangStatsSnapshot()

            if isOnlineGangSnapshotStable(lastMeta) then
                DATA.onlineStatsStabilized = true
                timedOut = false
                break
            end

            if os.clock() >= deadline then
                timedOut = true
                break
            end

            wait(tonumber(CONST.ONLINE_PREPARE_RETRY_MS) or 900)
        end

        local callbacks = DATA.onlineStatsCollectCallbacks or {}
        DATA.onlineStatsCollectCallbacks = {}
        DATA.onlineStatsCollectActive = false

        for i = 1, #callbacks do
            pcall(callbacks[i], lastStats, lastMeta, timedOut)
        end
    end)

    return true
end

local function getPlayerGangKeyById(id)
    if not isCachedPlayerOnline(id) then
        return nil
    end

    return resolveGangKeyByColor(getCachedPlayerColor(id))
end

function APP.getOnlineBantachkaMatches()
    local tracked = {}
    local accounts = APP.getBantachkaAccountsList()
    for i = 1, #accounts do
        local nick = normalizeNick(accounts[i])
        local key = nick:lower()
        if nick ~= "" and not tracked[key] then
            tracked[key] = nick
        end
    end

    if next(tracked) == nil then
        return {}
    end

    local matches = {}
    local rows = APP.getDirectOnlineGangPlayers()
    for i = 1, #rows do
        local nick = tostring(rows[i].nick or "")
        local nickKey = normalizeNick(nick):lower()
        if tracked[nickKey] then
            table.insert(matches, {
                id = tonumber(rows[i].id) or -1,
                nick = nick,
                gangKey = rows[i].gangKey
            })
            tracked[nickKey] = nil
        end
    end

    table.sort(matches, function(a, b)
        return tostring(a.nick or ""):lower() < tostring(b.nick or ""):lower()
    end)

    return matches
end

function APP.buildBantachkaDiscordLines(matches)
    local lines = {}
    for i = 1, #(matches or {}) do
        local nick = tostring(matches[i].nick or "")
        if nick ~= "" then
            table.insert(lines, string.format("Онлайн бантачка %s, возможно будет донатить", nick))
        end
    end
    return lines
end

function APP.notifyCaptureStartBantachka()
    local c = STATE.capture
    if c.bantachkaNotified then
        return {}
    end

    local matches = APP.getOnlineBantachkaMatches()
    c.bantachkaNotified = true

    for i = 1, #matches do
        local id = tonumber(matches[i].id) or -1
        local nick = tostring(matches[i].nick or "")
        if id >= 0 then
            chat(COLORS.GOLD .. "Онлайн бантачка " .. colorizeName(id, nick) .. COLORS.WHITE .. ", возможно будет донатить")
        else
            chat(COLORS.GOLD .. "Онлайн бантачка " .. COLORS.WHITE .. nick .. COLORS.WHITE .. ", возможно будет донатить")
        end
    end

    return matches
end

rebuildCaptureOverlayEntries = function()
    local c = STATE.capture
    c.overlayEntries = {}
    DATA.captureTopOverlayEntries = {}
    if not c.active then
        return
    end

    loadCaptureIgnoreNicks(false)

    local onlinePlayersByNick = {}

    for id in pairs(DATA.onlinePlayersById or {}) do
        local nick = getPlayerNameById(id)
        local playerColor = getCachedPlayerColor(id) or 0xFFFFFFFF
        onlinePlayersByNick[nick] = {
            id = id,
            color = playerColor
        }

        local gangKey = resolveGangKeyByColor(playerColor)
        if gangKey and c.participants[gangKey] and not isCaptureNickIgnored(nick) then
            local nickKey = normalizeNick(nick):lower()
            if not c.deadPlayers[nickKey] then
                table.insert(c.overlayEntries, {
                    id = id,
                    nick = nick,
                    gangKey = gangKey,
                    kills = tonumber(c.stats[nick] or 0) or 0
                })
            end
        end
    end

    table.sort(c.overlayEntries, function(a, b)
        if a.gangKey ~= b.gangKey then
            return tostring(a.gangKey) < tostring(b.gangKey)
        end
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)

    local sorted = sortedStats(c.stats or {})
    for i = 1, math.min(#sorted, 6) do
        local nick = tostring(sorted[i].nick or "")
        local online = onlinePlayersByNick[nick]
        table.insert(DATA.captureTopOverlayEntries, {
            index = i,
            nick = nick,
            id = online and tonumber(online.id) or -1,
            kills = tonumber(sorted[i].kills) or 0,
            color = online and tonumber(online.color) or 0xFFFFFFFF
        })
    end
end

markCapturePlayerDead = function(playerId)
    local c = STATE.capture
    if not c.active then
        return
    end

    local id = tonumber(playerId) or -1
    if id < 0 or id == 65535 then
        return
    end

    local nick = getPlayerNameById(id)
    local gangKey = getPlayerGangKeyById(id)
    if not nick then
        return
    end

    if gangKey and not c.manualAssistMode and not c.participants[gangKey] then
        return
    end

    c.deadPlayers[normalizeNick(nick):lower()] = true
    requestCaptureOverlayRefresh()
    persistActiveCaptureState()
end

local function showGangStatsToMe(statsData)
    chat(COLORS.WHITE .. "Онлайн банды:")
    chat("{FF00FF}The Ballas: " .. tostring(statsData.ballas or 0))
    chat("{00FF00}Grove Street: " .. tostring(statsData.grove or 0))
    chat("{FFFF00}Los Santos Vagos: " .. tostring(statsData.vagos or 0))
    chat("{6666FF}The Rifa: " .. tostring(statsData.rifa or 0))
    chat("{00CCFF}Varios Loz Aztecas: " .. tostring(statsData.aztecas or 0))
end

local function sendGangStatsToAdminChat(statsData)
    local msg = string.format(
        "TBG: %d | GS: %d | LSV: %d | Rifa: %d | VLA: %d",
        statsData.ballas or 0,
        statsData.grove or 0,
        statsData.vagos or 0,
        statsData.rifa or 0,
        statsData.aztecas or 0
    )
    sampSendChat(utf8_to_cp1251("/a " .. msg))
end

local function sendGangStatsToDiscord(statsData, title, extraLines)
    if CONST.DISCORD_SENDING_DISABLED then
        if not DATA.discordDisabledNoticeShown then
            DATA.discordDisabledNoticeShown = true
            chatInfo("Discord-отправка временно отключена для антикраш-проверки.")
        end
        return
    end

    if CONST.CAPTURE_DISCORD_SAFE_MODE then
        return false, "Discord онлайн временно отключен в safe-mode"
    end

    local webhook = sanitizeWebhookUrl(bufferValue(BUFF.onlineWebhookBuffer, CFG.online.webhook_url))
    if webhook == "" then
        chatError("Вебхук онлайна банд пустой.")
        return
    end

    local lines = {}
    local topLines = {}
    local bottomLines = {}

    if type(extraLines) == "table" and (extraLines.top_lines or extraLines.bottom_lines) then
        topLines = extraLines.top_lines or {}
        bottomLines = extraLines.bottom_lines or {}
    elseif type(extraLines) == "table" then
        topLines = extraLines
    end

    if #topLines > 0 then
        for i = 1, #topLines do
            table.insert(lines, tostring(topLines[i]))
        end
        table.insert(lines, "")
    end

    table.insert(lines, "Онлайн банды:")
    table.insert(lines, "The Ballas: " .. tostring(statsData.ballas or 0))
    table.insert(lines, "Grove Street: " .. tostring(statsData.grove or 0))
    table.insert(lines, "Los Santos Vagos: " .. tostring(statsData.vagos or 0))
    table.insert(lines, "The Rifa: " .. tostring(statsData.rifa or 0))
    table.insert(lines, "Varios Loz Aztecas: " .. tostring(statsData.aztecas or 0))

    if #bottomLines > 0 then
        table.insert(lines, "")
        for i = 1, #bottomLines do
            table.insert(lines, tostring(bottomLines[i]))
        end
    end

    local ok, result = sendDiscordEmbed(
        webhook,
        title or "Онлайн банд",
        "```" .. table.concat(lines, "\n") .. "```",
        intValue(INTS.onlineEmbedColorBuffer, CFG.online.embed_color or 16729344),
        "онлайн"
    )
    return ok, result
end

local function sendPreparedGangStatsToDiscord(title, extraLines, sourceLabel)
    sourceLabel = tostring(sourceLabel or "онлайна банд")

    if os.clock() < (tonumber(DATA.onlineSendGuardUntil) or 0) then
        if boolValue(BOOLS.localFeedBool, CFG.main.local_chat_feed ~= false) then
            chatInfo("Онлайн банд уже готовится или только что отправлялся. Подожди пару секунд.")
        end
        return false
    end

    DATA.onlineSendGuardUntil = os.clock() + (tonumber(CONST.ONLINE_SEND_GUARD_SECONDS) or 4.0)
    local ok = sendGangStatsToDiscord(getOnlineGangStatsDirect(), title, extraLines)
    if ok and boolValue(BOOLS.localFeedBool, CFG.main.local_chat_feed ~= false) then
        DATA.onlineSendGuardUntil = os.clock() + (tonumber(CONST.ONLINE_SEND_GUARD_SECONDS) or 4.0)
        chatInfo("Discord: " .. sourceLabel .. " отправляется.")
    elseif not ok then
        DATA.onlineSendGuardUntil = os.clock() + 1.5
    end

    return ok == true
end

local function sendCaptureStartOnline()
    local c = STATE.capture
    if c.onlineSent then return end

    local bantachkaMatches = APP.notifyCaptureStartBantachka()
    if not boolValue(BOOLS.autoOnlineOnCaptureStartBool, CFG.online.auto_send_on_capture_start ~= false) then return end
    if c.startLine == "" or c.initiatorLine == "" then return end

    local extraLines = {
        top_lines = { c.startLine, c.initiatorLine },
        bottom_lines = {}
    }
    local bantachkaLines = APP.buildBantachkaDiscordLines(bantachkaMatches)
    for i = 1, #bantachkaLines do
        table.insert(extraLines.bottom_lines, bantachkaLines[i])
    end

    sendPreparedGangStatsToDiscord(
        "Старт захвата: онлайн банд",
        extraLines,
        "онлайн со старта захвата"
    )

    c.onlineSent = true
    persistActiveCaptureState()
end

local function startPunishLogging()
    local c = STATE.capture
    c.punishLogging = true
    c.punishes = {}
    persistActiveCaptureState()
end

local function stopPunishLogging()
    STATE.capture.punishLogging = false
    persistActiveCaptureState()
end

local function addPunishmentLine(text)
    local line = cleanupPunishmentLine(text)
    if line == "" then return end

    local punishes = STATE.capture.punishes
    for i = 1, #punishes do
        if punishes[i] == line then
            return
        end
    end

    table.insert(punishes, line)
    appendLine(PATHS.PUNISH_LOG, withTimestamp(line))
    markGangParticipantsFromText(line)
    persistActiveCaptureState()

    if boolValue(BOOLS.punishShowInChatBool, CFG.punishments.show_success_in_chat ~= false) then
        chatSuccess("Наказание сохранено успешно!")
    end
end

local function startCapture(text)
    resetCapture()
    DATA.postCaptureMuted = false
    DATA.captureDiscordClosed = false
    DATA.captureDiscordDeadline = 0
    DATA.forceUnloadAfterDiscord = false
    DATA.forceUnloadScheduled = false
    DATA.pendingSelfReload = false

    local c = STATE.capture
    c.active = true
    c.startAt = os.time()
    c.startDt = getCaptureDateTimeString(c.startAt)
    c.startLine = normalizeSpaces(removeBrackets(text))

    markGangParticipantsFromText(c.startLine)
    appendLine(PATHS.CAPTURE_LOG, withTimestamp(c.startLine))
    startPunishLogging()
    requestCaptureOverlayRefresh()
    persistActiveCaptureState()

    if boolValue(BOOLS.fragShowMessagesBool, CFG.fraglist.show_status_messages_in_chat ~= false)
        and boolValue(BOOLS.localFeedBool, CFG.main.local_chat_feed ~= false) then
        chat(COLORS.INFO .. c.startLine)
    end
end

local function startCaptureAssistMode()
    if STATE.capture.active then
        chatInfo("Капт уже активен. Вспомогательный режим не требуется.")
        return
    end

    resetCapture()
    DATA.postCaptureMuted = false
    DATA.captureDiscordClosed = false
    DATA.captureDiscordDeadline = 0
    DATA.forceUnloadAfterDiscord = false
    DATA.forceUnloadScheduled = false
    DATA.pendingSelfReload = false

    local c = STATE.capture
    c.active = true
    c.startAt = os.time()
    c.startDt = getCaptureDateTimeString(c.startAt)
    c.startLine = "Вспомогательный режим капта запущен вручную"
    c.manualAssistMode = true
    c.sendLogsOnFinish = false
    c.onlineSent = true
    c.punishLogging = boolValue(BOOLS.punishEnabledBool, CFG.punishments.enabled ~= false)

    for _, gang in ipairs(GANGS.list) do
        c.participants[gang.key] = true
    end

    requestCaptureOverlayRefresh()
    persistActiveCaptureState()

    chatInfo("Вспомогательный режим капта включен.")
    chatInfo("Discord-логи этого капта отправляться не будут, но фраглист, слежка и оверлеи уже активны.")
end

local function addCaptureMessage(text)
    local c = STATE.capture
    if not c.active then return end

    local clean = normalizeSpaces(removeBrackets(text))

    if string.find(clean, "инициировал захват", 1, true) then
        c.initiatorLine = clean
        markGangParticipantsFromText(c.initiatorLine)
        c.manualAssistMode = false
        requestCaptureOverlayRefresh()

        if boolValue(BOOLS.fragShowMessagesBool, CFG.fraglist.show_status_messages_in_chat ~= false)
            and boolValue(BOOLS.localFeedBool, CFG.main.local_chat_feed ~= false) then
            chat(COLORS.INFO .. c.initiatorLine)
        end

        appendLine(PATHS.CAPTURE_LOG, withTimestamp(clean))
        persistActiveCaptureState()
        sendCaptureStartOnline()
        return
    end

    appendLine(PATHS.CAPTURE_LOG, withTimestamp(clean))
    requestCaptureOverlayRefresh()
    persistActiveCaptureState()
end

local function recordCaptureKill(killerId, victimId)
    local c = STATE.capture
    if not c.active then return end

    local killerNick = getPlayerNameById(killerId)
    local victimNick = getPlayerNameById(victimId)

    c.total = c.total + 1
    c.stats[killerNick] = (c.stats[killerNick] or 0) + 1

    local line = string.format("%s убил %s", killerNick, victimNick)
    table.insert(c.kills, line)
    appendLine(PATHS.CAPTURE_LOG, withTimestamp(line))
    requestCaptureOverlayRefresh()
    persistActiveCaptureState()
end

local function buildCaptureKillListLinesFromData(captureData)
    local lines = {}

    if captureData.start_line ~= "" then
        table.insert(lines, captureData.start_line)
    end
    if captureData.initiator_line ~= "" then
        table.insert(lines, captureData.initiator_line)
    end

    table.insert(lines, "")
    table.insert(lines, "")

    if captureData.kills and #captureData.kills > 0 then
        for i = 1, #captureData.kills do
            table.insert(lines, captureData.kills[i])
        end
    else
        table.insert(lines, "Убийств за захват не было")
    end

    table.insert(lines, "")
    table.insert(lines, "")

    if captureData.end_line ~= "" then
        table.insert(lines, captureData.end_line)
    end

    table.insert(lines, "")
    table.insert(lines, "")

    local topText = buildTopText(captureData.stats or {})
    for line in topText:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    return lines
end

local function buildCapturePunishLinesFromData(captureData)
    local lines = {}

    if captureData.start_line ~= "" then
        table.insert(lines, captureData.start_line)
    end
    if captureData.initiator_line ~= "" then
        table.insert(lines, captureData.initiator_line)
    end

    table.insert(lines, "")
    table.insert(lines, "")

    if captureData.punishes and #captureData.punishes > 0 then
        for i = 1, #captureData.punishes do
            table.insert(lines, captureData.punishes[i])
        end
    else
        table.insert(lines, "Наказаний за захват не было")
    end

    table.insert(lines, "")
    table.insert(lines, "")

    if captureData.end_line ~= "" then
        table.insert(lines, captureData.end_line)
    end

    local warnSummary = buildPunishmentGangWarnSummary(captureData)
    if #warnSummary > 0 then
        table.insert(lines, "")
        table.insert(lines, "")
        table.insert(lines, "Варны по бандам:")
        for i = 1, #warnSummary do
            table.insert(lines, warnSummary[i])
        end
    end

    return lines
end

local function splitLinesForDiscord(lines, limit)
    local chunks = {}
    local current = ""

    for i = 1, #lines do
        local line = tostring(lines[i])
        local candidate = (current == "" and line) or (current .. "\n" .. line)

        if #candidate > limit then
            if current ~= "" then
                table.insert(chunks, current)
                current = line
            else
                table.insert(chunks, line:sub(1, limit))
                current = ""
            end
        else
            current = candidate
        end
    end

    if current ~= "" then
        table.insert(chunks, current)
    end

    return chunks
end

local function getRecoveryAgeText(startAt)
    local age = os.time() - (tonumber(startAt) or 0)
    if age < 0 then age = 0 end
    return string.format("%d сек", age)
end

function APP.isNickOnline(targetNick)
    targetNick = trim(targetNick)
    if targetNick == "" then
        return false
    end

    local targetLower = targetNick:lower()
    local rows = APP.getDirectOnlineGangPlayers()
    for i = 1, #rows do
        local nick = tostring(rows[i].nick or "")
        if nick ~= "" and nick:lower() == targetLower then
            return true, rows[i].id, nick
        end
    end

    return false, -1, targetNick
end

function APP.getPriorityCheckResult()
    if not boolValue(BOOLS.priorityEnabledBool, CFG.priority.enabled == true) then
        return true, {}
    end

    local admins = APP.getPriorityAdminsList()
    if #admins == 0 then
        return true, {}
    end

    local myNick = getMyNick()
    if not myNick or myNick == "" then
        return true, {}
    end

    local myIndex = nil
    local myLower = myNick:lower()

    for i = 1, #admins do
        if admins[i]:lower() == myLower then
            myIndex = i
            break
        end
    end

    local blocking = {}

    for i = 1, #admins do
        local online, _, onlineNick = APP.isNickOnline(admins[i])
        if online then
            if myIndex then
                if i < myIndex then
                    table.insert(blocking, onlineNick)
                end
            else
                table.insert(blocking, onlineNick)
            end
        end
    end

    return #blocking == 0, blocking
end

function APP.runPriorityDebug()
    local enabled = boolValue(BOOLS.priorityEnabledBool, CFG.priority.enabled == true)
    local askConfirm = boolValue(BOOLS.priorityAskConfirmBool, CFG.priority.ask_confirmation ~= false)
    local admins = APP.getPriorityAdminsList()
    local myNick = getMyNick() or ""
    local myLower = myNick ~= "" and myNick:lower() or ""
    local myIndex = nil

    chat(COLORS.LINE .. CONST.LINE_TEXT)
    chat(COLORS.GOLD .. "DEBUG ПРИОРИТЕТА")
    chat(COLORS.WHITE .. "Включен: " .. (enabled and "да" or "нет") .. " | Подтверждение: " .. (askConfirm and "да" or "нет"))
    chat(COLORS.WHITE .. "Мой ник: " .. (myNick ~= "" and myNick or "не определен"))
    chat(COLORS.WHITE .. "Ников в списке: " .. tostring(#admins))

    for i = 1, #admins do
        if admins[i]:lower() == myLower then
            myIndex = i
            break
        end
    end

    if myIndex then
        chat(COLORS.WHITE .. "Мой индекс в приоритете: " .. tostring(myIndex))
    else
        chat(COLORS.RED .. "Мой ник не найден в списке приоритета.")
    end

    if #admins == 0 then
        chat(COLORS.INFO .. "Список приоритета пустой, поэтому отправка всегда разрешена.")
    end

    for i = 1, #admins do
        local online, id, onlineNick = APP.isNickOnline(admins[i])
        local prefix = online and COLORS.GREEN or COLORS.RED
        local relation = ""

        if myIndex then
            if i < myIndex then
                relation = " | выше меня"
            elseif i == myIndex then
                relation = " | это я"
            else
                relation = " | ниже меня"
            end
        end

        if online then
            chat(prefix .. tostring(i) .. ". " .. COLORS.WHITE .. admins[i] .. COLORS.ACCENT .. " -> ONLINE: " .. tostring(onlineNick) .. "[" .. tostring(id) .. "]" .. relation)
        else
            chat(prefix .. tostring(i) .. ". " .. COLORS.WHITE .. admins[i] .. COLORS.ACCENT .. " -> OFFLINE" .. relation)
        end
    end

    local allowed, blockingAdmins = APP.getPriorityCheckResult()
    if allowed then
        chat(COLORS.GREEN .. "Итог: отправка РАЗРЕШЕНА")
    else
        chat(COLORS.RED .. "Итог: отправка ЗАБЛОКИРОВАНА")
        for i = 1, #blockingAdmins do
            chat(COLORS.GOLD .. "Блокирует: " .. COLORS.WHITE .. tostring(blockingAdmins[i]))
        end
    end

    chat(COLORS.LINE .. CONST.LINE_TEXT)
end

local function actuallySendCaptureToDiscord(captureData)
    if CONST.DISCORD_SENDING_DISABLED then
        if not DATA.discordDisabledNoticeShown then
            DATA.discordDisabledNoticeShown = true
            chatInfo("Discord-отправка временно отключена для антикраш-проверки.")
        end
        return
    end

    local fragWebhook = sanitizeWebhookUrl(bufferValue(BUFF.fragWebhookBuffer, CFG.fraglist.webhook_url))
    local punishWebhook = sanitizeWebhookUrl(bufferValue(BUFF.punishWebhookBuffer, CFG.punishments.webhook_url))

    local summaryText = string.format(
        "%s\n%s\n\nВсего убийств: %d\nДлительность: %d сек",
        captureData.start_line ~= "" and captureData.start_line or "Старт не найден",
        captureData.end_line ~= "" and captureData.end_line or "Итог не найден",
        captureData.total or 0,
        captureData.duration or 0
    )

    if boolValue(BOOLS.fragSendSummaryBool, CFG.fraglist.send_summary ~= false) then
        if fragWebhook == "" then
            chatError("Вебхук логов захвата пустой.")
        else
            sendDiscordEmbed(
                fragWebhook,
                "Сводка по захвату",
                summaryText,
                intValue(INTS.fragEmbedColorBuffer, CFG.fraglist.embed_color or 16729344),
                "захват"
            )
        end
    end

    if boolValue(BOOLS.fragSendTopBool, CFG.fraglist.send_top ~= false) and (captureData.total or 0) > 0 then
        if fragWebhook == "" then
            chatError("Вебхук логов захвата пустой.")
        else
            sendDiscordEmbed(
                fragWebhook,
                "Топ по фрагам",
                buildTopText(captureData.stats or {}),
                intValue(INTS.fragEmbedColorBuffer, CFG.fraglist.embed_color or 16729344),
                "захват"
            )
        end
    end

    if boolValue(BOOLS.fragSendDetailsBool, CFG.fraglist.send_details ~= false) then
        if fragWebhook == "" then
            chatError("Вебхук логов захвата пустой.")
        else
            local killChunks = splitLinesForDiscord(buildCaptureKillListLinesFromData(captureData), 3500)
            sendDiscordEmbedsSequential(
                fragWebhook,
                killChunks,
                "Килллист захвата",
                intValue(INTS.fragEmbedColorBuffer, CFG.fraglist.embed_color or 16729344),
                "детали"
            )
        end
    end

    if boolValue(BOOLS.punishEnabledBool, CFG.punishments.enabled ~= false) and punishWebhook ~= "" then
        local punishChunks = splitLinesForDiscord(buildCapturePunishLinesFromData(captureData), 3500)
        sendDiscordEmbedsSequential(
            punishWebhook,
            punishChunks,
            "Наказания за захват",
            intValue(INTS.punishEmbedColorBuffer, CFG.punishments.embed_color or 15158332),
            "наказания"
        )
    elseif boolValue(BOOLS.punishEnabledBool, CFG.punishments.enabled ~= false) and punishWebhook == "" and captureData.punishes and #captureData.punishes > 0 then
        chatError("Вебхук наказаний пустой.")
    end

    if boolValue(BOOLS.localFeedBool, CFG.main.local_chat_feed ~= false) then
        chatInfo("Отправка логов в Discord запущена.")
    end
end

local function requestCaptureSendWithPriorityCheck(captureData, sourceTitle)
    if CONST.DISCORD_SENDING_DISABLED then
        if not DATA.discordDisabledNoticeShown then
            DATA.discordDisabledNoticeShown = true
            chatInfo("Discord-отправка временно отключена для антикраш-проверки.")
        end
        return
    end

    if not isSafeGameRenderState() then
        DATA.deferredCaptureAutoSend = {
            capture = captureData,
            source = tostring(sourceTitle or "")
        }
        return
    end

    local allowed, blockingAdmins = APP.getPriorityCheckResult()
    if allowed then
        actuallySendCaptureToDiscord(captureData)
        return
    end

    if boolValue(BOOLS.priorityAskConfirmBool, CFG.priority.ask_confirmation ~= false) then
        DATA.pendingCaptureToSend = captureData
        savePendingCaptureSnapshot()

        chat(COLORS.RED .. "В онлайне находятся более приоритетные администраторы")
        for i = 1, #blockingAdmins do
            chat(COLORS.GOLD .. " - " .. COLORS.WHITE .. blockingAdmins[i])
        end
        chat(COLORS.WHITE .. "Уверены, что хотите отправить логи с каптов?")
        chat(COLORS.ACCENT .. "Подтверждение: " .. COLORS.WHITE .. "/captconfirm")
        chat(COLORS.ACCENT .. "Отмена: " .. COLORS.WHITE .. "/captcancel")
        if sourceTitle and sourceTitle ~= "" then
            chat(COLORS.ACCENT .. "Источник: " .. COLORS.WHITE .. sourceTitle)
        end
    else
        chatError("Отправка логов остановлена. Более приоритетный администратор в онлайне.")
    end
end

local function stopCaptureAndSend(resultText)
    local c = STATE.capture
    if not c.active then
        return
    end

    c.active = false
    c.endLine = normalizeSpaces(removeBrackets(resultText or "Захват завершён"))
    markGangParticipantsFromText(c.endLine)

    appendLine(PATHS.CAPTURE_LOG, withTimestamp(c.endLine))

    if boolValue(BOOLS.fragShowMessagesBool, CFG.fraglist.show_status_messages_in_chat ~= false)
        and boolValue(BOOLS.localFeedBool, CFG.main.local_chat_feed ~= false) then
        chat(COLORS.INFO .. c.endLine)
    end

    stopPunishLogging()

    local captureData = buildCurrentCaptureData(c.endLine)
    DATA.lastCapture = captureData
    saveLastCaptureSnapshot()
    appendCaptureSessionBlock(captureData)

    clearActiveCaptureState()
    DATA.captureDiscordClosed = false
    DATA.captureDiscordDeadline = os.clock() + (tonumber(CONST.CAPTURE_DISCORD_MAX_TAIL_SECONDS) or 20)
    DATA.forceUnloadAfterDiscord = true
    DATA.forceUnloadScheduled = false
    DATA.pendingSelfReload = false
    enterPostCaptureQuietMode()
    actuallySendCaptureToDiscord(captureData)
    tryUnloadAfterDiscordFlush()
    resetCapture()
end

local function formatHotkeyText(vk, useCtrl, useAlt, useShift)
    local parts = {}
    if useCtrl then table.insert(parts, "CTRL") end
    if useAlt then table.insert(parts, "ALT") end
    if useShift then table.insert(parts, "SHIFT") end

    local keyName = tostring(vk)
    if vk == 0x48 then keyName = "H" end
    if vk == 0x47 then keyName = "G" end
    if vk == 0x46 then keyName = "F" end
    if vk == 0x45 then keyName = "E" end
    if vk == 0x77 then keyName = "F8" end
    if vk == 0x70 then keyName = "F1" end
    if vk == 0x71 then keyName = "F2" end
    if vk == 0x72 then keyName = "F3" end
    if vk == 0x73 then keyName = "F4" end
    if vk == 0x74 then keyName = "F5" end
    if vk == 0x75 then keyName = "F6" end
    if vk == 0x76 then keyName = "F7" end
    if vk == 0x78 then keyName = "F9" end
    if vk == 0x79 then keyName = "F10" end
    if vk == 0x7A then keyName = "F11" end
    if vk == 0x7B then keyName = "F12" end

    table.insert(parts, keyName)
    return table.concat(parts, " + ")
end

local function areModifiersPressed(useCtrl, useAlt, useShift)
    if useCtrl and not (isKeyDown(0x11) or isKeyDown(0xA2) or isKeyDown(0xA3)) then
        return false
    end
    if useAlt and not (isKeyDown(0x12) or isKeyDown(0xA4) or isKeyDown(0xA5)) then
        return false
    end
    if useShift and not (isKeyDown(0x10) or isKeyDown(0xA0) or isKeyDown(0xA1)) then
        return false
    end
    return true
end

local function isFollowHotkeyPressedOnce()
    local vk = tonumber(INTS.followHotkeyBuffer.v) or 0x48
    local down = isKeyDown(vk)
    local mods = areModifiersPressed(BOOLS.followUseCtrlBool.v, BOOLS.followUseAltBool.v, BOOLS.followUseShiftBool.v)

    if down and mods and not FOLLOW.hotkeyLatch then
        FOLLOW.hotkeyLatch = true
        return true
    end

    if not down then
        FOLLOW.hotkeyLatch = false
    end

    return false
end

local function resetFollowPrompt()
    FOLLOW.prompt.active = false
    FOLLOW.prompt.killerId = -1
    FOLLOW.prompt.killerName = ""
    FOLLOW.prompt.expireAt = 0
end

local function activateFollowPrompt(killerId, killerName)
    if not BOOLS.followEnabledBool.v then return end
    if not STATE.capture.active then return end
    if killerId == getMyId() then return end

    FOLLOW.prompt.active = true
    FOLLOW.prompt.killerId = killerId
    FOLLOW.prompt.killerName = killerName
    FOLLOW.prompt.expireAt = os.clock() + math.max(1, tonumber(INTS.followPromptSecondsBuffer.v) or 8)

    local hotkeyText = formatHotkeyText(
        tonumber(INTS.followHotkeyBuffer.v) or 0x48,
        BOOLS.followUseCtrlBool.v,
        BOOLS.followUseAltBool.v,
        BOOLS.followUseShiftBool.v
    )

    chat(
        COLORS.GOLD .. "Хотите следить за игроком? " ..
        COLORS.WHITE .. colorizeName(killerId, killerName) ..
        COLORS.ACCENT .. " — нажмите " .. COLORS.WHITE .. hotkeyText
    )
end

local function processFollowPrompt()
    if not FOLLOW.prompt.active then return end
    if os.clock() > FOLLOW.prompt.expireAt then
        resetFollowPrompt()
        return
    end
    if isPauseMenuActive() then return end

    if isFollowHotkeyPressedOnce() then
        local template = tostring(BUFF.followCommandBuffer.v or "/sp %d")
        local cmd = ""

        if template:find("%%d") then
            cmd = string.format(template, FOLLOW.prompt.killerId)
        elseif template:find("%%s") then
            cmd = string.format(template, FOLLOW.prompt.killerName)
        else
            cmd = trim(template) .. " " .. tostring(FOLLOW.prompt.killerId)
        end

        cmd = trim(cmd)
        if cmd ~= "" then
            sampSendChat(utf8_to_cp1251(cmd))
            chatSuccess("Команда слежки отправлена: " .. cmd)
        end

        resetFollowPrompt()
    end
end

local function sendLastCaptureCommand()
    if not DATA.lastCapture then
        local fromDisk = loadCaptureDataFromFile(PATHS.LAST_CAPTURE_STATE_FILE)
        if fromDisk then
            DATA.lastCapture = fromDisk
        end
    end

    if not DATA.lastCapture then
        chatError("Последний капт ещё не сохранён.")
        return
    end

    requestCaptureSendWithPriorityCheck(DATA.lastCapture, "ручная отправка последнего капта")
end

local function confirmPendingCaptureSend()
    if CONST.DISCORD_SENDING_DISABLED then
        DATA.pendingCaptureToSend = nil
        savePendingCaptureSnapshot()
        if not DATA.discordDisabledNoticeShown then
            DATA.discordDisabledNoticeShown = true
            chatInfo("Discord-отправка временно отключена для антикраш-проверки.")
        end
        return
    end

    if not DATA.pendingCaptureToSend then
        local fromDisk = loadCaptureDataFromFile(PATHS.PENDING_CAPTURE_STATE_FILE)
        if fromDisk then
            DATA.pendingCaptureToSend = fromDisk
        end
    end

    if not DATA.pendingCaptureToSend then
        chatError("Нет ожидающей отправки.")
        return
    end

    local captureData = DATA.pendingCaptureToSend
    DATA.pendingCaptureToSend = nil
    savePendingCaptureSnapshot()
    actuallySendCaptureToDiscord(captureData)
end

local function cancelPendingCaptureSend()
    if not DATA.pendingCaptureToSend then
        local fromDisk = loadCaptureDataFromFile(PATHS.PENDING_CAPTURE_STATE_FILE)
        if fromDisk then
            DATA.pendingCaptureToSend = fromDisk
        end
    end

    if not DATA.pendingCaptureToSend then
        chatError("Нет ожидающей отправки.")
        return
    end

    DATA.pendingCaptureToSend = nil
    savePendingCaptureSnapshot()
    chatInfo("Отправка логов отменена.")
end

local function restoreRecoveryInfo()
    DATA.recoveryFileInfo = loadCaptureDataFromFile(PATHS.ACTIVE_CAPTURE_STATE_FILE)
end

local function showCaptureStatus()
    local c = STATE.capture
    if c.active then
        chatInfo("Сейчас активен капт.")
        chat(COLORS.WHITE .. "Старт: " .. (c.startLine ~= "" and c.startLine or "не найден"))
        chat(COLORS.WHITE .. "Инициатор: " .. (c.initiatorLine ~= "" and c.initiatorLine or "не найден"))
        chat(COLORS.WHITE .. "Киллов: " .. tostring(c.total))
        chat(COLORS.WHITE .. "Наказаний: " .. tostring(#c.punishes))
        chat(COLORS.WHITE .. "Стартовал: " .. (c.startDt ~= "" and c.startDt or "неизвестно"))
        return
    end

    local data = loadCaptureDataFromFile(PATHS.ACTIVE_CAPTURE_STATE_FILE)
    if data and data.active then
        chatInfo("Найден recovery-файл незавершённого капта.")
        chat(COLORS.WHITE .. "Старт: " .. (data.start_line ~= "" and data.start_line or "не найден"))
        chat(COLORS.WHITE .. "Инициатор: " .. (data.initiator_line ~= "" and data.initiator_line or "не найден"))
        chat(COLORS.WHITE .. "Киллов: " .. tostring(data.total or 0))
        chat(COLORS.WHITE .. "Наказаний: " .. tostring(data.punishes and #data.punishes or 0))
        chat(COLORS.WHITE .. "Возраст recovery: " .. getRecoveryAgeText(data.start_at))
        chat(COLORS.WHITE .. "Команды: /captresume | /captfinish | /captdrop")
        return
    end

    chatInfo("Активного капта и recovery-файла нет.")
end

local function resumeCaptureFromRecovery()
    if STATE.capture.active then
        chatError("Капт уже активен. Сначала заверши или сбрось текущий.")
        return
    end

    local data = loadCaptureDataFromFile(PATHS.ACTIVE_CAPTURE_STATE_FILE)
    if not data or not data.active then
        chatError("Recovery-файл незавершённого капта не найден.")
        return
    end

    restoreCaptureFromData(data)
    restoreRecoveryInfo()
    DATA.postCaptureMuted = false
    DATA.captureDiscordClosed = false
    DATA.captureDiscordDeadline = 0
    DATA.forceUnloadAfterDiscord = false
    DATA.forceUnloadScheduled = false
    DATA.pendingSelfReload = false

    chatSuccess("Капт восстановлен из recovery-файла.")
    chat(COLORS.WHITE .. "Старт: " .. (STATE.capture.startLine ~= "" and STATE.capture.startLine or "не найден"))
    chat(COLORS.WHITE .. "Инициатор: " .. (STATE.capture.initiatorLine ~= "" and STATE.capture.initiatorLine or "не найден"))
    chat(COLORS.WHITE .. "Киллов: " .. tostring(STATE.capture.total))
    chat(COLORS.WHITE .. "Наказаний: " .. tostring(#STATE.capture.punishes))
end

local function dropCaptureRecovery()
    if STATE.capture.active then
        resetCapture()
    end

    clearActiveCaptureState()
    restoreRecoveryInfo()
    resetFollowPrompt()
    chatInfo("Recovery-файл текущего капта удалён.")
end

local function finishRecoveredCapture(arg)
    local reason = trim(arg or "")
    if not STATE.capture.active then
        local data = loadCaptureDataFromFile(PATHS.ACTIVE_CAPTURE_STATE_FILE)
        if data and data.active then
            restoreCaptureFromData(data)
        end
    end

    if not STATE.capture.active then
        chatError("Нет активного или восстановимого капта для завершения.")
        return
    end

    if reason == "" then
        reason = "Захват завершён вручную после восстановления"
    end

    stopCaptureAndSend(reason)
    restoreRecoveryInfo()
    chatSuccess("Капт завершён вручную.")
end

local function loadRecoveryArtifactsOnStart()
    DATA.lastCapture = loadCaptureDataFromFile(PATHS.LAST_CAPTURE_STATE_FILE)
    DATA.pendingCaptureToSend = loadCaptureDataFromFile(PATHS.PENDING_CAPTURE_STATE_FILE)
    DATA.recoveryFileInfo = loadCaptureDataFromFile(PATHS.ACTIVE_CAPTURE_STATE_FILE)

    if DATA.recoveryFileInfo and DATA.recoveryFileInfo.active then
        local age = os.time() - (tonumber(DATA.recoveryFileInfo.start_at) or 0)
        if age < 0 then age = 0 end

        if age <= CONST.MAX_RECOVERY_AGE_SECONDS then
            restoreCaptureFromData(DATA.recoveryFileInfo)
            chat(COLORS.GOLD .. "Обнаружен незавершённый капт после сбоя. " .. COLORS.WHITE .. "Состояние восстановлено автоматически.")
            chat(COLORS.WHITE .. "Киллов: " .. tostring(STATE.capture.total) .. " | Наказаний: " .. tostring(#STATE.capture.punishes))
        else
            chat(COLORS.RED .. "Найден старый recovery-файл капта (" .. getRecoveryAgeText(DATA.recoveryFileInfo.start_at) .. ").")
            chat(COLORS.WHITE .. "Автовосстановление пропущено. Команды: " .. COLORS.ACCENT .. "/captresume " .. COLORS.WHITE .. "| " .. COLORS.ACCENT .. "/captdrop " .. COLORS.WHITE .. "| " .. COLORS.ACCENT .. "/captstatus")
        end
    end

    if DATA.pendingCaptureToSend then
        chat(COLORS.GOLD .. "После прошлого сбоя найдено ожидающее подтверждения отправки.")
        chat(COLORS.WHITE .. "Команды: " .. COLORS.ACCENT .. "/captconfirm " .. COLORS.WHITE .. "| " .. COLORS.ACCENT .. "/captcancel")
    end
end

local function safeSetStyle(style, key, value)
    pcall(function()
        style[key] = value
    end)
end

local function safeSetColor(colors, colorKey, value)
    pcall(function()
        colors[colorKey] = value
    end)
end

local function drawSectionTitle(text)
    imgui.Spacing()
    local avail = imgui.GetContentRegionAvail().x
    local textWidth = imgui.CalcTextSize(text).x
    local x = (avail - textWidth) * 0.5
    if x > 0 then
        imgui.SetCursorPosX(imgui.GetCursorPosX() + x)
    end
    imgui.TextColored(imgui.ImVec4(0.94, 0.94, 0.93, 1.00), text)
    imgui.Separator()
end

function APP.isCompactMainLayout()
    return imgui.GetContentRegionAvail().x < 920
end

function APP.drawResponsiveInputInt(label, widgetId, intBuffer, helpText)
    imgui.TextWrapped(label)
    imgui.PushItemWidth(-1)
    imgui.InputInt(widgetId, intBuffer)
    imgui.PopItemWidth()
    if helpText and helpText ~= "" then
        imgui.TextWrapped(helpText)
    end
end

function APP.drawWebhookField(buffer, widgetId, editKey)
    local value = sanitizeWebhookUrl(buffer and buffer.v or "")
    local isEditing = UI.webhookEdit and UI.webhookEdit[editKey] == true

    if value == "" or isEditing then
        imgui.PushItemWidth(-110)
        imgui.InputText(widgetId, buffer)
        imgui.PopItemWidth()

        if value ~= "" then
            imgui.SameLine()
            if imgui.Button("Скрыть##" .. editKey, imgui.ImVec2(100, 0)) then
                UI.webhookEdit[editKey] = false
            end
        end
        return
    end

    imgui.TextColored(imgui.ImVec4(0.62, 0.92, 0.64, 1.00), "Вебхук установлен")
    imgui.SameLine()
    if imgui.Button("Изменить##" .. editKey, imgui.ImVec2(100, 0)) then
        UI.webhookEdit[editKey] = true
    end
end

function APP.finishWebhookSave(editKey, buffer)
    local value = sanitizeWebhookUrl(buffer and buffer.v or "")
    UI.webhookEdit[editKey] = (value == "")
end

local function drawTabRecovery()
    drawSectionTitle("Восстановление после краша")

    local data = loadCaptureDataFromFile(PATHS.ACTIVE_CAPTURE_STATE_FILE)
    if data and data.active then
        imgui.TextColored(imgui.ImVec4(1.00, 0.85, 0.35, 1.00), "Найден recovery-файл незавершённого капта")
        imgui.TextWrapped("Старт: " .. (data.start_line ~= "" and data.start_line or "не найден"))
        imgui.TextWrapped("Инициатор: " .. (data.initiator_line ~= "" and data.initiator_line or "не найден"))
        imgui.Text("Киллов: " .. tostring(data.total or 0))
        imgui.Text("Наказаний: " .. tostring(data.punishes and #data.punishes or 0))
        imgui.Text("Возраст recovery: " .. getRecoveryAgeText(data.start_at))
    else
        imgui.TextColored(imgui.ImVec4(0.35, 0.95, 0.45, 1.00), "Recovery-файл текущего капта не найден")
    end

    if DATA.lastCapture then
        imgui.Text("Последний сохранённый капт: есть")
    else
        imgui.Text("Последний сохранённый капт: нет")
    end

    if DATA.pendingCaptureToSend then
        imgui.TextColored(imgui.ImVec4(1.00, 0.75, 0.30, 1.00), "Есть ожидающая отправка после проверки приоритетов")
    else
        imgui.Text("Ожидающая отправка: нет")
    end

    if imgui.Button("Восстановить капт", imgui.ImVec2(200, 34)) then
        resumeCaptureFromRecovery()
    end
    imgui.SameLine()
    if imgui.Button("Принудительно завершить", imgui.ImVec2(220, 34)) then
        finishRecoveredCapture("")
    end
    imgui.SameLine()
    if imgui.Button("Удалить recovery", imgui.ImVec2(190, 34)) then
        dropCaptureRecovery()
    end

    if imgui.Button("Обновить статус recovery", imgui.ImVec2(220, 34)) then
        restoreRecoveryInfo()
        DATA.lastCapture = loadCaptureDataFromFile(PATHS.LAST_CAPTURE_STATE_FILE)
        DATA.pendingCaptureToSend = loadCaptureDataFromFile(PATHS.PENDING_CAPTURE_STATE_FILE)
    end
end

drawTabCapture = function()
    drawSectionTitle("Discord логов захвата")

    imgui.Text("Webhook для логов захвата")
    APP.drawWebhookField(BUFF.fragWebhookBuffer, "##frag_webhook", "frag")

    drawSectionTitle("Команды и возможности")
    drawToggleRow("Сводка по захвату", BOOLS.fragSendSummaryBool, "frag_summary")
    drawToggleRow("Топ по фрагам", BOOLS.fragSendTopBool, "frag_top")
    drawToggleRow("Подробный килллист", BOOLS.fragSendDetailsBool, "frag_details")
    drawToggleRow("Статусные сообщения захвата", BOOLS.fragShowMessagesBool, "frag_status_messages")
    drawToggleRow("Убийства во время захвата", BOOLS.fragShowKillsBool, "frag_kills")

    if BOOLS.developerModeBool and BOOLS.developerModeBool.v then
        drawSectionTitle("Оформление")
        APP.drawResponsiveInputInt("Цвет embed логов захвата", "##frag_embed_color", INTS.fragEmbedColorBuffer)
    end

    if imgui.Button("Сохранить настройки логов", imgui.ImVec2(250, 34)) then
        if saveConfig() then
            APP.finishWebhookSave("frag", BUFF.fragWebhookBuffer)
            chatSuccess("Настройки fraglist сохранены.")
        end
    end

    imgui.SameLine()

    if imgui.Button("Тест вебхука логов", imgui.ImVec2(220, 34)) then
        saveConfig()
        local webhook = sanitizeWebhookUrl(BUFF.fragWebhookBuffer.v or "")
        if webhook == "" then
            chatError("Вебхук логов захвата пустой.")
        else
            local ok, result = sendDiscordEmbed(
                webhook,
                "Тест вебхука логов захвата",
                "Если это сообщение пришло - вебхук логов работает.",
                intValue(INTS.fragEmbedColorBuffer, CFG.fraglist.embed_color or 16729344),
                "захват"
            )
            if ok then
                chatInfo("Discord: тест логов отправляется.")
            end
        end
    end

    imgui.SameLine()

    if imgui.Button("Отправить последний капт", imgui.ImVec2(220, 34)) then
        saveConfig()
        sendLastCaptureCommand()
    end
end

drawTabPunishments = function()
    drawSectionTitle("Discord наказаний")

    imgui.Text("Webhook для наказаний за захват")
    APP.drawWebhookField(BUFF.punishWebhookBuffer, "##punish_webhook", "punish")

    drawToggleRow("Логировать наказания", BOOLS.punishEnabledBool, "punish_enabled")
    drawToggleRow("Показывать успех сохранения в чате", BOOLS.punishShowInChatBool, "punish_chat")
    if BOOLS.developerModeBool and BOOLS.developerModeBool.v then
        APP.drawResponsiveInputInt("Цвет embed наказаний", "##punish_embed_color", INTS.punishEmbedColorBuffer)
    end

    if imgui.Button("Сохранить настройки наказаний", imgui.ImVec2(270, 34)) then
        if saveConfig() then
            APP.finishWebhookSave("punish", BUFF.punishWebhookBuffer)
            chatSuccess("Настройки punishments сохранены.")
        end
    end

    imgui.SameLine()

    if imgui.Button("Тест вебхука наказаний", imgui.ImVec2(240, 34)) then
        saveConfig()
        local webhook = sanitizeWebhookUrl(BUFF.punishWebhookBuffer.v or "")
        if webhook == "" then
            chatError("Вебхук наказаний пустой.")
        else
            local ok, result = sendDiscordEmbed(
                webhook,
                "Тест вебхука наказаний",
                "Тестовое сообщение наказаний за захват.",
                tonumber(INTS.punishEmbedColorBuffer.v) or 15158332,
                "наказания"
            )
            if ok then
                chatInfo("Discord: тест наказаний отправляется.")
            end
        end
    end
end

drawTabOnline = function()
    drawSectionTitle("Онлайн банд")

    imgui.Text("Webhook для онлайна банд")
    APP.drawWebhookField(BUFF.onlineWebhookBuffer, "##online_webhook", "online")

    drawToggleRow("Автоматически отправлять онлайн при старте захвата", BOOLS.autoOnlineOnCaptureStartBool, "online_auto")
    if BOOLS.developerModeBool and BOOLS.developerModeBool.v then
        APP.drawResponsiveInputInt("Цвет embed онлайна банд", "##online_embed_color", INTS.onlineEmbedColorBuffer)
    end

    if imgui.Button("Сохранить настройки онлайна", imgui.ImVec2(250, 34)) then
        if saveConfig() then
            APP.finishWebhookSave("online", BUFF.onlineWebhookBuffer)
            chatSuccess("Настройки online сохранены.")
        end
    end

    imgui.SameLine()

    if imgui.Button("Тест онлайна банд в Discord", imgui.ImVec2(260, 34)) then
        saveConfig()
        local webhook = sanitizeWebhookUrl(BUFF.onlineWebhookBuffer.v or "")
        if webhook == "" then
            chatError("Вебхук онлайна банд пустой.")
        else
            local ok = sendPreparedGangStatsToDiscord(
                "Онлайн банд",
                {
                    "Тест старта захвата",
                    "Тестовый инициатор: Casual_Alvarez[123]"
                },
                "тест онлайна"
            )
        end
    end

    imgui.SameLine()

    if imgui.Button("Показать онлайн только мне", imgui.ImVec2(220, 34)) then
        showGangStatsToMe(getOnlineGangStatsDirect())
    end
end

drawTabBantachka = function()
    drawSectionTitle("Бантачка")

    imgui.TextWrapped("Каждый ник с новой строки. Если такой аккаунт есть онлайн в табе на старте капта, скрипт покажет уведомление и добавит строку в 'Старт захвата: онлайн банд'.")
    imgui.PushItemWidth(-1)
    imgui.InputTextMultiline("##bantachka_accounts", BUFF.bantachkaAccountsBuffer, imgui.ImVec2(-1, 300))
    imgui.PopItemWidth()

    if imgui.Button("Сохранить бантачку", imgui.ImVec2(220, 34)) then
        BUFF.bantachkaAccountsBuffer.v = table.concat(APP.getBantachkaAccountsList(), "\n")
        if saveConfig() then
            chatSuccess("Настройки bantachka сохранены.")
        end
    end

    imgui.SameLine()

    if imgui.Button("Проверить онлайн бантачек", imgui.ImVec2(260, 34)) then
        saveConfig()
        local matches = APP.getOnlineBantachkaMatches()
        if #matches == 0 then
            chatInfo("Онлайн бантачек в табе не найдено.")
        else
            for i = 1, #matches do
                chat(COLORS.GOLD .. "Онлайн бантачка " .. colorizeName(matches[i].id, matches[i].nick) .. COLORS.WHITE .. ", возможно будет донатить")
            end
        end
    end
end

drawTabPriority = function()
    drawSectionTitle("Проверка приоритетов")

    drawToggleRow("Включить проверку приоритетных администраторов", BOOLS.priorityEnabledBool, "priority_enabled")
    drawToggleRow("Спрашивать подтверждение при более высоком приоритете", BOOLS.priorityAskConfirmBool, "priority_confirm")

    imgui.TextWrapped("Список приоритетов сверху вниз. Каждый ник с новой строки.")
    imgui.PushItemWidth(-1)
    imgui.InputTextMultiline("##priority_admins", BUFF.priorityAdminsBuffer, imgui.ImVec2(-1, 280))
    imgui.PopItemWidth()

    if imgui.Button("Сохранить приоритеты", imgui.ImVec2(230, 34)) then
        BUFF.priorityAdminsBuffer.v = table.concat(APP.getPriorityAdminsList(), "\n")
        if saveConfig() then
            chatSuccess("Настройки priority сохранены.")
        end
    end

    imgui.SameLine()

    if imgui.Button("Проверить приоритет", imgui.ImVec2(220, 34)) then
        BUFF.priorityAdminsBuffer.v = table.concat(APP.getPriorityAdminsList(), "\n")
        saveConfig()
        local allowed, blockingAdmins = APP.getPriorityCheckResult()
        if allowed then
            chatSuccess("Приоритет пропускает отправку.")
        else
            chatError("Приоритет блокирует отправку. Онлайн выше по списку:")
            for i = 1, #blockingAdmins do
                chat(COLORS.GOLD .. " - " .. COLORS.WHITE .. tostring(blockingAdmins[i]))
            end
        end
    end

    imgui.SameLine()

    if imgui.Button("Дебаг приоритета", imgui.ImVec2(220, 34)) then
        BUFF.priorityAdminsBuffer.v = table.concat(APP.getPriorityAdminsList(), "\n")
        saveConfig()
        APP.runPriorityDebug()
    end
end

drawTabFollow = function()
    drawSectionTitle("Слежка по килллисту")

    drawToggleRow("Включить предложение слежки по килллисту", BOOLS.followEnabledBool, "follow_enabled")
    APP.drawResponsiveInputInt("Клавиша слежки (VK)", "##follow_hotkey", INTS.followHotkeyBuffer)
    APP.drawResponsiveInputInt("Сколько секунд держать предложение", "##follow_prompt_seconds", INTS.followPromptSecondsBuffer)

    drawToggleRow("Ctrl", BOOLS.followUseCtrlBool, "follow_ctrl")
    drawToggleRow("Alt", BOOLS.followUseAltBool, "follow_alt")
    drawToggleRow("Shift", BOOLS.followUseShiftBool, "follow_shift")

    if BOOLS.developerModeBool and BOOLS.developerModeBool.v then
        imgui.TextWrapped("Шаблон команды: %d = ID игрока, %s = ник игрока")
        imgui.PushItemWidth(-1)
        imgui.InputText("##follow_command", BUFF.followCommandBuffer)
        imgui.PopItemWidth()
    end

    imgui.Text("Текущая комбинация: " .. formatHotkeyText(
        tonumber(INTS.followHotkeyBuffer.v) or 0x48,
        BOOLS.followUseCtrlBool.v,
        BOOLS.followUseAltBool.v,
        BOOLS.followUseShiftBool.v
    ))

    if imgui.Button("Сохранить настройки слежки", imgui.ImVec2(270, 34)) then
        if saveConfig() then
            chatSuccess("Настройки follow сохранены.")
        end
    end
end

drawTabHelp = function()
    drawSectionTitle("Справка")

    imgui.TextWrapped("Основная команда открытия интерфейса:")
    imgui.TextWrapped("/discordghetto")
    imgui.TextWrapped("")
    imgui.TextWrapped("Полный список команд:")
    imgui.TextWrapped("/discordghetto - открыть стартовую страницу")
    imgui.TextWrapped("/getfrags me | a | discord - вывести или отправить онлайн банд")
    imgui.TextWrapped("/getfrags top - топ по фрагам текущего капта")
    imgui.TextWrapped("/getfrags solo ID - фраги выбранного игрока в текущем капте")
    imgui.TextWrapped("/lastcapt - отправить последний завершённый капт")
    imgui.TextWrapped("/captconfirm - подтвердить отложенную отправку")
    imgui.TextWrapped("/captcancel - отменить отложенную отправку")
    imgui.TextWrapped("/captscan66 - обновить белые исключения из диалога 66")
    imgui.TextWrapped("/captresume - восстановить капт из recovery-файла")
    imgui.TextWrapped("/captdrop - удалить recovery текущего капта")
    imgui.TextWrapped("/captfinish [текст] - завершить восстановленный капт вручную")
    imgui.TextWrapped("/captstatus - показать текущий статус капта и recovery")
    imgui.TextWrapped("/" .. CONST.UPDATER_COMMAND .. " - проверить и скачать обновление скрипта")
    imgui.TextWrapped("")
    imgui.TextWrapped("Файлы настроек лежат в moonloader\\ghetto_discord_assistant\\")
    imgui.TextWrapped("main.ini | fraglist.ini | punishments.ini | online.ini | bantachka.ini | priority.ini | follow.ini")
    imgui.TextWrapped("")
    imgui.TextWrapped("Логи:")
    imgui.TextWrapped("kill_log.txt | capture_log.txt | punishments_log.txt | capture_sessions.txt | kill_stats_db.txt")
end

local function chatStyled(kind, text)
    local prefixColor = COLORS.ACCENT
    local label = "Ghetto Discord Assistant"
    if kind == "error" then
        prefixColor = COLORS.ERROR
        label = "Ошибка"
    elseif kind == "success" then
        prefixColor = COLORS.GREEN
        label = "Готово"
    end
    chat(prefixColor .. "[" .. label .. "]" .. COLORS.WHITE .. " " .. tostring(text or ""))
end

chatInfo = function(text)
    chatStyled("info", text)
end

chatError = function(text)
    chatStyled("error", text)
end

chatSuccess = function(text)
    chatStyled("success", text)
end

local function drawCenteredText(text, color)
    local avail = imgui.GetContentRegionAvail().x
    local textWidth = imgui.CalcTextSize(text).x
    local x = (avail - textWidth) * 0.5
    if x > 0 then
        imgui.SetCursorPosX(imgui.GetCursorPosX() + x)
    end
    imgui.TextColored(color, text)
end

drawTabButton = function(id, label, width)
    local isActive = UI.active_tab == id
    local buttonWidth = width
    if buttonWidth == nil or buttonWidth <= 0 then
        buttonWidth = -1
    end

    if isActive then
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.56, 0.43, 0.22, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.64, 0.49, 0.26, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.47, 0.35, 0.17, 1.00))
    else
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.16, 0.17, 0.19, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.22, 0.23, 0.26, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.29, 0.23, 0.15, 1.00))
    end

    if imgui.Button(label, imgui.ImVec2(buttonWidth, 40)) then
        UI.active_tab = id
    end

    imgui.PopStyleColor(3)
end

drawToggleRow = function(label, boolObj, id)
    local state = boolObj and boolObj.v == true
    local compact = imgui.GetContentRegionAvail().x < 420
    imgui.BeginChild("##toggle_row_lux_" .. tostring(id), imgui.ImVec2(0, compact and 52 or 34), false)
    imgui.AlignTextToFramePadding()
    if compact then
        imgui.PushTextWrapPos(imgui.GetCursorPosX() + imgui.GetContentRegionAvail().x - 84)
        imgui.TextColored(imgui.ImVec4(0.88, 0.88, 0.86, 1.00), label)
        imgui.PopTextWrapPos()
        imgui.SetCursorPosY(imgui.GetCursorPosY() - 2)
        imgui.SetCursorPosX(math.max(0, imgui.GetWindowWidth() - 82))
    else
        imgui.PushTextWrapPos(imgui.GetCursorPosX() + imgui.GetContentRegionAvail().x - 92)
        imgui.TextColored(imgui.ImVec4(0.88, 0.88, 0.86, 1.00), label)
        imgui.PopTextWrapPos()
        imgui.SameLine(math.max(240, imgui.GetWindowWidth() - 88))
    end

    if state then
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.86, 0.25, 0.19, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.93, 0.31, 0.24, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.74, 0.20, 0.15, 1.00))
    else
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.34, 0.35, 0.38, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.41, 0.42, 0.46, 1.00))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.48, 0.49, 0.52, 1.00))
    end

    local buttonLabel = state and "ВКЛ" or "ВЫКЛ"
    if imgui.Button(buttonLabel .. "##" .. tostring(id), imgui.ImVec2(66, 22)) then
        boolObj.v = not boolObj.v
    end

    imgui.PopStyleColor(3)
    imgui.EndChild()
end

local function drawLuxuryCommandRow(commandText, description)
    if imgui.GetContentRegionAvail().x < 520 then
        imgui.TextColored(imgui.ImVec4(0.98, 0.76, 0.76, 1.00), commandText)
        imgui.TextWrapped(description)
    else
        imgui.TextColored(imgui.ImVec4(0.98, 0.76, 0.76, 1.00), commandText)
        imgui.SameLine(150)
        imgui.TextColored(imgui.ImVec4(0.84, 0.84, 0.82, 1.00), description)
    end
end

drawStartButton = function()
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.58, 0.43, 0.22, 1.00))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.68, 0.50, 0.26, 1.00))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.49, 0.36, 0.18, 1.00))
    local pressed = imgui.Button("НАЧАТЬ", imgui.ImVec2(280, 58))
    imgui.PopStyleColor(3)
    return pressed
end

drawAuthorFooter = function(text)
    imgui.Spacing()
    imgui.BeginChild("##author_footer_lux", imgui.ImVec2(0, 34), false)
    drawCenteredText(text, imgui.ImVec4(0.58, 0.58, 0.58, 1.00))
    imgui.EndChild()
end

applyFancyStyle = function()
    local style = imgui.GetStyle()

    safeSetStyle(style, "WindowRounding", 8.0)
    safeSetStyle(style, "ChildWindowRounding", 6.0)
    safeSetStyle(style, "ChildRounding", 6.0)
    safeSetStyle(style, "FrameRounding", 4.0)
    safeSetStyle(style, "ScrollbarRounding", 6.0)
    safeSetStyle(style, "GrabRounding", 4.0)
    safeSetStyle(style, "WindowPadding", imgui.ImVec2(12, 12))
    safeSetStyle(style, "FramePadding", imgui.ImVec2(8, 6))
    safeSetStyle(style, "ItemSpacing", imgui.ImVec2(8, 8))
    safeSetStyle(style, "ItemInnerSpacing", imgui.ImVec2(8, 6))
    safeSetStyle(style, "WindowTitleAlign", imgui.ImVec2(0.50, 0.50))
    safeSetStyle(style, "ButtonTextAlign", imgui.ImVec2(0.50, 0.50))
    safeSetStyle(style, "WindowBorderSize", 1.0)
    safeSetStyle(style, "ChildBorderSize", 1.0)
    safeSetStyle(style, "FrameBorderSize", 1.0)
    safeSetStyle(style, "PopupBorderSize", 1.0)

    local colors = style.Colors
    safeSetColor(colors, imgui.Col.Text,                 imgui.ImVec4(0.92, 0.92, 0.90, 1.00))
    safeSetColor(colors, imgui.Col.TextDisabled,         imgui.ImVec4(0.54, 0.55, 0.58, 1.00))
    safeSetColor(colors, imgui.Col.WindowBg,             imgui.ImVec4(0.12, 0.12, 0.12, 0.98))
    safeSetColor(colors, imgui.Col.ChildBg or imgui.Col.ChildWindowBg, imgui.ImVec4(0.15, 0.15, 0.15, 0.98))
    safeSetColor(colors, imgui.Col.Border,               imgui.ImVec4(0.40, 0.40, 0.40, 0.55))
    safeSetColor(colors, imgui.Col.FrameBg,              imgui.ImVec4(0.18, 0.18, 0.18, 1.00))
    safeSetColor(colors, imgui.Col.FrameBgHovered,       imgui.ImVec4(0.22, 0.22, 0.22, 1.00))
    safeSetColor(colors, imgui.Col.FrameBgActive,        imgui.ImVec4(0.24, 0.24, 0.24, 1.00))
    safeSetColor(colors, imgui.Col.TitleBg,              imgui.ImVec4(0.13, 0.13, 0.13, 1.00))
    safeSetColor(colors, imgui.Col.TitleBgActive,        imgui.ImVec4(0.15, 0.15, 0.15, 1.00))
    safeSetColor(colors, imgui.Col.Button,               imgui.ImVec4(0.17, 0.18, 0.20, 1.00))
    safeSetColor(colors, imgui.Col.ButtonHovered,        imgui.ImVec4(0.23, 0.24, 0.27, 1.00))
    safeSetColor(colors, imgui.Col.ButtonActive,         imgui.ImVec4(0.42, 0.20, 0.20, 1.00))
    safeSetColor(colors, imgui.Col.Header,               imgui.ImVec4(0.17, 0.18, 0.20, 1.00))
    safeSetColor(colors, imgui.Col.HeaderHovered,        imgui.ImVec4(0.23, 0.24, 0.27, 1.00))
    safeSetColor(colors, imgui.Col.HeaderActive,         imgui.ImVec4(0.42, 0.20, 0.20, 1.00))
    safeSetColor(colors, imgui.Col.CheckMark,            imgui.ImVec4(1.00, 0.33, 0.30, 1.00))
    safeSetColor(colors, imgui.Col.SliderGrab,           imgui.ImVec4(1.00, 0.33, 0.30, 1.00))
    safeSetColor(colors, imgui.Col.SliderGrabActive,     imgui.ImVec4(1.00, 0.40, 0.36, 1.00))
    safeSetColor(colors, imgui.Col.ScrollbarBg,          imgui.ImVec4(0.11, 0.12, 0.13, 1.00))
    safeSetColor(colors, imgui.Col.ScrollbarGrab,        imgui.ImVec4(0.26, 0.27, 0.29, 1.00))
    safeSetColor(colors, imgui.Col.ScrollbarGrabHovered, imgui.ImVec4(0.34, 0.35, 0.38, 1.00))
    safeSetColor(colors, imgui.Col.ScrollbarGrabActive,  imgui.ImVec4(0.42, 0.20, 0.20, 1.00))
end

drawWelcomePage = function()
    imgui.BeginChild("##welcome_shell_lux", imgui.ImVec2(0, 0), true)
    drawCenteredText("Ghetto Discord Assistant", imgui.ImVec4(0.96, 0.96, 0.94, 1.00))
    drawCenteredText("Панель захвата, логов Discord и восстановления", imgui.ImVec4(0.66, 0.67, 0.69, 1.00))
    imgui.Spacing()

    imgui.BeginChild("##welcome_hero_lux", imgui.ImVec2(0, 96), true)
    drawCenteredText("Собирает события капта, фиксирует наказания, считает онлайн банд и помогает завершить сессию после сбоя.", imgui.ImVec4(0.86, 0.86, 0.84, 1.00))
    imgui.Spacing()
    drawCenteredText("Один интерфейс для всего цикла работы во время захвата.", imgui.ImVec4(0.96, 0.84, 0.56, 1.00))
    imgui.EndChild()

    imgui.Spacing()

    imgui.BeginChild("##welcome_commands_lux", imgui.ImVec2(0, 205), true)
    imgui.TextColored(imgui.ImVec4(0.96, 0.84, 0.56, 1.00), "Команды и возможности")
    imgui.Separator()
    drawLuxuryCommandRow("/discordghetto", "открыть стартовую страницу")
    drawLuxuryCommandRow("/lastcapt", "отправить последний завершённый капт")
    drawLuxuryCommandRow("/getfrags", "показать или отправить онлайн банд")
    drawLuxuryCommandRow("/getfrags top", "топ по фрагам за текущий капт")
    drawLuxuryCommandRow("/getfrags solo ID", "фраги игрока за текущий капт")
    drawLuxuryCommandRow("/captresume", "восстановить незавершённый капт")
    drawLuxuryCommandRow("/captstatus", "проверить recovery и состояние капта")
    imgui.EndChild()

    imgui.Spacing()

    imgui.BeginChild("##welcome_controls_lux", imgui.ImVec2(0, 158), true)
    imgui.TextColored(imgui.ImVec4(0.96, 0.84, 0.56, 1.00), "Быстрые настройки")
    imgui.Separator()
    drawToggleRow("Локальные уведомления в чате", BOOLS.localFeedBool, "welcome_feed_lux")
    drawToggleRow("Автоотправка онлайна при старте", BOOLS.autoOnlineOnCaptureStartBool, "welcome_online_lux")
    drawToggleRow("Сохранять общую статистику фрагов", BOOLS.saveStatsBool, "welcome_stats_lux")
    imgui.EndChild()

    imgui.Spacing()
    local avail = imgui.GetContentRegionAvail().x
    local x = (avail - 280) * 0.5
    if x > 0 then
        imgui.SetCursorPosX(imgui.GetCursorPosX() + x)
    end
    if drawStartButton() then
        saveConfig()
        UI.active_tab = 1
    end

    imgui.Spacing()
    imgui.BeginChild("##welcome_version_lux", imgui.ImVec2(0, 42), true)
    drawCenteredText("Версия 9.5", imgui.ImVec4(0.84, 0.84, 0.82, 1.00))
    imgui.EndChild()

    drawAuthorFooter("by Casual Alvarez")
    imgui.EndChild()
end

drawBottomStatus = function()
    imgui.BeginChild("##status_footer_lux", imgui.ImVec2(0, 42), true)
    drawCenteredText(
        "Сессия: " .. tostring(DATA.sessionKills)
        .. " | Капт: " .. tostring(STATE.capture.total)
        .. " | Recovery: " .. (fileExists(PATHS.ACTIVE_CAPTURE_STATE_FILE) and "доступен" or "нет"),
        imgui.ImVec4(0.70, 0.70, 0.68, 1.00)
    )
    imgui.EndChild()
end

local function getGangByKey(gangKey)
    if not gangKey then
        return nil
    end
    for _, gang in ipairs(GANGS.list) do
        if gang.key == gangKey then
            return gang
        end
    end
    return nil
end

local function rebuildTestOverlayEntries()
    local entries = {}
    loadCaptureIgnoreNicks(false)

    for id in pairs(DATA.onlinePlayersById or {}) do
        local nick = getPlayerNameById(id)
        local gangKey = getPlayerGangKeyById(id)
        if nick and gangKey and not isCaptureNickIgnored(nick) then
            table.insert(entries, {
                id = id,
                nick = nick,
                gangKey = gangKey,
                kills = tonumber((STATE.capture.stats or {})[nick]) or 0
            })
        end
    end

    table.sort(entries, function(a, b)
        if a.gangKey == b.gangKey then
            return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
        end

        local aOrder = 999
        local bOrder = 999
        for index, gang in ipairs(GANGS.list) do
            if gang.key == a.gangKey then
                aOrder = index
            end
            if gang.key == b.gangKey then
                bOrder = index
            end
        end
        return aOrder < bOrder
    end)

    DATA.overlayTestEntries = entries
end

showKillTop = function()
    if not STATE.capture.active then
        chatError("Топ доступен только во время текущего капта.")
        return
    end

    local arr = sortedStats(STATE.capture.stats or {})
    if #arr == 0 then
        chatInfo("Во время текущего капта ещё нет фрагов.")
        return
    end

    chatInfo("Топ по фрагам за текущий капт:")
    local limit = intValue(INTS.maxTopBuffer, CFG.main.max_top_players or 10)
    if limit < 1 then limit = 10 end
    if limit > 20 then limit = 20 end

    for i = 1, math.min(#arr, limit) do
        chat(COLORS.WHITE .. tostring(i) .. ". " .. arr[i].nick .. " - " .. tostring(arr[i].kills))
    end
end

showKillStatsById = function(arg)
    local id = tonumber(arg)
    if not id then
        chatInfo("Использование: /getfrags solo ID")
        return
    end

    if not STATE.capture.active then
        chatError("Статистика solo доступна только во время текущего капта.")
        return
    end

    if not isCachedPlayerOnline(id) then
        chatError("Игрок с таким ID не найден.")
        return
    end

    local nick = getPlayerNameById(id)
    local kills = STATE.capture.stats[nick] or 0
    chatInfo(string.format("%s | фрагов за текущий капт: %d", colorizeName(id, nick), kills))
end

imgui.OnDrawFrame = function()
    if not imgui.Process then return end

    if UI.window_state.v then
        imgui.SetNextWindowSize(imgui.ImVec2(980, 760), imgui.Cond.FirstUseEver)
        pcall(function()
            imgui.SetNextWindowSizeConstraints(imgui.ImVec2(520, 520), imgui.ImVec2(4096, 4096))
        end)
        imgui.Begin("Ghetto Discord Assistant", UI.window_state)

        if UI.active_tab == 0 then
            drawWelcomePage()
        else
            imgui.BeginChild("##hero_main_lux_latest", imgui.ImVec2(0, 84), true)
            imgui.TextColored(imgui.ImVec4(0.96, 0.96, 0.94, 1.00), "Ghetto Discord Assistant")
            imgui.TextColored(imgui.ImVec4(0.67, 0.68, 0.70, 1.00), "Элегантная панель управления логами захвата, наказаниями и recovery")
            imgui.Spacing()
            imgui.TextColored(
                STATE.capture.active and imgui.ImVec4(0.96, 0.84, 0.56, 1.00) or imgui.ImVec4(0.66, 0.67, 0.70, 1.00),
                STATE.capture.active and "Капт сейчас активен" or "Ожидание нового капта"
            )
            imgui.EndChild()

            imgui.Spacing()
            local compactMainLayout = APP.isCompactMainLayout()

            if compactMainLayout then
                imgui.BeginChild("##sidebar_lux_latest", imgui.ImVec2(0, 248), true)
            else
                imgui.BeginChild("##sidebar_lux_latest", imgui.ImVec2(236, -86), true)
            end
            drawCenteredText("Разделы", imgui.ImVec4(0.94, 0.94, 0.93, 1.00))
            imgui.Separator()
            drawTabButton(1, "Логи захвата", -1)
            drawTabButton(2, "Наказания", -1)
            drawTabButton(3, "Онлайн банд", -1)
            drawTabButton(4, "Бантачка", -1)
            drawTabButton(5, "Приоритет", -1)
            drawTabButton(6, "Слежка", -1)
            drawTabButton(7, "Настройки", -1)
            drawTabButton(8, "Recovery", -1)
            drawTabButton(9, "Справка", -1)
            imgui.Spacing()
            drawCenteredText("Состояние", imgui.ImVec4(0.94, 0.94, 0.93, 1.00))
            imgui.Separator()
            imgui.TextWrapped("Последний капт: " .. (DATA.lastCapture and "сохранён" or "нет данных"))
            imgui.TextWrapped("Отложенная отправка: " .. (DATA.pendingCaptureToSend and "ожидает" or "нет"))
            imgui.TextWrapped("Overlay: " .. tostring(#(STATE.capture.overlayEntries or {})) .. " игроков")
            imgui.EndChild()

            if not compactMainLayout then
                imgui.SameLine()
            else
                imgui.Spacing()
            end

            imgui.BeginChild("##content_wrap_lux_latest", imgui.ImVec2(0, -86), true)
            if UI.active_tab == 1 then
                drawTabCapture()
            elseif UI.active_tab == 2 then
                drawTabPunishments()
            elseif UI.active_tab == 3 then
                drawTabOnline()
            elseif UI.active_tab == 4 then
                drawTabBantachka()
            elseif UI.active_tab == 5 then
                drawTabPriority()
            elseif UI.active_tab == 6 then
                drawTabFollow()
            elseif UI.active_tab == 7 then
                drawTabMain()
            elseif UI.active_tab == 8 then
                drawTabRecovery()
            else
                drawTabHelp()
            end
            imgui.EndChild()

            imgui.Spacing()
            drawBottomStatus()
            drawAuthorFooter("by Casual Alvarez")
        end

        if not UI.window_state.v and not STATE.capture.active then
            imgui.Process = false
        end

        imgui.End()
    end

end

local function registerCommands()
    sampRegisterChatCommand("getfrags", handleGetFragsCommand)
    sampRegisterChatCommand("captscan66", startDialog66WhiteScan)
    sampRegisterChatCommand(CONST.UPDATER_COMMAND, function()
        APP.checkForUpdates("download_if_new")
    end)
    sampRegisterChatCommand("prioritydebug", function()
        APP.runPriorityDebug()
    end)
    sampRegisterChatCommand("lastcapt", sendLastCaptureCommand)
    sampRegisterChatCommand("captconfirm", confirmPendingCaptureSend)
    sampRegisterChatCommand("captcancel", cancelPendingCaptureSend)
    sampRegisterChatCommand("captassist", startCaptureAssistMode)
    sampRegisterChatCommand("captresume", resumeCaptureFromRecovery)
    sampRegisterChatCommand("captdrop", dropCaptureRecovery)
    sampRegisterChatCommand("captfinish", finishRecoveredCapture)
    sampRegisterChatCommand("captstatus", showCaptureStatus)
    sampRegisterChatCommand("discordghetto", function()
        UI.active_tab = 0
        UI.window_state.v = true
        imgui.Process = true
        sampAddChatMessage(utf8_to_cp1251("{6FA8FF}[Ghetto Discord Assistant]{FFFFFF} Открыта стартовая страница."), -1)
    end)
end

local function printStartBanner()
    chat(COLORS.LINE .. CONST.LINE_TEXT)
    chat(COLORS.GOLD .. " Ghetto Discord Assistant запущен")
    chat(COLORS.WHITE .. " Автор: " .. COLORS.RED .. "Casual Alvarez")
    chat(COLORS.WHITE .. " Команды: "
        .. COLORS.ACCENT .. "/discordghetto "
        .. COLORS.WHITE .. "| "
        .. COLORS.ACCENT .. "/getfrags top "
        .. COLORS.WHITE .. "| "
        .. COLORS.ACCENT .. "/getfrags solo ID "
        .. COLORS.WHITE .. "| "
        .. COLORS.ACCENT .. "/lastcapt")
    chat(COLORS.WHITE .. " Recovery: " .. COLORS.ACCENT .. "/captstatus /captdrop /captfinish")
    chat(COLORS.WHITE .. " Обновление: " .. COLORS.ACCENT .. "/" .. CONST.UPDATER_COMMAND)
    chat(COLORS.WHITE .. " Папка: " .. COLORS.ACCENT .. "moonloader\\ghetto_discord_assistant\\")
    chat(COLORS.LINE .. CONST.LINE_TEXT)
end

function main()
    repeat wait(100) until isSampAvailable()

    DATA.onlineWarmupUntil = os.clock() + (tonumber(CONST.ONLINE_INITIAL_WARMUP_SECONDS) or 6.0)
    DATA.onlineStatsStabilized = false
    DATA.onlineColorEventCount = 0
    DATA.onlineStatsCollectActive = false
    DATA.onlineStatsCollectCallbacks = {}
    DATA.onlineSendGuardUntil = 0
    loadCaptureIgnoreNicks(true)
    ensureDir(PATHS.BASE_DIR)
    loadAllSettings()
    initBuffers()
    applyFancyStyle()
    loadStats()
    saveConfig()
    registerCommands()
    printStartBanner()
    loadRecoveryArtifactsOnStart()
    APP.checkForUpdates("check_only")
    APP.syncCustomNametagsState(true)
    APP.syncSkeletalState(true)

    while true do
        wait(0)

        if DATA.scriptTerminating then
            break
        end

        if DATA.pendingSelfReload then
            DATA.pendingSelfReload = false
            DATA.scriptTerminating = true
            THREADS.shuttingDown = true
            thisScript():reload()
            break
        end

        processPendingDeathEvents()
        APP.syncCustomNametagsState(true)
        APP.syncSkeletalState(true)
        APP.renderCustomNametagsFrame()

        if DATA.deferredCaptureAutoSend and not STATE.capture.active and isSafeGameRenderState() then
            local deferred = DATA.deferredCaptureAutoSend
            DATA.deferredCaptureAutoSend = nil
            requestCaptureSendWithPriorityCheck(
                deferred.capture,
                deferred.source ~= "" and deferred.source or "отложенная автоотправка капта"
            )
        end

        imgui.Process = UI.window_state.v

        if (STATE.capture.active or DATA.overlayTestActive) and os.clock() >= (tonumber(DATA.onlineSnapshotRefreshAt) or 0) then
            refreshOnlinePlayersSnapshot()
        end

        if STATE.capture.active and os.clock() >= (tonumber(STATE.capture.overlayRefreshAt) or 0) then
            rebuildCaptureOverlayEntries()
            STATE.capture.overlayRefreshAt = os.clock() + 1.0
        end

        if DATA.overlayTestActive and os.clock() >= (tonumber(DATA.overlayTestRefreshAt) or 0) then
            rebuildTestOverlayEntries()
            DATA.overlayTestRefreshAt = os.clock() + 1.0
        end

        if imgui.Process and not UI.window_state.v then
            imgui.Process = false
        end

        processFollowPrompt()
    end
end

function sampev.onCreate3DText(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
    return APP.rebuildLongRangeLabel(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    local scan = DATA.dialog66WhiteScan
    if not scan or not scan.active or tonumber(dialogId) ~= 66 then
        return
    end

    scan.pages = (tonumber(scan.pages) or 0) + 1
    local added = collectDialog66WhiteNicks(text)
    chatInfo(string.format("Диалог 66: страница %d, новых белых ников %d", scan.pages, added))

    if dialog66HasNextPage(button2) then
        requestDialog66NextPage()
    else
        finishDialog66WhiteScan()
    end
end

function sampev.onServerMessage(color, text)
    local raw = cp1251_to_utf8(text)

    if string.find(raw, "начали захват территории банды", 1, true) then
        if not STATE.capture.active then
            startCapture(raw)
        end
        return true
    end

    if STATE.capture.active and string.find(raw, "инициировал захват", 1, true) then
        addCaptureMessage(raw)
        return true
    end

    if STATE.capture.active
        and boolValue(BOOLS.punishEnabledBool, CFG.punishments.enabled ~= false)
        and STATE.capture.punishLogging
        and containsPunishmentByLegacyPrinciple(raw) then
        addPunishmentLine(raw)
        return true
    end

    if string.find(raw, "Попытка ", 1, true) and string.find(raw, " захватить территорию ", 1, true) and string.find(raw, " провалилась", 1, true) then
        stopCaptureAndSend(raw)
        restoreRecoveryInfo()
        return true
    end

    if string.find(raw, " захватили территорию у банды ", 1, true) and string.find(raw, " в районе", 1, true) then
        stopCaptureAndSend(raw)
        restoreRecoveryInfo()
        return true
    end

    return true
end

function sampev.onPlayerJoin(playerId, color, isNpc, nickname)
    markPlayerOnlineById(playerId, true)
    cachePlayerColorById(playerId, color, "join")
    cachePlayerNameById(playerId, nickname)
    requestCaptureOverlayRefresh()
end

function sampev.onSetPlayerName(playerId, name, success)
    if success ~= false then
        markPlayerOnlineById(playerId, true)
        cachePlayerNameById(playerId, name)
        requestCaptureOverlayRefresh()
    end
end

function sampev.onSetPlayerColor(playerId, color)
    markPlayerOnlineById(playerId, true)
    cachePlayerColorById(playerId, color, "live")
    requestCaptureOverlayRefresh()
end

function sampev.onPlayerStreamIn(playerId, team, model, position, rotation, color, fightingStyle)
    markPlayerOnlineById(playerId, true)
    cachePlayerColorById(playerId, color, "live")
    requestCaptureOverlayRefresh()
end

function sampev.onUpdateScoresAndPings(playerList)
    local refreshedOnline = {}

    for playerId in pairs(playerList or {}) do
        playerId = tonumber(playerId)
        if playerId and playerId >= 0 and playerId ~= 65535 then
            refreshedOnline[playerId] = true
            local liveNickname = tryGetLivePlayerNickname(playerId)
            if liveNickname then
                cachePlayerNameById(playerId, liveNickname)
            end
        end
    end

    DATA.onlinePlayersById = refreshedOnline
    requestCaptureOverlayRefresh()
end

function sampev.onPlayerQuit(playerId, reason)
    local id = tonumber(playerId) or -1
    markPlayerOnlineById(id, false)
    DATA.playerNamesById[id] = nil
    DATA.playerColorsById[id] = nil
    DATA.playerColorSourceById[id] = nil
    requestCaptureOverlayRefresh()
end

processPendingDeathEvents = function()
    local queue = DATA.pendingDeathEvents or {}
    if #queue == 0 then
        return
    end

    local limit = math.min(#queue, tonumber(CONST.MAX_DEATH_EVENTS_PER_TICK) or 20)
    local remaining = {}
    for i = limit + 1, #queue do
        remaining[#remaining + 1] = queue[i]
    end
    DATA.pendingDeathEvents = remaining

    for i = 1, limit do
        local event = queue[i]
        local killerId = tonumber(event.killerId) or -1
        local killedId = tonumber(event.killedId) or -1
        local reason = tonumber(event.reason) or 0

        if killerId ~= -1 and killerId ~= 65535 then
            local killerName = getPlayerNameById(killerId)
            local victimName = getPlayerNameById(killedId)
            local weaponName = getWeaponName(reason)

            addKillToGlobalStats(killerName)
            local streakCount = registerKillInStreak(killerName)
            recordCaptureKill(killerId, killedId)
            markCapturePlayerDead(killedId)

            local totalShown = DATA.stats[killerName] or 0
            if STATE.capture.active then
                totalShown = tonumber(STATE.capture.stats[killerName]) or 0
            end

            local line = string.format(
                "[%s] %s[%d] killed %s[%d] | weapon:%s | total:%d | streak:%d",
                getTimeString(),
                killerName,
                killerId,
                victimName,
                killedId,
                weaponName,
                totalShown,
                streakCount
            )
            appendLine(PATHS.LOG_FILE, line)

            if boolValue(BOOLS.localFeedBool, CFG.main.local_chat_feed ~= false)
                and STATE.capture.active
                and boolValue(BOOLS.fragShowKillsBool, CFG.fraglist.show_kills_in_chat ~= false) then
                chat(string.format(
                    "%s - %s | оружие: %s",
                    colorizeName(killerId, killerName),
                    colorizeName(killedId, victimName),
                    weaponName
                ))
            end

            showStreakMessageIfNeeded(killerId, killerName, streakCount)
            activateFollowPrompt(killerId, killerName)
        end
    end
end

function sampev.onPlayerDeathNotification(killerId, killedId, reason)
    if killerId == -1 or killerId == 65535 then
        return
    end
    table.insert(DATA.pendingDeathEvents, {
        killerId = tonumber(killerId) or -1,
        killedId = tonumber(killedId) or -1,
        reason = tonumber(reason) or 0
    })
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        DATA.scriptTerminating = true
        THREADS.shuttingDown = true

        for threadId, th in pairs(THREADS.active) do
            pcall(function()
                th:cancel()
            end)
            THREADS.active[threadId] = nil
        end

        APP.shutdownSkeletal()
        APP.shutdownCustomNametags()
        saveStats()
        saveConfig()
        persistActiveCaptureState()
        saveLastCaptureSnapshot()
        savePendingCaptureSnapshot()
    end
end

local function toggleTestOverlay()
    DATA.overlayTestActive = not DATA.overlayTestActive

    if DATA.overlayTestActive then
        refreshOnlinePlayersSnapshot(true, true)
        rebuildTestOverlayEntries()
        DATA.overlayTestRefreshAt = os.clock() + 1.0
        chatInfo(string.format("Тестовый оверлей включен. Найдено игроков: %d", #(DATA.overlayTestEntries or {})))
    else
        DATA.overlayTestEntries = {}
        DATA.overlayTestRefreshAt = 0
        chatInfo("Тестовый оверлей скрыт.")
    end
end

drawTabMain = function()
    drawSectionTitle("Настройки")

    local developerModeEnabled = BOOLS.developerModeBool and BOOLS.developerModeBool.v
    local developerModeButtonText = developerModeEnabled and "Выключить режим разработчика" or "Включить режим разработчика"
    if imgui.Button(developerModeButtonText, imgui.ImVec2(290, 34)) then
        BOOLS.developerModeBool.v = not developerModeEnabled
        saveConfig()
    end

    drawToggleRow("Сохранять общую статистику фрагов", BOOLS.saveStatsBool, "main_stats")
    drawToggleRow("Показывать локальные сообщения скрипта", BOOLS.localFeedBool, "main_local_feed")
    drawToggleRow("Показывать уведомления о сериях", BOOLS.streakAlertsBool, "main_streaks")
    drawSectionTitle("Визуал")
    drawToggleRow("Дальние 3D-лейблы", BOOLS.longRangeLabelsBool, "main_long_range_labels")
    drawToggleRow("Кастомные никнеймы и полоски HP", BOOLS.customNametagsBool, "main_custom_nametags")
    drawToggleRow("Skeletal WallHack", BOOLS.skeletalBool, "main_skeletal")
    if developerModeEnabled then
        APP.drawResponsiveInputInt("Максимум игроков в топе", "##max_top_players", INTS.maxTopBuffer)
        APP.drawResponsiveInputInt("Смещение времени для Discord (минуты)", "##discord_offset_minutes", INTS.discordTimeOffsetBuffer, "0 = время по компьютеру, 120 = добавить 2 часа, -60 = отнять 1 час.")
    end

    drawSectionTitle("Оверлей капта")
    drawToggleRow("Показывать список участников капта", BOOLS.captureOverlayEnabledBool, "main_overlay_enabled")
    if developerModeEnabled then
        APP.drawResponsiveInputInt("Позиция X", "##capture_overlay_x", INTS.captureOverlayXBuffer)
        APP.drawResponsiveInputInt("Позиция Y", "##capture_overlay_y", INTS.captureOverlayYBuffer)
        APP.drawResponsiveInputInt("Ширина области", "##capture_overlay_width", INTS.captureOverlayWidthBuffer)
        APP.drawResponsiveInputInt("Высота области", "##capture_overlay_height", INTS.captureOverlayHeightBuffer)
        APP.drawResponsiveInputInt("Зазор между столбцами", "##capture_overlay_gap", INTS.captureOverlayGapBuffer)
    end
    imgui.TextWrapped("Формат строки: Nick[ID] | фраги. Во время теста выводится текущий онлайн всех банд.")

    local testButtonText = DATA.overlayTestActive and "Скрыть тестовый оверлей" or "Вывести тестовый оверлей"
    if imgui.Button(testButtonText, imgui.ImVec2(250, 34)) then
        toggleTestOverlay()
    end

    imgui.Spacing()
    drawSectionTitle("Поздний вход")
    imgui.TextWrapped("Если вы зашли уже после старта капта, включите вспомогательный режим. Discord-логи такого капта отправляться не будут.")
    if imgui.Button("Запустить режим капта вручную", imgui.ImVec2(280, 34)) then
        startCaptureAssistMode()
    end
    imgui.TextWrapped("Команда: /captassist")

    imgui.Spacing()
    drawSectionTitle("Мини-топ капта")
    drawToggleRow("Показывать мини-топ на 6 игроков", BOOLS.captureTopOverlayEnabledBool, "main_capture_top_overlay")
    if developerModeEnabled then
        APP.drawResponsiveInputInt("Мини-топ X", "##capture_top_overlay_x", INTS.captureTopOverlayXBuffer)
        APP.drawResponsiveInputInt("Мини-топ Y", "##capture_top_overlay_y", INTS.captureTopOverlayYBuffer)
    end

    if imgui.Button("Сохранить настройки оверлеев", imgui.ImVec2(260, 34)) then
        if saveConfig() then
            APP.syncCustomNametagsState(true)
            APP.syncSkeletalState(true)
            chatSuccess("Настройки оверлеев сохранены.")
        end
    end

    if imgui.Button("Сохранить общие настройки", imgui.ImVec2(250, 34)) then
        if saveConfig() then
            APP.syncCustomNametagsState(true)
            APP.syncSkeletalState(true)
            chatSuccess("Общие настройки сохранены.")
        end
    end
end


local function getOverlayEntriesForRender()
    if not BOOLS.captureOverlayEnabledBool or not BOOLS.captureOverlayEnabledBool.v then
        return nil, nil
    end

    if STATE.capture.active then
        return STATE.capture.overlayEntries or {}, "Участники капта в онлайне:"
    end

    if DATA.overlayTestActive then
        return DATA.overlayTestEntries or {}, "Тестовый онлайн банд:"
    end

    return nil, nil
end

local function ensureOverlayFonts()
    if not DATA.overlayTitleFont then
        DATA.overlayTitleFont = renderCreateFont("Tahoma", 10, 5)
    end
    if not DATA.overlayLineFont then
        DATA.overlayLineFont = renderCreateFont("Tahoma", 9, 5)
    end

    return DATA.overlayTitleFont ~= nil and DATA.overlayLineFont ~= nil
end

local function drawOverlayText(font, text, x, y, color)
    if not font then
        return
    end
    local encoded = utf8_to_cp1251(text)
    renderFontDrawText(font, encoded, x + 1, y + 1, 0xAA000000)
    renderFontDrawText(font, encoded, x, y, color)
end

local function drawOverlayRenderLine(font, index, item, x, y)
    local gang = getGangByKey(item.gangKey)
    local nickColor = (gang and gang.color) or 0xFFFFFFFF
    local softWhite = 0xFFF0F0F0
    local fragColor = 0xFFFFD36B

    local left = string.format("%d. ", tonumber(index) or 0)
    local nickText = string.format("%s[%d]", tostring(item.nick or ""), tonumber(item.id) or 0)
    local fragsText = string.format(" | %d", tonumber(item.kills) or 0)
    local leftEncoded = utf8_to_cp1251(left)
    local nickEncoded = utf8_to_cp1251(nickText)

    drawOverlayText(font, left, x, y, softWhite)
    local nickX = x + renderGetFontDrawTextLength(font, leftEncoded)
    drawOverlayText(font, nickText, nickX, y, nickColor)
    local fragX = nickX + renderGetFontDrawTextLength(font, nickEncoded)
    drawOverlayText(font, fragsText, fragX, y, fragColor)
end

drawOverlayHud = function()
    local entries, title = getOverlayEntriesForRender()
    if not entries or #entries == 0 then
        return
    end

    if not ensureOverlayFonts() then
        return
    end

    local posX = tonumber(INTS.captureOverlayXBuffer and INTS.captureOverlayXBuffer.v) or tonumber(CFG.main.capture_overlay_x) or 22
    local posY = tonumber(INTS.captureOverlayYBuffer and INTS.captureOverlayYBuffer.v) or tonumber(CFG.main.capture_overlay_y) or 120
    local width = tonumber(INTS.captureOverlayWidthBuffer and INTS.captureOverlayWidthBuffer.v) or tonumber(CFG.main.capture_overlay_width) or 420
    local gap = tonumber(INTS.captureOverlayGapBuffer and INTS.captureOverlayGapBuffer.v) or tonumber(CFG.main.capture_overlay_gap) or 48
    if width < 260 then width = 260 end
    if gap < 0 then gap = 0 end

    local leftX = posX
    local rightX = posX + math.floor(width / 2) + gap
    local titleY = posY
    local startY = posY + 18
    local lineHeight = 16
    local mid = math.ceil(#entries / 2)

    drawOverlayText(DATA.overlayTitleFont, title, leftX, titleY, 0xFFF7F7F7)

    for i = 1, #entries do
        local item = entries[i]
        local columnX = (i <= mid) and leftX or rightX
        local rowIndex = (i <= mid) and (i - 1) or (i - mid - 1)
        local rowY = startY + rowIndex * lineHeight
        drawOverlayRenderLine(DATA.overlayLineFont, i, item, columnX, rowY)
    end
end

function onD3DPresent()
    if not isSafeGameRenderState() then
        return
    end

    pcall(APP.renderSkeletalFrame)

    local captureOverlayEnabled = BOOLS.captureOverlayEnabledBool and BOOLS.captureOverlayEnabledBool.v
    local captureTopEnabled = BOOLS.captureTopOverlayEnabledBool and BOOLS.captureTopOverlayEnabledBool.v
    local shouldDrawHud = DATA.overlayTestActive or (STATE.capture.active and (captureOverlayEnabled or captureTopEnabled))
    if not shouldDrawHud then
        return
    end

    pcall(drawOverlayHud)
    pcall(drawCaptureTopOverlayHud)
end

handleGetFragsCommand = function(arg)
    local clean = trim(arg or "")
    local lower = clean:lower()
    local data = getOnlineGangStatsDirect()

    if lower == "" or lower == "me" then
        showGangStatsToMe(data)
        return
    end

    if lower == "a" then
        sendGangStatsToAdminChat(data)
        return
    end

    if lower == "discord" then
        sendPreparedGangStatsToDiscord("Онлайн банд", nil, "онлайн банд")
        return
    end

    if lower == "top" then
        showKillTop()
        return
    end

    local soloId = lower:match("^solo%s+(%d+)$")
    if soloId then
        showKillStatsById(soloId)
        return
    end

    chatInfo("Использование: /getfrags me | a | discord | top | solo ID")
end

function buildCaptureTopOverlayEntries()
    if not STATE.capture.active then
        return {}
    end
    return DATA.captureTopOverlayEntries or {}
end

function drawCaptureTopOverlayHud()
    if not BOOLS.captureTopOverlayEnabledBool or not BOOLS.captureTopOverlayEnabledBool.v then
        return
    end

    local rows = buildCaptureTopOverlayEntries()
    if #rows == 0 then
        return
    end

    if not ensureOverlayFonts() then
        return
    end

    local posX = tonumber(INTS.captureTopOverlayXBuffer and INTS.captureTopOverlayXBuffer.v) or tonumber(CFG.main.capture_top_overlay_x) or 520
    local posY = tonumber(INTS.captureTopOverlayYBuffer and INTS.captureTopOverlayYBuffer.v) or tonumber(CFG.main.capture_top_overlay_y) or 120
    local lineHeight = 16

    drawOverlayText(DATA.overlayTitleFont, "Топ фрагов капта:", posX, posY, 0xFFF7F7F7)

    for i = 1, #rows do
        local item = rows[i]
        local y = posY + 18 + (i - 1) * lineHeight
        local left = string.format("%d. ", tonumber(item.index) or i)
        local nickText = item.id >= 0
            and string.format("%s[%d]", tostring(item.nick or ""), tonumber(item.id) or 0)
            or tostring(item.nick or "")
        local killsText = string.format(" | %d", tonumber(item.kills) or 0)
        local nickColor = tonumber(item.color) or 0xFFFFFFFF

        drawOverlayText(DATA.overlayLineFont, left, posX, y, 0xFFF0F0F0)
        local leftW = renderGetFontDrawTextLength(DATA.overlayLineFont, utf8_to_cp1251(left))
        drawOverlayText(DATA.overlayLineFont, nickText, posX + leftW, y, nickColor)
        local nickW = renderGetFontDrawTextLength(DATA.overlayLineFont, utf8_to_cp1251(nickText))
        drawOverlayText(DATA.overlayLineFont, killsText, posX + leftW + nickW, y, 0xFFFFD36B)
    end
end

local originalStopCaptureAndSend = stopCaptureAndSend
stopCaptureAndSend = function(resultText)
    if STATE.capture.sendLogsOnFinish ~= false then
        return originalStopCaptureAndSend(resultText)
    end

    local c = STATE.capture
    if not c.active then
        return
    end

    c.active = false
    c.endLine = normalizeSpaces(removeBrackets(resultText or "Захват завершен"))
    markGangParticipantsFromText(c.endLine)
    appendLine(PATHS.CAPTURE_LOG, withTimestamp(c.endLine))

    if boolValue(BOOLS.fragShowMessagesBool, CFG.fraglist.show_status_messages_in_chat ~= false)
        and boolValue(BOOLS.localFeedBool, CFG.main.local_chat_feed ~= false) then
        chat(COLORS.INFO .. c.endLine)
    end

    stopPunishLogging()

    local captureData = buildCurrentCaptureData(c.endLine)
    DATA.lastCapture = captureData
    saveLastCaptureSnapshot()
    appendCaptureSessionBlock(captureData)
    clearActiveCaptureState()
    chatInfo("Вспомогательный режим капта завершен. Discord-лог пропущен.")
    resetCapture()
end
