local process = require("@lune/process")
local stdio = require("@lune/stdio")
local fs = require("@lune/fs")

local function exec(command: string)
    local args = string.split(command, " ")
    local program = table.remove(args, 1) :: string

    return process.exec(program, args, {
        shell = true
    })
end

do
    local result = exec("wally install")

    if not result.ok then
        stdio.ewrite(result.stderr)
        return
    end

    stdio.write(result.stdout)
end

for _, path in fs.readDir("src") do
    if fs.isDir(`src/{path}`) and fs.isFile(`src/{path}/wally.toml`) then
        local result = exec(`wally install --project-path src/{path}`)

        if not result.ok then
            stdio.ewrite(result.stderr)
            return
        end

        stdio.write(result.stdout)
    end
end

stdio.write("\nFinished installing all dependencies.")