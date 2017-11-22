package = "lua-complete"
version = "dev-1"

source = {
    url = "git://github.com/FourierTransformer/lua-complete.git"
}

description = {
    summary = "A web framework for MoonScript & Lua",
    homepage = "http://github.com/FourierTransformer/lua-complete",
    maintainer = "Shakil Thakur <shakil.thakur@gmail.com>",
    license = "MIT"
}

dependencies = {
    "lua >= 5.1, < 5.4",
    "luacheck >= 0.21, < 0.22",
    "lua-cjson",
    "luafilesystem"
}

build = {
    type = "builtin",
    modules = {
        ["lua-complete.server"] = "lua-complete/server.lua",
        ["lua-complete.client"] = "lua-complete/client.lua",
        ["lua-complete.argparse"] = "lua-complete/argparse.lua",
        ["lua-complete.analyze"] = "lua-complete/analyze.lua",
    },
    install = {
        bin = { "bin/lua-complete" }
    },
}

