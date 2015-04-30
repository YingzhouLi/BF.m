function bf_explicit_check(N::Int,fun::Function,f,u,NC::Int)

    T = Complex{Float64};
    k = -N/2:N/2-1;
    (k1s,k2s) = ndgrid(k,k);
    k1s = reshape(k1s,N^2);
    k2s = reshape(k2s,N^2);
    kk = [k1s k2s];
    app = zeros(T,NC);
    ext = zeros(T,NC);
    for g=1:NC
        x1idx = floor(rand()*N+1);
        x2idx = floor(rand()*N+1);
        xxidx = x1idx + (x2idx-1)*N;
        x1 = (x1idx-1)/N;
        x2 = (x2idx-1)/N;
        xx = [x1 x2];
        app[g] = u[xxidx];
        ext[g] = sum(fun(xx,kk)*f);
    end
    err = app-ext;
    relerr = norm(err)/norm(ext);
    return relerr;

end
