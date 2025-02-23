build:
	cd libs/policyengine-fastapi && make build
	cd libs/policyengine-api && make build
	cd projects/policyengine-api-full && make build
	cd projects/policyengine-api-simulation && make build

dev-api-full:
	echo "Starting API (full) in dev mode"
	cd projects/policyengine-api-full && make dev

dev-api-simulation:
	echo "Starting API (simulation) in dev mode"
	cd projects/policyengine-api-simulation && make dev

dev:
	echo "Starting APIs (full+simulation) in dev mode"
	make dev-api-full & make dev-api-simulation

deploy-desktop-api-full: terraform/.bootstrap_settings
	echo "Deploying API (full) to desktop"
	cd projects/policyengine-api-full && make deploy
	
deploy-desktop-services: terraform/.bootstrap_settings
	echo "Deploying services"
	cd terraform/infra-policyengine-api && make deploy

deploy-desktop: deploy-desktop-api-full deploy-desktop-services