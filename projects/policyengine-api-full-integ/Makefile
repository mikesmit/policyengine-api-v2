integ-test:
	poetry install
	$(if $(ACCESS_TOKEN),INTEG_TEST_ACCESS_TOKEN='$(ACCESS_TOKEN)') \
	$(if $(FULL_API_URL),INTEG_TEST_BASE_URL='$(FULL_API_URL)') \
	poetry run pytest
