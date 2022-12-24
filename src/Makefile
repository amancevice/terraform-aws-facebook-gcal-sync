CID := $(shell date +%s)

all: test build

build: package.zip

ipython: .venv
	pipenv run ipython

test: .venv
	pipenv run black --check index.py

.PHONY: all build ipython test

package.zip: entrypoint index.py requirements.txt
	docker container create --name $(CID) --entrypoint entrypoint public.ecr.aws/lambda/python
	-docker container cp entrypoint $(CID):/usr/local/bin
	-docker container cp index.py $(CID):/var/task
	-docker container cp requirements.txt $(CID):/var/task
	-docker container start --attach $(CID)
	-docker container cp $(CID):/var/task/$@ $@
	docker container rm $(CID)

requirements.txt: .venv
	pipenv requirements > $@

Pipfile.lock: Pipfile
.venv: Pipfile.lock
	mkdir -p $@
	pipenv install --dev
	touch $@
