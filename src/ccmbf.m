function Factor = ccmbf(Nx, Nk, Factor1, Factor2, xx, xbox, kk, kbox, mR, tol, disp_flag, iter_num, globalidx_kk)
if(nargin == 9)
    disp_flag = 0;
    iter_num = 1;
    globalidx_kk = 1:Nk^2;
elseif(nargin == 10)
    iter_num = 1;
    globalidx_kk = 1:Nk^2;
elseif(nargin == 11)
    globalidx_kk = 1:Nk^2;
end

if(disp_flag)
    fprintf('CCMBF started...\n\n');
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

xidx = ccbf_prep(xx,xbox,npx1,npx2);
kidx = ccbf_prep(kk,kbox,npk1,npk2);

f1all = randn(Nxx,tR);
f2all = randn(Nxx,tR);

levels = max(log2(npk1)-3,0);
LS = 2*mR^2*npk1*npk2*npx1*npx2;
LSW = floor(mR*Nx^2*npk1*npk2/2^levels);

if(disp_flag)
    fprintf('Compression levels: %d\n',levels);
    fprintf('Preallocated sparse matrix size: %d, about %.2f GB\n\n', ...
        LS,(LS*levels+LSW)*(8*2+16)/1024/1024/1024);
end

U_uc = cell(npx1,npx2,npk1,npk2);
V_uc = cell(npx1,npx2,npk1,npk2);
P = cell(npx1,npx2,npk1,npk2);

if(disp_flag)
    t_start = cputime;
end

iter_list = cell(iter_num,1);
iter = 0;
f1 = zeros(Nxx,tR*iter_num);
fe = 0;
for k1=1:npk1
    for k2=1:npk2
        ik = globalidx_kk(kidx{k1,k2});
        iter = iter+1;
        if( length(ik) <= tR )
            f1(ik,fe+1:fe+length(ik))=eye(length(ik));
            fe = fe+length(ik);
        else
            f1(ik,fe+1:fe+tR)=f1all(ik,:);
            fe = fe+tR;
        end
        iter_list{iter} = [k1,k2];
        if(iter == iter_num)
            BR = apply_hbf(Factor1,f1(:,1:fe));
            BR = reshape(BR,Nx,Nx,[]);
            BR = fft2(BR)/Nx;
            BR = reshape(BR,Nxx,[]);
            BR = apply_hbf(Factor2,BR);
            fe = 0;
            for iiter=1:iter
                k1i = iter_list{iiter}(1);
                k2i = iter_list{iiter}(2);
                iklen = length(kidx{k1i,k2i});
                for x1=1:npx1
                    for x2=1:npx2
                        ix = xidx{x1,x2};
                        if( iklen <= tR )
                            U_uc{x1,x2,k1i,k2i}=BR(ix,fe+1:fe+iklen);
                        elseif( length(ix) > tR )
                            U_uc{x1,x2,k1i,k2i}=BR(ix,fe+1:fe+tR);
                        end
                        
                    end
                end
                fe = fe+min(tR,iklen);
            end
            iter = 0;
            f1 = zeros(Nxx,tR*iter_num);
            fe = 0;
        end
if(disp_flag)
    if( k1==1 && k2==1 )
        fprintf('Multiply U block: (%4d/%4d) by (%4d/%4d)',k1,npk1,k2,npk2);
    else
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('(%4d/%4d) by (%4d/%4d)',k1,npk1,k2,npk2);
    end
end
    end
end

if(iter > 0)
    BR = apply_hbf(Factor1,f1(:,1:fe));
    BR = reshape(BR,Nx,Nx,[]);
    BR = fft2(BR)/N;
    BR = reshape(BR,Nxx,[]);
    BR = apply_hbf(Factor2,BR);
    fe = 0;
    for iiter=1:iter
        k1i = iter_list{iiter}(1);
        k2i = iter_list{iiter}(2);
        iklen = length(kidx{k1i,k2i});
        for x1=1:npx1
            for x2=1:npx2
                ix = xidx{x1,x2};
                if( iklen <= tR )
                    U_uc{x1,x2,k1i,k2i}=BR(ix,fe+1:fe+iklen);
                elseif( length(ix) > tR )
                    U_uc{x1,x2,k1i,k2i}=BR(ix,fe+1:fe+tR);
                end
            end
        end
        fe = fe+min(tR,iklen);
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

iter_list = cell(iter_num,1);
iter = 0;
f2 = zeros(Nxx,tR*iter_num);
fe = 0;

for x1=1:npx1
    for x2=1:npx2
        ix = xidx{x1,x2};
        iter = iter+1;
        if( length(ix) <= tR )
            f2(ix,fe+1:fe+length(ix))=eye(length(ix));
            fe = fe+length(ix);
        else
            f2(ix,fe+1:fe+tR)=f2all(ix,:);
            fe = fe+tR;
        end
        iter_list{iter} = [x1,x2];
        if(iter == iter_num)
            BHR = apply_hbf_adj(Factor2,f2(:,1:fe));
            BHR = reshape(BHR,Nx,Nx,[]);
            BHR = ifft2(BHR)*Nx;
            BHR = reshape(BHR,Nxx,[]);
            BHR = apply_hbf_adj(Factor1,BHR);
            fe = 0;
            for iiter=1:iter
                x1i = iter_list{iiter}(1);
                x2i = iter_list{iiter}(2);
                ixlen = length(xidx{x1i,x2i});
                for k1=1:npk1
                    for k2=1:npk2
                        ik = globalidx_kk(kidx{k1,k2});
                        iklen = length(ik);
                        if( ixlen <= tR && iklen > tR )
                            V_uc{x1i,x2i,k1,k2}=BHR(ik,fe+1:fe+ixlen);
                        elseif( ixlen > tR && iklen > tR )
                            V_uc{x1i,x2i,k1,k2}=BHR(ik,fe+1:fe+tR);
                        end
                    end
                end
                fe = fe+min(tR,ixlen);
            end
            iter = 0;
            f2 = zeros(Nxx,tR*iter_num);
            fe = 0;
        end
if(disp_flag)
    if( x1==1 && x2==1 )
        fprintf('Multiply V block: (%4d/%4d) by (%4d/%4d)',x1,npx1,x2,npx2);
    else
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('(%4d/%4d) by (%4d/%4d)',x1,npx1,x2,npx2);
    end
end
    end
end

if(iter > 0)
    BHR = apply_hbf_adj(Factor2,f2(1:fe));
    BHR = reshape(BHR,Np,Np,[]);
    BHR = ifft2(BHR)*N;
    BHR = reshape(BHR,Npp,[]);
    BHR = apply_hbf_adj(Factor1,BHR);
    fe = 0;
    for iiter=1:iter
        x1i = iter_list{iiter}(1);
        x2i = iter_list{iiter}(2);
        ixlen = length(xidx{x1i,x2i});
        for k1=1:npk1
            for k2=1:npk2
                ik = globalidx_kk(kidx{k1,k2});
                if( ixlen <= tR && iklen > tR )
                    V_uc{x1i,x2i,k1,k2}=BHR(ik,fe+1:fe+ixlen);
                elseif( ixlen > tR && iklen > tR )
                    V_uc{x1i,x2i,k1,k2}=BHR(ik,fe+1:fe+tR);
                end
            end
        end
        fe = fe+min(tR,ixlen);
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

for x1=1:npx1
    for x2=1:npx2
        U = cell(npk1,npk2);
        for k1=1:npk1
            for k2=1:npk2
                ik = globalidx_kk(kidx{k1,k2});
                ix = xidx{x1,x2};
                iklen = length(ik);
                ixlen = length(ix);
                if( iklen<=tR )
                    [Utmp,Stmp,~] = svdtrunc(U_uc{x1,x2,k1,k2},mR,tol);
                    U{k1,k2} = Utmp*Stmp;
                    P{x1,x2,k1,k2} = 1./diag(Stmp);
                elseif( ixlen<=tR )
                    [Utmp,Stmp,~] = svdtrunc(V_uc{x1,x2,k1,k2}',mR,tol);
                    U{k1,k2} = Utmp*Stmp;
                    P{x1,x2,k1,k2} = 1./diag(Stmp);
                else
                    f1=f1all(ik,:);
                    f2=f2all(ix,:);
                    BR = U_uc{x1,x2,k1,k2};
                    BHR = V_uc{x1,x2,k1,k2};

                    [VC,~] = qr(BR,0);
                    [VR,~] = qr(BHR,0);

                    RrVC = f2'*VC;
                    VRRc = VR'*f1;
                    [Utmp,Stmp,~] = svdtrunc(pinv(RrVC) * f2'*BR * pinv(VRRc),mR,tol);
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
    fprintf('Compressed A Memory: %.2f GB\n\n',memsize.bytes/1024/1024/1024);
    clear memsize;
end

LS = 3*mR^2*npk1*npk2*npx1*npx2;
CPreSpr = repmat(struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                        'ST',zeros(LS,1),'Height',0,'Width',0,'Offset',0),levels,1);
WPreSpr = struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                 'ST',zeros(LS,1),'Height',Nk^2,'Width',0,'Offset',0);

for k1=1:npk1
    for k2=1:npk2
        V = cell(npx1,npx2);
        for x1=1:npx1
            for x2=1:npx2
                ik = globalidx_kk(kidx{k1,k2});
                ix = xidx{x1,x2};
                iklen = length(ik);
                ixlen = length(ix);
                if( iklen<=tR )
                    [~,Stmp,Vtmp] = svdtrunc(U_uc{x1,x2,k1,k2},mR,tol);
                    V{x1,x2} = Vtmp*Stmp;
                elseif( ixlen<=tR )
                    [~,Stmp,Vtmp] = svdtrunc(V_uc{x1,x2,k1,k2}',mR,tol);
                    V{x1,x2} = Vtmp*Stmp;
                else
                    f1=f1all(ik,:);
                    f2=f2all(ix,:);
                    BR = U_uc{x1,x2,k1,k2};
                    BHR = V_uc{x1,x2,k1,k2};

                    [VC,~] = qr(BR,0);
                    [VR,~] = qr(BHR,0);

                    RrVC = f2'*VC;
                    VRRc = VR'*f1;
                    [~,Stmp,Vtmp] = svdtrunc(pinv(RrVC) * f2'*BR * pinv(VRRc),mR,tol);
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
    fprintf('Compressed B Memory: %.2f GB\n\n',memsize.bytes/1024/1024/1024);
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
