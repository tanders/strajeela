% solver: fzn-gecode
% flags: -r 3
%

include "globals.mzn";

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% TODO
%
%% Note: additional propagation slightly slowed down search -- currently more work for solver without reducing search space
%%  Performance for additional compositional etc. constraints may benefit, lets see 
% - Can I somehow improve propagation?
%   - OK event_duration / event_duration_accum: reduce upper bound depending on possible summed duration
%   - OK propagation from durations etc back to new_event
%   - indices: take own index into account (e.g., index in the middle cannot have max/min current index)
%   - propagation from indices back to new_event
%
% - New array storing indices or new note start slices (dense representation)
%   -> possibly this is not a good idea...
%   Can I somehow use event_indices_set instead
%
% - Tests with simple rhythmic constraints (e.g., all notes with same/different durs)
% - Get access to all different start indices (e.g., with set constraints) for all-different constraints (will have appaling propagation)
%
% - add support for rests
% 


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

%% Constrains the elements of array 'ys' to be all different except those
%% elements that are assigned to 'x'.
%% source: modification of MiniZInc's alldifferent_except_0.mzn
predicate alldifferent_except_x(var int: x, array[int] of var int: ys) = 
    forall(i, j in index_set(ys) where i != j) (
       (ys[i] != x /\ ys[j] != x) -> ys[i] != ys[j]
    );


%% Convert an array to a set. Array elements are in increasing order.
%% Doublicates are only allowed at the end.
%% source: modification of array2set in http://www.hakank.org/minizinc/common.mzn
%% !! NOTE: this results in an expensive constraint, because of little propagation (basically, array is searched for after set is already found -- the array is not found by propagation)
predicate array2set(array[int] of var int: xs, var set of int: S) =
  let { int: n = length(xs) }
in
  increasing(xs) /\
  alldifferent_except_x(xs[1], xs) /\ % important for avoiding symmetries
  forall(i in index_set(xs)) ( xs[i] in S ) /\
  % secure that the values _not_ in xs are _not_ in S (up to the number of elements in the set)
  forall(i in lb_array(xs)..ub_array(xs)) (
    (not exists(j in index_set(xs)) (xs[j] = i ) <-> not (i in S))
  );

% predicate array2set(array[int] of var int: x, var set of int: s) =
%    let { int: n = length(x) }
%    in
%    forall(i in index_set(x)) (  x[i] in s ) /\
%    % secure that the values _not_ in x are _not_ in s
%    forall(i in lb_array(x)..ub_array(x)) (
%      (not exists(j in index_set(x)) (x[j] = i ) <-> not (i in s))
%    );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% variable declarations
%% 

int: max_slice_dur = 8; % !! can be inconsistent with slice_duration domain
int: max_end_time = n*max_slice_dur;

array[1..n] of var {1}: slice_duration; % TMP: uniform domain
% array[1..n] of var {1, 2, 4, 8}: slice_duration;
array[1..n] of var 0..max_end_time: slice_start;
%% new/old event marker (one more to mark end of last event)
%% I need Boolean representation for many constraints, and integer representation for branching
array[1..n] of var bool: new_event; 
array[1..n] of var 0..1: new_event_fd; 
constraint forall(i in 1..n)( 
  bool2int(new_event[i]) = new_event_fd[i]
);
var set of 1..n: event_indices_set; % set of indices where events start
%% event start indices without intermediate elements (e.g., consecutive indices are always pointing to different events)
array[1..n] of var 1..n: event_indices_seamless; 
%% start of most recently started note (not necessarily still playing)
array[1..n] of var 0..max_end_time: recentStartTime; 
% array[1..n] of var 0..max_end_time: event_startTime; % same as recentStartTime -- until I introduced rests
%% accumulator for duration: value before new_event=true correct event_duration
array[1..n] of var 1..max_end_time: event_duration_accum; 
array[1..n] of var 1..max_end_time: event_duration; 
% array[1..n] of var 48..72: event_pitch; % MIDI note numbers

%% TMP comments
% array[1..n] of var 0..n: current_start_index; % index of current new_event 
% array[1..n] of var 0..n: predecessor_start_index; % index of preceeding new_event 
% array[1..n] of var 0..n: successor_start_index; % index of preceeding new_event 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% constraints
%% 

% !! TODO: TMP -- aux until I introduced rests
constraint new_event[1] = true;

% slice_start / slice_duration
constraint slice_start[1] = 0;
constraint forall(i in 1..n-1)( 
  slice_start[i] + slice_duration[i] = slice_start[i+1] 
);

% TODO: recentStartTime cannot express yet whether never any event started yet (i.e., whether score started with rest)
%% recentStartTime
constraint forall(i in 2..n)( 
  ( not new_event[i] ) <->  (recentStartTime[i] = recentStartTime[i-1])
);
constraint forall(i in 1..n)( 
   new_event[i] <-> (recentStartTime[i] = slice_start[i] )
);
constraint forall(i in 1..n)( % redundant constraint for propagation
   recentStartTime[i] <= slice_start[i]
);
constraint forall(i in 2..n)( % redundant constraint for propagation
   recentStartTime[i] >= recentStartTime[i-1]
);


% event_duration_accum
constraint forall(i in 1..n)( 
  new_event[i] <-> ( event_duration_accum[i] = slice_duration[i] ) 
);
constraint forall(i in 2..n)( 
 not new_event[i] <-> ( event_duration_accum[i] = event_duration_accum[i-1] + slice_duration[i] )
);
constraint forall(i in 2..n)( % redundant constraint for propagation
 event_duration_accum[i] <= event_duration_accum[i-1] + slice_duration[i] 
);
% event_duration
constraint forall(i in 1..n-1)( 
  new_event[i+1] <-> ( event_duration[i] = event_duration_accum[i] ) 
);
constraint event_duration[n] = event_duration_accum[n]; % after last event a "new event" implicitly starts   
constraint forall(i in 1..n-1)( 
 not new_event[i+1] -> ( event_duration[i] = event_duration[i+1] ) % ! no equivalence, only implication
);
constraint forall(i in 1..n)( % redundant constraint for propagation
  event_duration[i] >= event_duration_accum[i] 
);
constraint forall(i in 2..n)( % redundant constraint for propagation
  event_duration[i-1] <= max([ event_duration_accum[i-1]+1, event_duration[i] ])
);
%%% seemingly implied in above redundant constraint
%% constraint forall(i in 1..n)( % redundant constraint for propagation
%%   event_duration[i] <= max(event_duration_accum)
%% );


%% event_indices_seamless
%%
%% TODO: not yet a seamless representation -- 
%% a local counter parameter and incrementation could help, but that is not possible
%% TODO: find existing global constraint that somehow "compacts" a sparse array -- new_event and new_event_fd are sparse arrays
%%
%% Can I somehow use element constraint? I want the indices of all elements in new_event_fd whose value is 1
%%
%% Possibly useful global constraints
%% - circuit / subcircuit
%% - roots
%%   roots(new_event_fd, event_indices_set, {1})
%%   

%% event_indices_set
%% event_indices_seamless
constraint link_set_to_booleans(event_indices_set, new_event);
%% BUGs: 
%% - array2set must be revised to cater for 0s at end of event_indices_seamless 
%% - elements in event_indices_seamless possibly not sorted
constraint array2set(event_indices_seamless, event_indices_set);
%% TODO: first m elements in event_indices_seamless as in event_indices_set
%% I am looking for the MiniZinc equivalent of the Oz constraint {FS.int.match *M *Dv}
%% TODO: rest is 0
%% !! BUG: i in S seems not to work with with set variable S
% constraint forall(event_index in event_indices_set, j in event_indices_seamless)( 
%   event_indices_seamless[j] = event_index
% );
%% dummy test
% constraint forall(event_index in event_indices_set)( 
%   event_indices_seamless[event_index] = event_index
% );

%% TMP test -- musing
%%
%% bool2int(i in event_indices_set)
%%
%% ! BUG: I want a variant of inverse
% inverse(new_event_fd, event_indices_seamless_tmp)
% sort(event_indices_seamless_tmp, event_indices_seamless) % but now 0s are at the beginning, not the end


%% TMP comments
%%
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
%% TMP tests
%%

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

%% consecutive events differ in duration
%% !! NB: non-existing successor not handled! 
% int: ii = 1;
% constraint event_duration[ii] != event_duration[successor_start_index[ii]] ;

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
% predicate successors(array[int] of var int: xs, int: start_index) =
%   forall(i in index_set(xs))(
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
%% solve and output
%% 

solve :: int_search(slice_duration ++ new_event_fd, 
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
  ++ "new_event: " ++ show(new_event_fd) ++ "\n"
%   ++ "new_event: " ++ show(new_event) ++ "\n"
  ++ "recentStartTime: " ++ show(recentStartTime) ++ "\n"
%  ++ "event_startTime: " ++ show(event_startTime) ++ "\n" 
  ++ "event_duration_accum: " ++ show(event_duration_accum) ++ "\n"
  ++ "event_duration: " ++ show(event_duration) ++ "\n"
  ++ "event_indices_set: " ++ show(event_indices_set) ++ "\n"
  ++ "event_indices_seamless: " ++ show(event_indices_seamless) ++ "\n"
%   ++ "current_start_index: " ++ show(current_start_index) ++ "\n"
%   ++ "predecessor_start_index: " ++ show(predecessor_start_index) ++ "\n"
%   ++ "successor_start_index: " ++ show(successor_start_index) ++ "\n"
];
