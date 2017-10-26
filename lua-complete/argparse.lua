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
function ArgParse:add(short, long, desc, required, override, default)
    local info = {
        short = short, desc = desc, required = required,
        override = override, value=default
    }
    self.args[long] = info
    self.validArgs["-" .. short] = long
    self.validArgs["--" .. long] = long
end

-- PRINT out the options!
local function printOption(short, long, desc)
    print(string.format(" -%s,  --%s\t\t%10s", short, long, desc))
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
        if self.validArgs[args[i]] then
            currentArg = self.validArgs[args[i]]
            if self.args[currentArg].override then
                overrideFound = true
            end
        else
            self.args[currentArg].value = args[i]
        end
    end
    currentArg = nil

    -- keep track of all the set commands
    local commands = {}

    if overrideFound then
        for k, v in pairs(self.args) do
            if v.override == true then
                if v.value == nil then
                    print("A value for '--" .. k .. "' is required")
                    ArgParse.printShortHelp()
                end
                commands[k] = v.value
            end
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
        if v.override then
            v.value = false
        end
        commands[k] = v.value
    end

    return commands
end

return ArgParse
