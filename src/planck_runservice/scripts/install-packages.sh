#!/bin/sh

set -e

wally install
rojo sourcemap default.project.json --output sourcemap.json
wally-package-types --sourcemap sourcemap.json DevPackages/
wally-package-types --sourcemap sourcemap.json Packages/