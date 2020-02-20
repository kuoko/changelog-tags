#!/usr/bin/env bash
DEPLOY_BRANCH=$1
COMMIT_HASH=$2
TAG=$(date +'%Y-%d-%m/%H-%M-%S')

echo  ${TAG};

if [[ 'master-built' = ${DEPLOY_BRANCH} ]]; then
      git push
      git tag -a ${TAG} -m ${TAG}$'\nComment line 1\nComment line 2'
      git push origin tag ${TAG}
fi