
include "globals.mzn";

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% TODO
%
%

% - Extend to simple counterpoint example
%   Compare performance with equivalent Strasheela example 
%
% - add support for rests
% 

%
% - OK New array storing indices or new note start slices (dense representation)
%   -> possibly this is not a good idea...
%   Can I somehow use event_indices_set instead
%
%% Note: additional propagation slightly slowed down search -- currently more work for solver without reducing search space
%%  Performance for additional compositional etc. constraints may benefit, lets see 
% - Can I somehow improve propagation?
%   - OK event_duration / event_duration_accum: reduce upper bound depending on possible summed duration
%   - OK propagation from durations etc back to new_event
%   - OK indices: take own index into account (e.g., index in the middle cannot have max/min current index)
%   - OK propagation from indices back to new_event
%
% - OK In current version 1 solution excluded (before 512  solutions for n=10, now only 511) -- why?
%  Several differences between list of all solutions for versions with and without new index constraints (solutions visited in different order)
%  How many solutions possible for 10 binary variables: 2^9 = 512. (One of the 10 vars is fixed beforehand) 
%  -> Possible way to find excluded solution: (automatically) create data files for all 512 solutions; create shell script to run all 512 tests; identify excluded solution by its output
%  !! new_event_fd = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]  ; =====UNSATISFIABLE=====
%% Perhaps UNSATISFIABLE because it excludes 11 in event_indices_seamless?
%
% - OK Tests with simple rhythmic constraints (e.g., all notes with same/different durs)
% - OK Get access to all different start indices (e.g., with set constraints) for all-different constraints (will have appaling propagation)
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Data input
% 

% Music representation based on Interwoven Voices List (Sneyers) and **kern 
% int: n; 
int: n = 10; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Predicate definitions
%% 

%% Constrains the elements of array 'y' to be all different except those
%% elements that are assigned to 'x'.
%% source: modification of MiniZInc's alldifferent_except_0.mzn
%% unused after all
predicate alldifferent_except_x(var int: x, array[int] of var int: y) = 
    forall(i, j in index_set(y) where i != j) (
       (y[i] != x /\ y[j] != x) -> y[i] != y[j]
    );

%% Convert a set S to an array x[1..n]. Set elements are in increasing order in the array, and set elements must be in 1..n.
%% If the array is longer than there are set elements, then the end of the array is padded with n+1.
predicate set2array(var set of int: S, array[int] of var int: x) =
  let { int: n = length(x),
        int: exceeding = n+1 }
in  
  %% main constraint
  forall(dom_val in lb_array(x)..ub_array(x)) (
    exists(i in 1..n)(dom_val = exceeding \/ x[i] = dom_val) <-> dom_val in (S union {exceeding})
  ) /\
  %% greatly improve propagation
  increasing(x) /\
  forall(i in 1..n-1)( card(S) >= i -> x[i] < x[i+1] );


%% Constraints for time slice arrays shared by all voices
predicate slice_constraints(array[int] of var int: slice_start, array[int] of var int: slice_duration) =
  slice_start[1] = 0 /\
  forall(i in 1..n-1)( 
    slice_start[i] + slice_duration[i] = slice_start[i+1] 
  );


%% !! TODO: recentStartTime cannot express yet whether never any event started yet (i.e., whether score started with rest)
predicate recentStartTime_constraints(
    array[int] of var bool: new_event,
    array[int] of var int: slice_start, 
    array[int] of var int: recentStartTime) = 
  let { int: n = length(new_event) }
in  
  forall(i in 1..n)( 
    (new_event[i] <-> (recentStartTime[i] = slice_start[i] )) /\
    %% redundant constraint for propagation 
    recentStartTime[i] <= slice_start[i]
  ) /\  
  forall(i in 2..n)( 
    ( not new_event[i] ) <->  (recentStartTime[i] = recentStartTime[i-1]) /\
    %% redundant constraint for propagation 
    recentStartTime[i] >= recentStartTime[i-1]
  );

predicate event_duration_constraints(
    array[int] of var bool: new_event,
    array[int] of var int: slice_duration, 
    array[int] of var int: event_duration_accum,
    array[int] of var int: event_duration) =
  let { int: n = length(new_event) }
in  
  %% event_duration_accum
  forall(i in 1..n)( 
    new_event[i] <-> ( event_duration_accum[i] = slice_duration[i] )
  ) /\
  forall(i in 2..n)( 
    (not new_event[i] <-> ( event_duration_accum[i] = event_duration_accum[i-1] + slice_duration[i] )) /\
    %% redundant constraint for propagation 
    event_duration_accum[i] <= event_duration_accum[i-1] + slice_duration[i]
  ) /\
  %% event_duration
  event_duration[n] = event_duration_accum[n] /\ % last duration must be its accum  
  forall(i in 1..n-1)( 
    (new_event[i+1] <-> ( event_duration[i] = event_duration_accum[i] )) /\ 
    (not new_event[i+1] -> ( event_duration[i] = event_duration[i+1] )) /\ % ! no equivalence, only implication
    %% redundant constraint for propagation 
    event_duration[i] <= max([ event_duration_accum[i]+1, event_duration[i+1] ])
  ) /\
  forall(i in 1..n)( 
    %% redundant constraint for propagation
    event_duration[i] >= event_duration_accum[i] 
  );
%%% seemingly implied in above redundant constraint
%% constraint forall(i in 1..n)( % redundant constraint for propagation
%%   event_duration[i] <= max(event_duration_accum)
%% );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Variable declarations
%% 

%% General variables

int: max_slice_dur = 8; % !! can be inconsistent with slice_duration domain
int: max_end_time = n*max_slice_dur;

array[1..n] of var {1}: slice_duration; % TMP: uniform domain
% array[1..n] of var {1, 2, 4, 8}: slice_duration;
array[1..n] of var 0..max_end_time: slice_start;

%% Voice-specific variables

%% new_event/new_event_fd: I need Boolean representation for many constraints, and integer representation for branching
array[1..n] of var bool: new_event_1; 
array[1..n] of var 0..1: new_event_fd_1; 
var set of 1..n: event_indices_set_1; % set of indices where events start
%% event start indices without intermediate elements (e.g., consecutive indices are always pointing to different events)
array[1..n] of var 1..n+1: event_indices_seamless_1; % n+1 to mark indices beyond the range
%% start of most recently started note (not necessarily still playing)
array[1..n] of var 0..max_end_time: recentStartTime_1; 
% array[1..n] of var 0..max_end_time: event_startTime; % same as recentStartTime -- until I introduced rests
%% accumulator for duration: value before new_event=true correct event_duration
array[1..n] of var 1..max_end_time: event_duration_accum_1; 
array[1..n] of var 1..max_end_time: event_duration_1; 
% array[1..n] of var 48..72: event_pitch; % MIDI note numbers

% %% TMP comments
% array[1..n] of var 0..n: current_start_index; % index of current new_event 
% array[1..n] of var 0..n: predecessor_start_index; % index of preceeding new_event 
% array[1..n] of var 0..n: successor_start_index; % index of preceeding new_event 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Constraints
%% 

constraint slice_constraints(slice_start, slice_duration);

constraint forall(i in 1..n)(bool2int(new_event_1[i]) = new_event_fd_1[i]);

constraint recentStartTime_constraints(new_event_1, slice_start, recentStartTime_1);

constraint event_duration_constraints(new_event_1, slice_duration, event_duration_accum_1, event_duration_1);

%% event_indices_set
%% event_indices_seamless
constraint link_set_to_booleans(event_indices_set_1, new_event_1);
constraint set2array(event_indices_set_1, event_indices_seamless_1);



% %% TMP comments
% %%
% % current_start_index
% constraint forall(i in 1..n)( 
%   new_event[i] -> ( current_start_index[i] = i ) 
% );
% constraint forall(i in 2..n)( 
%  not new_event[i] -> ( current_start_index[i] = current_start_index[i-1] )
% );
% % predecessor_start_index
% constraint predecessor_start_index[1] = 0; % no predecessor for first slice
% constraint forall(i in 2..n)( 
%   new_event[i] -> ( predecessor_start_index[i] = current_start_index[i-1] ) 
% );
% constraint forall(i in 2..n)( 
%  not new_event[i] -> ( predecessor_start_index[i] = predecessor_start_index[i-1] )
% );
% % successor_start_index
% constraint successor_start_index[n] = 0; % no successor for last slice
% constraint forall(i in 1..n-1)( 
%   new_event[i+1] -> ( successor_start_index[i] = current_start_index[i+1] ) 
% );
% constraint forall(i in 1..n-1)( 
%  not new_event[i+1] -> ( successor_start_index[i] = successor_start_index[i+1] )
% );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%   TMP tests
%%

% !! TODO: TMP -- aux until I introduced rests
constraint new_event_1[1] = true;


% %% consecutive events differ in duration
% constraint forall(i in 1..n-1) (  
%   event_indices_seamless[i+1] <= n -> 
%     event_duration[event_indices_seamless[i]] != event_duration[event_indices_seamless[i+1]] ); 

% % arrays of 1d where the first is fix int, the second is var int
% predicate cp1d(array[int] of int: x, array[int] of var int: y) =
%   assert(index_set(x) = index_set(y),
%            "cp1d: x and y have different sizes",
%     forall(i in index_set(x)) ( x[i] = y[i] ) )
% ; 
% constraint cp1d([1, 1, 1, 1, 1, 1, 1, 1, 1, 1], new_event_fd);


% constraint new_event[4] = true;
% constraint new_event[7] = true;

% array[1..n] of int: tmp_array = [1, 0, 0, 1, 0, 0, 1, 0, 0, 1];  % !! results in fail!! 
% % array[1..n] of int: tmp_array = [1, 0, 0, 1, 0, 0, 1, 0, 0, 0];
% constraint forall(i in 1..n)(
%   new_event_fd[i] = tmp_array[i]
% );

% array[1..n] of int: tmp_array = [3, 3, 3, 3, 3, 3, 3, 3, 3, 1];  
% constraint forall(i in 1..5)(
%   event_duration[i] = tmp_array[i]
% );

%% all events of same duration (for n=12 or other values that allow for that)
%% this is still easy to constrain :)
% constraint forall(i in 1..n-1)(
%   event_duration[i] = event_duration[i+1]
% );

%% TODO: can I have an alternative notation (or existing constraint) for the following to simplify accessing an nth successor?
%% 
% successor_start_index[successor_start_index[ii]]

%% Recursive predicate definition permitted?
%%   Seemingly not: get "cycle error: cycle in definition of `nth_successor'" 
%%   However, in MiniZinc tutorial, figure 58 shows two recursive predicate definitions 
%% TODO: ?? make tail recursive ?
% predicate nth_successor(var int: index, int: m) = 
%   if m > 1
%   then nth_successor(successor_start_index[index], m-1)
%   else successor_start_index[index]
%   endif;

%% TODO: unfinished def
%% expects an array and fills it with all the successor indices of start_index
%% once this works, the array of a given length could also be created, but then successors must be a function
% predicate successors(array[int] of var int: x, int: start_index) =
%   forall(i in index_set(x))(
% );


% %% three consecutive events differ in duration
% constraint event_duration[1] != event_duration[successor_start_index[1]]; 
% constraint forall(i in 1..2)(
%   event_duration[nth_successor(1, i)] != event_duration[nth_successor(1, i+1)]
% );

%% all event durations are different

%% event_duration: combine set and "exising" index collection 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Solve and output
%% 

% solve :: int_search(slice_duration ++ new_event_fd, 
%% TMP: search also for event_indices_seamless
solve :: int_search(new_event_fd_1 ++ slice_duration, % ++ event_indices_seamless, 
  first_fail, 
%   most_constrained,
  indomain_random, complete)
  satisfy;

% solve :: seq_search([
%     int_search(slice_duration, first_fail, indomain_random, complete), 
%     bool_search(new_event, first_fail, indomain_random, complete) ]) 
%   satisfy;

output [ 
  "slice_duration: " ++ show(slice_duration) ++ "\n" 
  ++ "slice_start: " ++ show(slice_start) ++ "\n" 
  ++ "new_event_1: " ++ show(new_event_fd_1) ++ "\n"
  ++ "recentStartTime_1: " ++ show(recentStartTime_1) ++ "\n"
%  ++ "event_startTime: " ++ show(event_startTime) ++ "\n" 
  ++ "event_duration_accum_1: " ++ show(event_duration_accum_1) ++ "\n"
  ++ "event_duration_1: " ++ show(event_duration_1) ++ "\n"
  ++ "event_indices_set_1: " ++ show(event_indices_set_1) ++ "\n"
  ++ "event_indices_seamless_1: " ++ show(event_indices_seamless_1) ++ "\n"
%   ++ "current_start_index: " ++ show(current_start_index) ++ "\n"
%   ++ "predecessor_start_index: " ++ show(predecessor_start_index) ++ "\n"
%   ++ "successor_start_index: " ++ show(successor_start_index) ++ "\n"
];
