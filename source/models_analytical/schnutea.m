function [ F ] = schnutea( params,t )
%GOMPERTZA Summary of this function goes here
%   Detailed explanation goes here
a      = params(1);
b      = params(2);
lambda = params(3);
mu     = params(4);

F = (mu * ( 1 - b ) / a ) * ( (1 - b * exp(a * lambda + 1 - b - a * t ) ) / ( 1 - b ) )^(1/b);

end
