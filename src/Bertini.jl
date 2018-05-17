module Bertini

using Base.Filesystem
import MultivariatePolynomials
const MP = MultivariatePolynomials

export bertini

function bertini(
    f::Vector{T};
    hom_variable_group = false,
    file_path = mktempdir(),
    bertini_path = "",
    MPTYPE = nothing,
    MAXNEWTONITS = nothing,
    ENDGAMEBDRY = nothing,
    ENDGAMENUM = nothing,
    TrackType = 0) where {T <: MP.AbstractPolynomialLike}

    oldpath = pwd()
    cd(file_path)
    println("File path: $(file_path)")

    bertini_input = ["CONFIG",
        "TrackType:$TrackType;"]
    MPTYPE != nothing && push!(bertini_input, "MPTYPE: $MPTYPE;")
    ENDGAMEBDRY != nothing && push!(bertini_input, "ENDGAMEBDRY: $ENDGAMEBDRY;")
    ENDGAMENUM != nothing && push!(bertini_input, "ENDGAMENUM: $ENDGAMENUM;")
    MAXNEWTONITS != nothing && push!(bertini_input, "MAXNEWTONITS: $MAXNEWTONITS;")
    push!(bertini_input, "END;", "INPUT")

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
    if !isempty(bertini_path) && bertini_path[end] != '/'
        bertini_path = string(bertini_path, "/")
    end

    writedlm("input.txt", bertini_input, '\n')
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
