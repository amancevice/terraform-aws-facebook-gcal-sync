requirements = $(shell cat requirements.txt | tr '\n' ' ')

.PHONY: lock package clean

Pipfile.lock: Pipfile
	pipenv lock
	pipenv lock -r > requirements.txt
	pipenv lock -r -d > requirements-dev.txt

lock: Pipfile.lock

build: lock
	docker-compose run --rm build -t /var/task $(requirements)
	cp lambda.py build/

package: build
	docker-compose run --rm -T package > package.zip
	git add package.zip

clean:
	rm -rf build
	docker-compose down
