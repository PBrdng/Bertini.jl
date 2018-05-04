module Bertini

import MultivariatePolynomials
const MP = MultivariatePolynomials

export bertini

function bertini(
    f::Vector{T};
    hom_variable_group = false,
    file_path = pwd(),
    bertini_path = "./",
    TrackType = 0) where {T <: MP.AbstractPolynomialLike}

    oldpath = pwd()
    cd(file_path)

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
        monomials = MP.monomials(f[i])
        fi_data = zip([MP.exponents(m) for m in monomials], [MP.variables(m) for m in monomials], MP.coefficients(f[i]))
        fi = ""
        t = first(fi_data)
        if typeof(t[3]) <: Real
            fi = string(fi, "+($(t[3]))")
        else
            fi = string(fi, "+(")
            fi = string(fi, string(t[3])[1:end-2])
            fi = string(fi, "*I)")
        end
        for j in 1:length(t[1])
            if t[1][j] > 1
                fi = string(fi, "*$(t[2][j]^t[1][j])")
            elseif t[1][j] == 1
                fi = string(fi, "*$(t[2][j])")
            end
        end
        for t in Iterators.drop(fi_data, 1)
            if typeof(t[3]) <: Real
                fi = string(fi, "+($(t[3]))")
            else
                fi = string(fi, "+(")
                fi = string(fi, string(t[3])[1:end-2])
                fi = string(fi, "*I)")
            end

            for j in 1:length(t[1])
                if t[1][j] > 1
                    fi = string(fi, "*$(t[2][j]^t[1][j])")
                elseif t[1][j] == 1
                    fi = string(fi, "*$(t[2][j])")
                end
            end
        end
        push!(bertini_input, "f$i = $fi;")
    end

    push!(bertini_input, "END")

    if file_path != "" && file_path[end] != '/'
        file_path = string(file_path, "/")
    end
    if bertini_path[end] != '/'
        bertini_path = string(bertini_path, "/")
    end

    writedlm("input.txt", bertini_input, '\n')
    run(`$(bertini_path)bertini input.txt`)
    if TrackType == 0
        if !hom_variable_group
            A = readdlm("finite_solutions")
            n_vars = length(MP.variables(f))
            finite_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            A = readdlm("nonsingular_solutions")
            n_vars = length(MP.variables(f))
            nonsingular_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            A = readdlm("real_finite_solutions")
            n_vars = length(MP.variables(f))
            real_finite_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            A = readdlm("singular_solutions")
            n_vars = length(MP.variables(f))
            singular_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            cd(oldpath)
            return Dict(
                "finite_solutions" => finite_solutions,
                "nonsingular_solutions" => nonsingular_solutions,
                "real_finite_solutions" => real_finite_solutions,
                "singular_solutions" => singular_solutions)
        else
            A = readdlm("nonsingular_solutions")
            n_vars = length(MP.variables(f))
            nonsingular_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            A = readdlm("real_solutions")
            n_vars = length(MP.variables(f))
            real_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            A = readdlm("singular_solutions")
            n_vars = length(MP.variables(f))
            singular_solutions = [[A[(j+i),1] + im * A[(j+i),2] for i in 1:n_vars] for j in 1:A[1,1]]

            cd(oldpath)
            return Dict(
                "nonsingular_solutions" => nonsingular_solutions,
                "real_solutions" => real_solutions,
                "singular_solutions" => singular_solutions)
        end
    end
    cd(oldpath)
end
end
