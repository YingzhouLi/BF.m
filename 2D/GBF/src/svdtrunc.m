function [U,S,V] = svdtrunc(A,r,tol, disp_flag)
    if( nargin==3 )
        disp_flag = 0;
    end
if( disp_flag )
    msgbox([num2str(size(A,1)) ' by ' num2str(size(A,2))], 'SVD size', 'replace');
end
    ms = min(size(A));
    [U,S,V] = svd(A,'econ');
    if(ms>r)
        idx = find(find(diag(S)>tol*S(1,1)*max(size(A)))<=r);
        U = U(:,idx);
        S = S(idx,idx);
        V = V(:,idx);
    end
end
