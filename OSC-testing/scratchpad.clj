(ns strajeela.osc-test
  (:use overtone.osc)
  )

;; Test OSC interface with Max patch in this directory.
;; https://github.com/overtone/osc-clj

;; start a server and create a client to talk with it
(def server (osc-server 7401))
(def client (osc-client "localhost" 7400))

;; Register a handler function for the /test OSC address
;; The handler takes a message map with the following keys:
;;   [:src-host, :src-port, :path, :type-tag, :args]
(osc-handle server "/test" (fn [msg] (println "MSG: " msg)))

(osc-listen server (fn [msg] (println "Listener: " msg)) :debug)

;; With debugging the sent messages are shown, but no message is ever received
;; (osc-debug true)

;; Prints at REPL and returns nil
;; (println "MSG: " "this is a test")

;; NOTE: Max receives UDP message at specified port, but integers must be explicitly converted into Java Integers to work for Max.
;; https://groups.google.com/forum/#!searchin/overtone/OSC/overtone/AU-mGoHv_2o/DSif7xU2H-wJ
;; https://groups.google.com/forum/#!searchin/overtone/OSC/overtone/Ely212uD708/7Ft8URjcMeAJ
(osc-send client "/test" (Integer. 1234567890))

;; send it some messages
(doseq [val (range 10)]
 (osc-send client "/test" "i" (Integer. val)))

;; (Thread/sleep 1000)

;; remove handler
(osc-rm-handler server "/test")

;; stop listening and deallocate resources
(osc-close client)
(osc-close server)




;;;;;;;;;;;;;;;;;;;;



