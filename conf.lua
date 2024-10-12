--- This is a file to configure the Lua Environment for the running script,
--- primarily used to set the relative paths where the Lua libraries are
--- installed inside ./modules/
---
--- To use this file as the environment config, link it to the desired
--- script with `lua -l conf script_to_run.lua`
---
--- The shell script `run.sh` give you an easier way to execute the
--- Lua scripts already with the config link enabled, just run
--- `./run/sh script` for a script in the project directory
--- `./run.sh src/script` for scripts inside another directory
---
--- It will add the .lua extension by itself

local f = string.format

---@type string Gets the current Lua version
local version = _VERSION:match("%d+%.%d+")

package.path = f(
  "modules/share/lua/%s/?/?.lua;modules/share/lua/%s/?/init.lua;modules/share/lua/%s/?.lua;%s",
  version,
  version,
  version,
  package.path
)
package.cpath = f("modules/lib/lua/%s/?.so;modules/lib/lua/%s/?/?.so;%s", version, version, package.path)
