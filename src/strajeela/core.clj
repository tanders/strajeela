(ns strajeela.core
  (:gen-class))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (println "Hello, World!"))

(defn plus1
  "This is just some stupid test :)"
  [x]
  (+ 1  x))

(plus1 3/2)

(def test '(1 2 3 4))
