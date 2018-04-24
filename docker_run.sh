#!/usr/bin/env bash

docker run --rm -ti \
    -v /c/Users/njones/source/repos/Agile_Data_Code_2/data:/shared \
    -v ads-data:/data \
    -p 8888:8888 \
    -p 8080:8080 \
    -p 9200:9200 \
    ac:6
