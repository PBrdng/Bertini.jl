# Bertini.jl
Julia wrapper for Bertini (https://bertini.nd.edu). Provides the function `bertini`.


For instance, to solve the polynomial
```math
f(x) = x^2 - 1
```
we type
```julia
using HomotopyContinuation, Bertini

@var x y
f = [x^2 - 1; x - y]

Bertini.bertini(f)
```

The full syntax of `bertini` is as follows
```julia
bertini(
    f;
    hom_variable_group = false,
    file_path = mktempdir(),
    bertini_path = "",
    MPTYPE = nothing,
    MAXNEWTONITS = nothing,
    ENDGAMEBDRY = nothing,
    ENDGAMENUM = nothing,
    TrackType = 0)
```
where
* `hom_variable_group` tells Bertini whether or not we are computing in projective space,
* `file_path` is the path to the folder where you want input.txt being saved to.
* `bertini_path` is the path to the folder where the bertini executable is saved to.
* the other arguments correspond to standard Bertini arguments
