local fs = require("@lune/fs")
local process = require("@lune/process")
local regex = require("@lune/regex")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local DependencyGraph = require("../src/planck/src/DependencyGraph")

type Manifest = {
	manifest: { [string]: any },
	content: string,
}

type Package = {
	name: string,
	version: string,
	path: string,
	manifests: {
		npm: Manifest,
		wally: Manifest,
	},
	dependencies: { string },
}

local DEPENDENCY_REGEXP = regex.new([[.+/(.+)@]])
local WALLY_VERSION_REGEXP = regex.new([[version\s*=\s*"(.*)"]])
local NPM_VERSION_REGEXP = regex.new([["version":\s*"(.*)"]])
local SEMVER_REGEXP = regex.new(
	[[(?m)^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$]]
)

local function exec(command: string)
	local args = string.split(command, " ")
	local program = table.remove(args, 1) :: string

	return process.exec(program, args, {
		shell = true,
	})
end

local function publishPackage(
	package: Package,
	version: string,
	dryRun: boolean
)
	stdio.write(
		`{stdio.style("dim")}`
			.. `Publishing...\t{package.name}@{version}\n`
			.. `{stdio.color("reset")}`
			.. `{stdio.style("reset")}`
	)

	local wallyPath = `{package.path}/wally.toml`
	fs.writeFile(
		wallyPath,
		WALLY_VERSION_REGEXP:replace(
			package.manifests.wally.content,
			`version = "{version}"`
		)
	)

	local npmPath = `{package.path}/package.json`
	fs.writeFile(
		npmPath,
		NPM_VERSION_REGEXP:replace(
			package.manifests.npm.content,
			`"version": "{version}"`
		)
	)

	do
		local result
		if not dryRun then
			result = exec(`wally publish --project-path {package.path}`)
		else
			result = exec(
				`wally package`
					.. " "
					.. `--project-path {package.path}`
					.. " "
					.. `--output package_tarballs/wally`
					.. `/{package.name}@{version}.zip`
			)
		end

		if not result.ok then
			stdio.ewrite(`{stdio.color("red")}{result.stderr}`)
			return
		end

		stdio.write(result.stdout)
	end

	do
		local result
		if not dryRun then
			result = exec(`npm publish ./{package.path}/`)
		else
			result = exec(
				`npm pack`
					.. " "
					.. `./{package.path}/`
					.. " "
					.. `--pack-destination package_tarballs/npm`
			)
		end

		if not result.ok then
			stdio.ewrite(`{stdio.color("red")}{result.stderr}`)
			return
		end

		stdio.write(result.stdout)
	end

	stdio.write(
		`{stdio.color("green")}`
			.. `Published\t{package.name}@{version}\n`
			.. `{stdio.color("reset")}`
	)
end

local dryRun = true

local args = {}
for _, arg in process.args do
	if arg == "--publish" then
		dryRun = false
		continue
	end

	table.insert(args, arg)
end

local version = table.remove(args, 1)
if not version or not SEMVER_REGEXP:isMatch(version) then
	error(`"Invalid Semver: '{version}'`)
end

local paths: { string } = #args ~= 0 and args or fs.readDir("src")

local packages = {}
local nameToPackage = {}

local graph = DependencyGraph.new()

for _, path in paths do
	local packagePath = `src/{path}`
	local wallyPath = `{packagePath}/wally.toml`
	local npmPath = `{packagePath}/package.json`

	local wallyContent = fs.readFile(wallyPath)
	local wallyManifest = serde.decode("toml", wallyContent)

	local npmContent = fs.readFile(npmPath)
	local npmManifest = serde.decode("json", npmContent)

	local package: Package = {
		name = string.split(wallyManifest.package.name, "/")[2],
		version = wallyManifest.package.version,
		path = packagePath,
		manifests = {
			npm = {
				manifest = npmManifest,
				content = npmContent,
			},
			wally = {
				manifest = wallyManifest,
				content = wallyContent,
			},
		},
		dependencies = {},
	}

	if wallyManifest.dependencies then
		for _, dependency in wallyManifest.dependencies do
			local captures = DEPENDENCY_REGEXP:captures(dependency)
			if not captures then
				continue
			end

			local capture = captures:get(1)
			if not capture then
				continue
			end

			table.insert(package.dependencies, capture.text)
		end
	end

	table.insert(packages, package)
	nameToPackage[package.name] = package
end

for _, package in packages do
	local dependent = false

	for _, dependency in package.dependencies do
		if not nameToPackage[dependency] then
			continue
		end

		if not table.find(graph.nodes, dependency) then
			graph:insert(dependency)
		end

		dependent = true
		graph:insertAfter(package.name, dependency)
	end

	if not dependent and not table.find(graph.nodes, package.name) then
		graph:insert(package.name)
	end
end

if dryRun then
	stdio.write(
		`{stdio.color("yellow")}`
			.. `Performing dry run\n`
			.. `{stdio.color("reset")}`
			.. `{stdio.style("dim")}`
			.. `Packages will not be published\n`
			.. `{stdio.style("reset")}\n`
	)

	if fs.isDir("package_tarballs") then
		fs.removeDir("package_tarballs")
	end

	fs.writeDir("package_tarballs")
	fs.writeDir("package_tarballs/wally")
	fs.writeDir("package_tarballs/npm")
elseif not dryRun then
	local prompt = `Are you sure you want to publish the following packages:`
	prompt ..= `{stdio.style("reset")}{stdio.style("dim")}`

	for _, name in graph:getOrderedList() do
		local package = nameToPackage[name]
		prompt ..= `\n{string.rep(" ", 4)}{name}@{package.version} -> {name}@{version}`
	end

	local shouldProceed = stdio.prompt("confirm", `{prompt}\n`, false)
	if not shouldProceed then
		stdio.ewrite(
			`{stdio.color("red")}Cancelled publishing {#packages} packages`
		)
	end
end

for _, name in graph:getOrderedList() do
	publishPackage(nameToPackage[name], version, dryRun)
end

if dryRun then
	stdio.write(
		`\n`
			.. "Generated tarballs for each package\n"
			.. `{stdio.style("dim")}`
			.. "These are located under ./package_tarballs"
	)
else
	stdio.write(`\nSuccessfully published {#packages} packages`)
end
