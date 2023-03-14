#!/usr/bin/env bash

npm install --save-dev @commitlint/{cli,config-conventional,prompt-cli}

echo "
## Add scripts in package.json
\"scripts\": {
  \"commit\": "commit"
}

## Add git hook (examples: husky) in package.json
\"husky\": {
  \"hooks\": {
    \"commit-msg\": \"commitlint -E HUSKY_GIT_PARAMS\"
  }
}
"
