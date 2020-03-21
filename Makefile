REPO      := amancevice/terraform-aws-facebook-gcal-sync
STAGES    := lock zip validate
CLEANS    := $(foreach STAGE,$(STAGES),clean-$(STAGE))
PYTHON    := $(shell cat .python-version | cut -d'.' -f1,2)
TIMESTAMP := $(shell date +%s)

.PHONY: default clean clobber $(CLEANS)

default: Pipfile.lock package.zip .docker/validate

.docker:
	mkdir -p $@

.docker/lock: Pipfile
.docker/zip: .docker/lock lambda.py
.docker/validate: .docker/zip
.docker/%: | .docker
	docker build \
	--build-arg PYTHON=$(PYTHON) \
	--iidfile $@-$(TIMESTAMP) \
	--tag $(REPO):$* \
	--tag $(REPO):$*-$(TIMESTAMP) \
	--target $* \
	.
	cp $@-$(TIMESTAMP) $@

Pipfile.lock: .docker/lock
	docker run --rm --entrypoint cat $$(cat $<) $@ > $@

package.zip: .docker/zip
	docker run --rm --entrypoint cat $$(cat $<) $@ > $@

clean: $(CLEANS) | .docker
	rm -rf .docker

clobber: clean
	docker image ls $(REPO) --quiet | xargs docker image rm --force

$(CLEANS): clean-%:
	docker image ls $(REPO):$*-* --format '{{.Repository}}:{{.Tag}}' | xargs docker image rm
	rm -rf .docker/$*-*
