This is the monorepo containing all our common api code and FastAPI-based WSGI applications for
the new policyengine api v2.

## Structure
* libs - directory containing packages that are dependencies of other packages
* projects - directory containing packages that are intended to be deployed as applications.

## Build tools
All packages are managed via poetry. Tests are run via pytest.

## Setup 
1. install [poetry](https://python-poetry.org/docs/)
2. run ``make install``

## Testing
either
* run ``make test`` to run all tests or
* go into the target directory and run
  * ``source .venv/bin/activate``
  * ``pytest``

## Mono repo structure
* /libraries - are common code that is intended to be build and consumed as packages
* /applications - applications which are intended to be built into and deploy as part of docker containers.

## library package structure
* /src - contains the actual code
  * /policyengine - namespace for our package (no ``__init__.py``)
* /tests - contains the tests
  * conftest.py - automatically loaded test fixtures.
  * /common - common code used by the other tests
* poetry.toml - poetry settings applied to this project alone
* pyproject.toml - definition of the package and dependencies.

## project package structure
Projects are intended to be run, not packaged and distributed.
