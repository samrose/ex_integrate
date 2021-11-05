#!/bin/bash

# Write to stderr, then exit with error code 1

err() {
  echo "This is an error" >&2
}

main () {
  err
  exit 1
}

main
