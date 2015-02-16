function run_fiof(N, func_name, mR, tol, fig)

addpath('../src/');
data_path = './data/';

if(~exist(data_path, 'dir'))
    mkdir(data_path);
end
    
  kbox = [1,N+1];
  k = 1:N;
  kk = k(:);
  
  xbox = [1,N+1];
  x = 1:N;
  xx = x(:);

  switch func_name
    case 'funF'
        fun = @(x,k)funF(N,x,k);
    case 'fun0'
        fun = @(x,k)fun0(N,x,k);
    case 'fun2'
        fun = @(x,k)fun2(N,x,k);
    case 'fun3' % bessel function
        fun = @(x,k)fun3(N,x,k);
  end


    if(1)
        f = randn(N,1) + sqrt(-1)*randn(N,1);
        binstr = sprintf('f_%d.bin', N);
        fid = fopen(binstr,'w');
        string = {'CpxNumMat'};
        serialize(fid, f, string);
    end
    if(1)
        binstr = sprintf('f_%d.bin', N);
        fid = fopen(binstr,'r');
        string = {'CpxNumMat'};
        f = deserialize(fid, string);
    end

    tic;
    Factor = fiof(N, fun, xx, xbox, kk, kbox, mR, tol, 1);
    FactorT = toc;

    tic;
    yy = apply_mfiof(Factor,f);
    ApplyT = toc;
    RunT = FactorT + ApplyT;
    
    NC = 256;
    tic;
    relerr = fiof_check(N,fun,f,yy,NC);
    Td = toc;
    Td = Td*N/NC;

    fprintf(fig,'------------------------------------------\n');
    fprintf(fig,'N                 : %4d\n', N);
    fprintf(fig,'Max Rank          : %4d\n', mR);
    fprintf(fig,'Tolerance         : %.3e\n', tol);
    fprintf(fig,'Relative Error_2  : %.3e\n', relerr);
    fprintf(fig,'Direct Time       : %.3e s\n', Td);
    fprintf(fig,'Running Time      : %.3e mins\n', RunT/60);
    fprintf(fig,'Factorization Time: %.3e mins\n', FactorT/60);
    fprintf(fig,'Applying Time     : %.3e s\n', ApplyT);
    fprintf(fig,'------------------------------------------\n\n');

    save([data_path 'Factor_' func_name '_' num2str(N) '_' num2str(mR) '.mat'],'Factor','-v7.3');

end
