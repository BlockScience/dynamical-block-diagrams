# This is a simple block diagram executor which is configured to
# simulate the diagram described here:
#
# https://hackmd.io/@ekez/HJTHYT8NA
#
# This does not compute execution order ahead of time, nor validate
# initial conditions. Though valid diagrams run with this executor
# ought to have the same behavior as a fully functional one.

using Random

mutable struct Wire
    value::Any
    initialized::Bool
    time::UInt
    function Wire()
        new(nothing, false, 0)
    end
end

struct Block
    inputs::Vector{Ref{Wire}}
    output::Ref{Wire}
    logic::Function
    function Block(logic)
        inputs = length(first(methods(logic)).sig.parameters)-1
        inputs = Vector{Ref{Wire}}(undef, inputs)
        new(inputs, Wire(), logic)
    end
end

function wire(output, block, terminal)
    block.inputs[terminal] = output
end

function initialize(block, value)
    block.output[].value = value
    block.output[].time = 1
    block.output[].initialized = true
end

cartesian2radius = Block((x, y) -> sqrt(x*x+y*y))
cartesian2theta = Block((x, y) -> atan(y, x))
addDelta = Block((theta) -> theta + rand()*2*pi)
polar2x = Block((r, th) -> trunc(Int, r*cos(th)))
polar2y = Block((r, th) -> trunc(Int, r*sin(th)))

blocks = [cartesian2radius, cartesian2theta, addDelta, polar2x, polar2y]

wire(cartesian2theta.output, addDelta, 1)
wire(cartesian2radius.output, polar2x, 1)
wire(cartesian2radius.output, polar2y, 1)
wire(addDelta.output, polar2x, 2)
wire(addDelta.output, polar2y, 2)
wire(polar2x.output, cartesian2radius, 1)
wire(polar2y.output, cartesian2radius, 2)
wire(polar2x.output, cartesian2theta, 1)
wire(polar2y.output, cartesian2theta, 2)

initialize(cartesian2radius, 500)
initialize(cartesian2theta, 0)

# Every wire has a timestamp. At time=0, wires have no value. Every
# time the value on a wire changes its timestamp is incremented.
#
# For a block with an initial value, once all of its inputs have the
# same timestamp as its output, a new value can be computed. For a
# block without an initial value, once all of its inputs have
# timestamps greater than its output, a new value can be
# computed.
#
# This corresponds to the propogation logic of
# dynamical-block-diagrams.pdf: blocks with initial values advance
# their timestep if all of their inputs receive values during
# propogation. Other blocks advance their timestep in response to
# their inputs having advanced timesteps.
#
# The execution logic randomly selects and executes a block if it is
# executable, repeating until the radius has become zero. A complete
# implementation of dynamical-block-diagrams.pdf would use Algorithm 2
# to pre-determine the execution order so no guessing was needed.
while cartesian2radius.output[].value > 0
  b = rand(blocks)
  g = true
  if b.output[].initialized
    for n in b.inputs
      if n[].time != b.output[].time
        g = false
      end
    end
  else
    for n in b.inputs
      if n[].time <= b.output[].time
        g = false
      end
    end
  end
  if g
    v = []
    for n in b.inputs
      push!(v, n[].value)
    end
    y = b.logic(v...)
    b.output[].value = y
    b.output[].time += 1
    if b == cartesian2radius
      println(b.output[].value)
    end
  end
end
