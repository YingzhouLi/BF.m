function fun0(x,k)

xk = (x[:,1]*k[:,1]' + x[:,2]*k[:,2]');
sx = (2 + sin(2*pi*x[:,1]).*sin(2*pi*x[:,2]))/3;
cx = (2 + cos(2*pi*x[:,1]).*cos(2*pi*x[:,2]))/3;
kr = sqrt(sx.^2*(k[:,1].^2)' + cx.^2*(k[:,2].^2)');

tmp = (2*pi)* (xk + kr);

res = complex(cos(tmp),sin(tmp));
return res;

end

#---------------------------------------------------

function fun1(x,k)

xk = (x[:,1]*k[:,1]' + x[:,2]*k[:,2]');
sx = (2 + sin(2*pi*x[:,1]).*sin(2*pi*x[:,2]))/4;
kr = sqrt(sx*(k[:,1].^2)');

tmp = (2*pi)* (xk + kr);

res = complex(cos(tmp),sin(tmp));
return res;

end

#---------------------------------------------------

function fun2(x,k)

xk = (x[:,1]*k[:,1]' + x[:,2]*k[:,2]');
kr = sqrt(k[:,1].^2 + k[:,2].^2);
xr = sqrt(x[:,1].^2 + x[:,2].^2);

tmp = (2*pi)* (xk + xr*kr');

res = complex(cos(tmp),sin(tmp));
return res;

end

#---------------------------------------------------

function funF(x,k)

xk = (x[:,1]*k[:,1]' + x[:,2]*k[:,2]');

tmp = (2*pi)* (xk);

res = complex(cos(tmp),sin(tmp));
return res;

end
