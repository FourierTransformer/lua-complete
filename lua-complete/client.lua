local socket = require("socket")
local cjson = require("cjson")
local client = {}

-- load an entire file into memory
local function loadFile(textFile)
    local file = io.open(textFile, "r")
    if not file then error("File not found at " .. textFile) end
    local allLines = file:read("*all")
    file:close()
    return allLines
end

-- send any generic message (a request or not) to the server
local function sendMessage(message, host, port)
     -- create a tcp connection
    -- print("creating tcp connection", host, port)
    local tcp = assert(socket.tcp())
    tcp:connect(host, port);

    -- print("Messagelen", #message)
    tcp:send(message .. "\n")
    -- tcp:send("HERP\n")

    -- send it out
    -- the message is fully recieved when the status is not closed.
    -- the loop after the message is recieved sets the s and partial values to nil
    -- print("trying to receive message")
    local s, status, partial, response
    while status ~= "closed" do
        s, status, partial = tcp:receive()
        if response == nil and (s or partial) then
            response = s or partial
        end
        -- print(s or partial)
    end
    tcp:close()

    return response
end

function client.sendRequest(filename, cursorOffset, port)
    -- default host and port
    local host = "127.0.0.1"

    -- print("creating request")
    -- the main request body
    local request = {
        filename = filename,
        src = loadFile(filename),
        cursor = cursorOffset
    }

    -- SEND IT!
    -- print("sending request")
    local packedMessage = cjson.encode(request)
    local packedResponse = sendMessage(packedMessage, host, port)
    -- print(packedResponse)

    -- print("passing back request")
    local response = cjson.decode(packedResponse)
    return response
    -- print(response.src)
end

function client.shutdown(port)
    print("Shutting down server on port: " .. port)
    local host = "127.0.0.1"
    local value = sendMessage("shutdown", host, port)
    if value == "OK" then
        print(value)
        os.exit(0)
    else
        error("Value not send back from server. Might already by closed.")
        os.exit(1)
    end
end

return client
