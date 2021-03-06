function [u1,number_of_FFTs] = ssprop(u0,dt,dz,nz,alpha,betap,gamma,tol);

% This function solves the nonlinear Schrodinger equation for
% pulse propagation in an optical fiber using the split-step
% Fourier method according to the non-linear phase rotation criterion.
%
% USAGE
%
% u1 = ssprop(u0,dt,dz,nz,alpha,betap,gamma);
% u1 = ssprop(u0,dt,dz,nz,alpha,betap,gamma,tol);
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
% tol - convergence tolerance (default = 1e-5)
%
% OUTPUT
%
% u1 - field at the output
% number_of_FFTs - number of Fast Fourier Transforms performed during the
% propagation
%
% NOTES  The dimensions of the input and output quantities can
% be anything, as long as they are self consistent.  E.g., if
% |u|^2 has dimensions of Watts and dz has dimensions of
% meters, then gamma should be specified in W^-1*m^-1.
% Similarly, if dt is given in picoseconds, and dz is given in
% meters, then beta(n) should have dimensions of ps^(n-1)/m.

if (nargin<8)
  tol = 1e-5;
end

nt = length(u0);
w = 2*pi*[(0:nt/2-1),(-nt/2:-1)]'/(dt*nt);

% constructing linear operator
linearoperator = -alpha/2;
for ii = 0:length(betap)-1;
  linearoperator = linearoperator - j*betap(ii+1)*(w).^ii/factorial(ii);
end

u1 = u0;
nf = 0; % parameter to save the number of FFTs
ufft = fft(u0); nf = nf + 1;

fiberlength = nz*dz;
propagedlength =0;

% Performig the SSFM according to the NLPR method spatial-step size
fprintf(1, '\nSimulation running...      ');
while propagedlength < fiberlength,
  dz = tol/(gamma * max(abs(u1).^2));
  if (dz + propagedlength) > fiberlength,
        dz = fiberlength - propagedlength;
  end
  halfstep = exp(linearoperator*dz/2);
  uhalf = ifft(halfstep.*ufft); nf = nf + 1;
  
  u1 = uhalf .* exp(-j*gamma*(abs(uhalf).^2 )*dz);
  ufft = halfstep.*fft(u1); nf = nf + 1;
  u1 = ifft(ufft); nf = nf + 1;

  propagedlength = propagedlength + dz;
  fprintf(1, '\b\b\b\b\b\b%5.1f%%', propagedlength * 100.0 /fiberlength );
end

% giving output parameters
u1 = ifft(ufft);
number_of_FFTs = nf;

