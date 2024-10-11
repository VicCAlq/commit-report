local f = string.format
local version = _VERSION:match("%d+%.%d+")
package.path = f(
  "modules/share/lua/%s/?/?.lua;modules/share/lua/%s/?/init.lua;modules/share/lua/%s/?.lua;%s",
  version,
  version,
  version,
  package.path
)
package.cpath = f("modules/lib/lua/%s/?.so;modules/lib/lua/%s/?/?.so;%s", version, version, package.path)
