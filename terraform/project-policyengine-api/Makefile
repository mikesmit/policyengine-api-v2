deploy:
	terraform apply -var-file=apply.tfvars

bootstrap:
	terraform init && terraform apply -var-file=apply.tfvars && terraform init
