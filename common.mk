build: remove_artifacts install checkformat pyright generate test 

remove_artifacts:
	rm -rf artifacts

install:
	uv sync --extra test --extra build

checkformat:
	@dirs=""; \
	[ -d "src" ] && dirs="$$dirs src"; \
	[ -d "tests" ] && dirs="$$dirs tests"; \
	if [ -n "$$dirs" ]; then \
		uv run black --check $$dirs; \
	else \
		echo "Neither 'src' nor 'tests' directory found. Skipping Black formatting."; \
	fi

format:
	@dirs=""; \
	[ -d "src" ] && dirs="$$dirs src"; \
	[ -d "tests" ] && dirs="$$dirs tests"; \
	if [ -n "$$dirs" ]; then \
		echo "Running Black on:$$dirs"; \
		uv run black $$dirs; \
	else \
		echo "Neither 'src' nor 'tests' directory found. Skipping Black formatting."; \
	fi

pyright:
	uv run pyright 

test:
	uv run pytest

generate:
	echo "No code generation target defined"

update:
	uv lock --upgrade
