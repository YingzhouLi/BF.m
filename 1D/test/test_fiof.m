%close all;
%clear all;
%clc;

addpath('../src/');
data_path = './data/';
log_path = './log/';

if(~exist(data_path, 'dir'))
    mkdir(data_path);
end
if(~exist(log_path, 'dir'))
    mkdir(log_path);
end

midall = cell(1,16);
recurall = cell(1,16);
global midstats recurstats

for i=10:2:16
  %% Set up parameters
  N = 2^i; %powers of 2 from 64 to 65536;
  tol=1e-9;
  mR = 8;         %max rank
  

  kbox = [1,N+1];
  k = 1:N;
  kk = k(:);
  
  xbox = [1,N+1];
  x = 1:N;
  xx = x(:);

  func_name = 'fun3';
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


  %% Begin test
  if(1)
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

    midstats = zeros(1,10);
    recurstats = zeros(1,10);
    tic;
    Factor = fiof(N, fun, xx, xbox, kk, kbox, mR, tol, 1);
    FactorT = toc;
    midall{i} = midstats;
    recurall{i} = recurstats;
    
    figure('position',[.1 .1 1500 600])
    subplot(1,3,1);
    plot(midstats,'-x');
    title([num2str(N) ' middle level rank stat, tol: ' num2str(tol)]);
    grid on;
    set(gca,'XTick',1:10);
    set(gca,'XTickLabel',1:10);
    subplot(1,3,2);
    plot(recurstats,'-x');
    title([num2str(N) ' recursion rank stat, tol: ' num2str(tol)]);
    grid on;
    set(gca,'XTick',1:10);
    set(gca,'XTickLabel',1:10);
    subplot(1,3,3);
    plot(midstats+recurstats,'-x');
    title([num2str(N) ' total rank stat, tol: ' num2str(tol)]);
    grid on;
    set(gca,'XTick',1:10);
    set(gca,'XTickLabel',1:10);
    saveas(gcf, [log_path 'Rank stat N' num2str(N) ' tol' num2str(tol)], 'fig');
    saveas(gcf, [log_path 'Rank stat N' num2str(N) ' tol' num2str(tol)], 'epsc');
    
    tic;
    yy = apply_mfiof(Factor,f);
    ApplyT = toc;
    RunT = FactorT + ApplyT;
    
    NC = 256;
    tic;
    relerr = fiof_check(N,fun,f,yy,NC);
    Td = toc;
    Td = Td*N/NC;

    disp(['------------------------------------------']);
    disp(['N                 : ' num2str(N)]);
    disp(['Max Rank          : ' num2str(mR)]);
    disp(['Tolerance         : ' num2str(tol)]);
    disp(['Relative Error_2  : ' num2str(relerr)]);
    disp(['Direct Time       : ' num2str(Td) ' s']);
    disp(['Running Time      : ' num2str(RunT/60) ' mins']);
    disp(['Factorization Time: ' num2str(FactorT/60) ' mins']);
    disp(['Applying Time     : ' num2str(ApplyT) ' s']);
    disp(['------------------------------------------']);

    save([data_path 'Factor_' func_name '_' num2str(N) '_' num2str(mR) '.mat'],'Factor','-v7.3');
    %fid = fopen([log_path 'Factor_' func_name '_' num2str(N) '_' num2str(mR) '.log'],'w+');
    %fclose(fid);

  end
end
