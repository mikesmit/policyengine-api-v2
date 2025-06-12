#!/bin/bash

script_dir=$(dirname "$0")
cd ${script_dir}
uv install &> /dev/null
uv run python scripts/dump_package_version.py uv.lock "$@"
