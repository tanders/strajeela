% solver: fzn-gecode
% flags: -r 3
%

include "globals.mzn";

% Music representation based on Interwoven Voices List (Sneyers) and **kern 
int: n = 10; 
int: max_slice_dur = 8; % !! can be inconsistent with slice_duration domain
int: max_end_time = n*max_slice_dur;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

array[1..n] of var {1}: slice_duration; % TMP: uniform domain
% array[1..n] of var {1, 2, 4, 8}: slice_duration;
array[1..n] of var 0..max_end_time: slice_start;
%% new/old event marker (one more to mark end of last event)
array[1..n] of var bool: new_event; 
% array[1..n+1] of var bool: new_event; 
% constraint new_event[n+1] = true;
%% start of most recently started note (not necessarily still playing)
array[1..n] of var 0..max_end_time: recentStartTime; 
% array[1..n] of var 0..max_end_time: event_startTime; % same as recentStartTime -- until I introduced rests
%% TODO: revise domain
% accumulator for duration: value before new_event=true correct event_duration
array[1..n] of var 1..20: event_duration_accum; 
array[1..n] of var 1..20: event_duration; % needed ?
% array[1..n] of var 48..72: event_pitch; % MIDI note numbers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

constraint slice_start[1] = 0;
constraint forall(i in 1..n-1)( 
  slice_start[i] + slice_duration[i] = slice_start[i+1] 
);
% TODO: recentStartTime cannot express yet whether never any event started yet (i.e., whether score started with rest)
%% recentStartTime
constraint forall(i in 2..n)( 
  ( not new_event[i] ) ->  (recentStartTime[i] = recentStartTime[i-1])
);
constraint forall(i in 1..n)( 
   new_event[i] -> (recentStartTime[i] = slice_start[i] )
);
% TMP -- aux until I introduced rests
constraint new_event[1] = true;
% constraint increasing(slice_start);
% constraint increasing(event_startTime);

% event_duration_accum
constraint forall(i in 1..n)( 
  new_event[i] -> ( event_duration_accum[i] = slice_duration[i] ) 
);
constraint forall(i in 2..n)( 
 not new_event[i] -> ( event_duration_accum[i] = event_duration_accum[i-1] + slice_duration[i] )
);
% event_duration
% TODO: buggy for last slice
constraint forall(i in 1..n-1)( 
  new_event[i+1] -> ( event_duration[i] = event_duration_accum[i] ) 
);
constraint forall(i in 1..n-1)( 
 not new_event[i+1] -> ( event_duration[i] = event_duration[i+1] )
);

% constraint forall(i in 1..n)(new_event[i] ->  )

% event_duration = slice_durations between two true new_events 
% constraint forall(i in 1..n)(new_event[i] ->  )

% constraint recentStartTime[1] = 0;
% constraint forall(i in 1..n)(new_event[i] ->  )
% constraint event_startTime[1] < event_startTime[2]; % dummy test
% constraint forall(i in 1..n-1, j in 2..n)( event_startTime[i] = event_startTime[j] );
% constraint alldifferent(event_startTime);


solve :: seq_search([
    int_search(slice_duration, first_fail, indomain_random, complete), 
    bool_search(new_event, first_fail, indomain_random, complete) ]) 
  satisfy;

output [ 
  "slice_duration: " ++ show(slice_duration) ++ "\n" 
  ++ "slice_start: " ++ show(slice_start) ++ "\n" 
  ++ "new_event: " ++ show(new_event) ++ "\n"
  ++ "recentStartTime: " ++ show(recentStartTime) ++ "\n"
%  ++ "event_startTime: " ++ show(event_startTime) ++ "\n" 
  ++ "event_duration_accum: " ++ show(event_duration_accum) ++ "\n"
  ++ "event_duration: " ++ show(event_duration) ++ "\n"
];