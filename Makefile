POETRY_DIRS = libs/policyengine-fastapi \
              libs/policyengine-api \
              projects/policyengine-api-household

install:
	@for dir in $(POETRY_DIRS); do \
		echo "Installing dependencies in $$dir..."; \
		cd $$dir && poetry install && cd -; \
	done
