CID := $(shell date +%s)

all: test build

build: package.zip

clean:
	rm -rf requirements.txt

ipython: .venv
	pipenv run ipython

test: .venv
	pipenv run black --check index.py

.PHONY: all build clean ipython test

package.zip: *
	docker container create --name $(CID) --entrypoint entrypoint.sh public.ecr.aws/lambda/python
	-docker container cp entrypoint.sh $(CID):/usr/local/bin
	-docker container cp index.py $(CID):/var/task
	-docker container cp requirements.txt $(CID):/var/task
	-docker container start --attach $(CID)
	-docker container cp $(CID):/var/task/$@ $@
	docker container rm $(CID)

requirements.txt: Pipfile.lock .venv
	pipenv requirements > $@

Pipfile.lock .venv: Pipfile
	mkdir -p .venv
	pipenv install --dev
	touch .venv
