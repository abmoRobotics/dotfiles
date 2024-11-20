-- Standard awesome library
local awful = require("awful")


local beautiful = require("beautiful") -- for awesome.icon

local M = {}                           -- menu
local _M = {}                          -- module

local terminal = RC.vars.terminal

local editor = RC.vars.editor
local editor_cmd = terminal .. " -e " .. editor
 
M.awesome = {
	{
		"Hotkeys",
		function()
			hotkeys_popup.show_help(nil, awful.screen.focused())
		end,
	},
	{ "Manual",          terminal .. " -e man awesome" },
	{ "Edit config",     editor_cmd .. " " .. awesome.conffile },
	{ "Terminal",        terminal },
	{ "Shutdown/Logout", "oblogout" },
	{ "Restart",         awesome.restart },
	{
		"Quit",
		function()
			awesome.quit()
		end,
	},
}

M.favorite = {
	{ "VS Code",       "code" },
}


function _M.get()
	-- Main Menu
	local menu_items = {
		{ "Awesome",          M.awesome, beautiful.awesome_subicon },
		{ "Favorite",         M.favorite },
	}

	return menu_items
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return setmetatable({}, {
	__call = function(_, ...)
		return _M.get(...)
	end,
})