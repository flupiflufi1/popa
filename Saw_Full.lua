script_author('flupiflufi')
script_name("Leso\xD0\xF3\xE1 \xE1\xEE\xF2")
script_version('0.0.6')
script_description("Leso\xD0\xF3\xE1 \xFD\xF2\xE0 \xE1\xEE\xF2 \xED\xE0 \xEB\xE5\xF1\xEE\xEF\xE8\xEB\xEA\xF3, \xEE\xED \xF0\xF3\xE1\xE8\xF2 \xEB\xE5\xF1!")

local mem = require "memory"
local mad = require("MoonAdditions")
local imgui = require 'mimgui'
local ti = require 'tabler_icons'
local samp = require 'lib.samp.events'
local font = renderCreateFont('Arial', 9, 5)
local json = require 'dkjson'
local effil    = require 'effil'
local g_cpos = imgui.GetCursorPos
local ffi = require 'ffi'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local ok_imgui, imgui_pre = pcall(require, 'mimgui')
local ok_particles, Particles = pcall(require, 'Particles')

local required = {
    "memory", "MoonAdditions", "mimgui", "tabler_icons",
    "encoding", "lib.samp.events", "dkjson", "effil"
}
local navmesh = {"navmesh.navmesh", "navmesh.movement", "navmesh.render"}
local sawmill_hidden = false
local missing = {}
for _, lib in ipairs(required) do
    if not pcall(require, lib) then missing[#missing+1] = lib end
end
local nav_missing = false
for _, lib in ipairs(navmesh) do
    if not pcall(require, lib) then nav_missing = true; break end
end
if nav_missing then missing[#missing+1] = "navmesh (navmesh.navmesh / movement / render)" end
libs_missing = #missing > 0
local ml_path    = getWorkingDirectory()
local logo_tex      = nil
local logo_loaded   = false
local logo_loading  = false
local LOGO_URL       = "https://raw.githubusercontent.com/flupiflufi1/popa/main/lesorub_logo.png"
local LOGO_PATH      = ml_path .. "\\config\\lesorub_logo.png"

function ensure_config_dir()
    local cfg_dir = ml_path .. "\\config"
    if not doesDirectoryExist(cfg_dir) then
        createDirectory(cfg_dir)
    end
end
local im = imgui_pre
function try_load_logo()
    if logo_loaded or logo_loading then return end
    ensure_config_dir()
    if doesFileExist(LOGO_PATH) then
        local ok_t, tex = pcall(function()
            return im.CreateTextureFromFile and im.CreateTextureFromFile(LOGO_PATH)
                or (renderLoadTextureFromFile and renderLoadTextureFromFile(LOGO_PATH))
                or nil
        end)
        if ok_t and tex then
            logo_tex    = tex
            logo_loaded = true
        end
    else
        logo_loading = true
        lua_thread.create(function()
            local dl2 = require('moonloader').download_status
            local done2, err2 = false, false
            downloadUrlToFile(LOGO_URL, LOGO_PATH, function(_, st2)
                if st2 == dl2.STATUS_ENDDOWNLOADDATA then done2 = true
                elseif st2 == dl2.STATUSEX_ENDDOWNLOAD and not done2 then err2 = true end
            end)
            local t2 = os.clock() + 15
            while not done2 and not err2 and os.clock() < t2 do wait(100) end
            logo_loading = false
            if done2 and doesFileExist(LOGO_PATH) then
                local ok3, tex3 = pcall(function()
                    return im.CreateTextureFromFile and im.CreateTextureFromFile(LOGO_PATH)
                        or (renderLoadTextureFromFile and renderLoadTextureFromFile(LOGO_PATH))
                        or nil
                end)
                if ok3 and tex3 then
                    logo_tex    = tex3
                    logo_loaded = true
                end
            end
        end)
    end
end
if libs_missing then
    if not ok_imgui then
        print("[LesoRub] ======== \xCE\xEF\xF3\xF9\xE5\xED\xED\xFB\xE5 \xE1\xE8\xE1\xEB\xE5\xEE\xF2\xE5\xEA\xE8 ========")
        for _, v in ipairs(missing) do print("[LesoRub] \xCF\xF0\xEE\xEF\xF3\xF9\xE5\xED\xEE: " .. v) end
        print("[LesoRub] \xD1\xEA\xE0\xF7\xE0\xF2\xFC: https://github.com/flupiflufi1/popa/releases")
    else
        local im = imgui_pre
        local LIBS_URL    = "https://raw.githubusercontent.com/flupiflufi1/popa/main/lesobot_libs.zip"
        local NAVMESH_URL = "https://raw.githubusercontent.com/flupiflufi1/popa/main/navmesh.zip"

        libo_show_win   = im.new.bool(true)
        libo_progress   = im.new.float(0)
        libo_state      = 'idle'
        libo_status     = u8("\xC3\xEE\xF2\xEE\xE2\xEE")
        local ml_path    = getWorkingDirectory()
        local zip1       = ml_path .. '\\lesobot_libs_tmp.zip'
        local zip2       = ml_path .. '\\navmesh_tmp.zip'

        local ZZLIB_URL    = "https://raw.githubusercontent.com/flupiflufi1/popa/main/zzlib.lua"
        local INFLATE1_URL = "https://raw.githubusercontent.com/flupiflufi1/popa/main/inflate-bwo.lua"
        local INFLATE2_URL = "https://raw.githubusercontent.com/flupiflufi1/popa/main/inflate-bit32.lua"

        local lib_path = ml_path .. "\\lib\\"

        local function load_zzlib()
            return pcall(function()
                package.path = package.path .. ";" .. ml_path .. "\\lib\\?.lua"
                zzlib = require("zzlib")
            end)
        end

        local function download_file(url, path, on_done, on_fail)
            local dl = require('moonloader').download_status
            local ok = false
            downloadUrlToFile(url, path, function(_, st)
                if st == dl.STATUS_ENDDOWNLOADDATA then
                    ok = true
                    on_done()
                elseif st == dl.STATUSEX_ENDDOWNLOAD and not ok then
                    on_fail(url)
                end
            end)
        end
        libo_start_dl = function()
            libo_state  = 'downloading'
            libo_status = u8("\xC7\xE0\xE3\xF0\xF3\xE7\xEA\xE0 zzlib...")
            libo_progress[0] = 0.0
            lua_thread.create(function()
                local dl = require('moonloader').download_status
                local step = 0
                local total_steps = nav_missing and 6 or 5
                local failed = false

                local function await_download(url, dest)
                    local done = false
                    local err  = false
                    downloadUrlToFile(url, dest, function(_, st, got, tot)
                        if st == dl.STATUS_DOWNLOADINGDATA then
                        elseif st == dl.STATUS_ENDDOWNLOADDATA then
                            done = true
                        elseif st == dl.STATUSEX_ENDDOWNLOAD then
                            if not done then err = true end
                        end
                    end)
                    while not done and not err do wait(100) end
                    return not err
                end

                local function next_step(status)
                    step = step + 1
                    libo_progress[0] = step / total_steps
                    libo_status = u8(status)
                end
                libo_status = u8("\xC7\xE0\xE3\xF0\xF3\xE7\xEA\xE0 zzlib.lua...")
                if not await_download(ZZLIB_URL, lib_path .. "zzlib.lua") then
                    libo_state = 'error'; libo_status = u8("\xCE\xF8\xE8\xE1\xEA\xE0: zzlib.lua"); return
                end
                next_step(u8("\xC7\xE0\xE3\xF0\xF3\xE7\xEA\xE0 inflate-bwo.lua..."))
                if not await_download(INFLATE1_URL, lib_path .. "inflate-bwo.lua") then
                    libo_state = 'error'; libo_status = u8("\xCE\xF8\xE8\xE1\xEA\xE0: inflate-bwo.lua"); return
                end
                next_step(u8("\xC7\xE0\xE3\xF0\xF3\xE7\xEA\xE0 inflate-bit32.lua..."))
                if not await_download(INFLATE2_URL, lib_path .. "inflate-bit32.lua") then
                    libo_state = 'error'; libo_status = u8("\xCE\xF8\xE8\xE1\xEA\xE0: inflate-bit32.lua"); return
                end
                next_step(u8("\xC7\xE0\xE3\xF0\xF3\xE7\xEA\xE0 \xE1\xE8\xE1\xEB\xE8\xEE\xF2\xE5\xEA..."))
                local ok, err = load_zzlib()
                if not ok then
                    libo_state = 'error'; libo_status = u8("\xCE\xF8\xE8\xE1\xEA\xE0 \xE7\xE0\xE3\xF0\xF3\xE7\xEA\xE8 zzlib: ") .. tostring(err); return
                end
                if not await_download(LIBS_URL, zip1) then
                    libo_state = 'error'; libo_status = u8("\xCE\xF8\xE8\xE1\xEA\xE0: lesobot_libs.zip"); return
                end
                next_step(u8("\xD0\xE0\xF1\xEF\xE0\xEA\xEE\xE2\xEA\xE0 \xE1\xE8\xE1\xEB\xE8\xEE\xF2\xE5\xEA..."))
                local ok2, err2 = pcall(zzlib.unzip_full_archive_files, zip1, ml_path)
                if not ok2 then
                    libo_state = 'error'; libo_status = u8("\xCE\xF8\xE8\xE1\xEA\xE0 \xF0\xE0\xF1\xEF\xE0\xEA\xEE\xE2\xEA\xE8 libs: ") .. tostring(err2); return
                end
                pcall(os.remove, zip1)

                if not nav_missing then
                    libo_state  = 'done'
                    libo_status = u8("\xC3\xEE\xF2\xEE\xE2\xEE!")
                    libo_progress[0] = 1.0
                    return
                end
                next_step(u8("\xC7\xE0\xE3\xF0\xF3\xE7\xEA\xE0 navmesh..."))
                if not await_download(NAVMESH_URL, zip2) then
                    libo_state = 'error'; libo_status = u8("\xCE\xF8\xE8\xE1\xEA\xE0: navmesh.zip"); return
                end
                next_step(u8("\xD0\xE0\xF1\xEF\xE0\xEA\xEE\xE2\xEA\xE0 navmesh..."))
                local ok3, err3 = pcall(zzlib.unzip_full_archive_files, zip2, ml_path)
                if not ok3 then
                    libo_state = 'error'; libo_status = u8("\xCE\xF8\xE8\xE1\xEA\xE0 \xF0\xE0\xF1\xEF\xE0\xEA\xEE\xE2\xEA\xE8 navmesh: ") .. tostring(err3); return
                end
                pcall(os.remove, zip2)
                libo_state  = 'done'
                libo_status = u8("\xC3\xEE\xF2\xEE\xE2\xEE!")
                libo_progress[0] = 1.0
            end)
        end

        local rgb_hue       = 0.0

        local function hue2rgb(h)
            h = h % 1.0
            local r, g, b
            local i = math.floor(h * 6)
            local f = h * 6 - i
            local q = 1 - f
            if     i % 6 == 0 then r,g,b = 1,f,0
            elseif i % 6 == 1 then r,g,b = q,1,0
            elseif i % 6 == 2 then r,g,b = 0,1,f
            elseif i % 6 == 3 then r,g,b = 0,q,1
            elseif i % 6 == 4 then r,g,b = f,0,1
            else                    r,g,b = 1,0,q
            end
            return r, g, b
        end

        libo_register_frame = function()
            try_load_logo()
            im.OnFrame(function() return libo_show_win[0] end, function()
                local sw, sh = getScreenResolution()
                rgb_hue = (rgb_hue + 0.004) % 1.0
                local rr, rg, rb = hue2rgb(rgb_hue)
                im.PushStyleColor(im.Col.WindowBg, im.ImVec4(0.06, 0.06, 0.10, 0.97))
                im.PushStyleColor(im.Col.Border, im.ImVec4(0, 0, 0, 0))
                im.PushStyleColor(im.Col.BorderShadow, im.ImVec4(0, 0, 0, 0))
                imgui.GetStyle().WindowRounding  = 0
                imgui.GetStyle().WindowBorderSize = 0
                local WIN_W = 650
                local WIN_H = 286
                im.SetNextWindowPos(im.ImVec2(sw/2, sh/2), im.Cond.Always, im.ImVec2(0.5, 0.5))
                im.SetNextWindowSize(im.ImVec2(WIN_W, WIN_H), im.Cond.Always)
                im.Begin('##lb_missing', libo_show_win, im.WindowFlags.NoMove + im.WindowFlags.NoResize + im.WindowFlags.NoCollapse + im.WindowFlags.NoTitleBar)
                local wp   = im.GetWindowPos()
                local ws   = im.GetWindowSize()
                local draw = im.GetWindowDrawList()
                local fdl  = im.GetForegroundDrawList()
                for i = 1, 4 do
                    local off   = i * 2.0
                    local alpha = 0.14 - i * 0.025
                    local hr, hg, hb = hue2rgb((rgb_hue + i * 0.06) % 1.0)
                    fdl:AddRect(
                        im.ImVec2(wp.x - off, wp.y - off),
                        im.ImVec2(wp.x + ws.x + off, wp.y + ws.y + off),
                        im.ColorConvertFloat4ToU32(im.ImVec4(hr, hg, hb, alpha)),
                        0, 0, off * 1.5)
                end
                fdl:AddRect(
                    im.ImVec2(wp.x, wp.y),
                    im.ImVec2(wp.x + ws.x, wp.y + ws.y),
                    im.ColorConvertFloat4ToU32(im.ImVec4(rr, rg, rb, 1.0)),
                    0, 0, 1.5)

                local PAD       = 16
                local LOGO_W    = WIN_H - PAD * 2
                local LOGO_H    = LOGO_W -10
                local win_w     = WIN_W
                local content_x = LOGO_W + PAD * 2 + 8
                im.SetCursorPos(im.ImVec2(PAD, PAD))
                if logo_loaded and logo_tex then
                    im.Image(logo_tex, im.ImVec2(LOGO_W, LOGO_H))
                else
                    im.PushStyleColor(im.Col.Button, im.ImVec4(0.10, 0.10, 0.16, 1))
                    im.PushStyleColor(im.Col.ButtonHovered, im.ImVec4(0.10, 0.10, 0.16, 1))
                    im.PushStyleColor(im.Col.ButtonActive, im.ImVec4(0.10, 0.10, 0.16, 1))
                    im.Button('##logo_ph', im.ImVec2(LOGO_W, LOGO_H))
                    im.PopStyleColor(3)
                    im.SetCursorPos(im.ImVec2(PAD + LOGO_W/2 - 10, PAD + LOGO_H/2 - 8))
                    im.PushStyleColor(im.Col.Text, im.ImVec4(0.3, 0.3, 0.4, 1))
                    im.Text('...')
                    im.PopStyleColor()
                end
                local ver_str = 'v' .. tostring(thisScript and thisScript().version or '?')
                local ver_w   = im.CalcTextSize(ver_str).x
                im.SetCursorPos(im.ImVec2(PAD + (LOGO_W - ver_w) * 0.5, PAD + LOGO_H + 4))
                im.PushStyleColor(im.Col.Text, im.ImVec4(0.35, 0.35, 0.45, 1))
                im.Text(ver_str)
                im.PopStyleColor()
                local div_x = PAD + LOGO_W + PAD
                local div_r, div_g, div_b = hue2rgb((rgb_hue + 0.45) % 1.0)
                draw:AddLine(
                    im.ImVec2(wp.x + div_x, wp.y + 16),
                    im.ImVec2(wp.x + div_x, wp.y + WIN_H - 16),
                    im.ColorConvertFloat4ToU32(im.ImVec4(div_r, div_g, div_b, 0.35)), 1.0)

                im.SetCursorPos(im.ImVec2(content_x, 18))
                im.PushStyleColor(im.Col.Text, im.ImVec4(0.95, 0.95, 1.0, 1))
                im.Text('LesoRub BOT')
                im.PopStyleColor()

                im.SetCursorPos(im.ImVec2(content_x, 38))
                im.PushStyleColor(im.Col.Text, im.ImVec4(0.50, 0.50, 0.62, 1))
                im.Text(u8("\xCE\xF2\xF1\xF3\xF2\xF1\xF2\xE2\xF3\xFE\xF2 \xE1\xE8\xE1\xEB\xE8\xEE\xF2\xE5\xEA\xE8"))
                im.PopStyleColor()

                draw:AddLine(
                    im.ImVec2(wp.x + content_x, wp.y + 60),
                    im.ImVec2(wp.x + win_w - PAD, wp.y + 60),
                    im.ColorConvertFloat4ToU32(im.ImVec4(0.22, 0.22, 0.32, 1)), 1.0)

                local ly = 70
                im.PushStyleColor(im.Col.Text, im.ImVec4(1.0, 0.60, 0.18, 1))
                for i, lib in ipairs(missing) do
                    im.SetCursorPos(im.ImVec2(content_x, ly + (i-1)*19))
                    im.Text('* ' .. lib)
                end
                im.PopStyleColor()
                local btn_y = ly + #missing * 19 + 16
                im.SetCursorPos(im.ImVec2(content_x, btn_y))
                if libo_state == 'idle' then
                    im.PushStyleColor(im.Col.Text, im.ImVec4(0.55, 0.55, 0.68, 1))
                    im.Text(u8("\xC0\xE2\xF2\xEE\xF3\xF1\xF2\xE0\xED\xEE\xE2\xEA\xE0 \xF1 GitHub:"))
                    im.PopStyleColor()
                    im.SetCursorPos(im.ImVec2(content_x, btn_y + 22))
                    local bw = win_w - content_x - PAD
                    im.PushStyleColor(im.Col.Button,        im.ImVec4(0.16, 0.16, 0.26, 1.0))
                    im.PushStyleColor(im.Col.ButtonHovered, im.ImVec4(0.22, 0.22, 0.36, 1.0))
                    im.PushStyleColor(im.Col.ButtonActive,  im.ImVec4(0.10, 0.10, 0.18, 1.0))
                    im.PushStyleColor(im.Col.Text,          im.ImVec4(0.90, 0.90, 0.95, 1.0))
                    if im.Button(u8("\xD1\xEA\xE0\xF7\xE0\xF2\xFC \xE1\xE8\xE1\xEB\xE8\xEE\xF2\xE5\xEA\xE8"), im.ImVec2(bw, 40)) then
                        lua_thread.create(libo_start_dl)
                    end
                    im.PopStyleColor(4)

                elseif libo_state == 'downloading' then
                    im.PushStyleColor(im.Col.Text, im.ImVec4(1, 1, 0.3, 1))
                    im.Text(libo_status)
                    im.PopStyleColor()
                    im.SetCursorPos(im.ImVec2(content_x, btn_y + 22))
                    local bw2 = win_w - content_x - PAD
                    im.PushStyleColor(im.Col.PlotHistogram, im.ImVec4(rr, rg, rb, 1))
                    im.PushStyleColor(im.Col.FrameBg,       im.ImVec4(0.10, 0.10, 0.16, 1))
                    im.ProgressBar(libo_progress[0], im.ImVec2(bw2, 22), '')
                    im.PopStyleColor(2)

                elseif libo_state == 'done' then
                    _t = _t or os.clock()
                    local s = math.max(0, 5 - (os.clock() - _t))
                    if s <= 0 then thisScript():reload() end
                    im.PushStyleColor(im.Col.Text, im.ImVec4(0.2, 1, 0.4, 1))
                    im.Text(u8("\xD3\xF1\xF2\xE0\xED\xEE\xE2\xEB\xE5\xED\xEE!"))
                    im.PopStyleColor()
                    im.SetCursorPos(im.ImVec2(content_x, btn_y + 22))
                    im.PushStyleColor(im.Col.Text, im.ImVec4(1, 1, 0.3, 1))
                    im.Text(u8("\xCF\xE5\xF0\xE5\xE7\xE0\xEF\xF3\xF1\xEA \xF7\xE5\xF0\xE5\xE7 ") .. tostring(s) .. u8(" \xF1\xE5\xEA..."))
                    im.PopStyleColor()

                elseif libo_state == 'error' then
                    im.PushStyleColor(im.Col.Text, im.ImVec4(1, 0.25, 0.25, 1))
                    im.Text(u8("\xCE\xF8\xE8\xE1\xEA\xE0: ") .. libo_status)
                    im.PopStyleColor()
                    im.SetCursorPos(im.ImVec2(content_x, btn_y + 22))
                    im.PushStyleColor(im.Col.Text, im.ImVec4(0.45, 0.45, 0.55, 1))
                    im.TextWrapped(u8("\xD1\xEA\xE0\xF7\xE0\xF9\xE8\xF5 \xE2\xF0\xF3\xF7\xED\xF3\xFE: github.com/flupiflufi1/popa/releases"))
                    im.PopStyleColor()
                end

                im.End()
                im.PopStyleColor(3)
            end)
        end
    end
end

VERSION_JSON_URL = "https://raw.githubusercontent.com/flupiflufi1/popa/main/version.json?" .. tostring(os.clock())
local UPDATE_DOWNLOAD_URL = ""
local UPDATE_LATEST_VER  = ""
local update_available   = nil
local update_check_done  = false
local update_popup_shown = false
local upd_popup_open     = imgui.new.bool(true)

local function check_version_silent()
    lua_thread.create(function()
        local dl = require('moonloader').download_status
        local tmp = os.tmpname()
        if doesFileExist(tmp) then os.remove(tmp) end
        local done = false
        downloadUrlToFile(VERSION_JSON_URL, tmp, function(_, st)
            if st == dl.STATUS_ENDDOWNLOADDATA then
                done = true
            elseif st == dl.STATUSEX_ENDDOWNLOAD and not done then
                update_check_done = true
                update_available = false
                pcall(os.remove, tmp)
            end
        end)
        local timeout = os.clock() + 10
        while not done and os.clock() < timeout do wait(200) end
        if done and doesFileExist(tmp) then
            local f = io.open(tmp, 'r')
            if f then
                local ok, vdata = pcall(decodeJson, f:read('*a'))
                f:close()
                if ok and vdata and vdata.latest then
                    UPDATE_LATEST_VER   = vdata.latest
                    UPDATE_DOWNLOAD_URL = vdata.updateurl or ""
                    if vdata.latest ~= thisScript().version then
                        update_available = true
                    else
                        update_available = false
                    end
                else
                    update_available = false
                end
            else
                update_available = false
            end
            pcall(os.remove, tmp)
        else
            update_available = false
        end
        update_check_done = true
    end)
end
if not libs_missing then
    NavMesh = require("navmesh.navmesh")
    nav_movement = require("navmesh.movement")
    nav_render = require("navmesh.render")
end

local new = imgui.new
local iv2 = imgui.ImVec2
local iv4 = imgui.ImVec4

-- ×àñòèöû íà òåëåæêå (ñîçäàþòñÿ ëåíèâî ïðè ïåðâîì êàäðå)
local telega_particles = nil
local function get_telega_particles()
    if not ok_particles then return nil end
    if not telega_particles then
        telega_particles = Particles:new({
            max_particles    = 25,
            gravity          = -0.03,
            color            = {1.0, 0.65, 0.0, 1.0},
            line_color       = {1.0, 0.75, 0.1, 0.55},
            line_thickness   = 1.2,
            max_distance     = 40,
            boundary_behavior= "respawn",
            infinite_life    = false,
            speed_range      = {-0.8, 0.8},
            min_speed        = 0.3,
            max_speed        = 1.5,
            particle_size    = 3,
            wind             = 0,
            friction         = 0.97,
        })
    end
    return telega_particles
end
local conv_c = imgui.ColorConvertFloat4ToU32
local need_find_telega = false
local need_find_telega_time = 0
local has_telega = false
local safe_point_away = {x = -502.42962646484, y = -182.15553283691, z = 77.370460510254}
local safe_point = {-502.42962646484, -182.15553283691, 77.370460510254}
local sdacha_points = {
    {x = -498.21423339844, y = -200.26248168945, z = 78.761642456055},
    {x = -557.31085205078, y = -199.52032470703, z = 78.531639099121}
}

local new_points = {
    {x = -479.8229, y = -160.3730, z = 77.2529}, {x = -480.9420, y = -169.5446, z = 78.2109}, {x = -481.4666, y = -183.4663, z = 78.1901}
}
local ignore_trees = {
    {-562, -135, 72},
    {-575, -164, 78},
    {-456, -162, 76},
    {-542, -142, 74}
}
local pickup_telega_pos = nil
local next_telega_pos = nil
local pickup_telega_skip_check = false
local saved_tree_points = nil
local saved_tree_point_idx = 1

local tree_centers = {
    {-534.18, -162.23, 76.84},
    {-581.75, -154.33, 76.46},
    {-614.24, -146.86, 70.06},
    {-658.58, -141.35, 59.48},
    {-685.15, -110.72, 62.53},
    {-657.99, -109.62, 61.33},
    {-673.37, -74.75, 65.39},
    {-636.36, -76.42, 63.21},
    {-628.33, -104.96, 63.92},
    {-647.08, -45.01, 64.33},
    {-627.31, -0.48, 59.58},
    {-601.90, -67.80, 61.81},
    {-583.19, -111.42, 65.89},
    {-548.49, -132.31, 68.71},
    {-528.83, -113.18, 62.74},
    {-495.38, -127.08, 65.48},
    {-470.24, -121.97, 62.97},
    {-444.63, -119.02, 61.46},
    {-475.98, -154.01, 73.65},
    {-435.24, -153.45, 71.01},
    {-433.32, -84.32, 56.06},
    {-457.07, -77.06, 57.20},
    {-437.62, -47.63, 57.20},
    {-432.54, -19.52, 52.84},
    {-499.05, -88.52, 60.15},
    {-474.82, 28.11, 44.77},
    {-442.70, 8.73, 49.98},
    {-477.46, -57.97, 59.11},
    {-480.73, -30.00, 57.20},
    {-523.44, -49.36, 60.43},
    {-513.20, 11.60, 51.80},
    {-547.04, 46.71, 53.99},
    {-584.95, -29.21, 62.79},
    {-592.59, 1.12, 59.66},
    {-576.76, 38.15, 54.24},
    {-549.56, -20.07, 61.93},
    {-558.63, 23.08, 59.76},
    {-564.32, -62.93, 62.77}
}

local all_anims = {
    "abseil", "arrestgun", "atm", "bike_elbowl", "bike_elbowr", "bike_fallr", "bike_fall_off",
    "bike_pickupl", "bike_pickupr", "bike_pullupl", "bike_pullupr", "bomber",
    "car_alignhi_lhs", "car_alignhi_rhs", "car_align_lhs", "car_align_rhs",
    "car_closedoorl_lhs", "car_closedoorl_rhs", "car_closedoor_lhs", "car_closedoor_rhs",
    "car_close_lhs", "car_close_rhs", "car_crawloutrhs", "car_dead_lhs", "car_dead_rhs",
    "car_doorlocked_lhs", "car_doorlocked_rhs", "car_fallout_lhs", "car_fallout_rhs",
    "car_getinl_lhs", "car_getinl_rhs", "car_getin_lhs", "car_getin_rhs",
    "car_getoutl_lhs", "car_getoutl_rhs", "car_getout_lhs", "car_getout_rhs",
    "car_hookertalk", "car_jackedlhs", "car_jackedrhs", "car_jumpin_lhs", "car_lb",
    "car_lb_pro", "car_lb_weak", "car_ljackedlhs", "car_ljackedrhs", "car_lshuffle_rhs",
    "car_lsit", "car_open_lhs", "car_open_rhs", "car_pulloutl_lhs", "car_pulloutl_rhs",
    "car_pullout_lhs", "car_pullout_rhs", "car_qjacked", "car_rolldoor", "car_rolldoorlo",
    "car_rollout_lhs", "car_rollout_rhs", "car_shuffle_rhs", "car_sit", "car_sitp",
    "car_sitplo", "car_sit_pro", "car_sit_weak", "car_tune_radio", "climb_idle",
    "climb_jump", "climb_jump2fall", "climb_jump_b", "climb_pull", "climb_stand",
    "climb_stand_finish", "cower", "crouch_roll_l", "crouch_roll_r", "dam_arml_frmbk",
    "dam_arml_frmft", "dam_arml_frmlt", "dam_armr_frmbk", "dam_armr_frmft",
    "dam_armr_frmrt", "dam_legl_frmbk", "dam_legl_frmft", "dam_legl_frmlt",
    "dam_legr_frmbk", "dam_legr_frmft", "dam_legr_frmrt", "dam_stomach_frmbk",
    "dam_stomach_frmft", "dam_stomach_frmlt", "dam_stomach_frmrt", "door_lhinge_o",
    "door_rhinge_o", "drivebyl_l", "drivebyl_r", "driveby_l", "driveby_r", "drive_boat",
    "drive_boat_back", "drive_boat_l", "drive_boat_r", "drive_l", "drive_lo_l",
    "drive_lo_r", "drive_l_pro", "drive_l_pro_slow", "drive_l_slow", "drive_l_weak",
    "drive_l_weak_slow", "drive_r", "drive_r_pro", "drive_r_pro_slow", "drive_r_slow",
    "drive_r_weak", "drive_r_weak_slow", "drive_truck", "drive_truck_back",
    "drive_truck_l", "drive_truck_r", "drown", "duck_cower", "endchat_01", "endchat_02",
    "endchat_03", "ev_dive", "ev_step", "facanger", "facgum", "facsurp", "facsurpm",
    "factalk", "facurios", "fall_back", "fall_collapse", "fall_fall", "fall_front",
    "fall_glide", "fall_land", "fall_skydive", "fight2idle", "fighta_1", "fighta_2",
    "fighta_3", "fighta_block", "fighta_g", "fighta_m", "fightidle", "fightshb",
    "fightshf", "fightsh_bwd", "fightsh_fwd", "fightsh_left", "fightsh_right",
    "flee_lkaround_01", "floor_hit", "floor_hit_f", "fucku", "gang_gunstand", "gas_cwr",
    "getup", "getup_front", "gum_eat", "guncrouchbwd", "guncrouchfwd", "gunmove_bwd",
    "gunmove_fwd", "gunmove_l", "gunmove_r", "gun_2_idle", "gun_butt",
    "gun_butt_crouch", "gun_stand", "handscower", "handsup", "hita_1", "hita_2",
    "hita_3", "hit_back", "hit_behind", "hit_front", "hit_gun_butt", "hit_l", "hit_r",
    "hit_walk", "hit_wall", "idlestance_fat", "idlestance_old", "idle_armed",
    "idle_chat", "idle_csaw", "idle_gang1", "idle_hbhb", "idle_rocket", "idle_stance",
    "idle_taxi", "idle_tired", "jetpack_idle", "jog_femalea", "jog_malea", "jump_glide",
    "jump_land", "jump_launch", "jump_launch_r", "kart_drive", "kart_l", "kart_lb",
    "kart_r", "kd_left", "kd_right", "ko_shot_face", "ko_shot_front", "ko_shot_stom",
    "ko_skid_back", "ko_skid_front", "ko_spin_l", "ko_spin_r", "pass_smoke_in_car",
    "phone_in", "phone_out", "phone_talk", "player_sneak", "player_sneak_walkstart",
    "roadcross", "roadcross_female", "roadcross_gang", "roadcross_old", "run_1armed",
    "run_armed", "run_civi", "run_csaw", "run_fat", "run_fatold", "run_gang1",
    "run_left", "run_old", "run_player", "run_right", "run_rocket", "run_stop",
    "run_stopr", "run_wuzi", "seat_down", "seat_idle", "seat_up", "shot_leftp",
    "shot_partial", "shot_partial_b", "shot_rightp", "shove_partial", "smoke_in_car",
    "sprint_civi", "sprint_panic", "sprint_wuzi", "swat_run", "swim_tread", "tap_hand",
    "tap_handp", "turn_180", "turn_l", "turn_r", "walk_armed", "walk_civi",
    "walk_csaw", "walk_doorpartial", "walk_drunk", "walk_fat", "walk_fatold",
    "walk_gang1", "walk_gang2", "walk_old", "walk_player", "walk_rocket",
    "walk_shuffle", "walk_start", "walk_start_armed", "walk_start_csaw",
    "walk_start_rocket", "walk_wuzi", "weapon_crouch", "woman_idlestance", "woman_run",
    "woman_runbusy", "woman_runfatold", "woman_runpanic", "woman_runsexy",
    "woman_walkbusy", "woman_walkfatold", "woman_walknorm", "woman_walkold",
    "woman_walkpro", "woman_walksexy", "woman_walkshop", "xpressscratch"
}
 
--êîëèçèÿ
local mainIni = {
    act = {
        cmd = "col",
        player = false,
        vehicle = false,
        object = false
    },
    press = {
        menu = false,
        player = false,
        vehicle = false,
        object = false
    },
    alpha = {
        player = 250,
        vehicle = 250,
        object = 250
    },
    delObject = {
        blackList = "",
        whiteList = ""
    }
}
 
config = {
    radar = false,
    debug = false,
    tracers = false,
    stat_status = false,
    x = 700,
    y = 800,
    derevo_value = 0,
    drova_value = 0,  
    radar_size = 299,
    radar_zoom = 20,
    radar_pos = {187, 553},
    cjSkin = false,
    show_navmesh = false,
    animspeed_enabled = false,
    animspeed_value = 1.0,
    runskincj = false,
    autobeer = false,
    infinite_run = false,
    warningseytg = false,
    telegram = false,
    smart_sdacha = false,
    selected_sdacha_index = 1,
    auto_job = true,
    auto = false,
    telegram_token = "",
    telegram_chat_id = "",
    anti_vehicle = false,
    warning_color = {1.0, 0.0, 0.3, 1.0},
    antiadmin_autoOff = true,
    offer_telegram = false,
    avatar_path  = "",
    daily_trees = 0,
    weekly_trees = 0,
    daily_drova = 0,
    weekly_drova = 0,
    degniebat_den = 0,
    degniebat_week = 0,
    bot_hotkey = 0,
    combo_key1 = 0,
    combo_key2 = 0,
    menu_movable = false,
    menu_pos_x = 0,
    menu_pos_y = 0,
    menu_command = "sawbot",
    bot_command = "sawrun",
    last_day = tonumber(os.date("%d")),
    last_week = tonumber(os.date("%U")),   
    antiadmin_telegramNotf = false, 
    antiadmin_reversal = false,
    antiadmin_blinking = false,
    antiadmin_autoExit = false,
    antiadmin_skipdialog = false,
    antiadmin_warningsey = false,
    antiadmin_kick = false,
    antiadmin_skip11 = 1250,
    antiadmin_skip22 = 1500,
    antiadmin_flash = 1,
    enable_random_pauses = true,
    enable_jump = true,
    enable_random_turns = true,
    autoeat = false,
    eatmethod = 0,
    eatpercent = 1,
    autolarek = false,
    antibot_antifreeze = false,
    camera_smooth_close = 0.15,
    camera_turn_slow = 45.0,
    camera_turn_mid = 120.0,
    camera_turn_fast = 360.0,
    camera_smooth_mid = 0.08,
    camera_smooth_far = 0.04,
    camera_dist = 10.0,
    camera_height_offset = 1.0,
    check_stuck = false,
    antiadmin_sound_path = "",
    antiadmin_play_sound = false,
    telegram_api_url = "https://api.telegram.org",
}
 
cVARS = {
    bot = new.bool(false),
    menu = new.bool(false),
    radar = new.bool(false),
    tracers = new.bool(false),
    debug = new.bool(false),
    runskincj = new.bool(config.runskincj),
    x = 700,
    y = 800,
    stat_status = new.bool(false),
    derevo_value = new.int(80000),
    drova_value = new.int(1000),
    degniebat = new.int(0),
    derevo_amount = new.int(0),
    drova_amount = new.int(0),
    animspeed_enabled = new.bool(false),
    animspeed_value = new.float(1.0),
    color = '0xFFFFFFFF',
    r = 0.93023252487183,
    g = 0.74464881420135,
    b = 0.17739316821098,
    rainbowcolor = new.bool(false),
    radar_size = new.int(299),
    radar_zoom = new.int(20),
    menu_movable = new.bool(config.menu_movable),
    menu_pos_x = new.int(config.menu_pos_x),
    menu_pos_y = new.int(config.menu_pos_y),
    anti_vehicle = new.bool(config.anti_vehicle),
    combo_key2 = new.int(config.combo_key2),
    combo_key1 = new.int(config.combo_key1),
    smart_sdacha = new.bool(config.smart_sdacha),
    auto_job = new.bool(config.auto_job),
    offer_telegram = new.bool(config.offer_telegram),
    selected_sdacha_index = new.int(config.selected_sdacha_index),
    infinite_run = new.bool(config.infinite_run),
    warning_color = new.float[4](config.warning_color[1], config.warning_color[2], config.warning_color[3], config.warning_color[4]),
    warningseytg = new.bool(config.warningseytg),
    enable_jump = new.bool(config.enable_jump),
    enable_random_turns = new.bool(config.enable_random_turns),
    autobeer = new.bool(config.autobeer),
    cjSkin = new.bool(config.cjSkin),
    show_navmesh = new.bool(config.show_navmesh or false),
    telegram = new.bool(config.telegram),
    telegram_token = new.char[256](),
    telegram_chat_id = new.char[256](),
    auto = new.bool(config.auto),
    menu_command = new.char[64](),
    bot_command = new.char[64](),
    menu_hotkey = new.int(config.menu_hotkey or 0),
    bot_hotkey = new.int(config.bot_hotkey),
    daily_trees  = new.int(config.daily_trees),
    weekly_trees = new.int(config.weekly_trees),
    daily_drova  = new.int(config.daily_drova),
    weekly_drova = new.int(config.weekly_drova),
    degniebat_den  = new.int(config.degniebat_den),
    degniebat_week = new.int(config.degniebat_week),
    last_day = new.int(config.last_day),
    last_week = new.int(config.last_week),
    antiadmin_autoOff = new.bool(config.antiadmin_autoOff),
    antiadmin_telegramNotf = new.bool(config.antiadmin_telegramNotf),
    antiadmin_reversal = new.bool(config.antiadmin_reversal),
    antiadmin_blinking = new.bool(config.antiadmin_blinking),
    antiadmin_autoExit = new.bool(config.antiadmin_autoExit),
    antibot_antifreeze = new.bool(config.antibot_antifreeze),
    antiadmin_skipdialog = new.bool(config.antiadmin_skipdialog),
    antiadmin_warningsey = new.bool(config.antiadmin_warningsey),
    antiadmin_skip11 = new.int(config.antiadmin_skip11),
    antiadmin_skip22 = new.int(config.antiadmin_skip22),
    antiadmin_flash = new.int(config.antiadmin_flash),
    antiadmin_kick = new.bool(config.antiadmin_kick),
    enable_random_pauses = new.bool(config.enable_random_pauses),
    autoeat = new.bool(config.autoeat),
    eatmethod = new.int(config.eatmethod),
    eatpercent = new.int(config.eatpercent),
    autolarek = new.bool(config.autolarek),
    camera_smooth_close = new.float(0.15),
    camera_turn_slow = new.float(45.0),
    camera_turn_mid  = new.float(120.0),
    camera_turn_fast = new.float(360.0),
    camera_smooth_mid = new.float(0.08),
    camera_smooth_far = new.float(0.04),
    camera_dist = new.float(10.0),
    camera_height_offset = new.float(1.0),
    check_stuck = new.bool(config.check_stuck),
    antiadmin_sound_path = new.char[256]("moonloader/config/admin_alert.mp3"),
    antiadmin_play_sound = new.bool(config.antiadmin_play_sound),
    avatar_path = new.char[256]("avatar.png"),
    telegram_api_url = new.char[256]("https://api.telegram.org"),
}
 
ffi.copy(cVARS.menu_command, config.menu_command)
ffi.copy(cVARS.bot_command, config.bot_command)
ffi.copy(cVARS.avatar_path, config.avatar_path or "avatar.png")
ffi.copy(cVARS.telegram_api_url, config.telegram_api_url)
local function tg_api_url()
    return u8:decode(ffi.string(cVARS.telegram_api_url))
end

local object = imgui.new.bool(false)
local objectpen = imgui.new.bool(false)
local objectnotree = imgui.new.bool(false)
local player = imgui.new.bool(false)
local vehicle = imgui.new.bool(false)
local objectAlpha = imgui.new.int(mainIni.alpha.object)
local warning_color_window = imgui.new.bool(false)
local objectsettngs = imgui.new.bool(false)
local show_telegram_popup = new.bool(false)
 
local sdacha_names = {
    u8("\xCF\xE5\xF0\xE2\xE0\xFF \xF2\xEE\xF7\xEA\xE0 \xF1\xE4\xE0\xF7\xE8"),
    u8("\xC2\xF2\xEE\xF0\xE0\xFF \xF2\xEE\xF7\xEA\xE0 \xF1\xE4\xE0\xF7\xE8"),
}

--âñÿêàÿ õåðü ëîêàëüíàÿ áðóõ
local ImItems_sdacha = imgui.new['const char*'][#sdacha_names](sdacha_names)
local selected_sdacha = nil
local current_new_point_index = 1
local selected_new_points = {}
local cumshot = false
local turnleft = false
local turnright = false
local piska = false
local zalupa = false
local state_entered = {} 
local last_message_ids = {}
local active = false
local lastBeerTime = 0
local gradient_offset = 0 
local menu_open_time = nil
local menu_anim_duration = 0.45
local satiety
local walking = false
local formatScreenshot = '.jpg'
local selected_tab = u8("\xC3\xEB\xE0\xE2\xED\xE0\xFF")
local token = ""
local chat_id = ""
local updateid = nil
local audio = nil
local audiostream_state = require('moonloader').audiostream_state
local alert_audio = nil
 
local last_fix_zabor_id = 1
local bot_state = "IDLE"

local nav = nil
local nav_current_path = nil
local nav_path_index = 1
local nav_target_x = nil
local nav_target_y = nil
local nav_target_z = nil

local nav_segment_size   = 15.0
local nav_extend_dist    = 10.0
local nav_full_path      = {}
local nav_full_idx       = 1
local nav_last_built_x   = nil
local nav_scan_target_angle = nil
local nav_detour_angle  = 0.0
local nav_detour_step   = 30.0
local nav_detour_fails  = 0
local set_wait_alt = 0

local current_tree_points = {}
local current_tree_point_idx = 1
local minigame_running = false
local minigame_done_time = 0

local partner_name = nil
local partner_absent = false
local waiting_for_my_turn = false
local my_turn_ready = false

local last_alt = false
last_pos_x = 0
last_pos_y = 0
last_pos_z = 0
last_check_time = 0
stuck_ticks = 0
local nav_path_building = false
local CHECK_INTERVAL   = 0.9
local MIN_MOVE_DIST    = 0.35
local STUCK_THRESHOLD  = 4
local STUCK_ACTION_COOLDOWN = 2.5
last_stuck_action_time = 0
local last_cam_time = 0
 
local elements = {
    radar = {
        pos = {x = 187, y = 553},
        set_pos = false,
        set_pos_offset = {x = 0, y = 0},
        draw_points = {}
    },
    custom = {
        toggle_button = {},
        slider_custom = {}
    }
}
 
local method = {
    u8("\xD7\xE8\xEF\xF1\xFB"),
    u8("\xD0\xFB\xE1\xE0"),
    u8("\xCE\xEB\xE5\xED\xE8\xED\xE0")
}

local ImItems = imgui.new['const char*'][#method](method)
ffi.cdef [[
    typedef int BOOL;
    typedef unsigned long HANDLE;
    typedef HANDLE HWND;
    HWND GetActiveWindow(void);
    BOOL ShowWindow(HWND hWnd, int  nCmdShow);
    int __stdcall MoveFileA(const char *lpExistingFileName, const char *lpNewFileName);
    int __stdcall DeleteFileA(const char *lpFileName);
]]
 
local lower, sub, char, upper = string.lower, string.sub, string.char, string.upper
local concat = table.concat
local lu_rus, ul_rus = {}, {}
for i = 192, 223 do
    local A, a = char(i), char(i + 32)
    ul_rus[A] = a
    lu_rus[a] = A
end
local E, e = char(168), char(184)
ul_rus[E] = e
lu_rus[e] = E
 
function string.nlower(s)
    s = lower(s)
    local len, res = #s, {}
    for i = 1, len do
        local ch = sub(s, i, i)
        res[i] = ul_rus[ch] or ch
    end
    return concat(res)
end

local tree_avoid_circle_points = {}
local tree_avoid_circle_index = 1
local tree_circle_radius = 5.0
local tree_circle_direction = 1

function generateTreeAvoidCircle(center_x, center_y, center_z, radius, num_points)
    local points = {}
    local step = (2 * math.pi) / num_points
    
    for i = 0, num_points - 1 do
        local angle = i * step
        local x = center_x + math.cos(angle) * radius
        local y = center_y + math.sin(angle) * radius
        local z = center_z + 0.5
        table.insert(points, {x, y, z})
    end
    return points
end

function getTreeCenterFromPoint(tx, ty, tz)
    local nearest, dist = getNearestTreeCenter(tx, ty, tz)
    if nearest and dist < 30 then
        return nearest[1], nearest[2], nearest[3]
    end
    if #current_tree_points >= 2 then
        local p1 = current_tree_points[1]
        local p2 = current_tree_points[2]
        return (p1[1] + p2[1])/2, (p1[2] + p2[2])/2, (p1[3] + p2[3])/2
    end
    return tx, ty, tz
end

function findNearestSdachaPoint()
    local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
    local min_dist = math.huge
    local nearest_point = nil
    for _, point in ipairs(sdacha_points) do
        local distance = getDistanceBetweenCoords3d(mX, mY, mZ, point.x, point.y, point.z)
        if distance < min_dist then
            min_dist = distance
            nearest_point = point
        end
    end
    return nearest_point, min_dist
end
 
function lineVec(point1, point2, distance)
    local dx = point2.x - point1.x
    local dy = point2.y - point1.y
 
    local length = math.sqrt(dx * dx + dy * dy)
    local normalized_dx = dx / length
    local normalized_dy = dy / length
    local new_x = point1.x - normalized_dx * distance
    local new_y = point1.y - normalized_dy * distance
    return {x = new_x, y = new_y}
end
 
function findTable(table, value)
    for v in table:gmatch("%S+") do
        if v == value then
            return true
        end
    end
    return false
end
 
function applyAnimationSpeed()
    if cVARS.animspeed_enabled[0] then
        for _, anim_name in ipairs(all_anims) do
            setCharAnimSpeed(PLAYER_PED, anim_name, cVARS.animspeed_value[0])
        end
    else
        for _, anim_name in ipairs(all_anims) do
            setCharAnimSpeed(PLAYER_PED, anim_name, 1.0)
        end
    end
end
 
--êðàñèâî íàñðàë ïàêåòàìè êàñòîìíûìè
function sendCustomPacket(text)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #text)
    raknetBitStreamWriteString(bs, text)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end
function sendPacket_220_1_128()
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 1)
    raknetBitStreamWriteInt8(bs, 128)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end
function sendPacket_220_1_0()
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 1)
    raknetBitStreamWriteInt8(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end
 
local key_map = {
    65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
    48,49,50,51,52,53,54,55,56,57,
    96,97,98,99,100,101,102,103,104,105,106,107,109,110,111,
    112,113,114,115,116,117,118,119,120,121,122,123,
    8,9,13,16,17,19,20,27,32,33,34,35,36,45,46,144,145
}

function getPressedKey()
    for _, key in ipairs(key_map) do
        if isKeyJustPressed(key) then
            return key
        end
    end
    return nil
end
 
function getKeyName(key)
    local key_names = {
        [8]="Backspace",[9]="Tab",[13]="Enter",[16]="Shift",[17]="Ctrl",[19]="Pause",
        [20]="CapsLock",[27]="Esc",[32]="Space",[33]="Page Up",[34]="Page Down",
        [35]="End",[36]="Home",[45]="Insert",[46]="Delete",[144]="Num Lock",[145]="Scroll Lock",
        [112]="F1",[113]="F2",[114]="F3",[115]="F4",[116]="F5",[117]="F6",[118]="F7",
        [119]="F8",[120]="F9",[121]="F10",[122]="F11",[123]="F12",
        [96]="Num0",[97]="Num1",[98]="Num2",[99]="Num3",[100]="Num4",[101]="Num5",
        [102]="Num6",[103]="Num7",[104]="Num8",[105]="Num9",[106]="Num*",[107]="Num+",[109]="Num-",[110]="Num.",[111]="Num/",
        [48]="0",[49]="1",[50]="2",[51]="3",[52]="4",[53]="5",[54]="6",[55]="7",[56]="8",[57]="9",
        [65]="A",[66]="B",[67]="C",[68]="D",[69]="E",[70]="F",[71]="G",[72]="H",[73]="I",[74]="J",
        [75]="K",[76]="L",[77]="M",[78]="N",[79]="O",[80]="P",[81]="Q",[82]="R",[83]="S",[84]="T",
        [85]="U",[86]="V",[87]="W",[88]="X",[89]="Y",[90]="Z"
    }
    return key_names[key] or "Unknown"
end

function playAlertSound()
    if not cVARS.antiadmin_play_sound[0] then return end
    local path = ffi.string(cVARS.antiadmin_sound_path)
    if path == "" then return end
 
    if alert_audio then
        setAudioStreamState(alert_audio, audiostream_state.STOP)
        alert_audio = nil
    end
 
    alert_audio = loadAudioStream(path)
    if alert_audio then
        setAudioStreamVolume(alert_audio, 1.0)
        setAudioStreamState(alert_audio, audiostream_state.PLAY)
    else
        cMsg("\xCE\xF8\xE8\xE1\xEA\xE0 \xE7\xE0\xE3\xF0\xF3\xE7\xEA\xE8 \xE7\xE2\xF3\xEA\xE0 \xE0\xED\xF2\xE8\xE0\xE4\xEC\xE8\xED\xE0: " .. path)
    end
end

local avatar_texture = nil
local avatar_path_cached = ""
 
local function reload_avatar()
    local path = ffi.string(cVARS.avatar_path)
    if path == "" then
        avatar_texture = nil
        return
    end
    local full_path
    if path:find("[/\\]") or path:find("^%a:") then
        full_path = path
    else
        full_path = getWorkingDirectory() .. "\\resource\\" .. path
    end
    avatar_texture = nil
    avatar_path_cached = full_path
    if doesFileExist(full_path) then
        local tex = imgui.CreateTextureFromFile(full_path)
        if tex then
            avatar_texture = tex
        else
            sampAddChatMessage("\xCD\xE5 \xF3\xE4\xE0\xEB\xEE\xF1\xFC \xE7\xE0\xE3\xF0\xF3\xE7\xE8\xF2\xFC \xE0\xE2\xE0\xF2\xE0\xF0: " .. full_path, 0xFF4444)
        end
    else
        sampAddChatMessage("\xD4\xE0\xE9\xEB \xE0\xE2\xE0\xF2\xE0\xF0\xE0 \xED\xE5 \xED\xE0\xE9\xE4\xE5\xED: " .. full_path, 0xFF4444)
    end
end

function getNearestTreeCenter(target_x, target_y, target_z)
    local min_dist = math.huge
    local nearest = nil
    
    for _, center in ipairs(tree_centers) do
        local dist = getDistanceBetweenCoords3d(
            target_x, target_y, target_z,
            center[1], center[2], center[3]
        )
        if dist < min_dist then
            min_dist = dist
            nearest = center
        end
    end
    
    return nearest, min_dist
end

function Draw3DCircle(x, y, z, radius, color) -- by MrCreepTon
    local screen_x_line_old, screen_y_line_old;
    for rot=0, 360 do
        local rot_temp = math.rad(rot)
        local lineX, lineY, lineZ = radius * math.cos(rot_temp) + x, radius * math.sin(rot_temp) + y, z
        local screen_x_line, screen_y_line = convert3DCoordsToScreen(lineX, lineY, lineZ)
        if screen_x_line ~=nil and screen_x_line_old ~= nil and isPointOnScreen(lineX, lineY, lineZ, 1) then renderDrawLine(screen_x_line, screen_y_line, screen_x_line_old, screen_y_line_old, 3, color) end
        screen_x_line_old, screen_y_line_old = screen_x_line, screen_y_line
    end
end

local autoEnabled = true
local isProcessingTurn = false

local currentStart = 0
local currentWidth = 0

local taskQueue = {}
local workerRunning = false

function startWorker()
    if workerRunning then return end
    workerRunning = true
    lua_thread.create(function()
        while workerRunning do
            if #taskQueue > 0 then
                local task = table.remove(taskQueue, 1)
                task()
            else
                wait(50)
            end
        end
    end)
end

function pushTask(fn)
    taskQueue[#taskQueue + 1] = fn
end

function performTurn()
    if not autoEnabled or isProcessingTurn or currentWidth == 0 then
        return
    end
    isProcessingTurn = true
    local pos = math.floor(currentStart + currentWidth / 2 + 0.5)
    local whatisthis = math.floor((pos - currentStart) / currentWidth * 100 + 0.5)
    pushTask(function()
        sendCustomPacket("lumbering-game.start")
        local speed = currentWidth > 0 and currentWidth or 1
        local waitTime = math.floor(pos / speed + 0.5) * 75
        wait(waitTime)
        sendCustomPacket(string.format(
            "lumbering-game.turnEnd|%d|%d",
            pos,
            whatisthis
        ))
        wait(200)
        isProcessingTurn = false
    end)
end

function findTelegaIn3DText()
    local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
    local best_pos = nil
    local best_dist = 20
    for id = 0, 2048 do
        if sampIs3dTextDefined(id) then
            local t, c, posX, posY, posZ = sampGet3dTextInfoById(id)
            if t and t:find(u8("\xC4\xF0\xEE\xE2\xE0:")) then
                local dist = getDistanceBetweenCoords3d(posX, posY, posZ, mX, mY, mZ)
                if dist < best_dist then
                    best_dist = dist
                    best_pos = {posX, posY, posZ}
                end
            end
        end
    end
    if best_pos then
        --sampAddChatMessage("[BOT] telega: " .. math.floor(best_pos[1]) .. " " .. math.floor(best_pos[2]) .. " d:" .. math.floor(best_dist), 0x00FF00)
    else
        --sampAddChatMessage("[BOT] telega NOT found", 0xFF4444)
    end
    return best_pos
end

function main()
    math.randomseed(os.time())
    if libs_missing then
        if libo_register_frame then libo_register_frame() end
        while libo_show_win and libo_show_win[0] do wait(100) end
        return
    end
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while not isSampAvailable() do wait(0) end
    check_version_silent()
    hwin = ffi.C.GetActiveWindow()
    getLastUpdate()
    cMsg("\xD3\xF1\xEF\xE5\xF8\xED\xEE \xE7\xE0\xE3\xF0\xF3\xE6\xE5\xED! \xC8\xF1\xEF\xEE\xEB\xFC\xE7\xF3\xE9 {ABABAB}/sawbot")
    lua_thread.create(warning)
    lua_thread.create(warning2)
    lua_thread.create(get_telegram_updates)
    load_cfg()
    startWorker()
    sampRegisterChatCommand(config.menu_command, function()
        cVARS.menu[0] = not cVARS.menu[0]
        if cVARS.menu[0] then menu_open_time = os.clock() end
        if not cVARS.bot[0] then bot_state = "IDLE" end
    end)
    sampRegisterChatCommand(ffi.string(cVARS.bot_command), function()
        cVARS.bot[0] = not cVARS.bot[0]
        if not cVARS.bot[0] then bot_state = "IDLE" end
    end)
    if cVARS.telegram[0] then
        token = u8:decode(ffi.string(cVARS.telegram_token))
        chat_id = u8:decode(ffi.string(cVARS.telegram_chat_id))
        
        if string.len(token) > 0 and string.len(chat_id) > 0 then
            getLastUpdate()
            lua_thread.create(get_telegram_updates)
        end
    end

    X,Y = getScreenResolution()    
    nav = NavMesh.new()
    nav:init()
    cMsg("NavMesh \xE8\xED\xE8\xF6\xE8\xE0\xEB\xE8\xE7\xE8\xF0\xEE\xE2\xE0\xED!")
    while true do wait(0)
        if nav then nav:update_mesh() end
        if nav and cVARS.show_navmesh[0] then nav_render.renderNavMesh(nav) end
        if nav_current_path then nav_render.renderNavPath(nav_current_path, nav_path_index) end
        if cVARS.menu_hotkey[0] and isKeyJustPressed(cVARS.menu_hotkey[0]) then
            cVARS.menu[0] = not cVARS.menu[0]
            if cVARS.menu[0] then menu_open_time = os.clock() end
        end
        if cVARS.bot_hotkey[0] and isKeyJustPressed(cVARS.bot_hotkey[0]) then
            cVARS.bot[0] = not cVARS.bot[0]
            if not cVARS.bot[0] then bot_state = "IDLE" end
            syncToggleButton(ti.ICON_TREES .. u8(" \xC1\xEE\xF2 \xE4\xE5\xF0\xE5\xE2\xE0"), cVARS.bot[0])
        end
        if cVARS.combo_key1[0] and cVARS.combo_key2[0] then
            local key1_down = isKeyDown(cVARS.combo_key1[0])
            local key2_down = isKeyDown(cVARS.combo_key2[0])
            if key1_down and key2_down then
                cVARS.menu[0] = not cVARS.menu[0]
                if cVARS.menu[0] then menu_open_time = os.clock() end
                wait(200)
            end
        end
        gradient_offset = gradient_offset + 0.5
        if gradient_offset > 300 then gradient_offset = 0 end
        applyAnimationSpeed()
        if cVARS.infinite_run[0] then
            mem.setint8(0xB7CEE4, 1)
        else
            mem.setint8(0xB7CEE4, 0)
        end
        if not cVARS.bot[0] then
            walking = false
        end
        if cVARS.autobeer[0] and cVARS.bot[0] then
            local now = os.clock()
            if now - lastBeerTime >= 600 then
                lastBeerTime = now
                sampSendChat("/beer")
                sampAddChatMessage("{00FF00}[AutoBeer]{FFFFFF} \xC2\xFB\xEF\xE8\xF2\xEE \xEF\xE8\xE2\xEE (\xE8\xED\xF2\xE5\xF0\xE2\xE0\xEB 10 \xEC\xE8\xED\xF3\xF2)", -1)
            end
        end
        if cVARS.runskincj[0] then
            mem.setuint8(sampGetServerSettingsPtr(), 1)
        end
        if cVARS.stat_status[0] then
            zarabotok = cVARS.derevo_amount[0] * cVARS.derevo_value[0] + cVARS.drova_amount[0] * cVARS.drova_value[0]
            r, g, b, a = rainbow(1, 255, 15)
            renderFontDrawText(font, (cVARS.bot[0] and u8("\xD1\xF2\xE0\xF2\xF3\xF1: \xD0\xE0\xE1\xEE\xF2\xE0\xE5\xF2!") or u8("\xD1\xF2\xE0\xF2\xF3\xF1: \xC2\xFB\xEA\xEB"))..u8("\n\xCA\xEE\xEB-\xE2\xEE \xE4\xE5\xF0\xE5\xE2\xE0: ")..cVARS.derevo_amount[0]..' ('..zarabotok ..'$)', cVARS.x, cVARS.y, (cVARS.rainbowcolor[0] and join_argb(a, r, g, b) or -1))
        end
        if cVARS.antiadmin_skipdialog[0] then
            dialogskip = math.random(cVARS.antiadmin_skip11[0], cVARS.antiadmin_skip22[0])
        end
        if cVARS.tracers[0] then
            local x, y, z = getCharCoordinates(PLAYER_PED)
            local pX, pY = convert3DCoordsToScreen(x, y, z)
            for id = 0, 2048 do
                if sampIs3dTextDefined(id) then
                    local text, color, posX, posY, posZ, distance, ignore_walls, player, veh = sampGet3dTextInfoById(id)
                    local distance = getDistanceBetweenCoords3d(posX, posY, posZ, x, y, z)
                    if isTreeLabel(text) and isPointOnScreen(posX,posY,posZ, -1) and distance < 60 then 
                        local wX, wY = convert3DCoordsToScreen(posX,posY,posZ)
                        renderDrawLine(pX,pY,wX,wY, 1,0xFFFFFFFF)
                        renderDrawPolygon(wX,wY,5,5,16,0,0xFF00FFFF)
                    end
                end
            end
        end
        if satiety and cVARS.autoeat[0] and satiety <= cVARS.eatpercent[0] then
            if cVARS.eatmethod[0] == 0 then
                wait(500)
                sampSendChat('/cheeps')
                wait(3500)
            elseif cVARS.eatmethod[0] == 1 then
                wait(500)
                sampSendChat('/jfish')
                wait(3500)
            elseif cVARS.eatmethod[0] == 2 then
                wait(500)
                sampSendChat('/jmeat')
                wait(3500)
            elseif cVARS.eatmethod[0] == 3 then
                wait(500)
                sampSendChat('/meatbag')
                wait(3500)
            end
        end
        if objectpen[0] then
            for k, v in ipairs(getAllObjects()) do
                if doesObjectExist(v) then
                    local model = tostring(getObjectModel(v))
                    if model == "14872" then
                        if objectpen[0] then
                            setObjectCollision(v, not objectpen)
                            mad.set_object_model_alpha(v, mainIni.alpha.object)
                        end
                    end
                end
            end
        else
            for k, v in ipairs(getAllObjects()) do
                if doesObjectExist(v) then
                    mad.set_object_model_alpha(v, 250)
                end
            end
        end
        --êîëèçèÿ
        if object[0] then
            for k, v in ipairs(getAllObjects()) do
                if doesObjectExist(v) then
                    local model = tostring(getObjectModel(v))
 
                    if model == "687" or model == "685" then
                        if objectnotree[0] then
                            setObjectCollision(v, true)
                            mad.set_object_model_alpha(v, 250)
                        end
                    elseif model == "3172" or model == "3171" or model == "3168" then
                        setObjectCollision(v, false)
                        mad.set_object_model_alpha(v, mainIni.alpha.object)
                    else
                        if #tostring(mainIni.delObject.blackList) == 0 then
                            if not findTable(tostring(mainIni.delObject.whiteList), model) then
                                setObjectCollision(v, false)
                                mad.set_object_model_alpha(v, mainIni.alpha.object)
                            end
                        else
                            for n in tostring(mainIni.delObject.blackList):gmatch("(%S+)") do
                                if model == n then
                                    setObjectCollision(v, false)
                                    mad.set_object_model_alpha(v, mainIni.alpha.object)
                                end
                            end
                        end
                    end
                end
            end
        else
            for k, v in ipairs(getAllObjects()) do
                if doesObjectExist(v) then
                    mad.set_object_model_alpha(v, 250)
                end
            end
        end
        if player[0] then
            for k, v in ipairs(getAllChars()) do
                if doesCharExist(v) and v ~= PLAYER_PED then
                    setCharCollision(v, not player)
                end
            end
        end
        if vehicle[0] then
            for k, v in ipairs(getAllVehicles()) do
                if doesVehicleExist(v) then
                    setCarCollision(v, not vehicle)
                end
            end     
        else
            for k, v in ipairs(getAllVehicles()) do
                if doesVehicleExist(v) then
                    setCarCollision(v, true)
                end
            end
        end
                
        --êîëèçèÿ
        if changepos then
            sampToggleCursor(true)
            local x, y = getCursorPos()
            cVARS.x = x
            cVARS.y = y
            if isKeyJustPressed(0x01) then
            sampAddChatMessage("\xCF\xEE\xE7\xE8\xF6\xE8\xFF \xF1\xEE\xF5\xF0\xE0\xED\xE5\xED\xE0.", -1)
            changepos = false
            sampToggleCursor(false)
            end
        end
        if cVARS.bot[0] and 
           (bot_state == "SEARCH_TREE" or bot_state == "GO_TO_TREE_POINT" or bot_state == "PLAY_MINIGAME") then
            local target_x, target_y, target_z
            if current_tree_points and #current_tree_points > 0 then
                local idx = current_tree_point_idx or 1
                local pt = current_tree_points[idx]
                if pt then
                    target_x, target_y, target_z = pt[1], pt[2], pt[3]
                end
            end
            if target_x then
                local nearest_center, dist = getNearestTreeCenter(target_x, target_y, target_z)
                if nearest_center and dist < 30 then
                    lua_thread.create(function()
                        Draw3DCircle(nearest_center[1], nearest_center[2], nearest_center[3] + 0.5, 4.0, 0xFF37ff57)
                    end)
                end
            end
        end
        if cVARS.bot[0] then
            if need_find_telega then
                local pos = findTelegaIn3DText()
                if pos then
                    need_find_telega = false
                    if has_telega then
                        next_telega_pos = pos
                        --sampAddChatMessage("[BOT] next telega saved, will pick after delivery", 0xFFAA00)
                    else
                        pickup_telega_pos = pos
                        pickup_telega_skip_check = false
                        resetNavPath()
                        bot_state = "PICKUP_TELEGA"
                        state_entered["PICKUP_TELEGA"] = false
                    end
                elseif os.clock() - need_find_telega_time > 8.0 then
                    need_find_telega = false
                    --sampAddChatMessage("[BOT] telega search timeout", 0xFF4444)
                end
            end
            local f, tree = getNearestTree()
            if bot_state == "IDLE" then
                bot_state = "SEARCH_TREE"
            elseif bot_state == "SCAN_FOR_TREE" then
                local f, tree = getNearestTree()
            
                if f then
                    nav_scan_target_angle = nil
                    bot_state = "SEARCH_TREE"
                else
                    if not current_cam_angle then current_cam_angle = 0.0 end
                    if not nav_scan_target_angle then nav_scan_target_angle = current_cam_angle end
                    nav_scan_target_angle = (nav_scan_target_angle + 0.8) % 360
                    local scan_diff = (nav_scan_target_angle - current_cam_angle + 180) % 360 - 180
                    local abs_scan = math.abs(scan_diff)
                    local spd_scan
                    if abs_scan < 20 then
                        spd_scan = cVARS.camera_turn_slow[0]
                    elseif abs_scan < 90 then
                        spd_scan = cVARS.camera_turn_mid[0]
                    else
                        spd_scan = cVARS.camera_turn_fast[0]
                    end
                    local dt_scan = os.clock() - last_cam_time
                    if dt_scan <= 0 or dt_scan > 0.2 then dt_scan = 0.05 end
                    last_cam_time = os.clock()
                    local max_rot_scan = spd_scan * dt_scan
                    local step_scan = scan_diff
                    if math.abs(step_scan) > max_rot_scan then
                        step_scan = max_rot_scan * (step_scan > 0 and 1 or -1)
                    end
                    current_cam_angle = current_cam_angle + step_scan
                    current_cam_angle = (current_cam_angle + 360) % 360
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    local camX = px + math.cos(math.rad(current_cam_angle)) * cVARS.camera_dist[0]
                    local camY = py + math.sin(math.rad(current_cam_angle)) * cVARS.camera_dist[0]
                    local camZ = pz + cVARS.camera_height_offset[0]
                    set_camera_direction({camX, camY, camZ})
                    walking = false
                    setGameKeyState(1, 0)
                    setGameKeyState(16, 0)
                end   
            elseif bot_state == "PICKUP_TELEGA" then
                if not state_entered["PICKUP_TELEGA"] then
                    state_entered["PICKUP_TELEGA"] = true
                    set_wait_alt = os.clock()
                end
                if pickup_telega_pos then
                    if not pickup_telega_skip_check then
                        local telega_still_exists = false
                        for id = 0, 2048 do
                            if sampIs3dTextDefined(id) then
                                local t, c, posX, posY, posZ = sampGet3dTextInfoById(id)
                                if t and t:find("\xc4\xf0\xee\xe2\xe0:") then
                                    local d = getDistanceBetweenCoords3d(posX, posY, posZ,
                                        pickup_telega_pos[1], pickup_telega_pos[2], pickup_telega_pos[3])
                                    if d < 8.0 then
                                        telega_still_exists = true
                                        pickup_telega_pos = {posX, posY, posZ}
                                        break
                                    end
                                end
                            end
                        end
                        if not telega_still_exists then
                            --sampAddChatMessage("[BOT] telega gone (taken by another player), searching tree", 0xFF4444)
                            pickup_telega_pos = nil
                            pickup_telega_skip_check = false
                            state_entered["PICKUP_TELEGA"] = false
                            bot_state = "SEARCH_TREE"
                            goto continue_state
                        end
                    end
                    local dist = distPoint(pickup_telega_pos[1], pickup_telega_pos[2], pickup_telega_pos[3])
                    if dist < 5.0 then
                        local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
                        local tx, ty, tz = pickup_telega_pos[1], pickup_telega_pos[2], pickup_telega_pos[3]
                        local dx, dy = tx - mX, ty - mY
                        local target_angle = math.deg(math.atan2(cam_y and (cam_y - mY) or dy, cam_x and (cam_x - mX) or dx))
                        if dist > 1.0 then
                            walking = true
                            setGameKeyState(1, -255)
                            setGameKeyState(16, 0)
                        else
                            walking = false
                            setGameKeyState(1, 0)
                            setGameKeyState(16, 0)
                        end
                    else
                        navRunToPoint(pickup_telega_pos[1], pickup_telega_pos[2], pickup_telega_pos[3], true)
                    end
                    if dist < 3.0 then
                        local data = samp_create_sync_data('player')
                        data.keysData = data.keysData + 1024
                        data.send()
                    end
                end
                if os.clock() - set_wait_alt > 30 then
                    pickup_telega_pos = nil
                    pickup_telega_skip_check = false
                    state_entered["PICKUP_TELEGA"] = false
                    bot_state = "SEARCH_TREE"
                end
                ::continue_state::
            elseif bot_state == "RUN_SDACHA" then
                if not state_entered["RUN_SDACHA"] then
                    if cVARS.enable_random_pauses[0] then
                        wait(math.random(1000, 1500))
                    end
                    state_entered["RUN_SDACHA"] = true
                end
                if not has_telega then
                    resetNavPath()
                    if next_telega_pos then
                        pickup_telega_pos = next_telega_pos
                        next_telega_pos = nil
                        pickup_telega_skip_check = true
                        state_entered["PICKUP_TELEGA"] = false
                        resetNavPath()
                        bot_state = "PICKUP_TELEGA"
                    else
                        bot_state = "SEARCH_TREE"
                    end
                else
                    if not next_telega_pos and current_tree_points and #current_tree_points > 0 then
                        local pt = current_tree_points[current_tree_point_idx] or current_tree_points[1]
                        if pt then
                            local found, tdx, tdy, tdz = hasDrovaLabelNear(pt[1], pt[2], pt[3], 80)
                            if found then
                                next_telega_pos = {tdx, tdy, tdz}
                            end
                        end
                    end
                    local target_sdacha
                    if cVARS.smart_sdacha[0] then
                        target_sdacha, _ = findNearestSdachaPoint()
                    else
                        local index = cVARS.selected_sdacha_index[0] + 1
                        target_sdacha = sdacha_points[index]
                    end
                    if not target_sdacha then target_sdacha = sdacha_points[1] end
                    navRunToPoint(target_sdacha.x, target_sdacha.y, target_sdacha.z, true)
                    local distance = distPoint(target_sdacha.x, target_sdacha.y, target_sdacha.z)
                    if distance < 1.5 then
                        setGameKeyState(1, 0)
                        setGameKeyState(16, 0)
                        walking = false
                    end
                end
            elseif bot_state == "GO_KYSHAT" then
                navRunToPoint(-552.03942871094, -183.31585693359, 78.419914245605, true)
                local distance = distPoint(-552.03942871094, -183.31585693359, 78.419914245605)
                if distance < 1.5 and active then
                    wait(1000)
                    sendCustomPacket('streetFood.purchase|pizza')
                    wait(1000)
                    sendCustomPacket('streetFood.purchase|hotdog')
                    sendCustomPacket('streetFood.close')
                    active = false
                    bot_state = "RETURN_FROM_FOOD"
                end
            elseif bot_state == "RETURN_FROM_FOOD" then
                navRunToPoint(-518.3679, -185.5178, 78.0082, true)
                local return_distance = distPoint(-518.3679, -185.5178, 78.0082)
                if return_distance < 1.5 then
                    bot_state = "SEARCH_TREE"
                end
            elseif bot_state == "SEARCH_TREE" then
                local f, pts = getNearestTree()
                if f then
                    local center_x, center_y, center_z = pts[1][1], pts[1][2], pts[1][3]
                    local has_drova, dx, dy, dz = hasDrovaLabelNear(center_x, center_y, center_z, 50)
                    
                    if has_drova and not has_telega then
                        pickup_telega_pos = {dx, dy, dz}
                        saved_tree_points = pts
                        saved_tree_point_idx = 1
                        resetNavPath()
                        bot_state = "PICKUP_TELEGA"
                        state_entered["PICKUP_TELEGA"] = false
                    else
                        current_tree_points = pts
                        current_tree_point_idx = 1
                        minigame_running = false
                        local pt = current_tree_points[1]
                        navRunToPoint(pt[1], pt[2], pt[3], true)
                        -- æä¸ì showModal îò ñåðâåðà, showModal ñàì ïåðåêëþ÷èò â PLAY_MINIGAME
                    end
                else
                    bot_state = "SCAN_FOR_TREE"
                end
            elseif bot_state == "PLAY_MINIGAME" then
                if not state_entered["PLAY_MINIGAME"] then
                    state_entered["PLAY_MINIGAME"] = true
                    minigame_running = true
                    minigame_done_time = 0
                    partner_name = nil
                    partner_absent = false
                    waiting_for_my_turn = false
                    my_turn_ready = false
                end
                local minigame_timeout = (partner_name ~= nil) and 60 or 25
                if waiting_for_my_turn then
                    set_wait_alt = os.clock()
                end
                if os.clock() - set_wait_alt > minigame_timeout then
                    local pt = current_tree_points[current_tree_point_idx] or current_tree_points[1]
                    if pt then
                        table.insert(ignore_trees, {pt[1], pt[2], pt[3]})
                    end
                    current_tree_points = {}
                    minigame_running = false
                    minigame_done_time = 0
                    partner_name = nil
                    partner_absent = false
                    waiting_for_my_turn = false
                    my_turn_ready = false
                    bot_state = "SEARCH_TREE"
                    state_entered["PLAY_MINIGAME"] = false
                end
                if not minigame_running and minigame_done_time > 0 then
                    if os.clock() - minigame_done_time >= 3.0 then
                        sendCustomPacket("lumbering-game.exit")
                        minigame_done_time = 0
                        state_entered["PLAY_MINIGAME"] = false
                        waiting_for_my_turn = false
                        my_turn_ready = false
                        if #current_tree_points >= 2 then
                            local next_idx = (current_tree_point_idx == 1) and 2 or 1
                            local next_pt = current_tree_points[next_idx]
                            local any_avail_idx = nil
                            if partner_absent then
                                any_avail_idx = next_idx
                                partner_absent = false
                                --sampAddChatMessage("[BOT] partner was absent, going to other point", 0x00FF00)
                            elseif next_pt and isPointAvailable(next_pt[1], next_pt[2], next_pt[3]) then
                                any_avail_idx = next_idx
                            else
                                for scan_i = 1, #current_tree_points do
                                    local scan_pt = current_tree_points[scan_i]
                                    if scan_pt and scan_i ~= next_idx and isPointAvailable(scan_pt[1], scan_pt[2], scan_pt[3]) then
                                        any_avail_idx = scan_i
                                        break
                                    end
                                end
                            end
                            if any_avail_idx then
                                current_tree_point_idx = any_avail_idx
                                bot_state = "GO_TO_TREE_POINT"
                                state_entered["GO_TO_TREE_POINT"] = false
                                resetNavPath()
                            else
                                current_tree_point_idx = 1
                                local pt = current_tree_points and current_tree_points[1]
                                local found_t, tdx, tdy, tdz = false, nil, nil, nil
                                if pt then
                                    found_t, tdx, tdy, tdz = hasDrovaLabelNear(pt[1], pt[2], pt[3], 80)
                                end
                                if found_t and not has_telega then
                                    pickup_telega_pos = {tdx, tdy, tdz}
                                    pickup_telega_skip_check = false
                                    if current_tree_points and #current_tree_points > 0 then
                                        saved_tree_points = current_tree_points
                                        saved_tree_point_idx = current_tree_point_idx or 1
                                    end
                                    resetNavPath()
                                    bot_state = "PICKUP_TELEGA"
                                    state_entered["PICKUP_TELEGA"] = false
                                else
                                    bot_state = "WAIT_TELEGA"
                                    state_entered["WAIT_TELEGA"] = false
                                end
                            end
                        else
                            current_tree_point_idx = 1
                            local pt = current_tree_points and current_tree_points[1]
                            local found_t, tdx, tdy, tdz = false, nil, nil, nil
                            if pt then
                                found_t, tdx, tdy, tdz = hasDrovaLabelNear(pt[1], pt[2], pt[3], 80)
                            end
                            if found_t and not has_telega then
                                pickup_telega_pos = {tdx, tdy, tdz}
                                pickup_telega_skip_check = false
                                if current_tree_points and #current_tree_points > 0 then
                                    saved_tree_points = current_tree_points
                                    saved_tree_point_idx = current_tree_point_idx or 1
                                end
                                resetNavPath()
                                bot_state = "PICKUP_TELEGA"
                                state_entered["PICKUP_TELEGA"] = false
                            else
                                bot_state = "WAIT_TELEGA"
                                state_entered["WAIT_TELEGA"] = false
                            end
                        end
                    end
                end

            elseif bot_state == "GO_TO_TREE_POINT" then
                if current_tree_points and #current_tree_points > 0 then
                    local found_available = false
                    for try = 1, #current_tree_points do
                        local chk = current_tree_points[current_tree_point_idx]
                        if chk and isPointAvailable(chk[1], chk[2], chk[3]) then
                            found_available = true
                            break
                        end
                        current_tree_point_idx = (current_tree_point_idx % #current_tree_points) + 1
                    end
                    if not found_available then
                        local pt_chk = current_tree_points and current_tree_points[1]
                        local found_t3, tdx3, tdy3, tdz3 = false, nil, nil, nil
                        if pt_chk then found_t3, tdx3, tdy3, tdz3 = hasDrovaLabelNear(pt_chk[1], pt_chk[2], pt_chk[3], 80) end
                        if found_t3 and not has_telega then
                            pickup_telega_pos = {tdx3, tdy3, tdz3}
                            pickup_telega_skip_check = false
                            saved_tree_points = current_tree_points
                            saved_tree_point_idx = current_tree_point_idx or 1
                            resetNavPath()
                            bot_state = "PICKUP_TELEGA"
                            state_entered["PICKUP_TELEGA"] = false
                        else
                            bot_state = "WAIT_TELEGA"
                            state_entered["WAIT_TELEGA"] = false
                        end
                        return
                    end
                else
                    bot_state = "WAIT_TELEGA"
                    state_entered["WAIT_TELEGA"] = false
                    return
                end
                local target_pt = current_tree_points[current_tree_point_idx]
                if not target_pt then
                    bot_state = "WAIT_TELEGA"
                    state_entered["WAIT_TELEGA"] = false
                    return
                end
                if not isPointAvailable(target_pt[1], target_pt[2], target_pt[3]) then
                    local found_t2, tdx2, tdy2, tdz2 = hasDrovaLabelNear(target_pt[1], target_pt[2], target_pt[3], 80)
                    if found_t2 and not has_telega then
                        pickup_telega_pos = {tdx2, tdy2, tdz2}
                        pickup_telega_skip_check = false
                        saved_tree_points = current_tree_points
                        saved_tree_point_idx = current_tree_point_idx or 1
                        resetNavPath()
                        bot_state = "PICKUP_TELEGA"
                        state_entered["PICKUP_TELEGA"] = false
                    else
                        bot_state = "WAIT_TELEGA"
                        state_entered["WAIT_TELEGA"] = false
                    end
                    return
                end
                if not state_entered["GO_TO_TREE_POINT"] then
                    state_entered["GO_TO_TREE_POINT"] = true
                    partner_name = nil
                    partner_absent = false
                    waiting_for_my_turn = false
                    my_turn_ready = false
                    local cx, cy, cz = getTreeCenterFromPoint(target_pt[1], target_pt[2], target_pt[3])
                    local px, py, pz = getCharCoordinates(PLAYER_PED)
                    tree_avoid_circle_points = generateTreeAvoidCircle(cx, cy, pz, tree_circle_radius, 20)
                    local dx = px - cx
                    local dy = py - cy
                    local current_angle = math.deg(math.atan2(dy, dx))
                    if current_angle < 0 then current_angle = current_angle + 360 end
                    local tx = target_pt[1] - cx
                    local ty = target_pt[2] - cy
                    local target_angle = math.deg(math.atan2(ty, tx))
                    if target_angle < 0 then target_angle = target_angle + 360 end
                    local diff = (target_angle - current_angle + 360) % 360
                    tree_circle_direction = (diff <= 180) and 1 or -1
                    local min_dist = math.huge
                    local start_idx = 1
                    for i, pt in ipairs(tree_avoid_circle_points) do
                        local d = getDistanceBetweenCoords2d(px, py, pt[1], pt[2])
                        if d < min_dist then
                            min_dist = d
                            start_idx = i
                        end
                    end
                    tree_avoid_circle_index = start_idx
                end
                local px, py, pz = getCharCoordinates(PLAYER_PED)
                local tx, ty, tz = target_pt[1], target_pt[2], target_pt[3]
                local dist_to_target = getDistanceBetweenCoords3d(px, py, pz, tx, ty, tz)

                if dist_to_target < 4.0 then
                    runToPoint(tx, ty, tz)

                    if dist_to_target < 1.65 then
                        -- æä¸ì showModal îò ñåðâåðà, îí ñàì ïåðåêëþ÷èò â PLAY_MINIGAME
                        tree_avoid_circle_points = {}
                        tree_avoid_circle_index = 1
                    end
                else
                    if tree_avoid_circle_points and #tree_avoid_circle_points > 0 then
                        local circle_pt = tree_avoid_circle_points[tree_avoid_circle_index]
                        runToPoint(circle_pt[1], circle_pt[2], pz + 0.6)
                        local dist_to_circle = getDistanceBetweenCoords2d(px, py, circle_pt[1], circle_pt[2])
                        if dist_to_circle < 2.3 then
                            tree_avoid_circle_index = tree_avoid_circle_index + tree_circle_direction
                            if tree_avoid_circle_index < 1 then
                                tree_avoid_circle_index = #tree_avoid_circle_points
                            elseif tree_avoid_circle_index > #tree_avoid_circle_points then
                                tree_avoid_circle_index = 1
                            end
                        end
                    else
                        runToPoint(tx, ty, tz)
                    end
                end

            elseif bot_state == "WAIT_TELEGA" then
                if not state_entered["WAIT_TELEGA"] then
                    state_entered["WAIT_TELEGA"] = true
                    set_wait_alt = os.clock()
                end
                if current_tree_points and #current_tree_points > 0 then
                    local pt = current_tree_points[current_tree_point_idx] or current_tree_points[1]
                    if pt then
                        local found, tdx, tdy, tdz = hasDrovaLabelNear(pt[1], pt[2], pt[3], 80)
                        if found and not has_telega then
                            pickup_telega_pos = {tdx, tdy, tdz}
                            if current_tree_points and #current_tree_points > 0 then
                                saved_tree_points = current_tree_points
                                saved_tree_point_idx = current_tree_point_idx or 1
                            end
                            resetNavPath()
                            bot_state = "PICKUP_TELEGA"
                            state_entered["PICKUP_TELEGA"] = false
                        end
                    end
                end
                if bot_state == "WAIT_TELEGA" and current_tree_points and #current_tree_points > 0 then
                    local avail_idx = nil
                    for try_i = 1, #current_tree_points do
                        local chk_pt = current_tree_points[try_i]
                        if chk_pt and isPointAvailable(chk_pt[1], chk_pt[2], chk_pt[3]) then
                            avail_idx = try_i
                            break
                        end
                    end
                    if avail_idx then
                        current_tree_point_idx = avail_idx
                        resetNavPath()
                        bot_state = "GO_TO_TREE_POINT"
                        state_entered["GO_TO_TREE_POINT"] = false
                    else
                        local pt = current_tree_points[1]
                        if pt then navRunToPoint(pt[1], pt[2], pt[3], true) end
                    end
                end
                if os.clock() - set_wait_alt > 45 then
                    state_entered["WAIT_TELEGA"] = false
                    current_tree_points = {}
                    bot_state = "SEARCH_TREE"
                end
            elseif bot_state == "ESCAPE_VEHICLE" then
                if not state_entered["ESCAPE_VEHICLE"] then
                    state_entered["ESCAPE_VEHICLE"] = true
                end
                navRunToPoint(safe_point_away.x, safe_point_away.y, safe_point_away.z, true)
                local distance = distPoint(safe_point_away.x, safe_point_away.y, safe_point_away.z)
                if distance < 3.0 then
                    cVARS.bot[0] = false
                    bot_state = "IDLE"
                    if cVARS.telegram[0] then
                        sendTelegramNotification(u8("\xC4\xEE\xF1\xF2\xE8\xE3\xED\xF3\xF2\xE0 \xE1\xE5\xE7\xEE\xEF\xE0\xF1\xED\xE0\xFF \xF2\xEE\xF7\xEA\xE0. \xC1\xEE\xF2 \xE2\xFB\xEA\xEB\xFE\xF7\xE5\xED."))
                    end
                end
            end
        end
    end
end
 
function rainbow(speed, alpha, offset)
    local clock = os.clock() + offset
    local r = math.floor(math.sin(clock * speed) * 127 + 128)
    local g = math.floor(math.sin(clock * speed + 2) * 127 + 128)
    local b = math.floor(math.sin(clock * speed + 4) * 127 + 128)
    return r,g,b,alpha
end
 
function join_argb(a, r, g, b)
    local argb = b
    argb = bit.bor(argb, bit.lshift(g, 8))
    argb = bit.bor(argb, bit.lshift(r, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end
 
function distPoint(x, y, z)
    local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
    local distance = getDistanceBetweenCoords3d(mX, mY, mZ, x, y, z)
    return distance
end

function resetNavPath()
    nav_current_path  = nil
    nav_path_index    = 1
    nav_target_x      = nil
    nav_target_y      = nil
    nav_target_z      = nil
    nav_path_building = false
    nav_full_path     = {}
    nav_full_idx      = 1
    nav_last_built_x  = nil
    nav_segment_size  = 30.0
    nav_detour_angle  = 0.0
    nav_detour_fails  = 0
    walking = false
    setGameKeyState(1, 0)
    setGameKeyState(16, 0)
end

local function getNavLookaheadPoint(path, start_idx, px, py, pz, lookahead_dist)
    local acc = 0
    local prev_x, prev_y, prev_z = px, py, pz
    for i = start_idx, #path do
        local pt = path[i]
        local d = getDistanceBetweenCoords3d(prev_x, prev_y, prev_z, pt[1], pt[2], pt[3])
        acc = acc + d
        if acc >= lookahead_dist then
            return pt[1], pt[2], pt[3]
        end
        prev_x, prev_y, prev_z = pt[1], pt[2], pt[3]
    end
    local last = path[#path]
    return last[1], last[2], last[3]
end

-- Çàïðåù¸ííûå çîíû (êâàäðàòû, âíóòðü êîòîðûõ áîò íå çàõîäèò)
local FORBIDDEN_ZONES = {
    {   -- Çîíà 1
        minX = -562.574, maxX = -559.206,
        minY = -206.480, maxY = -193.727,
        minZ =   77.0,   maxZ =   80.0,
    },
    {   -- Çîíà 2
        minX = -502.202, maxX = -499.574,
        minY = -206.164, maxY = -194.868,
        minZ =   77.0,   maxZ =   80.0,
    },
}

local function isForbiddenZone(x, y, z)
    for _, zone in ipairs(FORBIDDEN_ZONES) do
        if x >= zone.minX and x <= zone.maxX
        and y >= zone.minY and y <= zone.maxY
        and z >= zone.minZ and z <= zone.maxZ then
            return true
        end
    end
    return false
end

function navRunToPoint(x, y, z, use_mesh)
    if not use_mesh or not nav then
        runToPoint(x, y, z)
        return
    end
    local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
    local dist_to_goal = getDistanceBetweenCoords3d(mX, mY, mZ, x, y, z)
    if dist_to_goal < 4.0 then
        nav_current_path  = nil
        nav_path_building = false
        nav_full_path     = {}
        nav_full_idx      = 1
        nav_last_built_x  = nil
        runToPoint(x, y, z)
        return
    end
    local target_changed = (nav_target_x == nil) or
        getDistanceBetweenCoords3d(nav_target_x, nav_target_y, nav_target_z, x, y, z) > 2.0
    if target_changed then
        nav_target_x, nav_target_y, nav_target_z = x, y, z
        nav_current_path  = nil
        nav_path_index    = 1
        nav_path_building = false
        nav_full_path     = {}
        nav_full_idx      = 1
        nav_last_built_x  = nil
    end
    local function try_extend_path()
        if nav_path_building then return end
        local bx, by, bz
        if nav_full_path and #nav_full_path > 0 then
            local last = nav_full_path[#nav_full_path]
            bx, by, bz = last[1], last[2], last[3]
        else
            bx, by, bz = mX, mY, mZ
        end
        local d_to_goal = getDistanceBetweenCoords3d(bx, by, bz, x, y, z)
        if d_to_goal < 3.0 then return end
        local dx = x - bx
        local dy = y - by
        local dz = z - bz
        local len = math.sqrt(dx*dx + dy*dy + dz*dz)
        local seg = math.min(nav_segment_size, len)
        local detour_seg = seg
        if nav_detour_fails > 0 then
            detour_seg = math.max(8.0, seg * math.max(0.3, 1.0 - nav_detour_fails * 0.12))
        end
        local tx, ty, tz
        if nav_detour_fails > 0 and nav_detour_angle ~= 0.0 then
            local base_angle = math.atan2(dy, dx)
            local jitter = (math.random() - 0.5) * math.rad(10)
            local offset_rad = math.rad(nav_detour_angle) + jitter
            tx = bx + math.cos(base_angle + offset_rad) * detour_seg
            ty = by + math.sin(base_angle + offset_rad) * detour_seg
            tz = bz + dz/len * detour_seg
        else
            tx = bx + dx/len * seg
            ty = by + dy/len * seg
            tz = bz + dz/len * seg
        end
        nav_path_building = true
        local startX, startY, startZ = bx, by, bz
        lua_thread.create(function()
            local ok, path = pcall(function()
                return nav:generate_path_hybrid(startX, startY, startZ, tx, ty, tz)
            end)
            if not ok then
                nav_path_building = false
                nav_segment_size = math.max(10.0, nav_segment_size * 0.6)
                nav_detour_fails = nav_detour_fails + 1
                local sign = (nav_detour_fails % 2 == 0) and 1 or -1
                nav_detour_angle = sign * nav_detour_step * math.ceil(nav_detour_fails / 2)
                if math.abs(nav_detour_angle) > 150 then
                    nav_detour_angle = 0.0
                    nav_detour_fails = 0
                end
                if cVARS.debug[0] then
                    cMsg(string.format("[NAV] FAILED pcall (%.1f,%.1f)->(%.1f,%.1f) seg=%.1f detour=%.0f°", startX, startY, tx, ty, nav_segment_size, nav_detour_angle), 0xFF4444)
                end
                return
            end
            if path and #path > 0 then
                local MIN_STEP = 2.5
                local clean = {path[1]}
                for i = 2, #path - 1 do
                    local prev = clean[#clean]
                    local pt   = path[i]
                    if getDistanceBetweenCoords3d(prev[1],prev[2],prev[3], pt[1],pt[2],pt[3]) >= MIN_STEP
                    and not isForbiddenZone(pt[1], pt[2], pt[3]) then
                        clean[#clean+1] = pt
                    end
                end
                if #path > 1 then
                    local last = path[#path]
                    if not isForbiddenZone(last[1], last[2], last[3]) then
                        clean[#clean+1] = last
                    end
                end
                local MAX_PTS = 6
                local added = 0
                local px2, py2, pz2 = getCharCoordinates(PLAYER_PED)
                -- skip points already behind the bot
                local skip_until = 1
                if #nav_full_path > 0 then
                    local tail = nav_full_path[#nav_full_path]
                    for i = 1, #clean do
                        local d_bot  = getDistanceBetweenCoords3d(px2, py2, pz2, clean[i][1], clean[i][2], clean[i][3])
                        local d_tail = getDistanceBetweenCoords3d(tail[1], tail[2], tail[3], clean[i][1], clean[i][2], clean[i][3])
                        if d_bot < 3.0 or d_tail < 2.0 then
                            skip_until = i + 1
                        else
                            break
                        end
                    end
                end
                for i = skip_until, #clean do
                    if added >= MAX_PTS then break end
                    nav_full_path[#nav_full_path+1] = clean[i]
                    added = added + 1
                end
                if not nav_current_path and #nav_full_path > 0 then
                    nav_current_path = nav_full_path
                    nav_path_index   = nav_full_idx
                end
                nav_segment_size = math.min(30.0, nav_segment_size * 1.2 + 2.0)
                nav_detour_fails = 0
                nav_detour_angle = 0.0
            else
                nav_detour_fails = nav_detour_fails + 1
                local sign = (nav_detour_fails % 2 == 0) and 1 or -1
                nav_detour_angle = sign * nav_detour_step * math.ceil(nav_detour_fails / 2)
                if math.abs(nav_detour_angle) > 150 then
                    nav_detour_angle = 0.0
                    nav_detour_fails = 0
                end
                if cVARS.debug[0] then
                    cMsg(string.format("[NAV] STUCK (%.1f,%.1f)->(%.1f,%.1f) seg=%.1f goal=(%.1f,%.1f) next_detour=%.0f°",
                        startX, startY, tx, ty, nav_segment_size, x, y, nav_detour_angle), 0xFFAA00)
                end
            end
            nav_path_building = false
        end)
    end
    if not nav_current_path then
        try_extend_path()
        runToPoint(x, y, z)
        return
    end
    local mX2, mY2, mZ2 = getCharCoordinates(PLAYER_PED)
    local path = nav_current_path
    local n    = #path
    while nav_path_index < n do
        local pt      = path[nav_path_index]
        local pt_next = path[nav_path_index + 1]
        local d_cur  = getDistanceBetweenCoords3d(mX2, mY2, mZ2, pt[1],      pt[2],      pt[3])
        local d_next = getDistanceBetweenCoords3d(mX2, mY2, mZ2, pt_next[1], pt_next[2], pt_next[3])
        if (d_cur < 2.5 and d_next < d_cur) or d_cur < 1.5 then
            nav_path_index = nav_path_index + 1
            nav_full_idx   = nav_path_index
        else
            break
        end
    end
    if n > 0 then
        local last = path[n]
        local d_to_last = getDistanceBetweenCoords3d(mX2, mY2, mZ2, last[1], last[2], last[3])
        local d_last_to_goal = getDistanceBetweenCoords3d(last[1], last[2], last[3], x, y, z)
        if d_to_last < nav_extend_dist and d_last_to_goal > 3.0 then
            try_extend_path()
        end
    end
    if nav_path_index > n then
        nav_current_path  = nil
        nav_path_building = false
        nav_full_path     = {}
        nav_full_idx      = 1
        runToPoint(x, y, z)
        return
    end
    if nav_path_index == n then
        local pt = path[n]
        local d  = getDistanceBetweenCoords3d(mX2, mY2, mZ2, pt[1], pt[2], pt[3])
        if d < 2.0 then
            local d_to_goal2 = getDistanceBetweenCoords3d(mX2, mY2, mZ2, x, y, z)
            if d_to_goal2 < 4.0 then
                nav_current_path  = nil
                nav_path_building = false
                nav_full_path     = {}
                nav_full_idx      = 1
            end
            runToPoint(x, y, z)
            return
        end
    end
    local pt_cam = path[nav_path_index]
    if not current_cam_angle then current_cam_angle = 0.0 end
    local dx_cam = pt_cam[1] - mX2
    local dy_cam = pt_cam[2] - mY2
    local target_angle = math.deg(math.atan2(dy_cam, dx_cam))
    local angle_diff = (target_angle - current_cam_angle + 180) % 360 - 180
    local abs_diff_nav = math.abs(angle_diff)
    local cam_speed_dps_nav
    if abs_diff_nav < 20 then
        cam_speed_dps_nav = cVARS.camera_turn_slow[0]
    elseif abs_diff_nav < 90 then
        cam_speed_dps_nav = cVARS.camera_turn_mid[0]
    else
        cam_speed_dps_nav = cVARS.camera_turn_fast[0]
    end
    local dt_nav = os.clock() - last_cam_time
    if dt_nav <= 0 or dt_nav > 0.2 then dt_nav = 0.05 end
    last_cam_time = os.clock()
    local max_rot_nav = cam_speed_dps_nav * dt_nav
    local step_nav = angle_diff
    if math.abs(step_nav) > max_rot_nav then
        step_nav = max_rot_nav * (step_nav > 0 and 1 or -1)
    end
    current_cam_angle = current_cam_angle + step_nav
    current_cam_angle = (current_cam_angle + 360) % 360
    local cam_dist = cVARS.camera_dist[0]
    local camX = mX2 + math.cos(math.rad(current_cam_angle)) * cam_dist
    local camY = mY2 + math.sin(math.rad(current_cam_angle)) * cam_dist
    local camZ = mZ2 + cVARS.camera_height_offset[0]
    set_camera_direction({camX, camY, camZ})
    runToPoint(pt_cam[1], pt_cam[2], pt_cam[3])
end

function runToPoint(x, y, z, cam_x, cam_y, cam_z)
    local now = os.clock()
    local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
    if now - last_check_time >= CHECK_INTERVAL then
        local moved = getDistanceBetweenCoords3d(mX, mY, mZ, last_pos_x, last_pos_y, last_pos_z)
        if moved < MIN_MOVE_DIST then
            stuck_ticks = stuck_ticks + 1
        else
            stuck_ticks = 0
        end
        last_pos_x, last_pos_y, last_pos_z = mX, mY, mZ
        last_check_time = now
        if cVARS.check_stuck[0] then
            if stuck_ticks >= STUCK_THRESHOLD and now - last_stuck_action_time >= STUCK_ACTION_COOLDOWN then
                cMsg(string.format("\xC7\xE0\xF1\xF2\xF0\xE5\xE2\xE0\xED\xE8\xE5! (%.2f \xEC \xE7\xE0 %.1f\xF1)"), moved, CHECK_INTERVAL)
                setGameKeyState(14, 255)
                setGameKeyState(0, math.random() > 0.5 and 220 or -220)
                wait(180)
                setGameKeyState(14, 0)
                setGameKeyState(0, 0)
                sendTelegramNotification(u8("\xC1\xEE\xF2 \xF0\xE0\xF1\xF2\xF0\xFF\xEB \xEF\xEE\xEC\xEE\xE5\xEC\xF3"))
                last_stuck_action_time = now
                stuck_ticks = stuck_ticks - 2
            end
        end
    end
    if not current_cam_angle then current_cam_angle = 0.0 end
    if not turn_state then
        turn_state = { dir=0, intensity=0.0, untilTime=0.0, lastChange=0.0 }
    end
    if not last_jump then last_jump = 0 end
    local dx, dy = x - mX, y - mY
    local distance = getDistanceBetweenCoords3d(mX, mY, mZ, x, y, z)
    local target_angle = math.deg(math.atan2(cam_y and (cam_y - mY) or dy, cam_x and (cam_x - mX) or dx))
    local angle_diff = (target_angle - current_cam_angle + 180) % 360 - 180
    local legacy_smooth
    if distance < 8 then
        legacy_smooth = cVARS.camera_smooth_close[0]
    elseif distance < 25 then
        legacy_smooth = cVARS.camera_smooth_mid[0]
    else
        legacy_smooth = cVARS.camera_smooth_far[0]
    end
    local abs_diff = math.abs(angle_diff)
    local cam_speed_dps
    if abs_diff < 20 then
        cam_speed_dps = cVARS.camera_turn_slow[0]
    elseif abs_diff < 90 then
        cam_speed_dps = cVARS.camera_turn_mid[0]
    else
        cam_speed_dps = cVARS.camera_turn_fast[0]
    end
    local dt = now - last_cam_time
    if dt <= 0 or dt > 0.2 then dt = 0.05 end
    last_cam_time = now
    local max_rot = cam_speed_dps * dt
    local step = angle_diff
    if math.abs(step) > max_rot then
        step = max_rot * (step > 0 and 1 or -1)
    end
    if bot_state == "GO_TO_TREE_POINT" then
        current_cam_angle = current_cam_angle + angle_diff * legacy_smooth
    else
        current_cam_angle = current_cam_angle + step
    end
    current_cam_angle = (current_cam_angle + 360) % 360
    local cam_dist = cVARS.camera_dist[0]
    local camX = mX + math.cos(math.rad(current_cam_angle)) * cam_dist
    local camY = mY + math.sin(math.rad(current_cam_angle)) * cam_dist
    local camZ = mZ + cVARS.camera_height_offset[0]
    set_camera_direction({camX, camY, camZ})
    walking = true
    setGameKeyState(1, -255)
    local now = os.clock()
    local final_dist = distance
    if nav_target_x then
        local mX2, mY2, mZ2 = getCharCoordinates(PLAYER_PED)
        final_dist = getDistanceBetweenCoords3d(mX2, mY2, mZ2, nav_target_x, nav_target_y, nav_target_z)
    end
    local near_tree   = (bot_state == "SEARCH_TREE" or bot_state == "PLAY_MINIGAME") and final_dist < 8
    local near_sdacha = (bot_state == "RUN_SDACHA")  and final_dist < 8
    local near_telega = (bot_state == "PICKUP_TELEGA") and final_dist < 5
    local should_walk = near_tree or near_sdacha or near_telega
    if cVARS.enable_jump[0] and (bot_state == "SEARCH_TREE" or bot_state == "GO_TO_TREE_POINT") and distance > 15 and now - last_jump > 1 then
        setGameKeyState(14, 255)
        setGameKeyState(16, 0)
        last_jump = now
    else
        setGameKeyState(14, 0)
        if should_walk then
            setGameKeyState(16, 0)
        else
            setGameKeyState(16, 255)
        end
    end
    local on_navmesh_path = nav_current_path ~= nil
    if not on_navmesh_path and now > turn_state.untilTime and cVARS.enable_random_turns[0] and now - turn_state.lastChange > 0.6 then
        local r = math.random()
        if r > 0.997 then
            turn_state.dir = 1
            turn_state.untilTime = now + (0.15 + math.random() * 0.5)
            turn_state.lastChange = now
        elseif r < 0.003 then
            turn_state.dir = -1
            turn_state.untilTime = now + (0.15 + math.random() * 0.5)
            turn_state.lastChange = now
        else
            turn_state.dir = 0
        end
    elseif on_navmesh_path then
        turn_state.dir = 0
        turn_state.intensity = turn_state.intensity * 0.85
    end
    local desired = 0
    if turn_state.dir == 1 then desired = 200
    elseif turn_state.dir == -1 then desired = -200
    end
    local inertia = 0.15
    turn_state.intensity = turn_state.intensity + (desired - turn_state.intensity) * inertia
    if distance < 2.0 then
        turn_state.intensity = turn_state.intensity * 0.25
    end
    local finalTurn = math.floor(turn_state.intensity)
    if isBuildingInFront() then
        finalTurn = -255
    end
    if nav_current_path then
        setGameKeyState(0, 0)
    else
        setGameKeyState(0, finalTurn)
    end
end
 
function isBuildingInFront()
    if bot_state == "ESCAPE_VEHICLE" then
        return false
    end
    local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
    local ped_angle = math.rad(getCharHeading(PLAYER_PED)) + math.pi / 2
    local ppX, ppY, ppZ = 5 * math.cos(ped_angle) + pX, 5 * math.sin(ped_angle) + pY, pZ + 0.8
    local result, colPoint = processLineOfSight(
        pX, pY, pZ,
        ppX, ppY, ppZ,
        true, true, true, false, false, false, false, false
    )
    if not result then
        return false
    end
    local entityType = colPoint.entityType
    if entityType == 1 then
        return true
    end
    if entityType == 2 then
        if cVARS.anti_vehicle[0] then
            if bot_state == "RUN_SDACHA" then
                bot_state = "ESCAPE_VEHICLE"
                state_entered["ESCAPE_VEHICLE"] = false
            end
        end
        return true
    end
    return false
end
 
function isTreeInFov(treeX, treeY)
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    if not current_cam_angle then current_cam_angle = 0.0 end
    local dx, dy = treeX - px, treeY - py
    local distance = math.sqrt(dx*dx + dy*dy)
    local angleToTree = math.deg(math.atan2(dy, dx))
    local diff = (angleToTree - current_cam_angle + 180) % 360 - 180
    local fov
    if distance < 2.5 then
        fov = 160
    elseif distance < 6 then
        fov = 120
    elseif distance < 12 then
        fov = 90
    else
        fov = 70
    end
    return math.abs(diff) <= (fov * 0.5)
end

function isTreeLabel(text)
    return text and text:find(u8("\xC4\xE5\xF0\xE5\xE2\xEE")) and (text:find(u8("\xC4\xEE\xF1\xF2\xF3\xEF\xED\xEE")) or text:find(u8("\xED\xE0\xE4\xF0\xF3\xE1\xEB\xE5\xED\xEE")))
end

function isPointAvailable(x, y, z)
    local CHECK_RADIUS = 4.0
    for id = 0, 2048 do
        if sampIs3dTextDefined(id) then
            local text, color, posX, posY, posZ = sampGet3dTextInfoById(id)
            if text and text:find(u8("\xC4\xE5\xF0\xE5\xE2\xEE")) then
                local dist = getDistanceBetweenCoords3d(posX, posY, posZ, x, y, z)
                if dist < CHECK_RADIUS then
                    if text:find(u8("\xC4\xEE\xF1\xF2\xF3\xEF\xED\xEE")) then
                        return true
                    else
                        return false
                    end
                end
            end
        end
    end
    return false
end

function hasDrovaLabelNear(x, y, z, radius)
    radius = radius or 50
    for id = 0, 2048 do
        if sampIs3dTextDefined(id) then
            local text, color, posX, posY, posZ = sampGet3dTextInfoById(id)
            if text and text:find(u8("\xC4\xF0\xEE\xE2\xE0:")) then
                local dist = getDistanceBetweenCoords3d(posX, posY, posZ, x, y, z)
                if dist < radius then
                    return true, posX, posY, posZ
                end
            end
        end
    end
    return false
end

function isPointOccupiedByPlayer(point, radius)
    radius = radius or 3
    for _, player in ipairs(getAllChars()) do
        if select(1, sampGetPlayerIdByCharHandle(player)) and player ~= PLAYER_PED then
            local plX, plY, plZ = getCharCoordinates(player)
            local dist = getDistanceBetweenCoords3d(plX, plY, plZ, point[1], point[2], point[3])
            if dist < radius then return true end
        end
    end
    return false
end

function treeHasBothPointsOccupied(group)
    local occupied = 0
    for _, pt in ipairs(group) do
        if isPointOccupiedByPlayer({pt.x, pt.y, pt.z}, 3) then
            occupied = occupied + 1
        end
    end
    return occupied >= #group
end

function getNearestTree()
    if not isSampfuncsLoaded() or not isSampLoaded() or not isSampAvailable() then
        return false, {}
    end
    local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
    local all_points = {}
    for id = 0, 2048 do
        if sampIs3dTextDefined(id) then
            local text, color, posX, posY, posZ = sampGet3dTextInfoById(id)
            if isTreeLabel(text) then
                local distance = getDistanceBetweenCoords3d(posX, posY, posZ, mX, mY, mZ)
                if not coordsIn({posX, posY, posZ}, ignore_trees) then
                    table.insert(all_points, {x=posX, y=posY, z=posZ, dist=distance, label=text})
                end
            end
        end
    end
    if #all_points == 0 then return false, {} end
    local trees = {}
    local used = {}
    for i = 1, #all_points do
        if not used[i] then
            local group = {all_points[i]}
            used[i] = true
            for j = i+1, #all_points do
                if not used[j] then
                    local d = getDistanceBetweenCoords2d(
                        all_points[i].x, all_points[i].y,
                        all_points[j].x, all_points[j].y)
                    if d < 15.0 then
                        table.insert(group, all_points[j])
                        used[j] = true
                    end
                end
            end
            if not treeHasBothPointsOccupied(group) then
                local min_d = math.huge
                for _, pt in ipairs(group) do
                    if pt.dist < min_d then min_d = pt.dist end
                end
                table.insert(trees, {points=group, dist=min_d})
            end
        end
    end
    if #trees == 0 then return false, {} end
    table.sort(trees, function(a,b) return a.dist < b.dist end)
    local nearest = trees[1]
    table.sort(nearest.points, function(a,b) return a.dist < b.dist end)
    local pts = {}
    for _, p in ipairs(nearest.points) do
        if not isPointOccupiedByPlayer({p.x, p.y, p.z}, 3) and p.label and p.label:find("\xc4\xee\xf1\xf2\xf3\xef\xed\xee") then
            table.insert(pts, {p.x, p.y, p.z})
        end
    end
    for _, p in ipairs(nearest.points) do
        if not isPointOccupiedByPlayer({p.x, p.y, p.z}, 3) and p.label and not p.label:find("\xc4\xee\xf1\xf2\xf3\xef\xed\xee") then
            table.insert(pts, {p.x, p.y, p.z})
        end
    end
    for _, p in ipairs(nearest.points) do
        if isPointOccupiedByPlayer({p.x, p.y, p.z}, 3) then
            table.insert(pts, {p.x, p.y, p.z})
        end
    end
    if #pts == 0 then return false, {} end

    return true, pts
end

function coordsIn(el, _table)
    for _, v in pairs(_table) do
        local dist = getDistanceBetweenCoords2d(el[1], el[2], v[1], v[2])
        if dist < 1 then
            return true
        end
    end
    return false
end

function noPlayersAround(point, radius)
    local radius = radius or 3
    for _, player in ipairs(getAllChars()) do
        if select(1, sampGetPlayerIdByCharHandle(player)) and player ~= PLAYER_PED then
            local plX, plY, plZ = getCharCoordinates(player)
            local dist = getDistanceBetweenCoords3d(plX, plY, plZ, point[1], point[2], point[3])
            if dist < radius then return false end
        end
    end
    return true
end
 
function set_camera_direction(point) -- óêðàë îòêóäà-òî
    local c_pos_x, c_pos_y, c_pos_z = getActiveCameraCoordinates()
    local vect = {x = point[1] - c_pos_x, y = point[2] - c_pos_y}
    local ax = math.atan2(vect.y, -vect.x)
    setCameraPositionUnfixed(0.0, -ax)
end
 
--ñàìï èâåíòñ
function samp.onApplyPlayerAnimation(player_id, anim_lib, anim_name, loop, lock_x, lock_y, freeze, time) -- ìá ïîíàäîáèòñÿ, ïîòîì ïîñìòðþ
end
 
function samp.onSetPlayerAttachedObject(playerId, index, create, object)
    local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if playerId == my_id then
        local isTelega = (object.modelId == 12199 or object.modelId == 12203)
        if isTelega and create then
            has_telega = true
            pickup_telega_skip_check = false
            local target_sdacha_point
            if cVARS.smart_sdacha[0] then
                target_sdacha_point, _ = findNearestSdachaPoint()
            else
                local idx = cVARS.selected_sdacha_index[0] + 1
                target_sdacha_point = sdacha_points[idx]
            end
            if not target_sdacha_point then
                target_sdacha_point = sdacha_points[1]
            end
            resetNavPath()
            bot_state = "RUN_SDACHA"
            state_entered["RUN_SDACHA"] = false
        end
        if isTelega and not create then
            has_telega = false
            if next_telega_pos then
                pickup_telega_pos = next_telega_pos
                next_telega_pos = nil
                pickup_telega_skip_check = true
                resetNavPath()
                state_entered["PICKUP_TELEGA"] = false
                bot_state = "PICKUP_TELEGA"
            end
        end
    end
end
 
otvet = false
local answerWords = {u8("\xE2\xFB \xF2\xF3\xF2?"),u8("\xC2\xFB \xF2\xF3\xF2?")}
local otvet_1 = {
    u8("/b \xF2\xF3\xF2\xE0 \xFF \xF2\xF3\xF2\xE0"),
    u8("/b \xF8\xEE \xF2\xE5?"),
    u8("/b \xE4\xE0?"),
    u8("/b \xF3\xE6\xE5 5 \xF0\xE0\xE7 \xF7\xE5\xEA\xE0\xFE\xF2"),
    u8("/b \xED\xE5 \xE1\xEE\xF2 \xFF"),
    u8("/b \xF2\xE0 \xF2\xF3\xF2 \xFF"),
    u8("/b \xF3 \xFD\xEA\xF0\xE0\xED\xE0 \xFF"),
    u8("/b \xF5\xE4, \xF2\xF3\xF2 \xFF"),
    "/b +++",
    u8("/b \xED\xE0 \xEC\xE5\xF1\xF2\xE5"),
    u8("/b \xE4\xE0"),
    u8("/b \xEE\xEF\xFF\xF2\xFC \xF7\xE5\xEA\xE0\xFE\xF2("),
    u8("/b \xEF\xF0,\xF2\xF3\xF2 \xFF"),
    u8("/b \xED\xEE\xF0\xEC \xE2\xF1\xE5, \xFF \xF2\xF3\xF2"),
    u8("/b \xED\xE5 \xE1\xEE\xE8\xF1\xFC , \xF2\xF3\xF2"),
    u8("/b \xF3 \xE0\xEF\xEF\xE0\xF0\xE0\xF2\xE0"),
    u8("/b \xF2\xF3\xF2"),
    "/b tyt",
    u8("/b \xEA\xED\xF8"),
    u8("/b \xE5\xF1\xF2\xE5\xF1\xF2\xE2\xE5\xED\xED\xEE"),
    u8("/b \xE0 \xE3\xE4\xE5 \xE5\xF9\xB8?"),
    u8("/b \xFF \xF2\xF3\xF2, \xE0\xE2\xFB?"),
    u8("/b \xED\xF3 \xF2\xF3\xF2\xE0"),
    u8("/b \xF2\xF3\xF3\xF3\xF3\xF2"),
    "/b daaaa",
    "/b na meste",
    "/b ya tyt",
    u8("/b \xE0 \xE3\xE4\xE5 \xFF \xEC\xEE\xE3\xF3 \xE1\xFB\xF2\xFC"),
    u8("/b \xE4\xE0 \xE1\xEB\xFF, \xF2\xF3\xF2 \xFF"),
    u8("/b \xEA\xF2\xEE \xEE\xEF\xFF\xF2\xFC \xF0\xE5\xEF \xEA\xE8\xED\xF3\xEB"),
    u8("/b \xF2\xF3\xF3\xF3\xF3\xF3\xF3\xF2"),
    u8("/b \xFF\xFF\xFF\xFF\xFF \xF2\xF3\xF3\xF3\xF3\xF3\xF3\xF2"),
    u8("/b \xF7\xB8 \xEE\xEF\xFF\xF2\xFC? \xE2\xE0\xF9\xE5 \xFF \xF2\xF3\xF2"),
    u8("/b \xEA\xED\xF8 \xF2\xF3\xF2"),
    u8("/b \xEA\xED\xF8 \xFF \xF2\xF3\xF3\xF3\xF3\xF2"),
    u8("/b \xEB\xEE\xEB, \xF2\xF3\xF2\xE0 \xFF"),
    u8("/b \xF3\xE6\xE5 3 \xF7\xE5\xEA\xE0\xE5\xF8, \xF2\xF3\xF2"),
    u8("/b  \xFD\xF5, \xFF \xF2\xF3\xF2"),
    u8("/b \xE4\xE0 \xF3 \xEC\xE5\xED\xFF \xF2\xE0\xEA \xE0\xF0\xE5\xED\xE4\xE0 \xEA\xEE\xED\xF7\xE8\xF2\xFC\xF1\xFF, \xFF \xF2\xF3\xF2"),
    u8("/b \xE8 \xF2\xE0\xEA 15 \xF4\xEF\xF1, \xE5\xF9\xB8 \xE2\xFB, \xFF \xF2\xF3\xF2"),
    "/b da tyt",
    "/b na meste ya",
    "/b im tyta",
    u8("/b \xF2\xEE\xEA \xEB\xE8\xE2\xED\xF3\xF2\xFC \xF5\xEE\xF2\xE5\xEB"),
    u8("/b \xF2\xF3\xF2 \xFF, \xFF \xED\xE0\xF0\xE0\xE1\xEE\xF2\xE0\xEB\xE0\xF1\xFF \xE1\xE1"),
    u8("/b \xEE\xE4\xE0, \xFF\xF2\xF3\xF2 \xE5\xF1 \xF7\xE5"),
    u8("/b \xFD\xF2\xEE \xF1\xE0\xEC\xEE\xE5, \xFF \xF2\xF3\xF2"),
    u8("/b \xF7\xE5 \xEA\xE0\xEA \xF7\xE0\xF1\xF2\xEE \xF7\xE5\xEA\xE0\xFE\xF2, \xFF\xF2\xF3\xF2"),
    u8("/b \xED\xF3 \xF2\xF3\xF2 \xFF"),
        u8("\xF7\xE5 \xF2\xE5, \xFF \xF0\xE0\xE1\xEE\xF2\xE0\xFE \xED\xE5 \xEC\xE5\xF8\xE0\xE9"),
    u8("\xF2\xF3\xF2 \xFF, \xED\xE5 \xEC\xE5\xF8\xE0\xE9\xF1\xFF"),
    u8("\xE4\xE0 \xF2\xF3\xF2"),
    u8("\xF2\xF3\xF2, \xE0 \xF7\xEE?"),
    "xd, tyt",
    u8("\xE4\xE0"),
    "da tyt"
    }
 
samp.onServerMessage = function(color, text)
    if text:find(u8("\xE3\xEE\xE2\xEE\xF0\xE8\xF2")) then
        if cVARS.warningseytg[0] then
            sendTelegramNotification(u8("\xCF\xEE\xE4\xEE\xE7\xF0\xE5\xED\xE8\xE5 \xED\xE0 \xEE\xE1\xF9\xE5\xED\xE8\xE5: ") .. text)
        elseif cVARS.antiadmin_warningsey[0] then
            warn2 = true
        end
    end
    if piska then
        readMemory(0, 1)
    end
    if text:find(u8("\xC7\xE0\xE1\xE5\xF0\xE8\xF2\xE5 \xF2\xE5\xEB\xE5\xE6\xEA\xF3 \xF1 \xE4\xF0\xEE\xE2\xE0\xEC\xE8 \xF0\xFF\xE4\xEE\xEC \xF1 \xE4\xE5\xF0\xE5\xE2\xEE\xEC!")) then
        local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
        local found = false
        for id = 0, 2048 do
            if sampIs3dTextDefined(id) then
                local t, c, posX, posY, posZ = sampGet3dTextInfoById(id)
                if t and t:find(u8("\xC4\xF0\xEE\xE2\xE0:")) then
                    local dist = getDistanceBetweenCoords3d(posX, posY, posZ, mX, mY, mZ)
                    if dist < 80 then
                        if has_telega then
                            next_telega_pos = {posX, posY, posZ}
                            --sampAddChatMessage("[BOT] solo cut: 2nd telega saved (no check)", 0xFFAA00)
                        else
                            pickup_telega_pos = {posX, posY, posZ}
                            pickup_telega_skip_check = false
                            if current_tree_points and #current_tree_points > 0 then
                                saved_tree_points = current_tree_points
                                saved_tree_point_idx = current_tree_point_idx or 1
                            end
                            resetNavPath()
                            bot_state = "PICKUP_TELEGA"
                            state_entered["PICKUP_TELEGA"] = false
                        end
                        found = true
                        break
                    end
                end
            end
        end
        if not found then
            if current_tree_points and #current_tree_points > 0 then
                saved_tree_points = current_tree_points
                saved_tree_point_idx = current_tree_point_idx or 1
            end
            need_find_telega = true
            need_find_telega_time = os.clock()
            --sampAddChatMessage("[BOT] telega label not found yet, searching...", 0xFFAA00)
        end
    end
    if cVARS.antiadmin_autoOff[0] and cVARS.bot[0] then
        if text:find(u8("\xF2\xE5\xEB\xE5\xEF\xEE\xF0\xF2\xE8\xF0\xEE\xE2\xE0\xEB")) and not text:find(u8("\xE3\xEE\xE2\xEE\xF0\xE8\xF2")) then
            cVARS.bot[0] = false
            bot_state = "IDLE"
            cMsg("{DDECFF}\xC1\xEE\xF2\xE8\xEA \xE4\xF0\xE5\xE2\xF1\xE8\xF1\xE8\xED\xFB {FF0000}\xE7\xE0\xE2\xE5\xF0\xF8\xE8\xEB \xF0\xE0\xE1\xEE\xF2\xF3")
            if cVARS.antiadmin_play_sound[0] then
                playAlertSound()
            end
        end
    end
    local isAdminMessage =
        text:find(u8("\xE0\xE4\xEC\xE8\xED\xE8\xF1\xF2\xF0\xE0\xF2\xEE\xF0")) or
        text:find(u8("\xC0\xE4\xEC\xE8\xED\xE8\xF1\xF2\xF0\xE0\xF2\xEE\xF0")) or
        text:find(u8("\xEE\xF2\xE2\xE5\xF2\xE8\xEB \xE2\xE0\xEC")) or
        text:find(u8("\xC0\xE4\xEC\xE8\xED\xE8\xF1\xF2\xF0\xE0\xF2\xEE\xF0 (.+) \xEE\xF2\xE2\xE5\xF2\xE8\xEB \xE2\xE0\xEC%:")) or
        text:find(u8("%(%( \xC0\xE4\xEC\xE8\xED\xE8\xF1\xF2\xF0\xE0\xF2\xEE\xF0 (.+)%[%d+%]%:")) or
        text:find(u8("%(%( \xE0\xE4\xEC\xE8\xED\xE8\xF1\xF2\xF0\xE0\xF2\xEE\xF0 .+%[(%d+)%]%:"))
    if color ~= -2686721 and isAdminMessage then
        if cVARS.antiadmin_autoOff[0] and cVARS.bot[0] then
            cVARS.bot[0] = false
            bot_state = "IDLE"
            cMsg("{DDECFF}\xC1\xEE\xF2\xE8\xEA \xE4\xF0\xE5\xE2\xF1\xE8\xF1\xE8\xED\xFB {FF0000}\xE7\xE0\xE2\xE5\xF0\xF8\xE8\xEB \xF0\xE0\xE1\xEE\xF2\xF3")
        end
        if cVARS.antiadmin_telegramNotf[0] and cVARS.telegram[0] then
            sendTelegramNotification(u8("\xCF\xEE\xE4\xEE\xE7\xF0\xE5\xED\xE8\xE5 \xED\xE0 \xE0\xE4\xEC\xE8\xED\xE0: ") .. text)
        end
        if cVARS.antiadmin_reversal[0] then
            ffi.C.ShowWindow(hwin, 3)
        end
        if cVARS.antiadmin_blinking[0] then
            if cVARS.antiadmin_flash[0] == 1 then
                warn = true
            elseif cVARS.antiadmin_flash[0] == 2 then
                warn2 = true
            end
        end
        if cVARS.antiadmin_play_sound[0] then
            playAlertSound()
        end
        if cVARS.antiadmin_kick[0] then
            if not isCharInAnyCar(PLAYER_PED) then
                local random = math.random(1, 2)
                if random == 2 then
                    giveWeaponToChar(PLAYER_PED, 32, 100)
                else
                    setCharCoordinates(PLAYER_PED, 1000.0, 1000.0, 1000.0)
                end
                sendTelegramNotification(u8("\xCA\xE8\xEA\xED\xF3\xEB\xE8 \xEF\xE5\xF0\xF1\xEE\xED\xE0\xE6\xE0"))
            end
        end
        if cVARS.antiadmin_autoExit[0] then
            readMemory(0, 1)
            sendTelegramNotification(u8("\xCA\xF0\xE0\xF8\xED\xF3\xEB \xE8\xE3\xF0\xF3"))
        end
    end
    if text:find(u8("\xD3 \xE2\xE0\xF1 \xED\xE5\xF2 \xEF\xE8\xE2\xE0!")) and not text:find(u8("\xE3\xEE\xE2\xEE\xF0\xE8\xF2")) then
        if cVARS.autobeer[0] then
            sendTelegramNotification(u8("\xD5... \xD5... \xD5\xEE\xE7\xFF\xE8\xED \xF3 \xE2\xE0\xF1 \xE7\xE0\xEA\xEE\xED\xF7\xE8\xEB\xEE\xF1\xFC \xEF\xE8\xE2\xEE, \xEA\xF3\xEF\xE8\xF2\xE5 \xEF... \xEF... \xEF\xE0\xE7\xFF\xE7\xFF"))
            cVARS.autobeer[0] = false
        end
    end
    local t = string.nlower(text:gsub('{......}', ''))
    for _, word in ipairs(answerWords) do
        if t:find(word)
        and not t:find(u8("\xE3\xEE\xE2\xEE\xF0\xE8\xF2"))
        and not t:find('vip')
        and not t:find('forever')
        and not t:find('admin')
        and not t:find('premium') then
            if cVARS.auto[0] then
                lua_thread.create(function()
                    if not otvet then
                        otvet = true
                        wait(math.random(2000, 3000))
                        sendPacket_220_1_128()
                        wait(500)
                        sendPacket_220_1_0()
                        sampSendChat(otvet_1[math.random(1, #otvet_1)])
                        wait(math.random(1000, 5000))
                        otvet = false
                    end
                end)
            end
            break
        end
    end
    if cVARS.bot[0] and not text:find(u8("\xE3\xEE\xE2\xEE\xF0\xE8\xF2")) and not text:find(u8("\xEA\xF0\xE8\xF7\xE8\xF2")) then
        if text:find(u8("\xC2\xFB \xF1\xEB\xE8\xF8\xEA\xEE\xEC \xE4\xE0\xEB\xE5\xEA\xEE \xEE\xF2 \xE4\xE5\xF0\xE5\xE2\xE0!")) then
            resetNavPath()
            bot_state = "SEARCH_TREE"
        elseif text:find(u8("\xD2\xE5\xEB\xE5\xE6\xEA\xE0 \xF1 \xE4\xF0\xEE\xE2\xE0\xEC\xE8 \xE1\xFB\xEB\xE0 \xEF\xEE\xF2\xE5\xF0\xFF\xED\xE0")) and not (bot_state == "ESCAPE_VEHICLE") then
            resetNavPath()
            bot_state = "SEARCH_TREE"
        elseif text:find(u8("\xCF\xEE\xE4\xEE\xE6\xE4\xE8\xF2\xE5, \xE4\xF0\xF3\xE3\xEE\xE9 \xE8\xE3\xF0\xEE\xEA \xF1\xE5\xE9\xF7\xE0\xF1 \xF0\xF3\xE1\xE8\xF2 \xE4\xE5\xF0\xE5\xE2\xEE")) then
            -- Äåðåâî çàíÿòî äðóãèì èãðîêîì  äîáàâëÿåì â èãíîð è èùåì äðóãîå
            resetNavPath()
            if current_tree_points and current_tree_points[1] then
                local pt = current_tree_points[current_tree_point_idx] or current_tree_points[1]
                table.insert(ignore_trees, {pt[1], pt[2], pt[3]})
            end
            bot_state = "SEARCH_TREE"
            state_entered["SEARCH_TREE"] = false
        end
    end
    -- Ãðóïïîâîé áîíóñ: "[Ãðóïïà] Ó÷àñòíèê ãðóïïû äîñòàâèë äðîâà! Âàø áîíóñ: +NNN äðîâ, + MM.MMM"
    do
        local clean = text:gsub("{......}", "")
        local drova_bonus = clean:match(u8("%+(%d+)%s*%p*%s*\xE4\xF0\xEE\xE2"))
        local money_bonus = clean:match("%+%s*([%d%.]+)%s*$") or clean:match("%+%s*([%d%.]+)%s*,")
        if not money_bonus then
            money_bonus = clean:match("([%d%.]+)%s*$")
        end
        if clean:find(u8("\xE4\xEE\xF1\xF2\xE0\xE2\xE8\xEB \xE4\xF0\xEE\xE2\xE0")) and clean:find(u8("\xC2\xE0\xF8 \xE1\xEE\xED\xF3\xF1")) then
            if drova_bonus then
                local n = tonumber(drova_bonus) or 0
                cVARS.drova_amount[0] = cVARS.drova_amount[0] + n
                cVARS.daily_drova[0]  = cVARS.daily_drova[0]  + n
                cVARS.weekly_drova[0] = cVARS.weekly_drova[0] + n
            end
        end
    end
    local text, prefix, color = sampGetChatString(99)
    local filename = text:match(u8("\xD1\xEA\xF0\xE8\xED\xF8\xEE\xF2 \xF1\xEE\xF5\xF0\xE0\xED\xE5\xED: (%d+%.%d+%.%d+%.%d+%.jpg)"))
 
    if cumshot and filename and color == 4287146594 then
        sampAddChatMessage("\xD1\xEA\xF0\xE8\xED\xF8\xEE\xF2 \xED\xE0\xE9\xE4\xE5\xED: " .. filename, -1)
        local todayFolder = getTodayScreenshotFolder()
        local filePath = todayFolder .. "\\" .. filename
        sendScreenshotTG(filePath, filename)
        cumshot = false
    end
end
 
function samp.onSendPlayerSync(data)
    if walking then
        data.upDownKeys = 65408
    end
    if turnleft then
        data.leftRightKeys = 65408
    end
    if turnright then
        data.leftRightKeys = 00128
    end
 
    return data
end

function samp.onSetPlayerPos(position)
    if not active then return end
    local mX, mY, mZ = getCharCoordinates(PLAYER_PED)
    if math.floor(mX) == math.floor(position.x) and math.floor(mY) == math.floor(position.y) and math.floor(mZ) < math.floor(position.z) then
        if cVARS.antiadmin_autoOff[0] and cVARS.bot[0] then
            sendTelegramNotification(u8("\xCE\xEF\xE0 \xE0\xE4\xEC\xE8\xED \xF1\xEB\xE0\xEF\xED\xF3\xEB, \xEE\xEA\xE0\xED\xF7\xE8\xE2\xE0\xFE \xF1\xE2\xEE\xFE \xF0\xE0\xE1\xEE\xF2\xF3"))
            cVARS.bot[0] = false
            bot_state = "IDLE"
            if cVARS.antiadmin_play_sound[0] then
                playAlertSound()
            end
        end
    end
end
 
function onReceivePacket(id, bs) 
    if id == 220 then
        raknetBitStreamIgnoreBits(bs, 8)
        local subId = raknetBitStreamReadInt8(bs)
        if subId == 17 then
            raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
            
            if (cVARS.autoeat[0] or cVARS.autolarek[0]) and str:find("event%.arizonahud%.playerSatiety', `%[(%d+)%]`") then
                satiety = tonumber(str:match("(%d+)"))
            end
            if str:lower():find("streetfood") then
                active = true
            end
            if cVARS.bot[0] and str:find("LumberingGame", 1, true) and str:find("showModal", 1, true) then
                if bot_state == "GO_TO_TREE_POINT" or bot_state == "SEARCH_TREE" then
                    set_wait_alt = os.clock()
                    minigame_running = true
                    minigame_done_time = 0
                    bot_state = "PLAY_MINIGAME"
                    state_entered["PLAY_MINIGAME"] = false
                elseif bot_state == "PLAY_MINIGAME" then
                    minigame_running = false
                    minigame_done_time = os.clock()
                    partner_name = nil
                    partner_absent = false
                    waiting_for_my_turn = false
                    my_turn_ready = false
                end
            end
            if cVARS.bot[0] and bot_state == "PLAY_MINIGAME" then
                if str:find("initializeResult", 1, true) then
                    minigame_running = false
                    minigame_done_time = os.clock()
                end
            end
            if str:find("LumberingGame", 1, true) and str:find("showModal", 1, true) then
                isProcessingTurn = false
                taskQueue = {}
            end
            if str:find("lumberingGame%.updateGameState") then
                local data = str:match("`(%b[])`") or str:match("%[.-%]")
                if not data then return end
                currentStage = tonumber(data:match('"stage":(%d+)')) or currentStage
                currentStart = tonumber(data:match('"start":(%d+)')) or 0
                currentWidth = tonumber(data:match('"width":(%d+)')) or 0
                local isMyState = tonumber(data:match('"isMyState":(%d+)')) or 0
                local my_samp_name = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
                if not my_samp_name then my_samp_name = "" end
                local new_partner = nil
                for name_val in data:gmatch('"name":"([^"]+)"') do
                    if name_val ~= my_samp_name and name_val ~= "\xc2\xdb" then
                        new_partner = name_val
                        break
                    end
                end
                if new_partner then
                    local is_absent = (new_partner:find("\xce\xf2\xf2\xf2\xf2") ~= nil)
                    if not is_absent then
                        partner_name = new_partner
                        if partner_absent then
                            partner_absent = false
                        end
                    else
                        if not partner_absent and cVARS.bot[0] and bot_state == "PLAY_MINIGAME" then
                            partner_absent = true
                            if waiting_for_my_turn then
                                sendCustomPacket("lumbering-game.exit")
                                isProcessingTurn = false
                                taskQueue = {}
                                minigame_running = false
                                minigame_done_time = 0
                                waiting_for_my_turn = false
                                my_turn_ready = false
                                if current_tree_points and #current_tree_points >= 2 then
                                    local next_idx = (current_tree_point_idx == 1) and 2 or 1
                                    if isPointAvailable(current_tree_points[next_idx][1], current_tree_points[next_idx][2], current_tree_points[next_idx][3]) then
                                        current_tree_point_idx = next_idx
                                    end
                                end
                                resetNavPath()
                                bot_state = "GO_TO_TREE_POINT"
                                state_entered["GO_TO_TREE_POINT"] = false
                            end
                        end
                    end
                else
                    partner_name = nil
                    partner_absent = false
                end
                if cVARS.bot[0] and bot_state == "PLAY_MINIGAME" and partner_name ~= nil then
                    if isMyState == 0 and not waiting_for_my_turn and not isProcessingTurn then
                        waiting_for_my_turn = true
                        my_turn_ready = false
                    end
                end

                if isMyState == 1 and autoEnabled and currentWidth > 0 and not isProcessingTurn then
                    waiting_for_my_turn = false
                    my_turn_ready = false
                    pushTask(function()
                        wait(110 + math.random(60, 130))
                        performTurn()
                    end)
                end
            end
            if str:find("event.arizonahud.showSawmillNotification") and
               str:find(u8("\xC2\xC0\xD8\xC0 \xCE\xD7\xC5\xD0\xC5\xC4\xDC \xD0\xC5\xC7\xC0\xD2\xDC")) then
                waiting_for_my_turn = false
                my_turn_ready = true
            end
            if str:find("event.arizonahud.showSawmillNotification") and str:find(u8("\xC2\xFB \xEF\xEE\xEB\xF3\xF7\xE8\xEB\xE8 \xF2\xE5\xEB\xE5\xE6\xEA\xF3")) then
                need_find_telega = true
                need_find_telega_time = os.clock()
            end
            if str:find("event.arizonahud.showSawmillNotification") and str:find(u8("\xC2\xFB \xF1\xE4\xE0\xEB\xE8 \xE4\xF0\xEE\xE2\xE0 \xED\xE0 \xEF\xE5\xF0\xE5\xF0\xE0\xE1\xEE\xF2\xEA\xF3")) then
                resetNavPath()
                if cVARS.autolarek[0] and satiety and satiety <= 25 then
                    bot_state = "GO_KYSHAT"
                elseif next_telega_pos then
                    pickup_telega_pos = next_telega_pos
                    next_telega_pos = nil
                    state_entered["PICKUP_TELEGA"] = false
                    bot_state = "PICKUP_TELEGA"
                else
                    bot_state = "SEARCH_TREE"
                    last_jump = os.clock() + 3
                end
            end
            if str:find("initializeResult") then
                isProcessingTurn = false
                taskQueue = {}
            end

            -- ================= ÍÀ×ÀËÎ: Ó×¨Ò ÄÐÎÂ, ÄÐÅÂÅÑÈÍÛ È ÄÅÍÅÃ =================
            if str:find("event.itemsNotification.initialize") then
                local drova_amt = 0
                local derevo_amt = 0
                local d_m = str:match(u8("\"title\":\"\xC4\xF0\xEE\xE2\xE0\".-\"description\":\"x(%d+)\""))
                if d_m then drova_amt = tonumber(d_m) end
                local dr_m = str:match(u8("\"title\":\"\xC4\xF0\xE5\xE2\xE5\xF1\xE8\xED\xE0 \xE2\xFB\xF1\xF8\xE5\xE3\xEE \xEA\xE0\xF7\xE5\xF1\xF2\xE2\xE0\".-\"description\":\"x(%d+)\""))
                if dr_m then derevo_amt = tonumber(dr_m) end

                if drova_amt > 0 or derevo_amt > 0 then
                    local today = tonumber(os.date("%d"))
                    local week_num = tonumber(os.date("%U"))
                    if today ~= cVARS.last_day[0] then
                        cVARS.daily_trees[0] = 0; cVARS.daily_drova[0] = 0; cVARS.degniebat_den[0] = 0; cVARS.last_day[0] = today
                    end
                    if week_num ~= cVARS.last_week[0] then
                        cVARS.weekly_trees[0] = 0; cVARS.weekly_drova[0] = 0; cVARS.degniebat_week[0] = 0; cVARS.last_week[0] = week_num
                    end

                    cVARS.derevo_amount[0] = cVARS.derevo_amount[0] + derevo_amt
                    cVARS.drova_amount[0] = cVARS.drova_amount[0] + drova_amt
                    cVARS.daily_trees[0] = cVARS.daily_trees[0] + derevo_amt
                    cVARS.weekly_trees[0] = cVARS.weekly_trees[0] + derevo_amt
                    cVARS.daily_drova[0] = cVARS.daily_drova[0] + drova_amt
                    cVARS.weekly_drova[0] = cVARS.weekly_drova[0] + drova_amt
                    save_cfg()
                end
            end

            if str:find("event.arizonahud.hideSawmillNotification") then
                sawmill_hidden = true
            end

            if str:find("event.player.addMoney") and sawmill_hidden then
                local money_match = str:match("%[(%d+)%]")
                local money_amt = money_match and tonumber(money_match) or 0
                sawmill_hidden = false -- ñáðîñ ôëàãà ñðàçó ïîñëå ïðîâåðêè

                if money_amt > 0 then
                    local today = tonumber(os.date("%d"))
                    local week_num = tonumber(os.date("%U"))
                    if today ~= cVARS.last_day[0] then
                        cVARS.degniebat_den[0] = 0; cVARS.last_day[0] = today
                    end
                    if week_num ~= cVARS.last_week[0] then
                        cVARS.degniebat_week[0] = 0; cVARS.last_week[0] = week_num
                    end

                    -- Ôîðìóëà ñ ó÷¸òîì ïðÿìîé âûïëàòû äåíåã
                    local rashetzalypi = (cVARS.derevo_amount[0] * (cVARS.derevo_value[0] or 0)) + 
                                         (cVARS.drova_amount[0] * (cVARS.drova_value[0] or 0)) + money_amt
                    if rashetzalypi > 0 then
                        cVARS.degniebat_den[0] = rashetzalypi
                        cVARS.degniebat_week[0] = rashetzalypi
                        save_cfg()
                    end
                end
            end
            -- ================= ÊÎÍÅÖ: Ó×¨Ò ÄÐÎÂ, ÄÐÅÂÅÑÈÍÛ È ÄÅÍÅÃ =================

        end
    elseif id == 33 then
        cVARS.bot[0] = false
        bot_state = "IDLE"
        if cVARS.antiadmin_telegramNotf[0] then
            sendTelegramNotification(u8("\xCF\xEE\xF2\xE5\xF0\xFF\xED\xEE \xF1\xEE\xE5\xE4\xE8\xED\xE5\xED\xE8\xE5 \xF1 \xF1\xE5\xF0\xE2\xE5\xF0\xEE\xEC"))
        end
    elseif id == 32 then
        cVARS.bot[0] = false
        bot_state = "IDLE"
        if cVARS.antiadmin_telegramNotf[0] then
            sendTelegramNotification(u8("\xD1\xE5\xF0\xE2\xE5\xF0 \xE7\xE0\xEA\xF0\xFB\xEB \xF1\xEE\xE5\xE4\xE8\xED\xE5\xED\xE8\xE5"))
        end
    end
end
 
samp.onShowDialog = function(dialogId, style, title, button1, button2, text)
    if dialogId == 15039 then
        if cVARS.antiadmin_autoOff[0] then
            cVARS.bot[0] = false
            bot_state = "IDLE"
            cMsg("{DDECFF}\xC1\xEE\xF2\xE8\xEA \xE4\xF0\xE5\xE2\xF1\xE8\xF1\xE8\xED\xFB{FF0000}\xE7\xE0\xE2\xE5\xF0\xF8\xE8\xEB \xF0\xE0\xE1\xEE\xF2\xF3")
        end
        if cVARS.antiadmin_kick[0] then
            if not isCharInAnyCar(PLAYER_PED) then
                local random = math.random(1, 2)
                if random == 1 then
                    giveWeaponToChar(PLAYER_PED, 32, 100)
                else
                    setCharCoordinates(PLAYER_PED, 1000.0, 1000.0, 1000.0)
                end
            end
        end
        if cVARS.antiadmin_skipdialog[0] then
            lua_thread.create(function()
                wait(dialogskip)
                setVirtualKeyDown(27, true)
                wait(50)
                setVirtualKeyDown(27, false)
            end)
        end
        if cVARS.antiadmin_play_sound[0] then
            playAlertSound()
        end
        if cVARS.antiadmin_telegramNotf[0] then
            sendTelegramNotification(u8("\xCF\xEE\xE4\xEE\xE7\xF0\xE5\xED\xE8\xE5 \xED\xE0 \xE0\xE4\xEC\xE8\xED\xE0: ") .. text)
        end
 
        if cVARS.antiadmin_reversal[0] then
            ffi.C.ShowWindow(hwin, 3)
        end
 
        if cVARS.antiadmin_blinking[0] then
            if cVARS.antiadmin_flash[0] then
                warn = true
                warn2 = true
            end
        end
 
        if control.autoExit.v then
            sendTelegramNotification(u8("\xCA\xF0\xE0\xF8\xED\xF3\xEB \xE8\xE3\xF0\xF3"))
            readMemory(0, 1)
        end
    end
 
    if dialogId == 26137 and cVARS.auto_job[0] then
        sampSendDialogResponse(26137, 1, 0, u8("1. \xD3\xF1\xF2\xF0\xEE\xE9\xF1\xF2\xE2\xEE \xED\xE0 \xF0\xE0\xE1\xEE\xF2\xF3 \xEB\xE5\xF1\xEE\xF0\xF3\xE1\xEE\xEC"))
        return false
    elseif dialogId == 26138 and cVARS.auto_job[0] then
        sampSendDialogResponse(dialogId, 1, 65535, "")
        return false
    elseif dialogId == 26141 and cVARS.auto_job[0] then
        sampSendDialogResponse(dialogId, 1, 65535, "")
        return false
    elseif dialogId == 26139 and cVARS.auto_job[0] then
        sampSendDialogResponse(dialogId, 1, 65535, "")
        return false
    end
end
 
samp.onTogglePlayerControllable = function(controllable) 
    if not(controllable) and cVARS.antibot_antifreeze[0] and not bot_state == "WAIT_TELEGA" and cVARS.bot[0] then
        sendTelegramNotification(u8("\xC2\xE0\xF1 \xE7\xE0\xEC\xEE\xF0\xEE\xE7\xE8\xEB\xE8"))
        cVARS.bot[0] = false
        if cVARS.antiadmin_play_sound[0] then
            playAlertSound()
        end
    end
end

-- Telegram functions

function threadHandle(runner, url, args, resolve, reject)
    local t = runner(url, args)
    local r = t:get(0)
    while not r do
        r = t:get(0)
        wait(0)
    end
    local status = t:status()
    if status == 'completed' then
        local ok, result = r[1], r[2]
        if ok then resolve(result) else reject(result) end
    elseif status == 'canceled' then
        reject(status)
    else
        reject('unknown error')
    end
    t:cancel(0)
end

function requestRunner()
    return effil.thread(function(u, a)
        local https = require 'ssl.https'
        local ok, result = pcall(https.request, u, a)
        if ok then
            return {true, result}
        else
            return {false, result}
        end
    end)
end

function async_http_request(url, args, resolve, reject)
    local runner = requestRunner()
    if not reject then reject = function() end end
    lua_thread.create(function()
        threadHandle(runner, url, args, resolve, reject)
    end)
end

function encodeUrl(str)
    if str then
        str = u8:encode(str, 'CP1251')
        str = str:gsub("([^%w _%%%-%.~])", function(c) 
            return string.format("%%%02X", string.byte(c)) 
        end)
        str = str:gsub(" ", "%%20")
    end
    return str
end

function getMainMenuKeyboard()
    local keyboard = {
        keyboard = {
            {
                {text = u8("\xD1\xF2\xE0\xF0\xF2 \xE1\xEE\xF2\xE0")},
                {text = u8("\xD1\xF2\xEE\xEF \xE1\xEE\xF2\xE0")}
            },
            {
                {text = u8("\xD1\xF2\xE0\xF2\xF3\xF1")},
                {text = u8("\xC7\xE0\xF0\xE0\xE1\xEE\xF2\xEE\xEA")}
            },
            {
                {text = u8("\xCE\xF2\xEF\xF0\xE0\xE2\xE8\xF2\xFC \xF1\xEE\xEE\xE1\xF9\xE5\xED\xE8\xE5")},
                {text = u8("\xC2\xFB\xF5\xEE\xE4 \xE8\xE7 \xE8\xE3\xF0\xFB")}
            },
            {
                {text = u8("\xC7\xE0\xEA\xF0\xFB\xF2\xFC \xE4\xE8\xE0\xEB\xEE\xE3")},
                {text = u8("\xCA\xF0\xE0\xF8 \xE8\xE3\xF0\xFB")}
            },
            {
                {text = u8("\xD1\xE4\xE5\xEB\xE0\xF2\xFC \xF1\xEA\xF0\xE8\xED\xF8\xEE\xF2")},
                {text = u8("\xCF\xEE\xEC\xEE\xF9\xFC")}
            }
        },
        resize_keyboard = true,
        one_time_keyboard = true
    }
    return keyboard
end

function deletePreviousMessage(chat_id)
    if last_message_ids[chat_id] then
        async_http_request('https://api.telegram.org/bot' .. token .. '/deleteMessage?chat_id=' .. chat_id .. '&message_id=' .. last_message_ids[chat_id], '', function() end)
    end
end

function sendTelegramNotification(msg, chat_id)
    chat_id = chat_id or config.telegram_chat_id
    if not chat_id or chat_id == "" then
        cMsg("\xCE\xF8\xE8\xE1\xEA\xE0: chat_id \xED\xE5 \xF3\xEA\xE0\xE7\xE0\xED \xE8\xEB\xE8 \xEF\xF3\xF1\xF2\xEE\xE9. \xCF\xF0\xEE\xE2\xE5\xF0\xFC\xF2\xE5 \xED\xE0\xF1\xF2\xF0\xEE\xE9\xEA\xE8 Telegram.")
        return
    end
    msg = msg:gsub('{......}', '')
    msg = encodeUrl(msg)
    local keyboard_json = encodeUrl(json.encode(getMainMenuKeyboard()))
    deletePreviousMessage(chat_id)
    async_http_request(tg_api_url() .. '/bot' .. token .. '/sendMessage?chat_id=' .. chat_id .. '&text=' .. msg .. '&reply_markup=' .. keyboard_json, '', function(result)
        local proc_table = decodeJson(result)
        if proc_table and proc_table.ok and proc_table.result.message_id then
            last_message_ids[chat_id] = proc_table.result.message_id
        end
    end)
end

function sendMenu(chat_id, text)
    local keyboard_json = encodeUrl(json.encode(getMainMenuKeyboard()))
    deletePreviousMessage(chat_id)
    async_http_request(tg_api_url() .. '/bot' .. token .. '/sendMessage?chat_id=' .. chat_id .. '&text=' .. encodeUrl(text) .. '&reply_markup=' .. keyboard_json, '', function(result)
        local proc_table = decodeJson(result)
        if proc_table and proc_table.ok and proc_table.result.message_id then
            last_message_ids[chat_id] = proc_table.result.message_id
        end
    end)
end

function processing_telegram_updates(result)
    if result then
        local proc_table = decodeJson(result)
        if proc_table and proc_table.ok then
            for i, res in ipairs(proc_table.result) do
                if res.update_id > updateid then
                    updateid = res.update_id
                    local callback = res.callback_query
                    local message = res.message
                    if message and message.text then
                        local chat_id = message.chat.id
                        local text = u8:decode(message.text)
                        if text:match('^!send (.+)') then
                            local sendMessage = text:match('^!send (.+)')
                            sampSendChat(sendMessage)
                            sendTelegramNotification(u8("\xD1\xEE\xEE\xE1\xF9\xE5\xED\xE8\xE5 \xEE\xF2\xEF\xF0\xE0\xE2\xEB\xE5\xED\xEE \xE2 \xE8\xE3\xF0\xEE\xE2\xEE\xE9 \xF7\xE0\xF2: ") .. sendMessage, chat_id)
                        elseif text:match('^/start') then
                            sendMenu(chat_id, u8("\xCF\xF0\xE8\xE2\xE5\xF2! \xC2\xFB\xE1\xE5\xF0\xE8\xF2\xE5 \xE4\xE5\xE9\xF1\xF2\xE2\xE8\xE5 \xE1\xEE\xF2\xE0:"))
                        elseif text == u8("\xD1\xF2\xE0\xF0\xF2 \xE1\xEE\xF2\xE0") then
                            cVARS.bot[0] = true
                            bot_state = "SEARCH_TREE"
                            sendTelegramNotification(u8("\xC1\xEE\xF2 \xEB\xE5\xF1\xEE\xF0\xF3\xE1\xE0 \xE7\xE0\xEF\xF3\xF9\xE5\xED!"), chat_id)
                        elseif text == u8("\xD1\xF2\xEE\xEF \xE1\xEE\xF2\xE0") then
                            cVARS.bot[0] = false
                            sendTelegramNotification(u8("\xC1\xEE\xF2 \xEB\xE5\xF1\xEE\xF0\xF3\xE1\xE0 \xEE\xF1\xF2\xE0\xED\xEE\xE2\xEB\xE5\xED!"), chat_id)
                        elseif text == u8("\xD1\xF2\xE0\xF2\xF3\xF1") then
                            local statusText = u8("\xD1\xF2\xE0\xF2\xF3\xF1 \xE1\xEE\xF2\xE0: ") .. (cVARS.bot[0] and u8("\xD0\xC0\xC1\xCE\xD2\xC0\xC5\xD2") or u8("\xCE\xD1\xD2\xC0\xCD\xCE\xC2\xCB\xC5\xCD"))
                            statusText = statusText .. u8("\n\xD2\xE5\xEA\xF3\xF9\xE5\xE5 \xF1\xEE\xF1\xF2\xEE\xFF\xED\xE8\xE5: ") .. bot_state
                            statusText = statusText .. u8("\n\xC4\xE5\xF0\xE5\xE2\xFC\xE5\xE2 \xF1\xF0\xF3\xE1\xEB\xE5\xED\xEE: ") .. cVARS.derevo_amount[0]
                            sendTelegramNotification(statusText, chat_id)
                        elseif text == u8("\xC7\xE0\xF0\xE0\xE1\xEE\xF2\xEE\xEA") then
                            local zarabotok = cVARS.derevo_amount[0] * cVARS.derevo_value[0] + cVARS.drova_amount[0] * cVARS.drova_value[0]
                            local earningsText = u8("\xD2\xE5\xEA\xF3\xF9\xE8\xE9 \xE7\xE0\xF0\xE0\xE1\xEE\xF2\xEE\xEA: ") .. zarabotok .. u8("$\n\xD6\xE5\xED\xE0 \xE7\xE0 \xE4\xE5\xF0\xE5\xE2\xEE: ") .. cVARS.derevo_value[0] .. u8("$\n\xC4\xE5\xF0\xE5\xE2\xFC\xE5\xE2 \xF1\xF0\xF3\xE1\xEB\xE5\xED\xEE: ") .. cVARS.derevo_amount[0]
                            sendTelegramNotification(earningsText, chat_id)
                        elseif text == u8("\xCE\xF2\xEF\xF0\xE0\xE2\xE8\xF2\xFC \xF1\xEE\xEE\xE1\xF9\xE5\xED\xE8\xE5") then
                            sendTelegramNotification(u8("\xC2\xE2\xE5\xE4\xE8\xF2\xE5 \xF1\xEE\xEE\xE1\xF9\xE5\xED\xE8\xE5 \xF7\xE5\xF0\xE5\xE7 !send <\xF2\xE5\xEA\xF1\xF2> \xE2 \xF7\xE0\xF2"), chat_id)
                        elseif text == u8("\xC2\xFB\xF5\xEE\xE4 \xE8\xE7 \xE8\xE3\xF0\xFB") then
                            sampProcessChatInput('/q')
                            sendTelegramNotification(u8("\xC2\xFB\xF5\xEE\xE6\xF3 \xE8\xE7 \xE8\xE3\xF0\xFB!"), chat_id)
                        elseif text == u8("\xC7\xE0\xEA\xF0\xFB\xF2\xFC \xE4\xE8\xE0\xEB\xEE\xE3") then
                            lua_thread.create(function()
                                wait(500)
                                setVirtualKeyDown(27, true)
                                wait(50)
                                setVirtualKeyDown(27, false)
                            end)
                            sendTelegramNotification(u8("\xC4\xE8\xE0\xEB\xEE\xE3 \xE7\xE0\xEA\xF0\xFB\xF2!"), chat_id)
                        elseif text == u8("\xCA\xF0\xE0\xF8 \xE8\xE3\xF0\xFB") then
                            piska = true
                            sendTelegramNotification(u8("\xC8\xE3\xF0\xE0 \xEA\xF0\xE0\xF8\xED\xF3\xF2\xE0!"), chat_id)
                        elseif text == u8("\xD1\xE4\xE5\xEB\xE0\xF2\xFC \xF1\xEA\xF0\xE8\xED\xF8\xEE\xF2") then
                            lua_thread.create(function()
                                cumshot = true
                                wait(1000)
                                setVirtualKeyDown(119, true)
                                wait(50)
                                setVirtualKeyDown(119, false)
                            end)
                            sendTelegramNotification(u8("\xD1\xEA\xF0\xE8\xED\xF8\xEE\xF2 \xE4\xE5\xEB\xE0\xE5\xF2\xF1\xFF, \xEE\xE6\xE8\xE4\xE0\xE5\xF2\xF1\xFF \xF1\xEE\xF5\xF0\xE0\xED\xE5\xED\xE8\xE5..."),chat_id)
                        elseif text == u8("\xCF\xEE\xEC\xEE\xF9\xFC") then
                            local helpText = u8("\xCA\xEE\xEC\xE0\xED\xE4\xFB \xE1\xEE\xF2\xE0:\n") ..
                                            u8("/start - \xCF\xEE\xEA\xE0\xE7\xE0\xF2\xFC \xEC\xE5\xED\xFE\n") ..
                                            u8("!send <\xF2\xE5\xEA\xF1\xF2> - \xCE\xF2\xEF\xF0\xE0\xE2\xE8\xF2\xFC \xF1\xEE\xEE\xE1\xF9\xE5\xED\xE8\xE5 \xE2 \xE8\xE3\xF0\xEE\xE2\xEE\xE9 \xF7\xE0\xF2\n") ..
                                            u8("\xCA\xED\xEE\xEF\xEA\xE8:\n") ..
                                            u8("\xD1\xF2\xE0\xF0\xF2 \xE1\xEE\xF2\xE0 - \xC7\xE0\xEF\xF3\xF1\xF2\xE8\xF2\xFC \xE1\xEE\xF2\xE0\n") ..
                                            u8("\xD1\xF2\xEE\xEF \xE1\xEE\xF2\xE0 - \xCE\xF1\xF2\xE0\xED\xEE\xE2\xE8\xF2\xFC \xE1\xEE\xF2\xE0\n") ..
                                            u8("\xD1\xF2\xE0\xF2\xF3\xF1 - \xCF\xEE\xEA\xE0\xE7\xE0\xF2\xFC \xF1\xF2\xE0\xF2\xF3\xF1 \xE1\xEE\xF2\xE0\n") ..
                                            u8("\xC7\xE0\xF0\xE0\xE1\xEE\xF2\xEE\xEA - \xCF\xEE\xEA\xE0\xE7\xE0\xF2\xFC \xE7\xE0\xF0\xE0\xE1\xEE\xF2\xEE\xEA\n") ..
                                            u8("\xCE\xF2\xEF\xF0\xE0\xE2\xE8\xF2\xFC \xF1\xEE\xEE\xE1\xF9\xE5\xED\xE8\xE5 - \xC2\xE2\xE5\xF1\xF2\xE8 \xF1\xEE\xEE\xE1\xF9\xE5\xED\xE8\xE5 \xE4\xEB\xFF \xF7\xE0\xF2\xE0\n") ..
                                            u8("\xC2\xFB\xF5\xEE\xE4 \xE8\xE7 \xE8\xE3\xF0\xFB - \xC2\xFB\xE9\xF2\xE8 \xE8\xE7 \xE8\xE3\xF0\xFB (/q)\n") ..
                                            u8("\xC7\xE0\xEA\xF0\xFB\xF2\xFC \xE4\xE8\xE0\xEB\xEE\xE3 - \xC7\xE0\xEA\xF0\xFB\xF2\xFC \xE4\xE8\xE0\xEB\xEE\xE3 (Esc)\n") ..
                                            u8("\xCA\xF0\xE0\xF8 \xE8\xE3\xF0\xFB - \xCA\xF0\xE0\xF8\xED\xF3\xF2\xFC \xE8\xE3\xF0\xF3\n") ..
                                            u8("\xD1\xE4\xE5\xEB\xE0\xF2\xFC \xF1\xEA\xF0\xE8\xED\xF8\xEE\xF2 - \xD1\xE4\xE5\xEB\xE0\xF2\xFC \xE8 \xEE\xF2\xEF\xF0\xE0\xE2\xE8\xF2\xFC \xF1\xEA\xF0\xE8\xED\xF8\xEE\xF2\n") ..
                                            u8("\xCF\xEE\xEC\xEE\xF9\xFC - \xCF\xEE\xEA\xE0\xE7\xE0\xF2\xFC \xFD\xF2\xEE \xF1\xEE\xEE\xE1\xF9\xE5\xED\xE8\xE5")
                            sendTelegramNotification(helpText, chat_id)
                        end
                    end
                end
            end
        end
    end
end

function get_telegram_updates()
    while not updateid do wait(1) end
    local runner = requestRunner()
    local reject = function() end
    local args = ''
    while true do
        local url = tg_api_url() .. '/bot'..token..'/getUpdates?offset='..(updateid + 1)
        threadHandle(runner, url, args, function(result)
            processing_telegram_updates(result)
        end, reject)
        wait(0)
    end
end

function getLastUpdate()
    async_http_request(tg_api_url() .. '/bot' .. token .. '/getUpdates?chat_id=' .. chat_id .. '&offset=-1', '', function(result)
        if result then
            local proc_table = decodeJson(result)
            if proc_table and proc_table.ok then
                if #proc_table.result > 0 then
                    updateid = proc_table.result[1].update_id
                    if proc_table.result[1].message then
                        last_message_ids[chat_id] = proc_table.result[1].message.message_id
                    end
                else
                    updateid = 1
                end
            end
        end
    end)
end

---îòïðàâêà ñêðèíøîòà ñïèçæåíàÿ 
function formatText(text)
    local t = {
        ['{day}'] = os.date('%d'),
        ['{month}'] = os.date('%m'),
        ['{monthName}'] = os.date('%B'),
        ['{year}'] = os.date('%Y'),
        ['{nick}'] = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))),
    }
    for k, v in pairs(t) do text = text:gsub(k, v) end
    return text
end

function getTodayScreenshotFolder()
    local t = os.date("*t")
    local monthNames = {
        u8("\xFF\xED\xE2\xE0\xF0\xFF"), u8("\xF4\xE5\xE2\xF0\xE0\xEB\xFF"), u8("\xEC\xE0\xF0\xF2\xE0"), u8("\xE0\xEF\xF0\xE5\xEB\xFF"), u8("\xEC\xE0\xFF"), u8("\xE8\xFE\xED\xFF"), u8("\xE8\xFE\xEB\xFF"), u8("\xE0\xE2\xE3\xF3\xF1\xF2\xE0"),
        u8("\xF1\xE5\xED\xF2\xFF\xE1\xF0\xFF"), u8("\xEE\xEA\xF2\xFF\xE1\xF0\xFF"), u8("\xED\xEE\xFF\xE1\xF0\xFF"), u8("\xE4\xE5\xEA\xE0\xE1\xF0\xFF")
    }
    local dayStr = string.format("%02d", t.day)
    local monthStr = monthNames[t.month]
    local yearStr = t.year .. u8("\xE3")
    local folder = dayStr .. " " .. monthStr .. " " .. yearStr
    local fullPath = getFolderPath(5) .. "\\GTA San Andreas User Files\\SAMP\\arizona\\screens\\" .. folder

    if not doesDirectoryExist(fullPath) then
        createDirectory(fullPath)
        sampAddChatMessage("DEBUG: \xD1\xEE\xE7\xE4\xE0\xED\xE0 \xEF\xE0\xEF\xEA\xE0: " .. fullPath, 0x00FF00)
    else
        sampAddChatMessage("DEBUG: \xD1\xE5\xE3\xEE\xE4\xED\xFF\xF8\xED\xFF\xFF \xEF\xE0\xEF\xEA\xE0: " .. fullPath, 0x00FF00)
    end
    return fullPath
end

function sendScreenshotTG(path, file)
    lua_thread.create(function()
        telegramRequest(config.telegram_token, 'sendPhoto', {caption = file or 'nil...', chat_id = config.telegram_chat_id}, {photo = path})
    end)
end

function telegramRequest(token, telegramMethod, requestParameters, requestFile)
    local multipart = require('multipart-post')
    local effil = require('effil')
    local dkjson = require('dkjson')

    local defValues = {
        ['caption'] = tostring(u8:encode('')),
        ['parse_mode'] = tostring('HTML'),
        ['disable_notification'] = tostring(false),
        ['reply_to_message_id'] = tostring(0),
        ['reply_markup'] = dkjson.encode({['inline_keyboard'] = {{}}})
    }
    for k, v in pairs(defValues) do if requestParameters[k] == nil then requestParameters[k] = v end end
    for key, value in ipairs(requestParameters) do
        if (#requestParameters ~= 0) then requestParameters[key] = tostring(value) end
    end

    if requestFile and next(requestFile) ~= nil then
        local fileType, fileName = next(requestFile)
        local file = io.open(fileName, 'rb')
        if file then
            requestParameters[fileType] = {filename = fileName, data = file:read('*a')}
            file:close()
        else
            sampAddChatMessage("\xCE\xF8\xE8\xE1\xEA\xE0: \xCD\xE5 \xF3\xE4\xE0\xEB\xEE\xF1\xFC \xEE\xF2\xEA\xF0\xFB\xF2\xFC \xF4\xE0\xE9\xEB " .. fileName, 0xFF0000)
            return false, 'io.open '..fileName..' = false'
        end
    end

    local body, boundary = multipart.encode(requestParameters)
    local thread = effil.thread(function(p_token, p_method, p_body, p_boundary)
        local http = require('ssl.https')
        local ltn12 = require('ltn12')

        local response = {}
        local ok_src, source = pcall(ltn12.source.string, p_body)
        local ok_sink, sink = pcall(ltn12.sink.table, response)
        if not ok_src or not ok_sink then
            return {false, {"ltn12 failure"}}
        end

        local ok, err = pcall(function()
            http.request({
                url = string.format(tg_api_url() .. '/bot', tostring(p_token), tostring(p_method)),
                method = 'POST',
                headers = {
                    ['Accept'] = '*/*',
                    ['Accept-Encoding'] = 'gzip, deflate',
                    ['Accept-Language'] = 'en-us',
                    ['Content-Type'] = string.format('multipart/form-data; boundary=%s', tostring(p_boundary)),
                    ['Content-Length'] = #p_body
                },
                source = source,
                sink = sink
            })
        end)

        if ok then
            return {true, response}
        else
            return {false, {tostring(err)}}
        end
    end)(token, telegramMethod, body, boundary)
    local result = thread:get(0)
    while not result do
        result = thread:get(0)
        wait(0)
    end

    local status, terr = thread:status()
    if terr then
        sampAddChatMessage("\xCE\xF8\xE8\xE1\xEA\xE0 \xEF\xEE\xF2\xEE\xEA\xE0: " .. tostring(terr), 0xFF0000)
        thread:cancel(0)
        return false, terr
    end

    if status == 'completed' and type(result) == 'table' then
        local ok = result[1]
        local response_table = result[2] or {}
        local response_body = (type(response_table) == 'table' and response_table[1]) and response_table[1] or nil

        if response_body then
            local success, parsed = pcall(dkjson.decode, response_body)
            if success and type(parsed) == 'table' then
                if ok then
                    sampAddChatMessage("\xD1\xEA\xF0\xE8\xED\xF8\xEE\xF2 \xF3\xF1\xEF\xE5\xF8\xED\xEE \xEE\xF2\xEF\xF0\xE0\xE2\xEB\xE5\xED \xE2 Telegram!", 0x00FF00)
                    thread:cancel(0)
                    return true, parsed
                else
                    sampAddChatMessage("\xCE\xF8\xE8\xE1\xEA\xE0 \xEE\xF2\xEF\xF0\xE0\xE2\xEA\xE8 \xE2 Telegram: "..tostring(parsed), 0xFF0000)
                    thread:cancel(0)
                    return false, parsed
                end
            else
                if ok then
                    sampAddChatMessage("\xCE\xF2\xE2\xE5\xF2 Telegram (\xED\xE5 JSON) \xEF\xEE\xEB\xF3\xF7\xE5\xED.", 0x00FF00)
                    thread:cancel(0)
                    return true, response_body
                else
                    sampAddChatMessage("\xCE\xF8\xE8\xE1\xEA\xE0 \xEE\xF2\xEF\xF0\xE0\xE2\xEA\xE8 \xE2 Telegram: "..tostring(response_body), 0xFF0000)
                    thread:cancel(0)
                    return false, response_body
                end
            end
        else
            sampAddChatMessage("\xCF\xF3\xF1\xF2\xEE\xE9 \xEE\xF2\xE2\xE5\xF2 \xEE\xF2 HTTP \xE7\xE0\xEF\xF0\xEE\xF1\xE0.", 0xFF0000)
            thread:cancel(0)
            return false, 'empty_response'
        end
    else
        sampAddChatMessage("\xD1\xF2\xE0\xF2\xF3\xF1 \xEF\xEE\xF2\xEE\xEA\xE0: "..tostring(status), 0xFF0000)
        thread:cancel(0)
        return false, status
    end
end

function decodeJson(jsonString)
    local success, result = pcall(function() return json.decode(jsonString) end)
    if success then
        return result
    else
        return nil
    end
end

function imgui.ShowHelpMarker(desc)
    imgui.TextDisabled(ti.ICON_HELP)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450.0)
        imgui.TextUnformatted(desc)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

-- Îòðèñîâêà ÷àñòèö íàä òåëåæêîé
imgui.OnFrame(
    function()
        return ok_particles and pickup_telega_pos ~= nil and cVARS.bot[0]
    end,
    function(self)
        self.HideCursor = true
    end,
    function()
        if not pickup_telega_pos then return end
        local p = get_telega_particles()
        if not p then return end

        local tx, ty, tz = pickup_telega_pos[1], pickup_telega_pos[2], pickup_telega_pos[3]
        local sx, sy = convert3DCoordsToScreen(tx, ty, tz + 0.5)
        if not sx or not isPointOnScreen(tx, ty, tz, 0) then return end

        local area = 50
        p.size = iv2(area * 2, area * 2)
        p:update(iv2(sx, sy))

        local b_dl = imgui.GetBackgroundDrawList()
        p:draw(b_dl, iv2(sx - area, sy - area))
    end
)

imgui.OnFrame(function() return cVARS.debug[0] end,
    function(self)
        self.HideCursor = true
    end,
    function(player)
        local b_dl = imgui.GetBackgroundDrawList()
        b_dl:AddRectFilled(iv2(40, 360), iv2(650, 515), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.0, 0.0, 0.0, 0.6)), 6)
        imgui.PushFont(fonts[16])
        b_dl:AddText(iv2(50, 370), 0xFFFFFFFF,
            "BOT_STATE = " .. bot_state .. "   |   WALKING = " .. tostring(walking or false) .. "   |   TELEGA = " .. tostring(has_telega))
        local x, y, z = getCharCoordinates(PLAYER_PED)
        b_dl:AddText(iv2(50, 390), 0xFFFFFFFF,
            "PED_COORDS | " .. string.format("X = %.3f Y = %.3f Z = %.3f", x, y, z))
        local f, tree = getNearestTree()
        local tree_str
        if f and tree and #tree > 0 and type(tree[1]) == "table" and #tree[1] >= 3 then
            tree_str = string.format("X = %.3f Y = %.3f Z = %.3f", tree[1][1], tree[1][2], tree[1][3])
        elseif f and tree and type(tree[1]) == "number" then
            tree_str = string.format("X = %.3f Y = %.3f Z = %.3f", tree[1], tree[2], tree[3])
        else
            tree_str = "NOT FOUND"
        end
        b_dl:AddText(iv2(50, 410), 0xFFFFFFFF,
            "NEAREST_TREE | " .. (f and "TRUE" or "FALSE") .. " | " .. tree_str)
        local goal_str = nav_target_x and string.format("X = %.3f Y = %.3f Z = %.3f", nav_target_x, nav_target_y, nav_target_z) or "NONE"
        b_dl:AddText(iv2(50, 430), 0xFFFFFFFF, "GOAL | " .. goal_str)
        local path_len = nav_current_path and #nav_current_path or 0
        local full_len = nav_full_path and #nav_full_path or 0
        local tp_str = (current_tree_points and #current_tree_points > 0)
            and string.format("%d pts idx=%d", #current_tree_points, current_tree_point_idx or 1) or "NONE"
        b_dl:AddText(iv2(50, 450), 0xFFFFFFFF,
            string.format("PATH | idx=%d cur=%d full=%d building=%s   |   TREE_PTS = %s",
                nav_path_index, path_len, full_len, tostring(nav_path_building), tp_str))
        b_dl:AddText(iv2(50, 470), 0xFFFFFFFF,
            string.format("SEG = %.1f   DETOUR = %.0f deg   FAILS = %d",
                nav_segment_size, nav_detour_angle, nav_detour_fails))
        b_dl:AddText(iv2(50, 490), 0xFFFFFFFF,
            string.format("CAM_ANGLE = %.1f deg   |   STUCK_TICKS = %d / %d",
                current_cam_angle or 0, stuck_ticks or 0, STUCK_THRESHOLD))
    end
)

imgui.OnFrame(function() return cVARS.radar[0] end,
    function(self)
        self.HideCursor = true

        if imgui.IsMouseDoubleClicked(0) and imgui.IsMouseHoveringRect(iv2(elements.radar.pos.x - cVARS.radar_size[0] / 2, elements.radar.pos.y - cVARS.radar_size[0] / 2), iv2(elements.radar.pos.x + cVARS.radar_size[0] / 2, elements.radar.pos.y + cVARS.radar_size[0] / 2), false) then
            elements.radar.set_pos = not elements.radar.set_pos
            local mouse_pos = imgui.GetMousePos()
            elements.radar.set_pos_offset = {
                x = mouse_pos.x - elements.radar.pos.x,
                y = mouse_pos.y - elements.radar.pos.y
            }
        end
        if elements.radar.set_pos then
            local mouse_pos = imgui.GetMousePos()
            elements.radar.pos.x = mouse_pos.x - elements.radar.set_pos_offset.x
            elements.radar.pos.y = mouse_pos.y - elements.radar.set_pos_offset.y
        end
        draw_points = {}
        local b_dl = imgui.GetBackgroundDrawList()
        local X1, Y1, Z1 = getActiveCameraCoordinates()
        local X2, Y2, Z2 = getActiveCameraPointAt()
        local cameraAngle = -math.atan2(X1 - X2, Y1 - Y2) - math.pi
        local cam_sin = math.sin(cameraAngle)
        local cam_cos = math.cos(cameraAngle)
        local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
        if not isSampfuncsLoaded() or not isSampLoaded() or not isSampAvailable() then return end
        for id = 0, 2048 do
            if sampIs3dTextDefined(id) then
                local text, color, posX, posY, posZ, distance, ignore_walls, player, veh = sampGet3dTextInfoById(id)
                if text:find(u8("\xD1\xF0\xF3\xE1\xE8\xF2\xFC \xE4\xE5\xF0\xE5\xE2\xEE")) then 
                    local dps = worldToRadarCenterOffset(posX, posY, pX, pY, cVARS.radar_zoom[0], cVARS.radar_size[0])
                    dps = rotatePoint(dps, iv2(0, 0), cam_cos, cam_sin)
                    dps.x = dps.x < -cVARS.radar_size[0] / 2 and -cVARS.radar_size[0] / 2 or dps.x
                    dps.x = dps.x > cVARS.radar_size[0] / 2 and cVARS.radar_size[0] / 2 or dps.x
                    dps.y = dps.y < -cVARS.radar_size[0] / 2 and -cVARS.radar_size[0] / 2 or dps.y
                    dps.y = dps.y > cVARS.radar_size[0] / 2 and cVARS.radar_size[0] / 2 or dps.y
                    table.insert(draw_points, iv2(dps.x + elements.radar.pos.x, dps.y + elements.radar.pos.y))
                end
            end
        end 

    end,
    function (player)
        local b_dl = imgui.GetBackgroundDrawList()
        b_dl:AddRectFilled(
            iv2(elements.radar.pos.x - cVARS.radar_size[0] / 2, elements.radar.pos.y - cVARS.radar_size[0] / 2),
            iv2(elements.radar.pos.x + cVARS.radar_size[0] / 2, elements.radar.pos.y + cVARS.radar_size[0] / 2),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.0, 0.0, 0.0, 0.5)), 10
        )
        b_dl:AddLine(iv2(elements.radar.pos.x, elements.radar.pos.y - cVARS.radar_size[0] / 2), iv2(elements.radar.pos.x, elements.radar.pos.y + cVARS.radar_size[0] / 2), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 0.5)), 1)
        b_dl:AddLine(iv2(elements.radar.pos.x - cVARS.radar_size[0] / 2, elements.radar.pos.y), iv2(elements.radar.pos.x + cVARS.radar_size[0] / 2, elements.radar.pos.y), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, 0.5)), 1)
        if elements.radar.set_pos then
            imgui.PushFont(fonts[48])
            local text_size = imgui.CalcTextSize(ti.ICON_ARROWS_MOVE)
            b_dl:AddText(iv2(elements.radar.pos.x - text_size.x / 2, elements.radar.pos.y - text_size.y / 3), 0xFFFFFFFF, ti.ICON_ARROWS_MOVE)
            imgui.PopFont()
        end

        for k, v in pairs(draw_points) do
            b_dl:AddCircleFilled(v, 4, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.21, 0.21, 0.21, 1)), 16)
            b_dl:AddCircleFilled(v, 3, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.37, 1, 0.27, 1)), 16)
        end
    end
)

function rotatePoint(p, o, c, s)
    return iv2(
        (c * (p.x - o.x) - s * (p.y - o.y)) + o.x,
        (s * (p.x - o.x) + c * (p.y - o.y)) + o.y
    )
end

function worldToRadarCenterOffset(pos_x, pos_y, pX, pY, zoom, radar_radius)
    return iv2(((pos_x - pX) / (3000 / zoom)) * radar_radius, ((pY - pos_y) / (3000 / zoom)) * radar_radius)
end

-- length: optional explicit width; nil = full available region
function GraySeparator(thickness, padding, length)
    local dl = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()
    local avail_w = length or imgui.GetContentRegionAvail().x
    local line_color = imgui.GetColorU32Vec4(imgui.ImVec4(0.7, 0.7, 0.7, 1))
    local line_thickness = thickness or 2
    local line_padding = padding or 5
    dl:AddLine(
        imgui.ImVec2(p.x, p.y),
        imgui.ImVec2(p.x + avail_w, p.y),
        line_color,
        line_thickness
    )
    imgui.SetCursorScreenPos(imgui.ImVec2(p.x, p.y + line_thickness + line_padding))
end

function syncToggleButton(id, state)
    if elements.custom.toggle_button[id] then
        local btn = elements.custom.toggle_button[id]
        btn.progress = state and 1 or 0
        btn.back = state
        btn.anim = false
    end
end

function clp(text,width)
    if imgui.BeginChild(text, imgui.ImVec2(width,27), false,imgui.WindowFlags.NoScrollbar) then
        qwe = imgui.CollapsingHeader(text)
        imgui.EndChild()
    end
    return qwe
end

-- ====== Content fade animation (ported from Saw_v1_8_1_stable) ======
content_display_tab  = nil
content_target_tab   = nil
content_anim         = 1.0
content_slide_offset = 0.0
content_panel_alpha_multiplier = 1.0

local content_fade_color_ids = {
    imgui.Col.Text,
    imgui.Col.TextDisabled,
    imgui.Col.FrameBg,
    imgui.Col.FrameBgHovered,
    imgui.Col.FrameBgActive,
    imgui.Col.CheckMark,
    imgui.Col.SliderGrab,
    imgui.Col.SliderGrabActive,
    imgui.Col.Button,
    imgui.Col.ButtonHovered,
    imgui.Col.ButtonActive,
    imgui.Col.Header,
    imgui.Col.HeaderHovered,
    imgui.Col.HeaderActive,
    imgui.Col.Separator,
    imgui.Col.Border,
}

function push_content_style_alpha(alpha)
    local style = imgui.GetStyle and imgui.GetStyle()
    if not style or not style.Colors then return 0 end
    local pushed = 0
    for _, color_id in ipairs(content_fade_color_ids) do
        local ok, color = pcall(function() return style.Colors[color_id] end)
        if ok and color then
            local ok2 = pcall(function()
                imgui.PushStyleColor(color_id, iv4(color.x, color.y, color.z, color.w * alpha))
            end)
            if ok2 then pushed = pushed + 1 end
        end
    end
    return pushed
end

function request_sidebar_tab(tab)
    if tab == nil then return end
    if selected_tab == nil then selected_tab = tab end
    if content_display_tab == nil then content_display_tab = tab end
    if tab == selected_tab and content_target_tab == nil and content_display_tab == tab then return end
    selected_tab = tab
    if content_display_tab == tab and content_target_tab == nil then
        content_anim = 1.0; content_slide_offset = 0.0; return
    end
    content_target_tab = tab
end

function update_content_transition(dt)
    if content_display_tab == nil then content_display_tab = selected_tab end
    local fade_out_speed = math.min(dt * 10.5, 1.0)
    local fade_in_speed  = math.min(dt * 11.5, 1.0)
    if content_target_tab ~= nil then
        if content_display_tab ~= content_target_tab and content_anim > 0.02 then
            content_anim = math.max(0.0, content_anim - fade_out_speed)
        else
            if content_display_tab ~= content_target_tab then
                content_display_tab = content_target_tab
            end
            content_anim = math.min(1.0, content_anim + fade_in_speed)
            if content_anim >= 0.999 then content_anim = 1.0; content_target_tab = nil end
        end
    else
        content_anim = math.min(1.0, content_anim + fade_in_speed)
    end
    local eased = content_anim * content_anim * (3.0 - 2.0 * content_anim)
    content_slide_offset = (1.0 - eased) * 10.0
    return eased
end
-- ====== end content fade ======

imgui.OnFrame(function() return cVARS.menu[0] end,
    function(self)
        imgui.SetNextWindowSize(iv2(1500, 900), imgui.Cond.FirstUseEver)
        local overlay_dl = imgui.GetBackgroundDrawList()
        overlay_dl:AddRectFilled(
            iv2(0, 0),
            iv2(getScreenResolution()),
            conv_c(iv4(0.0, 0.0, 0.0, 0.45))
        )
        if cVARS.menu_movable[0] then
            local pos_x = cVARS.menu_pos_x[0]
            local pos_y = cVARS.menu_pos_y[0]
            if pos_x == 0 or pos_y == 0 then
                local scrW, scrH = getScreenResolution()
                pos_x = (scrW - 1500) / 2
                pos_y = (scrH - 800) / 2
            end
            imgui.SetNextWindowPos(iv2(pos_x, pos_y), imgui.Cond.Appearing)
        else
            local scrW, scrH = getScreenResolution()
            imgui.SetNextWindowPos(iv2((scrW - 1500) / 2, (scrH - 800) / 2), imgui.Cond.Always)
        end
        
        imgui.PushStyleColor(imgui.Col.WindowBg, iv4(0, 0, 0, 0))
        imgui.Begin(u8("Leso\xD0\xF3\xE1 \xE1\xEE\xF2##main"), cVARS.menu, imgui.WindowFlags.NoTitleBar)
        local outline_color = conv_c(iv4(0.3, 0.9, 0.3, 1.0))
        local outline_thickness = 3.0
        local dl = imgui.GetWindowDrawList()
        local win_pos = imgui.GetWindowPos()
        local win_size = imgui.GetWindowSize()

        local tri_top = iv2(win_pos.x + 800, win_pos.y + 100)
        local tri_bl  = iv2(win_pos.x + 225, win_pos.y + 750+75)
        local tri_br  = iv2(win_pos.x + 1375, win_pos.y + 750+75)
        if not menu_open_time then menu_open_time = os.clock() end
        if content_display_tab == nil then content_display_tab = selected_tab end
        local anim_elapsed = os.clock() - menu_open_time
        local anim_t = math.min(anim_elapsed / menu_anim_duration, 1.0)
        local ease = 1.0 - (1.0 - anim_t)^3
        local clip_top = win_pos.y - 50
        local clip_bot = win_pos.y + win_size.y * ease + 50
        local clip_left = win_pos.x - 100
        local clip_right = win_pos.x + win_size.x + 100
        dl:PushClipRect(iv2(clip_left, clip_top), iv2(clip_right, clip_bot), false)
        dl:AddTriangleFilled(tri_top, tri_bl, tri_br, conv_c(iv4(0.06, 0.06, 0.06, 0.95)))
        local base_vec_x = tri_bl.x - tri_br.x
        local base_vec_y = tri_bl.y - tri_br.y
        local base_len   = math.sqrt(base_vec_x^2 + base_vec_y^2)
        local bx  = base_vec_x / base_len
        local by  = base_vec_y / base_len
        local bnx = -by
        local bny = bx
        local push_inside   = 117
        local push_inside1  = 10
        local rect_length   = 12
        local rect_width    = 50
        local r2_slant      = 1
        local r23_angle     = 288
        local r3_height     = 71
        local r1 = iv2(tri_bl.x + bx * push_inside, tri_bl.y + by * push_inside)
        local r2 = iv2(tri_bl.x - bx * (rect_length - push_inside1) + bnx * r2_slant,
                    tri_bl.y - by * (rect_length - push_inside1) + bny * r2_slant)
        local r4 = iv2(tri_bl.x + bnx * rect_width, tri_bl.y + bny * rect_width)
        local side_len = math.sqrt((r4.x - r1.x)^2 + (r4.y - r1.y)^2)
        local ca = math.cos(math.rad(r23_angle))
        local sa = math.sin(math.rad(r23_angle))
        local dx = side_len * ca
        local dy = side_len * sa
        local r3 = iv2(r2.x + dx, r2.y + dy + r3_height)
        dl:AddQuadFilled(r1, r2, r3, r4, conv_c(iv4(0.06, 0.06, 0.06, 0.95)))
        local edge_vec_x = tri_top.x - tri_bl.x
        local edge_vec_y = tri_top.y - tri_bl.y
        local edge_len = math.sqrt(edge_vec_x^2 + edge_vec_y^2)
        local ex = edge_vec_x / edge_len
        local ey = edge_vec_y / edge_len
        local nx = ey
        local ny = -ex
        local strip_width = 48
        local strip_length = edge_len - 60
        local top_y = math.min(r1.y + ey * strip_length, r4.y + ey * strip_length)
        local side_offset = 40
        local p1 = r1
        local p4 = r4
        local p2 = iv2(p1.x + ex * strip_length + side_offset, top_y)
        local p3 = iv2(p4.x + ex * strip_length, top_y)
        dl:AddQuadFilled(p1, p2, p3, p4, conv_c(iv4(0.06, 0.06, 0.06, 0.95)))
        local outline = { tri_top, tri_br, r2, r1, p1, p2, p3, p4, r3 }
        for i = 1, #outline do
            local a = outline[i]
            local b = outline[(i % #outline) + 1]
            dl:AddLine(a, b, outline_color, outline_thickness)
        end
        local float_gap = 17
        local utop_top = iv2(tri_top.x - 57, tri_top.y - float_gap - 55)
        local utop_bl  = iv2(p2.x, tri_top.y - float_gap)
        local utop_br  = iv2(tri_top.x, tri_top.y - float_gap)
        dl:AddTriangleFilled(utop_top, utop_bl, utop_br, conv_c(iv4(0.06, 0.06, 0.06, 0.95)))
        dl:AddTriangle(utop_top, utop_bl, utop_br, conv_c(iv4(0.3, 0.9, 0.3, 1.0)), 3.0)
        dl:AddLine(utop_bl, utop_br, conv_c(iv4(0.3, 0.9, 0.3, 1.0)), 3.0)
        local close_btn_size = iv2(30, 30)
        local tri_center_x = (utop_top.x + utop_bl.x + utop_br.x) / 3
        local tri_center_y = (utop_top.y + utop_bl.y + utop_br.y) / 3
        local close_pos = iv2(
            tri_center_x - close_btn_size.x / 2,
            tri_center_y - close_btn_size.y / 2
        )
        imgui.SetCursorScreenPos(close_pos)
        imgui.PushStyleColor(imgui.Col.Button,        iv4(0.0, 0.0, 0.0, 0.0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, iv4(0.0, 0.0, 0.0, 0.05))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  iv4(0.0, 0.0, 0.0, 0.1))
        if imgui.Button("##close_btn", close_btn_size) then
            cVARS.menu[0] = false
            save_cfg()
        end
        local is_hovered = imgui.IsItemHovered()
        imgui.PopStyleColor(3)
        close_spin = close_spin or 0.0
        local spin_speed = 720.0
        if is_hovered then
            close_spin = math.min(close_spin + spin_speed * imgui.GetIO().DeltaTime, 360.0)
        else
            close_spin = math.max(close_spin - spin_speed * 2.0 * imgui.GetIO().DeltaTime, 0.0)
        end
        local dl = imgui.GetWindowDrawList()
        local icon_size = 18
        local half = icon_size * 0.5
        local center = iv2(
            close_pos.x + close_btn_size.x * 0.5,
            close_pos.y + close_btn_size.y * 0.5
        )
        local angle_rad = close_spin * (math.pi / 180.0)
        local function rotate_point(px, py)
            local dx = px - center.x
            local dy = py - center.y
            local rx = dx * math.cos(angle_rad) - dy * math.sin(angle_rad)
            local ry = dx * math.sin(angle_rad) + dy * math.cos(angle_rad)
            return center.x + rx, center.y + ry
        end
        local thickness = 3.5
        local col = conv_c(iv4(1.0, 1.0, 1.0, 1.0))
        local x1, y1 = rotate_point(center.x - half, center.y - half)
        local x2, y2 = rotate_point(center.x + half, center.y + half)
        dl:AddLine(iv2(x1, y1), iv2(x2, y2), col, thickness)
        local x3, y3 = rotate_point(center.x + half, center.y - half)
        local x4, y4 = rotate_point(center.x - half, center.y + half)
        dl:AddLine(iv2(x3, y3), iv2(x4, y4), col, thickness)
        local start_pos = iv2(r3.x, r3.y)
        local end_pos = iv2(tri_br.x-40,tri_br.y-51)
        local outline_color = conv_c(iv4(0.3, 0.9, 0.3, 1.0))
        local outline_thickness = 3.0
        dl:AddLine(start_pos, end_pos, outline_color, outline_thickness)
        dl:AddLine(start_pos, end_pos, outline_color, outline_thickness)
        local recent_line_y = end_pos.y + 18
        local recent_line_x_start = start_pos.x
        local recent_line_x_end = end_pos.x
        local scroll_text = u8("\xCF\xEE\xE4\xEF\xE8\xF8\xE8\xF1\xFC \xEF\xE6 \xED\xE0 \xEC\xEE\xE9 \xF2\xE3\xEA ")
        local scroll_speed = 40.0
        local scroll_width = 280
        local scroll_x_base = recent_line_x_start + 5
        local scroll_clip_end = scroll_x_base + scroll_width
        if not _scroll_offset then _scroll_offset = 0 end
        _scroll_offset = (_scroll_offset + scroll_speed * imgui.GetIO().DeltaTime) % scroll_width
        imgui.PushFont(fonts[12])
        local text_color = conv_c(iv4(0.3, 1.0, 0.3, 1.0))
        dl:PushClipRect(iv2(scroll_x_base, recent_line_y), iv2(scroll_clip_end, recent_line_y + 20), true)
        dl:AddText(iv2(scroll_x_base - _scroll_offset+10, recent_line_y + 3), text_color, scroll_text)
        dl:AddText(iv2(scroll_x_base - _scroll_offset + scroll_width+10, recent_line_y + 3), text_color, scroll_text)
        dl:PopClipRect()
        imgui.PopFont()

        -- Ð¼Ð¸Ð³Ð°ÑÑÐ°Ñ ÐºÐ½Ð¾Ð¿ÐºÐ° Ð¿Ð¾Ð´Ð¿Ð¸ÑÐºÐ¸ Ð½Ð° ÑÐ³Ðº
        if not _tgk_blink_t then _tgk_blink_t = 0 end
        _tgk_blink_t = _tgk_blink_t + imgui.GetIO().DeltaTime
        local blink_alpha = 0.55 + 0.45 * math.sin(_tgk_blink_t * 5.0)
        local blink_border = 0.6 + 0.4 * math.sin(_tgk_blink_t * 5.0)
        local tgk_btn_w = 140
        local tgk_btn_h = 20
        local tgk_btn_x = scroll_clip_end + 6
        local tgk_btn_y = recent_line_y
        dl:AddRectFilled(
            iv2(tgk_btn_x, tgk_btn_y),
            iv2(tgk_btn_x + tgk_btn_w, tgk_btn_y + tgk_btn_h),
            conv_c(iv4(0.07, 0.45 * blink_alpha, 0.07, blink_alpha)),
            4
        )
        dl:AddRect(
            iv2(tgk_btn_x, tgk_btn_y),
            iv2(tgk_btn_x + tgk_btn_w, tgk_btn_y + tgk_btn_h),
            conv_c(iv4(0.2, blink_border, 0.2, blink_border)),
            4, nil, 1.5
        )
        imgui.PushFont(fonts[12])
        local tgk_label = u8("\xcf\xee\xe4\xef\xe8\xf8\xe8\xf1\xfc \xed\xe0 \xf2\xe3\xea!")
        local tgk_sz = imgui.CalcTextSize(tgk_label)
        local tgk_text_x = tgk_btn_x + (tgk_btn_w - tgk_sz.x) * 0.5
        local tgk_text_y = tgk_btn_y + (tgk_btn_h - tgk_sz.y) * 0.5
        dl:AddText(iv2(tgk_text_x, tgk_text_y), conv_c(iv4(0.6 + 0.4 * blink_alpha, 1.0, 0.6 + 0.4 * blink_alpha, 1.0)), tgk_label)
        imgui.PopFont()
        imgui.SetCursorScreenPos(iv2(tgk_btn_x, tgk_btn_y))
        imgui.PushStyleColor(imgui.Col.Button,        iv4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, iv4(0.2, 0.6, 0.2, 0.15))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  iv4(0.3, 0.8, 0.3, 0.25))
        if imgui.Button("##tgk_sub_btn", iv2(tgk_btn_w, tgk_btn_h)) then
            os.execute('start https://t.me/flupiflufi')
        end
        imgui.PopStyleColor(3)

        local tab_x_start = scroll_clip_end + tgk_btn_w + 12 + 370
        local tab_y = recent_line_y
        local tab_h = 20
        local tab_pad_x = 8
        imgui.PushFont(fonts[12])
        local recent_tabs = {}
        if not _recent_tabs then _recent_tabs = {} end
        if _last_selected_tab ~= selected_tab then
            _last_selected_tab = selected_tab
            for i, t in ipairs(_recent_tabs) do
                if t == selected_tab then table.remove(_recent_tabs, i) break end
            end
            table.insert(_recent_tabs, 1, selected_tab)
            if #_recent_tabs > 5 then table.remove(_recent_tabs) end
        end
        local cur_tab_x = tab_x_start
        for i, tab_name in ipairs(_recent_tabs) do
            local is_cur = (tab_name == selected_tab)
            local text_sz = imgui.CalcTextSize(tab_name)
            local tw = text_sz.x + tab_pad_x * 2
            local tx1 = cur_tab_x
            local tx2 = cur_tab_x + tw
            if tx2 > recent_line_x_end - 5 then break end
            local bg_col = is_cur and conv_c(iv4(0.2, 0.7, 0.2, 0.4)) or conv_c(iv4(0.1, 0.1, 0.1, 0.6))
            local border_col = is_cur and conv_c(iv4(0.3, 0.9, 0.3, 1.0)) or conv_c(iv4(0.3, 0.3, 0.3, 0.8))
            local txt_col = is_cur and conv_c(iv4(0.4, 1.0, 0.4, 1.0)) or conv_c(iv4(0.7, 0.7, 0.7, 1.0))
            dl:AddRectFilled(iv2(tx1, tab_y), iv2(tx2, tab_y + tab_h), bg_col, 3)
            dl:AddRect(iv2(tx1, tab_y), iv2(tx2, tab_y + tab_h), border_col, 3, nil, 1.0)
            dl:AddText(iv2(tx1 + tab_pad_x, tab_y + 3), txt_col, tab_name)
            cur_tab_x = tx2 + 4
        end
        imgui.PopFont()
        local buttons = {
            {name = u8("\xC3\xEB\xE0\xE2\xED\xE0\xFF"),     icon = ti.ICON_TREES},
            {name = u8("\xD1\xE5\xF2\xF2\xE8\xED\xE3"),  icon = ti.ICON_SETTINGS},
            {name = u8("Telegram"),    icon = ti.ICON_BRAND_TELEGRAM},
            {name = u8("\xC0\xED\xF2\xE8\xE0\xE4\xEC"),   icon = ti.ICON_SHIELD_OFF},
            {name = u8("\xC0\xED\xF2\xE8-\xC5\xE4\xE0"),    icon = ti.ICON_TOOLS_KITCHEN_2},
            {name = u8("\xC0\xED\xF2\xE8\xE1\xEE\xF2"),     icon = ti.ICON_ROBOT_OFF},
            {name = u8("\xD1\xF2\xE0\xF2\xE0"),  icon = ti.ICON_PRESENTATION},
            {name = u8("\xC3\xE0\xE9\xE4\xFB"),  icon = ti.ICON_BOOK_2}
        }

        local edge_vec_x2 = tri_top.x - tri_bl.x
        local edge_vec_y2 = tri_top.y - tri_bl.y
        local edge_len2 = math.sqrt(edge_vec_x2^2 + edge_vec_y2^2)
        local strip_length2 = edge_len2 - 20
        local base_offset = 0
        local btn_step = (strip_length2 - base_offset) / (#buttons + 1)
        local btn_offset_into_strip = strip_width / 2
        local nav_offset = 37
        local base_x = tri_bl.x + nx * nav_offset
        local base_y = tri_bl.y + ny * nav_offset

        --[[
        local block_x = tri_bl.x + 45
        local block_y = tri_bl.y - 165
        local block_width = 220
        local block_height = 140

        dl:AddRectFilled(iv2(block_x, block_y), iv2(block_x + block_width, block_y + block_height), conv_c(iv4(0.08, 0.08, 0.08, 0.92)), 6)
        dl:AddRect(iv2(block_x, block_y), iv2(block_x + block_width, block_y + block_height), conv_c(iv4(0.3, 0.9, 0.3, 1)), 6, nil, 2)

        imgui.SetCursorPos(iv2(block_x - win_pos.x + 20, block_y - win_pos.y + 15))
        imgui.PushFont(fonts[18])
        imgui.TextColored(iv4(0.4, 1.0, 0.4, 1), u8"BlastHack: flupiflufi")
        imgui.PopFont()

        local sub_line_y = block_y + 38
        local line_sub_start = block_x + 20
        local line_sub_length = block_width - 40

        for i = 0, line_sub_length, 3 do
            local phase = (i - gradient_offset * 1.3) % line_sub_length
            if phase < 0 then phase = phase + line_sub_length end
            local t = phase / line_sub_length
            local green = 0.45 + 0.55 * (math.sin(t * math.pi * 4) * 0.5 + 0.5)
            dl:AddRectFilled(
                iv2(line_sub_start + i, sub_line_y),
                iv2(line_sub_start + i + 3, sub_line_y + 3),
                conv_c(iv4(0.3, green, 0.3, 1))
            )
        end

        imgui.SetCursorPos(iv2(block_x - win_pos.x + 20, block_y - win_pos.y + 55))
        imgui.Text(u8"https://t.me/flupiflufi")

        imgui.SetCursorPos(iv2(block_x - win_pos.x + 20, block_y - win_pos.y + 78))
        imgui.Text(u8"KOTACBAS Verified")

        imgui.SetCursorPos(iv2(block_x - win_pos.x + 20, block_y - win_pos.y + 105))

        imgui.PushStyleColor(imgui.Col.Button,        iv4(0.18, 0.5, 0.18, 1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, iv4(0.23, 0.65, 0.23, 1))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  iv4(0.28, 0.75, 0.28, 1))
        imgui.PushStyleColor(imgui.Col.Text,          iv4(1.0, 1.0, 1.0, 1))

        if imgui.Button(u8"Ïåðåéòè â òãê", iv2(block_width - 40, 28)) then
            os.execute('start https://t.me/flupiflufi')
        end

        imgui.PopStyleColor(4)
        ]]

        local function tri_x_at_y(abs_y)
            local t_top = tri_top.y
            local t_bot = tri_bl.y
            local t = (abs_y - t_top) / (t_bot - t_top)
            t = math.max(0, math.min(1, t))
            local lx = tri_top.x + (tri_bl.x - tri_top.x) * t
            local rx = tri_top.x + (tri_br.x - tri_top.x) * t
            return lx, rx
        end

        local c_margin_nav   = 165
        local c_margin_right = 30
        local c_margin_top   = 100
        local c_margin_bot   = 40
        local c_inner_pad    = 18
        local content_abs_y_start = tri_top.y + c_margin_top
        local content_abs_y_end   = tri_bl.y  - c_margin_bot
        local lx_bot, rx_bot = tri_x_at_y(content_abs_y_end)
        local child_w = (rx_bot - lx_bot) - c_margin_nav - c_margin_right+350
        local child_h = content_abs_y_end - content_abs_y_start+100
        local child_abs_x = lx_bot + c_margin_nav
        local child_abs_y = content_abs_y_start
        imgui.SetCursorPos(iv2(child_abs_x - win_pos.x-250, child_abs_y - win_pos.y-100))
        imgui.BeginChild("##content", iv2(child_w, child_h), false, imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoScrollWithMouse)
        local child_pos = imgui.GetWindowPos()
        for i = #buttons, 1, -1 do
            local btn = buttons[i]
            local idx = #buttons - i + 1
            local is_selected = (selected_tab == btn.name)
            local dist = base_offset + btn_step * idx
            local btn_x = base_x + ex * dist + nx * btn_offset_into_strip
            local btn_y = base_y + ey * dist + ny * btn_offset_into_strip
            local cursor_x = btn_x - child_pos.x - 19
            local cursor_y = btn_y - child_pos.y - 19
            imgui.SetCursorPos(iv2(cursor_x, cursor_y))
            imgui.PushStyleColor(imgui.Col.Button,        iv4(0, 0, 0, 0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, iv4(0,0,0,0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  iv4(0,0,0,0))
            local icon_color = is_selected and iv4(0.4, 1.0, 0.4, 1) or iv4(0.65, 0.65, 0.65, 1)
            imgui.PushStyleColor(imgui.Col.Text, icon_color)
            imgui.PushFont(fonts[20])
            if imgui.Button(btn.icon .. "##nav" .. idx, iv2(38, 38)) then
                if selected_tab ~= btn.name then
                    request_sidebar_tab(btn.name)
                    btn_animation_start = os.clock()
                end
            end
            imgui.PopFont()
            if imgui.IsItemHovered() then
                imgui.PushFont(fonts[16])
                imgui.BeginTooltip()
                imgui.PushTextWrapPos(450.0)
                imgui.TextUnformatted(btn.name)
                imgui.PopTextWrapPos()
                imgui.EndTooltip()
                imgui.PopFont()
                local w = 78
                local h = 38
                local skew = -15
                local p1 = iv2(btn_x - w/2 - skew, btn_y - h/2)
                local p2 = iv2(btn_x + w/2 - skew, btn_y - h/2)
                local p3 = iv2(btn_x + w/2 + skew, btn_y + h/2)
                local p4 = iv2(btn_x - w/2 + skew, btn_y + h/2)
                local col_fill = conv_c(iv4(0.0, 0.75, 0.0, 0.15))
                local col_line = conv_c(iv4(0.0, 0.75, 0.0, 0.85))
                local thick = 2.5
                dl:AddTriangleFilled(p1, p2, p3, col_fill)
                dl:AddTriangleFilled(p1, p3, p4, col_fill)
                dl:AddLine(p1, p2, col_line, thick)
                dl:AddLine(p4, p3, col_line, thick)
            end
            if is_selected then
                    local w = 78
                    local h = 38
                    local skew = -15
                    local p1 = iv2(btn_x - w/2 - skew, btn_y - h/2)
                    local p2 = iv2(btn_x + w/2 - skew, btn_y - h/2)
                    local p3 = iv2(btn_x + w/2 + skew, btn_y + h/2)
                    local p4 = iv2(btn_x - w/2 + skew, btn_y + h/2)
                    local col_fill = conv_c(iv4(0.0, 1.0, 0.0, 0.2))
                    local col_line = conv_c(iv4(0.0, 1.0, 0.0, 1.0))
                    local thick = 2.5
                    dl:AddTriangleFilled(p1, p2, p3, col_fill)
                    dl:AddTriangleFilled(p1, p3, p4, col_fill)
                    local stripe_h = 10
                    local speed = 150
                    if btn_animation_start then
                        local elapsed = os.clock() - btn_animation_start
                        local progress = elapsed * speed / h
                        if progress <= 1.08 then
                            local y_top = btn_y - h/2
                            local stripe_cy = y_top + h * math.min(progress, 1.0)
                            for i = 0, h - 1 do
                                local row_y = y_top + i
                                if math.abs(row_y - stripe_cy) < stripe_h / 2 then
                                    local row_t = i / (h - 1)
                                    local left_x  = p1.x + (p4.x - p1.x) * row_t
                                    local right_x = p2.x + (p3.x - p2.x) * row_t
                                    local fade = 1.0 - math.abs(row_y - stripe_cy) / (stripe_h / 2)
                                    local alpha = 0.65 * fade
                                    dl:AddRectFilled(
                                        iv2(left_x, row_y),
                                        iv2(right_x, row_y + 1),
                                        conv_c(iv4(1.0, 1.0, 1.0, alpha))
                                    )
                                end
                            end
                        end
                    end
                    dl:AddLine(p1, p2, col_line, thick)
                    dl:AddLine(p4, p3, col_line, thick)
                end

            imgui.PopStyleColor(4)
        end
        local child_dl   = imgui.GetWindowDrawList()
        local child_pos  = imgui.GetWindowPos()
        local function pyramid_cursor_x(extra_pad)
            extra_pad = extra_pad or 0
            local cur_y_abs = child_pos.y + imgui.GetCursorPosY()
            local lx, rx = tri_x_at_y(cur_y_abs)
            local indent = (lx - child_pos.x) + c_inner_pad + extra_pad - 12
            return math.max(c_inner_pad + extra_pad - 12, indent)
        end
        local function pyramid_width(extra_pad)
            extra_pad = extra_pad or 0
            local cur_y_abs = child_pos.y + imgui.GetCursorPosY()
            local lx, rx = tri_x_at_y(cur_y_abs)
            local available = (rx - c_margin_right) - (lx + c_margin_nav + c_inner_pad + extra_pad) - child_pos.x
            return math.max(50, available)
        end
        local function pyramid_cursor_x1(extra_pad)
            extra_pad = extra_pad or 0
            local cur_y_abs = child_pos.y + imgui.GetCursorPosY()
            local lx, rx = tri_x_at_y(cur_y_abs)
            local indent_from_right = (rx - child_pos.x) - c_margin_right - c_inner_pad - extra_pad
            return math.max(c_inner_pad + extra_pad, indent_from_right)
        end
        local function pyramid_width1(extra_pad)
            extra_pad = extra_pad or 0
            local cur_y_abs = child_pos.y + imgui.GetCursorPosY()
            local lx, rx = tri_x_at_y(cur_y_abs)
            local available = (rx - c_margin_right - c_inner_pad - extra_pad) 
                            - (lx + c_margin_nav + c_inner_pad) 
                            - child_pos.x
            return math.max(50, available)
        end

        imgui.SetCursorPosX(pyramid_cursor_x(12))
        imgui.PushFont(fonts[22] or fonts[20])
        imgui.Text(selected_tab)
        imgui.PopFont()
        imgui.Spacing()

        -- content fade animation
        local _dt = imgui.GetIO().DeltaTime
        if _dt <= 0 then _dt = 1/60 end
        local content_alpha = update_content_transition(_dt)
        local content_render_alpha = math.max(0.0, math.min(1.0, content_alpha))
        content_panel_alpha_multiplier = content_render_alpha
        local _content_style_pushed = push_content_style_alpha(content_render_alpha)
        local _slide_pos = imgui.GetCursorPos()
        imgui.SetCursorPos(iv2(_slide_pos.x, _slide_pos.y + content_slide_offset))

        imgui.PushFont(fonts[16])

        if content_display_tab == u8("\xC3\xEB\xE0\xE2\xED\xE0\xFF") then
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 8)
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PillButton(ti.ICON_TREES .. u8(" \xC1\xEE\xF2 \xE4\xE5\xF0\xE5\xE2\xE0"), cVARS.bot, 0.15)

            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PillButton(ti.ICON_RADAR .. u8(" \xD0\xE0\xE4\xE0\xF0"), cVARS.radar, 0.15)

            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PillButton(ti.ICON_VECTOR_OFF .. u8(" \xD2\xF0\xE0\xF1\xE5\xF0\xFB"), cVARS.tracers, 0.15)

            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PillButton(ti.ICON_BUG .. u8(" Debug"), cVARS.debug, 0.15)

            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushItemWidth(math.min(200))
            imgui.SliderInt(ti.ICON_RULER_2 .. u8(" \xD0\xE0\xE7\xEC\xE5\xF0 \xF0\xE0\xE4\xE0\xF0\xE0"), cVARS.radar_size, 100, 500)
            imgui.PopItemWidth()
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushItemWidth(math.min(290))
            imgui.SliderInt(ti.ICON_RULER_2 .. u8(" \xC7\xF3\xEC \xF0\xE0\xE4\xE0\xF0\xE0"), cVARS.radar_zoom, 5, 100)
            imgui.PopItemWidth()
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushItemWidth(50)
            if clp(u8("\xC4\xEE\xEF.\xF4\xF3\xED\xEA\xF6\xE8\xE8"),480) then
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.PillButton(u8("\xD1\xEA\xE8\xED CJ"), cVARS.cjSkin, 0.15) then
                    local skinNow = getCharModel(PLAYER_PED)
                    if cVARS.cjSkin[0] and sampGetGamestate() == 3 and skinNow ~= 74 then
                        set_player_skin(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), 74)
                    else
                        set_player_skin(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), config.defoltSkin or 0)
                    end
                    config.cjSkin = cVARS.cjSkin[0]
                end
                imgui.SameLine()
                imgui.SetCursorPosX(pyramid_cursor_x1(120))
                imgui.Text(u8("\xCD\xE0 \xEE\xE1\xFA\xE5\xEA\xF2\xFB"))
                imgui.SameLine(pyramid_cursor_x1(30))
                if imgui.Button(ti.ICON_SETTINGS .. "##ObjSettingsBtn", imgui.ImVec2(28, 28)) then
                    objectsettngs[0] = true
                    imgui.OpenPopup("##object_popup")
                end
                local object_popup_open = new.bool(true)
                if imgui.BeginPopupModal("##object_popup", object_popup_open, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize) then
                    imgui.SetCursorPosX(10)
                    imgui.PillButton(u8(" \xCD\xE0 \xE2\xF1\xE5 \xEE\xE1\xFA\xE5\xEA\xF2\xFB"), object, 0.15)
                    imgui.PillButton(u8(" \xD2\xEE\xEB\xFC\xEA\xEE \xED\xE0 \xEF\xED\xE8"), objectpen, 0.15)
                    imgui.PillButton(u8(" \xCD\xE5 \xE2\xEA\xEB\xFE\xF7\xE0\xF2\xFC \xED\xE0 \xE4\xE5\xF0\xE5\xE2\xFC\xFF"), objectnotree, 0.15)
                    if imgui.Button(u8("\xC2\xFB\xEA\xEB\xFE\xF7\xE8 \xE5\xE3\xEE \xED\xE0\xF5\xF3\xE9"), iv2(340, 45)) then
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                imgui.PillButton(u8("\xD3\xF1\xEA\xEE\xF0\xE5\xED\xE8\xE5 \xE0\xED\xE8\xEC\xE0\xF6\xE8\xE9"), cVARS.animspeed_enabled, 0.15)
                if cVARS.animspeed_enabled[0] then
                    imgui.SetCursorPosX(pyramid_cursor_x(10))
                    imgui.PushItemWidth(200)
                    imgui.SliderFloat(u8("\xD1\xEA\xEE\xF0\xEE\xF1\xF2\xFC \xE0\xED\xE8\xEC\xE0\xF6\xE8\xE9"), cVARS.animspeed_value, 0.1, 10.0)
                    imgui.PopItemWidth()
                end
                imgui.SameLine()
                imgui.SetCursorPosX(pyramid_cursor_x1(130))
                imgui.PillButton(u8("\xCD\xE0 \xEC\xE0\xF8\xE8\xED\xFB"), vehicle, 0.15)
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                imgui.PillButton(u8("\xC1\xE5\xF1\xEF\xE0\xEB\xE5\xE2\xED\xFB\xE9 \xE1\xE5\xE3 CJ"), cVARS.runskincj, 0.15)
                imgui.SameLine() imgui.ShowHelpMarker(u8("\xC2\xFB\xE4\xE0\xF1\xF2 \xE1\xE5\xE3 \xF1\xE8\xE4\xE6\xE5\xFF \xED\xE0 \xEB\xFE\xE1\xEE\xE9 \xF1\xEA\xE8\xED"))
                imgui.SameLine()
                imgui.SetCursorPosX(pyramid_cursor_x1(140))
                imgui.PillButton(u8(" \xCD\xE0 \xE8\xE3\xF0\xEE\xEA\xEE\xE2"), player, 0.15)
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.PillButton(ti.ICON_RUN .. u8(" \xC1\xE5\xF1\xEA\xEE\xED\xE5\xF7\xED\xFB\xE9 \xE1\xE5\xE3"), cVARS.infinite_run, 0.15) then
                    config.infinite_run = cVARS.infinite_run[0]
                    save_cfg()
                end
                imgui.SameLine()
                imgui.SetCursorPosX(pyramid_cursor_x1(300))
                imgui.PushItemWidth(100)
                imgui.Text(u8("\xCF\xF0\xEE\xE7\xF0\xE0\xF7\xED\xEE\xF1\xF2\xFC \xEE\xE1\xFA\xE5\xEA\xF2\xEE\xE2"))
                imgui.SameLine()
                if imgui.SliderInt(u8(""), objectAlpha, 0, 250) then
                    mainIni.alpha.object = objectAlpha[0]
                end
                imgui.PopItemWidth()
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.PillButton(u8("\xC0\xE2\xF2\xEE\xF3\xF1\xF2\xF0\xEE\xE9\xF1\xF2\xE2\xEE \xED\xE0 \xF0\xE0\xE1\xEE\xF2\xF3"), cVARS.auto_job, 0.15) then
                    config.auto_job = cVARS.auto_job[0]
                    save_cfg()
                end
                imgui.SameLine()
                imgui.SetCursorPosX(pyramid_cursor_x1(260))
                if imgui.Button(u8("\xC2\xFB\xE1\xF0\xE0\xF2\xFC \xF6\xE2\xE5\xF2 \xEC\xE8\xE3\xE0\xED\xE8\xFF"), iv2(300, 30)) then
                    warning_color_window[0] = true
                end
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                imgui.PillButton(u8("\xC7\xE2\xF3\xEA\xEE\xE2\xEE\xE5 \xEE\xEF\xEE\xE2\xE5\xF9\xE5\xED\xE8\xE5"), cVARS.antiadmin_play_sound, 0.15)
                imgui.SameLine()
                imgui.SetCursorPosX(pyramid_cursor_x1(150))
                if imgui.Button(ti.ICON_SNOWFLAKE .. u8("UnFreeze"), imgui.ImVec2(176, 25)) then
                    freezeCharPosition(PLAYER_PED, true)
                    freezeCharPosition(PLAYER_PED, false)
                    setPlayerControl(PLAYER_HANDLE, true)
                    restoreCameraJumpcut()
                    clearCharTasksImmediately(PLAYER_PED)
                end
                if cVARS.antiadmin_play_sound[0] then
                    imgui.SetCursorPosX(pyramid_cursor_x(10))
                    imgui.Text(u8("\xCF\xF3\xF2\xFC \xEA \xF4\xE0\xE9\xEB\xF3:"))
                    imgui.SetCursorPosX(pyramid_cursor_x(10))
                    imgui.PushItemWidth(500)
                    if imgui.InputText(u8("##sound_path"), cVARS.antiadmin_sound_path, 256) then
                        save_cfg()
                    end
                    imgui.PopItemWidth()
                    imgui.SetCursorPosX(pyramid_cursor_x(10))
                    if imgui.Button(u8("\xD2\xE5\xF1\xF2 \xE7\xE2\xF3\xEA\xE0"), iv2(200, 50)) then
                        playAlertSound()
                    end
                end
            end
            imgui.PopItemWidth()
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
        elseif content_display_tab == u8("\xD1\xE5\xF2\xF2\xE8\xED\xE3") then
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushItemWidth(168)
            if imgui.InputTextWithHint("##menu_command", u8("\xCA\xEE\xEC\xE0\xED\xE4\xE0 \xEC\xE5\xED\xFE"), cVARS.menu_command, 64) then
                config.menu_command = ffi.string(cVARS.menu_command)
                save_cfg()
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8("\xCA\xEE\xEC\xE0\xED\xE4\xE0 \xEE\xF2\xEA\xF0\xFB\xF2\xE8\xFF \xEC\xE5\xED\xFE"))
            end
            imgui.PopItemWidth()
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushItemWidth(220)
            if imgui.InputTextWithHint("##bot_command", u8("\xCA\xEE\xEC\xE0\xED\xE4\xE0 \xE1\xEE\xF2\xE0"), cVARS.bot_command, 64) then
                config.bot_command = ffi.string(cVARS.bot_command)
                save_cfg()
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8("\xCA\xEE\xEC\xE0\xED\xE4\xE0 \xE4\xEB\xFF \xE7\xE0\xEF\xF3\xF1\xEA\xE0 \xE1\xEE\xF2\xE0"))
            end
            imgui.PopItemWidth()

            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.Text(u8("\xCA\xEB\xE0\xE2\xE8\xF8\xE0 \xE4\xEB\xFF \xEE\xF2\xEA\xF0\xFB\xF2\xE8\xFF \xEC\xE5\xED\xFE:"))
            local menu_button_text = u8("\xC2\xFB\xE1\xF0\xE0\xF2\xFC \xEA\xEB\xE0\xE2\xE8\xF8\xF3 \xEC\xE5\xED\xFE")
            if cVARS.waiting_for_menu_key then
                menu_button_text = u8("\xCD\xE0\xE6\xEC\xE8\xF2\xE5 \xEA\xEB\xE0\xE2\xE8\xF8\xF3...")
                local key = getPressedKey()
                if key then
                    cVARS.menu_hotkey[0] = key
                    save_cfg()
                    cVARS.waiting_for_menu_key = false
                end
            elseif cVARS.menu_hotkey[0] and cVARS.menu_hotkey[0] ~= 0 then
                menu_button_text = u8(getKeyName(cVARS.menu_hotkey[0]) or u8("\xCD\xE5 \xE2\xFB\xE1\xF0\xE0\xED\xEE"))
            end
            imgui.SetCursorPosX(pyramid_cursor_x(30))
            if imgui.Button(menu_button_text) then
                cVARS.waiting_for_menu_key = true
            end

            imgui.SetCursorPosX(pyramid_cursor_x(41))
            imgui.Text(u8("\xCA\xEB\xE0\xE2\xE8\xF8\xE0 \xE4\xEB\xFF \xE0\xEA\xF2\xE8\xE2\xE0\xF6\xE8\xE8 \xE1\xEE\xF2\xE0:"))
            local bot_button_text = u8("\xC2\xFB\xE1\xF0\xE0\xF2\xFC \xEA\xEB\xE0\xE2\xE8\xF8\xF3 \xE1\xEE\xF2\xE0")
            if cVARS.waiting_for_bot_key then
                bot_button_text = u8("\xCD\xE0\xE6\xEC\xE8\xF2\xE5 \xEA\xEB\xE0\xE2\xE8\xF8\xF3...")
                local key = getPressedKey()
                if key then
                    cVARS.bot_hotkey[0] = key
                    save_cfg()
                    cVARS.waiting_for_bot_key = false
                end
            elseif cVARS.bot_hotkey[0] and cVARS.bot_hotkey[0] ~= 0 then
                bot_button_text = u8(getKeyName(cVARS.bot_hotkey[0]) or u8("\xCD\xE5 \xE2\xFB\xE1\xF0\xE0\xED\xEE"))
            end
            imgui.SetCursorPosX(pyramid_cursor_x(75))
            if imgui.Button(bot_button_text) then
                cVARS.waiting_for_bot_key = true
            end

            imgui.SetCursorPosX(pyramid_cursor_x(30))
            imgui.Text(u8("\xCA\xEE\xEC\xE1\xE8\xED\xE0\xF6\xE8\xFF \xEA\xEB\xE0\xE2\xE8\xF8 \xE4\xEB\xFF \xEE\xF2\xEA\xF0\xFB\xF2\xE8\xFF \xEC\xE5\xED\xFE:"))
            local combo1_text = u8("\xC2\xFB\xE1\xF0\xE0\xF2\xFC 1 \xEA\xEB\xE0\xE2\xE8\xF8\xF3")
            if cVARS.waiting_for_combo_key1 then
                combo1_text = u8("\xCD\xE0\xE6\xEC\xE8\xF2\xE5 1 \xEA\xEB\xE0\xE2\xE8\xF8\xF3...")
                local key = getPressedKey()
                if key then
                    cVARS.combo_key1[0] = key
                    cVARS.waiting_for_combo_key1 = false
                    save_cfg()
                end
            elseif cVARS.combo_key1[0] and cVARS.combo_key1[0] ~= 0 then
                combo1_text = u8(getKeyName(cVARS.combo_key1[0]) or u8("\xCD\xE5 \xE2\xFB\xE1\xF0\xE0\xED\xEE"))
            end
            imgui.SetCursorPosX(pyramid_cursor_x(41))
            if imgui.Button(combo1_text) then
                cVARS.waiting_for_combo_key1 = true
            end
            imgui.SameLine()
            imgui.Text("+")
            imgui.SameLine()
            local combo2_text = u8("\xC2\xFB\xE1\xF0\xE0\xF2\xFC 2 \xEA\xEB\xE0\xE2\xE8\xF8\xF3")
            if cVARS.waiting_for_combo_key2 then
                combo2_text = u8("\xCD\xE0\xE6\xEC\xE8\xF2\xE5 2 \xEA\xEB\xE0\xE2\xE8\xF8\xF3...")
                local key = getPressedKey()
                if key then
                    cVARS.combo_key2[0] = key
                    cVARS.waiting_for_combo_key2 = false
                    save_cfg()
                end
            elseif cVARS.combo_key2[0] and cVARS.combo_key2[0] ~= 0 then
                combo2_text = u8(getKeyName(cVARS.combo_key2[0]) or u8("\xCD\xE5 \xE2\xFB\xE1\xF0\xE0\xED\xEE"))
            end
            if imgui.Button(combo2_text) then
                cVARS.waiting_for_combo_key2 = true
            end

            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.Spacing()
            imgui.SetCursorPosX(pyramid_cursor_x(92))
            if imgui.Button(u8("\xD1\xE1\xF0\xEE\xF1\xE8\xF2\xFC \xE2\xF1\xE5 \xE1\xE8\xED\xE4\xFB \xED\xE0 \xF1\xF2\xE0\xED\xE4\xE0\xF0\xF2\xED\xFB\xE5")) then
                cVARS.menu_hotkey[0] = 0
                cVARS.bot_hotkey[0] = 0
                cVARS.combo_key1[0] = 0
                cVARS.combo_key2[0] = 0
                cVARS.waiting_for_menu_key = false
                cVARS.waiting_for_bot_key = false
                cVARS.waiting_for_combo_key1 = false
                cVARS.waiting_for_combo_key2 = false
                save_cfg()
            end

            imgui.SetCursorPosX(pyramid_cursor_x())
            GraySeparator(-1, 10, 585)
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 8)
            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8("\xD0\xE0\xE7\xF0\xE5\xF8\xE8\xF2\xFC \xEF\xE5\xF0\xE5\xEC\xE5\xF9\xE5\xED\xE8\xE5 \xEC\xE5\xED\xFE"), cVARS.menu_movable, 0.15) then
                config.menu_movable = cVARS.menu_movable[0]
                save_cfg()
                if not cVARS.menu_movable[0] then
                    local scrW, scrH = getScreenResolution()
                    cVARS.menu_pos_x[0] = (scrW - 1000) / 2
                    cVARS.menu_pos_y[0] = (scrH - 650) / 2
                    save_cfg()
                end
            end
            imgui.SameLine()
            imgui.ShowHelpMarker(u8("\xC5\xF1\xEB\xE8 \xE2\xEA\xEB\xFE\xF7\xE5\xED\xEE \xEC\xEE\xE6\xED\xEE \xEF\xE5\xF0\xE5\xF2\xE0\xF1\xEA\xE8\xE2\xE0\xF2\xFC \xEC\xE5\xED\xFE \xEC\xFB\xF8\xEA\xEE\xE9\n\xC2\xFB\xEA\xEB\xFE\xF7\xE5\xED\xEE \xF2\xEE \xEC\xE5\xED\xFE \xF4\xE8\xEA\xF1\xE8\xF0\xEE\xE2\xE0\xED\xEE \xEF\xEE \xF6\xE5\xED\xF2\xF0\xF3 \xFD\xEA\xF0\xE0\xED\xE0"))
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.Text(u8("\xCF\xF3\xF2\xFC \xEA \xE0\xE2\xE0\xF2\xE0\xF0\xF3 (\xEF\xE0\xEF\xEA\xE0 moonloader):"))
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushItemWidth(350)
            if imgui.InputTextWithHint("##avatar_path", u8("\xED\xE0\xEF\xF0\xE8\xEC\xE5\xF0: avatar.png"), cVARS.avatar_path, 256) then
                config.avatar_path = ffi.string(cVARS.avatar_path)
                save_cfg()
                reload_avatar()
            end
            imgui.PopItemWidth()
            imgui.SameLine()
            if imgui.Button(ti.ICON_RELOAD .. "##reload_avatar") then
                reload_avatar()
            end
            imgui.Spacing()
            imgui.SetCursorPosX(pyramid_cursor_x())
            GraySeparator(-1, 10, 755)
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushStyleColor(imgui.Col.Text, iv4(0.5, 0.5, 0.5, 1.0))
            imgui.Text(u8("\xD2\xE5\xEA\xF3\xF9\xE0\xFF \xE2\xE5\xF0\xF1\xE8\xFF: ") .. thisScript().version)
            if update_check_done then
                if update_available then
                    imgui.PopStyleColor()
                    imgui.PushStyleColor(imgui.Col.Text, iv4(1.0, 0.85, 0.1, 1.0))
                    imgui.SameLine()
                    imgui.Text(u8("  ") .. ti.ICON_REFRESH_ALERT .. u8("  \xC4\xEE\xF1\xF2\xF3\xEF\xED\xE0 \xED\xEE\xE2\xE0\xFF \xE2\xE5\xF0\xF1\xE8\xFF: ") .. UPDATE_LATEST_VER)
                    imgui.PopStyleColor()
                else
                    imgui.SameLine()
                    imgui.Text(u8("  ") .. ti.ICON_CHECK .. u8("  \xC0\xEA\xF2\xF3\xE0\xEB\xFC\xED\xE0\xFF"))
                    imgui.PopStyleColor()
                end
            else
                imgui.PopStyleColor()
            end
            imgui.SetCursorPosX(pyramid_cursor_x(40))
            imgui.PushStyleColor(imgui.Col.Button,        iv4(0.08, 0.38, 0.65, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered,  iv4(0.12, 0.55, 0.88, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,   iv4(0.05, 0.27, 0.48, 1.0))
            local check_btn_txt = u8("\xCF\xF0\xEE\xE2\xE5\xF0\xE8\xF2\xFC \xEE\xE1\xED\xEE\xE2\xEB\xE5\xED\xE8\xE5")
            if not update_check_done then check_btn_txt = u8("\xCF\xF0\xEE\xE2\xE5\xF0\xEA\xE0...") end
            if imgui.Button(ti.ICON_REFRESH .. " " .. check_btn_txt) and update_check_done then
                update_check_done  = false
                update_available   = nil
                update_popup_shown = false
                UPDATE_LATEST_VER  = ""
                UPDATE_DOWNLOAD_URL = ""
                VERSION_JSON_URL = "https://raw.githubusercontent.com/flupiflufi1/popa/main/version.json?" .. tostring(os.clock())
                check_version_silent()
            end
            imgui.PopStyleColor(3)
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
        elseif content_display_tab == u8("Telegram") then
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 8)
            imgui.SetCursorPosY(160)
            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(ti.ICON_DOWNLOAD .. u8(" \xC2\xEA\xEB\xFE\xF7\xE8\xF2\xFC Telegram"), cVARS.telegram, 0.15) then
                config.telegram = cVARS.telegram[0]
                save_cfg()
            end
            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8("\xD3\xE2\xE5\xE4\xEE\xEC\xEB\xE5\xED\xE8\xFF \xED\xE0 \xEE\xE1\xF9\xE5\xED\xE8\xE5"), cVARS.warningseytg, 0.15) then
                config.warningseytg = cVARS.warningseytg[0]
                save_cfg()
            end
            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.Button(u8("\xD2\xE5\xF1\xF2 \xF3\xE2\xE5\xE4\xEE\xEC\xEB\xE5\xED\xE8\xFF"), iv2(200, 50)) then
                config.telegram_token  = u8:decode(ffi.string(cVARS.telegram_token)):gsub("%s+", "")
                config.telegram_chat_id = u8:decode(ffi.string(cVARS.telegram_chat_id)):gsub("%s+", "")
                save_cfg()
                token    = config.telegram_token
                chat_id  = config.telegram_chat_id
                if cVARS.telegram[0] and #token > 5 and #chat_id > 3 then
                    getLastUpdate()
                    sendTelegramNotification(u8("\xD2\xE5\xF1\xF2\xEE\xE2\xEE\xE5 \xF1\xEE\xEE\xE1\xF9\xE5\xED\xE8\xE5 \xEE\xF2 \xE1\xEE\xF2\xE0!"))
                elseif #token < 5 and #chat_id < 3 then
                    cMsg("\xD2\xEE\xEA\xE5\xED \xE8\xEB\xE8 chat_id \xE2\xFB\xE3\xEB\xFF\xE4\xFF\xF2 \xED\xE5\xEA\xEE\xF0\xF0\xE5\xEA\xF2\xED\xEE")
                elseif not cVARS.telegram[0] then
                    cMsg("\xCD\xE0\xE6\xEC\xE8 \xEA\xED\xEE\xEF\xEA\xF3 \xC2\xEA\xEB\xFE\xF7\xE8\xF2\xFC Telegram, \xF7\xF2\xEE\xE1\xFB \xE7\xE0\xF0\xE0\xE1\xEE\xF2\xE0\xEB\xEE")
                end
            end
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushItemWidth(470)
            imgui.Text(u8("Token \xE1\xEE\xF2\xE0:"))
            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.InputText("##token", cVARS.telegram_token, 256, imgui.InputTextFlags.Password) then
                config.telegram_token = u8:decode(ffi.string(cVARS.telegram_token)):gsub("%s", "")
                save_cfg()
            end
            imgui.PopItemWidth()
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushItemWidth(555)
            imgui.Text(u8("Chat ID:"))
            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.InputText("##chatid", cVARS.telegram_chat_id, 256) then
                config.telegram_chat_id = u8:decode(ffi.string(cVARS.telegram_chat_id)):gsub("%s", "")
                save_cfg()
            end
            imgui.PopItemWidth()
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.Text(u8("\xCF\xF0\xEE\xEA\xF1\xE8 / \xF0\xE5\xE7\xE5\xF0\xE2\xED\xFB\xE9 URL API Telegram:"))
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushItemWidth(500)
            if imgui.InputTextWithHint("##tg_api_url", "https://api.telegram.org", cVARS.telegram_api_url, 256) then
                config.telegram_api_url = u8:decode(ffi.string(cVARS.telegram_api_url)):gsub("%s+", "")
                save_cfg()
            end
            imgui.PopItemWidth()
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.PushStyleColor(imgui.Col.Text, iv4(0.6, 0.6, 0.6, 1))
            imgui.TextWrapped(u8("\xCF\xF3\xE1\xEB\xE8\xF7\xED\xFB\xE5 \xEF\xF0\xEE\xEA\xF1\xE8: https://tg.bakh.us  |  https://tgapi.ru"))
            imgui.PopStyleColor()
            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.Button(u8("\xD1\xE1\xF0\xEE\xF1\xE8\xF2\xFC \xED\xE0 \xF1\xF2\xE0\xED\xE4\xE0\xF0\xF2\xED\xFB\xE9"), iv2(280, 30)) then
                local default = "https://api.telegram.org"
                for i = 1, #default do
                    cVARS.telegram_api_url[i-1] = default:sub(i,i):byte()
                end
                cVARS.telegram_api_url[#default] = 0
                config.telegram_api_url = default
                save_cfg()
            end
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
        elseif content_display_tab == u8("\xC0\xED\xF2\xE8\xE0\xE4\xEC") then
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 8)
            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xCA\xF0\xE0\xF8 \xE8\xE3\xF0\xFB"), cVARS.antiadmin_autoExit, 0.15) then config.antiadmin_autoExit = cVARS.antiadmin_autoExit[0] save_cfg() end
            imgui.SameLine() imgui.ShowHelpMarker(u8("\xCA\xF0\xE0\xF8\xE8\xF2 \xE8\xE3\xF0\xF3 \xEF\xF0\xE8 \xE0\xE4\xEC\xE8\xED\xE5"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xD1\xEA\xE8\xEF \xE4\xE8\xE0\xEB\xEE\xE3\xE0"), cVARS.antiadmin_skipdialog, 0.15) then config.antiadmin_skipdialog = cVARS.antiadmin_skipdialog[0] save_cfg() end
            imgui.SameLine() imgui.ShowHelpMarker(u8("\xC0\xE2\xF2\xEE\xEC\xE0\xF2\xE8\xF7\xE5\xF1\xEA\xE8 \xE7\xE0\xEA\xF0\xFB\xE2\xE0\xE5\xF2 \xE4\xE8\xE0\xEB\xEE\xE3"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xD0\xE0\xE7\xE2\xEE\xF0\xEE\xF2 \xEE\xEA\xED\xE0"), cVARS.antiadmin_reversal, 0.15) then config.antiadmin_reversal = cVARS.antiadmin_reversal[0] save_cfg() end
            imgui.SameLine() imgui.ShowHelpMarker(u8("\xD0\xE0\xE7\xE2\xEE\xF0\xE0\xF7\xE8\xE2\xE0\xE5\xF2 \xE8\xE3\xF0\xF3"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xCC\xE8\xE3\xE0\xED\xE8\xE5 \xFD\xEA\xF0\xE0\xED\xEE\xEC"), cVARS.antiadmin_blinking, 0.15) then config.antiadmin_blinking = cVARS.antiadmin_blinking[0] save_cfg() end
            imgui.SameLine() imgui.ShowHelpMarker(u8("\xCC\xE8\xE3\xE0\xE5\xF2 \xFD\xEA\xF0\xE0\xED\xEE\xEC"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.RadioButtonIntPtr(u8("\xCC\xE8\xE3\xE0\xED\xE8\xE5 350\xEC\xF1"), cVARS.antiadmin_flash, 1) then config.antiadmin_flash = 1 save_cfg() end
            imgui.SameLine()
            if imgui.RadioButtonIntPtr(u8("\xCC\xE8\xE3\xE0\xED\xE8\xE5 500\xEC\xF1"), cVARS.antiadmin_flash, 2) then config.antiadmin_flash = 2 save_cfg() end

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xC2\xFB\xEA\xEB\xFE\xF7\xE5\xED\xE8\xE5 \xE1\xEE\xF2\xE0 \xEF\xF0\xE8 \xE0\xE4\xEC\xE8\xED\xE5"), cVARS.antiadmin_autoOff, 0.15) then config.antiadmin_autoOff = cVARS.antiadmin_autoOff[0] save_cfg() end
            imgui.SameLine() imgui.ShowHelpMarker(u8("\xC2\xFB\xEA\xEB\xFE\xF7\xE0\xE5\xF2 \xE1\xEE\xF2\xE0 \xEF\xF0\xE8 \xF1\xEE\xEE\xE1\xF9\xE5\xED\xE8\xE8 \xE0\xE4\xEC\xE8\xED\xE0"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xD3\xE2\xE5\xE4\xEE\xEC\xEB\xE5\xED\xE8\xE5 \xE2 TG"), cVARS.antiadmin_telegramNotf, 0.15) then config.antiadmin_telegramNotf = cVARS.antiadmin_telegramNotf[0] save_cfg() end
            imgui.SameLine() imgui.ShowHelpMarker(u8("\xCE\xF2\xEF\xF0\xE0\xE2\xEB\xFF\xE5\xF2 \xF3\xE2\xE5\xE4\xEE\xEC\xEB\xE5\xED\xE8\xE5 \xE2 Telegram"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xC0\xE2\xF2\xEE\xEE\xF2\xE2\xE5\xF2 '\xC2\xFB \xF2\xF3\xF2?'"), cVARS.auto, 0.15) then config.auto = cVARS.auto[0] save_cfg() end
            imgui.SameLine() imgui.ShowHelpMarker(u8("\xC0\xE2\xF2\xEE\xEC\xE0\xF2\xE8\xF7\xE5\xF1\xEA\xE8 \xEE\xF2\xE2\xE5\xF7\xE0\xE5\xF2 \xED\xE0 \xEF\xF0\xEE\xE2\xE5\xF0\xEA\xE8"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xCC\xE8\xE3\xE0\xED\xE8\xE5 \xEF\xF0\xE8 \xEF\xEE\xE4\xEE\xE7\xF0\xE5\xED\xE8\xE8"), cVARS.antiadmin_warningsey, 0.15) then config.antiadmin_warningsey = cVARS.antiadmin_warningsey[0] save_cfg() end

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xD0\xE5\xE0\xEA\xF6\xE8\xFF \xED\xE0 \xF4\xF0\xE8\xE7"), cVARS.antibot_antifreeze, 0.15) then config.antibot_antifreeze = cVARS.antibot_antifreeze[0] save_cfg() end

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xCA\xE8\xEA \xEF\xF0\xE8 \xE0\xE4\xEC\xE8\xED\xE5"), cVARS.antiadmin_kick, 0.15) then
                config.antiadmin_kick = cVARS.antiadmin_kick[0]
                save_cfg()
            end
            imgui.SameLine()
            imgui.ShowHelpMarker(u8("\xCF\xF0\xE8 \xEF\xEE\xE4\xEE\xE7\xF0\xE5\xED\xE8\xE8 \xED\xE0 \xE0\xE4\xEC\xE8\xED\xE0:\n\xC2\xFB\xE4\xE0\xB8\xF2 M4 \xE8\xEB\xE8 \xF2\xE5\xEB\xE5\xEF\xEE\xF0\xF2\xE8\xF0\xF3\xE5\xF2 \xE2 \xED\xE5\xE1\xEE (\xF0\xE0\xED\xE4\xEE\xEC\xED\xEE)\n\xD2\xEE\xEB\xFC\xEA\xEE \xE5\xF1\xEB\xE8 \xE2\xFB \xED\xE5 \xE2 \xEC\xE0\xF8\xE8\xED\xE5"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.Text(u8("\xD1\xEA\xE8\xEF \xE4\xE8\xE0\xEB\xEE\xE3\xE0 \xEE\xF2"))
            imgui.SameLine()
            imgui.PushItemWidth(140)
            if imgui.InputInt(u8("\xE4\xEE"), cVARS.antiadmin_skip11) then
                cVARS.antiadmin_skip11[0] = math.max(500, cVARS.antiadmin_skip11[0])
                config.antiadmin_skip11 = cVARS.antiadmin_skip11[0]
                save_cfg()
            end
            imgui.SameLine()
            if imgui.InputInt(u8("\xEC\xF1"), cVARS.antiadmin_skip22) then
                cVARS.antiadmin_skip22[0] = math.max(cVARS.antiadmin_skip11[0] + 100, cVARS.antiadmin_skip22[0])
                config.antiadmin_skip22 = cVARS.antiadmin_skip22[0]
                save_cfg()
            end
            imgui.PopItemWidth()
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
        elseif content_display_tab == u8("\xC0\xED\xF2\xE8-\xC5\xE4\xE0") then
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 8)
            imgui.SetCursorPosX(pyramid_cursor_x())
            if clp(u8("\xC0\xE2\xF2\xEE\xE5\xE4\xE0"),170) then
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.PillButton(u8(" \xC0\xE2\xF2\xEE\xE5\xE4\xE0"), cVARS.autoeat, 0.15) then config.autoeat = cVARS.autoeat[0] save_cfg() end
                if cVARS.autoeat[0] then
                    imgui.SetCursorPosX(pyramid_cursor_x(10))
                    imgui.PushItemWidth(150)
                    if imgui.Combo(u8("\xD1\xEF\xEE\xF1\xEE\xE1 \xE5\xE4\xFB"), cVARS.eatmethod, ImItems, #method) then config.eatmethod = cVARS.eatmethod[0] save_cfg() end
                    imgui.PopItemWidth()
                    imgui.SetCursorPosX(pyramid_cursor_x(10))
                    imgui.Text(u8("\xCA\xF3\xF8\xE0\xF2\xFC \xEF\xF0\xE8 \xF1\xFB\xF2\xEE\xF1\xF2\xE8"))
                    imgui.PushItemWidth(340)    
                    imgui.SetCursorPosX(pyramid_cursor_x(10))
                    imgui.SliderInt(u8(""), cVARS.eatpercent, 1, 99)
                    config.eatpercent = cVARS.eatpercent[0] save_cfg()
                    imgui.PopItemWidth()
                end
            end
            imgui.SetCursorPosX(pyramid_cursor_x())
            if clp(u8("\xC0\xE2\xF2\xEE\xE5\xE4\xE0 \xE8\xE7 \xEB\xE0\xF0\xFC\xEA\xE0"),220) then
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.PillButton(u8(" \xC2\xEA\xEB\xFE\xF7\xE8\xF2\xFC"), cVARS.autolarek, 0.15) then config.autolarek = cVARS.autolarek[0] save_cfg() end
            end
            imgui.SetCursorPosX(pyramid_cursor_x())
            if clp(u8("\xC0\xE2\xF2\xEE\xEF\xE8\xE2\xEE"),270) then
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.PillButton(u8(" \xC2\xEA\xEB\xFE\xF7\xE8\xF2\xFC \xE0\xE2\xF2\xEE\xEF\xE8\xE2\xEE"), cVARS.autobeer, 0.15) then config.autobeer = cVARS.autobeer[0] save_cfg() end
            end
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
        elseif content_display_tab == u8("\xC0\xED\xF2\xE8\xE1\xEE\xF2") then
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 8)
            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xCF\xF0\xFB\xE6\xEA\xE8"), cVARS.enable_jump, 0.15) then
                config.enable_jump = cVARS.enable_jump[0]
                save_cfg()
            end

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xC0\xED\xF2\xE8-\xEC\xE0\xF8\xE8\xED\xE0"), cVARS.anti_vehicle, 0.15) then
                config.anti_vehicle = cVARS.anti_vehicle[0]
                save_cfg()
            end
            imgui.SameLine()
            imgui.ShowHelpMarker(u8("\xC5\xF1\xEB\xE8 \xEF\xE5\xF0\xE5\xE4 \xE1\xEE\xF2\xEE\xEC \xEC\xE0\xF8\xE8\xED\xE0, \xE1\xEE\xF2 \xF3\xE1\xE5\xE6\xE8\xF2 \xE8 \xEE\xF2\xEA\xEB\xFE\xF7\xE8\xF2\xF1\xFF"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xD0\xE0\xED\xE4\xEE\xEC\xED\xFB\xE5 \xEF\xE0\xF3\xE7\xFB"), cVARS.enable_random_pauses, 0.15) then
                config.enable_random_pauses = cVARS.enable_random_pauses[0]
                save_cfg()
            end
            imgui.SameLine()
            imgui.ShowHelpMarker(u8("\xC1\xEE\xF2 \xE1\xF3\xE4\xE5\xF2 \xE4\xE5\xEB\xE0\xF2\xFC \xED\xE5\xE1\xEE\xEB\xFC\xF8\xE8\xE5 \xF1\xEB\xF3\xF7\xE0\xE9\xED\xFB\xE5 \xEE\xF1\xF2\xE0\xED\xEE\xE2\xEA\xE8 \xE2\xEE \xE2\xF0\xE5\xEC\xFF \xE4\xE2\xE8\xE6\xE5\xED\xE8\xFF, \xF7\xF2\xEE\xE1\xFB \xE2\xFB\xE3\xEB\xFF\xE4\xE5\xF2\xFC \xE5\xF1\xF2\xE5\xF1\xF2\xE2\xE5\xED\xED\xE5\xE5"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xC0\xED\xF2\xE8-\xE7\xE0\xF1\xF2\xF0\xE5\xE2\xE0\xED\xE8\xE5"), cVARS.check_stuck, 0.15) then
                config.check_stuck = cVARS.check_stuck[0]
                save_cfg()
            end
            imgui.SameLine()
            imgui.ShowHelpMarker(u8("\xC5\xF1\xEB\xE8 \xE1\xEE\xF2 \xE7\xE0\xF1\xF2\xF0\xED\xE5\xF2, \xEF\xF0\xFB\xE3\xED\xE5\xF2 \xE8 \xEF\xF0\xE8\xF8\xB8\xF2 \xF3\xE2\xE5\xE4, \xE4\xE0\xEB\xFC\xF8\xE5 \xE4\xE5\xEB\xEE \xE7\xE0 \xE2\xE0\xEC\xE8"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xD0\xE0\xED\xE4\xEE\xEC\xED\xFB\xE5 \xEF\xEE\xE2\xEE\xF0\xEE\xF2\xFB"), cVARS.enable_random_turns, 0.15) then
                config.enable_random_turns = cVARS.enable_random_turns[0]
                save_cfg()
            end

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8(" \xCF\xEE\xEA\xE0\xE7\xE0\xF2\xFC NavMesh \xF1\xE5\xF2\xEA\xF3"), cVARS.show_navmesh, 0.15) then
                config.show_navmesh = cVARS.show_navmesh[0]
                save_cfg()
            end
            imgui.SameLine() imgui.ShowHelpMarker(u8("\xCE\xF2\xEE\xE1\xF0\xE0\xE6\xE0\xE5\xF2 \xF1\xE5\xF2\xEA\xF3 \xED\xE0\xE2\xE8\xE3\xE0\xF6\xE8\xE8 \xE2 \xE8\xE3\xF0\xEE\xE2\xEE\xEC \xEC\xE8\xF0\xE5"))

            imgui.SetCursorPosX(pyramid_cursor_x())
            if imgui.PillButton(u8("\xD3\xEC\xED\xFB\xE9 \xE2\xFB\xE1\xEE\xF0 \xF2\xEE\xF7\xEA\xE8 \xF1\xE4\xE0\xF7\xE8"), cVARS.smart_sdacha, 0.15) then
                config.smart_sdacha = cVARS.smart_sdacha[0]
                save_cfg()
            end
            imgui.SameLine()
            imgui.ShowHelpMarker(u8("\xC1\xEE\xF2 \xF1\xE0\xEC \xE2\xFB\xE1\xE5\xF0\xE5\xF2 \xE1\xEB\xE8\xE6\xE0\xE9\xF8\xF3\xFE \xF2\xEE\xF7\xEA\xF3"))

            if not cVARS.smart_sdacha[0] then
                imgui.SetCursorPosX(pyramid_cursor_x())
                imgui.PushItemWidth(300)
                if imgui.Combo(u8("\xD0\xF3\xF7\xED\xEE\xE9 \xE2\xFB\xE1\xEE\xF0 \xF2\xEE\xF7\xEA\xE8"), cVARS.selected_sdacha_index, ImItems_sdacha, #sdacha_names) then
                    config.selected_sdacha_index = cVARS.selected_sdacha_index[0]
                    save_cfg()
                end
                imgui.PopItemWidth()
            end

            imgui.SetCursorPosX(pyramid_cursor_x())
            if clp(u8("\xCD\xE0\xF1\xF2\xF0\xEE\xE9\xEA\xE8 \xEA\xE0\xEC\xE5\xF0\xFB"),510) then
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                imgui.PushItemWidth(250)
                
                if imgui.SliderFloat(u8("\xD1\xE3\xEB\xE0\xE6\xE8\xE2\xE0\xED\xE8\xE5 \xE1\xEB\xE8\xE6\xED\xE5\xE5 (<8\xEC)"), cVARS.camera_smooth_close, 0.01, 0.5) then
                    config.camera_smooth_close = cVARS.camera_smooth_close[0]
                    save_cfg()
                end
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.SliderFloat(u8("\xD1\xE3\xEB\xE0\xE6\xE8\xE2\xE0\xED\xE8\xE5 \xF1\xF0\xE5\xE4\xED\xE5\xE5 (<25\xEC)"), cVARS.camera_smooth_mid, 0.01, 0.5) then
                    config.camera_smooth_mid = cVARS.camera_smooth_mid[0]
                    save_cfg()
                end
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.SliderFloat(u8("\xD1\xE3\xEB\xE0\xE6\xE8\xE2\xE0\xED\xE8\xE5 \xE4\xE0\xEB\xFC\xED\xE5\xE5"), cVARS.camera_smooth_far, 0.01, 0.5) then
                    config.camera_smooth_far = cVARS.camera_smooth_far[0]
                    save_cfg()
                end
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.SliderFloat(u8("\xCF\xEE\xE2\xEE\xF0\xEE\xF2 \xEF\xEB\xE0\xE2\xED\xFB\xE9 (<20°) °/\xF1"), cVARS.camera_turn_slow, 5.0, 180.0) then
                    config.camera_turn_slow = cVARS.camera_turn_slow[0]
                    save_cfg()
                end
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.SliderFloat(u8("\xCF\xEE\xE2\xEE\xF0\xEE\xF2 \xF1\xF0\xE5\xE4\xED\xE8\xE9 (<90°) °/\xF1"), cVARS.camera_turn_mid, 30.0, 360.0) then
                    config.camera_turn_mid = cVARS.camera_turn_mid[0]
                    save_cfg()
                end
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.SliderFloat(u8("\xCF\xEE\xE2\xEE\xF0\xEE\xF2 \xF0\xE5\xE7\xEA\xE8\xE9 (>90°) °/\xF1"), cVARS.camera_turn_fast, 60.0, 720.0) then
                    config.camera_turn_fast = cVARS.camera_turn_fast[0]
                    save_cfg()
                end
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.SliderFloat(u8("\xC4\xE8\xF1\xF2\xE0\xED\xF6\xE8\xFF \xEA\xE0\xEC\xE5\xF0\xFB"), cVARS.camera_dist, 5.0, 20.0) then
                    config.camera_dist = cVARS.camera_dist[0]
                    save_cfg()
                end
                imgui.SetCursorPosX(pyramid_cursor_x(10))
                if imgui.SliderFloat(u8("\xC2\xFB\xF1\xEE\xF2\xE0 \xEA\xE0\xEC\xE5\xF0\xFB"), cVARS.camera_height_offset, 0.0, 3.0) then
                    config.camera_height_offset = cVARS.camera_height_offset[0]
                    save_cfg()
                end
                imgui.PopItemWidth()
            end
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
        elseif content_display_tab == u8("\xD1\xF2\xE0\xF2\xE0") then
            imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 8)
            local function DrawStatBlock(title, icon, day_value, week_value, pos_offset_x, pos_offset_y, bg_color, border_color, width, height, text_offset)
                local block_size = iv2(width or 360, height or 155)
                local text_offset = text_offset or 0
                imgui.SetCursorPosX(pyramid_cursor_x() + (pos_offset_x or 0))
                imgui.SetCursorPosY(imgui.GetCursorPosY() + (pos_offset_y or 0))
                local p = imgui.GetCursorScreenPos()
                local dl = imgui.GetWindowDrawList()
                dl:AddRectFilled(p, iv2(p.x + block_size.x, p.y + block_size.y), bg_color, 0)
                dl:AddRect(p, iv2(p.x + block_size.x, p.y + block_size.y), border_color, 0, nil, 1.4)
                imgui.BeginGroup()
                    imgui.SetCursorPos(iv2(pyramid_cursor_x() + (pos_offset_x or 0) + 15 + text_offset, 
                                        imgui.GetCursorPosY() + 14))
                    imgui.PushFont(fonts[18])
                    imgui.Text((icon or "") .. " " .. title)
                    imgui.PopFont()
                    local sep_p = imgui.GetCursorScreenPos()
                    dl:AddLine(iv2(sep_p.x, sep_p.y), 
                            iv2(sep_p.x + block_size.x, sep_p.y), 
                            border_color, 1.2)

                    imgui.Dummy(iv2(0, 10))
                    local value_x = pyramid_cursor_x() + (pos_offset_x or 0) + 40 + text_offset
                    imgui.SetCursorPosX(value_x)
                    imgui.Text(u8("    \xC7\xE0 \xE4\xE5\xED\xFC:   ") .. tostring(day_value))
                    imgui.SetCursorPosX(value_x)
                    imgui.Text(u8("    \xC7\xE0 \xED\xE5\xE4\xE5\xEB\xFE: ") .. tostring(week_value))
                    imgui.Dummy(iv2(0, 12))
                imgui.EndGroup()
            end
            imgui.SetCursorPosX(pyramid_cursor_x())
            imgui.SetCursorPosY(imgui.GetCursorPosY() + 25)
            imgui.BeginGroup()
                imgui.SetCursorPosX(pyramid_cursor_x())
                imgui.PillButton(ti.ICON_PRESENTATION .. u8(" \xCE\xF2\xEA\xF0\xFB\xF2\xFC \xF1\xF2\xE0\xF2\xF3"), cVARS.stat_status, 0.15)
                imgui.SetCursorPosX(pyramid_cursor_x())
                imgui.PillButton(ti.ICON_RAINBOW .. u8(" \xD0\xE0\xE4\xF3\xE6\xED\xFB\xE9 \xF2\xE5\xEA\xF1\xF2"), cVARS.rainbowcolor, 0.15)
                imgui.SetCursorPosX(pyramid_cursor_x())
                imgui.PushItemWidth(150)
                imgui.InputInt(u8("\xD6\xE5\xED\xE0 \xE7\xE0 \xE4\xE5\xF0\xE5\xE2\xEE $"), cVARS.derevo_value)
                imgui.SetCursorPosX(pyramid_cursor_x())
                imgui.InputInt(u8("\xD6\xE5\xED\xE0 \xE7\xE0 \xE4\xF0\xEE\xE2\xE0 $"), cVARS.drova_value)
                imgui.PopItemWidth()
                imgui.SetCursorPosX(pyramid_cursor_x())
                imgui.Text(u8("\xD2\xE5\xEA\xF3\xF9\xE8\xE9 \xE7\xE0\xF0\xE0\xE1\xEE\xF2\xEE\xEA: ") ..(cVARS.derevo_amount[0] * cVARS.derevo_value[0]) .. u8(" $"))
                imgui.SetCursorPosX(pyramid_cursor_x())
                if imgui.Button(u8("\xCE\xF7\xE8\xF1\xF2\xE8\xF2\xFC \xF1\xF2\xE0\xF2\xE8\xF1\xF2\xE8\xEA\xF3"), iv2(200, 28)) then
                    cVARS.daily_trees[0] = 0
                    cVARS.weekly_trees[0] = 0
                    cVARS.derevo_amount[0] = 0
                    cVARS.drova_amount[0] = 0
                    cVARS.daily_drova[0] = 0
                    cVARS.weekly_drova[0] = 0
                    cVARS.degniebat_den[0] = 0
                    cVARS.degniebat_week[0] = 0
                    save_cfg()
                end
                imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
            imgui.EndGroup()
            DrawStatBlock(u8("\xC4\xE5\xED\xFC\xE3\xE8"), ti.ICON_WOOD, 
                        cVARS.degniebat_den[0], cVARS.degniebat_week[0],
                        65, 20,
                        conv_c(iv4(0.2, 0.8, 0.2, 0.28)),
                        conv_c(iv4(0.6, 0.6, 0.6, 1.0)),
                        360, 155,
                        10)
            DrawStatBlock(u8("\xC4\xE5\xF0\xE5\xE2\xEE \xE2\xFB\xF1\xF8\xE5\xE3\xEE \xEA\xE0\xF7\xE5\xF1\xF2\xE2\xE0"), ti.ICON_WOOD,
                        cVARS.daily_trees[0], cVARS.weekly_trees[0],
                        -30, 51,
                        conv_c(iv4(0.28, 0.14, 0.05, 0.28)),
                        conv_c(iv4(0.6, 0.6, 0.6, 1.0)),
                        360, 155,
                        40)
            imgui.SameLine()
            DrawStatBlock(u8("\xC4\xF0\xEE\xE2\xE0"), ti.ICON_WOOD,
                        cVARS.daily_drova[0], cVARS.weekly_drova[0],
                        405, 0,
                        conv_c(iv4(0.81, 0.58, 0.29, 0.28)),
                        conv_c(iv4(0.6, 0.6, 0.6, 1.0)),
                        360, 155,
                        0)
        elseif content_display_tab == u8("\xC3\xE0\xE9\xE4\xFB") then
            imgui.SetCursorPosX(pyramid_cursor_x()-40)
            imgui.SetCursorPosY(imgui.GetCursorPosY() + 45)
            imgui.Text(u8("1. \xCA\xE0\xEA \xEF\xEE\xE4\xEA\xEB\xFE\xF7\xE8\xF2\xFC \xD2\xC3 \xE1\xEE\xF2\xE0?"))
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()

                imgui.Text(u8("1. \xC7\xE0\xE9\xE4\xE8 \xE2 Telegram \xE8 \xED\xE0\xE9\xE4\xE8 \xE1\xEE\xF2\xE0 @BotFather"))
                imgui.Text(u8("2. \xCD\xE0\xE6\xEC\xE8 \xED\xE0 'Start' \xE8\xEB\xE8 \xE2\xE2\xE5\xE4\xE8 /start"))
                imgui.Text(u8("3. \xC2\xE2\xE5\xE4\xE8 \xEA\xEE\xEC\xE0\xED\xE4\xF3 /newbot \xE4\xEB\xFF \xF1\xEE\xE7\xE4\xE0\xED\xE8\xFF \xED\xEE\xE2\xEE\xE3\xEE \xE1\xEE\xF2\xE0"))
                imgui.Text(u8("4. \xCF\xF0\xE8\xE4\xF3\xEC\xE0\xE9 \xE8\xEC\xFF \xE4\xEB\xFF \xE1\xEE\xF2\xE0 (\xEE\xF2\xEE\xE1\xF0\xE0\xE6\xE0\xE5\xEC\xEE\xE5)"))
                imgui.Text(u8("5. \xCF\xF0\xE8\xE4\xF3\xEC\xE0\xE9 \xFE\xE7\xE5\xF0\xED\xE5\xE9\xEC \xE1\xEE\xF2\xE0, \xED\xE0\xEF\xF0\xE8\xEC\xE5\xF0: MyTestBot"))
                imgui.Text(u8("6. \xCF\xEE\xF1\xEB\xE5 BotFather \xE2\xFB\xE4\xE0\xF1\xF2 \xF2\xE5\xE1\xE5.. \xF2\xEE\xEA\xE5\xED(\xF2\xE8\xEF\xEE: 123456789:ABCDeKltuVWXyz)"))
                imgui.Text(u8("7. \xD1\xEA\xEE\xEF\xE8\xF0\xF3\xE9 \xF2\xEE\xEA\xE5\xED \xE8 \xE2\xF1\xF2\xE0\xE2\xFC \xE5\xE3\xEE \xE2 \xEF\xEE\xEB\xE5 Token \xE1\xEE\xF2\xE0"))
                imgui.Text(u8("8. \xD3\xE1\xE5\xE4\xE8\xF1\xFC, \xF7\xF2\xEE \xE2\xEA\xEB\xFE\xF7\xE5\xED\xE0 \xEA\xED\xEE\xEF\xEA\xE0 \xC2\xEA\xEB\xFE\xF7\xE8\xF2\xFC Telegram"))
                imgui.Text(u8("9. \xC4\xE0\xEB\xFC\xF8\xE5 \xE7\xE0\xF5\xEE\xE4\xE8 \xE2 \xE1\xEE\xF2\xE0 @GetMyChatID_Bot \xE8\xEB\xE8 \xEF\xEE\xE4\xEE\xE1\xED\xEE\xE3\xEE"))
                imgui.Text(u8("10. \xCF\xE8\xF8\xE8 \xF1\xF2\xE0\xF0\xF2 /start \xE8 \xE8\xF9\xE8 \xF1\xF2\xF0\xEE\xEA\xF3 User ID (\xED\xE0\xEF\xF0\xE8\xEC\xE5\xF0 14881337)"))
                imgui.Text(u8("11. \xCA\xEE\xEF\xE8\xF0\xF3\xE9 \xF6\xE8\xF4\xE5\xF0\xEA\xE8 \xE8 \xE2\xF1\xF2\xE0\xE2\xEB\xFF\xE9 \xE2 \xEF\xEE\xEB\xE5 Chat ID"))
                imgui.Text(u8("12. \xCD\xE0\xE6\xEC\xE8 \xEA\xED\xEE\xEF\xEA\xF3 \xF2\xE5\xF1\xF2 \xF3\xE2\xE5\xE4\xEE\xEC\xEB\xE5\xED\xE8\xFF, \xE5\xF1\xEB\xE8 \xED\xE5 \xEF\xF0\xE8\xF8\xEB\xB8\xF2 \xED\xE8\xF7\xE5\xE3\xEE \xE1\xEE\xF2"))
                imgui.Text(u8("12. ..\xF2\xEE \xEF\xE5\xF0\xE5\xE7\xE0\xE3\xF0\xF3\xE7\xE8 \xF1\xEA\xF0\xE8\xEF\xF2"))
                imgui.Text(u8("13. \xD2\xE5\xEF\xE5\xF0\xFC \xE2\xF1\xEE \xE7\xE0\xE8\xE1\xE0\xF2\xE0 \xE8 \xEC\xEE\xE6\xE5\xF8\xFC \xEF\xEE\xEB\xFC\xE7\xEE\xE2\xE0\xF2\xFC\xF1\xFF!"))

                imgui.EndTooltip()
            end
            imgui.SetCursorPosX(260)
            imgui.SetCursorPosY(imgui.GetCursorPosY() + 305)
            imgui.TextWrapped(u8[[
Áîò ïîëíîñòüþ àâòîìàòèçèðóåò ðàáîòó ëåñîðóáà íà Arizona RP.

Âêëþ÷èòå áîòà íà âêëàäêå "Ãëàâíàÿ"
Íàñòðîéòå àíòèàäìèí-ôóíêöèè äëÿ áåçîïàñíîñòè
Ïîäêëþ÷èòå Telegram áîò áóäåò ïðèñûëàòü óâåäîìëåíèÿ è ïðèíèìàòü êîìàíäû
Àâòîåäà è àâòîïèâî ïîìîãóò íå óìåðåòü îò ãîëîäà
Óìíàÿ ñäà÷à ñàìà âûáåðåò áëèæàéøóþ òî÷êó

Ïî âñåì âîïðîñàì: @Official_Peredoz
è àáàçÿòàëüíî îôîðìè ïàäïèñüêó íà ìîé òãê: @flupiflufi
            ]])
        end

        imgui.PopFont()
        if _content_style_pushed and _content_style_pushed > 0 then
            imgui.PopStyleColor(_content_style_pushed)
        end
        content_panel_alpha_multiplier = 1.0
        imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
        imgui.EndChild()
        local popup_handled = false
        if update_check_done and update_available and not update_popup_shown then
            update_popup_shown = true
            upd_popup_open[0] = true
            imgui.OpenPopup("##update_available")
            popup_handled = true
        end
        if not popup_handled then
            if not cVARS.offer_telegram[0] and not show_telegram_popup[0] then
                if update_check_done and not update_available then
                    show_telegram_popup[0] = true
                    imgui.OpenPopup("##telegram_offer")
                end
            end
        end
        imgui.PopStyleColor()
        if imgui.BeginPopupModal("##update_available", upd_popup_open, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize) then
            popup_handled = true
            imgui.SetWindowFontScale(1.1)
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Text, iv4(1.0, 0.85, 0.1, 1.0))
            imgui.CenterText(ti.ICON_REFRESH_ALERT .. u8(" \xC4\xEE\xF1\xF2\xF3\xEF\xED\xEE \xEE\xE1\xED\xEE\xE2\xEB\xE5\xED\xE8\xE5!"))
            imgui.PopStyleColor()
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Text, iv4(0.75, 0.75, 0.75, 1.0))
            imgui.CenterText(u8("\xD2\xE5\xEA\xF3\xF9\xE0\xFF \xE2\xE5\xF0\xF1\xE8\xFF: ") .. thisScript().version)
            imgui.CenterText(u8("\xCD\xEE\xE2\xE0\xFF \xE2\xE5\xF0\xF1\xE8\xFF: ") .. UPDATE_LATEST_VER)
            imgui.PopStyleColor()
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            imgui.PushStyleColor(imgui.Col.Button,        iv4(0.10, 0.55, 0.10, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered,  iv4(0.15, 0.75, 0.15, 1.0))
            imgui.PushStyleColor(imgui.Col.ButtonActive,   iv4(0.07, 0.38, 0.07, 1.0))
            imgui.SetCursorPosX((imgui.GetWindowWidth() - 300) / 2)
            if imgui.Button(ti.ICON_DOWNLOAD .. u8(" \xD1\xEA\xE0\xF7\xE0\xF2\xFC \xEE\xE1\xED\xEE\xE2\xEB\xE5\xED\xE8\xE5"), iv2(300, 42)) then
                if UPDATE_DOWNLOAD_URL ~= "" then
                    lua_thread.create(function()
                        local dl = require('moonloader').download_status
                        local done_dl = false
                        downloadUrlToFile(UPDATE_DOWNLOAD_URL, thisScript().path, function(_, st)
                            if st == dl.STATUS_ENDDOWNLOADDATA then
                                done_dl = true
                                sampAddChatMessage("[LesoRub] \xCE\xE1\xED\xEE\xE2\xEB\xE5\xED\xE8\xE5 \xF1\xEA\xE0\xF7\xE0\xED\xEE! \xCF\xE5\xF0\xE5\xE7\xE0\xEF\xF3\xF1\xEA...", -1)
                                wait(500)
                                thisScript():reload()
                            elseif st == dl.STATUSEX_ENDDOWNLOAD and not done_dl then
                                sampAddChatMessage("[LesoRub] \xCE\xF8\xE8\xE1\xEA\xE0 \xF1\xEA\xE0\xF7\xE8\xE2\xE0\xED\xE8\xFF \xEE\xE1\xED\xEE\xE2\xEB\xE5\xED\xE8\xFF!", -1)
                            end
                        end)
                    end)
                end
                imgui.CloseCurrentPopup()
            end
            imgui.PopStyleColor(3)
            imgui.Spacing()
            imgui.SetCursorPosX((imgui.GetWindowWidth() - 200) / 2)
            imgui.PushStyleColor(imgui.Col.Text, iv4(0.5, 0.5, 0.5, 1.0))
            if imgui.Button(u8("\xCF\xEE\xF2\xEE\xEC"), iv2(200, 28)) then
                imgui.CloseCurrentPopup()
            end
            imgui.PopStyleColor()
            imgui.Spacing()
            imgui.SetWindowFontScale(1.0)
            imgui.EndPopup()
        end

        if imgui.BeginPopupModal("##telegram_offer", telegram_popup_open, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize) then
            imgui.SetWindowFontScale(1.1)
            imgui.CenterText(u8("\xC4\xEB\xFF \xEF\xEE\xEB\xF3\xF7\xE5\xED\xE8\xFF \xE0\xEA\xF2\xF3\xE0\xEB\xFC\xED\xEE\xE9 \xE8\xED\xF4\xEE\xF0\xEC\xE0\xF6\xE8\xE8 \xEF\xEE \xF1\xEA\xF0\xE8\xEF\xF2\xF3"))
            imgui.CenterText(u8("\xE8 \xF1\xE2\xE5\xE6\xE8\xF5 \xEE\xE1\xED\xEE\xE2\xEB\xE5\xED\xE8\xE9  \xEF\xF0\xE8\xF1\xEE\xE5\xE4\xE8\xED\xFF\xE9\xF1\xFF \xEA \xED\xE0\xF8\xE5\xEC\xF3 \xD2\xE5\xEB\xE5\xE3\xF0\xE0\xEC\xEC \xCA\xE0\xED\xE0\xEB\xF3!"))
            imgui.NewLine()
            imgui.CenterText(ti.ICON_BRAND_TELEGRAM .. u8(" \xCD\xE0\xF8 \xD2\xE5\xEB\xE5\xE3\xF0\xE0\xEC \xCA\xE0\xED\xE0\xEB ") .. ti.ICON_BRAND_TELEGRAM)
            imgui.NewLine()
            imgui.NewLine()
            imgui.SetCursorPosX((imgui.GetWindowWidth() - 340) / 2)
            if imgui.Button(u8("\xCF\xE5\xF0\xE5\xE9\xF2\xE8 \xE2 Telegram \xCA\xE0\xED\xE0\xEB"), iv2(340, 45)) then
                cVARS.offer_telegram[0] = true
                config.offer_telegram = true
                save_cfg()
                os.execute('start https://t.me/flupiflufi')
                imgui.CloseCurrentPopup()
            end
            imgui.SetWindowFontScale(1.0)
            imgui.EndPopup()
        end

        if cVARS.menu_movable[0] then
            local pos = imgui.GetWindowPos()
            if math.floor(pos.x) ~= cVARS.menu_pos_x[0] or math.floor(pos.y) ~= cVARS.menu_pos_y[0] then
                cVARS.menu_pos_x[0] = math.floor(pos.x)
                cVARS.menu_pos_y[0] = math.floor(pos.y)
                save_cfg()
            end
        end

        imgui.End()
        dl:PopClipRect()
    end
)

imgui.OnFrame(
    function() return warning_color_window[0] end,
    function()
        local window_size = imgui.ImVec2(300, 200)
        imgui.SetNextWindowSize(window_size, imgui.Cond.FirstUseEver)
        if imgui.Begin(u8("\xC2\xFB\xE1\xEE\xF0 \xF6\xE2\xE5\xF2\xE0 \xEC\xE8\xE3\xE0\xED\xE8\xFF"), warning_color_window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
            imgui.ColorEdit4(u8("\xD6\xE2\xE5\xF2"), cVARS.warning_color)
            if imgui.Button(u8("\xC7\xE0\xEA\xF0\xFB\xF2\xFC"), imgui.ImVec2(100, 30)) then
                warning_color_window[0] = false
            end
            imgui.End()
        end
    end
)
imgui.OnFrame(
    function() return cVARS.menu[0] and avatar_texture ~= nil end,
    function(self)
        self.HideCursor = true
        local scrW, scrH = getScreenResolution()
        local av_size = 400

        imgui.SetNextWindowPos(iv2(scrW - av_size - 20, scrH - av_size - 20), imgui.Cond.Always)
        imgui.SetNextWindowSize(iv2(av_size + 50, av_size), imgui.Cond.Always)

        imgui.PushStyleColor(imgui.Col.WindowBg, iv4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.Border, iv4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ChildBg, iv4(0, 0, 0, 0))

        imgui.Begin("##avatar_corner", nil,
            imgui.WindowFlags.NoTitleBar +
            imgui.WindowFlags.NoResize +
            imgui.WindowFlags.NoMove +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoInputs +
            imgui.WindowFlags.NoBackground
        )
        if avatar_texture ~= nil then
            local dl = imgui.GetWindowDrawList()
            local x, y = scrW - av_size - 20, scrH - av_size - 20
            local uv_min = iv2(0.0, 0.0)
            local uv_max = iv2(1.0, 1.0)
            dl:AddImage(avatar_texture, iv2(x, y), iv2(x + av_size, y + av_size), uv_min, uv_max)
        end
        imgui.End()
        imgui.PopStyleColor(3)
    end
)
function set_player_skin(id, skin)
    local BS = raknetNewBitStream()
    raknetBitStreamWriteInt32(BS, id)
    raknetBitStreamWriteInt32(BS, skin)
    raknetEmulRpcReceiveBitStream(153, BS)
    raknetDeleteBitStream(BS)
end

function pack_color(a, r, g, b)
    local color = b
    color = bit.bor(color, bit.lshift(g, 8))
    color = bit.bor(color, bit.lshift(r, 16))
    color = bit.bor(color, bit.lshift(a, 24))
    return color
end

function warning()
    while true do wait(0)
        if warn then
            local col = cVARS.warning_color
            local r, g, b, a = col[0]*255, col[1]*255, col[2]*255, col[3]*255
            local color1 = pack_color(a, r, g, b)
            local color2 = pack_color(a*0.2, r*0.2, g*0.2, b*0.2)
            for i = 1, 20 do
                renderDrawBox(0, 0, X, Y, (i % 2 == 0) and color1 or color2)
                wait(cVARS.antiadmin_flash[0] or 10)
            end
            warn = false
        end
    end
end

function warning2()
    while true do wait(0)
        if warn2 then
            local col = cVARS.warning_color
            local r, g, b, a = col[0]*255, col[1]*255, col[2]*255, col[3]*255
            local color1 = pack_color(a, r, g, b)
            local color2 = pack_color(a*0.2, r*0.2, g*0.2, b*0.2)
            for i = 1, 40 do
                renderDrawBox(0, 0, X, Y, (i % 2 == 0) and color1 or color2)
                wait(cVARS.antiadmin_flash[0] or 10)
            end
            warn2 = false
        end
    end
end

function cMsg(text) -- ÷òîáû äåëàòü 5 ñòðîê ïðè çàãðóçêå
    sampAddChatMessage("[{7208fc}Leso{6207d9}\xD0\xF3\xE1{FFFFFF}] " .. text, -1)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local my_font_compressed_data_base85 = "7])#######d?fma'/###[),##2(V$#Q6>##u@;*>vo>Z)7KMiK6f>11fY;996He8#CD2MK]sEn/(RdL<#)'McY5S>-FqEn/NFxF>milS;Z4S>-+B^01kZn42Vm:H%x.>>#fWN$5aNV=B%U$8ncPUV$77YY#_`(*H>*>>#M>:@-ud5&5#-0%JIv<7eN)35&<7h(E?/d<BoL3NPcq.>-r@pV-TT$=(k8nO$],>>#gqEn/<_[FHZiaWs9euH2T@uu#G4JuBN4*SU8mQS%F3kn/`K[^I*Tj)#vfG<-T)NU/+>00F<eeZgF&O>HJx?U2<%S+HL0a5Nnsp4J2H:;$>>N+2]slx4k)-UAeI1=#G<5)MRZ<igKQP?MSF(VGS8'DE6S7&4n.[w'OMYY#0]Wh#Ys%_#[/;,#NR)8ve_nI-TbW3M<DT;-,b@U.jE,+#8eIU.%####1F;=-s.g,MN_vY#W#juLke)Z#DY2uLf.BrM0oU%kP:c@t`^W1#rP'##bkLEN%hO`<xfo+#KFBv-bWn*.FkUxL;xSfLLLZY#keJ(MoPG&#*s/kL%8gV-M@2I$tIbA#,xkA#S@@I->LE/1`>uu#'5YY#7;uu#ss:T..%###^Z`=-L#iP/LKMigEk^oes2>PpceL]lWc8GjYjUJDHpI&GMiefLMpFD<j,ZS@@Q^_&..(B#L2KWN&rJfL[f1p.f@C>#u,2_A-p=xt_dS-H)LF_&I*2^#@N#<-$sG<-.p8gLZghlL^3IA4Ud62BnIhumGRt-$'Af-HfK'9AHR@/1Dg_k4M2V7n:]$YlUnL+iUcpI_C)5;nt/QD-498ZM'</#M[;X'M'4DhLIxRiLHcCH-*hLtL8a]rQ-]F&#J.#'#te'f#?mm*Mr^GVd?I(^#W-u-$5P*rLnaSwuo*T,M-Tpwuahk*v*>-$vF=W%v6,h#v8]gwMh(Vp.=wV:v:BCwK+#q-$TDa-6lrFkO1PLJ:jefS8f=OkknEo^f<Rd--%206vEp57vCxj5vcgG<-#>/SRp?$'vCd+;.<^Np#=ec/$AF0Gn]xQjLhr>8%IQ*REnhm7RBw_G%oQN;)nJT:v.YjfLihr7[mp@)=(S_`b*nxP/```%XMN*##5iGd<M^ouGRPpe<94CGDE:*#>1E&2^,'b`<T<Kkb]<bSA9CY&#)?jp'5G;:%P8a-62>Q+`Xr5f_W^j9;ukL+i^Ab8&v2QD-sTG-M>Fw/vi5?;#r$a..dx6qLTZ]#M0g>oLd6>xuilF?-F(m<-x4T;->=DiLQlD;?P4_S.Y%tV.?:t-$D5?F%rh+;dP%$F@T1Xk4%n>_/W3vW.H^H;6md8/1UL#l+m)Ow9'uT^#/YFm#_dEB--=K$.FPoVM8G5gLBrJfL?.*$#M%###%2/vLf?jZ#<OI@#jbO_.3.>>#5AT;-4$T,MemsmL+SMpL@Y%iLu4$##1lA,Me2#&#)(MT.sQ>+#-.MT.DDc>#ekw6/$:F&#k?hhLt3L7'CPDcV/Jc._dr*Pf.'S%kNI=ipoSf=uGjKSIvKI`j,qWD<jb_VQMp9v-gaDj(0on34RC/2'LFQk4oLwCah4b1g3HOxkRbtIq0.tk4--k>#7H9&=@CP/)ar)<-tPf9vxo64v6(>uu$-S1vvv@1vpd%1vlWi0vCl9BuabpS1fL(##)B&##nA)i]#`p?^CCt-$L8:I$VRc8/:qTq)RAl-$]`l-$3=0jCmj]b%5Rae$[.LcDSuh'&<I#AXxUX&#RYPe$Dnu=YB64F%1rsOogd+poWkX.qG&/C&h/hiqI?Se$@nhFro]+##g;Ig<8nw6/&)###`*v=P[aEL#.xHs$Ew/6&UjlN'f]Rh(vO9+*0CvC+@6]],P)Cv-ar)9/qefQ0+XLk1;K3.3K>pF4[1V`5l$=#7&n#<86a`T9FSFn:VF-1<g9jI=w,Pc>1v6&@Ais>AQ[YWBgbR.GW2SvK>_anNOQP1P`D7JQp7tcR*+Q&T<*S?UsJUfCOPr+swUb&#u`U6M4=f6M*SpV-0@(`&UsuXK[OJdqJUFErXTk9WDunF3rNmlEP3$aIc5/?KOH_9MC&$7X2bjcWLudYP:K.m.jM7YY0vHS@E*^xbKU@/1JxR`Wlwh(jw_V5&k$^S@dDRfqeNvfC[x+/hu(Q;H)PQG`s_Rm&/rrSIqe<N'Qj6gLbX?)j&rPm8.%:aN2PJ/q2@Zm8FS%HVkkog(vg4NT4&.Tn6XMN9ZROaWT$)Hr*sma3^9=<H7I4BbUhnN0*n86SHU:HrJ'R68_w,$YN6<BtV2lH;aqTBXu3Ph(G(iBFMsiTenHSn/P@gBXZ##%#5<r6AudQ$YuG+bs%<ShCDUQ*s@@ZtZHvcb<B7Lhqdc++N-`i=$9aaOB8=Vbsj]&iLUB_+37J-o]*#Jc3E6v[cR&-J;.jrUnTLuCXVuW]>]#1]u#>3J`W&N2(p&vuHCK7j(X4KJVco%d<^5A>dsn'^>Bv-&lWeJ&Gb6K2_L?Xp8E^R,WO?69&,,OpJ:E1dj3N=QBa14^lCNnv?l;*Eb.bS?-(-$'GB_%9fw6Q??*xdpfHAwQ0ww93U$Co?-9vK?Z*=a',])$_Po*dWn&2Y3L2n4@-5k?kUfP44(v-SkCftj9].cuk(J<g'P/$j9o7D;:8h0^q]Jm:x-Q7/:]q=F.<0Zik_:I[.*0:3rAOW@4U?G).sSCa:8cU>xHSue+M,jwQKd`>8%6]###@d%H)+,Bf3L]B.*d.Ls-cNeF4PDes.f^T,5Tat]#d52s%_=gK1]EV`NLm)A+$xe7nNQrB8K)###hm#DW)1eU&:i###wlqB#cc``3Qh%i)HCD9.LJ4Q',u<2C*xK^#iY&nJp(;b7q3n0#5MwqL,IL*#=sgo.=66N'iQGw.W$<8.=lZq;$P1gMf]Zx6$^iA.'$CD3`&T,3-BAqD1(nW_+@Qv$hnGI61sUD30)JS@6f7^#X?':%b2kMC_>G$GxEl0(q'ZJ(P'Xp%/c@p,<IlA#X<kR/#&`'%VWA#G[D1PUFPF&)j'&k'X(g.&$^.tdb/W?YP-O9%(UGs-jN7#M*RH/&YNOp%F*MB#M0*##Qle+MGdhsLQv'*#kg*iMcd6lLft+G43`<9/ko&T/O(;9.x<7f3O7oA,@g=t_JTvv-=@[s$;xs9):i^F*U9Gj'8+P?g=#JaJQv(4'1D8A,`$r%,QxTN2$sB8.nM/iL'#38(E?ZpMVfv40T?;O1x+iT/khl3+$Qtx%YMI-)Pu.60jQHL2D=T60#LQ4(3`j0(5BR.M[Ofi1OA422ZBp]=8AP##tR0^#m,`g%fQ_c)nZai0]$%##sbLs-<)'J31E.H)*)TF4+87<.(Ot(3?RYn*qxpI*JAHg)8qLhLA+p+M.fWa4(m]npYrjT9>^Xacl=+j1l@4j1]K$X976oZI[X=X(%iNX.7M>YuRLhW-/L$C#5+iZ#J-iT9EfH03),Yj1Td.k2:Y3B-@f:T0H8h9%xFRN'1gcI8g_b&#r&eiL+tI(#e,>>#+Q0W-lI[?TE4vr-gc``3d^s/Mh:U%6uW2B%pBFA#4(XD##.(:)uT4x#-/7#Nrb623kiW%;8<=h:)xZP;]6t%,Fcv6LoJ,$Gjb6k2#>M0(AabVfj_6k2IhhE#T0l;-L.4LEb^Dp9nC,`4)t6LEcD.h()NV)3nuJ-)IYZ@b<Z@=7e8umL[pM...82mL9&RQ8<0%w%u/0s$O),##$.A5#Dud(#hD?9/Kp?d)=9..Mx?,gLh6<9//W8f3LhwLM$*>>%llBF+Mfe.2oKx8%n>1q%(0jLFaWgm&gUw8%c=4h8ZdERDH2XW/fKgq%6kGhm7<MG*fOu;-s4pr-Pf[+MmQ2AN=[,5M-Qo'.+x4gLRZfF-Zu0@/O29f3G`8ZRWo=sLE$Kfhh+qumeoDE-jn-E.Z1X#A1s7&ugwpo7O)cH3:E-)*B.i?#G+i5/*e75/.Mo+M7h'E#er%@'G)l3+e?lD##Dd8.lf/+*W5q58'ix]$:^Xv#t1wj'-^HE3j,q`3_Gik'h?<v#<V?X$?8D_=DnE9%V$'q%=cQX$MFRX$O=R<$<eYN'3wlB$UA*hLfS0k9OAa]+bxeL(LkI8%=c;Q&=&4&%LNKY$&VdL-%lL5/_1N`#M_?iLN@7^$Ig,BZ.9j'%2+j5/krvN'qf3jL'V5W-It/`&#;t3+fYi9;_dh7#]P`S%[P###G@3Q/7x<=.*W8f3*^B.*`<$R&s6)D+,kn=-O(:B+'/fh(4oJfLlTqLpIPLJ1WRS70Sg'u$ZVd8/lPi63k&B.*/DmT%i[em&]1US.Q/*&+K7p,Mw-,GMT.,GMfov##>`x<CTR(f)_M0E+T#S.MBv7RM<gQ:vkLGM9j@72'#5;x-o$258>?qB#d/1U%1DcY#-aEjLO:-uuCqN9%rU6I$UrllLCGZY#r+TV-[JMk4tiou,7xH)4mm9h$Bb:hLe&2s-,r:T.RJ))3pBtR/OINO@Ff'K++?_s-_XB^77V;^@B-*H#V4BtL]s1O@QEt*A')Sk7us2E#nea5MDat[tPSs+j?090)l^;P(?W]88Wu_3='4FW-cn'mTY3v7&j(npI)qm4(sri0(j1>#&OEpm&U8D?u1.$I6FJXGMGW?LMKCR#%Xl-F%-HW'8viWI)K.De$.#nA,1U@q.iUYV-O8`$'NiJ5'Qe&7CjbH03ifZ3)'I1hL_o7LE_VPh2BXO>'e5)4''VI=9&?Oe-8B4m'i8x21R$J03>ekKMHY[;#ap3$Mx]WmLkDPA#Lp--X?/B.*:'ihL@t_.Q;x/o8N`ptUwcAZ/1ts'/cG7h(gNPwTd%g-)#48r8'F]M3(M39%h*e)E*l9LEKMN]'p$O2Mgma0(fCRR9cP^/3@*m3'_r,++p6Nh3?hjp%+nm---Fc&>fwpxuW=^;-8-NM-&cmM&W:%T.oaVa4bWw*.>dO59,WD^4NE/M^@^[w%X3aZuOuvr%S<^F*3.9AXEd14'Cu:?#xIF2(`V(0(.D#A#VMtT%`8ZA';iwcV)]Z<-2bBH%m'mo7iBdAmpMGA#,39Z-?:^k$,++m^OOPk'svwKumR[r.mo;MKQv(4'5g>CMui[R;r`P??/g0E+Igpq%tu=O/fL5C?sg*58.r(T/T$Gp^?r0@/BKc8/5>PjL[H]s$,Y8a#?x>[KZstP9B.p,3wc``3tTw*.SjLnLSHRV%Gv:1;Jvh>$Q@d2Ca7,gLpxon9SB]R;ODW+GCWI/(Y7[R97EL%Q3d<JMV]1DNxl25MFi:p.$,>>#`(6I$df$>l8c###IwAv-%3<gLc1Ej9^O1E4^MCoI2O0T6.vR[#4HHH)d>***&^Qk'dD24'`PP>u*^M$#lNp$.$]m&M[N,&#8>N)#mp@.*[M:9.g18C#*OWW-fHRpKml@d)-i+%OL[jr?Ah(w8IIsm;oWpIEYM8LEuL0e9Ub]R9,H$9.-@H03@OpZ78<9X7Y+OS:&S=<BX08b>dG7#%=G_R;4G?kMLE@v$)(L^uhOTR9hc9R1idb2M#&;'#S(jI.dZ'u$##q;-Y#vp%H77]6gt9DNLgN1)iP&gL/_'%1j#-J;<124;@279%dNLV%>?.]E[Xpm=NM,($FwaT%>==9/k)Ig(?L0:9gVg=PeN03M^?#k2Cw9lMPVaG##LRg:Y`l8/a<c4:,Vu'&$4Es-Sp7iL5K0D9R';Dbt4)F7^dh7#m7Hm'dW-Elk.)697+=WoB9u99[XIAGl$TT%n/>>#3l1v#b:3/(Ia9B#ak4D#:N.)*Ja-)*:Su>#F;8Q(VcfI&UQ^m&$p)AXUd>7&+UH8'@gru5bf.5'T(tpu+1>$,]3n0#Q)###NeXfLlH42'd=Hq;UCwP/r&+Z6[B9u.>XqB#Yfjp%%C#_'vRsNNDS,m%ZTOp%b,E?Y/n(R<F^8xt-;g=u0;Lu%ZY?C#5_<?#k%AA4f`aI)O#<S7h*-B#Q:L5MF5E?#F)=D<^fUwTr&_B#;G)e.S=:G'PE;U3)L+m#bOc##1=t(3+dfF4Q?TR/U2Cp.A3ed3V@A,tZ<j?#Y*DM%g5uh:WeZp.+HHu.UGt8ACnd:7Q6ti0'@H<6cMk.)SlXv>M7PY>s6s<-+$Ee-wi31`FF1L1Daio0@P9s&Wg:,)dK*>JU.vaGYb.9(%,<K1q6.DjOH%29gsAv-Ja=L#75Dm/Rq@.*dZ'u$d*2.MA@;X-88hd4nALh$KBIIMAK=:.bl@d)#=oT%m@3AF'AC32:0GA#^PlU8+C>D@kA;ZuV^d(5C)0D5h-$k'4qF[Ic2fP1._x@#q]ZjNGEkt$Is*^?V3aK,>L&r8_EXsDe^7MLZr$-'KAni;@98S'I&IS#s$cL++2GC55vW_AQ7=t$l&LA7?,if1mx;+&(>PV-cSs8/#'pS80IGBZ[toe%EVYV-+87<.M:O-)Dl74'5vQ#8jOt8(]Cga4,#@V/Fl(v#?j6h(TS1u7saZDuPqn(WHB4rl:ut&HN1qt#oH.%#fWt&#5g02:e7nwB5V'f)eS(I;8o5Q8(,Bf31EQJ(q@2V8BGQ@tb;)4'+^FY7>3fo5vHYA-FD7D6^^$5+C3,>J=o3DWOH`*4[W*qu:nv(5T*vN>$Ps[kmaA<-i#B%)qg/<-a%Cl%#-#9.,r?Z@s]%$-*jZpS``CI$n`1W@:]L=MH7a0(L3ia41si7@gg29/4PsB4d'CW]`9W$#[U(d-q,os&Ift/Mc8V-Ml7+/M.V.)*'-$,sUb<B-?hU]2C^^q@T9H#8s9?V/*Qna4<))P-CED=/[*'u$P0;hL/#6<-NMKS1K7)4'-=rl/S$xs$c4mNM#(^fLwDj0(@P,uuY6Xt$8USCMX[=?/tWp%4wH7lL0]T4MD?mk0fl)4'-#&#/sri0(QZ`Qs&f8;[g,pq7@kG,*?:;p7$Ws6hg1kZ%s'tn/vH%1(FN9U@,&iE%p/i0(K7I'&1V/4'd;24'Okk,#nwD<-cP#E(C6Bg)#<^3MqL]L(OdnJ&$$d3'Ix$5)`Ai0(Lfe88+'=hG5N'%M%m6xkZlQEnY4;mLO$TfLXP$##Fx#;#eWp%4=XER<1mqB#*cj>.sri0(Nt5AuB31[-VBV0P<GZw0oTVKan>GA#Qj+W-1shweJq+[$N/>Z@M9'b4Awda42`gq%cg-XqskKh($jaa43(jV$Y?t9%JF)?uF,$aM&<Huu#>`5/;;.$$d_LP8Uj[$TH*YO:PAZ0)dg'B#<LqDjCebRMXw%$4.t*qefcD8&oKZruGB53'qMT[u>h$.18[:8.H+mYu'_wd%&$0<-B]@Q-hbNvN)5dp%:deB#?K%1(LKw4](i)M-2>rn;f%sc<C<mv-WKBD3B6:h$ap*P(XAqB#Nk9x^(k4A#Fq]r.)';=/uPWU.*N'[M6/%0):fp0&krK?unVtv/(34^(/U>Fu9#>g.X[?K#mDiF8GD0Z-m+?N)ipf@#9GZT.16mYu;c;a-IXw'&VQ^]=u5IAuXgwv7C7xJjkZP2.U'AW-F$$w7T3>V/O-Xp.pS=Z@I$f^6^IUp$r+vs-A0JS8GgpTT:+&Z$(rE4::O9j(b;@#%f?T;772/a3Iv%E'Yo(NMi'jXuOx&2B.vl$0r`oZ2=m.MgvW(&+Vh$##`uUv-rf9L&.Tkwnr6Sr8WZ'=Sx-h`$<^[tdW;dt$lO#61Y6Xt$2[a69CO:a4bZDhL`r2?>Y7qk.<epq%wcGl$w'2=(QOLKaKlcd$rC$##;;.$$6qAo%EON:8KdM<%LW1,)dg'B#k.BB#o7j>P&>H&N+dSA,Z>hI$d74cM+'0N(I:cZIojWV$'+Bq/7dN@t)Ip&$VUHuuq.>>#%$$;#A6r:)J=[/:J-KaY+Pj/%8a,F%W:W;RFadd2[%v)8F60TKFaXw,g.KQKo6cX(sT3H4$XN6/@n0NCvCS#8A3nU&D&ba4i@P$8W4n0#WgO+`d+?H.rjP]4o@Z29i_Ove)fb,WrI%1(5KQh(_G(t$cQ(0(,j-4'1Y15/Y3*]F+1Zm8ag[A,SX.n8@,,d3kVQX$b?hMUUbN0)VF'U@Y)Wa#TF/j-1ZnE['#x5'g*(oeh-$B#(iDwTpG(>ldeIk=@XI5/x0oG*9-X7%dN8s$9oe:%ZTNT%m[w`am-0f)Z<q4fYTx[#[UWE*$`x(NLiP>u.p>>#Z#+##vq3dtgna^-%)V/sU'N?#J(v]O2ECK*`%Bm$c<Xp%:SsD*O=4)WPE>(+:r%l#cCpF*[njh$lptX$Sf]>*#P>i9+'lc2q,7+*F26Q&94ol##(s?u$6n0#wdI+ir8nCs]re#-_tu,*VUx3Fa8t1)^Zr,2$f2T%f2:U%t6WN'[IRW$TLMp%f8_6&t<&0(ZCIW$5pPj'ZsK^us;k9%0q08@*ob]uRo&kLKXb@XAT.2_[Q(2hHNgG*-F6$$#mqB#]p*P(Do0C#fn#=-w;8T$d:bM(B0B)6dNFT%4<Rl8Cw39%7/Lc`FIVZu4.Uv'2,Guu^Cj20c`08.cc``3%N$xe<=S;%'.c)3Mh%@#YxcC'':-AOQ_`ZuC2'sL2gg309Q-&4Of$T.oN/@ul^n'&P.A5#qtd(#O$(,)kC@xe&Csi-#r]@'eWeNBru@I,RS:JD]trW'rbn.(qI4Q'kxp=uJPHb%MW>Y&@>_;.Y@lo7kF$C#w#?A4TPGYu5RET%1X6C#9Xap%ScZm&mnX>%qt,YSQ?I*.,N<%?8qG,*&k2gL5HII-'VI*.O5.'NoDv:$*5PwKQGY>#taN1#L)MP-mK>w.k%AA4wdCwK5,<Q/+K;<%NtgD3H3&#Gtfp#Gag^D3xjHs&>4IW$S0J]&SuhS%'/`Q&b'Q'#ih/*#r(V$#$U.M3OnUP8qI%rmK-kT%Tg^m&3QR:&GfsDtwob._],MfL22ut$aaf;-bK0b%PbEs$0J#n&SWp6&;NVfU$l<a&QK53'pvYY#GEW:v9ZLA4dnho.8Gr_=v`6#6k]M&='4r4)8mSc$A6gIE_[T#8Y*:HW]cgQ]7%54'a.Gc41elo@q7;Z@aC8V8qtd_uvr@@#ZA0*+Y-m9#%&>uu5BCn#8*kW8'@$a$`rUs-8Fo79VS$9.O^c3']8^v@b89(sx%9.0A,IdjRGW1%,<a^OT%Z48u?HV/8>J&#rCbA#(@PS]ZMoP0i:H,3N0OW-F=Tet:6wA%GXR,;sawQKd:pP'YFCW-3:_x5l55`1MSlq&[Y2W%_L_<-3@6$g=;CZ@>ME<%Rs3c4vVl&5pm,3'MpAwPv:*;&NmIElSVCI;[l`L)1vQJ(fT2^@bL04'ST(0(.kcp00>b;0,`gq%v&j5(Twk'A2Q,tN*,f(#Rl$bO$.uo$kv849_8jedT$+kk&H8f3vh#h/7%54''tBV/1hG3ke&kc4tOKK/LVW?'DNSdNl;[E.@vba4Fh&6/5x#;#4Yu.:cA]'J_:tV?wEtM(&O4U%s:S#8re_g(VXca4'ADO'&LF2(]d<Z@Oal3'OFDNCcG7h(^jl0(Nk>-05@Cn#tke%#:(5*:<9cD4^n[6%&%x[-]B&(%CEK&ZxdvO(?oBEWLK?18tv;E#3&[#8SVhW/A/[)kCF.h(hf#u@.tAZ@@A`/8]Bjn4+8pa4c4(##LFS/1ksp:#frgo.e*gm00$ArNs.E.3iuOo$OMRj4[Z*b[X#8gLfTs?#a5o_uH_d68`XX]u?ca9`6a387aoUP&1hr+;KbR_8lm7f3Wjhh$>4vr-ldYh#uJI-)Ilmo']Yi0(sXH[#g0Jh(P_`$#%2Puu8(2,#`RGw.]Qk&#o0p&$sWtO:F5?v$s_M/)<M-<-EnN30Tv-4']<mu%wA4-v2E%bWp-1hLt,@v$v&tV$7G]=%^3C4fqXfY>+fb,MF$g(%S2YY#osp:#HPUV$CI;8.80g0N+q8V-.*.#%$g&+*-t-AOp3UkHMk'H2XB.0(^IIW$`L:T%+?i/qdlG9%d,nVqF+mYu(rmo%%%u];mcn92,XTD31EFM0CUH=J^he'M%XOjL;ICp7Xv?@'=[8Q/l/^I*(pcoR^'MgLb**j$thWP&u6q-<PF]#8e)m0(cNma4io;(&3L-iLrTS1(&RfI4vqJfLTl,J_TsgG*#bK*<vpBwKIJ4gLFDfRMreaNMExVf:W?bM__7*;?(wFoLvu_#$TNb<-1UP)%o80TK5w>V/80Gc4;T?)uBC0I$x?pw47YFR*Lbe8.%&>uuR+@p.S'+&#mPA_m5g](%XnR29lD_B#*cV#AbO94'<P;:%R4/AbkW(CAGmM-)dPvD-4[?YPo1Ds-W&l[&,)]L(1xD9.283h(m8Bm8Ah'#Z>?ab$aPqs$rSB[#qR2a-pa'dt[Exo%s@AD*f]/E>*8I.%RkvDc35FW@&dm5&bvQX/4,Yv,CLr?#fjrU%lwV)%Y+@p.`2+##<MTw9wb$##qIMW-_2Qd5Au;9/BI?)Nc/s<%`&PA#S$]I*L@[s$ZVd8/W:d#u10Y]#.sgr.<CMO11L>L2Lv_p%5uFG0xw*_553WN2^=g020-`*MF6n3'DG250US@i1Vr0N2>uB)Nh)nL2.M4O1A:39.)cV4#=EBN9uQRm0`@0+*d1:HM1pYA';iwcV0/::'MPwS@e5C7%GlsPAX6Xt$On8c/MaGb%<uwKs0#5$M`Ro?(Nn[D4/iA01hf`#&YJI-)(Q5$0HFp?.'gZ#8`nbEOQv(4']Bda4RD%5JCuF^u7jk,#$,GuuB=^;-W$^5;u<*wZZ2I4$b1B+*bAF>Mjm&w#lwaI)GE#3']aBB#(NtT%Vk^hLgLu9#]OFgL/?+jL2flA+b=X)3HD<1%n,C:%OOV)*m=7)adX=gLZG/-W66gb*m2M7W`;$;%OBFAu<6J@#7Z<Q)Ots9%+>4S7NXTI)9Q^%b-Ua9`mZ*RE^n@K*>ACv-a1[s$hDQ/;spE#-u_x('Q0Yq%...0([Xns$a7Up%?btx'fuf?jI:2?#0%eS%:oG<-q.TV-w2.[B/@v7vvDH&MpkA%#gQKl:n@mQqPId)O2dMZ.cH+5&a?bp%r@1&4dbrs-hOugLWWmuu>v5D->#tnLVbZY#Ii08.&ufg2?mkT`Qah1;nF6.4<f2u$ex],3d:l.:LU[S%TM?xbQqns$`j1h(jM,N#9UYH2QV$gu<_jQ/+pl.UY6Xt$2+D9.FrxICV,N*IX),##%7]P#0sd(#g$(,)YsHd)sS%_Qc%Tn$%BOZ6PX<9/JS5W-s'7s0Zju[$/lAd)drc31%/AM1K<%b4&qTr.G-ia46FvQ'L`HS/u#Ot7n40p7fRNS/[MC*<]rv?-PU&m&[+iV$w-np4)P`X-rG3:MD3.87]k32'+'fO9>CN;7T>BX%ZN4T%'jIw#:hjp%it.CP,+ih$,726:#4_F*(M)I.=@[s$0d/dMlb6lLgu=c4[(=MKcb[a45=3q.?76F[>WrA#]Nsi-gbl-ZVlI21JYIPg^b8_]aD:;$YVm$$PXt&#&dTv-CV>c43Y7%-J^D.3[GO,MhHUv-GH5<.[dCE3w6x8%lHr%,6IM%,[5`0(@17W$E)(n';[mc*o,qQ&M;g]$<X3t$r#?R&Hhjp%EbE9%rv>R&FR39%cN@*Hhbx<?[gB#$*j,*4ao^I*`bP/C41T;.6(1E37YSd3Ji7CuXv(?#x6;ZuMu($#lGa^#%V0^#2<@*H>]d8/vmO9`1DXI)Gb8`&NR$(+&`5C++o@TLkA>]#@6x-)B+bt(&PF&#m8*B#i>dgBINF&#:vkG3ER,@.2m@d)hk,E3jsjT9D=H?ImCI[-Kx7C#[v-t9VF72LL:k>-?Slw9nBbA#o(x%#s)xpAt=L/)KRxQ/7I9^'KC0^'B4g;.h2XSUr1%5Jo]WVRMnp*%6'+m%ZN4T%nZ+T.`l53#S:J3%Vq'E#*b0T%]7%s$da@hCSKK6&0v^pR3B7X)/nX6&/pBTR*),##SG6(#qQ;e.VH?D*SRl_$GG>c4TMrB#TekD#fFuw5Qrun%g(^iB?NiZ>RKPJ(m.4e),&uV-RF@qffMM0(boNe)2%l?%l4fM19xxV?A$qj(0k'u$SxP:A7V2<%l[KF*13Dx.wc``3q=9#]Ex;9/l#l7%/sTm?Ei1^#`OfO.).'N0Cppl&v/^f1r6[c;JeT/)6um>-`JO=&.'_e?5<1^#B*Gs%7F4q?E3G&#7(n;-/DOJ-&#sb&FN-5gU0J<-j=t(8(N4Au7xToNg0P1#[?O&#%NOV-@S]-Fe]jm$BM4I)JtC.3#VYV-OM>c4PkWX-wqAv8u(e3'Ix$5)/]da/=##p4mJ^@)f&'EN<krr?e<tiC9/uaNFts,#0>N)#f[a`/_PiMi#'j#9qblA#dJ2n)lD:Y-$Hd)GeIH##'1qB#].S-#EXI%#diPlLH<H:*^0b>-lkNc'.doJZoLFgjG)ACs9[IRWuorQW2C&/151'SWDDRv$^^D.3%46XVHr^a44t`a4b#U$-9_@x,b83I.)oEV/6f'<RY5Y>-%_,#U%B_l8Sr9B#/$$;#qlP<-9WvX(lTX1DakSm_*A*f%JLgv>X'4B,];(B#WOw2(];AalWV,p8ev<#-9@Ns-aB2W@krw21EDc>-ZSMU%7-0<-_PSn$?S9dtZ^Gx'gV_%eL&F?)AO*W-kBt,ODm;+riL.&exY,;HAwDn8J&i52[=6##klc8.@n:$#PlajMH=AGV/,'%'sg*6O<NupRiS?M9MoUPgu<IQLQUw[-sc``3ICuM(r6KZ$NC^;.r;am$r0EQL'*[V@hD['5S)24'q'3;HQ_`Zuk&qK-7iCU)$KI-)UKos$1Gp;-8Q3b$Zx:<'J)Ys'Hk.Q8t:>^ZaC&l-D_3X-Z<n)5KI_P8hp`#7lnZY#e@(##6$x+`H)w%+A8(`dY+]S@jJjV7aBJ<-l=`5%lt`W-uQtlr$rJfLj>a*M-<UsNvVSc&TbF$@v(N0(cJ%1(P>9]t7)C<-CQQD-[C2&.3PvtLp_P&#RQvw5:APD%mDps76(Hq;w22k'h5F&dY?-1%Ot[E5UIZuui6J'.?oMuLo$T%#)kP]4BJC<-Ik45*D^x2)(9:99IGmv&.pq`3DK*hLtG9@%u5ko.L>kjV<R+<+KT>?-NMr*)%1Vr@rQH&mbSv6#Kww%#uQ6Q'3D5jB1Oj?oqJ;B'6(]E,iS7U&dr+q@7I^'-.aS%9I2RmO+VQ<-h#kC8BhrS&GO'3)/vF1#Q3=&#Kc:J:0uxc3%d>W-hQ^f+Rx%W?TZLk)9D7'TA5rDc$NoI-[&He'q3n0##5B6$PXt&#5oE<8@]L/)-fV<-[da((r$4?-7]wJ8tB9Zh>q$@%$v1'#isb<'jk;68`5-'?UThLRr+Fo(2_d'#v]8xto_h._;d`]+EYMH*O7%s$QUwG;])VT/k%AA4R`>lLsuU:%26Hc&ZT'q%3`,q%#0g*%*0g*%M*N4Y:X%u-%'<fMMT.JM?*/YMh*eN9X^K/`YnDM02S678Z$okrxO]L(;K3X&@;ADAE;3EGf#eI)4D^jD:Hw^8x`k2(cN7LCtc*Htdn06Ad#AKsn8,&#W*s^%Ua+Q8tQP8/+NB9r?S)3r9D7'T;TQm2@sJw92FLWJd[_p$Lr<^Qba@G*H7`q7x0_dkGTh[1Gb9oec[*SnHg?D*;aR#St:Vm9AlkA#qa(x(ppR@<w_0^[jm`>9iZO&#p-;p$Vd%-#Wj9'#W0or'f[/?-#P:]&5&t)$RvAZ&B:ww@o8P&#<4`>:NXCIR;EV^$0C(XS_kcp%NYDkWhmC`jhg=G2.hN)dkkpiBM076Mt&.Z?j[g/)j>0gMj4AZ9o`%T&C0ON&Ns(M'3n'W]Y:O9@dDP)kA.Gc44ZkK*cq5fCjJ$5JQ_+K1vNt,+-Vkc)sF0*+OCMd4/c(Dj44co7=$eK3hqTk$a&S5AsPnY6SJ)?-b(84**8-8(,>nLKo[@>-d,Uh$16Ts-,GnV8WSd0dq<xmqJwBHSbOE3(Ui6vT$stC0ChNP&jsXc2>e>lX<eWs-'(D58?7W`bE0X<-c>eL-%Y)Y&>(L+*?-QTWS&###^f4P]NK[i9%ro,3Ss]q$a&ur7iq+-5<reC#?K*u$o(jX87[c,MJ=UL*17xT%1.BH<R>op&E_?q7'Zv&@W7$##e-N9`Ya4J_;Vml&po%^=Oua)>3kHA%#rEY-2;)?[26)$B[Xp2`a+c'BGcXlXDg<q@mN;W^oX8,9Ct/g22+1k$beu@>:Z=AuMcW#AqQSZ*%qm^#jH.%#5iWs8lSia4Bhp:/#3m;%Sp,W-^m:CZ8heq.[5MG)%Vu42)C<v:>2Sf3)Wr?-F[WT%`n/m&i#p^/nfc;'S80TKn(Tp/d/i+9kn.U/%<$3'Eq(&5t'54'DR#&uYp`gO>FL585#>3)0=4)##?U='fj8q7UI_VI,:*78qpC</`J'a+W####R9<-vgnf&$7g1$#c.HP/2$<JuZxB-'8<LE6dCv98+:E?8AMEk>66%O=H/5##vm,D-i',M<)DSW9MbW$'&S[k=Gr(?@R8Rr9iIRk=X)&vLNk#m#jH.%#F>uu#X'==-PGS3%?4vr-SmsZ)Krq0GkS)O0fr@[#Z_`$#;//vLF_k,885T;.c'7=]mw.f$2^Q88;@e<-:[@$8i3KGNHDV,;bN'N_&^oo.ljS-+$`^iB0T7*-XNMu9u`lA#/D@e%f[EpL.jmi9GF%^P92pmBoulG*Odna$Rr:m8iru'Z]c^-'F2?n8NfpvJRVB-'(9DKOc?Pw$pXZj;PINv'A22Hb8KEC8iL4Au?_*(8^2h^#jH.%#ko6r8>pYD4<rHm8f/+vK%rp9*'+Yv86ftU($ut%(,.oDSRu:W-IXMLWnS$7,^=3?-h/Go(V]$>-t^Ml-E[It''l4_$#C-2Uv;wJ*NGcQ8pV^VIvk^&#CXwZTUpVfLK>62'[=PV-XT^`3Z2Cv-3mDF375^+45a1,d,<^'&>cM*I5=H;[_H-pM/FwM0`m4T%k)(U%8$Dr@&?1Al@l-[BW1r8.;Vml&b9JPBxLYjDJeY@(T2l<-PMBW*<]^jDXRa6&>]^jD9da_8b;c8N3)'586qfcj9TYjD6MO;&bk/J+b>rX%mEU.2Pdl3'i.KQKL]34'IY<T@#qg6Sqhx_%evcA=O9`s/.rBx(8bn68eb6^TT2Puu$3MG#mf%-#RKb&#)X_E'hsK=-l^*_&7+0tB]DXg&#A3*Ct6C#$MNH'6l-4O:]I#WMaNuT9]8<JS_sN0(cJo4R(6$##?0Hl$0*'2#^Kb&#-P@V+`*ub<e<@>Q'soqgf5,*?dUUB#'H(v>sCC`j#Fp98>rX&#TKNh#Xq[+`t^8W-)K#r`rZ8<-7Y(E'-l>UTU7$##6DK-QNRjf1)P'hFtSA@+um;t?kUv'#v6YY#)#$;#0jd(#_rBfb.U%I'w_>2t3+ce),39Z-m&B.*:D>H$/DEO'5vQ#8/aYYux`.='/5B$,0gd<(/gf2)KHmSIV2-sKE2w=lG5c;-lQ%V-D?R://`($#RlIfLR6gq$NIcI):`TqDAM>c4@N*.3LC<A&jmgs-Ja:^JMxe5'Z6n0#Q,no@*x);n$PpD3fH=GJ=o3DWBrY>#cD.h(klqFVi*2mJ&l4B#MHDigf-sM(7d,g)[Dau'W_w[-<n8')wU/>(r5)4':T7^#ITAj-j^a;KPF$##FG*5v/g?iLY>M'#wrgo.SjQW%=fXI)f2qM:[^A<7jr/+4rkCI3_(<v6k+J^$xuXV-?7&M'1?v`-2md'Axh6X7Z$E?#<3*a*Y74h(8Q:87&n9*<Ln#12IJK:'$ViA#_<oA#Iu%h(k`2iK$',fUa;MfL1^CL.L?)Mg(i@CRLimI+YnlX.2>uu#`8x#/(NOV-6ZV/YBcd8/Y^Tv-w^uVHS;Q0)1vQJ(+gB.*,:<p`fSH$$)3Uq%O>'v-/hRX-6$81&e^kp%kv[5%f:XM((TA[,&MXi(8s*qe4D]>gx_n5JG;sl(/dtf*btoK(?G=I#<nu3'o[v@#)j*.)9hjGm+h&'&YIO7Wq3n0#x+'q#vsn%#I8nSJ0]bA#*K$K:GE$C#m(j0(cJI-)-x&-)q'b8.RI=H)EVm8.Fe:S(wvh/15Bo$#%)>>#N.96$pn,D-bv?D-.+cR':H*XCjn7@#a6j'O[jir?_e:wIWqlc-:Bl`@Q=-##Bg732ocl&#C7B0/dKVvgp(8h(n4=@-m>&n.9$$;#f41Q8#5T;.<.Jm/vw?=7v-R=75&pc$?<TF(KA&'f_D?V%*l568mZD?54,:`<-3frQ[dYk'@OkQ-_9fA#Jx.h(d3n0#Epi&#Gn)uJ^IPjtK[LW/tb9b*-jApJv1mA#<a@N%%*:dOYA9s7sl:e35IL,3sTNE(SeuUZ6^^j((osA'KS:a%4[n;-xIl8KA]A:V6(tkD0Re902U)##3Q'>ltr,F%.hBd2T?A#G(Y&g2)sKs6Ao8C4Rq@.*7HZ+0or<K(T.iv#I<)T%d/CU%3*V%Mp78X%NGeouST4mNH+)?#9dvg%a-1oeE-Uv'5G:;$-A###acY8%p##,2DLKV6aJ#-3t(4I)d6c^AB$lD#ikkj1IUFb3[uJL(#,GgL4gZx6`<E:.b@Fj0&$nO(VT<Z@lN)e3>WZ20wocB,/tF/sL>L9;p'Yu%Xq`EO<9M0(]Li>7g4a#84a498UAO9'Fjl>>lK1</pOUv@0afY#7*Zr/*Xha4b+3`#2Sp--Di.P##X&*#SYU(.$7`j9B%/t%QPW]+rgai0=BcW-rmVNt,IL,3aWPJ(rPB%67?;)NP,#1:[AqB#tNDZu[uR[#N8(:8Jp0^ukZWw,K>J;M+rL5/vi*.)iQjMMZDx4]$RirQxG^e$A/E/2so$(#dA$i$4kf;->,sE-6?kV$%`nR9R^#<.U0m:&%N(T.I52k';:rp.e'Ld#`S?tLPRha4O91h(qw%T.pMQ#8wAm`-iBMQE_/QJ(mxlP9a#^G3DJ)UD.+L^#]O?1g?r2ZdY,?v$1]x?Br]wSu/r@[#J3ZT13*jrQC_39%ku%,MwQ#F@`p?o#ierA.qrgo.g8)jT)j]L(KQ#]#QKF2(-emuC4v.h([Uk0(#x?=0^dp7)%5YY#^x5I$/e<kF4+.5/%Pg?[QSK(%iJ))3&V9+*>HjL)DM%[[ku0t:Ba&wQK-kT%HH2?#rMcBZ=ui$'VZ^m&gu[fLMe;v#SsGw[O:$##Ur[fLUrOrL%f8%#L`L*Obkrm$3Jke)_rBCOk8W$>i1RLauKnl//L*8ox;:d*V,lS2e&59%Zkjp%XD7h(APsGZ41*U-e?7E.Jn7`<CqC^##hb,ME_;;$x9+_JE9%RNh=NP&nN*20iYv*3?X1N(QXkD#:cko7PLi'SHFS30hnRs$mSIh(O@ULP975B$6Fw=lmuo:-=SmmSef_E'R;7A45x^=)Ct=d;H<YD46<hm/7%x[-LVd8/:rXGkov>V/*xw4(EvQ#8aT2^@p$:4'j.k@O7t;r7]TND#a0Gc4%Bi0(.cV#AT9H#8dKh?'/Nps$+4c3`Ur8d#%<F&#pp[j%B4vr-Ut;8.7r5dM.FA+4n8ct-g]&=<u0N;7w.r;-s-iI&QLO`#uN_%/uv6muWWEe+s8.lftaXGuu-Z)/0iba4eNrQN2A'gLFO,&#(F9D3a8t1)I^/gL;cSUJ6$;9/:E_#$fle`*AH*?5OF@<$tjLC,6v;E#iG%1(bF%L_#jI@#U&Eh>:C'.(>_8Q&emmH3Yq#6)88Y7(Fl(v#%rQ[#TgCKMqLsYKoF;9&=iD]b:,^v^n%`oI71Hv$EVj]$M@?m8'J(E4?p;%$;k+T.b@.@#xBR-&`E^0K_r0^#5]<e&rS1u7jI]g4+8pa4h]MfLGC?##tGYE4Ui8>,JC$##R@'fFq[K%%AV'f)O4OF3;X^:/ns7f3NLp+MsLND#CbNW@,k?h(]7IY4*(kFV'%#G4#;AV/=Iga4g(_O9Y@Vv@=j3`s1pu40?+$pWrba^uAM`a4+aO*Idk<m/?mLA4<o###[di.0_SQ$$$_Aj0*,6X$8_t`#Oh)>PCr:v#QUg#&Yv>3'Bi1LJ]XZP/RnR[#A?Tu$KK>R&-P>s%mT=@/%&>uuas3$MFWb;IV8###xnj]4e<%##I^7<CncM]$l4NT/&lA:/R7#WI[scH3xKeF4St@.*B_gsLvh/a#c:qQ&p2eY#U#6v$+5G>##CLI&edkp%][4k$iLk2(hQL:&Fw82'qi@G&iptp%^KZ2%kFn/p3x-W$Uu2:/_:aGqww=gLeZoS%em3?kBqNp%vrT%k9<**3,V1vu7NUn#O=#+#t*(f)0*NbNTi;E4S$]I*udJe$@P,G42$ZvK]%>o$D7[x6[O:U'U+M&MwLF02@EWL)OKOA#6eM>#kQJG5h0)'4Mv2PK,@n>#&^P14F#I-)_08s$@^xU7@m@v71pn:/,KDJ%?F[s$'/s</&B6N';fei1[R3T%6)*L5%E.h(-1BO10Q=r7$%a<@9)uX&j3%##.+35&&U8a4*``$'^5GW-T#MnWiei8.a'/@#3WEC#SGPj'v(U@k==@s$2o'HM$+;8.=:.W$.7L^#2F`o$NOlB#wgbu%3(@W$*f@['>A0P8+qO['G5YY#;I=>ZiWaG3,GpS/j8dp.gc``3VUqZLR;MQ&iV9%kK-kT%BP6pJpLO[Re5[UMV^oo#$:F&#G0+KNaVSa$SZQ#B4sb[&s?kj-rDd=-?Zap$o6Op%h(q)5'%g+M4`YgLLH^l#wV)K;mD^;.suQ.%>2K+4&eaC5SZbA=axdC#bKF2(=1CC#]5$;%t0rs-'r%'=Uom_#B:fI(rBdru+2(j'9PcY#nHK4&E>5REWYvU7BHZ8&jx,abxhX]+Bm(Z6c_1p$rUFb3YZTC,ShH1Mfq<]bK#W]uG_sfL-Msu5(.h^#B/)H(m-TjAB/,F%glXa*c>W`-W]s-Z0sZeOV=w[-P%<..SZ2eM%s+Sna;HqVkBB`&<Slo;*WCFIIfhs-,PYi9t_A6(?u;Y$PIw[-,cQ%)4w89%FYR,VSn%@#KmZP/Q[rZuTkjp%&AM))P_`$#j4[,<nvV]+O_(Jh*^88.mN#]>3m^99jrM#RN[fDZpMGA#IOFb3.1P<%k;n)4TMrB#eGId)k_+D#TV2^@?Ixs$s:1<-]R9^7s+Yv,^J@E-/8l(53@br/4K(p/EZ+Y@T;CZ@:94R-*;001joRV6+8.j4POha4,d1p.93Av#>rC9r^2?X0Dld@ba&d]470Sc;A:Hg)vv`0CGRcH3p.mY#b0aZuh<Ke$XxclL@CJr%+Zi0($R+Sn5QT/)<Mfo7%FlD4<r7W]>;Uv-2^7&.YF_^%iq<]bX]b*kl/uu-O^c3's.[)kX6Xt$?+sY$Wa*g)?6D/%>4JKU5-uL'7IrJ:ca0^#BXVU%,:as-YOMIN-$;T.HaJ?u8M&N-1>)6Mtp#D-8-<#MZj;;$Dld@bKS1R<qj?D*od&/1j,KZ-ipC=%:I-AOjkaG<53Z<.)^B.*:#wu5NPo9D;82YNqilrHWv^p.6G$:7m:3IHUvM*I9ZbA<]S,=785YY#(=V:vlAHA4^Ilr-OaAv&1nsj&iX`V$Tl<H29T2^@,nQ-)+G,n&S),@#W.h%%NF^#8Bp#6)lTn-'VZ^m&+p0t*<(a95SxefL+Lmu#d#jE-gsUX%KIs;-+Xb,%B_N/):7*9.u3YD#$>X8/J$AQ'e8M0(Jg%Q^Y,?v$+A^;-Gq_).n)wENt38S[qb`p%LjQD*vIF&#v%cq9JI^n*]SdsQYhx7RZm/F-d:'w%&o$##1@6&%%A0T/Uv-U99XkD#Z&Gr$7oiM:F5JT&dMO$6C0oQ'QZk',T5o_u&p57&Vb8P:$$1B#ZLHS/A*DH2b'>V/X<M0(hI#[/EaHr%q)<Q.J:f]4QF[/:FIR@%/9j'%-Hc,*DWN=&jxnA.8U.+8t+@p.<,Yv,g)BI$%YS#88UcjL?+Xf-pRcd=?YR#8hru--5O-.MI8MjA'0xFDa.Gc4G>^;-]r:]0+2YY#uqd(#d+/-<QatWS5e'E#h[]V%h:j=.uiWI)wl4P]6q84(xadHJcMZr%t$$H-(G'F*&>t(k,:+<-k2ps$qb`p%e51Ip4nK5olb5C+bOlo7mrUq4R4f(#pH^Gaf^'Q/oqd(#'sgo.La0aE4a=x>7kQnrbuGf_Q++11u.q^/;8F6'E`YYu9ND>&CB3E>sn`:8V6C^#;Tm%+_7FNDPdkB#.D###%HW;-so,F%&h'u$I4ww-rpL#?'EG3`:DcI'05G>#x6xoq.DM;(fKG/(;rew#)EOR%2ha$#f3UhL(2ej#7fHiLnJGA#?1[s$RxR7(A;,f*I'Pm/w#ui'28>Yukt2u$)Wis%YQXp%/4^F#RkE.+n[`q8K&pE@j3.lBxWQPpoG/lBS#7_#YrlYuHE,n&@?H%+UNYq.wdt1K_VAwgcRNE,&DgF4>gQv$Y12w&?b;39X#Nm1^v'&=^0/3M`L[t1'qa)+IAW+M2OJs8^YkL:1Ol)4u?lD#*fwA-wrwA-_U<^-@ZUwKK_$QUVkvv&P3@*.AMre;KXCS*;0sbNmllq&0rg=CQoN7WKvFwPD4<YPuSSw>$m*B,bkh8.JHm;.(GeF<+i]m(^IwnS'cF<Un]-##MxW9#YD*1#ca5A4j?:K1Pd0f3R8qZ3*K/f3h5'F.l?I1C9:<_Auf[fLmJ12'N$'6/r&+Z6Nx,f*><B<-@aA32P=$##ca''#(DoHH9+^*#lA`T.+Mc##pB`T.-V(?#1@`T.VG?C#DA`T.71r?#?B`T.6%`?#lB`T.::7[#C@`T.l[Aa#)B`T.J<tx#IrG<-/fG<-OA`T.]GZ$$sK%q.HLn<$MdX3F)SFgL<-kuL0=`T.2xL$#hg`=-(fG<-xB`T.0d@H#9@`T.F6OA#uA`T.Ct*A#KtG<-8X`=-$C`T.U-*h#S@`T.f1W`#jB`T.h:s%$k@`T.3Q@)$1-#t6WQK>$+c/*#Xst.#e)1/#I<x-#U5C/#lj9'#2_jjL-o@(#/K6(#ZY5<-Ow^8/<O>+#7tarLVe=rL?QG&#QZhpLlwXrLSWG&#x/f-#t]W#.n)eQMt/^NM@fipL>+m<-5V3B-hfG<-MYL&OM:CSM8(8qL')8qL6:(sLc.<5CQX$##k^T%J$'4RDCKlmB$eZL2cS^PBJBYwnB(8fGXWmmDjF/p8iEv<B_b+m9xAkjEEU0@-^meF-xq($H9CM*H,,lVCvC^$.))trL^*B-#9Nkv/=NSiB+RZWB@T,<--NSF-Hr.>-PH<+0=`/A='DvlE/T,<-aq5=OG8)UP,'[lLKO/b-,X(G@MxXs8DHo(<XQDnaYEv6a%P1,N.X0,N68<MM.sK5PUkiMN'1Rx-QmXoLf#YrLua5.#.T3rLjd7(#[D5LMR`HY>->hoDRB*g273IL2Y4hM1HFme?vkr,+&B@5./5[qL0LG&#GA1).7mWrL1x.qLhY+rLj92/#FSrt-&$@qL5XVD5C.P@-,YD5B6J/>BgTV=B;kl`F]QKA,>2a5_i.(589BLq>h>$U8A[t#7*dxd-v(+GMQJtL^7uZb%&ji(txcc/C'8P>#)8>##*;G##.GY##2Sl##6`($#:l:$#>xL$#B.`$#F:r$#JF.%#NR@%#R_R%#Vke%#Zww%#_-4&#c9F&#gEX&#kQk&#o^''#sj9'#wvK'#%-_'#)9q'#-E-(#`QK'&w?V`39V7A4=onx4A1OY5EI0;6Ibgr6M$HS7Q<)58UT`l8Ym@M9^/x.:bGXf:f`9G;jxp(<n:Q`<rR2A=vkix=$.JY>(F+;?,_br?0wBS@49$5A8QZlA(a$DW5rj+MD0%>PO&d(WEH1VdDMSrZ>vViBS(f7eQfi:di++PfiuIoeX,WfCsOFlfOuo7[&+T.q$(_.hbS8GD$Sp(EM(1DER=L`EV[H]FZndxF_6auGcH&;Hggx7Il2u4Jn>:PJsSUlJ[wSiKx%n.L<U=loDF`+`/*S%kW2K;$0o$s$41[S%8I<5&<bsl&@$TM'D<5/(HTlf(LmLG)P/.)*TGe`*X`EA+]x&#,a:^Y,eR>;-ikur-m-VS.qE75/u^nl/#wNM0'90/1+Qgf1/jGG23,))37D``3;]@A4?uwx4C7XY5GO9;6Khpr6O*QS7SB258WZil8[sIM9`5+/:dMbf:hfBG;$Vg4]8Y,M^:SKl]aa-DN%#<ipmj?P;]N<H=x':oD>Heh2Z&#d3]8YD4^Au`4Wg/g2hIP)N$t2.3b5^G3oSkk41_E.NnUwA-;YwA-oe`=-`Y#<-hY#<-iY#<-jY#<-kY#<-lY#<-m`>W-irQF%WuQF%&*F,3&*F,3&*F,3&*F,3&*F,3&*F,3&*F,3&*F,3&*F,3&*F,3&*F,3&*F,3&*F,3(9kG3rX:d-kuQF%'3bG3'3bG3'3bG3'3bG3'3bG3'3bG3'3bG3'3bG3'3bG3'3bG3'3bG3'3bG3'3bG3)B0d3rX:d-luQF%(<'d3(<'d3(<'d3(<'d3(<'d3(<'d3(<'d3(<'d3(<'d3(<'d3(<'d3(<'d3(<'d3*KK)4rOuG-gG8F-_mDE-`v`a-1E+.-N?lk:=k9^#Z2c'&*tj-$4<k-$'LSDXS]%:).m6@'Mfv--x>sx+B1?>#Ner*>/`:;$31lxu.i&gLuwSfL(XPgLsNX?QX64V.h$2eGia$]-``6@'YZ2^#+7`T.,),##9K<$5&5>##^vK'#YGY##N)d3#jkF6#.W*9#aM#<-N6T;-t).m/^%*)#gMc###Y`=-O6T;-P6T;-Q6T;-R6T;-S6T;-T6T;-hH,[.<>N)#('HpLU['(i-D=G17S>:12%###=s)/,,u)1^t=R4#"
    -- ÍÀÑÐÀË Â Î×ÊÎ, ÍÓ ÄÀ
    fonts = {}
    local config = imgui.ImFontConfig()
    local iconfig = imgui.ImFontConfig()
    iconfig.MergeMode = false
    config.MergeMode = true
    config.PixelSnapH = true

    local list = {
        "ARROWS_MOVE",
        "WOOD",
        "TREES",
        "RADAR",
        "VECTOR_OFF",
        "BUG",
        "RULER_2",
        "DEVICE_FLOPPY",
        "DOWNLOAD",
        "X",
        "MAN",
        "TOOL",
        "LOCATION",
        "FLAGFILLED",
        "BREAD",
        "ARROWLEFT",
        "HOURGLASS",
        "QUESTION",
        "FLAG",
        "GARDEN_CART",
        "SNOWFLAKE",
        "RUN",
        "SHIRT",
        "PRESENTATION",
        "RAINBOW",
        "BRAND_TELEGRAM",
        "SHIELD_OFF",
        "TOOLS_KITCHEN_2",
        "ROBOT_OFF",
        "BOOK_2",
        "CHECK",
        "SETTINGS",
        "HELP",
        "RELOAD",
        "REFRESH",
        "REFRESH_ALERT"
    }
    local builder = imgui.ImFontGlyphRangesBuilder()
    local range = imgui.ImVector_ImWchar()
    local defaultGlyphRanges = imgui.ImVector_ImWchar()
    for _, icon in pairs(list) do
        builder:AddText(ti(icon))
    end
    builder:BuildRanges(defaultGlyphRanges)
    local iconRanges = imgui.new.ImWchar[3](ti.min_range, ti.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), 14, config, defaultGlyphRanges[0].Data)
    fonts[12] = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(my_font_compressed_data_base85, 13, iconfig, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), 13, config, defaultGlyphRanges[0].Data)
    fonts[14] = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(my_font_compressed_data_base85, 15, iconfig, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), 15, config, defaultGlyphRanges[0].Data)
    fonts[16] = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(my_font_compressed_data_base85, 17, iconfig, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), 17, config, defaultGlyphRanges[0].Data)
    fonts[48] = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(my_font_compressed_data_base85, 42, iconfig, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), 49, config, defaultGlyphRanges[0].Data)
    fonts[18] = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(my_font_compressed_data_base85, 18, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), 19, config, defaultGlyphRanges[0].Data)
    fonts[20] = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(my_font_compressed_data_base85, 20, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), 21, config, defaultGlyphRanges[0].Data)
    fonts[22] = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(my_font_compressed_data_base85, 22, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), 23, config, defaultGlyphRanges[0].Data)
    apply_custom_style()
    reload_avatar()
    try_load_logo()
end)

function apply_custom_style()
    imgui.SwitchContext()
    imgui.GetStyle().WindowPadding = imgui.ImVec2(15, 15)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
    imgui.GetStyle().IndentSpacing = 0
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10
    imgui.GetStyle().WindowBorderSize = 0
    imgui.GetStyle().ChildBorderSize = 0
    imgui.GetStyle().PopupBorderSize = 0
    imgui.GetStyle().FrameBorderSize = 0
    imgui.GetStyle().TabBorderSize = 0
    imgui.GetStyle().WindowRounding = 8
    imgui.GetStyle().ChildRounding = 2
    imgui.GetStyle().FrameRounding = 4
    imgui.GetStyle().PopupRounding = 2
    imgui.GetStyle().ScrollbarRounding = 2
    imgui.GetStyle().GrabRounding = 2
    imgui.GetStyle().TabRounding = 2
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().Colors[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg] = imgui.ImVec4(0.08, 0.08, 0.08, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Header] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Separator] = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Tab] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.05, 0.05, 0.05, 0.97)
    imgui.GetStyle().Colors[imgui.Col.Border] = imgui.ImVec4(0.25, 0.25, 0.26, 0.00)
    imgui.GetStyle().Colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.16, 0.16, 0.16, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.18, 0.18, 0.18, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.43, 0.43, 0.43, 0.8)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.35, 0.35, 0.35, 0.8)
    imgui.GetStyle().Colors[imgui.Col.CheckMark] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip] = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
    imgui.GetStyle().Colors[imgui.Col.TabHovered] = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabActive] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget] = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
    imgui.GetStyle().Colors[imgui.Col.NavHighlight] = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
    imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end

function imgui.CenterText(text)
    if text == nil then return end
    local windowWidth = imgui.GetWindowWidth()
    local textSize    = imgui.CalcTextSize(text)
    local textWidth   = textSize.x
    if textWidth >= windowWidth then
        imgui.Text(text)
        return
    end
    local posX = (windowWidth - textWidth) / 2
    imgui.SetCursorPosX(posX)
    imgui.Text(text)
end

function imgui.ToggleButton(str_id, bool, anim_speed)
    local p = imgui.GetCursorScreenPos()
    local cp = g_cpos()
    local DL = imgui.GetWindowDrawList()
    local h = imgui.GetTextLineHeightWithSpacing()
    local w = math.floor(h * 1.8)
    local s = anim_speed or 0.2
    local clicked = false
    if elements.custom.toggle_button[str_id] == nil then
        elements.custom.toggle_button[str_id] = {
            anim = false,
            anim_speed = anim_speed,
            back = bool[0],
            progress = 0,
            start_time = 0,
            hover_progress = 0
        }
    end
    local function bringVec4To(from, to, start_time, duration)
        local timer = os.clock() - start_time
        if timer >= 0.00 and timer <= duration then
            local count = timer / (duration / 100)
            return imgui.ImVec4(
                from.x + (count * (to.x - from.x) / 100),
                from.y + (count * (to.y - from.y) / 100),
                from.z + (count * (to.z - from.z) / 100),
                from.w + (count * (to.w - from.w) / 100)
            ), true
        end
        return (timer > duration) and to or from, false
    end
    if imgui.InvisibleButton("##" .. str_id .. "tglbtn", iv2(w + 4, h + 2)) then
        if not elements.custom.toggle_button[str_id].anim then
            clicked = true
            bool[0] = not bool[0]
            elements.custom.toggle_button[str_id].anim = true
            elements.custom.toggle_button[str_id].start_time = os.clock()
        end
    end
    if elements.custom.toggle_button[str_id].anim then
        if elements.custom.toggle_button[str_id].back then
            elements.custom.toggle_button[str_id].progress = 1 - ((os.clock() - elements.custom.toggle_button[str_id].start_time) / s)
        else
            elements.custom.toggle_button[str_id].progress = (os.clock() - elements.custom.toggle_button[str_id].start_time) / s
        end
        if elements.custom.toggle_button[str_id].progress > 1 then
            elements.custom.toggle_button[str_id].progress = 1
            elements.custom.toggle_button[str_id].anim = false
            elements.custom.toggle_button[str_id].back = true
        elseif elements.custom.toggle_button[str_id].progress < 0 then
            elements.custom.toggle_button[str_id].progress = 0
            elements.custom.toggle_button[str_id].anim = false
            elements.custom.toggle_button[str_id].back = false
        end
    end
    if imgui.IsItemHovered() then
        elements.custom.toggle_button[str_id].hover_progress = math.sin(os.clock() * 10) * 0.05
    else
        elements.custom.toggle_button[str_id].hover_progress = 0
    end
    imgui.SameLine()
    imgui.SetCursorPosY(cp.y + 4)
    imgui.SetCursorPosX(g_cpos().x + 3)
    imgui.Text(str_id)
    local color_true = iv4(1, 1, 1, 1)
    local color_false = iv4(0.6, 0.6, 0.6, 1)
    DL:AddRect(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + w + 4, p.y + h + 2), conv_c(iv4(0.5, 0.5, 0.5, 1.0)), 3, 15, 1.5)
    local hover_offset = elements.custom.toggle_button[str_id].hover_progress * h
    local offset
    if elements.custom.toggle_button[str_id].anim then
        offset = math.floor(h * 0.9) * elements.custom.toggle_button[str_id].progress + hover_offset
        local box_color, _ = bringVec4To(
            elements.custom.toggle_button[str_id].back and color_true or color_false,
            elements.custom.toggle_button[str_id].back and color_false or color_true,
            elements.custom.toggle_button[str_id].start_time,
            s
        )
        if elements.custom.toggle_button[str_id].progress < 0.5 then
            DL:AddRectFilled(imgui.ImVec2(p.x + 3, p.y + 3),
                            imgui.ImVec2(p.x + w / 2 + 1 + (offset / 0.5), p.y + h - 1),
                            conv_c(box_color), 3, 15, 1.5)
        else
            offset = math.floor(h * 0.9) * ((elements.custom.toggle_button[str_id].progress - 0.5) / 0.5) + hover_offset
            DL:AddRectFilled(imgui.ImVec2(p.x + 3 + offset, p.y + 3),
                            imgui.ImVec2(p.x + w / 2 + 1 + math.floor(h * 0.9), p.y + h - 1),
                            conv_c(box_color), 3, 15, 1.5)
        end
    else
        offset = (elements.custom.toggle_button[str_id].back and math.floor(h * 0.9) or 0) + hover_offset
        DL:AddRectFilled(imgui.ImVec2(p.x + 3 + offset, p.y + 3),
                        imgui.ImVec2(p.x + w / 2 + 1 + offset, p.y + h - 1),
                        conv_c(bool[0] and color_true or color_false), 3, 15, 1.5)
    end
    local icon = bool[0] and ti.ICON_CHECK or ti.ICON_X
    local icon_size = h * 0.5
    local icon_pos = imgui.ImVec2(
        p.x + 3 + offset,
        p.y + 4
    )
    DL:AddText(icon_pos, conv_c(iv4(0,0,0,1)), icon)
    imgui.SetCursorPosX(10)
    return clicked
end

-- ============================================================
--  imgui.PillButton  --  pill toggle: smooth slide, hover glow, white text
--  Usage: imgui.PillButton(str_id, bool_ptr, [anim_speed])
--  Returns true on click
-- ============================================================
function imgui.PillButton(str_id, bool_ptr, anim_speed)
    local s      = anim_speed or 0.13
    local h      = imgui.GetTextLineHeightWithSpacing()
    local pill_h = math.floor(h * 0.78)
    local pill_w = math.floor(pill_h * 1.9)
    local pad    = 2
    local knob_r = math.floor((pill_h - pad * 2) * 0.5)
    local rr     = math.floor(pill_h * 0.5)   -- full round ends
    local p      = imgui.GetCursorScreenPos()
    local cp     = g_cpos()
    local DL     = imgui.GetWindowDrawList()
    local dt     = imgui.GetIO().DeltaTime
    if dt <= 0 then dt = 1/60 end
    local clicked = false
    local key    = "__pill_" .. str_id

    if elements.custom.toggle_button[key] == nil then
        elements.custom.toggle_button[key] = {
            t           = bool_ptr[0] and 1.0 or 0.0,
            hover_phase = 0.0,
            hover_t     = 0.0,
        }
    end
    local st = elements.custom.toggle_button[key]

    -- invisible hit area
    imgui.PushStyleColor(imgui.Col.Button,        iv4(0,0,0,0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, iv4(0,0,0,0))
    imgui.PushStyleColor(imgui.Col.ButtonActive,  iv4(0,0,0,0))
    if imgui.Button("##" .. key, iv2(pill_w + 4, pill_h + 4)) then
        clicked = true
        bool_ptr[0] = not bool_ptr[0]
    end
    imgui.PopStyleColor(3)

    -- animate t toward target
    local target = bool_ptr[0] and 1.0 or 0.0
    local diff   = target - st.t
    local step   = dt / s
    if math.abs(diff) <= step then st.t = target
    else st.t = st.t + (diff > 0 and step or -step) end
    local t_ease = st.t * st.t * (3.0 - 2.0 * st.t)

    -- hover
    if imgui.IsItemHovered() then
        st.hover_t     = math.min(1.0, st.hover_t + dt * 10)
        st.hover_phase = st.hover_phase + dt * 7
    else
        st.hover_t     = math.max(0.0, st.hover_t - dt * 10)
    end
    -- subtle white flicker on hover (no colour, just brightness)
    local flicker = 0.0
    if st.hover_t > 0.01 then
        flicker = st.hover_t * (0.08 + 0.08 * math.sin(st.hover_phase))
    end

    local cx = p.x + 2
    local cy = p.y + 2

    -- pill background: dark-gray -> green, plus hover brightness
    local bg_r = 0.18 + flicker
    local bg_g = 0.18 + 0.52 * t_ease + flicker
    local bg_b = 0.18 + flicker
    DL:AddRectFilled(iv2(cx, cy), iv2(cx + pill_w, cy + pill_h),
        conv_c(iv4(bg_r, bg_g, bg_b, 1.0)), rr)

    -- pill border
    DL:AddRect(iv2(cx, cy), iv2(cx + pill_w, cy + pill_h),
        conv_c(iv4(0.35, 0.35 + 0.55 * t_ease, 0.35, 0.6 + 0.4 * t_ease)), rr, nil, 1.0)

    -- knob
    local travel  = pill_w - pad * 2 - knob_r * 2
    local knob_cx = cx + pad + knob_r + travel * t_ease
    local knob_cy = cy + pill_h * 0.5

    -- knob shadow
    DL:AddCircleFilled(iv2(knob_cx + 1, knob_cy + 1),
        knob_r, conv_c(iv4(0, 0, 0, 0.25)), 32)
    -- knob body
    DL:AddCircleFilled(iv2(knob_cx, knob_cy),
        knob_r, conv_c(iv4(0.95, 0.95, 0.95, 1.0)), 32)

    -- label: white, no colour change
    imgui.SameLine()
    imgui.SetCursorPosY(cp.y + (h - imgui.GetTextLineHeight()) * 0.5 - 4)
    imgui.SetCursorPosX(g_cpos().x + 4)
    imgui.Text(str_id)

    imgui.SetCursorPosX(10)
    return clicked
end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require 'ffi'
    local sampfuncs = require 'sampfuncs'
    local raknet = require 'samp.raknet'
    require 'samp.synchronization'

    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
        spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end

function load_cfg()
    if doesFileExist(getWorkingDirectory().."\\config\\lesorub_flupiflufi.json") then 
        local f = io.open(getWorkingDirectory().."\\config\\lesorub_flupiflufi.json", "r")
        config = decodeJson(f:read('*a'))
        f:close()
        elements.radar.pos = config.radar_pos
        cVARS.radar[0] = config.radar
        cVARS.debug[0] = config.debug
        cVARS.tracers[0] = config.tracers
        cVARS.radar_size[0] = config.radar_size
        cVARS.radar_zoom[0] = config.radar_zoom
        cVARS.telegram[0] = config.telegram
        cVARS.infinite_run[0] = config.infinite_run
        cVARS.warningseytg[0] = config.warningseytg
        cVARS.auto[0] = config.auto
        cVARS.offer_telegram[0] = config.offer_telegram
        cVARS.smart_sdacha[0] = config.smart_sdacha
        cVARS.selected_sdacha_index[0] = config.selected_sdacha_index
        cVARS.warning_color[0] = config.warning_color[1]
        cVARS.warning_color[1] = config.warning_color[2]
        cVARS.warning_color[2] = config.warning_color[3]
        cVARS.warning_color[3] = config.warning_color[4]
        cVARS.antiadmin_autoOff[0] = config.antiadmin_autoOff
        cVARS.antiadmin_telegramNotf[0] = config.antiadmin_telegramNotf
        cVARS.antiadmin_reversal[0] = config.antiadmin_reversal
        cVARS.antiadmin_blinking[0] = config.antiadmin_blinking
        cVARS.antiadmin_autoExit[0] = config.antiadmin_autoExit
        cVARS.antiadmin_skipdialog[0] = config.antiadmin_skipdialog
        cVARS.antiadmin_warningsey[0] = config.antiadmin_warningsey
        cVARS.antiadmin_skip11[0] = config.antiadmin_skip11
        cVARS.antiadmin_skip22[0] = config.antiadmin_skip22
        cVARS.antiadmin_flash[0] = config.antiadmin_flash
        cVARS.antiadmin_kick[0] = config.antiadmin_kick
        cVARS.auto_job[0] = config.auto_job
        cVARS.daily_trees[0]  = config.daily_trees
        cVARS.weekly_trees[0] = config.weekly_trees
        cVARS.daily_drova[0]  = config.daily_drova
        cVARS.weekly_drova[0] = config.weekly_drova
        cVARS.degniebat_den[0]  = config.degniebat_den
        cVARS.degniebat_week[0] = config.degniebat_week
        cVARS.last_day[0]     = config.last_day
        cVARS.last_week[0]    = config.last_week
        cVARS.anti_vehicle[0] = config.anti_vehicle
        cVARS.autoeat[0] = config.autoeat
        cVARS.eatmethod[0] = config.eatmethod
        cVARS.eatpercent[0] = config.eatpercent
        cVARS.autolarek[0] = config.autolarek
        cVARS.autobeer[0] = config.autobeer
        cVARS.antibot_antifreeze[0] = config.antibot_antifreeze
        cVARS.enable_jump[0] = config.enable_jump
        cVARS.enable_random_turns[0] = config.enable_random_turns
        cVARS.camera_smooth_close[0] = config.camera_smooth_close
        cVARS.camera_smooth_mid[0] = config.camera_smooth_mid
        cVARS.camera_smooth_far[0] = config.camera_smooth_far
        cVARS.camera_turn_slow[0] = config.camera_turn_slow or 45.0
        cVARS.camera_turn_mid[0]  = config.camera_turn_mid  or 120.0
        cVARS.camera_turn_fast[0] = config.camera_turn_fast or 360.0
        cVARS.animspeed_enabled[0] = config.animspeed_enabled
        cVARS.animspeed_value[0] = config.animspeed_value
        cVARS.camera_dist[0] = config.camera_dist
        cVARS.enable_random_pauses[0] = config.enable_random_pauses
        cVARS.menu_movable[0] = config.menu_movable
        cVARS.menu_pos_x[0] = config.menu_pos_x
        cVARS.menu_pos_y[0] = config.menu_pos_y
        cVARS.camera_height_offset[0] = config.camera_height_offset
        cVARS.menu_hotkey[0] = config.menu_hotkey
        cVARS.bot_hotkey[0] = config.bot_hotkey
        cVARS.check_stuck[0] = config.check_stuck
        cVARS.show_navmesh[0] = config.show_navmesh or false
        if config.menu_command then
            for i = 1, math.min(63, #config.menu_command) do
                cVARS.menu_command[i-1] = config.menu_command:sub(i,i):byte()
            end
            cVARS.menu_command[math.min(63, #config.menu_command)] = 0
        end
        if config.bot_command then
            for i = 1, math.min(63, #config.bot_command) do
                cVARS.bot_command[i-1] = config.bot_command:sub(i,i):byte()
            end
            cVARS.bot_command[math.min(63, #config.bot_command)] = 0
        end
        if config.telegram_token then
            for i = 1, math.min(255, #config.telegram_token) do
                cVARS.telegram_token[i-1] = config.telegram_token:sub(i, i):byte()
            end
            cVARS.telegram_token[math.min(255, #config.telegram_token)] = 0
        end
        if config.menu_hotkey_combo and config.menu_hotkey_combo ~= "" then
            local keys = {}
            for key_name in string.gmatch(config.menu_hotkey_combo, "[^+]+") do
                table.insert(keys, key_name)
            end
            local function findKeyCodeByName(name)
                for _, code in ipairs(key_map) do
                    if getKeyName(code) == name then
                        return code
                    end
                end
                return 0
            end

            cVARS.combo_key1[0] = findKeyCodeByName(keys[1] or "")
            cVARS.combo_key2[0] = findKeyCodeByName(keys[2] or "")
        end
        cVARS.antiadmin_play_sound[0] = config.antiadmin_play_sound or false
        if config.antiadmin_sound_path then
            for i = 1, math.min(255, #config.antiadmin_sound_path) do
                cVARS.antiadmin_sound_path[i-1] = config.antiadmin_sound_path:sub(i, i):byte()
            end
            cVARS.antiadmin_sound_path[math.min(255, #config.antiadmin_sound_path)] = 0
        end
        if config.telegram_chat_id then
            for i = 1, math.min(255, #config.telegram_chat_id) do
                cVARS.telegram_chat_id[i-1] = config.telegram_chat_id:sub(i, i):byte()
            end
            cVARS.telegram_chat_id[math.min(255, #config.telegram_chat_id)] = 0
        end
        if config.avatar_path then
            for i = 1, math.min(255, #config.avatar_path) do
                cVARS.avatar_path[i-1] = config.avatar_path:sub(i, i):byte()
            end
            cVARS.avatar_path[math.min(255, #config.avatar_path)] = 0
        end
        if config.telegram_api_url then
            for i = 1, math.min(255, #config.telegram_api_url) do
                cVARS.telegram_api_url[i-1] = config.telegram_api_url:sub(i, i):byte()
            end
            cVARS.telegram_api_url[math.min(255, #config.telegram_api_url)] = 0
        end
    else
        config = {
            radar = false,
            debug = false,
            tracers = true,
            stat_status = false,
            x = 700,
            y = 800,
            derevo_value = 0,
            drova_value = 0,
            radar_size = 299,
            radar_zoom = 20,
            radar_pos = {187, 553},
            telegram = false,
            offer_telegram = false,
            warningseytg = false,
            auto = false,
            daily_trees = 0,
            weekly_trees = 0,
            daily_drova = 0,
            weekly_drova = 0,
            degniebat_den = 0,
            degniebat_week = 0,
            last_day = tonumber(os.date("%d")),
            last_week = tonumber(os.date("%U")),
            smart_sdacha = false,
            selected_sdacha_index = 1,
            auto_job = true,
            menu_command = "sawbot",
            bot_command = "sawrun",
            menu_hotkey = 0,
            bot_hotkey = 0,
            infinite_run = false,
            anti_vehicle = false,
            telegram_token = "",
            telegram_chat_id = "",
            warning_color = {1.0, 0.0, 0.3, 1.0},
            antiadmin_autoOff = true,
            antiadmin_telegramNotf = false,
            antiadmin_reversal = false,
            antiadmin_blinking = false,
            antiadmin_autoExit = false,
            antiadmin_skipdialog = false,
            antiadmin_warningsey = false,
            antiadmin_skip11 = 1250,
            antiadmin_skip22 = 1500,
            antiadmin_flash = 1,
            autoeat = false,
            eatmethod = 0,
            eatpercent = 1,
            autolarek = false,
            autobeer = false,
            enable_jump = true,
            enable_random_turns = true,
            antibot_antifreeze = false,
            camera_smooth_close = 0.15,
    camera_turn_slow = 45.0,
    camera_turn_mid = 120.0,
    camera_turn_fast = 360.0,
            camera_smooth_mid = 0.08,
            camera_smooth_far = 0.04,
            camera_dist = 10.0,
            camera_height_offset = 1.0,
            animspeed_enabled = false,
            animspeed_value = 1.0,
            check_stuck = false,
            antiadmin_sound_path = new.char[256]("moonloader/config/admin_alert.mp3"),
            antiadmin_play_sound = new.bool(false),
            avatar_path = new.char[256]("avatar.png"),
            telegram_api_url = "https://api.telegram.org",
        }
    end
end

function save_cfg()
    config.radar = cVARS.radar[0]
    config.debug = cVARS.debug[0]
    config.tracers = cVARS.tracers[0]
    config.radar_size = cVARS.radar_size[0]
    config.radar_zoom = cVARS.radar_zoom[0]
    config.radar_pos = elements.radar.pos
    config.telegram = cVARS.telegram[0]
    config.warningseytg = cVARS.warningseytg[0]
    config.auto = cVARS.auto[0]
    config.auto_job = cVARS.auto_job[0]
    config.daily_trees  = cVARS.daily_trees[0]
    config.weekly_trees = cVARS.weekly_trees[0]
    config.daily_drova  = cVARS.daily_drova[0]
    config.weekly_drova = cVARS.weekly_drova[0]
    config.degniebat_den  = cVARS.degniebat_den[0]
    config.degniebat_week = cVARS.degniebat_week[0]
    config.last_day     = cVARS.last_day[0]
    config.last_week    = cVARS.last_week[0]
    config.warning_color = {cVARS.warning_color[0], cVARS.warning_color[1], cVARS.warning_color[2], cVARS.warning_color[3]}
    config.antiadmin_autoOff = cVARS.antiadmin_autoOff[0]
    config.antiadmin_telegramNotf = cVARS.antiadmin_telegramNotf[0]
    config.antiadmin_reversal = cVARS.antiadmin_reversal[0]
    config.antiadmin_blinking = cVARS.antiadmin_blinking[0]
    config.antiadmin_autoExit = cVARS.antiadmin_autoExit[0]
    config.antiadmin_skipdialog = cVARS.antiadmin_skipdialog[0]
    config.antiadmin_warningsey = cVARS.antiadmin_warningsey[0]
    config.antiadmin_skip11 = cVARS.antiadmin_skip11[0]
    config.antiadmin_skip22 = cVARS.antiadmin_skip22[0]
    config.antiadmin_flash = cVARS.antiadmin_flash[0]
    config.antiadmin_kick = cVARS.antiadmin_kick[0]
    config.infinite_run = cVARS.infinite_run[0]
    config.autoeat = cVARS.autoeat[0]
    config.eatmethod = cVARS.eatmethod[0]
    config.eatpercent = cVARS.eatpercent[0]
    config.autolarek = cVARS.autolarek[0]
    config.autobeer = cVARS.autobeer[0]
    config.offer_telegram = cVARS.offer_telegram[0]
    config.smart_sdacha = cVARS.smart_sdacha[0]
    config.anti_vehicle = cVARS.anti_vehicle[0]
    config.selected_sdacha_index = cVARS.selected_sdacha_index[0]
    config.antibot_antifreeze = cVARS.antibot_antifreeze[0]
    config.enable_jump = cVARS.enable_jump[0]
    config.enable_random_turns = cVARS.enable_random_turns[0]
    config.animspeed_enabled = cVARS.animspeed_enabled[0]
    config.animspeed_value = cVARS.animspeed_value[0]
    config.camera_smooth_close = cVARS.camera_smooth_close[0]
    config.camera_smooth_mid = cVARS.camera_smooth_mid[0]
    config.camera_smooth_far = cVARS.camera_smooth_far[0]
    config.camera_turn_slow = cVARS.camera_turn_slow[0]
    config.camera_turn_mid  = cVARS.camera_turn_mid[0]
    config.camera_turn_fast = cVARS.camera_turn_fast[0]
    config.camera_dist = cVARS.camera_dist[0]
    config.menu_movable = cVARS.menu_movable[0]
    config.menu_pos_x = cVARS.menu_pos_x[0]
    config.menu_pos_y = cVARS.menu_pos_y[0]
    config.camera_height_offset = cVARS.camera_height_offset[0]
    config.menu_command = ffi.string(cVARS.menu_command)
    config.bot_command = ffi.string(cVARS.bot_command)
    config.enable_random_pauses = cVARS.enable_random_pauses[0]
    config.menu_hotkey = cVARS.menu_hotkey[0]
    config.bot_hotkey = cVARS.bot_hotkey[0]
    config.telegram_token = u8:decode(ffi.string(cVARS.telegram_token))
    config.telegram_chat_id = u8:decode(ffi.string(cVARS.telegram_chat_id))
    config.check_stuck = cVARS.check_stuck[0]
    config.show_navmesh = cVARS.show_navmesh[0]
    config.antiadmin_play_sound = cVARS.antiadmin_play_sound[0]
    config.antiadmin_sound_path = u8:decode(ffi.string(cVARS.antiadmin_sound_path))
    config.avatar_path = u8:decode(ffi.string(cVARS.avatar_path))
    config.telegram_api_url = u8:decode(ffi.string(cVARS.telegram_api_url))
    local combo_str = ""
    if cVARS.combo_key1[0] and cVARS.combo_key1[0] ~= 0 then
        combo_str = getKeyName(cVARS.combo_key1[0])
        if cVARS.combo_key2[0] and cVARS.combo_key2[0] ~= 0 then
            combo_str = combo_str .. "+" .. getKeyName(cVARS.combo_key2[0])
        end
    end
    config.menu_hotkey_combo = combo_str
    local f = io.open(getWorkingDirectory().."\\config\\lesorub_flupiflufi.json", "w")
    f:write(encodeJson(config))
    f:close()
end
