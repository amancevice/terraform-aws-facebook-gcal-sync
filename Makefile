ENDPOINT = http://$$(REPO=$(REPO) docker-compose port lambda 8080)/2015-03-31/functions/function/invocations

all: validate down

build: .env
	docker-compose build

clean: down

clobber: clean
	docker-compose down --rmi all --volumes

down: .env
	docker-compose down

up: .env | build
	docker-compose up --detach test

validate: package.zip | .terraform
	terraform fmt -check
	AWS_REGION=us-east-1 terraform validate

zip: package.zip

.PHONY: all build clean clobber down shell up validate zip

package.zip: Pipfile.lock | build
	docker-compose run --rm --entrypoint cat build $@ > $@

Pipfile.lock: Pipfile | build
	docker-compose run --rm --entrypoint cat build $@ > $@

.terraform:
	terraform init

.env:
	touch $@
