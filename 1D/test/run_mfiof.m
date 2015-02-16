function run_mfiof(N, Factor1, Factor2, mR, tol, fig)

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

%% Begin test
    if(1)
        f = randn(N,1) + sqrt(-1)*randn(N,1);
        binstr = sprintf('f_%d.bin', N);
        fid = fopen(binstr,'w');
        string = {'CpxNumMat'};
        serialize(fid, f, string);
    end
    if(0)
        binstr = sprintf('f_%d.bin', N);
        fid = fopen(binstr,'r');
        string = {'CpxNumMat'};
        f = deserialize(fid, string);
    end

    tic;
    y = apply_mfiof(Factor1.Factor,f);
    y = fft(y)/sqrt(N);
    y = apply_mfiof(Factor2.Factor,y);
    Td = toc;

    tic;
    Factor = mfiof(N, Factor1.Factor, Factor2.Factor, xx, xbox, kk, kbox, mR, tol, 1);
    FactorT = toc;

    tic;
    yy = apply_mfiof(Factor,f);
    ApplyT = toc;
    RunT = FactorT + ApplyT;
    
    NC = 256;
    relerr = mfiof_check(N,y,yy,NC);

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

end
