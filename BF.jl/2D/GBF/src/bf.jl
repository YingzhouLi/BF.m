include("./julia-support/ndgrid.jl")
using Distributions;
#---------------------------------------------

type ButterflyFactor{T<:Number}
    N ::Int
    U ::SparseMatrixCSC{T}
    G ::Array{SparseMatrixCSC{T},1}
    M ::SparseMatrixCSC{T}
    H ::Array{SparseMatrixCSC{T},1}
    V ::SparseMatrixCSC{T}
    function ButterflyFactor(N,levels)
        U = spzeros(0,0);
        G = Array(SparseMatrixCSC{T},levels);
        M = spzeros(0,0);
        H = Array(SparseMatrixCSC{T},levels);
        V = spzeros(0,0);
        new(N,U,G,M,H,V);
    end
end

type SparseFactor{T<:Number}
    Height ::Int
    Width  ::Int
    Offset ::Int
    XT     ::Array{Int,1}
    YT     ::Array{Int,1}
    ST     ::Array{T,1}
    function SparseFactor(len::Int;H=0,W=0)
        Height = H;
        Width  = W;
        Offset = 0;
        XT     = zeros(Int,len);
        YT     = zeros(Int,len);
        ST     = zeros(T,len);
        new(Height,Width,Offset,XT,YT,ST);
    end
end

#---------------------------------------------

include("./svdtrunc.jl")
include("./lowrank.jl")
include("./lowrankidx.jl")
include("./apply_bf.jl")
include("./apply_bf_adj.jl")
include("./bf_prep.jl")
include("./compression2D.jl")
include("./bf_explicit.jl")
include("./bf_explicit_check.jl")
