# LuaComplete
LuaComplete is an experimental code completion helper that uses static analysis to determine variable information (like keys and types). It should one day be able to help text editors and IDEs do completion of lua code. It follows the client/server model used for auto-completing code and caches analysis for speed. 

# Hopes and Dreams
I'll try to keep this updated with what's currently working, what I plan to do in the future, and things that are kinda out there.
## Working
LuaComplete can currently help auto-complete:
 * Top-level module functions/variables
 * Lua standard library

## In the future
 * All levels of module information (sub-table values/functions)
 * Add include paths (can then handle project-level modules)
 * Table completions
 * Completions of Lua's 'self' with colon operator
 * Function parameters for Lua functions and Lua standard library
 * Scoping of variables
 * Return types in current file
 * Better cache invalidation. Re-analyze any modules that may have been updated since analysis.

## Longshot
 * Return types for imported modules (would have to do full file analysis as opposed to just module analysis)
 * There is a lot more, I'm sure.

# Installation
1. Clone this repo
2. `luarocks make lua-complete-dev-1.rockspec`

# Usage
1. Fire up the server 
  * `lua-complete server`
2. Send a file and cursor position (in bytes) to the server:
  * `lua-complete client -f <filename> -c <cursor_position>`

It currently returns a json blob, but should soon return a nice human readable list.

# Notes
This is still really experimental! Be careful using this as I'm currently changing how/what it outputs and things that may affect everyday use. I would be especially weary of interacting with the server without the client, as I may change the serde format in the future. The same general warning goes for using any of the analyze module functions.
