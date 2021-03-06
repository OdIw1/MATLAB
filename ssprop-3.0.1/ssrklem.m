function u1 =ssrklem(u0,dt,dz,L,alpha,betap,gamma,to,tol)
% This function solves the nonlinear Schrodinger equation for
% pulse propagation in an optical fiber using the split-step
% RK4-IP method.
% 
% The following effects are included in the model: group velocity
% dispersion (GVD), higher order dispersion, loss, and self-phase
% modulation (gamma),Raman self-frequency shift, and
% self-steepening..
% 
% USAGE
%
% u1 = ssrklem(u0,dt,dz,nz,alpha,betap,gamma);
% u1 = ssrklem(u0,dt,dz,nz,alpha,betap,gamma,to);
% u1 = ssrklem(u0,dt,dz,nz,alpha,betap,gamma,to,tol);
%
% INPUT
%
% u0 - starting field amplitude (vector)
% dt - time step ps
% dz - propagation stepsize 
% nz - number of steps to take, ie, ztotal = dz*nz
% alpha - power loss coefficient, ie, P=P0*exp(-alpha*z)
% betap - dispersion polynomial coefs, [beta_0 ... beta_m] ps^n/m
% gamma - nonlinearity coefficient 
% to - optical cycle time = lambda0/c (default = 0) ps
% tol - convergence tolerance (default = 1e-5)
if nargin < 9                                   %判断输入宗量个数，进行默认赋值
   tol = 1e-5; 
end
if nargin < 8
   to = 0; 
end

nt = length(u0);                                %采样点数
w0 = 2*pi/to;                                   %参考角频率或载波角频率，单位THz                               
w = 2*pi*[(0:nt/2-1),(-nt/2:-1)]'/(dt*nt);      %角频率序列，单位THz
%%%%%%%%%%%%%%%%%% model by Q.Lin etc. in 2006 %%%%%%%%%%%%%%%%%%%%
 fR = (to~=0)*0.245;                             %拉曼响应对非线性响应的贡献系数
 fhR =ifft(ramanhR((-nt/2:nt/2-1)*dt).')*nt;     %拉曼响应序列的傅里叶变换，时域拉曼响应的时间单位为ps
%%%%%%%%%%%%%%%%%% model by K.J.Blow etc. in 1989 %%%%%%%%%%%%%%%%%
%fR = (to~=0)*0.18;                             %拉曼响应对非线性响应的贡献系数
%fhR =ifft(ramanhR_1989((-nt/2:nt/2-1)*dt).')*nt;     %拉曼响应序列的傅里叶变换，时域拉曼响应的时间单位为ps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
halfstep = -alpha/2;                            %光纤中损耗或增益系数
for ii = 0:length(betap)-1;                     %各阶色散，单位ps^n/m
    halfstep = halfstep + 1i*betap(ii+1)*(w).^ii/factorial(ii);
end

%以下计算过程中：
%ifft()*nt表示进行傅里叶变换
%fft()/nt表示进行逆傅里叶变换
zk=0;
ufft = ifft(u0)*nt;                             
hwait = waitbar(0,'Ready!Go!');                 %设置进度条
while zk < L   
    if  L-zk < dz
       dz = L-zk; 
    end
    waitbar(zk/L,hwait, ['已完成',num2str(100*zk/L,'%4.1f'),'% 当前步长为：',num2str(dz)]);
    u1 = calculate_u(u0,ufft,w,dz,fhR,fR,halfstep,gamma,w0,nt,dt);  
    uv1 = calculate_u(u0,ufft,w,dz/2,fhR,fR,halfstep,gamma,w0,nt,dt); 
    uv = calculate_u(uv1,ifft(uv1)*nt,w,dz/2,fhR,fR,halfstep,gamma,w0,nt,dt); 
        
    error = norm(uv-u1,2)/norm(uv,2);           %计算局部误差

    if error >= 2*tol                           %判断收敛并调整步长
        dz = dz/2;
    elseif error >= tol && error < 2*tol
        dz = dz/(2^(1/5));
    elseif error < tol && error >= tol/2
        zk = zk + dz;
        dz = dz*2^(1/5); 
        u0 = 16/15*uv-1/15*u1;                  %理查德森外推
        ufft =ifft(u0)*nt;
    else
        zk = zk + dz;
        dz = 2*dz; 
        u0 = 16/15*uv-1/15*u1;
        ufft = ifft(u0)*nt;
    end
end
u1 = uv;
delete(hwait);
end

function u1 = calculate_u(u0,ufft,w,dz,fhR,fR,halfstep,gamma,w0,nt,dt)
%从u0计算u1，步长为dz
%k1至k4为四阶库塔算法中的导数项，权重不可更改
halfstep = exp(halfstep*dz/2);
u1=u0;
uip = halfstep.*ufft;
k1 = compute_tfn(w,u1,fhR,fR,w0,gamma,dt,nt).*halfstep;
u2 = fft(uip+k1*dz/2)/nt;
k2 = compute_tfn(w,u2,fhR,fR,w0,gamma,dt,nt);
u3 = fft(uip+k2*dz/2)/nt;
k3 = compute_tfn(w,u3,fhR,fR,w0,gamma,dt,nt);
u4 = fft(halfstep.*(uip+k3*dz))/nt;
k4 = compute_tfn(w,u4,fhR,fR,w0,gamma,dt,nt);
ufft = halfstep.*(uip+k1*dz/6+k2*dz/3+k3*dz/3)+k4*dz/6;
u1 = fft(ufft)/nt;
end

function fg = compute_tfn(w,u,fhR,fR,w0,gamma,dt,nt)
%对时域序列u计算非线性算符N作用，得到频域结果fg
    op1 = abs(u).^2;
    op2 = dt*fft(ifft(op1)*nt.*fhR)/nt;
    op3 = u.*(((1-fR)*op1+fR*op2));
    fg = 1i*gamma.*(ifft(op3)*nt).*(1+w/w0);    %非线性项中的卷积和
    nan_region = isnan(fg);                     %处理NaN
    fg(nan_region) = 0;
end
