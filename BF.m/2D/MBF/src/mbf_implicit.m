function Factors = mbf_implicit(fun, fun_adj, xx, xbox, kk, kbox, mR, tol, disp_flag)

    function y = fun_restrict(fun,x,NN,idx)
        xall = zeros(NN,size(x,2));
        xall(idx,:) = x;
        y = fun(xall);
    end

    function x = fun_adj_restrict(fun_adj,y,idx)
        xall = fun_adj(y);
        x = xall(idx,:);
    end

NN = size(kk,1);
Nkk = size(kk,1);
levels = max(floor(log2(Nkk/2^2/mR^2)/2),0)+1;
Factors = cell(levels,2);
kkidglobal = 1:size(kk,1);
for iter = 1:levels-1
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
    Factors{iter,1} = bf_implicit(@(x)fun_restrict(fun,x,NN,kkidglobal(kkid)),...
        @(y)fun_adj_restrict(fun_adj,y,kkidglobal(kkid)),...
        xx, xbox, kk(kkid,:), kbox, mR, tol, disp_flag);
    kbox = ckbox;
    kk = kk(ckkid,:);
    kkidglobal = kkidglobal(ckkid);
end
Factors{end,2} = kkidglobal;
Nkk = size(kk,1);
xvec = zeros(NN,Nkk);
xvec(kkidglobal,:) = eye(Nkk);
Factors{end,1} = fun(xvec);

end