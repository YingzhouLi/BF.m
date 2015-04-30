function apply_bf_adj(Factor, y)

    if( size(y,2)==0 )
        return;
    end

    y = Factor.U'*y;

    for i=length(Factor.G):-1:1
        y = Factor.G[i]'*y;
    end

    y = Factor.M'*y;

    for i=1:length(Factor.H)
        y = Factor.H[i]*y;
    end

    y = Factor.V*y;

    return y;

end
