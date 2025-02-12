POETRY_DIRS = libs/policyengine-fastapi \
              libs/policyengine-api \
              projects/policyengine-api-main \
			  projects/policyengine-api-simulation \

install:
	@for dir in $(POETRY_DIRS); do \
		echo "Installing dependencies in $$dir..."; \
		cd $$dir && poetry install cd -; \
	done

install-all:
	poetry install

dev-simulation-api:
	cd projects/policyengine-api-simulation && poetry run fastapi dev src/policyengine_simulation_api/main.py