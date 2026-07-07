module Bertini

export bertini

import HomotopyContinuation
using HomotopyContinuation: @var
using HomotopyContinuation: @polyvar
export @var
export @polyvar
const HC = HomotopyContinuation
using DelimitedFiles

function read_output_file(file_path, filename; required = true)
    path = joinpath(file_path, filename)
    isfile(path) && return read(path, String)
    required && throw(ArgumentError("Bertini did not create '$filename'."))
    nothing
end

function bertini_output(file_path, TrackType, runtime)

    if TrackType == 0
        return Dict(
            :file_path => file_path,
            :finite_solutions => HC.read_solutions(joinpath(file_path, "finite_solutions")),
            :runtime => runtime,
        )
    elseif TrackType == 1
        return Dict(
            :file_path => file_path,
            :main_data => read_output_file(file_path, "main_data"),
            :witness_data => read_output_file(file_path, "witness_data"),
            :regenSummary => read_output_file(file_path, "regenSummary"; required = false),
            :runtime => runtime,
        )
    else
        throw(ArgumentError("Unsupported TrackType $TrackType."))
    end
end

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
    file_path = abspath(file_path)
    oldpath = pwd()
    cd(file_path)
    try
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

        cmd = bertini_path == "" ? `bertini input` : `$(bertini_path)/bertini input`
        runtime = @elapsed run(cmd)


        return bertini_output(file_path, TrackType, runtime)
    finally
        cd(oldpath)
    end
end

function bertini(
        f::Vector{HC.Expression},
        S = nothing;
        kwargs...
    )
    bertini(HC.System(f), S; kwargs...)
end
function bertini(
        f::HC.Expression,
        S = nothing;
        kwargs...
    )
    bertini(HC.System([f]), S; kwargs...)
end
end # module
