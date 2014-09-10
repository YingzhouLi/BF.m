function res = fun1(x,k,N,r)
    win = tukeyfun(k(:,1),N,r).*tukeyfun(k(:,2),N,r);
    k(:,1) = k(:,1).*win;
    k(:,2) = k(:,2).*win;
    xk = (x(:,1)*k(:,1)' + x(:,2)*k(:,2)');
    sx = (2 + sin(2*pi*x(:,1)).*sin(2*pi*x(:,2)))/9;
    kr = sqrt(sx*(k(:,1).^2)');

    tmp = (2*pi)* (xk + kr);

    res = complex(cos(tmp),sin(tmp));
end
