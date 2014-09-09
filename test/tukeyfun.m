function y = tukeyfun(x,N,r)
    if(r<=0)
        y = ones(size(x));
    else
        x = x/N+0.5;
        y = (x<r/2).*(1/2*(1+cos(2*pi/r*(x-r/2)))) + (x>=r/2 & x<1-r/2)...
            +(x>=1-r/2).*(1/2*(1+cos(2*pi/r*(x-1+r/2))));
    end
end