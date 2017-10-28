local parser = require("luacheck.parser")
local pretty = require 'pl.pretty'

local analyze = {}

-- a basic findEquals. Could one day do a lot more, but starting small for now.
local function findEquals(t, output, line)
    -- something is equal to something else!
    if t.equals_location then
        for i = 1, #t[1] do
            -- if there's a variable assignment
            if t[1][i].tag == "Id" and t[2][i] and t[2][i].tag then
                if t[2][i][1] and t[2][i][2] and
                    t[2][i][1].tag == "Id" and t[2][i][1][1] == "require" and
                    t[2][i][2].tag == "String" then
                    -- table.insert(output.modules, {
                        -- set the variable name
                        -- local tag = t[1][i][1]
                        output.modules[t[1][i][1]] = {
                            ["module"] = t[2][i][2][1],
                            ["location"] = line
                            -- ["line"]
                            -- could add scoping info here later
                            -- ["location"] = t[1][i].location
                        }
                            -- ["location"] = t[1][i].location
                    -- })
                    -- print(t[1][i][1])    -- name used
                    -- print(t[2][i][1][1]) -- require
                    -- print(t[2][i][2][1]) -- hexafont

                elseif t[2][i].tag == "Call" then
                    -- we might be able to do some type things here
                    -- print("Call")
                    -- pretty.dump(t[2][i])

                elseif t[2][i].tag == "Table" then
                    -- we'll get table info later...
                    -- print("Table")
                    -- pretty.dump(t[2][i])
                end
            end
            -- print("\n")
        end
    end
    -- return output
end

local function analyzeAST(t, output)
    -- yay recursion! create output if it doesn't exist
    if not output then
        output = {
            ["modules"] = {}
        }
    end

    -- iterate through ALL the tables!
    if type(t) == "table" then
        for line = 1, #t do
            -- mergeTable(output, findEquals(t[line]))
            findEquals(t[line], output, line)
            analyzeAST(t[line], output)
        end
    end
    return output
end

-- returns nil if it can't parse or the analyzed ast
function analyze.analyzeSource(src)
    -- print("generating ast...")
    -- print(src)
    -- print(type(src))

    -- lua 5.1 compat...
    local function parserParse()
        return parser.parse(src)
    end

    local function getAST()
        local name, value
        -- the first few levels are c/lua/syntax errors
        -- also, this could potentially be a moving target.
        for level = 11, 5, -1 do
            local i = 1
            while true do
                name, value = debug.getlocal(level, i)
                -- when nil, there are no more things to check.
                if name == nil then break end

                -- the variable is called "block"
                if name == "block" then
                    -- print("found it")
                    return value
                end

                i = i + 1
            end
        end
    end

    -- local status, ast = pcall(parser.parse, src)
    local _, ast = xpcall(parserParse, getAST)
    if not ast then
        -- print(ast)
        return nil
    end

    -- print("analyzing ast...")
    local assignments = analyzeAST(ast)
    pretty.dump(assignments)
    return assignments
end

-- adapted from https://facepunch.com/showthread.php?t=884409
function analyze.analyzeLuaFunc(func)
    local info = debug.getinfo(func, "uS")
    local out = {what = info.what}
    -- can't do anything with a c function
    if info.what == "C" then
        return out
    end

    -- going into the code!
    local paramCount = info.nparams
    local isVarArg = info.isVarArg
    local paramNameList = {}
    for i = 1, paramCount do
        local param_name = debug.getlocal(func, i)
        paramNameList[i] = param_name
    end

    -- add the ...'s for varargs
    if isVarArg then
        paramNameList[paramCount+1] = "..."
    end

    -- build up the output
    out["paramList"] = paramNameList
    -- out["paramCount"] = paramCount
    -- out["isVarArg"] = isVarArg
    return out
end

function analyze.analyzeTable(t)
    local out = {}
    local valueType
    for k, v in pairs(t) do
        valueType = type(v)
        out[k] = {["type"] = valueType}

        -- get information about sub-tables
        -- avoid metatables. recursion for days.
        if k ~= "__index" and valueType == "table" then
            out[k]["table"] = analyze.analyzeTable(v)
        elseif valueType == "function" then
            out[k]["function"] = analyze.analyzeLuaFunc(v)
        end
    end
    return out
end

function analyze.analyzeModule(module)
    print("analyze", module)
    local analyzedModule = require(module)
    local moduleType = type(analyzedModule)
    local output = {["type"] = moduleType}
    if type(analyzedModule) == "table" then
        output["table"] = analyze.analyzeTable(analyzedModule)
    elseif type(analyzedModule) == "function" then
        output["function"] = analyze.analyzeLuaFunc(analyzedModule)
    end
    -- pretty.dump(output)
    return output
end

return analyze

