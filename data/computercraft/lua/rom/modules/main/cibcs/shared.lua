--- @diagnostic disable
local utils = require("utils")
local shared = {
    top_divider_pos = 1,
    bottom_divider_pos = 1,
    protocols = {
        init = "cibcs/init",
        ident = "cibcs/ident",
        dsp = "cibcs/dsp",
        lifeline = "cibcs/lifeline"
    }
}

local commands = {
    ident_broadcast = {
        str = "IDENT?",
        channel = shared.protocols.init,
        details = "Host discovery request"
    },
    ident_request = {
        str = "IDENT!",
        channel = shared.protocols.ident,
        details = "Client identification request"
    },
    ident_accept = {
        str = "WLCM!",
        channel = shared.protocols.ident,
        details = "Connection accepted."
    },
    ident_ignore = {
        str = "FINE!",
        channel = shared.protocols.ident,
        details = "Connection already authenticated."
    },
    ident_reject = {
        str = "PSSFF!",
        channel = shared.protocols.ident,
        details = "Connection rejected: invalid token"
    },
    display_set = {
        str = "SET!",
        channel = shared.protocols.dsp,
        details = "Clear & set board content"
    },
    display_update = {
        str = "UPDATE!",
        channel = shared.protocols.dsp,
        details = "Update board content"
    },
    display_clear = {
        str = "CLEAR!",
        channel = shared.protocols.dsp,
        details = "Clear board content"
    },
    assure_alive = {
        str = "ALIVE!",
        channel = shared.protocols.lifeline,
        details = "Host is alive"
    }
}


function shared.show_init_message(mon, line, title, message, clear)
    if (clear == nil) then clear = false end
    local w, h = mon.getSize()

    if (clear) then
        mon.clear()
    end

    if (h / 2 - 3 ~= shared.top_divider_pos) then
        utils.monitor.clearLine(mon, shared.top_divider_pos)
    end
    utils.monitor.drawDivider(mon, h / 2 - 3, "-")
    shared.top_divider_pos = h / 2 - 3

    if (h / 2 + (line + 3) ~= shared.bottom_divider_pos) then
        utils.monitor.clearLine(mon, shared.bottom_divider_pos)
    end
    utils.monitor.drawDivider(mon, h / 2 + (line + 3), "-")
    shared.bottom_divider_pos = h / 2 + (line + 3)

    utils.monitor.clearLine(mon, h / 2 - 1)
    utils.monitor.blitCenter(
        mon,
        h / 2 - 1,
        title,
        colors.white, colors.blue
    )

    utils.monitor.clearLine(mon, h / 2 + (line + 1))
    utils.monitor.blitCenter(
        mon,
        h / 2 + (line + 1),
        message,
        colors.white, colors.gray
    )
end

function shared.show_init_error(mon, line, title, message, clear)
    if (clear == nil) then clear = false end
    local w, h = mon.getSize()

    if (clear) then
        mon.clear()
    end

    if (h / 2 - 3 ~= shared.top_divider_pos) then
        utils.monitor.clearLine(mon, shared.top_divider_pos)
    end
    utils.monitor.drawDivider(mon, h / 2 - 3, "-")
    shared.top_divider_pos = h / 2 - 3

    if (h / 2 + (line + 3) ~= shared.bottom_divider_pos) then
        utils.monitor.clearLine(mon, shared.bottom_divider_pos)
    end
    utils.monitor.drawDivider(mon, h / 2 + (line + 3), "-")
    shared.bottom_divider_pos = h / 2 + (line + 3)

    utils.monitor.clearLine(mon, h / 2 - 1)
    utils.monitor.blitCenter(
        mon,
        h / 2 - 1,
        title,
        colors.white, colors.red
    )

    utils.monitor.clearLine(mon, h / 2 + (line + 1))
    utils.monitor.blitCenter(
        mon,
        h / 2 + (line + 1),
        message,
        colors.white, colors.gray
    )
end

function shared.show_init_success(mon, line, title, message, clear)
    if (clear == nil) then clear = false end
    local w, h = mon.getSize()

    if (clear) then
        mon.clear()
    end

    if (h / 2 - 3 ~= shared.top_divider_pos) then
        utils.monitor.clearLine(mon, shared.top_divider_pos)
    end
    utils.monitor.drawDivider(mon, h / 2 - 3, "-")
    shared.top_divider_pos = h / 2 - 3

    if (h / 2 + (line + 3) ~= shared.bottom_divider_pos) then
        utils.monitor.clearLine(mon, shared.bottom_divider_pos)
    end
    utils.monitor.drawDivider(mon, h / 2 + (line + 3), "-")
    shared.bottom_divider_pos = h / 2 + (line + 3)

    utils.monitor.clearLine(mon, h / 2 - 1)
    utils.monitor.blitCenter(
        mon,
        h / 2 - 1,
        title,
        colors.white, colors.lime
    )

    utils.monitor.clearLine(mon, h / 2 + (line + 1))
    utils.monitor.blitCenter(
        mon,
        h / 2 + (line + 1),
        message,
        colors.white, colors.gray
    )
end

function shared.send_cibcs_host_command(host, command, recipient)
    local payload = {
        command = command.str,
        origin = host.name,
        details = command.details
    }

    rednet.send(recipient, payload, command.channel)
end

--- Sends an identification request to the client's host.
--- @param client table The client table
--- @return boolean success Whether the request was sent successfully.
function shared.send_client_ident(client)
    return rednet.send(
        client.host_id,
        {
            command = commands.ident_request.str,
            connection_token = client.token,
            identifier = client.id,
            target = client.host_id,
            details = commands
                .ident_request.details
        },
        commands.ident_request.channel
    )
end

--- Waits for an `IDENT?` command from `hostname`.
--- @param hostname host the host whose response to await
--- @param timeout number The amount of seconds to wait for the response.
--- @return response `nil` if none received, or the response if the host responded
function shared.await_host_ident(hostname, timeout)
    local board, response = rednet.receive(shared.protocols.init, timeout)
    if (response == nil) then return nil end
    if (response.origin == hostname and response.command == commands.ident_broadcast.str) then
        response.id = board
        return response
    end
    return nil
end

--- Waits for an `IDENT!` command from clients.
--- @param host table The receiving host table
--- @param timeout number The amount of seconds to wait for the response.
--- @return response `nil` if none received, or the response if the host responded
function shared.await_client_ident(host, timeout)
    local board, response = rednet.receive(shared.protocols.ident, timeout)
    if (response == nil) then return nil end
    if (response.command == commands.ident_request.str and response.target == host.id) then
        return response
    end
    return nil
end

return {
    show_init_error = shared.show_init_error,
    show_init_message = shared.show_init_message,
    show_init_success = shared.show_init_success,
    send_cibcs_host_command = shared.send_cibcs_host_command,
    send_client_ident = shared.send_client_ident,
    await_host_ident = shared.await_host_ident,
    await_client_ident = shared.await_client_ident,
    protocols = shared.protocols
}
