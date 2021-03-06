function [u1,nanfirst,nansecond,nanthird] =ssfm(u0,dt,dz,nz,alpha,betap,gamma,to,maxiter,tol)
% This function solves the nonlinear Schrodinger equation for
% pulse propagation in an optical fiber using the split-step
% Fourier method.
% 
% The following effects are included in the model: group velocity
% dispersion (GVD), higher order dispersion, loss, and self-phase
% modulation (gamma),Raman self-frequency shift, and
% self-steepening..
% 
% USAGE
%
% [u1,nanfirst,nansecond,nanthird] = ssfm(u0,dt,dz,nz,alpha,betap,gamma);
% [u1,nanfirst,nansecond,nanthird] = ssfm(u0,dt,dz,nz,alpha,betap,gamma,to);
% [u1,nanfirst,nansecond,nanthird] = ssfm(u0,dt,dz,nz,alpha,betap,gamma,to,maxiter);
% [u1,nanfirst,nansecond,nanthird] = ssfm(u0,dt,dz,nz,alpha,betap,gamma,to,maxiter,tol);
%
% INPUT
%
% u0 - starting field amplitude (vector)
% dt - time step
% dz - propagation stepsize
% nz - number of steps to take, ie, ztotal = dz*nz
% alpha - power loss coefficient, ie, P=P0*exp(-alpha*z)
% betap - dispersion polynomial coefs, [beta_0 ... beta_m]
% gamma - nonlinearity coefficient
% to - optical cycle time = lambda0/c (default = 0)
% maxiter - max number of iterations (default = 4)
% tol - convergence tolerance (default = 1e-5)
if (nargin<10)                                 
    tol = 1e-5;
end
if (nargin<9)
    maxiter = 4;
end 
if (nargin<8)
    to = 0;    
end 

nt = length(u0);                                %采样点数
w0 = 2*pi/to;                                   %参考角频率或载波角频率                               
w = 2*pi*[(0:nt/2-1),(-nt/2:-1)]'/(dt*nt);      %角频率序列
hR = ramanhR(((1:nt)-1/2)*dt).';   
fR = 0.245;

halfstep = -alpha/2;
for ii = 0:length(betap)-1;
    halfstep = halfstep + 1i*betap(ii+1)*(w).^ii/factorial(ii);
end
halfstep = exp(halfstep*dz/2);

u1 = u0;
ufft = ifft(u0)*nt;  
fhR =ifft(hR)*nt;

for iz = 1:nz
    fprintf(1, '\b\b\b\b\b\b%5.2f%%', iz * 100.0 /nz);
    uhalf = fft(halfstep.*ufft)/nt;

    for ii = 1:maxiter
        firstterm = ((abs(u1).^2 + abs(u0).^2));   
        nan_region = isnan(firstterm);
        firstterm(nan_region) = 0;        
        nanfirst = sum(nan_region);
        if w0 ~= Inf
            secondterm = (1i./w0) .* (((1./u1).*gradient((abs(u1).^2).*u1)./dt)...
                +((1./u0) .* gradient((abs(u0).^2).*u0)./dt));   
            nan_region = isnan(secondterm);
            secondterm(nan_region) = 0;       
            nansecond = sum(nan_region);

            thirdterm = fft((fhR.*ifft(firstterm))*dt);
            thirdterm = thirdterm + (1i./(w0.*(u0))).*gradient(((u0).*thirdterm.*0.5))./dt...
                + (1i./(w0.*(u1))).*gradient(((u1).*thirdterm.*0.5))./dt;
            nan_region = isnan(thirdterm);
            thirdterm(nan_region) = 0; 
            nanthird = length(nan_region);
        else
           secondterm = 0;
           nansecond = 0;
           thirdterm = fft((fhR.*ifft(firstterm)*nt)*dt)/nt;
           nanthird = 0;
        end
        
        uv = exp(1i*gamma*(((1-fR)*(firstterm + secondterm) + fR*thirdterm)*dz/2)) .* uhalf;        
        ufft = halfstep.*ifft(uv)*nt;
        uv = fft(ufft)/nt;
      
        if (norm(uv-u1,2)/norm(u1,2) < tol)
            u1 = uv; 
            break;
        end
         u1 = uv;  
    end
    if (ii == maxiter)
        warning('progr:Nneg','Failed to converge to %f in %d iterations',...
        tol,maxiter);
    end
    u0 = u1;
end

end
