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

-- enums for looking at specific chars
local autoCompleteTableChars = {
    [string.byte(".")] = true, -- table
    [string.byte("[")] = true, -- table
    [string.byte(":")] = true, -- func, table.
}
local autoCompleteFunctionChars = {
    [string.byte("(")] = true, -- func
}

local chars = {
    ["colon"] = string.byte(":")
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
    if autoCompleteTableChars[currentPos] or autoCompleteFunctionChars[currentPos] then
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
    -- %w is used to find alphanumeric values - hopefully being the variable names
    for word in string.gmatch(cursorVariable, "%w+") do table.insert(vars, word) end
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
    -- get the things from the request
    local request = cjson.decode(line)
    local src = request["src"]
    local filename = request["filename"]
    local packagePath = request["packagePath"]

    -- create a filecache if it doens't exist already
    if not fileCache[filename] then print("creating file cache") fileCache[filename] = {} end

    -- try to analyze the source code.
    local analysis = analyze.analyzeSource(src)

    if analysis then

        -- go through and analyze the existing modules
        for variable, moduleInfo in pairs(analysis.modules) do

            -- check if it's already been analyzed for the
            -- variable in the current file
            -- if not fileCache[filename][variable] then
                print("analyzed variable", variable)

                -- set the filename -> variable to the module name
                print("moduleInfo", moduleInfo.module)
                fileCache[filename][variable] = {
                    ["name"] = moduleInfo.module,
                    ["type"] = nil
                }

                -- cache the module in moduleCache
                -- the idea is you can do a lookup for system modules
                -- (as they dont change frequently) and only really need to
                -- analyze them once
                print("fileCache variable name", fileCache[filename][variable])
                if not moduleCache[moduleInfo.module] then
                    local analyzedModule = analyze.analyzeModule(moduleInfo.module)
                    if analyzedModule then
                        moduleCache[moduleInfo.module] = analyzedModule
                        fileCache[filename][variable].type = "system"
                    else
                        moduleCache[moduleInfo.module] = analyze.analyzeModule(moduleInfo.module, packagePath)
                        fileCache[filename][variable].type = "local"
                    end
                end

                -- TODO: figure out what happens if the analyzeModule require fails.
                -- update the path with the current file location
                -- check if the module has been analyzed
                -- if so: check the last modified date and see if it's changed
                --   if so: re-analyze the module
                -- if not: try to analyze the module
            if fileCache[filename][variable].type == "local" then
                print("\nlocal fileCache. RESCANNNN!!!")
                local analyzedModule = analyze.analyzeModule(moduleInfo.module, packagePath)
                if analyzedModule then
                    moduleCache[moduleInfo.module] = analyzedModule
                end
            end

        end
        print("module analysis complete")
    else
        print("analysis wasn't completed successfully")
        print("continuing anyway")
        -- return {}
    end

    -- try to find the variable that the cursor is on.
    -- if it doesn't exist, we can't really do anything.
    local cursorVariables, lastChar = parseCursorVariable(src, request["cursor"])
    if not cursorVariables or not cursorVariables[1] then print("no cursor found") return {} end
    print("twice", cursorVariables[1], lastChar)
    local cursorVariable = cursorVariables[1]

    -- keep track of the analyzed module
    local cursorLookupModule
    -- look in file first, then stdlib as people may override stdlib names
    if analysis and analysis.variables[cursorVariable] then
        cursorLookupModule = analysis.variables[cursorVariable]
    elseif fileCache[filename][cursorVariable] then
        print("found in file cache")
        print(fileCache[filename][cursorVariable].name)
        cursorLookupModule = moduleCache[fileCache[filename][cursorVariable].name]
        print(cursorLookupModule)
    elseif standardLibrary[cursorVariable] then
        cursorLookupModule = moduleCache[cursorVariable]
    else
        print("cursorVariable not found in any lookup", cursorVariable)
        return {}
    end

    -- traverse to the lastTable
    local lastTable = getTableInfo(cursorLookupModule, cursorVariables, 2)
    if lastTable == nil then print("lastTable is nil") return {} end

    local output = {["type"] = lastTable.type, ["info"] = {}}
    if cursorLookupModule then

        -- return all the things/types in the table
        if lastTable.type == "table" and autoCompleteTableChars[lastChar] then
            -- if the function is a colon, and the first argument is self,
            -- lua uses syntactic sugar to make life easier, so this accounts for it
            if lastChar == chars.colon then
                for k, v in pairs(lastTable.table) do
                    if v.type == "function" then
                        if v["function"].paramList and v["function"].paramList[1] == "self" then
                            table.insert(output.info, {name=k, type=v.type})
                        end
                    end
                end
            else
                -- some variables don't get fully explored...
                if lastTable.table then
                    for k, v in pairs(lastTable.table) do
                        if v.type == "function" and v["function"].what == "Lua" then
                            table.insert(output.info, {name=k, type=v.type, paramList=v["function"].paramList})
                        else
                            table.insert(output.info, {name=k, type=v.type})
                        end
                    end
                end
            end

        -- if it's a function return function params
        elseif lastTable.type == "function" and autoCompleteFunctionChars[lastChar] then
            if lastTable["function"].what == "Lua" then
                output.info = lastTable["function"].paramList
            end
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
                if output.type == "table" then
                    table.sort(output.info, function(a, b) return a.name < b.name end)
                end
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
