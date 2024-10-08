# Commit Report(er)

Small app to summarize commit activity and output it to a LaTeX report, which can then be converted to PDF.

It aims to be a decent substitute to a "daily" meeting if you're in a team where the main use for a daily is to give a report of recent progress to a client (be it your PM, PO or someone else), and let the developers focus on their tasks while also letting them know about their peers' progress (so that communication of potential blockers is also more efficient)

## Requirements

- Lua 5.1 minimum
- Luarocks
- SQLite3
- Penlight (installed via LuaRocks)
- LuaSQL-sqlite3 (installed via LuaRocks)
- Lapis (installed via Luarocks)

Currently, the easiest way to guarantee the dependencies are installed is to have them installed system-wide. Future implementation aims to be deployed as a docker image.

## Usage

There are/will be two intended modes of use:

- Via CLI by directly invoking the main init.lua script with some given arguments
- Via a web-app implemented with the Lapis framework

Current focus is to finish the CLI implementation first, then build the Lapis server to host a web-app version. It's intended to be fully deployable in any kind of host, be it cloud or local bare-metal.

The code is as documented as I thought was necessary for anyone wanting to understand the code-base, and everything is typed according to the most common Lua language servers

## How it works

1. The main script is invoked with a minimum of three arguments:
   - How many days from today will be the latest commit (with 0 being today)
   - How many days from today will be the oldest commit (eg. 4 being 4 days ago)
   - The full url of the git repository as in `https://gitsample.com/owner/repo_name.git`
2. The URL is given to the "fetcher" module, who will clone the repository into the `./repos/` directory with the option `--filter=blob:none` to avoid getting the full content for the repository
3. The "parser" module will get the branch names and store in a list
4. The "parser" then separates remote from local branches
5. The "parser" then gets the output from `git log` for branches whose last commit isn't older than the "oldest commit" argument
6. The "filter" module is then called to select only the commits that fit between the given range of days
7. The Database object is instantiated
8. A connection is stablished to a file named after the git repository (eg. `./databases/owner.repository.db`)
9. The commit table is created
10. The commit data gathered by the "filter" module is inserted
11. Optionally, the repository can be deleted after inserting the commit history in the database

Schema of how the web-app version will work is still in the planning stages

## Feature roadmap

-[x] CLI arguments  
-[x] Repository-fetching module: Will save the fetched repositories to ./repos/  
-[x] Parser module:  
 -[x] Branches parser  
 -[x] Branches categorizer (remote/local)  
 -[x] Commit serializer  
-[x] Filter module  
-[x] SQLite interface:  
 -[x] LuaSQL install  
 -[x] DB class instantiation  
 -[x] Connection initializer  
 -[x] Connection closer  
 -[x] Table selection  
 -[x] Table creation  
 -[x] Table deletion  
 -[x] Values selection  
 -[x] Values insertion  
 -[x] Values deletion  
 -[x] Values parsing  
 -[x] Columns parsing  
 -[x] Clauses parsing  
-[ ] SQLite integration:  
 -[ ] With fetcher  
 -[ ] With parser  
 -[ ] With filter  
 -[ ] With main script  
-[ ] LaTeX integration  
-[ ] Lapis integration  
-[ ] Docker containerization

The unfinished sections are expected to be expanded and fractioned as they're worked on.

## FAQ

> Why Lua?

- After 2 and a half years working with TS/JS/Python (and React and Django...) I wanted to take a break from these echosystems and go a bit lower-level. My main considerations were Lua and Go, since both are fast and relatively simple enough to get productive in a few days. In the end I chose Lua because it forces you to build more stuff by yourself (the Go standard library is _really_ well featured) and it being less common makes you take more effort in adapting to the tools you're given. Also, I was in the process of writing my own NeoVim config from scratch, so I was already in the headspace to use Lua.

> Why Lapis?

- It's already battle-tested by [Itch.io](https://itch.io) (you can read a bit more about it [here](https://leafo.net/posts/itchio-and-coroutines.html)), so I decided to give it a try.

> I have a question, where can I submit it?

- For now opening an issue is fine. Or you can send a PM here on GitHub or write me an email at vic.mca.dev@gmail.com
