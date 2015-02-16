close all;
clear all;
clc;

addpath('../src/');
data_path = './data/';
log_path = './log/';

if(~exist(data_path, 'dir'))
    mkdir(data_path);
end
if(~exist(log_path, 'dir'))
    mkdir(log_path);
end

%% Set up parameters
N = 256;
tol=1e-5;
mR = 4;         %max rank

kbox = [1,N+1];
k = 1:N;
kk = k(:);

xbox = [1,N+1];
x = 1:N;
xx = x(:);

FmR = 4;
func1_name = 'fun0';
func2_name = 'fun0';
Factor1 = load([data_path 'Factor_' func1_name '_' num2str(N) '_' num2str(FmR) '.mat'],'Factor');
%Factor2 = load([data_path 'Factor_' func2_name '_' num2str(N) '_' num2str(FmR) '.mat'],'Factor');
Factor2=Factor1;

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

    disp(['------------------------------------------']);
    disp(['N                 : ' num2str(N)]);
    disp(['Max Rank          : ' num2str(mR)]);
    disp(['Tolerance         : ' num2str(tol)]);
    disp(['Relative Error_2  : ' num2str(relerr)]);
    disp(['Running Time      : ' num2str(RunT/60) ' mins']);
    disp(['Factorization Time: ' num2str(FactorT/60) ' mins']);
    disp(['Applying Time     : ' num2str(ApplyT) ' s']);
    disp(['------------------------------------------']);

    save([data_path 'Factor_' func1_name '_' func2_name '_' num2str(N) '_' num2str(mR) '.mat'],'Factor','-v7.3');
end
