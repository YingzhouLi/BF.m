function lowrankidx(x,p,fun::Function,tol,mR::Int,
    Ridx::Array{Int,1},Cidx::Array{Int,1},rs::Array{Int,1},cs::Array{Int,1})

    T = Complex{Float64};

    Nx = size(x,1);
    Np = size(p,1);

    if( Nx==0 || Np==0 )
        U = zeros(T,Nx,0);
        S = zeros(T,0,0);
        V = zeros(T,Np,0);
        return U,S,V;
    end

    #get rows
    MR = fun(x[Ridx,:],p);

    #get columns
    MC = fun(x,p[Cidx,:]);

    #get middle matrix
    (QC,~,~) = qr(MC,pivot=true);
    (QR,~,~) = qr(MR',pivot=true);

    M1 = QC[rs,:];
    M2 = QR[cs,:];
    M3 = fun(x[rs,:],p[cs,:]);
    MD = pinv(M1) * (M3* pinv(M2'));
    (U,S,V) = svdtrunc(MD,mR,tol);
    U = QC*U;
    V = QR*V;
    return U,S,V;

end
