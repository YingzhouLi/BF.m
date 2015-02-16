function Factor = mfiof(N, Factor1, Factor2, xx, xbox, pp, pbox, mR, tol, disp_flag)

if(disp_flag)
    fprintf('MFIOF started...\n\n');
end

% Nx is the square root of the number of target points in space
[Nx,~] = size(xx);
% Np is the square root of the number of source points in phase
[Np,~] = size(pp);

tR=mR+5;

% npx is the number of blocks of each dimension in space
npx = 2^ceil(log2(sqrt(Nx))+0.5);
% npp is the number of blocks of each dimension in phase
npp = 2^ceil(log2(sqrt(Np))+0.5);

if(disp_flag)
    fprintf('Space  Frequence\n');
    fprintf('  npx    npp\n');
    fprintf(' %4d   %4d\n\n',npx,npp);
end

P = cell(npp,npx);

xidx = mfiof_prep(xx,xbox,npx);
pidx = mfiof_prep(pp,pbox,npp);

f1all = randn(Np,tR);% + sqrt(-1)*randn(Np,tR);
f2all = randn(Nx,tR);% + sqrt(-1)*randn(Nx,tR);

levels = floor(log2(Nx/mR)/2);
LS = 3*mR^2*npp*npx;

if(disp_flag)
    fprintf('Compression levels: %d\n',levels);
    fprintf('Preallocated sparse matrix size: %d, about %.2f GB\n\n', ...
        LS,LS*(levels+1)*(2*8+16)/1024/1024/1024);
end

U_uc = cell(npp,npx);
V_uc = cell(npp,npx);
P = cell(npp,npx);



if(disp_flag)
    t_start = cputime;
end

for p=1:npp
    ip = pidx{p};
    f1 = zeros(Np,tR);
    f1(ip,:)=f1all(ip,:);
    BR = apply_mfiof(Factor1,f1);
    BR = fft(BR)/sqrt(N);
    BR = apply_mfiof(Factor2,BR);
    for x=1:npx
        ix = xidx{x};
        U_uc{x,p}=BR(ix,:);
    end
if(disp_flag)
    if( p==1 )
        fprintf('Multiply U block: (%4d/%4d)',p,npp);
    else
        fprintf('\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('(%4d/%4d)',p,npp);
    end
end
end

if(disp_flag)
    fprintf('\n');
    fprintf('Multiply for U block cost %.2f seconds\n',cputime - t_start);
    memsize = whos('U_uc');
    fprintf('Uncompressed U Memory: %.2f GB\n\n',memsize.bytes/1024/1024/1024);
    clear memsize;
end
clear BR f1;


if(disp_flag)
    t_start = cputime;
end

for x=1:npx
    ix = xidx{x};
    f2 = zeros(Nx,tR);
    f2(ix,:)=f2all(ix,:);
    BHR = apply_mfiof_adj(Factor2,f2);
    BHR = ifft(BHR)*sqrt(N);
    BHR = apply_mfiof_adj(Factor1,BHR);
    for p=1:npp
        ip = pidx{p};
        V_uc{x,p}=BHR(ip,:);
    end
if(disp_flag)
    if( x==1 )
        fprintf('Multiply V block: (%4d/%4d)',x,npx);
    else
        fprintf('\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('(%4d/%4d)',x,npx);
    end
end
end

if(disp_flag)
    fprintf('\n');
    fprintf('Multiply for V block cost %.2f seconds\n',cputime - t_start);
    memsize = whos('V_uc');
    fprintf('Uncompressed V Memory: %.2f GB\n\n',memsize.bytes/1024/1024/1024);
    clear memsize;
end
clear BHR f2;

global CPreSpr WPreSpr;
CPreSpr = repmat(struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                        'ST',zeros(LS,1),'Height',0,'Width',0,'Offset',0),levels,1);
WPreSpr = struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                 'ST',zeros(LS,1),'Height',Nx^2,'Width',0,'Offset',0);
             
for x=1:npx
    U = cell(npp,1);
    for p=1:npp
        ip = pidx{p};
        ix = xidx{x};
        f1=f1all(ip,:);
        f2=f2all(ix,:);
        BR = U_uc{x,p};
        BHR = V_uc{x,p};

        [VC,~] = qr(BR,0);
        [VR,~] = qr(BHR,0);

        RrVC = f2'*VC;
        VRRc = VR'*f1;
        [Utmp,Stmp,~] = svdtrunc(pinv(RrVC) * f2'*BR * pinv(VRRc),mR,tol);
        U{p} = VC*Utmp*Stmp;
        P{x,p} = 1./diag(Stmp);
    end
    xxsub = xx(xidx{x},:);
    xos = xbox(1);
    xlen = xbox(2)-xbox(1);
    xsubbox = [ xos+(x-1)*xlen/npx, xos+x*xlen/npx ];
if(disp_flag)
    if( x==1 )
        fprintf('Compress U block: (%4d/%4d)',x,npx);
    else
        fprintf('\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('(%4d/%4d)',x,npx);
    end
end
    compression1D(U,xxsub,xidx{x},xsubbox,mR,tol,1,levels);
end

if(disp_flag)
	fprintf('\n');
end

Uid = find(WPreSpr.ST~=0);
USpr = sparse(WPreSpr.XT(Uid),WPreSpr.YT(Uid),WPreSpr.ST(Uid));
clear Uid;
ATol = cell(levels,1);
for l=1:levels
    Aid = find(CPreSpr(l).ST~=0);
    ATol{l} = sparse(CPreSpr(l).XT(Aid),CPreSpr(l).YT(Aid),CPreSpr(l).ST(Aid));
end
clear Aid;

if(disp_flag)
    memsize = whos('USpr');
    fprintf('Compressed U Memory: %.2f GB\n',memsize.bytes/1024/1024/1024);
    memsize = whos('ATol');
    fprintf('Compressed A Memory: %.2f GB\n\n',memsize.bytes/1024/1024/1024);
    clear memsize;
end

LS = 3*mR^2*npp*npx;
CPreSpr = repmat(struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                        'ST',zeros(LS,1),'Height',0,'Width',0,'Offset',0),levels,1);
WPreSpr = struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                 'ST',zeros(LS,1),'Height',Np,'Width',0,'Offset',0);

for p=1:npp
    V = cell(npx,1);
    for x=1:npx
        ip = pidx{p};
        ix = xidx{x};
        f1=f1all(ip,:);
        f2=f2all(ix,:);
        BR = U_uc{x,p};
        BHR = V_uc{x,p};

        [VC,~] = qr(BR,0);
        [VR,~] = qr(BHR,0);

        RrVC = f2'*VC;
        VRRc = VR'*f1;
        [~,Stmp,Vtmp] = svdtrunc(pinv(RrVC) * f2'*BR * pinv(VRRc),mR,tol);
        V{x} = VR*Vtmp*Stmp;
    end
    ppsub = pp(pidx{p},:);
    pos = pbox(1);
    plen = pbox(2)-pbox(1);
    psubbox = [ pos+(p-1)*plen/npp, pos+p*plen/npp ];
if(disp_flag)
    if( p==1 )
        fprintf('Compress V block: (%4d/%4d)',p,npp);
    else
        fprintf('\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('(%4d/%4d)',p,npp);
    end
end
    compression1D(V,ppsub,pidx{p},psubbox,mR,tol,1,levels);
end

if(disp_flag)
	fprintf('\n');
end

Vid = find(WPreSpr.ST~=0);
VSpr = sparse(WPreSpr.XT(Vid),WPreSpr.YT(Vid),WPreSpr.ST(Vid));
clear Vid;
BTol = cell(levels,1);
for l=1:levels
    Bid = find(CPreSpr(l).ST~=0);
    BTol{l} = sparse(CPreSpr(l).XT(Bid),CPreSpr(l).YT(Bid),CPreSpr(l).ST(Bid));
end
clear Bid;
clear WPreSpr CPreSpr;
if(disp_flag)
    memsize = whos('VSpr');
    fprintf('Compressed V Memory: %.2f GB\n',memsize.bytes/1024/1024/1024);
    memsize = whos('BTol');
    fprintf('Compressed B Memory: %.2f GB\n\n',memsize.bytes/1024/1024/1024);
    clear memsize;
end

totalH = zeros(npx,1);
for x=1:npx
    for p=1:npp
        totalH(x) = totalH(x) + length(P{x,p});
    end
end
currentH = zeros(npx,1);
for x=1:npx
    if(x>1)
        currentH(x) = currentH(x-1)+totalH(x-1);
    end
end

totalW = zeros(npp,1);
for p=1:npp
    for x=1:npx
        totalW(p) = totalW(p) + length(P{x,p});
    end
end
currentW = zeros(npp,1);
for p=1:npp
    if(p>1)
        currentW(p) = currentW(p-1)+totalW(p-1);
    end
end

totalel = 0;
for x=1:npx
    for p=1:npp
        totalel = totalel + length(P{x,p});
    end
end

offset = 0;
XT = zeros(totalel,1);
YT = zeros(totalel,1);
ST = zeros(totalel,1);
for x=1:npx
    localH = currentH(x);
    for p=1:npp
        Mlen = length(P{x,p});
        X = localH+(1:Mlen);
        Y = currentW(p)+(1:Mlen);
        idx = offset+1:offset+numel(X);
        XT(idx) = X(:);
        YT(idx) = Y(:);
        ST(idx) = P{x,p};
        if(~isempty(idx))
            offset = idx(end);
        end
        localH = localH + Mlen;
        currentW(p) = currentW(p) + Mlen;
    end
end
SigmaM = sparse(XT,YT,ST);
clear XT YT ST;
if(disp_flag)
    memsize = whos('SigmaM');
    fprintf('Compressed M Memory: %.2f GB\n\n',memsize.bytes/1024/1024/1024);
    clear memsize;
end

Factor = struct('U',[],'ATol',[],'SigmaM',[],'BTol',[],'V',[]);
Factor.U = USpr;
clear USpr;
Factor.ATol = ATol;
clear ATol;
Factor.SigmaM = SigmaM;
clear SigmaM;
Factor.BTol = BTol;
clear BTol;
Factor.V = VSpr;
clear VSpr;
end
