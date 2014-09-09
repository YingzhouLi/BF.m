function Factors = hmbf(N, Factor1, Factor2, xx, xbox, kk, kbox, mR, tol, disp_flag, iter_num)
    Nk = N;
    levels = floor(log2(Nk/mR)/2);
    iter=1;
    Factors = cell(levels,2);
    kkidglobal = 1:size(kk,1);
    while(size(kk,1)>4*mR)
        ckbox = kbox/2;
        ck1s = ckbox(1,1);
        ck1e = ckbox(1,2);
        ck2s = ckbox(2,1);
        ck2e = ckbox(2,2);
        kkid = find( (kk(:,1)<ck1s | kk(:,1)>=ck1e) ...
            | (kk(:,2)<ck2s | kk(:,2)>=ck2e) );
        ckkid = find( kk(:,1)>=ck1s & kk(:,1)<ck1e ...
            & kk(:,2)>=ck2s & kk(:,2)<ck2e );
        Factors{iter,2} = kkidglobal(kkid);
        Factors{iter,1} = ccmbf(N, Nk, Factor1, Factor2, xx, xbox, kk(kkid,:), kbox, mR, tol, disp_flag, iter_num,kkidglobal(kkid));
        iter = iter+1;
        kbox = ckbox;
        kk = kk(ckkid,:);
        kkidglobal = kkidglobal(ckkid);
        Nk = Nk/2;
    end
    Factors{iter,2} = kkidglobal;
    f = zeros(N^2,size(kk,1));
    f(kkidglobal,:) = eye(size(kk,1));
    f = apply_hbf(Factor1,f);
    f = reshape(f,N,N,[]);
    f = fft2(f)/N;
    f = reshape(f,N*N,[]);
    Factors{iter,1} = apply_hbf(Factor2,f);
end