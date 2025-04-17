local m = require("utils.monutils")

--- @diagnostic disable

-- A useful GUI library to make working with monitor GUIs easier.
local guilib = {}

function guilib.createButton(text, color, bgcolor, clickedColor)
    local button = {}
    button.text = text
    button.shouldClear = true

    button.textColor = colors.toBlit(color)
    button.bgColor = colors.toBlit(bgcolor)
    button.clickedColor = clickedColor

    button.length = string.len(text)

    button.posX = button.posX or 1
    button.posY = button.posY or 1

    button.prevLength = string.len(text)
    button.prevX = nil

    button.visible = true
    button.visibleOnScreen = false

    button.onAction = function() end

    --- Use this function to update your monitor table to control the button's visibility.
    --- If you don't, your button will always be visible (and therefore usable), even if it
    --- is actually not on the screen.<br>
    --- Usage: `monitor = button.connect(monitor)`
    --- @param monitor table The monitor on which it will be displayed.
    --- @return table monitor The updated monitor table.
    function button.connect(monitor)
        local old_clear = monitor.clear
        monitor.clear = function()
            button.visibleOnScreen = false
            old_clear()
        end

        local old_clearline = monitor.clearLine
        monitor.clearLine = function()
            local x, y = monitor.getCursorPos()
            if (y == button.posY) then
                button.visibleOnScreen = false
            end
            old_clearline()
        end

        return monitor
    end

    function button.setText(_text)
        if (_text == button.text) then return end

        button.text = _text
        button.prevLength = button.length
        button.length = string.len(button.text)
        button.shouldClear = true
    end

    function button.setColor(_color)
        if (colors.toBlit(_color) == button.textColor) then return end
        button.textColor = colors.toBlit(_color)
        button.shouldClear = true
    end

    function button.setClickedColor(_color)
        if (colors.toBlit(_color) == button.clickedColor) then return end
        button.clickedColor = colors.toBlit(_color)
        button.shouldClear = true
    end

    function button.setBackground(_bg)
        if (colors.toBlit(_bg) == button.bgColor) then return end
        button.bgColor = colors.toBlit(_bg)
        button.shouldClear = true
    end

    function button.setAction(func)
        button.onAction = func
    end

    function button.setVisible(visible)
        if (visible == button.visible) then return end
        button.visible = visible
        button.shouldClear = true
    end

    function button.onclick(side, x, y)
        if (not button.visible) then return end
        if (button.monitor ~= nil) then
            if (peripheral.getName(button.monitor) == side) then
                local endX = 0
                if (button.length > 1) then
                    endX = button.length + button.posX
                else
                    endX = button.posX
                end
                if (x >= button.posX and x <= endX and y == button.posY) then
                    local prevColor = button.bgColor
                    button.setBackground(button.clickedColor)
                    button.draw(button.monitor, button.posX, button.posY)
                    sleep(.1)
                    button.setBackground(colors.fromBlit(prevColor))
                    button.draw(button.monitor, button.posX, button.posY)

                    button.onAction()
                end
            end
        end
    end

    function button.draw(mon, x, y)
        local prevX, prevY = mon.getCursorPos()

        -- Clear everything in the area the button was last time, if required
        if (button.shouldClear) then
            if (button.prevX ~= nil) then
                for _x = button.prevX, (button.prevLength + button.prevX) - 1, 1 do
                    mon.setCursorPos(_x, y)
                    mon.blit("|", colors.toBlit(mon.getBackgroundColor()), colors.toBlit(mon.getBackgroundColor()))
                end
            end
            button.visibleOnScreen = false
            button.shouldClear = false
        end

        if (button.visible) then
            mon.setCursorPos(x, y)
            mon.blit(button.text, string.rep(button.textColor, button.length), string.rep(button.bgColor, button.length))

            button.posX = x
            button.posY = y
            button.prevX = x

            button.visibleOnScreen = true
        end

        button.monitor = mon

        mon.setCursorPos(prevX, prevY)
    end

    function button.click()
        button.onAction()
    end

    function button.getText()
        return button.text
    end

    function button.getTextLength()
        return button.length
    end

    function button.getTextColor()
        return button.textColor
    end

    function button.getBackgroundColor()
        return button.bgColor
    end

    function button.getPressedColor()
        return button.clickedColor
    end

    function button.isVisible()
        return button.visible
    end

    function button.isVisibleOnScreen()
        return button.visibleOnScreen
    end

    return {
        connect = button.connect,
        setText = button.setText,
        setColor = button.setColor,
        setClickedColor = button.setClickedColor,
        setBackgroundColor = button.setBackground,
        setAction = button.setAction,
        setVisible = button.setVisible,
        onclick = button.onclick,
        draw = button.draw,
        click = button.click,
        getText = button.getText,
        getTextLength = button.getTextLength,
        getTextColor = button.getTextColor,
        getBackgroundColor = button.getBackgroundColor,
        getPressedColor = button.getPressedColor,
        isVisible = button.isVisible,
        isVisibleOnScreen = button.isVisibleOnScreen
    }
end

function guilib.createLabel(text, color, bgcolor)
    local label = {}

    label.text = text
    label.length = string.len(label.text)

    label.textColor = colors.toBlit(color)
    label.bgColor = colors.toBlit(bgcolor)

    label.posX = label.posX or 1
    label.posY = label.posY or 1
    label.prevX = nil
    label.prevLength = string.len(label.text)

    label.visible = true
    label.shouldClear = true


    function label.setColor(color)
        if (colors.toBlit(color) == label.textColor) then return end
        label.textColor = colors.toBlit(color)
        label.shouldClear = true
    end

    function label.setBackgroundColor(color)
        if (colors.toBlit(color) == label.bgColor) then return end
        label.bgColor = colors.toBlit(color)
        label.shouldClear = true
    end

    function label.setText(text)
        if (text == label.text) then return end
        label.text = text
        label.prevLength = label.length
        label.length = string.len(text)
        label.shouldClear = true
    end

    function label.setVisible(visible)
        if (visible == label.visible) then return end
        label.visible = visible
        label.shouldClear = true
    end

    function label.draw(mon, x, y)
        local prevX, prevY = mon.getCursorPos()

        -- Clear everything in the area the label was last time, if required
        if (label.shouldClear) then
            if (label.prevX ~= nil) then
                for _x = label.prevX, (label.prevLength + label.prevX) - 1, 1 do
                    mon.setCursorPos(_x, y)
                    mon.blit("|", colors.toBlit(mon.getBackgroundColor()), colors.toBlit(mon.getBackgroundColor()))
                end
            end
            label.shouldClear = false
        end

        if (label.visible) then
            mon.setCursorPos(x, y)
            mon.blit(label.text, string.rep(label.textColor, label.length), string.rep(label.bgColor, label.length))

            label.posX = x
            label.posY = y
            label.prevX = x
        end

        mon.setCursorPos(prevX, prevY)
    end

    function label.getText()
        return label.text
    end

    function label.getTextColor()
        return label.textColor
    end

    function label.getBackgroundColor()
        return label.bgColor
    end

    function label.getTextLength()
        return label.length
    end

    function label.isVisible()
        return label.visible
    end

    return {
        setColor = label.setColor,
        setBackgroundColor = label.setBackgroundColor,
        setText = label.setText,
        setVisible = label.setVisible,
        getText = label.getText,
        getTextColor = label.getTextColor,
        getBackgroundColor = label.getBackgroundColor,
        getTextLength = label.getTextLength,
        isVisible = label.isVisible,
        draw = label.draw
    }
end

--- Creates a scrolling label (a label line-wide bar with a piece of text scrolling from start to end endlessly)
--- @param text string The scrolling text
--- @param color color The color of the text
--- @param bgcolor color The color of the background
--- @param rightToLeft boolean Whether the scroller scrolls from right to left (false -> left to right)
function guilib.createScrollingLabel(text, color, bgcolor, rightToLeft)
    local label = {}

    label.text = text
    label.length = string.len(text)

    label.textColor = colors.toBlit(color)
    label.bgColor = colors.toBlit(bgcolor)

    label.posX = label.posX or 1
    label.posY = label.posY or 1
    label.posIndex = label.posIndex or 1

    label.startReached = false
    label.rightToLeft = rightToLeft

    label.visible = true


    function label.setColor(color)
        label.textColor = colors.toBlit(color)
    end

    function label.setBackgroundColor(color)
        label.bgColor = colors.toBlit(color)
    end

    function label.setText(text)
        label.text = text
        label.length = string.len(text)
    end

    function label.setVisible(visible)
        label.visible = visible
    end

    function label.draw(mon, y)
        local prevX, prevY = mon.getCursorPos()
        local width, height = mon.getSize()

        -- Draw static BG
        mon.setCursorPos(prevX, y)
        mon.clearLine()

        -- If the label is not visible, don't draw it
        if (not label.visible) then return end

        mon.blit(string.rep("|", width), string.rep(label.bgColor, width), string.rep(label.bgColor, width))

        if (label.rightToLeft == false) then
            -- LEFT TO RIGHT

            -- Draw moving text
            if (label.posIndex >= 1 and label.posIndex < label.length) then
                -- Do not move the x-position  until the text is fully drawn in the beginning of the line
                mon.setCursorPos(1, y)

                -- First, draw the BG
                mon.blit(string.rep("|", width), string.rep(label.bgColor, width), string.rep(label.bgColor, width))
                mon.setCursorPos(1, y)

                _str = string.sub(label.text, label.length - label.posIndex + 1, label.length)
                mon.blit(_str, string.rep(label.textColor, string.len(_str)), string.rep(label.bgColor, string.len(_str)))

                -- Advance position index
                if (label.posIndex <= width + label.length) then
                    label.posIndex = label.posIndex + 1
                else
                    label.posIndex = 1
                end
            else
                -- First, draw the BG
                mon.blit(string.rep("|", width), string.rep(label.bgColor, width), string.rep(label.bgColor, width))
                mon.setCursorPos(1, y)

                mon.setCursorPos(label.posX, y)
                mon.blit(label.text, string.rep(label.textColor, label.length), string.rep(label.bgColor, label.length))

                -- Advance position, since the text is now visible
                if (label.posX < width) then
                    label.posX = label.posX + 1
                else
                    label.posX = 1
                    label.posIndex = 1
                end
            end
            label.posY = y
        else
            -- RIGHT TO LEFT

            -- Draw moving text
            if (label.posIndex >= 1 and label.posIndex <= width + label.length) then
                -- Move the x-position to the far right at the beginning of the line
                mon.setCursorPos(width - label.posIndex + 1, y)

                _str = string.sub(label.text, 1, math.min(label.posIndex, label.length))
                mon.blit(_str, string.rep(label.textColor, string.len(_str)), string.rep(label.bgColor, string.len(_str)))

                -- Advance position index
                if (label.posIndex < width + label.length) then
                    label.posIndex = label.posIndex + 1
                else
                    label.posIndex = 1
                end
            else
                mon.setCursorPos(1, y)
                mon.blit(label.text, string.rep(label.textColor, label.length), string.rep(label.bgColor, label.length))

                -- Advance position, since the text is now visible
                if (label.posIndex < width + label.length) then
                    label.posIndex = label.posIndex + 1
                else
                    label.posIndex = 1
                end
            end
            label.posY = y
        end


        mon.setCursorPos(prevX, prevY)
    end

    function label.getLength()
        return label.length
    end

    function label.getText()
        return label.text
    end

    function label.getTextColor()
        return label.textColor
    end

    function label.getBackgroundColor()
        return label.bgColor
    end

    function label.isRightToLeft()
        return label.rightToLeft
    end

    function label.isVisible()
        return label.visible
    end

    return {
        draw = label.draw,
        setText = label.setText,
        setColor = label.setColor,
        setBackgroundColor = label.setBackgroundColor,
        setVisible = label.setVisible,
        getLength = label.getLength,
        getText = label.getText,
        getTextColor = label.getTextColor,
        getBackgroundColor = label.getBackgroundColor,
        isRightToLeft = label.isRightToLeft,
        isVisible = label.isVisible
    }
end

--- Creates a progressbar that takes up one line
---@param val number The current value of the progressbar
---@param max number The maximum value of the progressbar
---@param fillColor string The color of the progressbar fill
---@param bgColor string The color of the progressbar background
function guilib.createLinewideProgressbar(val, max, fillColor, bgColor)
    local progressbar = {}

    progressbar.value = val
    progressbar.max = max
    progressbar.percentage = progressbar.value / progressbar.max

    progressbar.fillColor = colors.toBlit(fillColor)
    progressbar.bgColor = colors.toBlit(bgColor)

    progressbar.length = 0

    progressbar.posX = progressbar.posX or 1
    progressbar.posY = progressbar.posY or 1

    progressbar.visible = true
    progressbar.shouldClear = true

    progressbar.onClick = function() end

    function progressbar.draw(mon, x, y)
        local prevX, prevY = mon.getCursorPos()
        local prevTextColor = mon.getTextColor()
        local prevBg = mon.getBackgroundColor()


        local length, _ = mon.getSize()
        progressbar.length = progressbar.length or
            string.len(string.rep("|", math.floor(length * progressbar.percentage)))

        local progress = progressbar.percentage * length
        local textlen = math.floor(progress)

        mon.setCursorPos(x, y)

        if (progressbar.shouldClear) then
            mon.clearLine()
            progressbar.shouldClear = false
        end

        -- If the progressbar is not visible, don't draw it
        if (not progressbar.visible) then return end

        mon.setCursorPos(x, y)
        mon.blit(string.rep("|", length), string.rep(progressbar.bgColor, length),
            string.rep(progressbar.bgColor, length))
        mon.setCursorPos(x, y)

        mon.blit(string.rep("|", textlen), string.rep(progressbar.fillColor, textlen),
            string.rep(progressbar.fillColor, textlen))

        mon.setCursorPos(prevX, prevY)
        mon.setTextColor(prevTextColor)
        mon.setBackgroundColor(prevBg)
    end

    function progressbar.update(value)
        if (value == progressbar.value) then return end
        if (value >= progressbar.max) then
            progressbar.value = progressbar.max
        elseif (value <= 0) then
            progressbar.value = 0
        else
            progressbar.value = value
        end

        progressbar.percentage = progressbar.value / progressbar.max
        progressbar.shouldClear = true
    end

    function progressbar.onclick()
        progressbar.onClick()
    end

    function progressbar.setAction(func)
        progressbar.onclick = func
    end

    function progressbar.setMax(max)
        if (max == progressbar.max) then return end
        progressbar.max = max
        progressbar.shouldClear = true
    end

    function progressbar.setColor(color)
        if (colors.toBlit(color) == progressbar.fillColor) then return end
        progressbar.fillColor = colors.toBlit(color)
        progressbar.shouldClear = true
    end

    function progressbar.setBackground(color)
        if (colors.toBlit(color) == progressbar.bgColor) then return end
        progressbar.bgColor = colors.toBlit(color)
        progressbar.shouldClear = true
    end

    function progressbar.setVisible(visible)
        if (visible == progressbar.visible) then return end
        progressbar.visible = visible
        progressbar.shouldClear = true
    end

    function progressbar.getValue()
        return progressbar.value
    end

    function progressbar.getMaxValue()
        return progressbar.max
    end

    function progressbar.getTextLength()
        return progressbar.length
    end

    function progressbar.isVisible()
        return progressbar.visible
    end

    return {
        draw = progressbar.draw,
        setMax = progressbar.setMax,
        update = progressbar.update,
        setFillColor = progressbar.setColor,
        setBackgroundColor = progressbar.setBackground,
        setVisible = progressbar.setVisible,
        isVisible = progressbar.isVisible,
        getValue = progressbar.getValue,
        getMaxValue = progressbar.getMaxValue,
        getTextLength = progressbar.getTextLength
    }
end

--- Creates a progressbar. The area it should occupy is set upon calling `progressbar.draw(mon, from, to, y)`
---@param val number The current value of the progressbar (in percentages)
---@param max number The maximum value of the progressbar
---@param fillColor string The color of the progressbar fill
---@param bgColor string The color of the progressbar background
function guilib.createLimitedProgressbar(val, max, fillColor, bgColor)
    local progressbar = {}

    progressbar.value = val
    progressbar.max = max
    progressbar.percentage = progressbar.value / progressbar.max

    progressbar.fillColor = colors.toBlit(fillColor)
    progressbar.bgColor = colors.toBlit(bgColor)

    progressbar.length = 0

    progressbar.posX = progressbar.posX or 1
    progressbar.posY = progressbar.posY or 1

    progressbar.visible = true
    progressbar.shouldClear = true

    function progressbar.draw(mon, from_x, to_x, y)
        local prevX, prevY = mon.getCursorPos()
        local prevTextColor = mon.getTextColor()
        local prevBg = mon.getBackgroundColor()

        local fill_area = (to_x - from_x)
        local progress = progressbar.percentage * fill_area
        local textlen = math.floor(progress)
        progressbar.length = progressbar.length or textlen

        mon.setCursorPos(from_x, y)

        -- Clear everything between from_x and to_x
        if (progressbar.shouldClear) then
            for _x = from_x, 1, to_x + 1 do
                mon.setCursorPos(_x, y)
                mon.write("")
            end

            mon.setCursorPos(from_x, y)
            progressbar.shouldClear = false
        end

        -- If the progressbar is not visible, don't draw it
        if (not progressbar.visible) then return end

        mon.blit(string.rep("|", fill_area), string.rep(progressbar.bgColor, fill_area),
            string.rep(progressbar.bgColor, fill_area))
        mon.setCursorPos(from_x, y)

        mon.blit(string.rep("|", textlen), string.rep(progressbar.fillColor, textlen),
            string.rep(progressbar.fillColor, textlen))

        mon.setCursorPos(prevX, prevY)
        mon.setTextColor(prevTextColor)
        mon.setBackgroundColor(prevBg)
    end

    function progressbar.update(value)
        if (value == progressbar.value) then return end
        if (value >= progressbar.max) then
            progressbar.value = progressbar.max
        elseif (value <= 0) then
            progressbar.value = 0
        else
            progressbar.value = value
        end

        progressbar.percentage = progressbar.value / progressbar.max
        progressbar.shouldClear = true
    end

    function progressbar.setMax(max)
        if (max == progressbar.max) then return end
        progressbar.max = max
        progressbar.shouldClear = true
    end

    function progressbar.setColor(color)
        if (colors.toBlit(color) == progressbar.fillColor) then return end
        progressbar.fillColor = colors.toBlit(color)
        progressbar.shouldClear = true
    end

    function progressbar.setBackground(color)
        if (colors.toBlit(color) == progressbar.bgColor) then return end
        progressbar.bgColor = colors.toBlit(color)
        progressbar.shouldClear = true
    end

    function progressbar.setVisible(visible)
        if (visible == progressbar.visible) then return end
        progressbar.visible = visible
        progressbar.shouldClear = true
    end

    function progressbar.getValue()
        return progressbar.value
    end

    function progressbar.getMaxValue()
        return progressbar.max
    end

    function progressbar.getTextLength()
        return progressbar.length
    end

    function progressbar.isVisible()
        return progressbar.visible
    end

    return {
        draw = progressbar.draw,
        setMax = progressbar.setMax,
        update = progressbar.update,
        setFillColor = progressbar.setColor,
        setBackgroundColor = progressbar.setBackground,
        setVisible = progressbar.setVisible,
        isVisible = progressbar.isVisible,
        getValue = progressbar.getValue,
        getMaxValue = progressbar.getMaxValue,
        getTextLength = progressbar.getTextLength
    }
end

--- Creates a full-height vertical progressbar using the entire height of the monitor
---@param val number The current value of the progressbar
---@param max number The maximum value of the progressbar
---@param fillColor string The color of the filled portion
---@param bgColor string The color of the unfilled portion
---@param direction? "top-down"|"bottom-up" Whether the bar fills from top or bottom (default is "bottom-up")
function guilib.createVerticalFullHeightProgressbar(val, max, fillColor, bgColor, direction)
    local progressbar = {}

    progressbar.value = val
    progressbar.max = max
    progressbar.percentage = progressbar.value / progressbar.max

    progressbar.fillColor = colors.toBlit(fillColor)
    progressbar.bgColor = colors.toBlit(bgColor)
    progressbar.direction = direction or "bottom-up"

    progressbar.visible = true
    progressbar.shouldClear = true
    progressbar.height = 0

    function progressbar.draw(mon, x)
        local prevX, prevY = mon.getCursorPos()
        local prevTextColor = mon.getTextColor()
        local prevBg = mon.getBackgroundColor()

        local _, height = mon.getSize()
        local progress = progressbar.percentage * height
        local fill_height = math.floor(progress)
        progressbar.height = fill_height

        -- Clear
        if progressbar.shouldClear then
            for y = 1, height do
                mon.setCursorPos(x, y)
                mon.blit(" ", progressbar.bgColor, progressbar.bgColor)
            end
            progressbar.shouldClear = false
        end

        if not progressbar.visible then return end

        -- Background
        for y = 1, height do
            mon.setCursorPos(x, y)
            mon.blit("|", progressbar.bgColor, progressbar.bgColor)
        end

        -- Foreground
        if progressbar.direction == "top-down" then
            for y = 1, fill_height do
                mon.setCursorPos(x, y)
                mon.blit("|", progressbar.fillColor, progressbar.fillColor)
            end
        else -- "bottom-up"
            for y = height - fill_height + 1, height do
                mon.setCursorPos(x, y)
                mon.blit("|", progressbar.fillColor, progressbar.fillColor)
            end
        end

        mon.setCursorPos(prevX, prevY)
        mon.setTextColor(prevTextColor)
        mon.setBackgroundColor(prevBg)
    end

    function progressbar.update(value)
        if (value == progressbar.value) then return end
        if (value >= progressbar.max) then
            progressbar.value = progressbar.max
        elseif (value <= 0) then
            progressbar.value = 0
        else
            progressbar.value = value
        end

        progressbar.percentage = progressbar.value / progressbar.max
        progressbar.shouldClear = true
    end

    function progressbar.setMax(max)
        if (max == progressbar.max) then return end
        progressbar.max = max
        progressbar.shouldClear = true
    end

    function progressbar.setColor(color)
        if (colors.toBlit(color) == progressbar.fillColor) then return end
        progressbar.fillColor = colors.toBlit(color)
        progressbar.shouldClear = true
    end

    function progressbar.setBackground(color)
        if (colors.toBlit(color) == progressbar.bgColor) then return end
        progressbar.bgColor = colors.toBlit(color)
        progressbar.shouldClear = true
    end

    function progressbar.setVisible(visible)
        if (visible == progressbar.visible) then return end
        progressbar.visible = visible
        progressbar.shouldClear = true
    end

    function progressbar.setDirection(dir)
        if (dir == progressbar.direction) then return end
        if dir == "top-down" or dir == "bottom-up" then
            progressbar.direction = dir
            progressbar.shouldClear = true
        end
    end

    function progressbar.getValue()
        return progressbar.value
    end

    function progressbar.getMaxValue()
        return progressbar.max
    end

    function progressbar.getTextLength()
        return progressbar.height
    end

    function progressbar.isVisible()
        return progressbar.visible
    end

    return {
        draw = progressbar.draw,
        setMax = progressbar.setMax,
        update = progressbar.update,
        setFillColor = progressbar.setColor,
        setBackgroundColor = progressbar.setBackground,
        setVisible = progressbar.setVisible,
        setDirection = progressbar.setDirection,
        isVisible = progressbar.isVisible,
        getValue = progressbar.getValue,
        getMaxValue = progressbar.getMaxValue,
        getTextLength = progressbar.getTextLength
    }
end

--- Creates a vertical progressbar. The area it should occupy is set upon calling `progressbar.draw(mon, x, from_y, to_y)`
---@param val number The current value of the progressbar
---@param max number The maximum value of the progressbar
---@param fillColor string The color of the progressbar fill
---@param bgColor string The color of the progressbar background
---@param direction? "top-down"|"bottom-up" Whether the bar fills from top or bottom (default is "bottom-up")
function guilib.createVerticalLimitedProgressbar(val, max, fillColor, bgColor, direction)
    local progressbar = {}

    progressbar.value = val
    progressbar.max = max
    progressbar.percentage = progressbar.value / progressbar.max

    progressbar.fillColor = colors.toBlit(fillColor)
    progressbar.bgColor = colors.toBlit(bgColor)

    progressbar.height = 0
    progressbar.direction = direction or "bottom-up"

    progressbar.posX = progressbar.posX or 1
    progressbar.posY = progressbar.posY or 1

    progressbar.visible = true
    progressbar.shouldClear = true

    function progressbar.draw(mon, x, from_y, to_y)
        local prevX, prevY = mon.getCursorPos()
        local prevTextColor = mon.getTextColor()
        local prevBg = mon.getBackgroundColor()

        local fill_area = (to_y - from_y + 1)
        local progress = progressbar.percentage * fill_area
        local fill_height = math.floor(progress)
        progressbar.height = progressbar.height or fill_height

        -- Clear
        if (progressbar.shouldClear) then
            for y = from_y, to_y do
                mon.setCursorPos(x, y)
                mon.blit(" ", progressbar.bgColor, progressbar.bgColor)
            end
            progressbar.shouldClear = false
        end

        if (not progressbar.visible) then return end

        -- Background
        for y = from_y, to_y do
            mon.setCursorPos(x, y)
            mon.blit("|", progressbar.bgColor, progressbar.bgColor)
        end

        -- Foreground
        if progressbar.direction == "top-down" then
            for y = from_y, from_y + fill_height - 1 do
                if y <= to_y then
                    mon.setCursorPos(x, y)
                    mon.blit("|", progressbar.fillColor, progressbar.fillColor)
                end
            end
        else -- "bottom-up"
            for y = to_y - fill_height + 1, to_y do
                if y >= from_y then
                    mon.setCursorPos(x, y)
                    mon.blit("|", progressbar.fillColor, progressbar.fillColor)
                end
            end
        end

        mon.setCursorPos(prevX, prevY)
        mon.setTextColor(prevTextColor)
        mon.setBackgroundColor(prevBg)
    end

    function progressbar.update(value)
        if (value == progressbar.value) then return end
        if (value >= progressbar.max) then
            progressbar.value = progressbar.max
        elseif (value <= 0) then
            progressbar.value = 0
        else
            progressbar.value = value
        end

        progressbar.percentage = progressbar.value / progressbar.max
        progressbar.shouldClear = true
    end

    function progressbar.setMax(max)
        if (max == progressbar.max) then return end
        progressbar.max = max
        progressbar.shouldClear = true
    end

    function progressbar.setColor(color)
        if (colors.toBlit(color) == progressbar.fillColor) then return end
        progressbar.fillColor = colors.toBlit(color)
        progressbar.shouldClear = true
    end

    function progressbar.setBackground(color)
        if (colors.toBlit(color) == progressbar.bgColor) then return end
        progressbar.bgColor = colors.toBlit(color)
        progressbar.shouldClear = true
    end

    function progressbar.setVisible(visible)
        if (visible == progressbar.visible) then return end
        progressbar.visible = visible
        progressbar.shouldClear = true
    end

    function progressbar.setDirection(dir)
        if (dir == progressbar.direction) then return end
        if dir == "top-down" or dir == "bottom-up" then
            progressbar.direction = dir
            progressbar.shouldClear = true
        end
    end

    function progressbar.getValue()
        return progressbar.value
    end

    function progressbar.getMaxValue()
        return progressbar.max
    end

    function progressbar.getTextLength()
        return progressbar.height
    end

    function progressbar.isVisible()
        return progressbar.visible
    end

    return {
        draw = progressbar.draw,
        setMax = progressbar.setMax,
        update = progressbar.update,
        setFillColor = progressbar.setColor,
        setBackgroundColor = progressbar.setBackground,
        setVisible = progressbar.setVisible,
        setDirection = progressbar.setDirection,
        isVisible = progressbar.isVisible,
        getValue = progressbar.getValue,
        getMaxValue = progressbar.getMaxValue,
        getTextLength = progressbar.getTextLength
    }
end

--- Creates a list view.
--- @param header string The header of the list view.
--- @param headerTextColor string The color of the header text.
--- @param headerBackground string The color of the header background.
--- @param itemTextColor string The color of the item text.
--- @param itemBackground string The color of the item background.
--- @param listBackgroundColor string The color of the background.
--- @param itemHeight integer The height of a single item in lines.
function guilib.createListView(header, headerTextColor, headerBackground, itemTextColor, itemBackground,
                               listBackgroundColor, itemHeight)
    local listView = {}

    listView.header = header
    listView.headerColor = colors.toBlit(headerTextColor)

    listView.headerBg = colors.toBlit(headerBackground)
    listView.bgColor = colors.toBlit(listBackgroundColor)

    listView.itemColor = colors.toBlit(itemTextColor)
    listView.itemBgColor = colors.toBlit(itemBackground)

    listView.selectedItemColor = colors.toBlit(colors.black)
    listView.selectedItemBgColor = colors.toBlit(colors.white)

    listView.startY = listView.startY or 1
    listView.endY = listView.endY or 0

    listView.monWidth, listView.monHeight = 0, 0

    listView.firstItemOffsetFromTop = 3

    listView.items = {}
    listView.itemHeight = itemHeight or 1

    -- A table of all items' positional data.
    -- Element format: `{index: integer, startX: integer, endX: integer, startY: integer, endY: integer}`
    listView.itemPositions = {}

    listView.scrollPosition = 1

    listView.monitor = {}

    listView.onSelect = function(item) end

    listView.visible = true
    listView.visibleOnScreen = true

    listView.clickable = true
    listView.showTotal = true

    listView.shouldRefresh = true
    listView.shouldClear = false
    listView.currentHighlightedElementIndex = -1

    -- All GUI elements that make up the list view.
    listView.gui = {
        header = guilib.createLabel(listView.header, colors.fromBlit(listView.headerColor),
            colors.fromBlit(listView.headerBg)),
        counter = guilib.createLabel("0/0", colors.fromBlit(listView.headerColor),
            colors.fromBlit(listView.headerBg)),
        scrollUp = guilib.createButton("\30", colors.white, colors.green, colors.gray),
        scrollDown = guilib.createButton("\31", colors.white, colors.green, colors.gray),
        scrollReset = guilib.createButton("\7", colors.white, colors.blue, colors.lightBlue),
    }

    listView.gui.counter.setVisible(listView.showTotal)

    listView.gui.scrollUp.setAction(function()
        if (listView.scrollPosition <= 1) then
            listView.scrollPosition = 1
        else
            listView.scrollPosition = listView.scrollPosition - 1
        end
        listView.shouldRefresh = true
    end)

    listView.gui.scrollDown.setAction(function()
        if (listView.scrollPosition >= #listView.items) then
            listView.scrollPosition = #listView.items
        else
            listView.scrollPosition = listView.scrollPosition + 1
        end
        listView.shouldRefresh = true
    end)

    listView.gui.scrollReset.setAction(function()
        listView.scrollPosition = 1
        listView.shouldRefresh = true
    end)

    --- Use this function to update your monitor to control the list view's visibility.
    --- If you don't, your list view will always be visible (and therefore usable), even if it
    --- is actually not on the screen.<br>
    --- Usage: `monitor = listView.connect(monitor)`
    --- @param monitor table The monitor on which it will be displayed.
    --- @return table monitor The updated monitor table.
    function listView.connect(monitor)
        listView.monitor = monitor
        listView.monWidth, listView.monHeight = monitor.getSize()

        local old_clear = monitor.clear
        monitor.clear = function()
            listView.visibleOnScreen = false
            old_clear()
        end

        local old_clearline = monitor.clearLine
        monitor.clearLine = function()
            local x, y = monitor.getCursorPos()
            if (y >= listView.startY or y <= listView.endY) then
                listView.visibleOnScreen = false
            end
            old_clearline()
        end

        monitor = listView.gui.scrollUp.connect(monitor)
        monitor = listView.gui.scrollDown.connect(monitor)
        monitor = listView.gui.scrollReset.connect(monitor)

        return monitor
    end

    --- Sets the header of the list view.
    --- @param header string The header text.
    function listView.setHeader(header)
        if (header == listView.header) then return end
        listView.header = header
        listView.shouldClear = true
    end

    --- Sets the header text color of the list view.
    --- @param color color The color of the header text.
    function listView.setHeaderTextColor(color)
        if (colors.toBlit(color) == listView.headerTextColor) then return end
        listView.headerTextColor = colors.toBlit(color)
        listView.shouldClear = true
    end

    --- Sets the item text color of the list view.
    --- @param color color The color of the item text.
    function listView.setItemColor(color)
        if (colors.toBlit(color) == listView.itemTextColor) then return end
        listView.itemTextColor = colors.toBlit(color)
        listView.shouldClear = true
    end

    --- Sets the item background color.
    --- @param color color The color of the item background.
    function listView.setItemBgColor(color)
        if (colors.toBlit(color) == listView.itemBgColor) then return end
        listView.itemBgColor = colors.toBlit(color)
        listView.shouldClear = true
    end

    --- Sets the selected item text color.
    --- @param color color The color of the selected item text.
    function listView.setSelectedItemColor(color)
        if (colors.toBlit(color) == listView.selectedItemColor) then return end
        listView.selectedItemColor = colors.toBlit(color)
        listView.shouldClear = true
    end

    --- Sets the selected item background color.
    --- @param color color The color of the selected item background.
    function listView.setSelectedItemBackground(color)
        if (colors.toBlit(color) == listView.selectedItemBgColor) then return end
        listView.selectedItemBgColor = colors.toBlit(color)
        listView.shouldClear = true
    end

    --- Sets the background color for the list view.
    --- @param color color The color of the background.
    function listView.setBackground(color)
        if (colors.toBlit(color) == listView.bgColor) then return end
        listView.bgColor = colors.toBlit(color)
        listView.shouldClear = true
    end

    --- Sets the background color for the list view's header.
    --- @param color color The color of the background for the header.
    function listView.setHeaderBackground(color)
        if (colors.toBlit(color) == listView.headerBg) then return end
        listView.headerBg = colors.toBlit(color)
        listView.shouldClear = true
    end

    --- Adds an item to the list view.
    --- @param item string The text content of the item to add.
    function listView.addItem(item)
        table.insert(listView.items, item)
        listView.shouldRefresh = true
    end

    --- Removes an item from the list view.
    --- @param item integer|string The index or text content of the item to remove.
    function listView.removeItem(index)
        if (type(index) == "string") then
            for i, item in pairs(listView.items) do
                if (item == index) then
                    index = i
                    break
                end
            end
        end

        table.remove(listView.items, index)
        listView.shouldRefresh = true
    end

    --- Returns the index of an item in the list view.
    --- @param itemText string The text content of the item to find.
    --- @return integer index The index of the item, or `-1` if not found.
    function listView.getItemIndex(itemText)
        for i, item in pairs(listView.items) do
            if (item == itemText) then
                return i
            end
        end
        return -1
    end

    --- Clears the list view and causes a redraw.
    function listView.clear()
        listView.items = {}
        listView.itemPositions = {}
        listView.scrollPosition = 1
        listView.currentHighlightedElementIndex = -1
        listView.shouldClear = true
    end

    --- Sets the function to be called
    --- when a list element is selected (clicked on)
    --- The function will be called with a table containing the index and text content of the item.
    --- Table format: `{index: integer, text: string}`
    --- @param func function The function to be called when an item is selected.
    function listView.setOnSelect(func)
        listView.onSelect = function(item)
            func(item)
        end
    end

    --- Toggles the ability of the user to click on list elements.
    --- This will also prevent the selection callback from being called.
    --- @param clickable boolean Whether the list view's items should be clickable.
    function listView.setClickable(clickable)
        listView.clickable = clickable
    end

    --- Toggles the visibility of the list view's item counter next to the header.
    --- @param showTotal boolean Whether to show the total number of items next to the header.
    function listView.setShowTotal(showTotal)
        if (showTotal == listView.showTotal) then return end
        listView.showTotal = showTotal
        listView.shouldClear = true
    end

    --- Gets the header of the list view.
    --- @return string header The header text.
    function listView.getHeader()
        return listView.header
    end

    --- Gets the header text color of the list view.
    --- @return color color The color of the header text.
    function listView.getHeaderTextColor()
        return colors.fromBlit(listView.headerTextColor)
    end

    --- Gets the item text color of the list view.
    --- @return color color The color of the item text.
    function listView.getItemColor()
        return colors.fromBlit(listView.itemTextColor)
    end

    --- Gets the item background color.
    --- @return color color The color of the item background.
    function listView.getItemBgColor()
        return colors.fromBlit(listView.itemBgColor)
    end

    --- Gets the selected item text color.
    --- @return color color The color of the selected item text.
    function listView.getSelectedItemColor()
        return colors.fromBlit(listView.selectedItemColor)
    end

    --- Gets the selected item background color.
    --- @return color color The color of the selected item background.
    function listView.getSelectedItemBackground()
        return colors.fromBlit(listView.selectedItemBgColor)
    end

    --- Gets the background color for the list view.
    --- @return color color The color of the background.
    function listView.getBackground()
        return colors.fromBlit(listView.backgroundColor)
    end

    --- Gets the background color for the list view's header.
    --- @return color color The color of the background for the header.
    function listView.getHeaderBackground()
        return colors.fromBlit(listView.headerBg)
    end

    --- Gets whether the list view's items are clickable.
    --- @return boolean clickable Whether the list view's items are clickable.
    function listView.getClickable()
        return listView.clickable
    end

    --- Gets whether the list view's item counter is visible.
    --- @return boolean showTotal Whether the item counter is visible.
    function listView.getShowTotal()
        return listView.showTotal
    end

    function listView.getClickedItem(x, y)
        if (sizeof(listView.itemPositions) == 0) then return nil end

        for _, item in pairs(listView.itemPositions) do
            if (y >= item.startY and y <= item.endY) then
                if (x >= item.startX and x <= item.endX) then
                    return item
                end
            end
        end
        return nil
    end

    function listView.highlightItem(index, reset)
        if (index == nil) then return end
        if (listView.itemPositions[index] == nil) then return end
        if (reset == nil) then reset = false end

        local item = listView.itemPositions[index]
        listView.currentHighlightedElementIndex = item.index
        listView.shouldRefresh = true

        if (not reset) then
            sleep(.1)
            listView.highlightItem(index, true)
        else
            listView.currentHighlightedElementIndex = -1
            listView.shouldRefresh = true
        end
    end

    function listView.onclick(side, x, y)
        if (not listView.visible or not listView.visibleOnScreen) then return end
        listView.gui.scrollUp.onclick(side, x, y)
        listView.gui.scrollDown.onclick(side, x, y)
        listView.gui.scrollReset.onclick(side, x, y)

        if (not listView.clickable) then return end
        if (listView.monitor ~= nil) then
            if (peripheral.getName(listView.monitor) == side) then
                local clickedItem = listView.getClickedItem(x, y)
                if (clickedItem ~= nil) then
                    listView.onSelect({ index = clickedItem.index, text = listView.items[clickedItem.index] })
                    listView.highlightItem(clickedItem.index)
                end
            end
        end
    end

    function listView.draw(mon, from_y, to_y)
        local prevX, prevY = mon.getCursorPos()
        local monWidth, monHeight = mon.getSize()

        listView.gui.counter.setVisible(listView.showTotal)

        listView.startY = from_y
        listView.endY = to_y

        if (listView.currentHighlightedElementIndex == -1) then
            if (listView.shouldRefresh) then -- Only clear the item area
                for _y = listView.startY + listView.firstItemOffsetFromTop, listView.endY, 1 do
                    mon.setCursorPos(1, _y)
                    mon.clearLine()
                end
            elseif (listView.shouldClear) then -- Clear everything in the area the button was last time, if required
                for _y = listView.startY, listView.endY - 1, 1 do
                    mon.setCursorPos(1, _y)
                    mon.clearLine()
                end
                listView.visibleOnScreen = false
            end
        end

        if (not listView.visible) then return end

        if (listView.shouldRefresh or listView.shouldClear) then
            -- Draw the background (item area)
            for row = listView.startY + listView.firstItemOffsetFromTop, listView.endY - 1, 1 do
                for column = 2, monWidth - 1, 1 do
                    m.blit(mon, " ", column, row, colors.fromBlit(listView.bgColor), colors.fromBlit(listView.bgColor))
                end
            end

            -- Draw the background (header)
            for row = listView.startY + 1, listView.startY + 2, 1 do
                for column = 2, monWidth - 1, 1 do
                    m.blit(mon, " ", column, row, colors.fromBlit(listView.headerBg), colors.fromBlit(listView.headerBg))
                end
            end

            -- Draw the frame
            m.drawDivider(mon, listView.startY, "-")
            m.drawDivider(mon, listView.endY, "-")
            m.drawVertical(mon, 1, listView.startY + 1, listView.endY - 1, "|")
            m.drawVertical(mon, monWidth, listView.startY + 1, listView.endY - 1, "|")

            -- Draw all GUI elements
            listView.gui.header.draw(mon, 2, from_y + 1)
            listView.gui.scrollDown.draw(mon, monWidth - 1, listView.startY + 1)
            listView.gui.scrollReset.draw(mon, monWidth - 2, listView.startY + 1)
            listView.gui.scrollUp.draw(mon, monWidth - 3, listView.startY + 1)

            -- The Y coordinate of the first item
            local itemsStart = listView.startY + listView.firstItemOffsetFromTop
            local totalItemsDrawn = 0
            for i, item in pairs(listView.items) do
                -- The index gets the scrollPosition subtracted to mimic scrolling
                local index = (i - listView.scrollPosition) + 1

                -- We skip all items that are below scrollPosition (scrolled up)
                if (i < listView.scrollPosition) then
                    local data = listView.itemPositions[i]
                    if (data ~= nil) then
                        data.startX = -1
                        data.endX = -1
                        data.startY = -1
                        data.endY = -1
                        listView.itemPositions[i] = data
                    else
                        listView.itemPositions[i] = {
                            index = i,
                            startX = -1,
                            endX = -1,
                            startY = -1,
                            endY = -1
                        }
                    end
                    goto continue
                end

                -- The first item starts at itemsStart offset by all previous items (except the current one) heights.
                -- We also subtract 1 from the height to account for the text taking up one line. (this prevents for example itemHeight = 2 resulting in an actual height of 3)
                local itemStartY = itemsStart + (index - 1) * (listView.itemHeight - 1)

                -- If the height is one, set the offset to 0, since the text adds one line as the height already.
                local heightOffset = 0
                if (listView.itemHeight > 1) then
                    heightOffset = listView.itemHeight - 1
                else
                    heightOffset = 0
                end


                -- Offset each following item's startY by the combined gaps of the previous items.
                if (index > 1) then
                    for c = 1, index - 1, 1 do
                        itemStartY = itemStartY + 2
                    end
                end
                local itemEndY = itemStartY + heightOffset

                -- Stop drawing items if the endY is greater than the monitor's height (the item is out of the viewport)
                if (itemEndY > listView.endY - 1) then
                    break
                end


                -- Center the text vertically
                local textOffset = math.ceil((itemEndY - itemStartY) / 2)

                -- Save the item position info for highlighting.
                listView.itemPositions[i] = {
                    index = i,
                    startX = 2,
                    endX = monWidth - 2,
                    startY = itemStartY,
                    endY = itemEndY
                }

                if (i == listView.currentHighlightedElementIndex) then -- Highlight the item if the currentHighlightedElementIndex is set to the current item index
                    -- Draw item background
                    for _y = itemStartY, itemEndY, 1 do
                        m.blit(mon, string.rep("|", monWidth - 2), 2, _y, colors.fromBlit(listView.selectedItemBgColor),
                            colors.fromBlit(listView.selectedItemBgColor))
                    end

                    -- Draw item text
                    m.blit(mon, item, 2, itemEndY - textOffset, colors.fromBlit(listView.selectedItemColor),
                        colors.fromBlit(listView.selectedItemBgColor))
                    totalItemsDrawn = totalItemsDrawn + 1
                else -- Otherwise, draw the regular background and text.
                    -- Draw item background
                    for _y = itemStartY, itemEndY, 1 do
                        m.blit(mon, string.rep("|", monWidth - 2), 2, _y, colors.fromBlit(listView.itemBgColor),
                            colors.fromBlit(listView.itemBgColor))
                    end

                    -- Draw item text
                    m.blit(mon, item, 2, itemEndY - textOffset, colors.fromBlit(listView.itemColor),
                        colors.fromBlit(listView.itemBgColor))
                    totalItemsDrawn = totalItemsDrawn + 1
                end
                ::continue::
            end

            -- Update the counter and draw it.
            listView.gui.counter.setText("(" ..
                (listView.scrollPosition) ..
                "-" .. totalItemsDrawn + (listView.scrollPosition - 1) .. ") / " .. #listView
                .items)
            listView.gui.counter.draw(mon, listView.gui.header.getTextLength() + 3, from_y + 1)

            -- Reset refresh and clear flags, also set the visibleOnScreen flag to true.
            listView.visibleOnScreen = true
            listView.shouldRefresh = false
            listView.shouldClear = false
        end

        mon.setCursorPos(prevX, prevY)
    end

    return {
        setHeader = listView.setHeader,
        setHeaderTextColor = listView.setHeaderTextColor,
        setItemColor = listView.setItemColor,
        setItemBgColor = listView.setItemBgColor,
        setSelectedItemColor = listView.setSelectedItemColor,
        setSelectedItemBackground = listView.setSelectedItemBackground,
        setBackground = listView.setBackground,
        setOnSelect = listView.setOnSelect,
        setClickable = listView.setClickable,
        setShowTotal = listView.setShowTotal,
        setHeaderBackground = listView.setHeaderBackground,
        getHeader = listView.getHeader,
        getHeaderTextColor = listView.getHeaderTextColor,
        getItemColor = listView.getItemColor,
        getItemBgColor = listView.getItemBgColor,
        getSelectedItemColor = listView.getSelectedItemColor,
        getSelectedItemBackground = listView.getSelectedItemBackground,
        getBackground = listView.getBackground,
        getHeaderBackground = listView.getHeaderBackground,
        getClickable = listView.getClickable,
        getShowTotal = listView.getShowTotal,
        addItem = listView.addItem,
        removeItem = listView.removeItem,
        getItemIndex = listView.getItemIndex,
        clear = listView.clear,
        onclick = listView.onclick,
        draw = listView.draw,
        connect = listView.connect
    }
end

return guilib
