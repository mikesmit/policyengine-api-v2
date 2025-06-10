build: install checkformat pyright test

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
