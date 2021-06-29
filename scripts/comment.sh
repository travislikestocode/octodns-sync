#!/bin/bash
# Add pull request comment

_logfile="${GITHUB_WORKSPACE}/octodns-sync.log"
_planfile="${GITHUB_WORKSPACE}/octodns-sync.plan"
_doit=$DOIT

if [ "${ADD_PR_COMMENT}" = "Yes" ]; then
  echo "INFO: \$ADD_PR_COMMENT is 'Yes'."
  if [ -z "${PR_COMMENT_TOKEN}" ]; then
    echo "FAIL: \$PR_COMMENT_TOKEN is not set."
    exit 1
  fi
fi

if [ "${_doit}" = "--doit" ]; then
  _jobtype="deploy"
  _emoji=":shipit:"
  _syncoutput="
## octodns-sync shortened output:
\`\`\`txt
$(grep -Ev 'plan|populate|zone|sources' "${_logfile}")
\`\`\`
"
else
  _jobtype="dry run"
  _emoji=":test_tube:"
  _syncoutput=""
fi

# Construct the comment body
_sha="$(git log -1 --format='%h')"
_header="## ${_emoji} OctoDNS <ins>${_jobtype}</ins> for ${_sha} using ${OCTO_CONFIG_PATH}"
_body="${_header}

$(cat "${_planfile}")
$(echo "$_syncoutput")"

if [[ ("${GITHUB_EVENT_NAME}" = "pull_request") || ("${GITHUB_EVENT_NAME}" = "pull_request_target") ]]; then
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

# https://github.community/t/set-output-truncates-multiline-strings/16852/4
_body="${_body//$'\n'/\\n}"
echo "::set-output name=comment_body::$_body"  
