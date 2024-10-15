local M = {}

M.version = _VERSION:match("%d+%.%d+")
M.path_full = string.gsub(assert(io.popen("pwd", "r")):read("*a"), "\n", "")

M.luapath = string.format(
  [[%s/modules/share/lua/%s/?/?.lua;%s/modules/share/lua/%s/?/init.lua;%s/modules/share/lua/%s/?.lua;%s]],
  M.path_full,
  M.version,
  M.path_full,
  M.version,
  M.path_full,
  M.version,
  package.path
)

M.cpath = string.format(
  [[%s/modules/lib/lua/%s/?.so;%s/modules/lib/lua/%s/?/?.so;%s]],
  M.path_full,
  M.version,
  M.path_full,
  M.version,
  package.cpath
)

M.months =
  { Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }

M.test_path = "~/CodeProjects/Studies/Lua/daily-summarizer/"

M.day_length = 86400

return M
