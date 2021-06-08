ARG PYTHON_VERSION=3.8
FROM amazon/aws-lambda-python:${PYTHON_VERSION}
RUN yum install -y zip && pip install pipenv==2021.5.29
COPY . .
RUN pipenv lock -r > requirements.txt
RUN pipenv lock -r -d > requirements-dev.txt
RUN pip install -r requirements.txt -t .
RUN zip -x '*/__pycache__/*' -9r package.zip *
RUN pip install -r requirements-dev.txt
VOLUME /root
VOLUME /var/task
CMD [ "index.handler" ]
