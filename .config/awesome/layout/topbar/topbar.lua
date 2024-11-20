-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

-- Custom Local Library: Common Functional Decoration
local deco = {
	-- wallpaper = require("deco.wallpaper"),
	taglist = require("deco.taglist"),
	tasklist = require("deco.tasklist"),
}

local taglist_buttons = deco.taglist()
local tasklist_buttons = deco.tasklist()
local color = require("layout.topbar.colors")
local _M = {}

--Spacer
local separator = wibox.widget.textbox("     ")

-- local calendar_widget = require("deco.calendar")
-- local batteryarc_widget = require("deco.batteryarc")


---------------------------
--Widgets------------------
---------------------------

--textclock widget
mytextclock = wibox.widget.textclock(
	'<span color="' .. color.white .. '" font="Ubuntu Nerd Font Bold 13"> %a %b %d, %H:%M </span>', 10)


--calendar-widget
-- local cw = calendar_widget({
-- 	theme = "nord",
-- 	placement = "top_center",
-- 	start_sunday = true,
-- 	radius = 8,
-- 	previous_month_button = 1,
-- 	padding = 5,
-- 	next_month_button = 3,
-- })
mytextclock:connect_signal("button::press", function(_, _, _, button)
	if button == 1 then
		cw.toggle()
	end
end)


--Fancy taglist widget
awful.screen.connect_for_each_screen(function(s)
	local fancy_taglist = require("fancy_taglist")
	mytaglist = fancy_taglist.new({
		screen   = s,
		taglist  = { buttons = taglist_buttons },
		tasklist = { buttons = tasklist_buttons },
		filter   = awful.widget.taglist.filter.all,
		style    = {
			shape = gears.shape.rounded_rect
		},
	})
end)