
bootstrap:
	scripts/bootstrap.sh desktop

attach:
	scripts/attach.sh
	terraform init

bootstrap_beta:
	scripts/bootstrap.sh beta

bootstrap_prod:
	scripts/bootstrap.sh prod

deploy:
	@echo "Attempting to deploy project using bootstrap settings in ../.bootstrap_settings/apply.tfvars"
	terraform apply --var-file=../.bootstrap_settings/apply.tfvars
