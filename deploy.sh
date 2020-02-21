#!/usr/bin/env bash
DEPLOY_BRANCH=$1
COMMIT_HASH=$2
TAG=$(date +'%Y-%d-%m/%H-%M-%S')

if [[ 'master-built' = ${DEPLOY_BRANCH} ]]; then
    git checkout master
    export LOG=$(git log -1 --pretty=%B)
    git tag -a ${TAG} -m ${TAG} -m "${LOG}"
    git push origin tag ${TAG}
fi