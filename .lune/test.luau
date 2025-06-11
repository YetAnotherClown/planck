local fs = require("@lune/fs")
local process = require("@lune/process")
local regex = require("@lune/regex")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local COMMANDS = {
	"rojo build default.project.json --output Planck.rbxl",
	"run-in-roblox --place Planck.rbxl --script src/run-tests.server.luau",
}

local function exec(command: string)
	local args = string.split(command, " ")
	local program = table.remove(args, 1) :: string

	return process.exec(program, args, {
		shell = true,
	})
end

for _, command in COMMANDS do
	stdio.write(`\n> {command}\n`)
	local result = exec(command)

	stdio.ewrite(result.stderr)
	stdio.write(result.stdout)

	if not result.ok then
		return
	end
end
