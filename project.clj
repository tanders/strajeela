(defproject strajeela "0.0.1-SNAPSHOT"
  :description "This software is intended to be a successor of Strasheela at some stage -- for the original see strasheela.sourceforge.net/"
  ;; :url "http://example.com/FIXME"
  :license {:name "GNU General Public License"
            :url "https://gnu.org/licenses/gpl.html"}
  :dependencies [[org.clojure/clojure "1.6.0"]
                 ;; an alternative class-based object-system for Clojure based on hash-maps and multimethods
                 ;; Doc: https://github.com/eduardoejp/fenrir, http://eduardoejp.github.io/fenrir/fenrir-api.html
                 ;; [fenrir "0.1.0"]
                 ]
  :main ^:skip-aot strajeela.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
