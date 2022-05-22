###################
 Quality & Testing
###################

*************
 Commit Hook
*************

Can be run using ``pre-commit`` tool (http://pre-commit.com/):

.. code:: bash

   pre-commit install

First time run

.. code:: bash

   git checkout this repo hooks/

THEN

.. code:: bash

   cp hooks/* .git/hooks/

OR

.. code:: bash

   rm -Rf ./.git/hooks/ && ln -s ../hooks ./.git/hooks

.. code:: bash

   pre-commit run --all-files

   SKIP=ansible-lint git commit -am 'Add key'
   git commit -am 'Add key' --no-verify

*******************************
 Generate sphinx documentation
*******************************

.. code:: bash

   sphinx-build -b html ./docs docs/_build/
