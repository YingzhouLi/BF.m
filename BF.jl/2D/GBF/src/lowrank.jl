function lowrank(x,p,fun::Function,tol,tR::Int,mR::Int)

    T = Complex{Float64};

    Nx = size(x,1);
    Np = size(p,1);

    if( Nx==0 || Np==0 )
        U = zeros(T,Nx,0);
        S = zeros(T,0,0);
        V = zeros(T,Np,0);
        Ridx = Int[];
        Cidx = Int[];
        rs = Int[];
        cs = Int[];
        return U,S,V,Ridx,Cidx,rs,cs;
    end

    Ridx = Int[];
    Cidx = Int[];

    if(tR<Np && tR<Nx)
        for iter=1:2
            # get columns
            rs = sample(1:Nx,tR,replace=false);
            rs = unique([rs,Ridx]);
            M2 = fun(x[rs,:],p);
            (~,R2,E2) = qr(M2,pivot=true);
            Cidx = E2[find(abs(diag(R2)[1:tR]).>tol*abs(R2[1,1]))];

            # get rows
            cs = sample(1:Np,tR,replace=false);
            cs = unique([cs,Cidx]);
            M1 = fun(x,p[cs,:]);
            (~,R1,E1) = qr(M1',pivot=true);
            Ridx = E1[find(abs(diag(R1)[1:tR]).>tol*abs(R1[1,1]))];
        end
    else
        Ridx = 1:Nx;
        Cidx = 1:Np;
    end

    #get rows
    MR = fun(x[Ridx,:],p);

    #get columns
    MC = fun(x,p[Cidx,:]);

    #get middle matrix
    (QC,~,~) = qr(MC,pivot=true);
    (QR,~,~) = qr(MR',pivot=true);

    if(tR<Np && tR<Nx)
        cs = sample(1:Np,tR,replace=false);
        cs = unique([cs,Cidx]);
        rs = sample(1:Nx,tR,replace=false);
        rs = unique([rs,Ridx]);
    else
        cs = 1:Np;
        rs = 1:Nx;
    end

    M1 = QC[rs,:];
    M2 = QR[cs,:];
    M3 = fun(x[rs,:],p[cs,:]);
    MD = pinv(M1) * (M3* pinv(M2'));
    (U,S,V) = svdtrunc(MD,mR,tol);
    U = QC*U;
    V = QR*V;
    return U,S,V,Ridx,Cidx,rs,cs;

end
