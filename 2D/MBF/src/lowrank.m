function [U,S,V,xid,kid,mxid,mkid] = lowrank(fun,xx,kk,r,tol)
    rid = randsample(size(kk,1),r+5);
    A = fun(xx,kk(rid,:))';
    [~,R,E] = qr(A,0);
    rid = E(abs(diag(R))>tol*abs(R(1)));
    A = fun(xx(rid,:),kk);
    [~,R,E] = qr(A,0);
    rid = E(abs(diag(R))>tol*abs(R(1)));
    A = fun(xx,kk(rid,:))';
    [~,R,E] = qr(A,0);
    xid = E(abs(diag(R))>tol*abs(R(1)));
    
    rid = randsample(size(xx,1),r+5);
    A = fun(xx(rid,:),kk);
    [~,R,E] = qr(A,0);
    rid = E(abs(diag(R))>tol*abs(R(1)));
    A = fun(xx,kk(rid,:))';
    [~,R,E] = qr(A,0);
    rid = E(abs(diag(R))>tol*abs(R(1)));
    A = fun(xx(rid,:),kk);
    [~,R,E] = qr(A,0);
    kid = E(abs(diag(R))>tol*abs(R(1)));
    
    mkid = unique([randsample(size(kk,1),r+5)' kid]);
    mxid = unique([randsample(size(xx,1),r+5)' xid]);
    Utmp = fun(xx,kk(kid,:));
    Vtmp = fun(xx(xid,:),kk)';
    Mtmp = fun(xx(mxid,:),kk(mkid,:));
    
    [U,~] = qr(Utmp,0);
    [V,~] = qr(Vtmp,0);
    [Utmp,S,Vtmp] = svdtrunc(pinv(U(mxid,:))*Mtmp*pinv(V(mkid,:)'),r,tol);
    U = U*Utmp;
    V = V*Vtmp;
end