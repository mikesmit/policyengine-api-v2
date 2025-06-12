include ./makefile.env
include ../../server_common.local.mk

test:
	echo "SKIPPING TESTS"

generate:
	mkdir -p artifacts
	cd src && uv run python -m policyengine_api_simulation.generate_openapi > ../artifacts/openapi.json
	mvn -f ./generate_clients.pom.xml clean generate-sources
