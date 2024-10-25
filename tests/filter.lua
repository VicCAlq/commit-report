local C = assert(require("utils.constants"))
package.path = C.luapath
package.cpath = C.cpath

--- Busted functions:
--- assert, async, before_each, describe, done, expose, finally
--- it, mock, pending, randomize, setup, spy, teardown
local f = string.format
local b = require("busted")
require("busted.runner")()
local pretty = require("pl.pretty")
local tx = require("pl.tablex")

b.describe("Filter tests", function()
  b.describe("get_commits_in_range test", function()
    it("Should fail if 'branches' argument isn't a table", function()
      local filter = require("src.filter")
      local repo = "ollama.ollama"
      local branches = "branch"

      b.spy.on(filter, "get_commits_in_range")

      assert.has_error(function()
        ---@diagnostic disable-next-line
        filter.get_commits_in_range(branches, repo, nil)
      end, "get_commits_in_range: Value for 'branches' is not a table or nil")
      b.assert.spy(filter.get_commits_in_range).was.called()
    end)

    it("Should fail if 'range' argument isn't a table", function()
      local filter = require("src.filter")
      local repo = "ollama.ollama"
      local branches = { "main" }
      local range = 24

      b.spy.on(filter, "get_commits_in_range")

      assert.has_error(function()
        ---@diagnostic disable-next-line
        filter.get_commits_in_range(branches, repo, range)
      end, "get_commits_in_range: Value for 'range' is not a table or nil")
      b.assert.spy(filter.get_commits_in_range).was.called()
    end)

    it("Should fail if 'project' argument isn't a string", function()
      local filter = require("src.filter")
      local repo = { ollama = "ollama" }
      local branches = { "main" }
      local range = { 0, 12 }

      b.spy.on(filter, "get_commits_in_range")

      assert.has_error(function()
        ---@diagnostic disable-next-line
        filter.get_commits_in_range(branches, repo, range)
      end, "get_commits_in_range: Value for 'project' must be a valid string")
      b.assert.spy(filter.get_commits_in_range).was.called()
    end)

    it("Should fail if 'range.oldest' isn't a number", function()
      local filter = require("src.filter")
      local repo = "ollama.ollama"
      local branches = { "main" }
      local range = { oldest = {}, latest = 12 }

      b.spy.on(filter, "get_commits_in_range")

      assert.has_error(function()
        ---@diagnostic disable-next-line
        filter.get_commits_in_range(branches, repo, range)
      end, "get_commits_in_range: Value for 'range.oldest' is " .. type(range.oldest) .. " and not a number")
      b.assert.spy(filter.get_commits_in_range).was.called()
    end)

    it("Should fail if 'range.latest' isn't a number", function()
      local filter = require("src.filter")
      local repo = "ollama.ollama"
      local branches = { "main" }
      local range = { oldest = 0, latest = "a" }

      b.spy.on(filter, "get_commits_in_range")

      assert.has_error(function()
        ---@diagnostic disable-next-line
        filter.get_commits_in_range(branches, repo, range)
      end, "get_commits_in_range: Value for 'range.latest' is " .. type(range.latest) .. " and not a number")
      b.assert.spy(filter.get_commits_in_range).was.called()
    end)

    it("Should fail if 'range.latest' is smaller than 'range.oldest", function()
      local filter = require("src.filter")
      local repo = "ollama.ollama"
      local branches = { "main" }
      local range = { oldest = 0, latest = 4 }

      b.spy.on(filter, "get_commits_in_range")

      assert.has_error(function()
        ---@diagnostic disable-next-line
        filter.get_commits_in_range(branches, repo, range)
      end, "get_commits_in_range: Value for 'range.oldest' has to be larger than 'range.latest'")
      b.assert.spy(filter.get_commits_in_range).was.called()
    end)

    it("Filters commits within a given range of days", function()
      local filter = require("src.filter")
      local repo = "ollama.ollama"
      local branches = { "main" }
      local range = { oldest = 4, latest = 0 }
      os.execute(f("cd repos/%s/ && git fetch --all && git pull && cd ../../", repo))
      b.spy.on(filter, "get_commits_in_range")

      local commits = filter.get_commits_in_range(branches, repo, range)

      assert(type(commits[branches[1]][1].unix_time) == "number")
      assert(type(commits[branches[1]][1].author_name) == "string")
      assert(type(commits[branches[1]][1].author_email) == "string")
      b.assert.spy(filter.get_commits_in_range).was.called()
    end)
  end)
end)
