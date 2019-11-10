#!/usr/bin/env bash

# From: https://github.com/npm/pull
# Update it for GitLab

# Dependencies
# 1. [json](https://www.npmjs.com/package/json)
# 2. env $GITLAB_TOKEN

# Land a pull request
# Creates a PR-### branch, pulls the commits, opens up an interactive rebase to
# squash, and then annotates the commit with the changelog goobers
#
# Usage:
#   pr <url|number> [<upstream remote>=origin]

main () {
  if [ "$1" = "finish" ]; then
    shift
    finish "$@"
    return $?
  fi

  local url="$(prurl "$@")"
  local num=$(basename $url)

  if ! [[ $num =~ ^[0-9]+$ ]]; then
    echo "usage:"
    echo "from target branch:"
    echo "  $0 <url|number> [<upstream remote>=origin]"
    echo "from PR branch:"
    echo "  $0 finish <target branch>"
    exit 1
  fi

  local prpath="${url#git@gitlab.com:}"
  local repo=${prpath%/merge_requests/$num}
  local prweb="https://gitlab.com/$prpath"
  local root="$(prroot "$url")"

  local api="https://gitlab.com/api/v4/projects/${repo/\//%2F}/merge_requests/${num}?access_token=$GITLAB_TOKEN"
  local data=$(curl -s $api)
  local user=$(echo $data | json author.username)
  local prbranch="$(echo $data | json source_branch)"
  local prtarget="$(echo $data | json target_branch)"

  git checkout prtarget

  local ref="$(prref "$url" "$root")"
  local curhead="$(git show --no-patch --pretty=%H HEAD)"
  local curbranch="$(git rev-parse --abbrev-ref HEAD)"
  local cleanlines

  IFS=$'\n' cleanlines=($(git status -s -uno))
  if [ ${#cleanlines[@]} -ne 0 ]; then
    echo "working dir not clean" >&2
    IFS=$'\n' echo "${cleanlines[@]}" >&2
    echo "aborting PR merge" >&2
  fi

  # ok, ready to rock
  branch=PR-$num
  if [ "$prbranch" == "$branch" ]; then
    echo "already on $branch, you're on your own" >&2
    return 1
  fi

  me=$(git config gitlab.user)
  if [ "$me" == "" ]; then
    echo "run 'git config --add gitlab.user <username>'" >&2
    return 1
  fi

  exists=$(git show --no-patch --pretty=%H $branch 2>/dev/null)
  if [ "$exists" == "" ]; then
    git fetch origin $prbranch:$branch
    git checkout $branch
  else
    git checkout $branch
    git pull --rebase origin $prbranch
  fi

  git rebase -i $prbranch # squash and test

  echo ""
  echo ""
  echo "====="
  echo "review finished run:"
  echo "$0 finish"
  echo "====="
}

# add the PR-URL to the last commit, after squashing
finish () {
  # if [ $# -eq 0 ]; then
  #   echo "Usage: $0 finish <branch> (while on a PR-### branch)" >&2
  #   return 1
  # fi

  # local curbranch="$2"
  local ref=$(cat .git/HEAD)
  local prnum
  case $ref in
    "ref: refs/heads/PR-"*)
      prnum=${ref#ref: refs/heads/PR-}
      ;;
    *)
      echo "not on the PR-### branch any more!" >&2
      return 1
      ;;
  esac

  local me=$(git config gitlab.user || git config user.name)
  if [ "$me" == "" ]; then
    echo "run 'git config --add gitlab.user <username>'" >&2
    return 1
  fi

  set -x

  local url="$(prurl "$prnum")"
  local num=$prnum
  local prpath="${url#git@gitlab.com:}"
  local repo=${prpath%/merge_requests/$num}
  repo="${repo/\//%2F}"
  local prweb="https://gitlab.com/$prpath"
  local root="$(prroot "$url")"

  local api="https://gitlab.com/api/v4/projects/$repo/merge_requests/$prnum?access_token=$GITLAB_TOKEN"
  local data=$(curl -s $api)
  local user=$(echo $data | json author.username)
  local prbranch="$(echo $data | json source_branch)"

  local lastmsg="$(git log -1 --pretty=%B)"
  local newmsg="${lastmsg}
PR-URL: ${prweb}
Credit: @${user}
Close: !${num}
Reviewed-by: @${me}
"
  git commit --amend --no-verify -m "$newmsg" 

  git push -o merge_request.merge_when_pipeline_succeeds \
    -o merge_request.remove_source_branch \
    -f origin PR-$prnum:$prbranch

  curl -X PUT \
    -H 'Content-Type: application/json' \
    -d '{"merge_when_pipeline_succeeds": true, "should_remove_source_branch": true}' \
    -s https://gitlab.com/api/v4/projects/$repo/merge_requests/$prnum/merge?access_token=$GITLAB_TOKEN
  
  set +x
}

prurl () {
  local url="$1"
  if [ -z "$url" ] && type pbpaste &>/dev/null; then
    url="$(pbpaste)"
  fi
  if [[ "$url" =~ ^[0-9]+$ ]]; then
    local us="$2"
    if [ -z "$us" ]; then
      us="origin"
    fi
    local num="$url"
    local o="$(git config --get remote.${us}.url)"
    url="${o}"
    # @TODO
    # url="${url#(git:\/\/|https:\/\/)}"
    url="${url#https:\/\/}"
    url="${url#git@}"
    url="${url%.git}"
    url="${url#gitlab.com\/}"
    url="https://gitlab.com/${url}/merge_requests/$num"
  fi
  url=${url%/commits}
  url=${url%/diffs}
  url="$(echo $url | perl -p -e 's/#note_-[0-9]+$//g')"

  p='^https:\/\/gitlab.com\/[^\/]+\/[^\/]+\/merge_requests\/[0-9]+$'

  if ! [[ "$url" =~ $p ]]; then
    echo "Usage:"
    echo "  $0 <pull req url>"
    echo "  $0 <pull req number> [<remote name>=origin]"
    type pbpaste &>/dev/null &&
      echo "(will read url/id from clipboard if not specified)"
    exit 1
  fi
  url="${url/https:\/\/gitlab\.com\//git@gitlab.com:}"

  echo "$url"
}

prroot () {
  local url="$1"
  echo "${url/\/pull\/+([0-9])/}"
}

prref () {
  local url="$1"
  local root="$2"
  echo "refs${url:${#root}}/head"
}

main "$@"
