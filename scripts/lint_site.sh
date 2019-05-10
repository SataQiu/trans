#!/bin/bash

FAILED=0

echo -ne "mdspell "
mdspell --version
echo -ne "mdl "
mdl --version

# This performs spell checking and style checking over changed markdown files
check_pull_request_content() {

    # only check pull request, skip others
    if [[ -z ${CIRCLE_PULL_REQUEST} ]]; then
        echo "Skip, only check pull request."
        exit 0
    fi

    # parse target/local branch
    URL="https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/pulls/${CIRCLE_PR_NUMBER}"
    TARGET_BRANCH=$(curl -s -X GET -G ${URL} | jq '.base.ref' | tr -d '"')
    LOCAL_BRANCH=$(curl -s -X GET -G ${URL} | jq '.head.ref' | tr -d '"')

    # get changed files of this PR
    git checkout -q -b ${LOCAL_BRANCH}
    git checkout -q ${TARGET_BRANCH}
    git reset --hard -q origin/${TARGET_BRANCH}
    git checkout -q ${LOCAL_BRANCH}

    echo "Getting list of changed markdown files ..."
    CHANGED_FILES=$(git diff --name-only ${TARGET_BRANCH}..${LOCAL_BRANCH} -- '*.md')
    echo ${CHANGED_FILES[@]}

    # do spell check
    echo "Check spell ..."
    mdspell --en-us --ignore-acronyms --ignore-numbers --no-suggestions --report ${CHANGED_FILES[@]}
    if [[ "$?" != "0" ]]
    then
        echo "Spell check failed."
        echo "Feel free to add the word(s) into our glossary file '.spelling'"
        FAILED=1
    fi

    # do markdown format check
    echo "Check markdown format ..."
    mdl --ignore-front-matter --style mdl_style.rb ${CHANGED_FILES[@]}
    if [[ "$?" != "0" ]]
    then
        FAILED=1
    fi
}

check_pull_request_content

if [[ ${FAILED} -eq 1 ]]; then
    echo "LINTING FAILED"
    exit 1
fi
