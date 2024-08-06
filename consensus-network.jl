include("cadCAD.jl")
using .cadCAD: Diagram, block!, wire!, initialize!, collect!, execute!

network = Diagram()

nAgents = 20
ϵ = 1 / 11 - 1 / 12

# Create and wire agents to themselves.
for i in 1:nAgents
    name = "agent$i"
    block!(network, name, (self, in...) -> self + ϵ * sum(x - self for x in in))
    wire!(network, "$(name)->$(name).self")
end

# Connect agents to neighbors.
for i in 1:nAgents
    name = "agent$i"
    others = setdiff(1:nAgents, i)
    N_i = Set(rand(others, rand(1:length(others))))
    for (i, other) in enumerate(N_i)
        # index 1 on each block is `self`, so wire to input i+1
        wire!(network, "agent$(other)->$(name).$(i+1)")
    end
end

# Initialize agents.
for i in 1:nAgents
    initialize!(network, "agent$i", rand(1:42))
end

# Collect agent trajectories into matrix.
outputs = []
for i in 1:nAgents
    push!(outputs, [])
    collect!(network, "agent$i", outputs[i])
end

execute!(network, 500)

# Plot agent trajectories.
using UnicodePlots
plt = lineplot(outputs[1], color=:black)
for i in 2:length(outputs)
    lineplot!(plt, outputs[i], color=:black)
end
print(plt)
