--- @diagnostic disable

require("utils.helpers")

local logging = {}

function logging.log(module, type, msg)
    local terminal = term.current()
    local prevColor = terminal.getTextColor()

    if (string.lower(type) == "info") then
        terminal.setTextColor(colors.green)
    elseif (string.lower(type) == "error") then
        terminal.setTextColor(colors.red)
    elseif (string.lower(type) == "warning") then
        terminal.setTextColor(colors.yellow)
    else
        terminal.setTextColor(colors.gray)
    end

    if (string.lower(type) == "fatal") then
        local w, h = terminal.getSize()

        terminal.setTextColor(colors.white)
        print(string.rep("=", w))

        terminal.setTextColor(colors.red)
        print("[" .. module .. " " .. type .. "]: " .. msg)

        terminal.setTextColor(colors.white)
        print(string.rep("=", w))
    else
        print("[" .. module .. " " .. type .. "]: " .. msg)
    end
    terminal.setTextColor(prevColor)
end

function logging.info(msg, module)
    logging.log(module, "INFO", msg)
end

function logging.error(msg, module)
    logging.log(module, "ERROR", msg)
end

function logging.warning(msg, module)
    logging.log(module, "WARNING", msg)
end

function logging.fatal(msg, module)
    logging.log(module, "FATAL", msg)
end

return {
    info = logging.info,
    error = logging.error,
    warning = logging.warning,
    fatal = logging.fatal,
    log = logging.log
}
