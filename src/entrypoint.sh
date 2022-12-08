#!/bin/bash

yum install -y zip
pip install -r requirements.txt -t .
zip -9qr package.zip .
