function Factor = mfiof(N, Factor1, Factor2, xx, xbox, pp, pbox, mR, tol, disp_flag, iter_num)

if(nargin == 9)
    disp_flag = 0;
    iter_num = 1;
elseif(nargin == 10)
    iter_num = 1;
end

if(disp_flag)
    fprintf('MFIOF started...\n\n');
end

% Nx is the square root of the number of target points in space
[Nxx,~] = size(xx);
Nx = floor(sqrt(Nxx));
% Np is the square root of the number of source points in phase
[Npp,~] = size(pp);
Np = floor(sqrt(Npp));

tR=mR+5;

% npx is the number of blocks of each dimension in space
npx1 = 2^ceil(log2(sqrt(Nx))+0.5);
npx2 = 2^ceil(log2(sqrt(Nx))+0.5);
% npp is the number of blocks of each dimension in phase
npp1 = 2^ceil(log2(sqrt(Np))+0.5);
npp2 = 4*2^ceil(log2(sqrt(Np)));

if(disp_flag)
    fprintf('   Space      Frequence\n');
    fprintf('  npx1  npx2  npp1  npp2\n');
    fprintf('  %4d  %4d  %4d  %4d\n\n',npx1,npx2,npp1,npp2);
end

xidx = mfiof_prep(xx,xbox,npx1,npx2);
pidx = mfiof_prep(pp,pbox,npp1,npp2);

f1all = randn(Npp,tR);% + sqrt(-1)*randn(Npp,tR);
f2all = randn(Nxx,tR);% + sqrt(-1)*randn(Nxx,tR);

levels = floor(log2(Nx/mR)/2);
LS = 3*mR^2*npp1*npp2*npx1*npx2;

if(disp_flag)
    fprintf('Compression levels: %d\n',levels);
    fprintf('Preallocated sparse matrix size: %d, about %.2f GB\n\n', ...
        LS,LS*(levels+1)*(2*8+16)/1024/1024/1024);
end

U_uc = cell(npx1,npx2,npp1,npp2);
V_uc = cell(npx1,npx2,npp1,npp2);
P = cell(npx1,npx2,npp1,npp2);



if(disp_flag)
    t_start = cputime;
end

iter_list = cell(iter_num,1);
iter = 0;
f1 = zeros(Npp,tR*iter_num);
fe = 0;
for p1=1:npp1
    for p2=1:npp2
        ip = pidx{p1,p2};
        iter = iter+1;
        if( size(ip,1) <= tR )
            f1(ip,fe+1:fe+size(ip,1))=eye(size(ip,1));
            fe = fe+size(ip,1);
        else
            f1(ip,fe+1:fe+tR)=f1all(ip,:);
            fe = fe+tR;
        end
        iter_list{iter} = [p1,p2];
        if(iter == iter_num)
            BR = apply_mfiof(Factor1,f1(:,1:fe));
            BR = reshape(BR,Nx,Nx,[]);
            BR = fft2(BR)/N;
            BR = reshape(BR,Nxx,[]);
            BR = apply_mfiof(Factor2,BR);
            fe = 0;
            for iiter=1:iter
                p1i = iter_list{iiter}(1);
                p2i = iter_list{iiter}(2);
                iplen = size(pidx{p1i,p2i},1);
                for x1=1:npx1
                    for x2=1:npx2
                        ix = xidx{x1,x2};
                        if( iplen <= tR )
                            U_uc{x1,x2,p1i,p2i}=BR(ix,fe+1:fe+iplen);
                        elseif( size(ix,1) > tR )
                            U_uc{x1,x2,p1i,p2i}=BR(ix,fe+1:fe+tR);
                        end
                        
                    end
                end
                fe = fe+min(tR,iplen);
            end
            iter = 0;
            f1 = zeros(Npp,tR*iter_num);
            fe = 0;
        end
if(disp_flag)
    if( p1==1 && p2==1 )
        fprintf('Multiply U block: (%4d/%4d) by (%4d/%4d)',p1,npp1,p2,npp2);
    else
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('(%4d/%4d) by (%4d/%4d)',p1,npp1,p2,npp2);
    end
end
    end
end

if(iter > 0)
    BR = apply_mfiof(Factor1,f1(:,1:fe));
    BR = reshape(BR,Nx,Nx,[]);
    BR = fft2(BR)/N;
    BR = reshape(BR,Nxx,[]);
    BR = apply_mfiof(Factor2,BR);
    fe = 0;
    for iiter=1:iter
        p1i = iter_list{iiter}(1);
        p2i = iter_list{iiter}(2);
        iplen = size(pidx{p1i,p2i},1);
        for x1=1:npx1
            for x2=1:npx2
                ix = xidx{x1,x2};
                if( iplen <= tR )
                    U_uc{x1,x2,p1i,p2i}=BR(ix,fe+1:fe+iplen);
                elseif( size(ix,1) > tR )
                    U_uc{x1,x2,p1i,p2i}=BR(ix,fe+1:fe+tR);
                end

            end
        end
        fe = fe+min(tR,iplen);
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
        if( size(ix,1) <= tR )
            f2(ix,fe+1:fe+size(ix,1))=eye(size(ix,1));
            fe = fe+size(ix,1);
        else
            f2(ix,fe+1:fe+tR)=f2all(ix,:);
            fe = fe+tR;
        end
        iter_list{iter} = [x1,x2];
        if(iter == iter_num)
            BHR = apply_mfiof_adj(Factor2,f2(:,1:fe));
            BHR = reshape(BHR,Np,Np,[]);
            BHR = ifft2(BHR)*N;
            BHR = reshape(BHR,Npp,[]);
            BHR = apply_mfiof_adj(Factor1,BHR);
            fe = 0;
            for iiter=1:iter
                x1i = iter_list{iiter}(1);
                x2i = iter_list{iiter}(2);
                ixlen = size(xidx{x1i,x2i},1);
                for p1=1:npp1
                    for p2=1:npp2
                        ip = pidx{p1,p2};
                        iplen = size(ip,1);
                        if( ixlen <= tR && iplen > tR )
                            V_uc{x1i,x2i,p1,p2}=BHR(ip,fe+1:fe+ixlen);
                        elseif( ixlen > tR && iplen > tR )
                            V_uc{x1i,x2i,p1,p2}=BHR(ip,fe+1:fe+tR);
                        end
                    end
                end
                fe = fe+min(tR,ixlen);
            end
            iter = 0;
            f2 = zeros(Npp,tR*iter_num);
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
    BHR = apply_mfiof_adj(Factor2,f2(1:fe));
    BHR = reshape(BHR,Np,Np,[]);
    BHR = ifft2(BHR)*N;
    BHR = reshape(BHR,Npp,[]);
    BHR = apply_mfiof_adj(Factor1,BHR);
    fe = 0;
    for iiter=1:iter
        x1i = iter_list{iiter}(1);
        x2i = iter_list{iiter}(2);
        ixlen = size(xidx{x1i,x2i},1);
        for p1=1:npp1
            for p2=1:npp2
                ip = pidx{p1,p2};
                if( ixlen <= tR && iplen > tR )
                    V_uc{x1i,x2i,p1,p2}=BHR(ip,fe+1:fe+ixlen);
                elseif( ixlen > tR && iplen > tR )
                    V_uc{x1i,x2i,p1,p2}=BHR(ip,fe+1:fe+tR);
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
        U = cell(npp1,npp2);
        for p1=1:npp1
            for p2=1:npp2
                ip = pidx{p1,p2};
                ix = xidx{x1,x2};
                iplen = size(ip,1);
                ixlen = size(ix,1);
                if( iplen<=tR )
                    [Utmp,Stmp,~] = svdtrunc(U_uc{x1,x2,p1,p2},mR,tol);
                    U{p1,p2} = Utmp*Stmp;
                    P{x1,x2,p1,p2} = 1./diag(Stmp);
                elseif( ixlen<=tR )
                    [Utmp,Stmp,~] = svdtrunc(V_uc{x1,x2,p1,p2}',mR,tol);
                    U{p1,p2} = Utmp*Stmp;
                    P{x1,x2,p1,p2} = 1./diag(Stmp);
                else
                    f1=f1all(ip,:);
                    f2=f2all(ix,:);
                    BR = U_uc{x1,x2,p1,p2};
                    BHR = V_uc{x1,x2,p1,p2};

                    [VC,~] = qr(BR,0);
                    [VR,~] = qr(BHR,0);

                    RrVC = f2'*VC;
                    VRRc = VR'*f1;
                    [Utmp,Stmp,~] = svdtrunc(pinv(RrVC) * f2'*BR * pinv(VRRc),mR,tol);
                    U{p1,p2} = VC*Utmp*Stmp;
                    P{x1,x2,p1,p2} = 1./diag(Stmp);
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

LS = 3*mR^2*npp1*npp2*npx1*npx2;
CPreSpr = repmat(struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                        'ST',zeros(LS,1),'Height',0,'Width',0,'Offset',0),levels,1);
WPreSpr = struct('XT',zeros(LS,1),'YT',zeros(LS,1), ...
                 'ST',zeros(LS,1),'Height',Np^2,'Width',0,'Offset',0);

for p1=1:npp1
    for p2=1:npp2
        V = cell(npx1,npx2);
        for x1=1:npx1
            for x2=1:npx2
                ip = pidx{p1,p2};
                ix = xidx{x1,x2};
                iplen = size(ip,1);
                ixlen = size(ix,1);
                if( iplen<=tR )
                    [~,Stmp,Vtmp] = svdtrunc(U_uc{x1,x2,p1,p2},mR,tol);
                    V{x1,x2} = Vtmp*Stmp;
                elseif( ixlen<=tR )
                    [~,Stmp,Vtmp] = svdtrunc(V_uc{x1,x2,p1,p2}',mR,tol);
                    V{x1,x2} = Vtmp*Stmp;
                else
                    f1=f1all(ip,:);
                    f2=f2all(ix,:);
                    BR = U_uc{x1,x2,p1,p2};
                    BHR = V_uc{x1,x2,p1,p2};

                    [VC,~] = qr(BR,0);
                    [VR,~] = qr(BHR,0);

                    RrVC = f2'*VC;
                    VRRc = VR'*f1;
                    [~,Stmp,Vtmp] = svdtrunc(pinv(RrVC) * f2'*BR * pinv(VRRc),mR,tol);
                    V{x1,x2} = VR*Vtmp*Stmp;
                end
            end
        end
        ppsub = pp(pidx{p1,p2},:);
        p1os = pbox(1,1);
        p1len = pbox(1,2)-pbox(1,1);
        p2os = pbox(2,1);
        p2len = pbox(2,2)-pbox(2,1);
        psubbox = [ p1os+(p1-1)*p1len/npp1, p1os+p1*p1len/npp1; ...
                    p2os+(p2-1)*p2len/npp2, p2os+p2*p2len/npp2];
if(disp_flag)
    if( p1==1 && p2==1 )
        fprintf('Compress V block: (%4d/%4d) by (%4d/%4d)',p1,npp1,p2,npp2);
    else
        fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
        fprintf('(%4d/%4d) by (%4d/%4d)',p1,npp1,p2,npp2);
    end
end
        compression2D(V,ppsub,pidx{p1,p2},psubbox,mR,tol,1,levels);
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
        for p1=1:npp1
            for p2=1:npp2
                totalH(x) = totalH(x) + length(P{x1,x2,p1,p2});
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

totalW = zeros(npp1*npp2,1);
for p1=1:npp1
    for p2=1:npp2
        p = (p1-1)*npp2+p2;
        for x1=1:npx1
            for x2=1:npx2
                totalW(p) = totalW(p) + length(P{x1,x2,p1,p2});
            end
        end
    end
end
currentW = zeros(npp1*npp2,1);
for p1=1:npp1
    for p2=1:npp2
        p = (p1-1)*npp2+p2;
        if(p>1)
            currentW(p) = currentW(p-1)+totalW(p-1);
        end
    end
end

totalel = 0;
for x1=1:npx1
    for x2=1:npx2
        for p1=1:npp1
            for p2=1:npp2
                totalel = totalel + length(P{x1,x2,p1,p2});
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
        for p1=1:npp1
            for p2=1:npp2
                p = (p1-1)*npp2+p2;
                Mlen = length(P{x1,x2,p1,p2});
                X = localH+(1:Mlen);
                Y = currentW(p)+(1:Mlen);
                idx = offset+1:offset+numel(X);
                XT(idx) = X(:);
                YT(idx) = Y(:);
                ST(idx) = P{x1,x2,p1,p2};
                if(~isempty(idx))
                    offset = idx(end);
                end
                localH = localH + Mlen;
                currentW(p) = currentW(p) + Mlen;
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