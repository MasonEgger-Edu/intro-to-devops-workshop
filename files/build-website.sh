#!/bin/bash

hugo -s my_site
mkdir website && mv my_site/public/* website
tar -zcvf website.tar.gz website
rm -rf website
