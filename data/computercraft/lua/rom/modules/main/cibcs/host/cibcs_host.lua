--- @diagnostic disable
local shared = require("cibcs.shared")
local utils = require("utils")
local _host = {}

local function load_host_data(host)
    return utils.persistence.load_data("cibcs", "hostdata/host" .. host.id) or {
        authenticated_boards = {},
        connection_token = "",
        settings = {
            show_service_text_on_paused = true
        }
    }
end

local function clear_terminal()
    term.clear()
    term.setCursorPos(1, 1)
end


function _host.create_host(monitor_side, modem_side, name)
    local host = {}

    host.id = os.getComputerID()
    host.name = name or "cibcs_host_" .. os.getComputerID()
    host.data = load_host_data(host)

    host.monitor = peripheral.wrap(monitor_side)
    host.mon_w, host.mon_h = host.monitor.getSize()
    host.term_w, host.term_h = term.getSize()

    host.modem_side = modem_side
    host.ping_start = 0

    host.gui = {
        clientlist = {},
        actions = {},
        main = {}
    }

    host.gui.actions.reping_button = utils.gui.createButton("Re-ping", colors.white, colors.blue, colors.lightBlue)
    host.gui.actions.reping_button.setAction(function()
        host.is_serviced = false
        term.clear()
        host.monitor.clear()
        host.is_repinging = true
        host.ping_start = os.clock()
        host.board_discovery()
    end)

    host.gui.actions.exit_button = utils.gui.createButton("X", colors.white, colors.red, colors.pink)
    host.gui.actions.exit_button.setAction(function()
        host.is_serviced = false
        host.monitor.clear()
    end)


    host.gui.clientlist.next_button = utils.gui.createButton(">>", colors.white, colors.lightGray, colors.gray)
    host.gui.clientlist.prev_button = utils.gui.createButton("<<", colors.white, colors.lightGray, colors.gray)
    host.gui.clientlist.exit_button = utils.gui.createButton("X", colors.white, colors.red, colors.pink)
    host.gui.clientlist.paginator = {}
    host.gui.clientlist.page = 1

    host.gui.clientlist.next_button.setAction(function()
        if (host.gui.clientlist.page < sizeof(host.gui.clientlist.paginator)) then
            host.gui.clientlist.page = host.gui.clientlist.page + 1
        end
    end)

    host.gui.clientlist.prev_button.setAction(function()
        if (host.gui.clientlist.page > 1) then
            host.gui.clientlist.page = host.gui.clientlist.page - 1
        end
    end)

    host.gui.clientlist.exit_button.setAction(function()
        host.is_listing = false
        host.monitor.clear()
    end)

    host.gui.main.view_client_button = utils.gui.createButton("View clients", colors.white, colors.gray, colors
        .lightBlue)
    host.gui.main.view_client_button.setAction(function()
        host.is_listing = true
        host.monitor.clear()
    end)

    host.gui.main.service_button = utils.gui.createButton("Options", colors.white, colors.gray, colors.lightBlue)
    host.gui.main.service_button.setAction(function()
        host.is_serviced = true
        host.monitor.clear()
    end)


    host.gui.clientlist.next_button.connect(host.monitor)
    host.gui.clientlist.prev_button.connect(host.monitor)
    host.gui.clientlist.exit_button.connect(host.monitor)

    host.gui.main.view_client_button.connect(host.monitor)
    host.gui.main.service_button.connect(host.monitor)

    host.gui.actions.reping_button.connect(host.monitor)
    host.gui.actions.exit_button.connect(host.monitor)

    host.init_pb = utils.gui.createLimitedProgressbar(0, 100, colors.blue, colors.lightGray)


    -- Is the host currently looking for boards?
    host.is_pinging = false

    -- Is the host currently rediscovering boards?
    host.is_repinging = false

    -- Is the client list currently shown?
    host.is_listing = false

    -- Is the service menu currently shown?
    host.is_serviced = false

    -- Is the host broadcast paused?
    host.is_paused = false

    -- The text object used to display service info on the board.
    host.serviceText = {}

    -- The text object that represents the currently displayed text on the boards.
    host.data.currentText = {
        
    }

    utils.persistence.save_data(host.data, "cibcs", "hostdata/host" .. host.id)

    host.authenticate_sender = function(senderId)
        if (table.containsValue(host.data.authenticated_boards, senderId)) then return end
        host.data.authenticated_boards[senderId] = senderId
        utils.persistence.save_data(host.data, "cibcs", "hostdata/host" .. host.id)
    end

    host.forget_sender = function(senderId)
        if (not table.containsValue(host.data.authenticated_boards, senderId)) then
            return
        end

        table.removeValue(host.data.authenticated_boards, senderId)
        utils.persistence.save_data(host.data, "cibcs", "hostdata/host" .. host.id)
    end

    host.is_sender_authenticated = function(senderId)
        return host.data.authenticated_boards[senderId] ~= nil
    end

    host.show_console = function()
        term.clear()
        host.show_terminal_text("=[CIBCS]===========================================", 1)
        host.show_terminal_text("===================================================", host.term_h)
        term.setCursorPos(1, 2)

        while true do
            local x, y = term.getCursorPos()
            write("cibcs-control> ")
            local args = {}
            local cmd = read()
            for word in cmd:gmatch("%S+") do
                table.insert(args, word)
            end

            if (y == host.term_h - 1) then
                term.clear()
                host.show_terminal_text("=[CIBCS]===========================================", 1)
                host.show_terminal_text("===================================================", host.term_h)
                term.setCursorPos(1, 2)
            end

            if (args[1] == "auth") then
                print("There are currently " .. sizeof(host.data.authenticated_boards) .. " authenticated boards.")
            elseif (args[1] == "lsauth") then
                for _, board in pairs(host.data.authenticated_boards) do
                    print("- Board #" .. board)
                end
            elseif (args[1] == "deauth") then
                if (sizeof(args) >= 2) then
                    host.forget_sender(tonumber(args[2]))
                    print("Deauthenticated: Board #" .. args[2])
                else
                    printError("Missing parameter: <boardId>")
                end
            elseif (args[1] == "start") then
                host.is_paused = false
                term.clear()
                host.run()
            elseif (args[1] == "dsp") then
                if (sizeof(args) < 3) then
                    printError("Missing parameters: <client> <content>")
                else
                    local client = tonumber(args[2])
                    local content = ""
                    for i = 3, sizeof(args) do
                        content = content .. args[i] .. " "
                    end
                    getContent, error = load("return " .. content)
                    content = getContent()

                    if (client == nil) then
                        printError("Invalid client ID: " .. args[2])
                    else
                        if (not host.is_sender_authenticated(client)) then
                            printError("Cannot send display instructions to non-authenticated board #" .. client)
                        else
                            if (content ~= nil and sizeof(content) > 0) then
                                print("Display instruction sent")
                                rednet.send(client, { command = "UPDATE!", origin = host.name, text = content },
                                    shared.protocols.dsp)
                            else
                                print("Clear instruction sent")
                                rednet.send(client, { command = "CLEAR!", origin = host.name }, shared.protocols.dsp)
                            end
                        end
                    end
                end
            elseif (args[1] == "help") then
                print("Commands\nauth - show the amount of authenticated boards"
                    .. "\nlsauth - show the authenticated boards"
                    .. "\ndeauth <boardId> - deauthenticate a board"
                    ..
                    "\ndsp <client> <content> - send <content> to <client>\nstart - resumes CIBCS broadcast"
                )
            end
            sleep(.01)
        end
    end

    host.show_monitor_text = function(text, line)
        if (host.monitor == nil) then return end
        host.monitor.setCursorPos(1, line)
        host.monitor.clearLine()
        host.monitor.write(text)
    end

    host.show_terminal_text = function(text, line)
        if (line == nil) then line = 1 end
        term.setCursorPos(1, line)
        term.clearLine()
        term.write(text .. "\n")
    end

    host.refresh_boards = function(update)
        if (update == nil) then update = false end

        while not host.is_paused do
            for _, board in pairs(host.data.authenticated_boards) do
                if (update) then
                    rednet.send(board, { command = "UPDATE!", origin = host.name, text = host.data.currentText },
                        shared.protocols.dsp)
                else
                    rednet.send(board, { command = "SET!", origin = host.name, text = host.data.currentText },
                        shared.protocols.dsp)
                end
            end
            sleep(.05)
        end

        if (host.is_paused) then
            if (host.data.settings.show_service_text_on_paused) then
                for _, board in pairs(host.data.authenticated_boards) do
                    rednet.send(board, { command = "SET!", text = host.serviceText }, shared.protocols.dsp)
                end
            end
        end
    end

    host.clear_boards = function()
        for _, board in pairs(host.data.authenticated_boards) do
            rednet.send(board, { command = "CLEAR!", text = host.data.currentText }, shared.protocols.dsp)
            utils.monitor.clearLine(host.monitor, host.mon_h - 1)
            utils.monitor.blitCenter(host.monitor, host.mon_h - 1, "Cleared: #" .. board, colors.white, colors.blue)
        end
    end

    host.refresh_info = function()
        while not host.is_paused do
            if (host.is_listing) then
                utils.monitor.blitCenter(host.monitor, 2,
                    "Connected clients (" ..
                    host.gui.clientlist.page .. " / " .. tostring(sizeof(host.gui.clientlist.paginator) or 1) .. ")",
                    colors.white,
                    colors
                    .gray)

                if (host.gui.clientlist.paginator[host.gui.clientlist.page] ~= nil) then
                    for index, entry in pairs(host.gui.clientlist.paginator[host.gui.clientlist.page]) do
                        utils.monitor.writeCenter(host.monitor, index + 3, "- Board #" .. entry)
                    end
                else
                    utils.monitor.writeCenter(host.monitor, 4, "(No clients connected)")
                end

                host.gui.clientlist.exit_button.draw(host.monitor, host.mon_w, 1)

                if (host.gui.clientlist.page < sizeof(host.gui.clientlist.paginator)) then
                    host.gui.clientlist.next_button.draw(host.monitor,
                        host.mon_w - host.gui.clientlist.next_button.getTextLength() - 6, host.mon_h - 1)
                end

                if (host.gui.clientlist.page > 1) then
                    host.gui.clientlist.prev_button.draw(host.monitor, 6, host.mon_h - 1)
                end
            elseif (host.is_serviced) then
                utils.monitor.blitCenter(host.monitor, 2, "Service actions", colors.white, colors.gray)
                host.gui.actions.reping_button.draw(host.monitor,
                    utils.monitor.getCenterXByMonitor(host.monitor, host.gui.actions.reping_button.getText()), 4)
                host.gui.actions.exit_button.draw(host.monitor, host.mon_w, 1)
            elseif (not host.is_pinging) then
                utils.monitor.blitCenter(host.monitor, 2, "CIBCS HOST ONLINE", colors.white, colors
                    .blue)
                utils.monitor.blitCenter(host.monitor, 3, "Hostname: " .. host.name, colors.white, colors
                    .black)
                utils.monitor.blitCenter(host.monitor, 5, "Connected boards", colors.white, colors.lime)
                utils.monitor.blitCenter(host.monitor, 7, "< " .. sizeof(host.data.authenticated_boards) .. " >", colors
                    .lime, colors
                    .black)

                host.gui.main.view_client_button.draw(
                    host.monitor,
                    utils.monitor.getCenterXByMonitor(host.monitor, host.gui.main.view_client_button.getText()),
                    host.mon_h - 3)
                host.gui.main.service_button.draw(
                    host.monitor,
                    utils.monitor.getCenterXByMonitor(host.monitor, host.gui.main.service_button.getText()),
                    host.mon_h - 2)

                host.show_terminal_text("===================================================", 1)
                host.show_terminal_text("CIBCS HOST BROADCAST ACTIVE", 2)
                host.show_terminal_text("===================================================", 3)
                host.show_terminal_text("HOST SYSTEM INFORMATION", 5)
                host.show_terminal_text("- Physical ID: " .. host.id, 6)
                host.show_terminal_text("- CIBCS network ID: " .. host.name, 7)
                host.show_terminal_text("- Connected boards: " .. sizeof(host.data.authenticated_boards), 8)
                host.show_terminal_text("===================================================", host.term_h)
                host.show_terminal_text("> Press F1 to pause the broadcast", host.term_h - 1)
            end
            if (not host.is_pinging) then
                sleep(.1)
                host.monitor.clear()
            else
                sleep(.5)
            end
        end
    end

    host.check_input = function()
        while true do
            local event, key = os.pullEvent("key_up")
            if (key == keys.f1) then
                clear_terminal()
                host.show_terminal_text("BROADCAST PAUSED!", 1)
                host.serviceText = {
                    [2] = { content = "BOARD PAUSED", color = colors.white, bg = colors.red },
                    [3] = { content = "Host broadcast interrupted", color = colors.white, bg = colors.black }
                }
                host.is_paused = true

                sleep(1)

                clear_terminal()
                host.show_console()
            end
            sleep(.05)
        end
    end

    host.check_monitor_input = function()
        while true do
            local event, side, x, y = os.pullEvent("monitor_touch")
            if (host.is_listing) then
                host.gui.clientlist.next_button.onclick(side, x, y)
                host.gui.clientlist.prev_button.onclick(side, x, y)
                host.gui.clientlist.exit_button.onclick(side, x, y)
            elseif (host.is_serviced) then
                host.gui.actions.reping_button.onclick(side, x, y)
                host.gui.actions.exit_button.onclick(side, x, y)
            else
                host.gui.main.view_client_button.onclick(side, x, y)
                host.gui.main.service_button.onclick(side, x, y)
            end
        end
    end

    host.send_alive = function()
        while true do
            for _, board in pairs(host.data.authenticated_boards) do
                rednet.send(board, { command = "ALIVE!", origin = host.name }, shared.protocols.lifeline)
            end
            sleep(.5)
        end
    end

    -- Runs the lifecycle functions for the host
    -- Note: if you wish to use the host computer as well as run
    -- the CIBCS host program, use `parallel.waitForAny()`.
    host.run = function()
        parallel.waitForAll(host.refresh_boards, host.refresh_info, host.check_input, host.send_alive,
            host.check_monitor_input)
    end

    host.send_ident = function()
        while host.is_pinging do
            rednet.broadcast(
                { command = "IDENT?", origin = host.name, details = "Board discovery in progress" },
                shared.protocols.init
            )
            sleep(1)
        end
    end

    host.receive_ident = function()
        while host.is_pinging do
            ::start::
            local response = shared.await_client_ident(host, 20)
            if (response == nil) then
                if (os.clock() >= host.ping_start + 10) then
                    host.is_pinging = false
                    host.monitor.clear()
                    term.clear()
                    return
                else
                    goto start
                end
            end
            utils.monitor.writeCenter(host.monitor, 10, "auth success for: " .. tostring(response.identifier))
            -- If the sent connection token matches the configured one, accept connection
            if (response.connection_token == host.data.connection_token) then
                rednet.send(
                    response.identifier,
                    { command = "WLCM!", origin = host.name, details = "Authentication successful." },
                    shared.protocols.ident
                )
                host.authenticate_sender(response.identifier)
                print("- Authentication succeeded for board #" .. response.identifier)
            else
                rednet.send(
                    response.identifier,
                    { command = "PSSFF!", origin = host.name, details = "Authentication failed - invalid token." },
                    shared.protocols.ident
                )
                printError("- Authentication rejected for board #" .. response.identifier)
            end

            --[[
            if (host.is_sender_authenticated(board)) then
                rednet.send(
                    board,
                    {
                        command = "FINE!",
                        origin = host.name,
                        details =
                        "This connection has already been authenticated."
                    },
                    shared.protocols.init
                )
                print("- Discovered authenticated board #" .. board)
            end
            ]] --
        end
    end

    host.tick_pinging = function()
        term.clear()
        local initialKnownBoards = sizeof(host.data.authenticated_boards)
        while host.is_pinging do
            host.show_terminal_text("=======================================================", 1)
            host.show_terminal_text("=======================================================", 3)
            host.show_terminal_text("=======================================================", host.term_h)
            host.show_terminal_text(
                "Pinging boards... [" .. math.ceil(os.clock() / (host.ping_start + 10) * 100) .. "%]", 2)
            utils.monitor.clearLine(host.monitor, 5)

            if (host.is_repinging) then
                utils.monitor.blitCenter(host.monitor, 4, "Rediscovering boards...", colors.white, colors.purple)
            else
                utils.monitor.blitCenter(host.monitor, 4, "Starting up...", colors.white, colors.blue)
            end

            utils.monitor.writeCenter(host.monitor, 5,
                "Board discovery running...")
            term.setCursorPos(1, 4)
            host.init_pb.update(os.clock() / (host.ping_start + 10) * 100)
            host.init_pb.draw(host.monitor, 2, host.mon_w, 7)
            utils.monitor.writeCenter(host.monitor, 9,
                "Boards found: " ..
                tostring(sizeof(host.data.authenticated_boards)) ..
                " (" .. sizeof(host.data.authenticated_boards) - initialKnownBoards .. " new)")
            sleep(.1)
            if (os.clock() >= (host.ping_start + 10)) then
                host.is_pinging = false
                host.is_repinging = false
                host.monitor.clear()
                term.clear()
                return
            end
        end

        term.clear()
        term.setCursorPos(1, 1)
        host.show_terminal_text("=======================================================", 1)
        host.show_terminal_text("Ping concluded!", 2)
        host.show_terminal_text("=======================================================", 3)
        host.show_terminal_text(
            "New boards found: " ..
            sizeof(host.data.authenticated_boards) - initialKnownBoards ..
            " (total: " .. sizeof(host.data.authenticated_boards) .. ")", host.mon_h - 1)
        host.show_terminal_text("=======================================================", host.mon_h)
        host.monitor.clear()
    end

    --- Sets the content to be displayed on connected boards.
    ---@param content content a table of `[lineNumber] = { content: string, color: color, bg: color}` pairs
    host.update_text = function(content)
        host.data.currentText = content
        utils.persistence.save_data(host.data, "cibcs", "hostdata/host" .. host.id)
    end

    host.board_discovery = function()
        host.is_pinging = true
        host.ping_start = os.clock()
        host.init_pb.update(0)
        parallel.waitForAny(host.send_ident, host.receive_ident, host.tick_pinging)
        local page = 1
        local counter = 1
        for _, board in pairs(host.data.authenticated_boards) do
            if (host.gui.clientlist.paginator[page] == nil) then
                host.gui.clientlist.paginator[page] = {}
            end
            table.insert(host.gui.clientlist.paginator[page], board)

            counter = counter + 1
            if (counter >= (host.mon_h - 4)) then
                page = page + 1
                counter = 1
            end
        end
    end

    -- Initializes and starts the CIBCS host program.
    -- If you wish to use the computer on which a CIBCS
    -- host program runs, run this function with `immediate_start` = `false`,
    -- and use `host.run` with `parallel`.
    host.init = function(immediate_start)
        if (immediate_start == nil) then immediate_start = false end

        clear_terminal()
        host.monitor.clear()

        host.show_terminal_text("Initializing CIBCS")
        utils.monitor.blitCenter(host.monitor, 4, "Initializing CIBCS", colors.white, colors.blue)

        host.monitor.setCursorPos(1, 1)
        host.monitor.clear()

        os.setComputerLabel("CIBCS board host #" .. os.getComputerID())

        host.data = load_host_data(host)

        if (host.data.connection_token == "") then
            utils.monitor.blitCenter(host.monitor, 6, "MANUAL CONFIGURATION REQUIRED!", colors.white, colors.red)
            print("===================================================")
            print("First time configuration required")
            print("===================================================")
            print(
                "To allow secure connections from boards, input a unique connection token - it will be used to authenticate incoming connections: ")
            host.data.connection_token = io.read()

            utils.persistence.save_data(host.data, "cibcs", "hostdata/host" .. host.id)
            sleep(1)
        end

        if (not peripheral.isPresent(host.modem_side)) then
            utils.logging.fatal("The specified modem is not available.", "CIBCS")
            return
        else
            rednet.open(host.modem_side)
        end

        term.clear()
        host.monitor.clear()
        host.board_discovery()
        if (immediate_start) then
            host.run()
        end
        sleep(1)
    end

    return {
        init = host.init,
        run = host.run,
        name = host.name,
        id = host.id,
        update_text = host.update_text,
        connected_boards = host.data.authenticated_boards
    }
end

return _host
