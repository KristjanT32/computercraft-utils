--- @diagnostic disable

function len(str)
    if str == nil then return 0 end
    return string.len(str)
end

-- Returns the size of a given table.
--- @param table table The table to inspect.
--- @return integer size The size of the table.
function sizeof(table)
    if (table == nil) then return 0 end
    local size = 0
    for _, _ in pairs(table) do
        size = size + 1
    end
    return size
end

--- Returns `true` if the provided value is in `table`. Returns false otherwise.
--- @param table table The table to inspect
--- @param value any The value to check for.
---@return boolean found Whether the value is within `table`
local function containsValue(table, value)
    for k, v in pairs(table) do
        if (v == value) then
            return true
        end
    end
    return false
end

--- Returns `true` if the provided key is in `table`. Returns false otherwise.
--- @param table table The table to inspect
--- @param value any The key to check for.
---@return boolean found Whether the key is within `table`
local function containsKey(table, key)
    for k, v in pairs(table) do
        if (k == key) then
            return true
        end
    end
    return false
end

function table.size(table)
    return sizeof(table)
end

function table.hasValue(table, value)
    return containsValue(table, value)
end

function table.hasKey(table, key)
    return containsKey(table, key)
end

function table.removeValue(table, value)
    for key, val in pairs(table) do
        if (val == value) then
            table[key] = nil
        end
    end
    return table
end

--- Wraps the supplied piece of text to the specified width.
---@param text string The text to wrap.
---@param width integer The width to wrap the text to.
---@return string wrapped The wrapped text.
function string.wrapText(text, width)
    local wrapped = ""
    local line = ""
    for word in text:gmatch("%S+") do
        if #line + #word + 1 > width then
            wrapped = wrapped .. line .. "\n"
            line = word
        else
            if #line > 0 then
                line = line .. " " .. word
            else
                line = word
            end
        end
    end
    wrapped = wrapped .. line
    return wrapped
end

table.containsKey = table.hasKey
table.containsValue = table.hasValue
