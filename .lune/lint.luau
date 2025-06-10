local process = require("@lune/process")
local stdio = require("@lune/stdio")
local fs = require("@lune/fs")

local function exec(command: string)
	local args = string.split(command, " ")
	local program = table.remove(args, 1) :: string

	return process.exec(program, args, {
		shell = true,
	})
end

do
	local result = exec("rojo sourcemap default.project.json -o sourcemap.json")

	if not result.ok then
		stdio.ewrite(result.stderr)
		return
	end

	stdio.write(result.stdout)
end

if not fs.isFile("globalTypes.d.luau") then
	local result = exec(
		"curl -O https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau"
	)

	if not result.ok then
		stdio.ewrite(result.stderr)
		return
	end

	stdio.write(result.stdout)
end

do
	local result = process.exec("luau-lsp", {
        "analyze",
        "src",
        "--definitions=globalTypes.d.lua",
		"--base-luaurc=.luaurc",
		"--sourcemap=sourcemap.json",
		"--settings=.vscode/settings.json",
		"--no-strict-dm-types",
		'--ignore="**/DevPackages/**"',
		'--ignore="**/Packages/**"',
    })

	if not result.ok then
		stdio.ewrite(result.stderr)
		return
	end

	stdio.write(result.stdout)
end
