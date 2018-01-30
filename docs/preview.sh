#!/bin/bash

docker run -p 80:80 -v "$(pwd)"/build/html:/usr/share/nginx/html:ro --rm -d nginx:alpine
