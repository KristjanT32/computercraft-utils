--- @diagnostic disable

local persistence = {}


--- @param data table the data to save
---@param name string the name of the file to write to
function persistence.save_data(data, namespace, name)
    if not fs.exists(string.format('/%s/data', namespace)) then
        fs.makeDir(string.format('/%s/data', namespace))
    end
    local f = fs.open(string.format('/%s/data/%s', namespace, name), 'w')
    f.write(textutils.serialize(data))
    f.close()
end

---@param name string the name of the file to load
function persistence.load_data(namespace, name)
    if fs.exists(string.format('/%s/data/%s', namespace, name)) then
        local f = fs.open(string.format('/%s/data/%s', namespace, name), 'r')
        data = textutils.unserialize(f.readAll())
        f.close()
    end
    return data
end

return persistence
