#!/bin/bash
set -eu

WORKING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${WORKING_DIR}/step-0-color.sh"

cd "${WORKING_DIR}/../"

echo -e "${magenta} Cleaning started. ${NC}"

#pwd

#package-lock.json yarn.lock
#rm -Rf npm/ .node_cache/ .node_tmp/ .tmp/ .bower/ bower_components/ node/ node_modules/ .sass-cache/ .scannerwork/ target/ target-eclipse/ build/ phantomas/ dist/ docs/groovydocs/ docs/js/ docs/partials/ site/ coverage/
#docs/
#dist/bower_components/ dist/fonts/

rm -Rf _build/ build/ .eggs/ .toxs/ dist/ output/pytest-report.xml .coverage output/coverage.xml docs/_build/ docs/_static/* .tox/ .scannerwork/ .pytest_cache/ output/htmlcov/ cprofile out/ report/

rm -f checkstyle.xml docker-dockerfilelint.json overview.html ansible-lint.* ./*.log
rm -f package-lock.json Pipfile.lock  || true

find . -maxdepth 2 -mindepth 2 -regextype posix-egrep -type d -regex '.+/.*egg-info' -exec rm -rf {} \;
find . -maxdepth 2 -mindepth 2 -regextype posix-egrep -type d -regex '.*__pycache__.*' -exec rm -rf {} \;
#find hooks -type f -name "*.pyc" -delete

cd "${WORKING_DIR}"

echo -e "${green} Cleaning DONE. ${NC}"

exit 0
