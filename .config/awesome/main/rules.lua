local awful = require("awful")
local beautiful = require("beautiful")

local _M        = {}
-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
function _M.get(clientkeys, clientbuttons)
    local rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen+awful.placement.centered
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll. 
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "obs",
          "Galculator",
          "nautilus",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.p
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false --[[default = true]] }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1
    { rule = { class = "teams-for-linux" },
      properties = { screen = 1, tag = "Teams" } },
    { rule = { class = "Todoist"},
      properties = { screen = 2, tag = "1" } },
    { rule = { class = "Spotify"},
      properties = { screen = 1, tag = "8" } },
    { rule = { class = "Blueman-manager"},
      properties = { screen = 1, tag = "9" } },
    { rule = { class = "Arandr"},
      properties = { screen = 1, tag = "9" } },
    { rule = { class = "Code"},
    --   name = ".*phd_plan - Visual Studio Code.*"},
      properties = { screen = 1, tag = "PhD" },
      callback = function(c)
        local title = c.name 
        -- debug title 
        -- naughty.notify({ preset = naughty.config.presets.info,
        --              title = "title- debug",
        --              text = title })
        if string.find(title, "phd_plan") then
            -- c:move_to_tag(awful.screen.focused().tags[5])
        else 
            c.screen = awful.screen.focused()
            c:move_to_tag(awful.screen.focused().selected_tag)
        end
    end 
},
    -- { rule = { class = "code-phd-plan"},
    --   properties = { screen = 1, tag = "5" } },
    -- { rule = { class = "code-survey"},
    --   properties = { screen = 1, tag = "6" } },
    -- { rule = { class = "code-knowledge" },
    --   properties = { screen = 1, tag = "7" } },
}
return rules
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return setmetatable({}, { __call = function(_, ...) return _M.get(...) end })