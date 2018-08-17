#!/bin/bash

docker run -v "$(pwd)":/docs --rm -it makotow/sphinx-docker:1.3-sphinx1.7.6make clean