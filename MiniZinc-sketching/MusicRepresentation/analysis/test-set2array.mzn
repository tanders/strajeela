
include "globals.mzn";

%  !! new_event_fd = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]  ; =====UNSATISFIABLE=====
%% Perhaps UNSATISFIABLE because it excludes 11 in event_indices_seamless?

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% data input
% 

% Music representation based on Interwoven Voices List (Sneyers) and **kern 
% int: n; 
int: n = 10; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% predicate definitions
%% 

%% Convert a set S to an array xs[1..n]. Set elements are in increasing order in the array, and set elements must be in 1..n.
%% If the array is longer than there are set elements, then the end of the array is padded with n+1.
predicate set2array(var set of int: S, array[int] of var int: xs) =
  let { int: n = length(xs),
        int: exceeding = n+1 }
in
  %% improve propagation
  forall(i in 1..n-1)( card(S) >= i -> xs[i] < xs[i+1] ) /\
  increasing(xs) /\ % redundant, but may help..
  forall(dom_val in lb_array(xs)..ub_array(xs)) (
    exists(i in 1..n)(dom_val = exceeding \/ xs[i] = dom_val) <-> dom_val in (S union {exceeding})
  );



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% variable declarations
%% 

var set of 1..n: event_indices_set; % set of indices where events start
array[1..n] of var 1..n+1: event_indices_seamless; % n+1 to mark indices beyond the range


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% constraints
%% 

%% event_indices_set
%% event_indices_seamless
% constraint link_set_to_booleans(event_indices_set, new_event);
constraint set2array(event_indices_set, event_indices_seamless);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%   TMP tests
%%

% arrays of 1d where the first is fix int, the second is var int
predicate cp1d(array[int] of int: x, array[int] of var int: y) =
  assert(index_set(x) = index_set(y),
           "cp1d: x and y have different sizes",
    forall(i in index_set(x)) ( x[i] = y[i] ) )
; 

%% !!! =====UNSATISFIABLE=====
% constraint cp1d([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], event_indices_seamless);

constraint cp1d([1, 2, 3, 4, 5, 6, 7, 8, 10, 11], event_indices_seamless);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% solve and output
%% 

% solve :: int_search(slice_duration ++ new_event_fd, 
%% TMP: search also for event_indices_seamless
solve :: int_search(event_indices_seamless, 
  first_fail, 
  indomain_random, complete)
  satisfy;


output [ 
  "event_indices_set: " ++ show(event_indices_set) ++ "\n"
  ++ "event_indices_seamless: " ++ show(event_indices_seamless) ++ "\n"
];