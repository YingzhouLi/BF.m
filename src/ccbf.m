function Factor = ccbf(Nx, Nk, fun, xx, xbox, kk, kbox, mR, tol, disp_flag)

if(disp_flag)
    fprintf('CCBF started...\n\n');
end

Nxx = size(xx,1);
Nkk = size(kk,1);

tR=mR+5;

% npx is the number of blocks of each dimension in space
npx1 = 2^ceil(log2(sqrt(Nk)));
npx2 = 2^ceil(log2(sqrt(Nk)));
% npk is the number of blocks of each dimension in freq
npk1 = 2^ceil(log2(sqrt(Nk)));
npk2 = 2^ceil(log2(sqrt(Nk)));

if(disp_flag)
    fprintf('   Space      Frequence\n');
    fprintf('  npx1  npx2  npk1  npk2\n');
    fprintf('  %4d  %4d  %4d  %4d\n\n',npx1,npx2,npk1,npk2);
end

P = cell(npx1,npx2,npk1,npk2);

xidx = ccbf_prep(xx,xbox,npx1,npx2);
kidx = ccbf_prep(kk,kbox,npk1,npk2);

f1all = randn(Nkk,tR);
f2all = randn(Nxx,tR);

levels = max(log2(npk1)-3,0);
LS = 2*mR^2*npk1*npk2*npx1*npx2;
LSW = floor(mR*Nx^2*npk1*npk2/2^levels);

if(disp_flag)
    fprintf('Compression levels: %d\n',levels);
    fprintf('Preallocated sparse matrix size: %d, about %.2f GB\n', ...
        LS,(LS*levels+LSW)*(8*2+16)/1024/1024/1024);
end

global CPreSpr WPreSpr;
CPreSpr = repmat(struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                        'ST',zeros(LS,1),'Height',0,'Width',0,'Offset',0),levels,1);
WPreSpr = struct('XT',zeros(LSW,1),'YT',zeros(LSW,1), ...
                 'ST',zeros(LSW,1),'Height',Nx^2,'Width',0,'Offset',0);

for x1=1:npx1
    for x2=1:npx2
        U = cell(npk1,npk2);
        for k1=1:npk1
            for k2=1:npk2
                ik = kidx{k1,k2};
                ix = xidx{x1,x2};
                f1=f1all(ik,:);
                f2=f2all(ix,:);
                ButterflyMat = fun(xx(ix,:),kk(ik,:));
                if(min(size(ButterflyMat)) <= mR)
                    [Utmp,Stmp,~] = svdtrunc(ButterflyMat,mR,tol);
                    U{k1,k2} = Utmp*Stmp;
                    P{x1,x2,k1,k2} = 1./diag(Stmp);
                else
                    BR = ButterflyMat*f1;
                    BHR = ButterflyMat'*f2;

                    [VC,~] = qr(BR,0);
                    [VR,~] = qr(BHR,0);

                    RrVC = f2'*VC;
                    VRRc = VR'*f1;
                    [Utmp,Stmp,~] = svdtrunc(pinv(RrVC) * (f2'*BR) * pinv(VRRc),mR,tol);
                    U{k1,k2} = VC*Utmp*Stmp;
                    P{x1,x2,k1,k2} = 1./diag(Stmp);
                end
            end
        end
        xxsub = xx(xidx{x1,x2},:);
        x1os = xbox(1,1);
        x1len = xbox(1,2)-xbox(1,1);
        x2os = xbox(2,1);
        x2len = xbox(2,2)-xbox(2,1);
        xsubbox = [ x1os+(x1-1)*x1len/npx1, x1os+x1*x1len/npx1; ...
                    x2os+(x2-1)*x2len/npx2, x2os+x2*x2len/npx2];
if(disp_flag)
    if( x1==1 && x2==1 )
        fprintf('Compress U block: (%4d/%4d) by (%4d/%4d)',x1,npx1,x2,npx2);
    else
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('(%4d/%4d) by (%4d/%4d)',x1,npx1,x2,npx2);
    end
end
        compression2D(U,xxsub,xidx{x1,x2},xsubbox,mR,tol,1,levels);
    end
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
    fprintf('Compressed A Memory: %.2f GB\n',memsize.bytes/1024/1024/1024);
    clear memsize;
end

LS = 2*mR^2*npk1*npk2*npx1*npx2;
LSW = floor(mR*Nk^2*npx1*npx2/2^levels*3/4);

if(disp_flag)
    fprintf('Compression levels: %d\n',levels);
    fprintf('Preallocated sparse matrix size: %d, about %.2f GB\n', ...
        LS,(LS*levels+LSW)*(8*2+16)/1024/1024/1024);
end

CPreSpr = repmat(struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                        'ST',zeros(LS,1),'Height',0,'Width',0,'Offset',0),levels,1);
WPreSpr = struct('XT',zeros(LSW,1),'YT',zeros(LSW,1), ...
                 'ST',zeros(LSW,1),'Height',Nk^2,'Width',0,'Offset',0);

for k1=1:npk1
    for k2=1:npk2
        V = cell(npx1,npx2);
        for x1=1:npx1
            for x2=1:npx2
                ik = kidx{k1,k2};
                ix = xidx{x1,x2};
                f1=f1all(ik,:);
                f2=f2all(ix,:);
                ButterflyMat = fun(xx(ix,:),kk(ik,:));
                if(min(size(ButterflyMat)) <= mR)
                    [~,Stmp,Vtmp] = svdtrunc(ButterflyMat,mR,tol);
                    V{x1,x2} = Vtmp*Stmp;
                else
                    BR = ButterflyMat*f1;
                    BHR = ButterflyMat'*f2;

                    [VC,~] = qr(BR,0);
                    [VR,~] = qr(BHR,0);

                    RrVC = f2'*VC;
                    VRRc = VR'*f1;
                    [~,Stmp,Vtmp] = svdtrunc(pinv(RrVC) * (f2'*BR) * pinv(VRRc),mR,tol);
                    V{x1,x2} = VR*Vtmp*Stmp;
                end
            end
        end
        kksub = kk(kidx{k1,k2},:);
        k1os = kbox(1,1);
        k1len = kbox(1,2)-kbox(1,1);
        k2os = kbox(2,1);
        k2len = kbox(2,2)-kbox(2,1);
        ksubbox = [ k1os+(k1-1)*k1len/npk1, k1os+k1*k1len/npk1; ...
                    k2os+(k2-1)*k2len/npk2, k2os+k2*k2len/npk2];
if(disp_flag)
    if( k1==1 && k2==1 )
        fprintf('Compress V block: (%4d/%4d) by (%4d/%4d)',k1,npk1,k2,npk2);
    else
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('(%4d/%4d) by (%4d/%4d)',k1,npk1,k2,npk2);
    end
end
        compression2D(V,kksub,kidx{k1,k2},ksubbox,mR,tol,1,levels);
    end
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
    fprintf('Compressed B Memory: %.2f GB\n',memsize.bytes/1024/1024/1024);
    clear memsize;
end

totalH = zeros(npx1*npx2,1);
for x1=1:npx1
    for x2=1:npx2
        x = (x1-1)*npx2+x2;
        for k1=1:npk1
            for k2=1:npk2
                totalH(x) = totalH(x) + length(P{x1,x2,k1,k2});
            end
        end
    end
end
currentH = zeros(npx1*npx2,1);
for x1=1:npx1
    for x2 =1:npx2
        x = (x1-1)*npx2+x2;
        if(x>1)
            currentH(x) = currentH(x-1)+totalH(x-1);
        end
    end
end

totalW = zeros(npk1*npk2,1);
for k1=1:npk1
    for k2=1:npk2
        k = (k1-1)*npk2+k2;
        for x1=1:npx1
            for x2=1:npx2
                totalW(k) = totalW(k) + length(P{x1,x2,k1,k2});
            end
        end
    end
end
currentW = zeros(npk1*npk2,1);
for k1=1:npk1
    for k2=1:npk2
        k = (k1-1)*npk2+k2;
        if(k>1)
            currentW(k) = currentW(k-1)+totalW(k-1);
        end
    end
end

totalel = 0;
for x1=1:npx1
    for x2=1:npx2
        for k1=1:npk1
            for k2=1:npk2
                totalel = totalel + length(P{x1,x2,k1,k2});
            end
        end
    end
end

offset = 0;
XT = zeros(totalel,1);
YT = zeros(totalel,1);
ST = zeros(totalel,1);
for x1=1:npx1
    for x2=1:npx2
        x = (x1-1)*npx2+x2;
        localH = currentH(x);
        for k1=1:npk1
            for k2=1:npk2
                k = (k1-1)*npk2+k2;
                Mlen = length(P{x1,x2,k1,k2});
                X = localH+(1:Mlen);
                Y = currentW(k)+(1:Mlen);
                idx = offset+1:offset+numel(X);
                XT(idx) = X(:);
                YT(idx) = Y(:);
                ST(idx) = P{x1,x2,k1,k2};
                if(~isempty(idx))
                    offset = idx(end);
                end
                localH = localH + Mlen;
                currentW(k) = currentW(k) + Mlen;
            end
        end
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
