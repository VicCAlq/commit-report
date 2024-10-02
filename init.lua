local lapp = require("pl.lapp")
local pretty = require("pl.pretty")
local parser = require("src.parser")
local filter = require("src.filter")
local gitter = require("src.gitter")

local args = lapp([[
  Command-line mode for the summarizer.
    -v,--vertical  Vertical layout orientation (defaults to horizontal)
    -l,--latest (default 0)  Most recent date for the fetched commits
    <oldest> (number)  Oldest date for the fetched commits
    <url> (string)  URL for the GIT repo
]])
-- print(args.vertical, args.latest, args.oldest, args.url)

local repo_name = gitter.clone(args.url)

local branches = parser.branches_to_table(repo_name)
local remote_branches, _ = parser.categorize_branches(branches)

local commits = filter.get_commits_in_range(remote_branches, repo_name, { oldest = args.oldest, latest = args.latest })
pretty.dump(commits)
