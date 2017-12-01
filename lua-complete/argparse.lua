-- create a quick argument parser
local ArgParse = {}

-- handle help
ArgParse.commonHelp = {
    ["-h"] = true,
    ["--help"] = true,
    ["help"] = true,
    ["-?"] = true
}

ArgParse.versions = {
    ["-v"] = true,
    ["--version"] = true
}


function ArgParse:new(a)
    a = a or {
        validArgs = {},
        validFlags = {},
        args = {}
    }
    setmetatable(a, self)
    self.__index = self
    return a
end

-- OVERRIDE THE PRINT COMMANDS
function ArgParse.printFullHelp()

end

function ArgParse.printVersion()

end

function ArgParse.printShortHelp(code)
    print("see --help for more information")
    os.exit(code or 1)
end

-- a small add func
function ArgParse:addArg(short, long, desc, required, default)
    local info = {
        short = short, desc = desc, required = required,
        override = false, value=default
    }
    self.args[long] = info
    self.validArgs["-" .. short] = long
    self.validArgs["--" .. long] = long
end

function ArgParse:addFlag(short, long, desc, override)
    local info = {
        short = short, desc = desc, value = false,
        required = false, override = override
    }
    self.args[long] = info
    self.validFlags["-" .. short] = long
    self.validFlags["--" .. long] = long
end

local function rightPad(str, amount)
    return str .. string.rep(" ", amount - #str)
end

-- PRINT out the options!
local function printOption(short, long, desc)
    print(string.format(" -%s,  --%s %s", short, rightPad(long, 12), desc))
end
function ArgParse:print()
    for arg, info in pairs(self.args) do
        printOption(info.short, arg, info.desc)
    end
end

-- do some parsing.
function ArgParse:parse(args, index)
    -- incase someone asks for help.
    if self.commonHelp[args[index]] then
        ArgParse.printShortHelp()
    end

    -- parse through the args
    local currentArg
    local overrideFound = false
    for i = index, #args do
        -- try to find flags first
        if self.validFlags[args[i]] then
            -- if they exist, set value to true.
            currentArg = self.validFlags[args[i]]
            self.args[currentArg].value = true
            if self.args[currentArg].override then
                overrideFound = true
            end

        -- find argument
        elseif self.validArgs[args[i]] then
            currentArg = self.validArgs[args[i]]
        else
            -- set value of arg on next pass
            self.args[currentArg].value = args[i]
        end
    end
    currentArg = nil

    -- keep track of all the set commands
    local commands = {}

    -- set whatever values may exist (the defaults), and return the commands
    if overrideFound then
        for k, v in pairs(self.args) do
            commands[k] = v.value
        end
        return commands
    end

    -- ensure we have the required ones.
    for k, v in pairs(self.args) do
        if v.required == true then
            if v.value == nil then
                print("A value for '--" .. k .. "' is required")
                ArgParse.printShortHelp()
            end
        end
        commands[k] = v.value
    end

    return commands
end

return ArgParse
