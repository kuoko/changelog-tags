#!/usr/bin/env bash
DEPLOY_BRANCH=$1

if [[ 'master-built' = ${DEPLOY_BRANCH} ]]; then

    git checkout master
    git pull

    export LAST_TAG=$(git describe --tags `git rev-list --tags --max-count=1`)
    export CHANGE_LOG=$(git log ${LAST_TAG}..origin/preprod --oneline)

    export LOG=$(git log -1)

    NEW_TAG=$(date +'%Y-%d-%m/%H-%M-%S')
    git tag -a ${NEW_TAG} -m ${NEW_TAG} -m "${LOG}" -m "${CHANGE_LOG}"
    git push origin tag ${NEW_TAG}
fi