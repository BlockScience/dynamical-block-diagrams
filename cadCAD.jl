struct Diagram
    blocks::Dict{String,Any}
    function Diagram()
        new(Dict())
    end
end

mutable struct Wire
    value::Any
    initialized::Bool
    time::UInt
    function Wire()
        new(nothing, false, 0)
    end
end

mutable struct Block
    inputs::Vector{Ref{Wire}}
    output::Ref{Wire}
    logic::Function
    function Block(d::Diagram, name::String, logic::Function)
        inputs = length(first(methods(logic)).sig.parameters) - 1
        inputs = Vector{Ref{Wire}}(undef, inputs)
        b = new(inputs, Wire(), logic)
        d.blocks[name] = b
        b
    end
end

# e: "{name}->{name}.{argument}"
function wire(d::Diagram, e::String)
    e = split(e, "->")
    from = String(first(e))
    e = split(e[2], ".")
    to = String(first(e))
    terminal = e[2]
    args = Base.method_argnames(first(methods(d.blocks[to].logic)))[2:end]
    terminal = findfirst(==(Symbol(terminal)), args)
    wire(d, from, to, terminal)
end

function wire(d::Diagram, from::String, to::String, terminal::Int64)
    from = d.blocks[from]
    to = d.blocks[to]
    to.inputs[terminal] = from.output
end

function initialize(d::Diagram, block::String, value)
    block = d.blocks[block]
    block.output[].value = value
    block.output[].time = 1
    block.output[].initialized = true
end

function execute(d::Diagram, steps::Int64)
    stop = (x...) -> (steps -= 1) <= 0
    execute(d, stop)
end

function execute(d::Diagram, stop::Function)
    while true
        name, b = rand(d.blocks)
        go = true
        v = []
        i = b.output[].initialized
        for n in b.inputs
            if (i && n[].time != b.output[].time) || (!i && n[].time <= b.output[].time)
                go = false
                break
            end
            push!(v, n[].value)
        end
        if go
            b.output[].value = b.logic(v...)
            b.output[].time += 1
            if stop(name, b.output[].value)
                break
            end
        end
    end
end
