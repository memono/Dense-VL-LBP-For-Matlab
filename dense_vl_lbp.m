function lbp_fea = dense_vl_lbp( I_gray,wndSize )
%dense_vl_lbp High Dense VL_LBP implement by Memono
%
%   Make padding and sliding window to extract LBP for every pixel.
%   IT IS DEPENDED ON VL_FEAT. GET IT FROM THE OFFICAL WEBSITE
%   http://www.vlfeat.org/
%
%   lbp_fea = dense_vl_lbp( I_gray,wndSize )
%   lbp_fea = dense_vl_lbp( I_gray )
%   Input: 
%       I_gray:     Gray image (should be in type Single)
%       wndSize:    Sliding Window size (should be positive and odd )
%                   (Default: 5)
%   Output:
%       lbp_fea:    a matrix with LBP feature (like vl_lbp output)

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

% Constant: the dimension of vl_lbp feature
LBP_Z = 58;

% height & width
h = size(I_gray,1);
w = size(I_gray,2);

% The padding frame & edge is applied to make sure that every biased cropping(sliding) 
% of image can be resulted in the same size. It also allows every pixels in the image 
% (including the edge of I) to be covered.

% frameh(or framew) is equal to the first number that >= h(/w) and % wndSize == 0
% delta is the size of edge padding.
frameh = ceil(h/wndSize)*wndSize;
framew = ceil(w/wndSize)*wndSize;
delta = (wndSize-1)/2;

% image padding:
%
% frameImage = 
%   [   I , 0( h x framew-w ) ;
%       0( frameh-h x framew ) ]
%
% PaddingImage = 
%   [   0( delta x 2delta+framew ) ; 
%       0( frameh x delta ) , frameImage , 0( frameh x delta ) ; 
%       0( delta x 2delta+framew ) ]

% For example , for a 5x4 image that I(x,y)=10*x+y with wndSize=3
% Image is paded like this: (0e for edge padding and 0f for frame padding)
% Ipad       = [    0e  0e  0e  0e  0e  0e  0e  0e ;
%                   0e  11  12  13  14  0f  0f  0e ;
%                   0e  21  22  23  24  0f  0f  0e ;
%                   0e  31  32  33  34  0f  0f  0e ;
%                   0e  41  42  43  44  0f  0f  0e ;
%                   0e  51  52  53  54  0f  0f  0e ;
%                   0e  0f  0f  0f  0f  0f  0f  0e ;
%                   0e  0e  0e  0e  0e  0e  0e  0e ]    ;\

Ipad = single(zeros(frameh+delta*2,framew+delta*2));
Ipad((delta+1):(delta+h),(delta+1):(delta+w)) = I_gray;
Ipad = single(Ipad);

% extract vl_lbp & reshape to rows with lbp features in Z axis
% size of these rows = [ 1 , ? , LBP_Z ]
%
% for the 5x4 image example, ( frameh=framew=6, wndSize=3 )
%
% lbpcr{1,1} crop Ipad(1:6,1:6) and cover the pixels [ 11 41 14 44 ]
% lbpcr{2,1} crop Ipad(2:7,1:6) and cover the pixels [ 21 51 24 54 ]
% lbpcr{3,1} crop Ipad(3:8,1:6) and cover the pixels [ 31 Ipad(7,2) 34 Ipad(7,5) ]
% lbpcr{1,2} crop Ipad(1:6,2:7) and cover the pixels [ 12 42 Ipad(2,6) Ipad(5,6) ]
% lbpcr{2,2} crop Ipad(2:7,2:7) and cover the pixels [ 12 42 Ipad(2,6) Ipad(5,6) ]

lbpcr = cell(wndSize,wndSize);
for biasw=0:(wndSize-1)
    for biash=0:(wndSize-1)
        lbpcr{biash+1,biasw+1} = reshape(vl_lbp(Ipad((biash+1):(biash+frameh),(biasw+1):(biasw+framew)),wndSize),[1 frameh*framew/wndSize/wndSize LBP_Z]);
    end
end

% Mix rows together, and resize it to columns.
% Every columns in lbpcol represent the feature of wndSize-gapped columns in the frameImage
%
% for the 5x4 image example, ( frameh=framew=6, wndSize=3 )
%
% lbpcol{1} mixes [ lbpcr{1,1} ; lbpcr{2,1} ; lbpcr{3,1} ], resizes it into  [?,1,LBP_Z] 
% and it is representing pixels
% [ 11 ; 21 ; 31 ; 41 ; 51 ; 0f ; 14 ; 24 ; 34 ; 44 ; 54 ; 0f ]
% lbpcol{2}:
% [ 12 ; 22 ; 32 ; 42 ; 52 ; 0f ; 0f ; 0f ; 0f ; 0f ; 0f ; 0f ]
% lbpcol{3}:
% [ 13 ; 23 ; 33 ; 43 ; 53 ; 0f ; 0f ; 0f ; 0f ; 0f ; 0f ; 0f ]

lbpcol = cell(wndSize,1);
for jj=1:(wndSize)
    lbpcol{jj} = reshape( cell2mat(lbpcr(:,jj)) ,[frameh framew/wndSize LBP_Z]);
end

% mix each columns together, and resize it to LBP_Z-channels frameImage [frameh,framew,LBP_Z]
%
% for the 5x4 image example, ( frameh=framew=6, wndSize=3 )
%
% lbp_fea representing pixels:
% [ 11 ; 12 ; 13 ; 14 ; 0f ; 0f ;
%   21 ; 22 ; 23 ; 24 ; 0f ; 0f ; 
%   31 ; 32 ; 33 ; 34 ; 0f ; 0f ; 
%   41 ; 42 ; 43 ; 44 ; 0f ; 0f ;
%   51 ; 52 ; 53 ; 54 ; 0f ; 0f ;
%   0f ; 0f ; 0f ; 0f ; 0f ; 0f ]
lbp_fea = reshape(cell2mat(lbpcol(:)),[frameh framew LBP_Z]);

% cropping ( SORRY, NO EXAMPLE :D )
lbp_fea = lbp_fea(1:h,1:w,:);

end

