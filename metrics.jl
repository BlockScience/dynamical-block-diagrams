include("cadCAD.jl")

using UnicodePlots

function print(d::Diagram, block::String)
    block = d.blocks[block]
    f = block.logic
    block.logic = (v...) -> (y -> (println(y); y))(f(v...))
end

function lineplot(d::Diagram, block::String)
    block = d.blocks[block]
    t = []
    f = block.logic
    block.logic = (v...) -> (
        y -> (
            push!(t, y);
            println("\033[H\033[J");
            Base.print(UnicodePlots.lineplot(t));
            y
        ))(f(v...))
end

function ary2plot(d::Diagram, x::String, y::String, plot::Function)
    x = d.blocks[x]
    y = d.blocks[y]
    xs = []
    ys = []
    xf = x.logic
    yf = y.logic
    g = (l) -> (y) -> (push!(l, y); y)
    p = (y) -> (length(xs) == length(ys) && (sleep(0.003); println("\033[H\033[J"); Base.print(plot(xs, ys))); y)
    x.logic = (v...) -> p(g(xs)(xf(v...)))
    y.logic = (v...) -> p(g(ys)(yf(v...)))
end

function polarplot(v...)
    ary2plot(v..., UnicodePlots.polarplot)
end

function densityplot(v...)
    ary2plot(v..., (xs, ys) -> UnicodePlots.densityplot(xs, ys, dscale=x -> log(1 + x), title="density"))
end
