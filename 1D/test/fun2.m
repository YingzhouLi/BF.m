function res = fun2(N,x,k)
    x = (x-1)/N;
    k = k-1-N/2;
    xk = x*k';
    tmp = (2*pi)* (xk);
    res = complex(cos(tmp),sin(tmp));
end