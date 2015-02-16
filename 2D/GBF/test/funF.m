function res = funF(x,k)
    % x and k are column vectors.
    %------------
    xk = (x(:,1)*k(:,1)' + x(:,2)*k(:,2)');

    tmp = (2*pi)* (xk);

    res = complex(cos(tmp),sin(tmp));
end