#!/bin/bash
#set -xv

# shellcheck disable=SC1091
source /opt/ansible/env38/bin/activate

#sphinx-quickstart
sphinx-build -b html ./ _build/
# or make html
RC=$?
if [ ${RC} -ne 0 ]; then
  echo ""
  echo -e "${red} ${head_skull} Sorry, sphinx failed ${NC}"
  #exit 1
fi

exit 0
