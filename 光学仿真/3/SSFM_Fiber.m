function Eout = SSFM_Fiber(Ein,dz,nz)
global Ts;              % s

% Fiber parameters
gamma = 3e-2;           % W^-1 m^-1
beta1x = 0;             % ps/m
beta2x = 0;             % ps^2/m
beta3x =  5.67e-5;      % ps^3/m
beta4x =  -2.43e-7;      % ps^4/m
betap = [0 beta1x beta2x beta3x beta4x]';	    % Dispersion at lamda0
alpha = 1e-4;           % 1/m

% Generate the dispersion operator 
N = length(Ein);         % the number of point
w = 2*pi*[(0:N/2-1),(-N/2:-1)]'/(Ts*N*1e12);	%constructing used frequencies (rad.THz)
linearoperatorx = -alpha/2;
for ii = 0:length(betap)-1;
  linearoperatorx = linearoperatorx - 1j*betap(ii+1)*(w).^ii/factorial(ii);     % (rad/m)
end
halfstepx = exp(linearoperatorx*dz/2);

% The split-step Fourier method
ufft = fft(Ein); 
for i=1:nz,
  % Dispersion in the first half distance dz/2
  uhalf = ifft(halfstepx.*ufft);
  % Add the nonlinear operator in the middle point
  u1 = uhalf.*exp(1j*gamma*(abs(uhalf).^2)*dz);
  % Dispersion in the second half distance dz/2
  ufft = halfstepx.*(fft(u1)); % 
end
Eout = ifft(ufft);
