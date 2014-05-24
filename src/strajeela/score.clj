;;; File defines the music repesentation

;; See also the Overtone pitch representation
;; https://github.com/overtone/overtone/blob/cfd5ea71c67401bbda0b619a6f49268d01adc06c/src/overtone/music/pitch.clj

(ns strajeela.score
  ;; (:gen-class)
  )


;; Expect a partial score definition and returns a full score with all details. 
;; Similar in principle to translation of partial score into full score in Strasheela, but full score is 
;; - Not nested objects, but instead Clojure sequences, sets etc (but for which a custom interface is defined)
;; - A "2D-representation", similar to **kern of humdrum, where the outest layer is a Clojure sequence (?), that contains the **kern "spines" for each **kern "record" (slice) in time
;; In a CSP, all decision variables are represented by integers or sets of integers (or possibly floats), but in the partial score and perhaps even the full score, certain values (e.g., the pitch class) can be represented by synbols instead for convenience. 
;; TODO: def 
(defn full-score 
  "doc-string"
  [arg-list]
  )

(comment
  
;; TODO: 
(defn export-kern 
  "Expert to similar kern format, and from there export in various other formats possible"
  [arg-list]
  )


;; TODO:
;; This is challenging, as there are various extensions of kern available... 
;; Perhaps I should simply define an extra function for every extra Humdrum score format (need then to extract the relevant info from that file), and multiple representations from the same file/score can then be combined with an equivalent of mat-trans (to get a sequence of "records"). That would clarify which formats are supported, and parsing those formats can then be fully implemented. 
;; When important, do I want to store also comments soemhow? Technically certainly possible, e.g., with an extra comment key for the respective map (see http://musiccog.ohio-state.edu/Humdrum/representations/kern.html#Comments)
(defn import-kern 
  "Parse kern file and read content into full score definition."
  [arg-list]
  )

  )
