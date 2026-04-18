local AdjacencyMatrix = {}
AdjacencyMatrix.__index = AdjacencyMatrix

function AdjacencyMatrix.__tostring(self: AdjacencyMatrix)
	local s = "\n"

	for i = 1, self.length do
		if i == 1 then
			s ..= "\n"
		end

		local sub = ""
		for j = 1, self.width do
			if j == self.width then
				sub ..= `{self.matrix[i][j]}`
				continue
			end

			sub ..= `{self.matrix[i][j]}, `
		end

		sub ..= "\n"
		s ..= sub
	end

	return s
end

function AdjacencyMatrix.extend(self: AdjacencyMatrix)
	self.length = self.length + 1
	self.width = self.length + 1

	self.matrix[self.length] = {}
	for j = 1, self.width do
		self.matrix[self.length][j] = 0
	end

	for i = 1, self.length do
		self.matrix[i][self.width] = 0
	end
end

function AdjacencyMatrix.setEdge(
	self: AdjacencyMatrix,
	i: number,
	j: number,
	val: number
)
	self.matrix[i][j] = val
end

function AdjacencyMatrix.toAdjacencyList(self: AdjacencyMatrix): { { number } }
	local list = {}

	for i = 1, self.length do
		list[i] = {}
		for j = 1, self.width do
			if self.matrix[i][j] ~= 0 then
				table.insert(list[i], j)
			end
		end
	end

	return list
end

function AdjacencyMatrix.topologicalSort(self: AdjacencyMatrix): { number }?
	local adjacencyList = self:toAdjacencyList()

	local result = {}
	local inDegrees = table.create(self.length, 0)

	for i = 1, self.length do
		for _, j in adjacencyList[i] do
			inDegrees[j] += 1
		end
	end

	local queue = {}
	for i = 1, self.length do
		if inDegrees[i] == 0 then
			table.insert(queue, i)
		end
	end

	while #queue ~= 0 do
		local i = table.remove(queue, 1) :: number
		table.insert(result, i)

		for _, j in adjacencyList[i] do
			inDegrees[j] -= 1
			if inDegrees[j] == 0 then
				table.insert(queue, j)
			end
		end
	end

	if #result ~= self.length then
		return nil
	end

	return result
end

function AdjacencyMatrix.new(): AdjacencyMatrix
	return setmetatable({
		matrix = {},
		length = 0,
		width = 0,
	}, AdjacencyMatrix)
end

export type AdjacencyMatrix = setmetatable<{
	matrix: { { number } },
	length: number,
	width: number,
}, typeof(AdjacencyMatrix)>

local DependencyGraph = {}
DependencyGraph.__index = DependencyGraph

function DependencyGraph.getOrderedList<T>(self: DependencyGraph<T>): { T }?
	local orderedList = {}

	local topologicalSort = self.matrix:topologicalSort()
	if not topologicalSort then
		return nil
	end

	for _, i in topologicalSort do
		table.insert(orderedList, self.nodes[i])
	end

	return orderedList
end

function DependencyGraph.insertBefore<T>(
	self: DependencyGraph<T>,
	node: T,
	beforeNode: T
)
	local i = table.find(self.nodes, beforeNode)
	assert(i, "Node not found in DependencyGraph:insertBefore(_, unknown)")

	local j = table.find(self.nodes, node)
	if not j then
		table.insert(self.nodes, node)
		j = #self.nodes
	end

	-- selene: allow(incorrect_standard_library_use)
	assert(j)

	self.matrix:extend()
	self.matrix:setEdge(j, i, 1)

	return self
end

function DependencyGraph.insertAfter<T>(
	self: DependencyGraph<T>,
	node: T,
	afterNode: T
)
	local i = table.find(self.nodes, afterNode)
	assert(i, "Node not found in DependencyGraph:insertAfter(_, unknown)")

	local j = table.find(self.nodes, node)
	if not j then
		table.insert(self.nodes, node)
		j = #self.nodes
	end

	-- selene: allow(incorrect_standard_library_use)
	assert(j)

	self.matrix:extend()
	self.matrix:setEdge(i, j, 1)

	return self
end

function DependencyGraph.insert<T>(self: DependencyGraph<T>, node: T)
	local i = #self.nodes
	table.insert(self.nodes, node)
	local j = #self.nodes

	self.matrix:extend()

	if i ~= 0 then
		self.matrix:setEdge(i, j, 1)
	end

	return self
end

function DependencyGraph.new<T>(): DependencyGraph<T>
	return setmetatable({
		nodes = {},
		matrix = AdjacencyMatrix.new(),
		length = 0,
		width = 0,
	}, DependencyGraph)
end

export type DependencyGraph<T> = setmetatable<{
	nodes: { T },
	matrix: AdjacencyMatrix,
	length: number,
	width: number,
}, typeof(DependencyGraph)>

return DependencyGraph
