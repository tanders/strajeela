include "alldifferent.mzn";

int: n=12;

array[1..n] of var 1..n: x;      % sequence of numbers
array[1..n-1] of var 1..n-1: u;  % sequence of differences

constraint alldifferent(x);
constraint alldifferent(u);
constraint forall(i in 1..n-1)(u[i] = abs(x[i+1] - x[i]));

% solve satisfy; % much less efficient (at least for default solver)
%% uses > 1s with default solver -- Gecode much faster
% solve :: int_search(x, first_fail, indomain_min, complete)
%        satisfy;
%% random value ordering -- but different solutions also need different random seed
solve :: int_search(x, first_fail, indomain_random, complete)  
        satisfy;
output ["x = ",show(x),"\n"];
