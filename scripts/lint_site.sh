#!/bin/bash

FAILED=0

echo -ne "mdspell "
mdspell --version
echo -ne "mdl "
mdl --version

# This performs spell checking and style checking over markdown files in a content
# directory. 
check_content() {

    regexp="[[:digit:]]\+$"

    PR_NUMBER=`echo $CIRCLE_PULL_REQUEST | grep -o $regexp`

    url="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pulls/$PR_NUMBER"

    target_branch=$(curl -s -X GET -G $url | jq '.base.ref' | tr -d '"')

    echo "Resetting $target_branch to where the remote version is..."

    git checkout -q $target_branch

    git reset --hard -q origin/$target_branch

    git checkout -q $CIRCLE_BRANCH

    echo "Getting list of changed files..."
    changed_files=$(git diff --name-only $target_branch..$CIRCLE_BRANCH -- '*.md')

    echo ${changed_files[@]}

    exit 0

    for month in $(ls 2019)
    do  
        if [[ ${month} -ge "05" ]]; then
           mdspell en --ignore-acronyms --ignore-numbers --no-suggestions --report "2019/${month}/*/*.md"
        fi
    done
    
    if [[ "$?" != "0" ]]
    then
        FAILED=1
    fi

    for month in $(ls 2019)
    do  
        if [[ ${month} -ge "05" ]]; then
            mdl --ignore-front-matter --style mdl_style.rb "2019/${month}"
        fi
    done
   
    if [[ "$?" != "0" ]]
    then
        FAILED=1
    fi
}

check_content . --en-us

if [[ ${FAILED} -eq 1 ]]
then
    echo "LINTING FAILED"
    exit 1
fi
