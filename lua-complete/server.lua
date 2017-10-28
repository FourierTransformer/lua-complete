local socket = require("socket")
local cjson = require("cjson")
local analyze = require "lua-complete.analyze"

-- set up my caches
local moduleCache = {}
local fileCache = {}

-- set it up!
local server = {}

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
    [string.byte(".")] = true, -- table
    [string.byte("[")] = true, -- table
    [string.byte("(")] = true, -- func
    [string.byte(":")] = true, -- func
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
    if chars[currentPos] then
        local start = stringReverseFind(src, cursor-1, wordBoundarySet)
        return string.sub(src, start, cursor-1), currentPos
    end
end

local function parseCursorVariable(src, cursor)
    local cursorVariable, char = getCursorVariable(src, cursor)
    print(cursorVariable, char)
    -- probably missing an autocomplete trigger char
    if cursorVariable == nil then
        return nil, nil
    end
    local vars = {}
    -- quick word iterator. Should cover most use cases.
    for word in string.gmatch(cursorVariable, "%a+") do table.insert(vars, word) end
    return vars, char
end

local function getTableInfo(t, cursorVariables, depth)
    if cursorVariables[depth] == nil then
        return t
    end
    return getTableInfo(t.table[cursorVariables[depth]], cursorVariables, depth+1)
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
    local cursorVariables, lastChar = parseCursorVariable(src, request["cursor"])
    if not cursorVariables or not cursorVariables[1] then print("no cursor found") return {} end
    local cursorVariable = cursorVariables[1]

    local cursorLookupModule
    -- look in file first, then stdlib as people may override stdlib names
    if fileCache[filename][cursorVariable] then
        cursorLookupModule = fileCache[filename][cursorVariable]
    elseif standardLibrary[cursorVariable] then
        cursorLookupModule = cursorVariable
    else
        print("something's out of bounds")
        return {}
    end

    -- traverse to the lastTable
    local lastTable = getTableInfo(moduleCache[cursorLookupModule], cursorVariables, 2)

    -- print("cursorLookupModule", cursorLookupModule)
    local output = {}
    if cursorLookupModule then

        -- return all the things/types in the table
        if lastTable.type == "table" then
            for k, v in pairs(lastTable.table) do
                table.insert(output, {name=k, type=v.type})
            end
            -- return lastTable

        -- if it's a function return function params
        elseif lastTable.type == "function" then
            if lastTable["function"].what == "Lua" then
                output = lastTable["function"].paramList
            end
            -- return lastTable
        end
    end
    return output
end

function server.main(port)
    -- create a TCP socket and bind it to the local host, at any port
    local serverSocket = assert(socket.bind("*", port or 51371))

    -- keep everything up and running
    local running = true
    while running do
        -- wait for a connection from any client
        local client = serverSocket:accept()
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

-- useful when testing the private funcs
if _TEST then
    server._TEST = {
        ["getCursorVariable"] = getCursorVariable,
        ["parseCursorVariable"] = parseCursorVariable
    }
end

return server
