% 
% Copy/initialize/ensure equality of arrays in MiniZinc.
% 
% According to the specification of MiniZinc (at least since version 1.0.3) 
% assignments and comparisons of arrays are not allowed. E.g. this construct 
% is not allowed:
%    array[1..4] of var int: x;
%    constraint
%       x = [1,2,3,4]
%    ;
%
% Many of my models, especially the global constraint examples, use this
% type of assignment for checking the global constraints.
%
% The following cp<dim>d predicates is one way of doing almost the 
% same thing.

% 
% This MiniZinc model was created by Hakan Kjellerstrand, hakank@bonetmail.com
% See also my MiniZinc page: http://www.hakank.org/minizinc
%
include "globals.mzn"; 
int: n = 4;
array[1..n] of var 1..n: x;

%
% int
%
% arrays of 1d where the first is fix int, the second is var int
predicate cp1d(array[int] of int: x, array[int] of var int: y) =
  assert(index_set(x) = index_set(y),
           "cp1d: x and y have different sizes",
    forall(i in index_set(x)) ( x[i] = y[i] ) )
; 

% arrays of 1d where both arguments are var int
predicate cp1d(array[int] of var int: x, array[int] of var int: y) =
  assert(index_set(x) = index_set(y),
           "cp1d: x and y have different sizes",
     forall(i in index_set(x)) ( x[i] = y[i] ))
; 

% arrays of 2d where the first is fix int
predicate cp2d(array[int,int] of int: x, array[int,int] of var int: y) =
  assert(index_set_1of2(x) = index_set_1of2(y) /\
         index_set_2of2(x) = index_set_2of2(y),
           "cp2d: x and y have different sizes",
      forall(i in index_set_1of2(x), j in index_set_2of2(x)) (
         y[i,j] = x[i,j]
     ) 
  )
; 

% arrays of 2d where both arguments are var int
predicate cp2d(array[int,int] of var int: x, array[int,int] of var int: y) =
  assert(index_set_1of2(x) = index_set_1of2(y) /\
         index_set_2of2(x) = index_set_2of2(y),
           "cp2d: x and y have different sizes",
     forall(i in index_set_1of2(x), j in index_set_2of2(x)) (
         y[i,j] = x[i,j]
    ) 
  )
; 

%
% set of int
%
% first argument is set of fix int
predicate cp1d(array[int] of set of int: x, array[int] of var set of int: y) =
  assert(index_set(x) = index_set(y),
           "cp1d: x and y have different sizes",
    forall(i in index_set(x)) ( x[i] = y[i] ))
; 

% both arguments are var set of int
predicate cp1d(array[int] of var set of int: x, array[int] of var set of int: y) =
  assert(index_set(x) = index_set(y),
           "cp1d: x and y have different sizes",
    forall(i in index_set(x)) ( x[i] = y[i] ))
; 

predicate cp2d(array[int,int] of set of int: x, array[int,int] of var set of int: y) =
  assert(index_set_1of2(x) = index_set_1of2(y) /\
         index_set_2of2(x) = index_set_2of2(y),
           "cp2d: x and y have different sizes",
    forall(i in index_set_1of2(x), j in index_set_2of2(x)) (
        y[i,j] = x[i,j]
    ) 
  )
; 

predicate cp2d(array[int,int] of var set of int: x, array[int,int] of var set of int: y) =
  assert(index_set_1of2(x) = index_set_1of2(y) /\
         index_set_2of2(x) = index_set_2of2(y),
           "cp2d: x and y have different sizes",
     forall(i in index_set_1of2(x), j in index_set_2of2(x)) (
        y[i,j] = x[i,j]
     ) 
 )
; 


solve satisfy;
% solve :: int_search(x, first_fail, indomain_min, complete) satisfy;

constraint
   % cp1d([1,2,_,4], x) /\
   cp1d([1,2,3,4], x) /\
   increasing(x)
;


output
[
  show(x)
];