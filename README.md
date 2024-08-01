We describe a way block diagrams can be used to model dynamical
systems. We detail and prove the validity of static analysis procedures to:

1. Determine the execution order of an arbitrary diagram.
2. Determine if the initial values on a diagram are inconsistent.

Please see
[dynamical-block-diagrams.pdf](dynamical-block-diagrams.pdf) for more
details.

This project is a work in progress, we expect future work will
integrate these analysis techniques into
[cadCAD](https://github.com/cadCAD-org/cadCAD.jl).


[basic-executor.jl](basic-executor.jl) contains a very simple block
diagram execution library based on the semantics described in the
essay. It performs no validation, but on valid diagrams should produce
the same results as a fully functional one.
