module Bertini

using Base.Filesystem
import MultivariatePolynomials
const MP = MultivariatePolynomials
using DelimitedFiles

export bertini

function bertini(
    f::Vector{T};
    hom_variable_group = false,
    variable_groups = [MP.variables(f)],
    file_path = mktempdir(),
    bertini_path = "",
    TrackType = 0,
    optionalconfig...) where {T <: MP.AbstractPolynomialLike}

    oldpath = pwd()
    cd(file_path)
    println("File path: $(file_path)")

    input = ["CONFIG",
        "TrackType:$TrackType;"]
    for (k, v) in pairs(optionalconfig)
        push!(input, "$k: $v;")
    end
    push!(input, "END;")

    push!(input, "INPUT")

    for vars in variable_groups
        vargroup = hom_variable_group ? "hom_variable_group " : "variable_group "
        vargroup *= join(vars, ",") * ";"
        push!(input, vargroup)
    end

    push!(input, "function " * join(map(i -> "f$i", 1:length(f)), ",") * ";")
    for i in 1:length(f)
        monomials = MP.monomials(f[i])
        fi_data = zip(MP.exponents.(monomials), MP.variables.(monomials), MP.coefficients(f[i]))
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
        push!(input, "f$i = $fi;")
    end

    push!(input, "END")

    if file_path != "" && file_path[end] != '/'
        file_path = string(file_path, "/")
    end
    if !isempty(bertini_path) && bertini_path[end] != '/'
        bertini_path = string(bertini_path, "/")
    end

    writedlm("input.txt", input, '\n')
    @time run(`$(bertini_path)bertini input.txt`)
    n_vars = length(MP.variables(f))
    if TrackType == 0
        finite_solutions = read_solution_file("finite_solutions", n_vars)
        nonsingular_solutions = read_solution_file("nonsingular_solutions", n_vars)
        singular_solutions = read_solution_file("singular_solutions", n_vars)
        real_finite_solutions = read_solution_file("real_finite_solutions", n_vars)
        cd(oldpath)
        return Dict(
            "finite_solutions" => finite_solutions,
            "nonsingular_solutions" => nonsingular_solutions,
            "real_finite_solutions" => real_finite_solutions,
            "singular_solutions" => singular_solutions)
    else
        cd(oldpath)
        throw(error("Currently only `TrackType=0` is supported."))
    end
end

function read_solution_file(filename, n_vars)
    A = readdlm(filename)
    [[A[((j - 1)*n_vars + 1 + i),1] + im * A[((j - 1)*n_vars + 1 + i),2]
      for i in 1:n_vars] for j in 1:A[1,1]]
end

end
