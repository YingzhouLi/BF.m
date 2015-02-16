log_path = './log/';
data_path = './data/';

if(~exist(data_path, 'dir'))
    mkdir(data_path);
end
if(~exist(log_path, 'dir'))
    mkdir(log_path);
end

func_list = {'fun0'};
for func_i = 1:length(func_list)
    func_name = func_list{func_i};
    for N = 2.^(8:2:18)
        fid = fopen([log_path 'Factor_' func_name '_' func_name '_' num2str(N) '.log'],'a+');
        Factor1 = load([data_path 'Factor_' func_name '_' num2str(N) '_' num2str(8) '.mat'],'Factor');
        Factor2=Factor1;
        for mR = 10:2:12
            tol = 10^(-mR-1);
            run_mfiof(N, Factor1, Factor2, mR, tol, fid);
            fprintf('Func %s, N %4d, mR %2d finished.\n',func_list{func_i},N,mR);
        end
        fclose(fid);
    end
end
