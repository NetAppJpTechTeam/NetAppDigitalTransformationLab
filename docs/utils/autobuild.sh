#!/bin/bash

docker run -p 127.0.0.1:8000:8000 -v "$(pwd)":/docs --rm -d  makotow/sphinx-docker:1.1 sphinx-autobuild -H 0.0.0.0 source/ build/html
