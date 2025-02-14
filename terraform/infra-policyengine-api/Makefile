PROJECT_ID?=PROVIDE PROJECT ID
REGION?=us-central1
REPO?=api-v2
TAG?=desktop

deploy:
	terraform apply -var-file=apply.tfvars -var container_image=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/policyengine-api-household:${TAG} -var project_id=${PROJECT_ID}

init:
	terraform init -backend-config=backend.tfvars
