-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
local vicious = require("vicious")
local gfs = require("gears.filesystem")
local spotify_widget = require("awesome-wm-widgets.spotify-widget.spotify")
local todo_widget = require("awesome-wm-widgets.todo-widget.todo")
local logout_menu_widget = require("awesome-wm-widgets.logout-menu-widget.logout-menu")
local docker_widget = require("awesome-wm-widgets.docker-widget.docker")
local volume_widget = require('awesome-wm-widgets.volume-widget.volume')
local battery_widget = require("awesome-wm-widgets.battery-widget.battery")
local brightness_widget = require("awesome-wm-widgets.brightness-widget.brightness")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

require("main.error-handling")

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
-- beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.init("~/.config/awesome/theme.lua")

RC = {} -- global namespace, on top before require any modules 
RC.vars = require("main.user-variables")

modkey = RC.vars.modkey

local main = {
    rules = require("main.rules"), 
    layouts = require("main.layouts"),
    menu = require("main.menu"),
}

local bindings = {
    clientkeys = require("bindings.clientkeys"),
    clientbuttons = require("bindings.clientbuttons"),
    globalkeys = require("bindings.globalkeys"), 
    globalbuttons = require("bindings.globalbuttons"),
    bindtotags = require("bindings.bindtotags"),
}

require("main.spawn")

-- This is used later as the default terminal and editor to run.
-- terminal = "x-terminal-emulator"
menubar.utils.terminal = RC.vars.terminal
terminal = RC.vars.terminal
editor = RC.vars.editor
-- editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor 

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Layouts
RC.layouts = main.layouts()

RC.mainmenu = awful.menu({
	items = main.menu(),
	theme = {
		width = 250,
		height = 30,
		font = "Ubuntu Nerd Font 14",
		bg_normal = "#00000080",
		bg_focus = "#729fcf",
		border_width = 3,
		border_color = "#000000",
	},
})

-- a variable needed in statusbar (helper)
RC.launcher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = RC.mainmenu })

-- mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
--                                      menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
local label_color = "#d791a8"
local info_color = "#ffffff"

-- Create the data widget
local date_widget = wibox.widget.textclock("<span foreground='" .. label_color .. "'> <b> %a %b %-d</b>  </span>", 60)

-- Create the time widget
local time_widget = wibox.widget.textclock("<span foreground='" .. info_color .. "'><b>%l:%M %p </b></span>", 1)

-- Combine the date and time widgets
local date_time_widget = wibox.widget {
	date_widget,
	time_widget,
	layout = wibox.layout.fixed.horizontal,
}


-- Distro and kernel
-- Function to get kernel version
local function get_kernel_version(callback)
    awful.spawn.easy_async_with_shell("uname -r", function(stdout)
        local kernel = stdout:gsub("%s+", "") -- Remove any extra whitespace or newlines
        callback(kernel)
    end)
end


-- Create and update the kernel widget
local kernel_widget = wibox.widget.textbox()
get_kernel_version(function(kernel)
    kernel_widget:set_markup(string.format("<span foreground='%s'>  Debian</span> <span foreground='%s'>%s</span>", label_color, info_color, kernel))
end) 

-- Create cpu 
-- Create CPU widget
local cpu_widget = wibox.widget.textbox()

-- Register the widget with Vicious
vicious.register(cpu_widget, vicious.widgets.cpu, function (widget, args)
	return string.format("<span foreground='%s'> CPU:</span> <span foreground='%s'>%d%%</span>", label_color, info_color, args[1]) end, 2) --Updates every 2 seconds

-- Create Memory widget
local mem_widget = wibox.widget.textbox()

-- Register the widget with Vicious
vicious.register(mem_widget, vicious.widgets.mem, function (widget, args)
	return string.format("<span foreground='%s'> RAM:</span> <span foreground='%s'>%d%%</span>", label_color, info_color, args[1]) end, 15) --Updates every 15 seconds
	
-- Create a wibox for each screen and add it
-- local taglist_buttons = gears.table.join(
--                     awful.button({ }, 1, function(t) t:view_only() end),
--                     awful.button({ modkey }, 1, function(t)
--                                               if client.focus then
--                                                   client.focus:move_to_tag(t)
--                                               end
--                                           end),
--                     awful.button({ }, 3, awful.tag.viewtoggle),
--                     awful.button({ modkey }, 3, function(t)
--                                               if client.focus then
--                                                   client.focus:toggle_tag(t)
--                                               end
--                                           end),
--                     awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
--                     awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
--                 )

-- local tasklist_buttons = gears.table.join(
--                      awful.button({ }, 1, function (c)
--                                               if c == client.focus then
--                                                   c.minimized = true
--                                               else
--                                                   c:emit_signal(
--                                                       "request::activate",
--                                                       "tasklist",
--                                                       {raise = true}
--                                                   )
--                                               end
--                                           end),
--                      awful.button({ }, 3, function()
--                                               awful.menu.client_list({ theme = { width = 250 } })
--                                           end),
--                      awful.button({ }, 4, function ()
--                                               awful.client.focus.byidx(1)
--                                           end),
--                      awful.button({ }, 5, function ()
--                                               awful.client.focus.byidx(-1)
--                                           end))
 

local function pick_random_wallpaper(patterns)
    local all_files = {}
    local wallpapers_dir = os.getenv("HOME") .. "/.config/awesome/wallpapers/"

    -- Use io.popen to list directory contents
    local handle = io.popen("ls " .. wallpapers_dir)
    if handle then
        for filename in handle:lines() do
            for _, pat in ipairs(patterns) do
                if string.match(filename, pat) then
                    table.insert(all_files, wallpapers_dir .. filename)
                    break
                end
            end
        end
        handle:close()
    end

    if #all_files == 0 then
        return nil
    end

    math.randomseed(os.time())
    local idx = math.random(1, #all_files)
    return all_files[idx]
end

local function set_wallpaper(s)
    local g = s.geometry
    local aspect = g.width / g.height

    local wp

    if aspect > 2.0 then
        -- Ultrawide (e.g., 21:9) – pick random ultrawide*.jpg/png
        wp = pick_random_wallpaper({
            "ultrawide.*%.jpg",
            "ultrawide.*%.jpeg",
            "ultrawide.*%.png",
        })
    elseif math.abs(aspect - 16/9) < 0.05 or math.abs(aspect - 16/10) < 0.05 then
        -- 16:9 or 16:10 – pick random 16x_standard*.jpg/png
        wp = pick_random_wallpaper({
            "16x_standard.*%.jpg",
            "16x_standard.*%.jpeg",
            "16x_standard.*%.png",
        })
    end

    if not wp then
        -- Fallback: use any available wallpaper
        wp = os.getenv("HOME") .. "/.config/awesome/wallpapers/SRC.jpg"
    end

    if wp then
        gears.wallpaper.maximized(wp, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local deco = {
	-- wallpaper = require("deco.wallpaper"),
	taglist = require("deco.taglist"),
	tasklist = require("deco.tasklist"),
}
local taglist_buttons = deco.taglist()
local tasklist_buttons = deco.tasklist()



awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)
    -- Determine orientation
    local is_portrait = s.geometry.height > s.geometry.width

    -- Use vertical layout for portrait mode, and default to tile for landscape
    local chosen_layout
    if is_portrait then
        chosen_layout = awful.layout.layouts[6] -- Assuming `vertical_layout` is the 5th entry
    else
        chosen_layout = awful.layout.layouts[1] -- Assuming `tile` is the 1st entry
    end

    -- Each screen has its own tag table.
    -- awful.tag({ "1", "2", "Teams", "Coding", "PhD", "Survey", "WS7", "WS8", "Settings" }, s, awful.layout.layouts[1])
    awful.tag({ "1", "2", "Teams", "Coding", "PhD", "ISpaRo", "WS7", "WS8", "Settings" }, s, chosen_layout)

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        layout  = {
            spacing = 5,
            layout  = wibox.layout.fixed.horizontal
        },
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        style = {
            tasklist_disable_task_name = true, -- Hide task titles
        },
        layout = {
            spacing = 10,
            layout  = wibox.layout.fixed.horizontal,
        },
    }

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s,height = 40 })
    local centered_tasklist = wibox.container.place(s.mytasklist, "center", "center")
    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            -- mylauncher,
            s.mytaglist,
            s.mypromptbox,
            wibox.widget.systray(),
        },
        
        centered_tasklist, -- Middle widget
        { -- Right widgets
        
            layout = wibox.layout.fixed.horizontal,
            -- mykeyboardlayout,
            spotify_widget({
                font = 'Ubuntu Mono 9',
                play_icon = '/usr/share/icons/Papirus-Light/24x24/categories/spotify.svg',
                pause_icon = '/usr/share/icons/Papirus-Dark/24x24/panel/spotify-indicator.svg',
                dim_when_paused = true,
                show_tooltip = false,  
                max_length = -1, 
             }),
             todo_widget(),
             docker_widget{
                number_of_containers = 5
            },
            -- wibox.widget.systray(),
            -- mytextclock,
            -- minimum code for battery widget

            cpu_widget,
            mem_widget,
            kernel_widget,
            date_time_widget,
            -- s.mylayoutbox,
            brightness_widget{
                program = 'xbacklight',      
            },
            battery_widget({
                show_current_level = true,
                display_notification = true,

        }),
            volume_widget{
                widget_type = 'icon_and_text'
            },
            logout_menu_widget{
                font = 'Play 14',
                onlock = function() awful.spawn.with_shell('i3lock-fancy') end
            },
        },
    }
end)
-- awful.screen.connect_for_each_screen(function(s)
-- 	local fancy_taglist = require("fancy_taglist")
-- 	mytaglist = fancy_taglist.new({
-- 		screen   = s,
-- 		taglist  = { buttons = taglist_buttons },
-- 		tasklist = { buttons = tasklist_buttons },
-- 		filter   = awful.widget.taglist.filter.all,
-- 		style    = {
-- 			shape = gears.shape.rounded_rect
-- 		},
-- 	})
-- end)

-- require("layout.topbar.topbar")

-- }}}



-- Mouse and Key bindings
RC.globalkeys = bindings.globalkeys()
RC.globalkeys = bindings.bindtotags(RC.globalkeys)

-- Set keys 
root.buttons(bindings.globalbuttons())
root.keys(RC.globalkeys)
-- }}}



awful.rules.rules = main.rules(bindings.clientkeys(), bindings.clientbuttons())

require("main.signals")

 