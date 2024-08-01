# This is a simple block diagram executor which is subsequentally
# configured to run the diagram described here:
#
# https://hackmd.io/@ekez/HJTHYT8NA
#

# This does not compute execution order ahead of time, nor validate
# initial conditions. Though valid diagrams run with this executor
# ought to have the same behavior as a fully functional one.

using Random

mutable struct Node{Space}
    space::Type
    value::Union{Space, Nothing}
    initialized::Bool
    time::UInt
    function Node(t::Type)
        new{t}(t, nothing, false, 0)
    end
end

struct Block
    terminals::Vector{Ref{Node}}
    terminaltypes::Vector{Type}
    port::Ref{Node}
    logic::Function
    name::String
    function Block(terminaltypes, port, logic, name)
        terminals = Vector{Ref{Node}}(undef, length(terminaltypes))
        new(terminals, terminaltypes, Node(port), logic, name)
    end
end

function wire(port, block, terminal)
    @assert isa(port[].space, typeof(block.terminaltypes[terminal]))
    block.terminals[terminal] = port
end

function initialize(block, value)
    @assert isa(value, block.port[].space)
    block.port[].value = value
    block.port[].time = 1
    block.port[].initialized = true
end

cartesian2radius = Block([Int, Int], Real, (x, y) -> sqrt(x*x + y*y), "c2r")
cartesian2theta = Block([Int, Int], Real, (x, y) -> atan(y, x), "c2t")
addDelta = Block([Real], Real, (theta) -> theta + rand()*2*pi, "Δ")
polar2x = Block([Real, Real], Int, (r, th) -> trunc(Int, r * cos(th)), "p2x")
polar2y = Block([Real, Real], Int, (r, th) -> trunc(Int, r * sin(th)), "p2y")

blocks = [cartesian2radius, cartesian2theta, addDelta, polar2x, polar2y]

wire(cartesian2theta.port, addDelta, 1)
wire(cartesian2radius.port, polar2x, 1)
wire(cartesian2radius.port, polar2y, 1)
wire(addDelta.port, polar2x, 2)
wire(addDelta.port, polar2y, 2)
wire(polar2x.port, cartesian2radius, 1)
wire(polar2y.port, cartesian2radius, 2)
wire(polar2x.port, cartesian2theta, 1)
wire(polar2y.port, cartesian2theta, 2)

initialize(cartesian2radius, 500)
initialize(cartesian2theta, 0)

## Uncommenting this will lead to an over-determined initialiation.
# addDelta.port[].value = 1
# addDelta.port[].time = 1

while cartesian2radius.port[].value > 0
  b = rand(blocks)
  v = []
  g = true
  if b.port[].initialized
    for n in b.terminals
      if n[].time != b.port[].time
        g = false
      end
    end
  else
    for n in b.terminals
      if n[].time <= b.port[].time
        g = false
      end
    end
  end
  if g
    v = []
    for n in b.terminals
      push!(v, n[].value)
    end
    y = b.logic(v...)
    b.port[].value = y
    b.port[].time += 1
    if b.name == "c2r"
      println(b.port[].value)
    end
  end
end
