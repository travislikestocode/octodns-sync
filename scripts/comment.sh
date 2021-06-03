#!/bin/bash
# Add pull request comment

_planfile="${GITHUB_WORKSPACE}/octodns-sync.plan"

if [ "${ADD_PR_COMMENT}" = "Yes" ]; then
  echo "INFO: \$ADD_PR_COMMENT is 'Yes'."
  if [[ ("${GITHUB_EVENT_NAME}" = "pull_request") || ("${GITHUB_EVENT_NAME}" = "pull_request") ]]; then
    if [ -z "${PR_COMMENT_TOKEN}" ]; then
      echo "FAIL: \$PR_COMMENT_TOKEN is not set."
      exit 1
    fi
  else
    echo "SKIP: \$GITHUB_EVENT_NAME is not 'pull_request'."
    exit 0
  fi
  # Construct the comment body
  _sha="$(git log -1 --format='%h')"
  _header="## octoDNS Plan for ${_sha}"
  _footer="Automatically generated by octodns-sync"
  _body="${_header}

$(cat "${_planfile}")

${_footer}"
  # Post the comment
  # TODO: Rewrite post to use gh rather than python3
  _user="github-actions" \
  _token="${PR_COMMENT_TOKEN}" \
  _body="${_body}" \
  GITHUB_EVENT_PATH="${GITHUB_EVENT_PATH}" \
  python3 -c "import requests, os, json
comments_url = json.load(open(os.environ['GITHUB_EVENT_PATH'], 'r'))['pull_request']['comments_url']
response = requests.post(comments_url, auth=(os.environ['_user'], os.environ['_token']), json={'body':os.environ['_body']})
print(response)"

fi
