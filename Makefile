REPO   := amancevice/terraform-aws-facebook-gcal-sync
STAGES := lock zip validate
PYTHON := $(shell cat .python-version | cut -d'.' -f1,2)

.PHONY: default clean clobber $(STAGES)

default: Pipfile.lock package.zip validate

.docker:
	mkdir -p $@

.docker/lock: Pipfile
.docker/zip: .docker/lock lambda.py
.docker/validate: .docker/zip
.docker/%: | .docker
	docker build \
	--build-arg PYTHON=$(PYTHON) \
	--iidfile $@ \
	--tag $(REPO):$* \
	--target $* \
	.

Pipfile.lock: .docker/lock
	docker run --rm --entrypoint cat $$(cat $<) $@ > $@

package.zip: .docker/zip
	docker run --rm --entrypoint cat $$(cat $<) $@ > $@

clean:
	rm -rf .docker

clobber: clean
	docker image ls $(REPO) --quiet | xargs docker image rm --force

$(STAGES): %: .docker/%
