close all;
clear all;
clc;

addpath('../src/');
data_path = './data/';

%% Set up parameters
N = 256;
FmR = 12;

if(1)
    func1_name = 'fun0';
    func2_name = 'fun0';
    Factor = load([data_path 'Factor_' func1_name '_' func1_name '_' num2str(N) '_' num2str(FmR) '.mat'],'Factor');
end

if(0)
    func_name = 'fun0';
    Factor = load([data_path 'Factor_' func_name '_' num2str(N) '_' num2str(FmR) '.mat'],'Factor');
end

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
    y = apply_mfiof(Factor.Factor,f);
    toc;

end
