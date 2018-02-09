# Bertini.jl
Julia wrapper for Bertini (https://bertini.nd.edu). Provides the function `bertini`.

Uses the Julia package [DynamicPolynomials.jl](https://github.com/JuliaAlgebra/DynamicPolynomials.jl).

For instance, to solve the polynomial
```math
f(x) = x^2 - 1
```
we type
```julia
using Bertini
using DynamicPolynomials

@polyvar x
f = [x^2 - 1]

bertini(f)
```

The full syntax of `bertini` is as follows
```julia
bertini(
    f::Vector{T};
    hom_variable_group = false,
    file_path = "",
    bertini_path = "./",
    TrackType = 0)
```
where
* `T` is the polynomial type provided by DynamicPolynomials.
* `hom_variable_group` tells Bertini whether or not we are computing in projective space,
* `file_path` is the path to the folder where you want input.txt being saved to.
* `bertini_path` is the path to the folder where the bertini executable is saved to.
* `TrackType` sets the TrackType variable of Bertini.
