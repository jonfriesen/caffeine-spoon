--- === Caffeine ===
---
--- Keep the display awake until you turn Caffeine off, lock the screen, or a timer expires.

-- Modified from the upstream Caffeine Spoon by Jon Friesen.
-- Upstream: Chris Jones and contributors, MIT (LICENSE-MIT).
-- Modifications: Copyright 2026 Jon Friesen, Apache-2.0 (LICENSE).
local obj = { __gc = true }
--obj.__index = obj
setmetatable(obj, obj)
obj.__gc = function(t)
    t:stop()
end

-- Metadata
obj.name = "Caffeine"
obj.version = "1.0"
obj.author = "Chris Jones <cmsj@tenshu.net>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT (upstream); Apache-2.0 (modifications)"

obj.menuBarItem = nil
obj.hotkeyToggle = nil
obj.lockWatcher = nil
obj.durationTimer = nil
obj.timerEndTime = nil

-- Internal function used to find our location, so we know where to load files from
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end
obj.spoonPath = script_path()

function obj:init()
end

local function endSession(self)
    self:cancelTimer()
    if self.ownsDisplayIdle then
        hs.caffeinate.set("displayIdle", false)
        self.ownsDisplayIdle = nil
    end
    if self.menuBarItem then
        self.setDisplay(hs.caffeinate.get("displayIdle"))
    end
end

function obj:lockEventHandler(event)
    if event == hs.caffeinate.watcher.screensDidLock then
        endSession(self)
    end
end

--- Caffeine:bindHotkeys(mapping)
--- Method
--- Binds the toggle hotkey. Bind before `start()` to enable it on start, or call while running to replace it immediately.
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * toggle - Toggles display sleep prevention and cancels any active duration timer.
---
--- Returns:
---  * The Caffeine object
function obj:bindHotkeys(mapping)
    if (self.hotkeyToggle) then
        self.hotkeyToggle:delete()
    end
    local toggleMods = mapping["toggle"][1]
    local toggleKey = mapping["toggle"][2]
    self.hotkeyToggle = hs.hotkey.new(toggleMods, toggleKey, function() self.clicked() end)
    if self.menuBarItem then self.hotkeyToggle:enable() end

    return self
end

--- Caffeine:start()
--- Method
--- Starts Caffeine and shows the menu bar icon. If already running, stops the current session first.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Caffeine object
function obj:start()
    if self.menuBarItem then self:stop() end
    self.menuBarItem = hs.menubar.new()
    self.menuBarItem:setMenu(function()
        local buttons = hs.eventtap.checkMouseButtons()
        if buttons.right then
            -- Right click - show menu
            return self:buildMenu()
        else
            -- Left click - toggle and don't show menu
            self.clicked()
            return {}
        end
    end)
    if (self.hotkeyToggle) then
        self.hotkeyToggle:enable()
    end
    self.setDisplay(hs.caffeinate.get("displayIdle"))

    self.lockWatcher = hs.caffeinate.watcher.new(function(event)
        self:lockEventHandler(event)
    end)
    self.lockWatcher:start()

    return self
end

--- Caffeine:stop()
--- Method
--- Stops the watcher, removes the menu bar item, disables the hotkey, and cancels any timer.
--- Releases display sleep prevention only if Caffeine enabled it. The hotkey binding is kept for the next start.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Caffeine object
function obj:stop()
    if self.menuBarItem then
        self.menuBarItem:delete()
        self.menuBarItem = nil
    end
    if (self.hotkeyToggle) then
        self.hotkeyToggle:disable()
    end
    if self.lockWatcher then
        self.lockWatcher:stop()
        self.lockWatcher = nil
    end
    endSession(self)
    return self
end

function obj.setDisplay(state)
    local icon = state and "caffeine-on.pdf" or "caffeine-off.pdf"
    obj.menuBarItem:setIcon(obj.spoonPath .. icon)
end

function obj.clicked()
    obj:setState(not hs.caffeinate.get("displayIdle"))
end

--- Caffeine:setState(on)
--- Method
--- Sets display sleep prevention and cancels any active duration timer. Requires `start()`.
---
--- Parameters:
---  * on - A boolean, true if screens should be kept awake, false to let macOS send them to sleep
---
--- Returns:
---  * None
function obj:setState(on)
    assert(self.menuBarItem, "Start Caffeine before setting its state")
    self:cancelTimer()
    if not on then
        hs.caffeinate.set("displayIdle", false)
        self.ownsDisplayIdle = nil
    elseif not hs.caffeinate.get("displayIdle") then
        hs.caffeinate.set("displayIdle", true)
        self.ownsDisplayIdle = true
    end
    self.setDisplay(on)
end

--- Caffeine:enableForDuration(seconds)
--- Method
--- Keeps the display awake for a specified duration, replacing any active timer. Requires `start()`.
--- On expiry, releases display sleep prevention only if Caffeine enabled it.
---
--- Parameters:
---  * seconds - Number of seconds to keep Caffeine enabled
---
--- Returns:
---  * None
function obj:enableForDuration(seconds)
    self:setState(true)
    self.timerEndTime = os.time() + seconds
    local timer
    timer = hs.timer.doAfter(seconds, function()
        if self.durationTimer == timer then
            endSession(self)
        end
    end)
    self.durationTimer = timer
end

--- Caffeine:cancelTimer()
--- Method
--- Cancels any active duration timer without changing display sleep prevention. Safe to call when stopped.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:cancelTimer()
    local timer = self.durationTimer
    self.durationTimer = nil
    self.timerEndTime = nil
    if timer then timer:stop() end
end

--- Caffeine:buildMenu()
--- Method
--- Builds the menu bar dropdown. Building it does not require `start()`, but invoking its actions does.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the menu items
function obj:buildMenu()
    local currentState = hs.caffeinate.get("displayIdle")
    local hasTimer = self.durationTimer ~= nil

    local menu = {
        {
            title = currentState and "Disable Caffeine" or "Enable Caffeine",
            fn = self.clicked
        },
        { title = "-" },
        { title = "Enable for:", disabled = true },
        { title = "5 minutes", fn = function() self:enableForDuration(5 * 60) end },
        { title = "15 minutes", fn = function() self:enableForDuration(15 * 60) end },
        { title = "30 minutes", fn = function() self:enableForDuration(30 * 60) end },
        { title = "1 hour", fn = function() self:enableForDuration(60 * 60) end },
        { title = "4 hours", fn = function() self:enableForDuration(4 * 60 * 60) end },
        { title = "8 hours", fn = function() self:enableForDuration(8 * 60 * 60) end },
    }

    -- Show remaining time if timer is active
    if hasTimer and self.timerEndTime then
        local remaining = self.timerEndTime - os.time()
        if remaining > 0 then
            local mins = math.floor(remaining / 60)
            local hours = math.floor(mins / 60)
            mins = mins % 60
            local timeStr
            if hours > 0 then
                timeStr = string.format("%dh %dm remaining", hours, mins)
            else
                timeStr = string.format("%dm remaining", mins)
            end
            table.insert(menu, 2, { title = timeStr, disabled = true })
        end
    end

    return menu
end

return obj
