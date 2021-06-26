ARG PYTHON_VERSION=3.8

FROM public.ecr.aws/sam/build-python$PYTHON_VERSION AS build
RUN yum install -y zip && pip install pipenv==2021.5.29
COPY . .
RUN pipenv lock -r > requirements.txt
RUN pipenv lock -r -d > requirements-dev.txt
RUN pip install -r requirements.txt -t python
RUN zip -x '*/__pycache__/*' -9r package.zip .

FROM public.ecr.aws/lambda/python:$PYTHON_VERSION AS test
COPY --from=build /var/task .
RUN pip install -r requirements-dev.txt
ENV PYTHONPATH=/var/task/python
VOLUME /root
VOLUME /var/task
CMD [ "index.handler" ]
