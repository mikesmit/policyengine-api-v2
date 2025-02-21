build:
	cd libs/policyengine-fastapi && make build
	cd libs/policyengine-api && make build
	cd projects/policyengine-api-full && make build
	cd projects/policyengine-api-simulation && make build

dev-api-full:
	cd projects/policyengine-api-full && make dev

dev-api-simulation:
	cd projects/policyengine-api-simulation && make dev

dev:
	make dev-api-full & make dev-api-simulation