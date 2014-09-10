function res = fun2(x,k,N,r)
    win = tukeyfun(k(:,1),N,r).*tukeyfun(k(:,2),N,r);
    k(:,1) = k(:,1).*win;
    k(:,2) = k(:,2).*win;
    xk = (x(:,1)*k(:,1)' + x(:,2)*k(:,2)');
    kr = sqrt(k(:,1).^2 + k(:,2).^2);
    xr = sqrt(x(:,1).^2 + x(:,2).^2);

    tmp = (2*pi)* (xk + xr*kr');

    res = complex(cos(tmp),sin(tmp));
end