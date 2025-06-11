local AdjacencyMatrix = {}
AdjacencyMatrix.__index = AdjacencyMatrix

export type AdjacencyMatrix = {
	matrix: { { number } },
	length: number,
	width: number,

	extend: (self: AdjacencyMatrix) -> (),
	setEdge: (self: AdjacencyMatrix, i: number, j: number, v: number) -> (),
	toAdjacencyList: (self: AdjacencyMatrix) -> { { number } },
	topologicalSort: (self: AdjacencyMatrix) -> { number }?,
	new: () -> AdjacencyMatrix,
}

function AdjacencyMatrix:__tostring()
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

function AdjacencyMatrix:extend()
	self.length = (self.length :: number) + 1
	self.width = (self.length :: number) + 1

	self.matrix[self.length] = {}
	for j = 1, self.width do
		self.matrix[self.length][j] = 0
	end

	for i = 1, self.length do
		self.matrix[i][self.width] = 0
	end
end

function AdjacencyMatrix:setEdge(i, j, val)
	self.matrix[i][j] = val
end

function AdjacencyMatrix:toAdjacencyList()
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

function AdjacencyMatrix:topologicalSort(): { number }?
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
	}, AdjacencyMatrix) :: any
end

export type DependencyGraph<T> = {
	nodes: { T },
	matrix: AdjacencyMatrix,
	length: number,
	width: number,

	getOrderedList: (self: DependencyGraph<T>) -> { T }?,
	insert: (self: DependencyGraph<T>, node: T) -> DependencyGraph<T>,
	insertAfter: (
		self: DependencyGraph<T>,
		node: T,
		afterNode: T
	) -> DependencyGraph<T>,
	insertBefore: (
		self: DependencyGraph<T>,
		node: T,
		beforeNode: T
	) -> DependencyGraph<T>,
	new: () -> DependencyGraph<T>,
}

local DependencyGraph = {}
DependencyGraph.__index = DependencyGraph

function DependencyGraph:getOrderedList(): { any }?
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

function DependencyGraph:insertBefore(node, beforeNode)
	if not table.find(self.nodes, beforeNode) then
		error("Node not found in DependencyGraph:insertBefore(_, unknown)")
	end

	local j = table.find(self.nodes, node)
	if not j then
		table.insert(self.nodes, node)
		j = #self.nodes
	end

	local i = table.find(self.nodes, beforeNode)

	self.matrix:extend()
	self.matrix:setEdge(j, i, 1)

	return self
end

function DependencyGraph:insertAfter(node, afterNode)
	if not table.find(self.nodes, afterNode) then
		error("Node not found in DependencyGraph:insertAfter(_, unknown)")
	end

	local j = table.find(self.nodes, node)
	if not j then
		table.insert(self.nodes, node)
		j = #self.nodes
	end

	local i = table.find(self.nodes, afterNode)

	self.matrix:extend()
	self.matrix:setEdge(i, j, 1)

	return self
end

function DependencyGraph:insert(node)
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
	}, DependencyGraph) :: any
end

return DependencyGraph
