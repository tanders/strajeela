;;; File defines the music repesentation

(ns strajeela.score
  (:require [clojure2minizinc.core :as mz]))

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

(mz/include "globals.mzn")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; TODO: Predicate definitions
;;;

;; !! TODO: perhaps I better define MiniZinc predicates, which add type information
(comment
  ;; Constrains the elements of array 'y' to be all different except those
  ;; elements that are assigned to 'x'.
  ;; source: modification of MiniZinc's alldifferent_except_0.mzn
  ;; unused after all
  (mz/def-submodel alldifferent_except_x
    [x y]
    (mz/forall [i (mz/index_set y)
                j (mz/index_set y)
                :where (mz/!= i j)]
      (mz/-> (mz/and (mz/!= (mz/nth y i) x)
                     (mz/!= (mz/nth y j) x))
             (mz/!= (mz/nth y i) (mz/nth y j)))))
  
  (print (alldifferent_except_x 0 event_duration))

  )

(comment 

  (mz/aggregate
   )

  (mz/aggregate [i (mz/-- 1 3)] 
    (mz/* i i))
  ;; means [1*1, 2*2, 3*3]  (in MiniZinc syntax)


  (def a (mz/array (mz/-- 1 3) :int))
  (mz/aggregate [i (mz/-- 1 3)
                 j (mz/-- 1 3) 
                 :where (mz/< i j)]
    (mz/!= (mz/nth a i) (mz/nth a j)))  
  ;; means [a[1] != a[2], a[2] != a[3]] (in MiniZinc syntax)


  )



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Variables
;;; !! First declared without let etc for testing !!  Refactor later with let or similar 
;;;

;; 
;; General variables 
;;

;; ? Number of time slices? Can be CSP arg.
(def n (mz/int 'n 20))

;; Can be CSP arg.
;; Could be defined with ratios in Clojure and automatically translated into integers for CSP by setting the int that represents a 1/4 note, similar to Strasheela
(def slice_duration_domain #{1}) 
(def slice_duration (mz/array (mz/-- 1 n) [:var slice_duration_domain]
                              'slice_duration))
(def max_slice_dur (mz/int 'max_slice_dur (apply max slice_duration_domain)))
(def max_end_time (mz/int 'max_end_time (mz/* n max_slice_dur)))
(def slice_start (mz/array (mz/-- 1 n) [:var (mz/-- 1 max_end_time)]
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
(def new_event (mz/array (mz/-- 1 n) [:var :bool]
                         (partify 'new_event part_number)))
(def new_event_fd (mz/array (mz/-- 1 n) [:var (mz/-- 0 1)]
                            (partify 'new_event_fd part_number)))
;; set of indices where events start
(def event_index_set (mz/variable [:set (mz/-- 1 n)]
                                  (partify 'event_index_set part_number)))
;; event start indices without intermediate elements (e.g., consecutive indices are always pointing to different events)
;; !! n+1 to mark indices beyond the range
(def event_index (mz/array (mz/-- 1 n) [:var (mz/-- 1 (mz/+ n 1))]
                           (partify 'event_index part_number)))
;; start of most recently started note (not necessarily still playing)
(def recentStartTime (mz/array (mz/-- 1 n) [:var (mz/-- 0 max_end_time)]
                               (partify 'recentStartTime part_number)))
;; accumulator for duration: value before new_event=true correct event_duration
;; !! TODO: can duration be 0, e.g., for grace notes?
(def event_duration_accum (mz/array (mz/-- 1 n) [:var (mz/-- 1 max_end_time)]
                               (partify 'event_duration_accum part_number)))
(def event_duration (mz/array (mz/-- 1 n) [:var (mz/-- 1 max_end_time)]
                              (partify 'event_duration part_number)))
;; MIDI note numbers or later other pitch units
;; Test: restrict pitch domain directly to diatonic scale
(def pitch_domain #{48, 50, 52, 53, 55, 57, 59, 60, 62, 64, 65, 67, 69, 71, 72})
(def event_pitch (mz/array (mz/-- 1 n) [:var pitch_domain]
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



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Old sketches
;;;

(comment

  ;; !! !! TODO
  ;; - Flip data structure into a map of vectors (represented as arrays in MiniZinc)
  ;; - Additional vector/array with index of preceding note -- using element constraint on array this index gives access to previous note's parameters (including its predecessor's index)
  ;; - Think through -- will this approach also give access in MiniZinc to the sequence of all notes (e.g., their pitches) in a voice? 

  ;; TODO: what to do with bidirectional links
  
  ;; Music representation outline
  [ ;; vector or other collection is top-level (can be lazy in principle, but not for CSP)
    ;;
    ;; !! essential decision variables per time slice: :slice-duration, and then :new?, :rest?, and :pitch per simultaneous note
   {:slice-duration :<int-var> ;; dur of time slice -- TODO: only stored once per time slice?
    ;; all [items] at timeslice (corresponds to **kern record) wrapped in a map
    ;; each key in map corresponds to what is called an interpretation in **kern
    ;;
    ;; Each key must only be contained once in map, so I have vector of notes at key :note. But (usually), the number of notes in this vector should be the same for every time slice
    :note [
           ;; There could be multiple simultaneous notes per timeslice in spine, but such flexibility I cannot handle in CSP. So, at least for constraint problems I should limit this to 1 note. However, there can be any number of parallel spines, which can be rests at most times....
           ;; TODO: how to represent a note?
           ;; TODO: I need consisteny for predefined rules -- how to make sure some minimal set of params of notes and other "objects" is always there? Generating "objects" with functions? 
           {:kind :note ;; TODO: is this suitable type labelling mechanism? Also already implicit in key for surrounding map
            ;; TODO: Decide: If note is rest, new? value is indicates whether previous note belongs to this (i.e., whether it was a rest as well) to express overall duration. Do I need that?
            :new? :<bool-var>
            ;; Rest could be indicated with pitch value of -1 (or 0) to indicate the rest, but such special meaning complicates propagation (e.g., for underlying harmony I would always need to include that pitch). So, better have an extra decision variable for that.
            :rest? :<bool-var>
            ;; If :start-note is false, then this pitch must be the same as former part of note...
            ;; If note is rest, pitch value is meaningless and can be anything.
            :pitch :<int-var>  
            ;;
            ;; Optional: various derived values 
            ;; TODO: Decide: In Strasheela various derived values where always added, and user had to explicitly control which note subclass to use. Could I instead let constraints add such derived variables as needed? Need to be very careful with reusing and some standardisation of such variables...
            :start-time :<int-var>
            :duration :<int-var> ;; Sum of all time slice-durations of note
            :end-time :<int-var> ;; ??
            :pitch-class :<int-var>
            ;; ... 
            }
           {} 
           ;; ... 
           ]
    ;;
    ;; any further information can be stored
    :meter { ;; TODO:
            }
    :harmony { ;; TODO:
              }
    ;; TODO: where to put info?
    ;; Vector of arbitrary additional information (tandem interpretations in **kern) per spine
    :info []
    }
   ]

  )


(comment


  
;; Expect a partial score definition and returns a full score with all details. 
;; Similar in principle to translation of partial score into full score in Strasheela, but full score is 
;; - Not nested objects, but instead Clojure sequences, sets etc (but for which a custom interface is defined)
;; - A "2D-representation", similar to **kern of humdrum, where the outest layer is a Clojure sequence (?), that contains the **kern "spines" for each **kern "record" (slice) in time
;; In a CSP, all decision variables are represented by integers or sets of integers (or possibly floats), but in the partial score and perhaps even the full score, certain values (e.g., the pitch class) can be represented by synbols instead for convenience. 
;; TODO: def 
(defn full-score 
  "TODO: def and doc-string"
  [arg-list]
  )
  
;; TODO: 
(defn export-kern 
  "Expert to similar kern format, and from there export in various other formats possible"
  [arg-list]
  )


;; TODO:
;; ? Define using a parser generator? Doc how to use ANTLR via Clojure, see http://briancarper.net/blog/554/antlr-via-clojure
;; Check out whether that is the best parser generator for clojure...
;; Perhaps for 2D representation **kern I need something different -- first split representation into spines...
;; This is challenging, as there are various extensions of kern available... 
;; Perhaps I should simply define an extra function for every extra Humdrum score format (need then to extract the relevant info from that file), and multiple representations from the same file/score can then be combined with an equivalent of mat-trans (to get a sequence of "records"). That would clarify which formats are supported, and parsing those formats can then be fully implemented. 
;; When important, do I want to store also comments soemhow? Technically certainly possible, e.g., with an extra comment key for the respective map (see http://musiccog.ohio-state.edu/Humdrum/representations/kern.html#Comments)
(defn import-kern 
  "Parse kern file and read content into full score definition."
  [arg-list]
  )

  )
