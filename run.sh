#!/bin/sh

# Moving the input to a source code file
cp input.txt input.c
# Compiling
gcc -o object input.c
# Running the object file
./object
# Cleanning up
rm input.c object
