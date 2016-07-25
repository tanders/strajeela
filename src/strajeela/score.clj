;;; File defines the music repesentation

(ns strajeela.score
  (:require [clojure2minizinc.core :as mz]))

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
