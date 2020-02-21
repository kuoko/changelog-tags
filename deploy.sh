#!/usr/bin/env bash
DEPLOY_BRANCH=$1
COMMIT_HASH=$2
TAG=$(date +'%Y-%d-%m/%H-%M-%S')

if [[ 'master-built' = ${DEPLOY_BRANCH} ]]; then
#      git log 0b05921 --pretty=%B
#      echo "---"
#      git log ff2c048a --pretty=%B
      export LOG=$(git log -1)
#      export LOG=$(git log ${COMMIT_HASH})
      echo ${LOG};

#      git tag -a ${TAG} -m ${COMMIT_HASH}${LOG}
#      git push origin tag ${TAG}
fi