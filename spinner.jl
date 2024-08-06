include("cadCAD.jl")

import .cadCAD: Diagram, block!, wire!, initialize!, execute!, collect!

spinner = Diagram()

block!(spinner, "c2r", (x, y) -> sqrt(x * x + y * y))
block!(spinner, "c2Θ", (x, y) -> atan(y, x))
block!(spinner, "ΔΘ", (Θ) -> Θ + rand() * 2 * pi)
block!(spinner, "p2x", (r, Θ) -> trunc(Int, r * cos(Θ)))
block!(spinner, "p2y", (r, Θ) -> trunc(Int, r * sin(Θ)))

wire!(spinner, "c2r->p2x.r")
wire!(spinner, "c2r->p2y.r")
wire!(spinner, "c2Θ->ΔΘ.Θ")
wire!(spinner, "ΔΘ->p2x.Θ")
wire!(spinner, "ΔΘ->p2y.Θ")
wire!(spinner, "p2x->c2r.x")
wire!(spinner, "p2x->c2Θ.x")
wire!(spinner, "p2y->c2r.y")
wire!(spinner, "p2y->c2Θ.y")

trajectory = []
collect!(spinner, "c2r", trajectory)

initialize!(spinner, "c2r", 500)
initialize!(spinner, "c2Θ", 0)

execute!(spinner, 1000)

using UnicodePlots
print(lineplot(trajectory, color=:black))
