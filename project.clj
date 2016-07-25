(defproject strajeela "0.0.1-SNAPSHOT"
  :description "This software is intended to be a successor of Strasheela at some stage -- for the original see http://strasheela.sourceforge.net/"
  ;; :url "http://example.com/FIXME"
  :license {:name "GNU General Public License"
            :url "https://gnu.org/licenses/gpl.html"}
  :dependencies [[org.clojure/clojure "1.9.0-alpha10"]
                 ;; [org.clojure/clojure "1.8.0"]
                 [minizinc/clojure2minizinc "0.2.1-SNAPSHOT"]
                 ;; an alternative class-based object-system for Clojure based on hash-maps and multimethods
                 ;; Doc: https://github.com/eduardoejp/fenrir, http://eduardoejp.github.io/fenrir/fenrir-api.html
                 ;; [fenrir "0.1.0"]
                 [org.clojure/math.numeric-tower "0.0.4"]
                 ;; OSC library, https://github.com/overtone/osc-clj                 
                 [overtone/osc-clj "0.9.0"]
                 ]
  :codox {:metadata {:doc "TODO: write docs"
                     :doc/format :markdown}
          :output-path "doc/reference"
          ;; TODO: update URI for soures 
          :source-uri "https://github.com/tanders/strajeela/tree/master"
          :src-linenum-anchor-prefix "L"}
  ;; :main ^:skip-aot strajeela.core
  ;; :target-path "target/%s"
  ;; :profiles {:uberjar {:aot :all}}
  )


