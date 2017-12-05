package = "lua-complete"
version = "scm-0"

source = {
    url = "git://github.com/FourierTransformer/lua-complete.git"
}

description = {
    summary = "lua-complete is an auto-completion engine for the Lua language",
    detailed = [[
    lua-complete can provide auto-complete suggestions for a text editor or IDE.
    The file contents, cursor location, and [optionally] include directory get passed in,
    and lua-complete will suggest elements in the table and/or function arguments (for Lua functions). 
    ]],
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

