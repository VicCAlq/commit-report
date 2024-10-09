local lapp = require("pl.lapp")
local pretty = require("pl.pretty")
local parser = require("src.parser")
local filter = require("src.filter")
local fetcher = require("src.fetcher")

--- Command-line arguments
local args = lapp([[
  Command-line mode for the summarizer.
    -v,--vertical  Vertical layout orientation (defaults to horizontal)
    <latest> (number)  Most recent date for the fetched commits
    <oldest> (number)  Oldest date for the fetched commits
    <url> (string)  URL for the GIT repo
]])
-- print(args.vertical, args.latest, args.oldest, args.url)

--- Clones the repository to the adequate location inside ./repos/ and
--- returns the name of that directory
local repo_name = fetcher.clone(args.url)

--- Branch parsing to get only the remote branches
local branches = parser.branches_to_table(repo_name)
local remote_branches, _ = parser.categorize_branches(branches)

--- Filters the commits, getting only the commits in the given date range
local commits = filter.get_commits_in_range(remote_branches, repo_name, { oldest = args.oldest, latest = args.latest })
pretty.dump(commits)
