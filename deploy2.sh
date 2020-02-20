#!/usr/bin/env bash
REPO_SSH_URL=$1
COMMIT_HASH=$2
CURRENT_BRANCH=$3
WORKING_DIR=$4
BUILD_DIR="/tmp/vip-go-build-$(date +%s)"
DEPLOY_SUFFIX="${VIP_DEPLOY_SUFFIX:--built}"
DEPLOY_BRANCH="${CURRENT_BRANCH}${DEPLOY_SUFFIX}"
DEPLOY_PATH=$5

# Run some checks

if [[ ${CURRENT_BRANCH} == *${DEPLOY_SUFFIX} ]]; then
    echo "NOTICE: Attempting to build from branch ${CURRENT_BRANCH} to deploy ${DEPLOY_BRANCH}, it seems like a recursion so aborting."
	exit 1
fi

if [ -f .deployignore ]; then
	mv .deployignore .gitignore
else
    echo "NOTICE: Attempting to replace .gitignore with not existing .deployignore"
    exit 1;
fi

# Install dependencies through composer
docker-compose up -d
docker-compose run --rm composer install --no-scripts
docker-compose run --rm composer show > installed-plugins.txt
if cmp --silent metro-plugins.txt installed-plugins.txt; then
	echo "Composer has successfully installed all the dependencies"
else
  echo "NOTICE: Composer failed during install composer dependencies"
  exit 1;
fi

# Install Node and dependencies

. ${DEPLOY_PATH}
export NODE_VERSION=10
. setup-node

# . ~/.nvm/nvm.sh
# nvm install 10
cd themes/metro-parent

if type npm >/dev/null 2>&1; then
   npm install --unsafe-perm=true
   npm install -g gulp
else
   echo "NOTICE: npm: command not found"
   exit 1;
fi

# Build

if type gulp >/dev/null 2>&1; then
    gulp build
else
   echo "NOTICE: gulp: command not found"
   exit 1;
fi

rm -r node_modules

# Build: Gutenberg
if test -f lib/plugins/metro-gutenberg/package.json; then
  cd lib/plugins/metro-gutenberg
  npm install --unsafe-perm=true
  npm run build
  rm -rf node_modules
  cd ../../../
else
  echo "NOTICE: metro-gutenberg package.json not found, continuing without building for gutenberg..."
fi

cd ../../

# Commit and push the build

echo "Deploying ${CURRENT_BRANCH} to ${DEPLOY_BRANCH}"

git init "${BUILD_DIR}"
cd "${BUILD_DIR}"

git remote add origin ${REPO_SSH_URL}

if [[ 0 = $(git ls-remote --heads "${REPO_SSH_URL}" "${DEPLOY_BRANCH}" | wc -l) ]]; then
	echo -e "\nCreating a ${DEPLOY_BRANCH} branch..."
	git checkout --quiet --orphan "${DEPLOY_BRANCH}"
else
	echo "Using existing ${DEPLOY_BRANCH} branch"
	git fetch origin "${DEPLOY_BRANCH}" --depth=1
	git checkout --quiet "${DEPLOY_BRANCH}"
fi

echo "Syncing files..."

rsync --delete -a "${WORKING_DIR}/" "${BUILD_DIR}" --exclude='.git/'

git add -A .

git status

git commit --author="mol-teamcity <fe@mailonline.co.uk>" -am "${COMMIT_HASH}-build"

if [[ 0 = $(git ls-remote --heads "${REPO_SSH_URL}" "${DEPLOY_BRANCH}" | wc -l) ]]; then
	if git push --set-upstream origin "${DEPLOY_BRANCH}"
    then
      echo "git --set-upstream ${DEPLOY_BRANCH} push succeeded."
    else
      echo "git --set-upstream ${DEPLOY_BRANCH} push failed."
      exit 1;
    fi
else
	if git push origin "${DEPLOY_BRANCH}"
    then
      echo "git push ${DEPLOY_BRANCH} succeeded."
    else
      echo "git push ${DEPLOY_BRANCH} failed."
      exit 1;
    fi
fi

if [[ 'master-built' = ${DEPLOY_BRANCH}  ]]; then

fi


rm -r "${BUILD_DIR}"