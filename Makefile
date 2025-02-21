build:
	cd libs/policyengine-fastapi && make build
	cd libs/policyengine-api && make build
	cd projects/policyengine-api-household && make build
	cd projects/policyengine-simulation-api && make build