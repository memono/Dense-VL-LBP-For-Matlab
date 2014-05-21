function lbp_fea = dense_vl_lbp( I_gray,wndSize )
%dense_vl_lbp High Dense LBP implement by Memono
%
%   Make padding to extract LBP for every pixel.
%   Input: 
%       I_gray:     Gray image 
%       wndSize:    Window size (should be odd)

% empty input
if nargin < 1
    lbp_fea = [];
    return
end

% default wndSize
if nargin < 2
    wndSize = 5;
end

% check wndSize
if nargin < 3
    if wndSize<0 || mod(wndSize,2)~=1
        wndSize = floor(abs(wndSize)/2)*2+1;
    end
end

% the dimension of vl_lbp feature
LBP_Z = 58;

h = size(I_gray,1);
w = size(I_gray,2);

% frameh(or w) is equal to the n that (n>=h & n%wndSize==0).
% Delta is the size of padding placed out of the frame.
frameh = ceil(h/wndSize)*wndSize;
framew = ceil(w/wndSize)*wndSize;
delta = (wndSize-1)/2;

% padding [ 0s ; delta frame delta ; 0s ]
Ipad = single(zeros(frameh+delta*2,framew+delta*2));
Ipad((delta+1):(delta+h),(delta+1):(delta+w)) = I_gray;
Ipad = single(Ipad);


% extract vl_lbp & reshape to columes with lbp features in Z axis
lbpcr = cell(wndSize,wndSize);
for biasw=0:(wndSize-1)
    for biash=0:(wndSize-1)
        lbpcr{biash+1,biasw+1} = reshape(vl_lbp(Ipad((biash+1):(biash+frameh),(biasw+1):(biasw+framew)),wndSize),[1 frameh*framew/wndSize/wndSize LBP_Z]);
    end
end

% mix each column together
lbpcol = cell(wndSize,1);
for jj=1:(wndSize)
    lbpcol{jj} = reshape( cell2mat(lbpcr(:,jj)) ,[frameh framew/wndSize LBP_Z]);
end

% mix each row together
lbp_fea = reshape(cell2mat(lbpcol(:)),[frameh framew LBP_Z]);

% cropping
lbp_fea = lbp_fea(1:h,1:w,:);

end

