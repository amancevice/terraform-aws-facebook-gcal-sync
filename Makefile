all: validate

build:
	make -C src

clean:
	rm -rf .terraform*
	make -C src clean

validate: build .terraform
	AWS_REGION=us-east-1 terraform validate

.PHONY: all build clean validate

.terraform:
	terraform init
