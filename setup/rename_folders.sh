#!/bin/bash

find . -maxdepth 1 -type d -exec rename "${1}" "${2}" {} \;
