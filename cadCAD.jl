module cadCAD

struct Wire
    from::String
    to::String
    index::Int64
end

struct Diagram
    blocks::Dict{String,Function}
    wires::Set{Wire}
    initialization::Dict{String,Any}

    function Diagram()
        new(Dict(), Set(), Dict())
    end
end

function inputs(d::Diagram, b::String)
    v = []
    for w in d.wires
        if w.to == b
            push!(v, w)
        end
    end
    map(w -> w.from, sort(v, by=w -> w.index))
end

function outputs(d::Diagram, b::String)
    v = []
    for o in keys(d.blocks)
        if b in inputs(d, o)
            push!(v, o)
        end
    end
    v
end

function block!(d::Diagram, name::String, logic::Function)
    d.blocks[name] = logic
end

function wire!(d::Diagram, e::String)
    function p(e::String)
        e = split(e, "->")
        from = String(e[1])
        e = split(e[2], ".")
        to = String(e[1])
        terminal = e[2]
        from, to, terminal
    end

    from, to, terminal = p(e)
    index = findfirst(
        ==(Symbol(terminal)),
        Base.method_argnames(methods(d.blocks[to])[1])[2:end]
    )
    index = index === nothing ? tryparse(Int, terminal) : index
    @assert index !== nothing "wiring to nonexistant location ($to.$terminal)"
    push!(d.wires, Wire(from, to, index))
end

function initialize!(d::Diagram, block::String, value)
    @assert haskey(d.blocks, block) "initializing nonexistant block ($block)"
    d.initialization[block] = value
end

function execute!(d::Diagram, steps::Int64)
    function propogate(d::Diagram, I::Set)
        B = keys(d.blocks)
        S = Set([b for b in B if inputs(d, b) ⊆ I && length(inputs(d, b)) > 0])
        L = []
        while length(S) > 0
            b = rand(S)
            push!(L, b)
            delete!(S, b)
            for n in outputs(d, b)
                if n ∉ L && setdiff(inputs(d, n), I) ⊆ L
                    push!(S, n)
                end
            end
        end
        L
    end
    function order(d::Diagram, I::Set)
        V_t = propogate(d, I)
        L = []
        while true
            V_tp = propogate(d, Set([b for b in V_t if b in I]))
            if length(V_tp) == 0
                return [L; V_t], []
            end
            if Set(V_tp) == Set(V_t)
                return L, V_t
            end
            L = [L; V_t]
            V_t = V_tp
        end
    end
    function compileSequence(order, I)
        v = []
        xps = []
        for b in order
            args = map(name -> "x_$name", inputs(d, b))
            args = join(args, ", ")
            call = "$b($args)"
            assignment = "x_$b"
            if b in I
                assignment = "xp_$b"
                push!(xps, b)
            end
            push!(v, "$assignment = $call")
        end
        for b in xps
            push!(v, "x_$b = xp_$b")
        end
        join(v, "\n")
    end
    function compileFunction(d, I, steps)
        setup, loop = map(o -> compileSequence(o, I), order(d, I))
        loop = "  " * replace(loop, "\n" => "\n  ")
        body = strip("$setup\nsteps=$steps\nwhile (steps -= 1) >= 0\n$loop\nend")
        body = "  " * replace(body, "\n" => "\n  ")
        args = join([sort(collect(keys(d.blocks))); map(b -> "x_$b", sort(collect(I)))], ", ")
        "function execute_diagram($args)\n$body\nend"
    end

    I = Set(keys(d.initialization))
    fn = compileFunction(d, I, steps)
    eval(Meta.parse(fn))
    args = [
        map(b -> d.blocks[b], sort(collect(keys(d.blocks))));
        map(i -> d.initialization[i], sort(collect(I)))
    ]

    @invokelatest execute_diagram(args...)
end

# --- metrics --- #

passthru = (f, g) -> (v...) -> (y -> (g(y); y))(f(v...))

function print!(d::Diagram, block::String)
    f = d.blocks[block]
    d.blocks[block] = passthru(f, println)
end

function collect!(d::Diagram, block::String, into::Vector{Any})
    f = d.blocks[block]
    d.blocks[block] = passthru(f, x -> push!(into, x))
end

end
