local process = require("@lune/process")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local COMMANDS = {
	"wally install",
	"rojo sourcemap default.project.json -o sourcemap.json",
	"wally-package-types --sourcemap sourcemap.json Packages/",
	"wally-package-types --sourcemap sourcemap.json DevPackages/",
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

stdio.write("\nFinished installing all dependencies.")
