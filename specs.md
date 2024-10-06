# Basics of the app

This app's main function is to create a summary of the latest activities in a repository. Ideally its purpose is to generate a report containing the major updates from one day to the next, and format it into a `.latex` file. In the future the idea is to also generate charts to track the progress of the project.

## Features to implement

- 1st iteration can be via CLI, and getting the repo either through user input, or a config file (TOML, YAML, JSON or similar)
- 2nd iteration would be a web service with a preview function.
- Gather the repos by using `git clone --bare --filter=blob:none repo_address_goes_here`
- Implement a SQLite db to store the commits
- It'll only check things uploaded to the main repo, so local branches are not considered
- The summary is done through the commit messages, which will need to follow a template to be parsed
- Collaborators' pictures can be specified for the report
- Write summaries using Ollama if possible. Counts points for AI usage
- Decide on which and how to implement the charts
- Report format can also be specified (vertical for print, horizontal for presentation)

## App workflow

-[ ] Call the app by something like `summarizer https://www.gitsmth.com/my_company/my_repo.git` -[ ] Show cloning progress -[ ] After that, prompt the user about:

- Custom config TOML file
- Days range from today
- Report format -[ ] Show progress of report generation -[ ] Give user the report file

- Alternatively, it can all be said within the app call: -[x] `summarizer --vertical --days=1,4 https://www.gitsmth.com/my_company/my_repo.git`

To test the calls easily, use either:

- `lua init.lua $(cat ./test)`
- `xargs lua init.lua < ./test`

## Issues

- Package `lsqlite3complete` has to be installed system-wide, so the better thing to do is use a docker container
- It also has to be installed via `luarocks`

## Monetization

- For the web service, free-tier stores only the history for the current week (to save space)
- Make the service cheap enough (possibly 2 USD / EUR)
- Direct access to the latex file can be charged extra (5 USD plan?)
- Custom layouts can be charged extra (10 USD plan?)
- Lets make it fully self-hosted

## Commit template

Commits don't have to be single line, but the very first line has to contain the necessary information to determine the type of commit and stage of implementation. The following example denotes how to read it:

`p.impl: Parser for TOML configuration now correctly identifies language setting`

The first letter (`p` in the example) tells us the `status` of the task. They track directly to common Jira-esque task status. The following list explains them:

- `p`: In progress
- `i`: Just initialized
- `t`: In testing/evaluation
- `b`: Blocked
- `d`: Done

They must be then followed by a dot `.` to chain into the `type` of work done in the commit (`impl` in the example):

- `asset` - For asset aditions
- `bug` - For bugfixes
- `chore` - Chore (clean-ups, making code adhere to style-guide, etc)
- `config` - Project settings
- `dependency` - Dependencies (new and updates)
- `doc` - Documentation (readmes and docstrings)
- `env` - Environment details
- `errors` - Error handlers
- `hotfix` - For small changes
- `implementation` - Implementation (for new features)
- `performance` - Works on improving performance
- `pluging` - Plugins (new and updates)
- `refactor` - Refactors in general (modularization, design pattern implementation, etc)
- `removal` - Removal
- `test` - Test creation, refactor or update
- `update` - Updates implementation to newer version

Other types of work done can be implemented in the future. Those are then followed by a double-colon, after which comes the commit message, either as a one-liner or as the commit title and the message. As long as the first things are the `status` and `type` of the work done it'll be parsed correctly.
