function bf_explicit(fun::Function, xx, xbox, kk, kbox,
    mR::Int, tol, disp_flag::Bool)

    T = Complex{Float64};
    if(disp_flag)
        @printf("Butterfly Factorization explicit version started...\n\n");
    end

    # Nx is the square root of the number of target points in space
    Nxx = size(xx,1);
    Nx = ifloor((sqrt(Nxx)));
    # Nk is the square root of the number of source points in phase
    Nkk = size(kk,1);
    Nk = ifloor(sqrt(Nkk));

    tR = mR+5;

    # npx is the number of blocks of each dimension in space
    npx1 = int(exp2(iceil(log2(sqrt(Nx)))));
    npx2 = int(exp2(iceil(log2(sqrt(Nx)))));
    # npp is the number of blocks of each dimension in phase
    npk1 = int(exp2(iceil(log2(sqrt(Nk)))));
    npk2 = int(exp2(iceil(log2(sqrt(Nk)))));

    if(disp_flag)
        @printf("   Space      Frequence\n");
        @printf("  npx1  npx2  npk1  npk2\n");
        @printf("  %4d  %4d  %4d  %4d\n\n",npx1,npx2,npk1,npk2);
    end

    P = Array(Array{T,1},npx1,npx2,npk1,npk2);
    Ridx = Array(Array{Int,1},npx1,npx2,npk1,npk2);
    Cidx = Array(Array{Int,1},npx1,npx2,npk1,npk2);
    rs = Array(Array{Int,1},npx1,npx2,npk1,npk2);
    cs = Array(Array{Int,1},npx1,npx2,npk1,npk2);

    xidx = bf_prep(xx,xbox,npx1,npx2);
    kidx = bf_prep(kk,kbox,npk1,npk2);

    levels = max(iceil(log2(Nkk/npk1/npk2/mR/4)),0);
    LS = 4*mR^2*npk1*npk2*npx1*npx2;

    Factor = ButterflyFactor{T}(Nx,levels);

    if(disp_flag)
        @printf("Compression levels: %d\n",levels);
        @printf("Preallocated sparse matrix size: %d, about %.2f GB\n",
            LS,LS*(levels+2)*(2*8+16)/1024/1024/1024);
    end

    CPreSpr = Array(SparseFactor{T},levels);
    for iter = 1:levels
        CPreSpr[iter] = SparseFactor{T}(LS);
    end
    WPreSpr = SparseFactor{T}(LS,H=Nxx);

    for x1=1:npx1, x2=1:npx2
        U = Array(Array{T,2},npk1,npk2);
        for k1=1:npk1, k2=1:npk2
            ik = kidx[k1,k2];
            ix = xidx[x1,x2];
            (U[k1,k2],Stmp,~,Ridx[x1,x2,k1,k2],Cidx[x1,x2,k1,k2],
             rs[x1,x2,k1,k2],cs[x1,x2,k1,k2]) =
                lowrank(xx[ix,:], kk[ik,:], fun, tol, tR, mR);
            P[x1,x2,k1,k2] = 1./Stmp;
            U[k1,k2] = U[k1,k2].*Stmp';
        end
        xxsub = xx[xidx[x1,x2],:];
        x1os = xbox[1,1];
        x1len = xbox[1,2]-xbox[1,1];
        x2os = xbox[2,1];
        x2len = xbox[2,2]-xbox[2,1];
        xsubbox = [ x1os+(x1-1)*x1len/npx1 x1os+x1*x1len/npx1;
            x2os+(x2-1)*x2len/npx2 x2os+x2*x2len/npx2];
        if(disp_flag)
            if( x1==1 && x2==1 )
                @printf("Compress U block: (%4d/%4d) by (%4d/%4d)",
                    x1,npx1,x2,npx2);
            else
                @printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");
                @printf("(%4d/%4d) by (%4d/%4d)",x1,npx1,x2,npx2);
            end
        end
        compression2D(WPreSpr,CPreSpr,U,
            xxsub,xidx[x1,x2],xsubbox,mR,tol,1,levels);
    end

    if(disp_flag)
        @printf("\n");
    end

    Uid = find(WPreSpr.ST .!= 0);
    Factor.U = sparse(WPreSpr.XT[Uid],WPreSpr.YT[Uid],WPreSpr.ST[Uid]);
    if(disp_flag)
        if(WPreSpr.Offset>2*LS)
            @printf("Bad preallocation U, %d is required\n",WPreSpr.Offset);
        end
    end

    for l=1:levels
        Aid = find(CPreSpr[l].ST .!= 0);
        Factor.G[l] =
            sparse(CPreSpr[l].XT[Aid],CPreSpr[l].YT[Aid],CPreSpr[l].ST[Aid]);
        if(disp_flag)
            if(CPreSpr[l].Offset>LS)
                @printf("Bad preallocation A, %d is required\n",
                    CPreSpr[l].Offset);
            end
        end
    end

    for iter = 1:levels
        CPreSpr[iter] = SparseFactor{T}(LS);
    end
    WPreSpr = SparseFactor{T}(LS,H=Nkk);

    for k1=1:npk1, k2=1:npk2
        V = Array(Array{T,2},npx1,npx2);
        for x1=1:npx1, x2=1:npx2
            ik = kidx[k1,k2];
            ix = xidx[x1,x2];
            (~,Stmp,V[x1,x2]) = lowrankidx(xx[ix,:],kk[ik,:],fun,tol,mR,
                Ridx[x1,x2,k1,k2],Cidx[x1,x2,k1,k2],
                rs[x1,x2,k1,k2],cs[x1,x2,k1,k2]);
            V[x1,x2] = V[x1,x2].*Stmp';
        end
        kksub = kk[kidx[k1,k2],:];
        k1os = kbox[1,1];
        k1len = kbox[1,2]-kbox[1,1];
        k2os = kbox[2,1];
        k2len = kbox[2,2]-kbox[2,1];
        ksubbox = [ k1os+(k1-1)*k1len/npk1 k1os+k1*k1len/npk1;
            k2os+(k2-1)*k2len/npk2 k2os+k2*k2len/npk2];
        if(disp_flag)
            if( k1==1 && k2==1 )
                @printf("Compress V block: (%4d/%4d) by (%4d/%4d)",
                    k1,npk1,k2,npk2);
            else
                @printf("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");
                @printf("(%4d/%4d) by (%4d/%4d)",k1,npk1,k2,npk2);
            end
        end
        compression2D(WPreSpr,CPreSpr,V,
            kksub,kidx[k1,k2],ksubbox,mR,tol,1,levels);
    end

    if(disp_flag)
        @printf("\n");
    end

    Vid = find(WPreSpr.ST .!= 0);
    Factor.V = sparse(WPreSpr.XT[Vid],WPreSpr.YT[Vid],WPreSpr.ST[Vid]);
    if(disp_flag)
        if(WPreSpr.Offset>2*LS)
            @printf("Bad preallocation V, %d is required\n",WPreSpr.Offset);
        end
    end
    for l=1:levels
        Bid = find(CPreSpr[l].ST .!= 0);
        Factor.H[l] = sparse(CPreSpr[l].XT[Bid],CPreSpr[l].YT[Bid],
            CPreSpr[l].ST[Bid]);
        if(disp_flag)
            if(CPreSpr[l].Offset>LS)
                @printf("Bad preallocation B, %d is required\n",
                    CPreSpr[l].Offset);
            end
        end
    end

    totalH = zeros(npx1*npx2);
    for x1=1:npx1, x2=1:npx2, k1=1:npk1, k2=1:npk2
        x = (x1-1)*npx2+x2;
        totalH[x] += length(P[x1,x2,k1,k2]);
    end
    currentH = zeros(npx1*npx2);
    for x1=1:npx1, x2 =1:npx2
        x = (x1-1)*npx2+x2;
        if(x>1)
            currentH[x] = currentH[x-1]+totalH[x-1];
        end
    end

    totalW = zeros(npk1*npk2);
    for k1=1:npk1, k2=1:npk2, x1=1:npx1, x2=1:npx2
        k = (k1-1)*npk2+k2;
        totalW[k] += length(P[x1,x2,k1,k2]);
    end
    currentW = zeros(npk1*npk2);
    for k1=1:npk1, k2=1:npk2
        k = (k1-1)*npk2+k2;
        if(k>1)
            currentW[k] = currentW[k-1]+totalW[k-1];
        end
    end

    totalel = 0;
    for x1=1:npx1, x2=1:npx2, k1=1:npk1, k2=1:npk2
        totalel += length(P[x1,x2,k1,k2]);
    end

    offset = 0;
    XT = zeros(Int,totalel);
    YT = zeros(Int,totalel);
    ST = zeros(totalel);
    for x1=1:npx1, x2=1:npx2
        x = (x1-1)*npx2+x2;
        localH = currentH[x];
        for k1=1:npk1, k2=1:npk2
            k = (k1-1)*npk2+k2;
            Mlen = length(P[x1,x2,k1,k2]);
            X = localH+(1:Mlen);
            Y = currentW[k]+(1:Mlen);
            idx = offset+1:offset+length(X);
            XT[idx] = X;
            YT[idx] = Y;
            ST[idx] = P[x1,x2,k1,k2];
            if(~isempty(idx))
                offset = idx[end];
            end
            localH += Mlen;
            currentW[k] += Mlen;
        end
    end
    Factor.M = sparse(XT,YT,ST);

    return Factor;

end
