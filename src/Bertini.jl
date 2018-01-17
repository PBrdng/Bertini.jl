module Bertini

import MultivariatePolynomials
const MP = MultivariatePolynomials

export bertini

function bertini(
    f::Vector{T};
    hom_variable_group = false,
    file_path = "",
    bertini_path = "./",
    TrackType = 0) where {T <: MP.AbstractPolynomialLike}

    bertini_input = ["CONFIG";  "TrackType:$TrackType;"; "END;"; "INPUT"]
    if hom_variable_group
        f_vars = "hom_variable_group "
    else
        f_vars = "variable_group "
    end
    for var in MP.variables(f)
        f_vars = string(f_vars, "$var,")
    end
    f_vars = string(f_vars[1:end-1], ";")
    push!(bertini_input, f_vars)

    functions = "function "
    for i in 1:length(f)
        functions = string(functions, "f$i,")
    end
    functions = string(functions[1:end-1], ";")
    push!(bertini_input, functions)

    for i in 1:length(f)
        push!(bertini_input, "f$i = $(f[i]);")
    end

    push!(bertini_input, "END")

    if file_path != "" && file_path[end] != '/'
        file_path = string(file_path, "/")
    end
    if bertini_path[end] != '/'
        bertini_path = string(bertini_path, "/")
    end

    writedlm("$(file_path)input.txt", bertini_input, '\n')
    run(`$(bertini_path)bertini $(file_path)input.txt`)

    if bertini_path == "./"
        output_path = file_path
    else
        output_path = bertini_path
    end
    if TrackType == 0
        if !hom_variable_group
            A = readdlm("$(output_path)finite_solutions")
            n_vars = length(MP.variables(f))
            finite_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            A = readdlm("$(output_path)nonsingular_solutions")
            n_vars = length(MP.variables(f))
            nonsingular_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            A = readdlm("$(output_path)real_finite_solutions")
            n_vars = length(MP.variables(f))
            real_finite_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            A = readdlm("$(output_path)singular_solutions")
            n_vars = length(MP.variables(f))
            singular_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            return Dict(
                "finite_solutions" => finite_solutions,
                "nonsingular_solutions" => nonsingular_solutions,
                "real_finite_solutions" => real_finite_solutions,
                "singular_solutions" => singular_solutions)
        else
            A = readdlm("$(output_path)nonsingular_solutions")
            n_vars = length(MP.variables(f))
            nonsingular_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            A = readdlm("$(output_path)real_solutions")
            n_vars = length(MP.variables(f))
            real_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            A = readdlm("$(output_path)singular_solutions")
            n_vars = length(MP.variables(f))
            singular_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            return Dict(
                "nonsingular_solutions" => nonsingular_solutions,
                "real_solutions" => real_solutions,
                "singular_solutions" => singular_solutions)
        end
    end
end
end
