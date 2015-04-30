function compile_explicit()
# Set up parameters
N   = 8;
tol = 1e-1;
mR  = 1;

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

fun = funF;

f = randn(N,N) + 1im*randn(N,N);
f = reshape(f,N^2);

Factor = bf_explicit(fun, xx, xbox, kk, kbox, mR, tol, false);

yy = apply_bf(Factor,f);

NC = 1;
relerr = bf_explicit_check(N,fun,f,yy,NC);

end
