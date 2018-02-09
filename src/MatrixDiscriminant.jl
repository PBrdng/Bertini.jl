module MatrixDiscriminant
   import Iterators
   import MultivariatePolynomials
   const MP = MultivariatePolynomials

   export disc

   @inline function symvec(A::Array{T,2}) where {T<:Number}
      n, m = size(A)
      t = Iterators.subsets(1:n, 2)
      return [[A[i,i] for i in 1:n]; [sqrt(2) * A[i[1], i[2]] for i in t]]
   end
   @inline function symvec(A::Array{T,2}) where {T<:MP.AbstractPolynomialLike}
      n, m = size(A)
      t = Iterators.subsets(1:n, 2)
      return [[A[i,i] for i in 1:n]; [sqrt(2) * A[i[1], i[2]] for i in t]]
   end
   @inline function MPdet(A::Array{T,2}) where {T<:MP.AbstractPolynomialLike}
      if prod(A[:,1] .== zero(T))
         return zero(T)
      else
         D = det(A)
         den = MP.denominator(D)
         num = MP.numerator(D)
         return MP.div(num,den)
      end
   end

   function disc(A::Array{T,2}; SOS = false) where {T<:Number}
     n, m = size(A)
     @assert n == m "A must be symmetric, is $n × $m."
     O = Array{Matrix{T},1}(n)
     O[1] = eye(n)
     for i in 1:n-1
        O[i+1] = O[i] * A
     end
     if issymmetric(A) && eltype(A) <: Real
        O_A = hcat(symvec.(O)...)
        if !SOS
           return det(transpose(O_A) * O_A)
        else
           indices = Iterators.subsets(1:binomial(n+1,2), n)
           return [det(O_A[i,:]) for i in indices]
        end
     else
       O_A = hcat(vec.(O)...)
       return det(transpose(O_A) * O_A)
     end
   end

   function disc(A::Array{T,2}; SOS = false) where {T<:MP.AbstractPolynomialLike}
      n, m = size(A)
      @assert n == m "A must be symmetric, is $n × $m."
      O = Array{Matrix{T},1}(n)
      O[1] = eye(n)
      for i in 1:n-1
         O[i+1] = O[i] * A
      end
      if issymmetric(A) && eltype(eltype(MP.coefficients.(A))) <: Real <: Real
         O_A = hcat(symvec.(O)...)
         if !SOS
           return MPdet(transpose(O_A) * O_A)
         else
           indices = Iterators.subsets(1:binomial(n+1,2), n)
           return [MPdet(O_A[i,:]) for i in indices]
         end
      else
        O_A = hcat(vec.(O)...)
        return MPdet(transpose(O_A) * O_A)
      end
   end
end



# D = det(O_M[1:4,1:4])
# den = MP.denominator(D)
# num = MP.numerator(D)
# MP.div(num,den)
