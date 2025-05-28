#!/bin/sh

set -e

OUTPUT=PlanckRunService.rbxl

# If Packages aren't installed, install them.
if [ ! -d "DevPackages" ]; then
    sh scripts/install-packages.sh
fi


rojo sourcemap default.project.json --output sourcemap.json \
    && darklua process --config .darklua.json src/ dist/src \
    && darklua process --config .darklua.json scripts/run-tests.server.luau dist/run-tests.server.luau \
    && rojo build dev.project.json --output $OUTPUT \
    && run-in-roblox --place $OUTPUT --script dist/run-tests.server.luau
