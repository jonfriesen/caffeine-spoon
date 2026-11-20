local displayIdle = false
local timer, hotkey

hs = {
    caffeinate = {
        get = function(kind)
            assert(kind == "displayIdle")
            return displayIdle
        end,
        set = function(kind, enabled)
            assert(kind == "displayIdle")
            displayIdle = enabled
        end,
        watcher = {
            new = function()
                return { start = function() end, stop = function() end }
            end,
        },
    },
    menubar = {
        new = function()
            return { setMenu = function() end, setIcon = function() end, delete = function() end }
        end,
    },
    timer = {
        doAfter = function(_, callback)
            timer = {
                fire = callback,
                stop = function(self) self.stopped = true end,
            }
            return timer
        end,
    },
    hotkey = {
        new = function(_, _, callback)
            hotkey = {
                press = callback,
                enable = function(self) self.enabled = true end,
                disable = function(self) self.enabled = false end,
            }
            return hotkey
        end,
    },
}

local directory = arg[0]:match("^(.*[/])") or ""
local caffeine = dofile(directory .. "../init.lua")
caffeine:bindHotkeys({ toggle = { { "alt", "cmd" }, "c" } })
caffeine:start()
assert(hotkey.enabled)
caffeine:enableForDuration(300)
assert(displayIdle and not timer.stopped)
caffeine:stop()
assert(not displayIdle and timer.stopped and not hotkey.enabled)

-- Observing an existing assertion does not make it Caffeine's to release.
displayIdle = true
caffeine:start()
caffeine:stop()
assert(displayIdle)

-- Manual control keeps working, and retired callbacks cannot undo it.
caffeine:start()
caffeine:setState(false)
assert(not displayIdle)
caffeine:enableForDuration(300)
hotkey.press()
assert(not displayIdle and timer.stopped)
hotkey.press()
assert(displayIdle)
timer.fire()
assert(displayIdle)
caffeine:stop()
assert(not displayIdle)
