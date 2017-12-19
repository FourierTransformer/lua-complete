# lua-complete (BETA)
[![Build Status](https://travis-ci.org/FourierTransformer/lua-complete.svg?branch=master)](https://travis-ci.org/FourierTransformer/lua-complete)
[![Coverage Status](https://coveralls.io/repos/github/FourierTransformer/lua-complete/badge.svg?branch=master)](https://coveralls.io/github/FourierTransformer/lua-complete?branch=master)

lua-complete is a code completion helper that uses analysis to determine function names, function parameters, and table keys. It should one day be able to help text editors and IDEs do completion of Lua code. It follows the client/server model used for auto-completing code and caches analysis for speed.


## Setup
1. Install lua-complete from the dev luarocks:
```
luarocks install --server=http://luarocks.org/dev lua-complete
```

2. Install and configure one of the lua-complete plugins:
    * [LuaComplete-Sublime](https://github.com/FourierTransformer/LuaComplete-Sublime) (still in development)

### Command-line Options
```
Server options
lua-complete server [-p <port>]
 -p,  --port         port number to run the server on (default: 51371)

Client options
lua-complete client -c <cursor> [-f <file>] [-p <port>] [-i] [-x]
 -f,  --filename     path to file for autocompletion
 -i,  --stdin        read file from stdin. filename argument now used for cache filename
 -r,  --packagePath  path to load packages from (default: current dir)
 -c,  --cursor       cursor offset (in bytes) of variable to analyze
 -x,  --shutdown     shutdown the server
 -p,  --port         port number to connect to (default: 51371)
```

### Basic Command-line Usage
Fire up the server:
```
lua-complete server
```

Send a file and cursor position (in bytes) to the server:
```
lua-complete client -f <filename> -c <cursor_position>
```

It currently returns the type of completion (either "table" or "function") and any values/types that it knows about.

Example:
```
table
cars: string
foo: string
bar: table
```

NOTE: The cursor has to be at the position of the `.`, `:`, `[` or `(` to do any completions.

### Sample Library Usage
The library follows most of the same command-line options from above.

Server:
```lua
local server = require("lua-complete.server")
server.main(port)
```

Client:
```lua
local client = require("lua-complete.client")

-- the filename is only ever used for cache name purposes under the covers
output = client.sendRequest(filename, fileContents, cursorOffset, packagePath, port)

client.shutdown(port)
```

## Hopes and Dreams
I'll try to keep this updated with what's currently working, what I plan to do in the future, and things that are kinda out there.
### Working
lua-complete can currently help auto-complete:
 * Imported module functions, function parameters, and tables (including subtables!)
 * Lua standard library functions (except the packages module)
 * Completion of Lua's 'self' with colon operator (mostly, currently doesn't filter out "self" from function list) in imported modules
 * Table completions in current file (not-including sub-tables...)
 * Function parameters for Lua functions (in current file)
 * Add additional paths to search through (so it can handle project-level modules)

### In the future
 * Better cache invalidation. Re-analyze any project-level modules that may have been updated since analysis.
 * Auto-complete subtables in current file.
 * Add completions for standard library (and possibly other popular libraries)
 * Add ability to load custom completions
 * Better UTF-8 support for variable names (server currently has a gmatch pattern that doesn't handle UTF-8 well.)

### Longshot
The following would require more full file analysis as opposed to just module-level analysis (some testing would have to be done as to if there is a speed difference):
 * Determine if a Lua module function arg is optional or not
 * Return types in current file (requires more of a type system)
 * Scoping of variables (depends on how hard this ends up being)
 * Return types for imported modules (possibly out of scope)

### Impossible
I'm fairly certain the following is impossible to do in pure Lua:
 * Determine a C function's arguments


## Notes
This is still really experimental! Be careful using this as I'm currently changing how/what it outputs and things that may affect everyday use. I would be especially wary of interacting with the server without the client (trying to send it JSON directly), as I may change the serialize/deserialize format in the future. The same general warning goes for using any of the analyze module functions.

Your best bet is to use the command-line interface or import the server/client directly in lua - which would be useful if you're writing an editor in Lua.

## Questions and Contributing
Feel free to open a Github issue with any questions/features/suggestions that you have! Also, check out [CONTRIBUTING.md](CONTRIBUTING.md) if you want to help!

## Licenses
lua-complete is released under the [MIT License](LICENSE.md)
