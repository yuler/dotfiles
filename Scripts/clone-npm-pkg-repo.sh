#!/usr/bin/env bash

# Dependencies
# 1. [json](https://www.npmjs.com/package/json)
# 2. [hub](https://github.com/github/hub)

main() {
  local package=$1
  local api="curl http://registry.npm.taobao.org/$package"
  local url=$(curl -s $api | json repository.url)

  echo "url: $url"

  url="${url#git:\/\/github.com\/}"
  url="${url#https:\/\/github.com\/}"
  local repo="${url%.git}"

  echo "repo: $repo"
  local target="${repo/\//@}"

  echo "target: $target"

  set -x
  hub clone $repo $target
  set +x
}

main "$@"