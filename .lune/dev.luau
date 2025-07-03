local process = require("@lune/process")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local processes = {}

local COMMANDS = {
    "npm run watch",
    "rojo sourcemap default.project.json -o sourcemap.json --watch",
    "rojo serve",
}

for _, command in COMMANDS do
    local args = string.split(command, " ")
    local program = table.remove(args, 1) :: string

    table.insert(processes, process.create(program, args, {
        shell = true,
    }))
end

local function stdout(childProcess: process.ChildProcess)
    while task.wait() do
        local out = childProcess.stdout:read()
        if not out then
            continue
        end

        stdio.ewrite(out)
	end
end

local function stderr(childProcess: process.ChildProcess)
	while task.wait() do
        local out = childProcess.stderr:read()
        if not out then
            continue
        end

        stdio.ewrite(out)
	end
end

for _, childProcess in processes do
    task.spawn(stdout, childProcess)
    task.spawn(stderr, childProcess)
end
