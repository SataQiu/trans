#!/bin/bash

FAILED=0

echo -ne "mdspell "
mdspell --version
echo -ne "mdl "
mdl --version

# This performs spell checking and style checking over markdown files in a content directory. 
check_content() {

    # only check pull request, skip others
    if [[ -z $CIRCLE_PULL_REQUEST ]]; then
        echo "Skip, only check pull request "
        exit 0
    fi

    # parse target branch
    url="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pulls/$CIRCLE_PR_NUMBER"
    target_branch=$(curl -s -X GET -G $url | jq '.base.ref' | tr -d '"')
    local_branch=$(curl -s -X GET -G $url | jq '.head.ref' | tr -d '"')

    # get changed files of this PR
    git checkout -b $local_branch
    git checkout -q $target_branch
    git reset --hard -q origin/$target_branch
    git checkout -q $local_branch

    echo "Getting list of changed files..."
    changed_files=$(git diff --name-only $target_branch..$local_branch -- '*.md')
    echo ${changed_files[@]}

    for file in ${changed_files}
    do  
        # spell check
        mdspell --en-us --ignore-acronyms --ignore-numbers --no-suggestions --report ${file}
        if [[ "$?" != "0" ]]
        then
            FAILED=1
        fi

        # markdown format check
        mdl --ignore-front-matter --style mdl_style.rb ${file}
        if [[ "$?" != "0" ]]
        then
            FAILED=1
        fi
    done
}

check_content

if [[ ${FAILED} -eq 1 ]]; then
    echo "LINTING FAILED"
    exit 1
fi
