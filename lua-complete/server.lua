local socket = require("socket")
local cjson = require("cjson")
local analyze = require "lua-complete.analyze"

-- set up my caches
local moduleCache = {}
local fileCache = {}

-- standard library
local standardLibrary = {
    ["coroutine"] = true,
    -- ["package"] = true, -- this one starts trying to do all the things...
    ["string"] = true,
    ["table"] = true,
    ["math"] = true,
    ["io"] = true,
    ["os"] = true,
    ["debug"] = true,
}
-- load up the standard lib as needed
for k, _ in pairs(standardLibrary) do
    moduleCache[k] = analyze.analyzeModule(k)
end

-- an enum for looking at specific chars
local chars = {
    period = string.byte("."),
    openBracket = string.byte("[")
}

-- a set for word boundaries
local wordBoundarySet = {
    [string.byte(" ")] = true,
    [string.byte("\n")] = true,
    [string.byte("=")] = true,
    [string.byte("(")] = true,
}

local function stringReverseFind(src, i, charSet)
    local currentPos = i
    while currentPos > 0 do
        if charSet[string.byte(src, currentPos)] then break end
        currentPos = currentPos - 1
    end
    return currentPos + 1
end

local function getCursorVariable(src, cursor)
    local currentPos = string.byte(src, cursor)
    if currentPos == chars.period or currentPos == chars.openBracket then
        local start = stringReverseFind(src, cursor-1, wordBoundarySet)
        return string.sub(src, start, cursor-1)
    end
end

local function processRequest(line)
    print("PROCESS REQUEST")
    local request = cjson.decode(line)
    local src = request["src"]
    local filename = request["filename"]
    if not fileCache[filename] then print("creating file cache") fileCache[filename] = {} end

    -- try to analyze the source code.
    local analysis = analyze.analyzeSource(src)
    if analysis then
        for variable, moduleInfo in pairs(analysis.modules) do
            if not fileCache[filename][variable] then
                print("analyzed variable", variable)
                fileCache[filename][variable] = moduleInfo.module
                print("fileCache variable name", fileCache[filename][variable])
                if not moduleCache[moduleInfo.module] then
                    moduleCache[moduleInfo.module] = analyze.analyzeModule(moduleInfo.module)
                end
            end
        end
    end

    -- try to find the variable that the cursor is on.
    -- if it doesn't exist, we can't really do anything.
    local cursorVariable = getCursorVariable(src, request["cursor"])
    print(cursorVariable)
    if not cursorVariable then print("no cursor found") return {} end
    if standardLibrary[cursorVariable] then
        return moduleCache[cursorVariable]
    end
    local cursorLookupModule = fileCache[filename][cursorVariable]

    -- print("cursorLookupModule", cursorLookupModule)
    if cursorLookupModule then
        return moduleCache[cursorLookupModule]
    end
end

local function main(port)
    -- create a TCP socket and bind it to the local host, at any port
    local server = assert(socket.bind("*", port or 51371))

    -- keep everything up and running
    local running = true
    while running do
        -- wait for a connection from any client
        local client = server:accept()
        client:settimeout(10)

        -- receive the line
        local line, err = client:receive()

        -- if there was no error, send it back to the client
        if not err then
            -- clean shutdown mechanism
            if line == "shutdown" then
                client:send("OK" .. "\n")
                running = false
            else
                local output = processRequest(line)
                local encodedOutput = cjson.encode(output)
                client:send(encodedOutput .. "\n")
            end
        else
            print(err)
        end

        -- done with client, close the object
        client:close()
    end
end

return main
