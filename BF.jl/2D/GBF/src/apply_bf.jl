function apply_bf(Factor, y)

    if( size(y,2)==0 )
        return;
    end

    y = Factor.V'*y;

    for i=length(Factor.H):-1:1
        y = Factor.H[i]'*y;
    end

    y = Factor.M*y;

    for i=1:length(Factor.G)
        y = Factor.G[i]*y;
    end

    y = Factor.U*y;

    return y;

end
