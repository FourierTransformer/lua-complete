local server
local parser = require("luacheck.parser")

describe("Going to test a private element", function()

    setup(function()
        _G._TEST = true
        server = require("lua-complete.server")
    end)

    teardown(function()
        _G._TEST = nil
    end)

    local getTest = {
        ["herp."] = "herp",
        ["\nherp."] = "herp",
        ["(herp."] = "herp",
        ['["herp"].'] = '["herp"]',
        ['derp["herp"].perp.'] = 'derp["herp"].perp',
        ['derp["herp"].perp('] = 'derp["herp"].perp',
        ['=str:'] = 'str',
        [' str('] = 'str',
        ['derp(herp.'] = "herp"
    }

    for k, v in pairs(getTest) do
        it("gets ".. k .." correctly", function()
            assert.is_true(server._TEST.getCursorVariable(k, #k) == v)
        end)
    end

    local parseTest = {
        ["herp."] = {"herp"},
        ["\nherp."] = {"herp"},
        ["(herp."] = {"herp"},
        ['["herp"].'] = {"herp"},
        ['derp["herp"].perp.'] = {"derp", "herp", "perp"},
        ['derp["herp"].perp('] = {"derp", "herp", "perp"},
        ['=str:'] = {'str'},
        [' str('] = {'str'},
        ['derp(herp.'] = {"herp"}
    }

    for k, v in pairs(parseTest) do
        it("parses ".. k .." correctly", function()
            assert.same(server._TEST.parseCursorVariable(k, #k), v)
        end)
    end

end)