function svdtrunc(A,r,tol)

    ms = minimum(size(A));
    (U,S,V) = svd(A);
    if(ms>r)
        idx = find(S[1:r].>tol*S[1]);
        U = U[:,idx];
        S = S[idx];
        V = V[:,idx];
    end
    return U,S,V;

end
