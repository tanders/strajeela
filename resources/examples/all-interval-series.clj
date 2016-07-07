(ns clojure2minizinc.tutorial
  (:require [clojure2minizinc.core :as mz]  ; loading clojure2minizinc.core 
            ))

;; Strasheela code, http://strasheela.sourceforge.net/strasheela/doc/Example-AllIntervalSeries.html
(comment
  
proc {AllIntervalSeries L ?Dxs ?Xs}
   Xs = {FD.list L 0#L-1}              % Xs is list of L FD integers in {0, ..., L-1}
   Dxs = {FD.list L-1 1#L-1}
   %% Loop constrains intervals: inversionalEquivalentInterval(X_i, X_i+1, Dx_i)
   for I in 1..L-1
   do
       X1 = {Nth Xs I}
       X2 = {Nth Xs I+1}
       Dx = {Nth Dxs I}
    in
       {InversionalEquivalentInterval X1 X2 Dx}
   end
   {FD.distinctD Xs}                   % no PC repetition
   {FD.distinctD Dxs}                  % no interval repetition
   %% add knowledge from the literature: first series note is 0 and last is L/2
   Xs.1 = 0
   {List.last Xs} = L div 2
   %% Search strategy: first fail distribution
   {FD.distribute ff Xs}
end

proc {InversionalEquivalentInterval Pitch1 Pitch2 Interval}
   Aux = {FD.decl}                       % create an auxiliary variable
in
   %% adding 12 has no effect for mod 12, but the FD int Aux must be positive
   Aux =: Pitch2-Pitch1+12
   {FD.modI Aux 12 Interval}
end
  )

(comment
  (mz/minizinc 
   (mz/clj2mnz
    (let [a (mz/variable (mz/-- -1 1)) 
          b (mz/variable (mz/-- -1 1))]
      (mz/constraint (mz/!= a b))
      (mz/solve :satisfy)
      (mz/output-map {:a a :b b})
      ;; (pprint/pprint *mzn-store*)
      ))
   ;; :print-mzn? true
   ;; :num-solutions 3
   ;; :all-solutions? true
   )
  )
