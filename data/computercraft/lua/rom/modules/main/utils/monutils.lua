--- @diagnostic disable
local l = require("utils.logging")

local monutils = {}

function monutils.getCenterX(max, text)
    if len(text) >= max then return 1 end

    return (math.ceil((max / 2)) - math.floor(len(text) / 2))
end

function monutils.getCenterXByLength(max, len)
    if (len > max) then return 1 end

    return (math.ceil((max / 2)) - math.floor(len / 2))
end

function monutils.getCenterXByMonitor(mon, text)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local maxX, _ = mon.getSize()
    if (len(text) > maxX) then return 1 end

    return (math.ceil((maxX / 2)) - math.floor(len(text) / 2))
end

function monutils.clearAll(mons)
    for index, monitor in ipairs(mons) do
        monitor.clear()
    end
end

function monutils.writeLine(mon, line, text)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local prevX, prevY = mon.getCursorPos()

    mon.setCursorPos(1, line)
    mon.write(text)

    mon.setCursorPos(prevX, prevY)
end

function monutils.clearLine(mon, line)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local prevX, prevY = mon.getCursorPos()

    mon.setCursorPos(1, line)
    mon.clearLine()
    mon.setCursorPos(prevX, prevY)
end

function monutils.clearBetween(mon, startX, endX, y)
    local prevX, prevY = mon.getCursorPos()
    local bgColor = mon.getBackgroundColor()

    for x = startX, endX, 1 do
        monutils.blit(mon, " ", x, y, bgColor, bgColor)
    end

    mon.setCursorPos(prevX, prevY)
end

function monutils.clearFrom(mon, startLine)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local prevX, prevY = mon.getCursorPos()
    local _, maxY = mon.getSize()

    local _y = startLine
    while _y <= maxY do
        mon.setCursorPos(1, _y)
        mon.clearLine()
        _y = _y + 1
    end

    mon.setCursorPos(prevX, prevY)
end

function monutils.blitLine(mon, text, y, color, bgcolor)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local prevX, prevY = mon.getCursorPos()

    mon.setCursorPos(1, y)

    local textCol = string.rep(colors.toBlit(color), len(text))
    local bgCol = string.rep(colors.toBlit(bgcolor), len(text))

    mon.blit(text, textCol, bgCol)

    mon.setCursorPos(prevX, prevY)
end

function monutils.blit(mon, text, x, y, color, bgcolor)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local prevX, prevY = mon.getCursorPos()

    mon.setCursorPos(x, y)

    local textCol = string.rep(colors.toBlit(color), len(text))
    local bgCol = string.rep(colors.toBlit(bgcolor), len(text))

    mon.blit(text, textCol, bgCol)

    mon.setCursorPos(prevX, prevY)
end

function monutils.getWidth(mon)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local x, _ = mon.getSize()
    return x
end

function monutils.getHeight(mon)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local _, y = mon.getSize()
    return y
end

function monutils.drawDivider(mon, line, char)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local prevX, prevY = mon.getCursorPos()
    local length = monutils.getWidth(mon)

    mon.setCursorPos(1, line)
    mon.write(string.rep(char, length))

    mon.setCursorPos(prevX, prevY)
end

function monutils.drawVertical(mon, column, from, to, char)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local prevX, prevY = mon.getCursorPos()

    local _y = from
    while _y <= to do
        mon.setCursorPos(column, _y)
        mon.write(char)
        _y = _y + 1
    end

    mon.setCursorPos(prevX, prevY)
end

function monutils.printSize(mon)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local w, l = mon.getSize()
    mon.setCursorPos(1, 1)
    mon.write("W: " .. w)
    mon.setCursorPos(1, 2)
    mon.write("L: " .. l)
end

function monutils.writeCenter(mon, y, text)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local prevX, prevY = mon.getCursorPos()
    local maxX, maxY = mon.getSize()
    mon.setCursorPos(monutils.getCenterX(maxX, text), y)
    mon.clearLine()
    mon.write(text)
    mon.setCursorPos(prevX, prevY)
end

function monutils.blitCenter(mon, y, text, col, bgcol)
    if (mon == nil) then
        l.error("Monitor is nil", "GUI")
        return
    end

    local prevX, prevY = mon.getCursorPos()
    local centerX = monutils.getCenterXByMonitor(mon, text)

    mon.setCursorPos(centerX, y)

    local textCol = string.rep(colors.toBlit(col), len(text))
    local bgCol = string.rep(colors.toBlit(bgcol), len(text))

    mon.blit(text, textCol, bgCol)

    mon.setCursorPos(prevX, prevY)
end

return monutils;
