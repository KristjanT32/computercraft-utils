---@diagnostic disable 

local MultiMon = {}

---@type table<monitor> The table of all monitors controlled by the instance.
MultiMon.monitors = {}

---Creates a MultiMon instance
---@return MultiMon instance 
function MultiMon:create()
    instance = {}

    setmetatable(instance, self)
    self.__index = self

    return instance
end

--- Registers the supplied monitors to be controlled by this MultiMon instance
---@param ... table<monitor> A list of monitors to be controlled by this multimon instance.
function MultiMon:register(...)
    self.monitors = {...}
end

--- Registers the supplied monitors by first wrapping them using `peripheral.wrap`.
---@param ... string The names of the peripherals (monitors) to register
function MultiMon:wrap_all(...)
    for _, name in ipairs({...}) do
        local success, result = pcall(peripheral.wrap, name)
        if success then
            table.insert(self.monitors, result)
        else
            print("[!] Couldn't find a peripheral called '" .. name .. "'")
        end
    end
end

--- Clears all managed monitors
function MultiMon:clear()
    for _, mon in pairs(self.monitors) do
        mon.clear()
    end
end

--- Displays the monitor ID on each managed monitor.
--- <br>The ident info will be shown for 3 seconds, then the monitors will be cleared.
function MultiMon:ident()
    print(#self.monitors)
    for _, mon in ipairs(self.monitors) do
        local prevX, prevY = mon.getCursorPos()
        local prevColor = mon.getTextColor()
        local w, h = mon.getSize()

        mon.setCursorPos(1, h)
        mon.setTextColor(colors.white)
        mon.write("MultiMon")
        
        local ident_string = "#" .. tostring(_)
        mon.setCursorPos(w - string.len(ident_string) + 1, h)
        mon.setTextColor(colors.yellow)
        mon.write(ident_string)

        mon.setCursorPos(prevX, prevY)
        mon.setTextColor(prevColor)
    end

    sleep(3)
    self:clear()
end

--- Runs the supplied function for each of the monitors, supplying the monitor object as the first argument.
--- <br>Example: `MultiMon:for_each(monitor.write, "Test")` will run `monitor.write(mon, "Test")` for each managed monitor.
---@param func function The function to run for each monitor.
---@param ... any Any parameters to pass into the function.
function MultiMon:for_each(func, ...)
    for _, mon in pairs(self.monitors) do
        func(mon, ...)
    end
end

--- Calls the supplied function on each of the monitors.
--- <br>Example: `MultiMon:call_each("write", "Test")` will run `monitor.write("Test")` on each managed monitor.
---@param func string The name of the function to run
---@param ... any Any arguments to pass into the function 
function MultiMon:call_each(func, ...)
    for _, mon in pairs(self.monitors) do
        mon[func](...)
    end
end

--- Sets each managed monitor's cursor to `(x, y)`
---@param x integer The column
---@param y integer The row
function MultiMon:setCursorPos(x, y)
    self:call_each("setCursorPos", x, y)
end

--- Sets the text color for all managed monitors.
---@param color color The new text color
function MultiMon:setTextColor(color)
    self:call_each("setTextColor", color)
end

--- Sets the cursor position to `(x, y)` and writes `text` on all of the managed monitors.
---@param text string The text to write
---@param x integer The column
---@param y integer The row
function MultiMon:write(text, x, y)
    self:setCursorPos(x, y)
    self:call_each("write", text)
end

--- Writes `text` on the supplied line on all managed monitors.
---@param text string The text to write
---@param line integer The line number
function MultiMon:writeLine(text, line)
    self:write(text, 1, line)
end

--- Returns a table of all managed monitors.
---@return table<monitor>
function MultiMon:get_monitors()
    return self.monitors
end

return MultiMon