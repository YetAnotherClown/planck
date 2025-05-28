#!/bin/sh

set -e

rojo sourcemap default.project.json -o sourcemap.json

rm -rf dist
darklua process --config .darklua.json src/ dist/src

cp wally.toml dist/wally.toml
cp wally.lock dist/wally.lock

cp build.project.json dist/default.project.json
sed -i 's/dist\/src/src/' dist/default.project.json

cd ./dist

if [ "$1" = "--publish" ]; then
    wally publish
else
    wally package --output release.zip
fi