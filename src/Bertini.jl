module Bertini

export bertini

import HomotopyContinuation
const HC = HomotopyContinuation
using DelimitedFiles

"""
    bertini(
        f,
        S = nothing;
        hom_variable_group = false,
        variable_groups = [f.variables],
        parameters = f.parameters,
        file_path = mktempdir(),
        start_parameters = isempty(parameters) ? nothing :
                           UndefKeywordError(:start_parameters),
        final_parameters = isempty(parameters) ? nothing :
                           UndefKeywordError(:final_parameters),
        bertini_path = "",
        TrackType = 0,
        optionalconfig...,
    )

Run bertini.
"""
function bertini(
    f::HC.System,
    S = nothing;
    hom_variable_group = false,
    variable_groups = [f.variables],
    parameters = f.parameters,
    file_path = mktempdir(),
    start_parameters = isempty(parameters) ? nothing :
                       throw(UndefKeywordError(:start_parameters)),
    final_parameters = isempty(parameters) ? nothing :
                       throw(UndefKeywordError(:final_parameters)),
    bertini_path = "",
    TrackType = 0,
    optionalconfig...,
)
    oldpath = pwd()
    cd(file_path)
    println("File path: $(file_path)")

    input = ["CONFIG", "TrackType:$TrackType;"]
    for (k, v) in optionalconfig
        push!(input, "$k: $v;")
    end
    if !isempty(parameters)
        push!(input, "PARAMETERHOMOTOPY: 2;")
    end

    push!(input, "END;")

    push!(input, "INPUT")

    nvars = sum(length, variable_groups)
    for vars in variable_groups
        vargroup = hom_variable_group ? "hom_variable_group " :
                   "variable_group "
        vargroup *= join(vars, ",") * ";"
        push!(input, vargroup)
    end

    if !isempty(f.parameters)
        push!(input, "parameter " * join(f.parameters, ",") * ";")
    end

    n = length(f)
    push!(input, "function " * join(map(i -> "f$i", 1:n), ",") * ";")

    for (i, fi) in enumerate(f)
        push!(input, "f$i = $(fi);")
    end
    push!(input, "END")
    # replace complex numbers
    input = map(line -> replace(line, r"(^|\W)(im)(\W|$)" => s"\1I\3"), input)
    writedlm("input", input, '\n')

    if !isempty(parameters)
        if S === nothing
            throw(ArgumentError("start solutions not given."))
        end
        HC.write_solutions(joinpath(file_path, "start"), S)
        HC.write_parameters(
            joinpath(file_path, "start_parameters"),
            start_parameters,
        )
        HC.write_parameters(
            joinpath(file_path, "final_parameters"),
            final_parameters,
        )
    end

    if bertini_path == ""
        @time run(`bertini input`)
    else
        @time run(`$(bertini_path)/bertini input`)
    end


    finite_solutions = HC.read_solutions("finite_solutions")
    runtime = open(joinpath(file_path, "output")) do f
        while true
            x = readline(f)
            if eof(f)
                return parse(Float64, split(x, " = ")[2][1:end-1])
            end
        end
    end

    return Dict(
        :file_path => file_path,
        :finite_solutions => finite_solutions,
        :runtime => runtime,
    )
end

end # module
