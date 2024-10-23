local C = assert(require("utils.constants"))
package.path = C.luapath
package.cpath = C.cpath

local pretty = require("pl.pretty")
local b = require("busted")
require("busted.runner")()

b.describe("Checks if busted has been loaded", function()
  b.it("Just makes a truthful assertion", function()
    local parser = require("src.parser")

    b.spy.on(parser, "categorize_branches")
    local rem, loc = parser.categorize_branches({ "remotes/origin/test", "test" })
    pretty.dump(rem)
    pretty.dump(loc)

    b.assert.spy(parser.categorize_branches).was.called()
  end)
end)
