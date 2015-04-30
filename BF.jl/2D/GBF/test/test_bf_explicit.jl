include("../src/bf.jl");
include("./funcs.jl");
include("./compile_explicit.jl");
data_path = "data/";

if ~isdir(data_path)
    mkdir(data_path);
end

compile_explicit();

# Set up parameters
N   = 256;
tol = 1e-4;
mR  = 16;

# Here the range is from -N/2 to N/2-1 for each dimension of k
# and 0 to 1-1/N for each dimension of x.

kbox      = [-N/2 N/2;-N/2 N/2];
k         = -N/2:N/2-1;
(k1s,k2s) = ndgrid(k,k);
k1s       = reshape(k1s,N^2);
k2s       = reshape(k2s,N^2);
kk        = [k1s k2s];

xbox      = [0 1;0 1];
x         = (0:N-1)/N;
(x1s,x2s) = ndgrid(x,x);
x1s       = reshape(x1s,N^2);
x2s       = reshape(x2s,N^2);
xx        = [x1s x2s];

func_name = "funF";
if func_name == "funF"
    fun = funF;
elseif func_name == "fun0"
    fun = fun0;
elseif func_name == "fun1"
    fun = fun1;
elseif func_name == "fun2"
    fun = fun2;
end

## Begin test
if true
    f = randn(N,N) + 1im*randn(N,N);
    fid = open("f_"*string(N)*".bin","w");
    serialize(fid,f);
    close(fid);
end
if false
    fid = open("f_"*string(N)*".bin","r");
    f = deserialize(fid);
    close(fid);
end
f = reshape(f,N^2);

tic();
Factor = bf_explicit(fun, xx, xbox, kk, kbox, mR, tol, true);
FactorT = toc();

tic();
yy = apply_bf(Factor,f);
ApplyT = toc();
RunT = FactorT + ApplyT;

NC = 256;
tic();
relerr = bf_explicit_check(N,fun,f,yy,NC);
Td = toc();
Td = Td*N^2/NC;

println("------------------------------------------");
println("N                 : "*string(N));
println("Max Rank          : "*string(mR));
println("Tolerance         : "*string(tol));
println("Relative Error_2  : "*string(relerr));
println("Direct Time       : "*string(Td)*" s");
println("Running Time      : "*string(RunT/60)*" mins");
println("Factorization Time: "*string(FactorT/60)*" mins");
println("Applying Time     : "*string(ApplyT)*" s");
println("------------------------------------------");

fid = open(data_path*"Factor_"*func_name*"_"*string(N)*"_"*string(mR)*".bin",
    "w");
serialize(fid,Factor);
close(fid);
