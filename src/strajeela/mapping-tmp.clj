
;; NOTE: Clojure has already code walking built-in, e.g., http://clojuredocs.org/clojure.walk/walk
;; Possible problem: not tail recursive
(defn map-pairwise 
  "Collects the result of applying the binary function f on all pairwise combinations of xs, i.e. [(f xs1 xs2) .. (f xs1 xsN) (f xs2 xs3) .. (f xsN-1 xsN)]"
  [xs f]
  (if (empty? xs) 
    nil
    (let [xs-rest (rest xs)]
      (core/concat (map #(f (first xs) %) xs-rest)
                   (map-pairwise xs-rest f)))))

(comment
  (map-pairwise [1 2] list)
  (map-pairwise [1 2 3 4] list)
  )
