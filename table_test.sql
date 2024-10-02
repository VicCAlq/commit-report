-- ["remotes/origin/main"] = {
--    {
--      author_email = "alexmavr@users.noreply.github.com",
--      author_name = "Alex Mavrogiannis",
--      branch = "main",
--      commit = "f40bb398f6423ae82386820f0abfe279045771b7",
--      date = "Tue Oct 1 15:45:43 2024 -0700",
--      description = "Stop model before deletion if loaded (fixed #6957) (#7050)",
--      time = 1727808343
--    },
-- }

CREATE TABLE test_repo(
  commit VARCHAR(50) NOT NULL UNIQUE PRIMARY KEY,
  time INT NOT NULL,
  author_name VARCHAR(200) NOT NULL,
  author_email VARCHAR(200) NOT NULL,
  branch VARCHAR(200) NOT NULL,
  date TEXT NOT NULL,
  description TEXT NOT NULL,
)
