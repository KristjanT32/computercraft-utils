--- @diagnostic disable

-- A useful GUI library to make working with monitor GUIs easier.
local guilib = {}

function guilib.createButton(text, color, bgcolor, clickedColor)
    local button = {}
    button.text = text

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
        button.text = _text
        button.prevLength = button.length
        button.length = string.len(button.text)
    end

    function button.setColor(_color)
        button.textColor = colors.toBlit(_color)
    end

    function button.setClickedColor(_color)
        button.clickedColor = colors.toBlit(_color)
    end

    function button.setBackground(_bg)
        button.bgColor = colors.toBlit(_bg)
    end

    function button.setAction(func)
        button.onAction = func
    end

    function button.onclick(side, x, y)
        if (not button.visible) then return end
        if (button.monitor ~= nil) then
            if (peripheral.getName(button.monitor) == side) then
                if (x >= button.posX and x <= (button.length + button.posX) and y == button.posY) then
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

        -- Clear everything in the area the button was last time
        if (button.prevX ~= nil) then
            for _x = button.prevX, button.prevLength + button.prevX, 1 do
                mon.setCursorPos(_x, y)
                mon.blit("|", colors.toBlit(mon.getBackgroundColor()), colors.toBlit(mon.getBackgroundColor()))
            end
        end
        button.visibleOnScreen = false

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


    function label.setColor(color)
        label.textColor = colors.toBlit(color)
    end

    function label.setBackgroundColor(color)
        label.bgColor = colors.toBlit(color)
    end

    function label.setText(text)
        label.text = text
        label.prevLength = label.length
        label.length = string.len(text)
    end

    function label.setVisible(visible)
        label.visible = visible
    end

    function label.draw(mon, x, y)
        local prevX, prevY = mon.getCursorPos()

        -- Clear everything in the area the label was last time
        if (label.prevX ~= nil) then
            for _x = label.prevX, label.prevLength + label.prevX, 1 do
                mon.setCursorPos(_x, y)
                mon.blit("|", colors.toBlit(mon.getBackgroundColor()), colors.toBlit(mon.getBackgroundColor()))
            end
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
        mon.clearLine()

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
        if (value >= progressbar.max) then
            progressbar.value = progressbar.max
        elseif (value <= 0) then
            progressbar.value = 0
        else
            progressbar.value = value
        end

        progressbar.percentage = progressbar.value / progressbar.max
    end

    function progressbar.onclick()
        progressbar.onClick()
    end

    function progressbar.setAction(func)
        progressbar.onclick = func
    end

    function progressbar.setMax(max)
        progressbar.max = max
    end

    function progressbar.setColor(color)
        progressbar.fillColor = colors.toBlit(color)
    end

    function progressbar.setBackground(color)
        progressbar.bgColor = colors.toBlit(color)
    end

    function progressbar.setVisible(visible)
        progressbar.visible = visible
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
        for _x = from_x, 1, to_x + 1 do
            mon.setCursorPos(_x, y)
            mon.write("")
        end

        mon.setCursorPos(from_x, y)

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
        if (value >= progressbar.max) then
            progressbar.value = progressbar.max
        elseif (value <= 0) then
            progressbar.value = 0
        else
            progressbar.value = value
        end

        progressbar.percentage = progressbar.value / progressbar.max
    end

    function progressbar.setMax(max)
        progressbar.max = max
    end

    function progressbar.setColor(color)
        progressbar.fillColor = colors.toBlit(color)
    end

    function progressbar.setBackground(color)
        progressbar.bgColor = colors.toBlit(color)
    end

    function progressbar.setVisible(visible)
        progressbar.visible = visible
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

return guilib
