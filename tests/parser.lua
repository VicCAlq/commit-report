local C = assert(require("utils.constants"))
package.path = C.luapath
package.cpath = C.cpath

--- Busted functions:
--- assert, async, before_each, describe, done, expose, finally
--- it, mock, pending, randomize, setup, spy, teardown
local b = require("busted")
require("busted.runner")()
local pretty = require("pl.pretty")
local tx = require("pl.tablex")

b.describe("Parser tests", function()
  b.describe("branches_to_table test", function()
    b.it("Gets branches from given repository and stores the branch names in a table", function()
      local parser = require("src.parser")
      local repo = "ollama.ollama"

      b.spy.on(parser, "branches_to_table")

      local branches = parser.branches_to_table(repo)
      local main_index = tx.find(branches, "main")

      b.assert.spy(parser.branches_to_table).was.called_with(repo)
      assert(type(branches) == "table")
      assert(main_index ~= nil)
    end)
  end)

  b.describe("categorize_branches test", function()
    it("Returns two tables, one for remote branches and another for local branches", function()
      local parser = require("src.parser")
      local repo = "ollama.ollama"

      b.spy.on(parser, "categorize_branches")

      local rb, lb = parser.categorize_branches(parser.branches_to_table(repo))
      local rmain = tx.find(rb, "remotes/origin/main")
      local lmain = tx.find(lb, "main")

      b.assert.spy(parser.categorize_branches).was.called()
      assert(type(rb) == "table" and type(lb) == "table")
      assert(rmain ~= nil and lmain ~= nil)
    end)

    it("Should fail if 'table' argument isn't a table", function()
      local parser = require("src.parser")
      local repo = "ollama.ollama"

      b.spy.on(parser, "categorize_branches")

      assert.has_error(function()
        ---@diagnostic disable-next-line
        parser.categorize_branches(nil)
      end, "categorize_branches: The value given for 'branches' is not a table")
      b.assert.spy(parser.categorize_branches).was.called()
    end)
  end)

  b.describe("serialize_commits", function()
    it("Fails if project isn't a string", function()
      local parser = require("src.parser")
      local repo = { "ollama.ollama" }
      local branch = "remotes/origin/main"

      b.spy.on(parser, "serialize_commits")

      assert.has_error(function()
        ---@diagnostic disable-next-line
        parser.serialize_commits(repo, branch)
      end, "serialize_commits: The value given for 'project' is not a string")
      b.assert.spy(parser.categorize_branches).was.called()
    end)

    it("Fails if branch isn't a string", function()
      local parser = require("src.parser")
      local repo = "ollama.ollama"
      local branch = { "aaa" }

      b.spy.on(parser, "serialize_commits")

      assert.has_error(function()
        ---@diagnostic disable-next-line
        parser.serialize_commits(repo, branch)
      end, "serialize_commits: The value given for 'branch' is not a string")
      b.assert.spy(parser.categorize_branches).was.called()
    end)

    it("Returns a table containing commit objects from the given branch", function()
      local parser = require("src.parser")
      local repo = "ollama.ollama"
      local branch = "remotes/origin/main"

      local commits = parser.serialize_commits(repo, branch)

      assert(commits[1].author_name ~= nil, "Author name for this commit object is nil")
      assert(commits[1].author_email ~= nil, "Author email for this commit object is nil")
      assert(commits[1].unix_time > 0, "Unix time not valid for this commit object")
      b.spy.on(parser, "serialize_commits")

      b.assert.spy(parser.categorize_branches).was.called()
    end)
  end)
end)
