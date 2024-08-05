include("cadCAD.jl")
include("metrics.jl")

spinner = Diagram()

Block(spinner, "c2r", (x, y) -> sqrt(x * x + y * y))
Block(spinner, "c2Θ", (x, y) -> atan(y, x))
Block(spinner, "+Δ", (th) -> th + rand() * 2 * pi)
Block(spinner, "p2x", (r, th) -> trunc(Int, r * cos(th)))
Block(spinner, "p2y", (r, th) -> trunc(Int, r * sin(th)))

wire(spinner, "c2r->p2x.r")
wire(spinner, "c2r->p2y.r")
wire(spinner, "c2Θ->+Δ.th")
wire(spinner, "+Δ->p2x.th")
wire(spinner, "+Δ->p2y.th")
wire(spinner, "p2x->c2r.x")
wire(spinner, "p2x->c2Θ.x")
wire(spinner, "p2y->c2r.y")
wire(spinner, "p2y->c2Θ.y")

# lineplot(spinner, "c2r")
# polarplot(spinner, "c2r", "c2Θ")
densityplot(spinner, "p2x", "p2y")

initialize(spinner, "c2r", 500)
initialize(spinner, "c2Θ", 0)

execute(spinner, (name, y) -> name == "c2r" && y == 0)
