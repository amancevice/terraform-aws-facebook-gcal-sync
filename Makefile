REPO := amancevice/facebook-gcal-sync/aws
CONTAINER := $(shell date +%s)

all: validate

clean:
	rm -rf build package.zip requirements.txt

validate: package.zip | .terraform
	AWS_REGION=us-east-1 terraform validate

.PHONY: all clean validate

package.zip: requirements.txt | build
	cd build && zip -x '*/__pycache__/*' -9qr ../$@ .

build: requirements.txt
	mkdir -p $@
	docker build --tag $(REPO) .
	docker container create --name $(CONTAINER) $(REPO)
	docker container cp $(CONTAINER):/var/task $@
	docker container rm $(CONTAINER)
	docker image rm $(REPO)
	touch $@

requirements.txt: Pipfile
	pipenv lock -r > $@

.terraform:
	terraform init
