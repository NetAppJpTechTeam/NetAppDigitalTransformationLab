#!/bin/sh

docker run -p 127.0.0.1:8000:8000 -v "$(PWD)":/docs --rm -d  makotow/sphinx-docker:1.0 sphinx-autobuild source/ build/html
