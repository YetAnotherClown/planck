_G.NOCOLOR = _G.NOCOLOR

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local DevPackages = ReplicatedStorage.DevPackages

local Jest = require(DevPackages.Jest)

local runCLIOptions = {
	verbose = false,
	ci = false,
}

local projects = {
	Packages,
}

Jest.runCLI(script, runCLIOptions, projects):await()
