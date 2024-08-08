include("./cadCAD.jl")

network = Diagram()

nAgents = 42
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
    initialize!(network, "agent$i", rand(1:1000))
end

# store (agent) -> trajectory
trajectories = []
for i in 1:nAgents
    push!(trajectories, [])
    collect!(network, "agent$i", trajectories[i])
end

execute(network, 1000)

# Plot agent trajectories.
using UnicodePlots
plt = lineplot(trajectories[1], color=:black)
for i in 2:length(trajectories)
    lineplot!(plt, trajectories[i], color=:black)
end
print(plt)
