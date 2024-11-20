local awful = require("awful")

awful.spawn.with_shell("teams-for-linux")
awful.spawn.with_shell("code --new-window ~/ws/overleaf/phd_plan")
awful.spawn.with_shell("code --new-window ~/ws/overleaf/survey_paper")
awful.spawn.with_shell("code --new-window ~/ws/projects/aauspacerobotics")
awful.spawn.with_shell("google-chrome --new-window https://outlook.office.com/mail/")

-- spawn dotfiles
awful.spawn.with_shell("code --new-window ~/dotfiles")
awful.spawn.with_shell("code --new-window ~/.config/awesome")

awful.spawn.with_shell("~/.config/awesome/autorun.sh")