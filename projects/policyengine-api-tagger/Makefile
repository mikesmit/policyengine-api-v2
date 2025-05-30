build: test

install:
	poetry install

test: install
	poetry install --with test
	poetry run pytest

format: 
	black . -l 79
