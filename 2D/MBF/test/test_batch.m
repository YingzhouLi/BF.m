clc;

% clear all;
% run_hbf(128,'fun0',25,1e-6,0);

% clear all;
% run_hbf(256,'fun0',49,1e-8,0);

% clear all;
% run_hbf(128,'fun0W',25,1e-6,0.1);

% clear all;
% run_hbf(256,'fun0W',49,1e-8,0.1);

% clear all;
% run_hbf(256,'fun0W',25,1e-6,0.2);

% clear all;
% run_hbf(256,'fun0W',49,1e-8,0.2);

% clear all;
% run_hbf(256,'fun0W',25,1e-6,0.3);

% clear all;
% run_hbf(256,'fun0W',49,1e-8,0.3);

clear all;
run_hmbf(128,'fun0','fun0',25,25,1e-6);

clear all;
run_hmbf(128,'fun0W0.1','fun0W0.1',25,25,1e-6);