REPO           := amancevice/$(shell basename $$PWD)
PYTHON_VERSION := 3.8

ENDPOINT = http://$$(REPO=$(REPO) docker-compose port lambda 8080)/2015-03-31/functions/function/invocations

all: validate

clean: down
	rm -rf package.iid

clobber: clean
	REPO=$(REPO) docker-compose down --rmi all --volumes

down:
	REPO=$(REPO) docker-compose down

shell: .env Dockerfile.iid
	REPO=$(REPO) docker-compose run --rm shell

up: .env Dockerfile.iid
	REPO=$(REPO) docker-compose up --detach lambda
	@echo $(ENDPOINT)

validate: package.zip .terraform.lock.hcl
	terraform fmt -check
	AWS_REGION=us-east-1 terraform validate

zip: package.zip

.PHONY: all clean clobber down shell up validate zip

package.zip: Dockerfile.iid Pipfile.lock
	docker run --rm --entrypoint cat $(REPO) $@ > $@

Pipfile.lock: Pipfile | Dockerfile.iid
	docker run --rm --entrypoint cat $(REPO) $@ > $@

Dockerfile.iid: Dockerfile Pipfile index.py
	docker build --build-arg PYTHON_VERSION=$(PYTHON_VERSION) --iidfile $@ --tag $(REPO) .

.terraform.lock.hcl:
	terraform init
