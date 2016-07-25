(ns strajeela.score-test
  (:require [clojure2minizinc.core :as m]
            [strajeela.score :as s]))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; First step: direct translation of 2-part counterpoint example at
;; strajeela/MiniZinc-sketching/MusicRepresentation/SimpleCounterpoint-twoVoices.mzn
;; Later I refactor this, so that
;; - The score definition is defined by a single function -- which users can overwrite to change the default score creation
;; - A single abstraction creates an arbitrary number of parts
;; - The Clojure data is stored in some data structure for rel. convenient constraint application -- lets see how that works


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Include statements
;;;

(m/include "globals.mzn")

 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Variables
;;; !! First declared without let etc for testing !!  Refactor later with let or similar 
;;;

;; 
;; General variables 1
;;


;; ? Number of time slices? Can be CSP arg.
(def n (m/int 'n 20))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; General predicate definitions
;;;

;; unused after all
(m/predicate alldifferent_except_x
  "Constrains the elements of array `y` to be all different except those
  elements that are assigned to `x`.
  source: modification of MiniZinc's `alldifferent_except_0.mzn`"
  [x [:var :int]
   y [:array :int [:var :int]]]    
  (m/forall [i (m/index_set y)
             j (m/index_set y)
             :where (m/!= i j)]
    (m/-> (m/and (m/!= (m/nth y i) x)
                 (m/!= (m/nth y j) x))
          (m/!= (m/nth y i) (m/nth y j)))))


(comment

  ;; Test predicate alldifferent_except_x

  ;; Ideally I would create test data automatically, but that can be difficult to define
  ;; (and it must not use constraint def, as bug in constraint def would also occur in test).
  (m/validate-predicate alldifferent_except_x 0 [5 4 3 2 1 6 9 0 0 0]) ;; OK
  (m/validate-predicate alldifferent_except_x 0 [5 4 3 2 1 9 9 0 0 0]) ;; error, because 9 occurs twice

  
  (m/minizinc
   (m/clj2mnz
    (let [x (m/int 'x 9)
          my-array (m/array (m/-- 1 10) [:var (m/-- 0 10)] 'myarray)]      ;   [5 4 3 2 1 0 0 9 9 9]
      (m/constraint (alldifferent_except_x x my-array))
      (m/solve :satisfy)
      (m/output-map {:my-array my-array})))
   ;; :options ["--seed" "1"] ; ["-n" "2"]
   ;; :print-mzn? true
   ;; :print-solution? true
   )
  
  )


;; TODO: Debug and check 
;; !! uses global n
;; !! predefined function set2array already exists in MiniZinc -- but does that work for variables as well?
(m/predicate set2array
  "Convert a set `S` to an array `x[1..n]`. Set elements are in increasing
   order in the array, and set elements must be in `1..n`. If the array is 
   longer than there are set elements, then the end of the array is padded 
   with `n+1`."
  [S [:var :set :int]
   x [:array :int [:var :int]]]
  (m/local [(exceeding :int (m/+ n 1))]
    (m/and
     ;; main constraint
     (m/forall [dom_val (m/-- (m/lb_array x) (m/ub_array x))]
       ;; TODO:        
       (m/<-> (m/exists (m/or (m/= exceeding exceeding)
                                 (m/= (m/nth x i) dom_val)))
               (m/in dom_val (m/union S #{exceeding}))))
     ;; greatly improves propagation
     (m/increasing x)
     (m/forall [i (m/-- 1 (m/- n 1))]
       (m/-> (m/>= (m/card S) i)
              (m/< (m/nth x i) (m/nth x (m/+ i 1)))))
     )))

(comment

  

  )


;; TODO: Debug and check 
;; !! uses global n
(m/predicate slice_constraints
  "Constraints for time slice arrays shared by all voices"
  [slice_start [:array :int [:var :int]]
   slice_duration [:array :int [:var :int]]]
  (m/and
   ;; TODO: check: is slice_start 0 or 1-based?
   (m/= (m/nth slice_start 1) 0)
   (m/forall [i (m/-- 1 (m/- n 1))]
     (m/= (m/+ (m/nth slice_start i) (m/nth slice_duration i))
           (m/nth slice_start (m/+ i 1))))
   ))


;; TODO: Debug and check 
;; !! TODO: recentStartTime cannot express yet whether never any event started yet (i.e., whether score started with rest)
;; !! uses global n
(m/predicate recentStartTime_constraints
  [new_event [:array :int [:var :bool]]
   slice_start [:array :int [:var :int]]
   recentStartTime [:array :int [:var :int]]]
  (m/and
   (m/forall [i (m/-- 1 n)]
     (m/and (m/<-> (m/nth new_event i)
                   (m/= (m/nth recentStartTime i) (m/nth slice_start i)))
            ;; redundant constraint for propagation 
            (m/<= (m/nth recentStartTime i) (m/nth slice_start i))))
   (m/forall [i (m/-- 2 n)]
      (m/and
       (m/<-> (m/not (m/nth new_event i))
              (m/= (m/nth recentStartTime i) (m/nth recentStartTime (m/- i 1))))
       ;; redundant constraint for propagation 
       (m/>= (m/nth recentStartTime i) (m/nth recentStartTime (m/- i 1)))))))


;; TODO: Debug and check 
;; !! uses global n
(m/predicate event_duration_constraints
  [new_event [:array :int [:var :bool]]
   slice_duration [:array :int [:var :int]]
   event_duration_accum [:array :int [:var :int]]
   event_duration [:array :int [:var :int]]]
  (m/and
   ;; event_duration_accum
   (m/forall [i (m/-- 1 n)]
     (m/<-> (m/nth new_event i)
            (m/= (m/nth event_duration_accum i)
                 (m/nth slice_duration i))))
   (m/forall [i (m/-- 2 n)]
     (m/and
      (m/<-> (m/not (m/nth new_event i))
             (m/= (m/nth event_duration_accum i)
                  (m/+ (m/nth event_duration_accum (m/- i 1)) (m/nth slice_duration i))))
      ;; redundant constraint for propagation
      ;; sub-expr also in expr above -- can I abstract?
      ;;;; (m/+ (m/nth event_duration_accum (m/- i 1)) (m/nth slice_duration i))
      (m/<= (m/nth event_duration_accum i)
            (m/+ (m/nth event_duration_accum (m/- i 1)) (m/nth slice_duration i)))))
   ;; event_duration
   (m/= (m/nth event_duration n) (m/nth event_duration_accum n)) ; last duration must be its accum  
   (m/forall [i (m/-- 1 (m/- n 1))]
     (m/and
      (m/<-> (m/nth new_event (m/+ i 1))
             (m/= (m/nth event_duration i)
                  (m/nth event_duration_accum i)))
      ;; ! no equivalence, only implication
      (m/-> (m/not (m/nth new_event (m/+ i 1))) 
            (m/= (m/nth event_duration i)
                 (m/nth event_duration (m/+ i 1))))
      ;; redundant constraint for propagation 
      (m/<= (m/nth event_duration i) (m/max (m/+ (m/nth event_duration_accum i) 1)
                                            (m/nth event_duration (m/+ i 1))))))
   (m/forall [i (m/-- 1 n)]
     ;; redundant constraint for propagation
     (m/>= (m/nth event_duration i) (m/nth event_duration_accum i)))))


;; TODO: Debug and check 
(m/predicate event_pitch_constraints
  [new_event [:array :int [:var :bool]]
   event_pitch [:array :int [:var :int]]]
  (m/forall [i (m/-- 2 n)]
    ;; ! no equivalence, only implication
    (m/-> (m/not (m/nth new_event i))
          (m/= (m/nth event_pitch i)
               (m/nth event_pitch (m/- i 1))))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; TODO: Example-specific predicate definitions
;;;











;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Variables
;;; !! First declared without let etc for testing !!  Refactor later with let or similar 
;;;

;; 
;; General variables 2
;;

;; Can be CSP arg.
;; Could be defined with ratios in Clojure and automatically translated into integers for CSP by setting the int that represents a 1/4 note, similar to Strasheela
(def slice_duration_domain #{1}) 
(def slice_duration (m/array (m/-- 1 n) [:var slice_duration_domain]
                              'slice_duration))
(def max_slice_dur (m/int 'max_slice_dur (apply max slice_duration_domain)))
(def max_end_time (m/int 'max_end_time (m/* n max_slice_dur)))
(def slice_start (m/array (m/-- 1 n) [:var (m/-- 1 max_end_time)]
                           'slice_start))
  

;; 
;; Part-specific variables -- for a single voice
;;

(defn partify
  "Generates a part-specific variable name by concatenating a general name and a part number"
  [var-name part-num]
  (clojure.string/join [var-name "_" part-num])
  ;; (symbol (clojure.string/join [var-name "_" part-num]))
  )

(def part_number 1)
;; marker where new note starts
;; new_event/new_event_fd: I need Boolean representation for many constraints, and integer representation for branching
(def new_event (m/array (m/-- 1 n) [:var :bool]
                         (partify 'new_event part_number)))
(def new_event_fd (m/array (m/-- 1 n) [:var (m/-- 0 1)]
                            (partify 'new_event_fd part_number)))
;; set of indices where events start
(def event_index_set (m/variable [:set (m/-- 1 n)]
                                  (partify 'event_index_set part_number)))
;; event start indices without intermediate elements (e.g., consecutive indices are always pointing to different events)
;; !! n+1 to mark indices beyond the range
(def event_index (m/array (m/-- 1 n) [:var (m/-- 1 (m/+ n 1))]
                           (partify 'event_index part_number)))
;; start of most recently started note (not necessarily still playing)
(def recentStartTime (m/array (m/-- 1 n) [:var (m/-- 0 max_end_time)]
                               (partify 'recentStartTime part_number)))
;; accumulator for duration: value before new_event=true correct event_duration
;; !! TODO: can duration be 0, e.g., for grace notes?
(def event_duration_accum (m/array (m/-- 1 n) [:var (m/-- 1 max_end_time)]
                               (partify 'event_duration_accum part_number)))
(def event_duration (m/array (m/-- 1 n) [:var (m/-- 1 max_end_time)]
                              (partify 'event_duration part_number)))
;; MIDI note numbers or later other pitch units
;; Test: restrict pitch domain directly to diatonic scale
(def pitch_domain #{48, 50, 52, 53, 55, 57, 59, 60, 62, 64, 65, 67, 69, 71, 72})
(def event_pitch (m/array (m/-- 1 n) [:var pitch_domain]
                           (partify 'event_pitch part_number)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; TODO: Constraints
;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; TODO: TMP: Example-specific (simple counterpoint) constraints
;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; TODO: TMP: tests
;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; TODO: Solve and output
;;;




