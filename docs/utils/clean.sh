#!/bin/bash

docker run -v "$(pwd)":/docs --rm -it makotow/sphinx-docker:1.1 make clean