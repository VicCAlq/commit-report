local C = assert(require("utils.constants"))
package.path = C.luapath
package.cpath = C.cpath

--- Busted functions:
--- assert, async, before_each, describe, done, expose, finally
--- it, mock, pending, randomize, setup, spy, teardown
local b = require("busted")
local f = string.format
require("busted.runner")()
local pretty = require("pl.pretty")
local tx = require("pl.tablex")
