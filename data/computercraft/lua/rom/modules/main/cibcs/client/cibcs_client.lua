--- @diagnostic disable
local shared = require("cibcs.shared")
local utils = require("utils")
local _client = {}

function _client.create_client(hostname, token, monitor_side, modem_side)
    local client = {}

    client.id = os.getComputerID()

    client.host_name = hostname
    client.host_id = -1
    client.token = token

    client.monitor = peripheral.wrap(monitor_side)
    client.mon_w, client.mon_h = client.monitor.getSize()
    client.modem_side = modem_side

    -- This is true when the client has not received an "ALIVE!" command in response to
    -- an "ALIVE?" request.
    client.dead = false



    --- Initializes authorization with the host
    --- @return boolean success whether the authorization succeeded.
    client.init = function()
        if (peripheral.wrap(monitor_side) == nil) then
            utils.logging.fatal("Failed to find a monitor on side: " .. monitor_side, "System")
            return
        end

        if (peripheral.wrap(modem_side) == nil) then
            utils.logging.fatal("Failed to find a modem on side: " .. modem_side, "System")
            return
        end

        rednet.open(client.modem_side)

        client.monitor.clear()
        shared.show_init_message(client.monitor, 1, "Initializing board", "> Waiting for hosts")

        local id, content = rednet.receive(shared.protocols.init, 30)
        if (content == nil) then
            client.monitor.clear()
            shared.show_init_error(client.monitor, 1, "Initialization failed", "> No hosts are available")
            while true do
                local event, side, x, y = os.pullEvent("monitor_touch")
                os.reboot()
                sleep(.05)
            end
            return false
        end

        os.setComputerLabel("CIBCS Information Board #" .. os.getComputerID())

        while true do
            ::await_ident::
            local response = shared.await_host_ident(client.host_name, 5)
            if (response ~= nil) then
                if (response.origin == client.host_name) then
                    utils.logging.info(" Host found: " .. response.origin, "System")
                    shared.show_init_message(client.monitor, 1, "Initializing board", "> Host found, authenticating")
                    client.host_id = response.id
                else
                    utils.logging.info(" Looking for host...", "System")
                    goto await_ident
                end

                while true do
                    ::ident::
                    shared.send_client_ident(client)
                    local id, content = rednet.receive(shared.protocols.ident, 2)
                    if (content == nil) then
                        utils.logging.warning("Retrying authentication", "System")
                        goto ident
                    else
                        print(content.command .. " from " .. content.origin)
                    end
                    if (id == client.host_id and content.origin == client.host_name) then
                        if (content.command == "WLCM!" or content.command == "FINE!") then
                            shared.show_init_success(client.monitor, 1, "Board initialized", "> Waiting for host",
                                true)
                            return true
                        elseif (content.command == "PSSFF!") then
                            print("Couldn't authorize: " .. content.details .. " (" .. content.command .. ")")
                            shared.show_init_error(client.monitor, 1, "Initialization failed",
                                "Connection failed (" .. content.command .. ")")
                            shared.show_init_error(client.monitor, 2, "Initialization failed",
                                "< " .. content.details .. " >")
                            while true do
                                local event, side, x, y = os.pullEvent("monitor_touch")
                                os.reboot()
                                sleep(.05)
                            end
                            return false
                        end
                    end
                end
            else
                goto await_ident
            end
            sleep(.5)
        end
    end

    client.check_alive = function()
        while true do
            utils.logging.info(" Checking host status", "System")
            local id, response = rednet.receive(shared.protocols.lifeline, 10)

            if (response == nil) then
                client.dead = true
                utils.logging.error(" [!] Host unreachable", "System")
            else
                if (response.origin == client.host_name) then
                    if (response.command == "ALIVE!") then
                        client.dead = false
                        utils.logging.info(" [OK] Host reachable", "System")
                        sleep(10)
                    end
                end
            end
            sleep(5)
        end
    end

    client.set_board_content = function(content, clear)
        if clear then client.monitor.clear() end
        for line, lineContent in pairs(content) do
            if (lineContent.color == nil) then lineContent.color = colors.white end
            if (lineContent.bg == nil) then lineContent.bg = client.monitor.getBackgroundColor() end
            utils.monitor.blitCenter(client.monitor, line, lineContent.content, lineContent.color, lineContent.bg)
        end
    end

    --- [internal] Refreshes the board by listening to the host
    client.refresh = function()
        while true do
            if (not client.dead) then
                local id, content = rednet.receive(shared.protocols.dsp, 1)
                if (content ~= nil) then
                    if (content.origin == client.host_name) then
                        if (content.command == "UPDATE!") then
                            client.set_board_content(content.text, false)
                        elseif (content.command == "SET!") then
                            client.set_board_content(content.text, true)
                        elseif (content.command == "CLEAR!") then
                            client.monitor.clear()
                        end
                    end
                end
                sleep(.05)
            else
                client.monitor.clear()
                shared.show_init_message(client.monitor, 1, "No signal", "Timed out! No signal detected from host.", true)
                sleep(1)
                client.monitor.clear()
                sleep(.5)
            end
        end
    end

    --- Starts the lifecycle for the board.
    client.run = function()
        parallel.waitForAll(client.refresh, client.check_alive)
    end

    return {
        init = client.init,
        run = client.run,
        id = client.id,
        host = {
            id = client.host_id,
            name = client.host_name
        },
        is_dead = client.dead,
        monitor = client.monitor
    }
end

return _client
