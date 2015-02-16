function Factor = fiof(N, fun, xx, xbox, pp, pbox, mR, tol, disp_flag)

if(disp_flag)
    fprintf('FIOF started...\n\n');
end

% Nx is the square root of the number of target points in space
[Nx,~] = size(xx);
% Np is the square root of the number of source points in phase
[Np,~] = size(pp);

tR=3*mR;

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
Ridx = cell(npp,npx);
Cidx = cell(npp,npx);
rs = cell(npp,npx);
cs = cell(npp,npx);

xidx = mfiof_prep(xx,xbox,npx);
pidx = mfiof_prep(pp,pbox,npp);

levels = floor(log2(Nx/mR/4)/2);
LS = 4*mR^2*npp*npx;

if(disp_flag)
    fprintf('Compression levels: %d\n',levels);
    fprintf('Preallocated sparse matrix size: %d, about %.2f GB\n', ...
        LS,LS*(levels+1)*(2*8+16)/1024/1024/1024);
end

global CPreSpr WPreSpr;
CPreSpr = repmat(struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                        'ST',zeros(LS,1),'Height',0,'Width',0,'Offset',0),levels,1);
WPreSpr = struct('XT',zeros(4*LS,1),'YT',zeros(4*LS,1), ...
                 'ST',zeros(4*LS,1),'Height',Nx,'Width',0,'Offset',0);

for x=1:npx
    U = cell(npp,1);
    for p=1:npp
        ip = pidx{p};
        ix = xidx{x};
        [U{p},Stmp,~,Ridx{x,p},Cidx{x,p},rs{x,p},cs{x,p}] = lowrank(xx(ix),pp(ip), fun, tol, tR, mR);
        P{x,p} = 1./diag(Stmp);
        U{p} = U{p}*Stmp;
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
if(disp_flag)
    if(length(WPreSpr.XT)>4*LS)
	fprintf('Bad preallocation U, %d is required',length(WPreSpr.XT));
    end
end
clear Uid;
ATol = cell(levels,1);
for l=1:levels
    Aid = find(CPreSpr(l).ST~=0);
    ATol{l} = sparse(CPreSpr(l).XT(Aid),CPreSpr(l).YT(Aid),CPreSpr(l).ST(Aid));
    if(disp_flag)
        if(length(CPreSpr(l).XT)>LS)
            fprintf('Bad preallocation A, %d is required',length(CPreSpr(l).XT));
        end
    end
end
clear Aid;

if(disp_flag)
    memsize = whos('USpr');
    fprintf('Compressed U Memory: %.2f GB\n',memsize.bytes/1024/1024/1024);
    memsize = whos('ATol');
    fprintf('Compressed A Memory: %.2f GB\n',memsize.bytes/1024/1024/1024);
    clear memsize;
end

LS = 4*mR^2*npp*npx;
CPreSpr = repmat(struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                        'ST',zeros(LS,1),'Height',0,'Width',0,'Offset',0),levels,1);
WPreSpr = struct('XT',zeros(4*LS,1),'YT',zeros(4*LS,1), ...
                 'ST',zeros(4*LS,1),'Height',Np,'Width',0,'Offset',0);

for p=1:npp
    V = cell(npx,1);
    for x=1:npx
        ip = pidx{p};
        ix = xidx{x};
        [~,Stmp,V{x}] = lowrankidx(xx(ix),pp(ip),fun,tol,tR,mR,Ridx{x,p},Cidx{x,p},rs{x,p},cs{x,p});
        V{x} = V{x}*Stmp;
    end
    ppsub = pp(pidx{p});
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
if(disp_flag)
    if(length(WPreSpr.XT)>4*LS)
	fprintf('Bad preallocation V, %d is required',length(WPreSpr.XT));
    end
end
clear Vid;
BTol = cell(levels,1);
for l=1:levels
    Bid = find(CPreSpr(l).ST~=0);
    BTol{l} = sparse(CPreSpr(l).XT(Bid),CPreSpr(l).YT(Bid),CPreSpr(l).ST(Bid));
    if(disp_flag)
        if(length(CPreSpr(l).XT)>LS)
            fprintf('Bad preallocation B, %d is required',length(CPreSpr(l).XT));
        end
    end
end
clear Bid;
clear WPreSpr CPreSpr;
if(disp_flag)
    memsize = whos('VSpr');
    fprintf('Compressed V Memory: %.2f GB\n',memsize.bytes/1024/1024/1024);
    memsize = whos('BTol');
    fprintf('Compressed B Memory: %.2f GB\n',memsize.bytes/1024/1024/1024);
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
    fprintf('Compressed M Memory: %.2f GB\n',memsize.bytes/1024/1024/1024);
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
