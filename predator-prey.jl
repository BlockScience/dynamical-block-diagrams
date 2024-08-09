# Lotka–Volterra equations for predator-prey dynamics.
#
# This simulation runs for a million steps and is intended to
# demonstrate the performance of compiled diagrams. In this particular
# case, the diagram is compiled to:
#
# function execute_diagram(fish, shark, x_fish, x_shark)
#   steps=1000000
#   while (steps -= 1) >= 0
#     xp_shark = shark(x_fish, x_shark)
#     xp_fish = fish(x_fish, x_shark)
#     x_shark = xp_shark
#     x_fish = xp_fish
#   end
# end
#
include("./cadCAD.jl")

world = Diagram()

fishGrowthRate = 1.1
fishHuntRate = 0.4

sharkGrowthRate = 0.1
sharkDeathRate = 0.4

dt = 0.00005

block!(world, "fish", function (fishpop, sharkpop)
    fishpop + dt * (fishGrowthRate * fishpop - fishHuntRate * fishpop * sharkpop)
end)

block!(world, "shark", function (fishpop, sharkpop)
    sharkpop + dt * (sharkGrowthRate * sharkpop * fishpop - sharkDeathRate * sharkpop)
end)

wire!(world, "fish->shark.fishpop")
wire!(world, "fish->fish.fishpop")
wire!(world, "shark->fish.sharkpop")
wire!(world, "shark->shark.sharkpop")

initialize!(world, "fish", 10)
initialize!(world, "shark", 10)

ft = []
st = []
collect!(world, "fish", ft)
collect!(world, "shark", st)

execute(world, 1000000)

using UnicodePlots
plt = lineplot(ft, color=:black)
lineplot!(plt, st, color=:red)
print(plt)
