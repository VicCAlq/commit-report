-- ["remotes/origin/main"] = {
--    {
--      author_email = "mxyng@pm.me",
--      author_name = "Michael Yang",
--      branch = "mxyng/mllama",
--      commit = "3e8d03f8f6b723f5d3df90ab4db0e6d6983029f4",
--      date = "2024-09-30 11:13:49.000",
--      description = "integrate mllama.cpp to server.cpp",
--      time = 1727705629
--    },
-- }

CREATE TABLE IF NOT EXISTS test_repo (
commit_hash VARCHAR(50) NOT NULL UNIQUE PRIMARY KEY,
unix_time INT NOT NULL,
author_name VARCHAR(200) NOT NULL,
author_email VARCHAR(200) NOT NULL,
branch VARCHAR(200) NOT NULL,
date TEXT NOT NULL,
description TEXT NOT NULL
);

INSERT INTO test_repo (
commit_hash, 
unix_time, 
author_name, 
author_email, 
branch, 
date, 
description
) VALUES (
'3e8d03f8f6b723f5d3df90ab4db0e6d6983029f4',
1727705629,
'Michael Yang',
'mxyng@pm.me',
'mxyng/mllama',
'2024-09-30 11:13:49.000',
'integrate mllama.cpp to server.cpp'
);
