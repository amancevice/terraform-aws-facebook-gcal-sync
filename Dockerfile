ARG PYTHON_VERSION=3.9

FROM public.ecr.aws/lambda/python:$PYTHON_VERSION
COPY . .
RUN pip install -r requirements.txt -t .
#ENV PYTHONPATH=/var/task/python
#VOLUME /root
#VOLUME /var/task
CMD [ "index.handler" ]
