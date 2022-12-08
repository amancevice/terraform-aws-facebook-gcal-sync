all: validate

build:
	make -C src

clean:
	make -C src $@

validate: build .terraform
	AWS_REGION=us-east-1 terraform validate

.PHONY: all build clean validate

.terraform:
	terraform init
