ARG PYTHON=3.8
ARG TERRAFORM=latest

FROM lambci/lambda:build-python${PYTHON} AS lock
RUN pipenv lock 2>&1
COPY Pipfile* /var/task/
RUN pipenv lock -r > requirements-lock.txt
RUN pipenv lock -r -d > requirements-dev-lock.txt

FROM lambci/lambda:build-python${PYTHON} AS zip
COPY lambda.py .
COPY --from=lock /var/task/ .
RUN pip install -r requirements-lock.txt -t .
RUN zip -9r package.zip .

FROM hashicorp/terraform:${TERRAFORM} AS validate
WORKDIR /var/task/
COPY *.tf /var/task/
RUN terraform init
RUN terraform fmt -check
ARG AWS_DEFAULT_REGION=us-east-1
COPY --from=zip /var/task/package.zip .
RUN terraform validate
