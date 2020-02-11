#!/bin/sh

openapi-generator generate \
  -g elixir \
  -i ./openapi/specs/action-server.yml \
  -o ./ \
  -t ./openapi/elixir \
  --additional-properties=invokerPackage=RasaSdk
