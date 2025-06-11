build: remove_artifacts install checkformat pyright generate test 

remove_artifacts:
	rm -rf artifacts

install:
	uv sync --extra test --extra build

format:
	uv run black .

checkformat:
	uv run black --check src

pyright:
	uv run pyright 

test:
	uv run pytest

generate:
	echo "No code generation target defined"
