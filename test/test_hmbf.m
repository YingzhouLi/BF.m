close all;
clear all;
clc;

addpath('../src/');
data_path = '/home/ryanli/Documents/Research/HBF/data/';
log_path = './log/';

if(~exist(data_path, 'dir'))
    mkdir(data_path);
end
if(~exist(log_path, 'dir'))
    mkdir(log_path);
end

%% Set up parameters
N = 256;
tol=1e-6;
mR = 25;         %max rank

k = -N/2:N/2-1;
kbox = [-N/2,N/2;-N/2,N/2];
[k1s,k2s] = ndgrid(k);
k1s = k1s(:);  k2s = k2s(:);
kk = [k1s k2s];

x = (0:N-1)'/N;
xbox = [0,1;0,1];
[x1s,x2s] = ndgrid(x);
x1s = x1s(:);  x2s = x2s(:);
xx = [x1s x2s];

FmR = 25;
func1_name = 'fun0W0.1';
func2_name = 'fun0W0.1';
Factor1 = load([data_path 'Factors_' func1_name '_' num2str(N) '_' num2str(FmR) '.mat'],'Factors');
%Factor2 = load([data_path 'Factors_' func2_name '_' num2str(N) '_' num2str(FmR) '.mat'],'Factors');
Factor2=Factor1;

%% Begin test
if(1)
    if(1)
        f = randn(N,N) + sqrt(-1)*randn(N,N);
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
    f = reshape(f,N^2,1);

    tic;
    y = apply_hbf(Factor1.Factors,f);
    y = reshape(y,N,N,[]);
    y = fft2(y)/N;
    y = reshape(y,N^2,[]);
    y = apply_hbf(Factor2.Factors,y);
    toc;

    tic;
    Factors = hmbf(N, Factor1.Factors, Factor2.Factors, xx, xbox, kk, kbox, mR, tol, 1, 4);
    FactorT = toc;

    tic;
    yy = apply_hbf(Factors,f);
    ApplyT = toc;
    RunT = FactorT + ApplyT;

    disp(['------------------------------------------']);
    disp(['N                 : ' num2str(N)]);
    disp(['Function name     : ' func_name]);
    disp(['Max Rank          : ' num2str(mR)]);
    disp(['Tolerance         : ' num2str(tol)]);
    disp(['Relative Error_1  : ' num2str(norm(y-yy,1)/norm(y,1))]);
    disp(['Relative Error_2  : ' num2str(norm(y-yy)/norm(y))]);
    disp(['Relative Error_inf: ' num2str(norm(y-yy,inf)/norm(y,inf))]);
    disp(['Running Time      : ' num2str(RunT/60) ' mins']);
    disp(['Factorization Time: ' num2str(FactorT/60) ' mins']);
    disp(['Applying Time     : ' num2str(ApplyT) ' s']);
    disp(['------------------------------------------']);

    save([data_path 'Factors_' func1_name '_' func2_name '_' num2str(N) '_' num2str(mR) '.mat'],'Factors','-v7.3');
    fid = fopen([log_path 'Factors_' func1_name '_' func2_name '_' num2str(N) '_' num2str(mR) '.log'],'w+');
    fclose(fid);
end
