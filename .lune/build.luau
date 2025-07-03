local process = require("@lune/process")
local stdio = require("@lune/stdio")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

type Project = {
    name: string,
    [string]: any
}

local function exec(command: string)
    local args = string.split(command, " ")
    local program = table.remove(args, 1) :: string

    return process.exec(program, args, {
        shell = true
    })
end

do
    local result = exec("npm run build")

    if not result.ok then
        stdio.ewrite(result.stderr)
        return
    end

    stdio.write(result.stdout)
end

for _, path in fs.readDir("out") do
    if fs.isDir(`out/{path}`) then
        local projectPath = `out/{path}/default.project.json`
        local project: Project = serde.decode("json", fs.readFile(projectPath))

        local outputPath = `builds/{project.name}.rbxm`
        if not fs.isDir("builds") then
            fs.writeDir("builds")
        end

        local result = exec(`rojo build {projectPath} --output {outputPath}`)

        if not result.ok then
            stdio.ewrite(result.stderr)
            return
        end

        stdio.write(result.stdout)
    end
end

stdio.write("\nFinished building all packages, build files can be found in the 'builds' directory")