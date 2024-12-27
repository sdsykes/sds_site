; clojure ETA interpreter
; S Sykes 2011
;
; project.clj
; (defproject eta "1.0.0"
;  :description "Clojure ETA interpreter"
;  :dependencies [[org.clojure/clojure "1.2.1"] [org.clojure/clojure-contrib "1.2.0"]]
;  :main eta.core)

(ns eta.core
  (:gen-class)
  (:import (java.io BufferedReader FileReader))
  (:use [clojure.contrib.io :only (reader)]))

(def rdr (reader *in*))

(defn stack-new [] (vector-of :int))
(defn stack-push [s e] (conj s (int e)))
(defn stack-top [s] (get s (dec (count s))))
(defn stack-pop [s] (if (empty? s) s (pop s)))
(defn stack-empty? [s] (empty? s))
(defn halibut [s n] 
  (if (<= n 0)
    (conj s (get s (+ (count s) (dec n))))
    (vec
      (concat
          (subvec s 0 (- (count s) (inc n)))
          (subvec s (- (count s) n))
          (list (get s (- (count s) (inc n))))))))

(defn state-new [code]
  (let [code-list (re-seq #".*\r?\n" code)]
  {:lineno 1
  :charno 0
  :stack (stack-new) 
  :num false
  :code code-list
  :linecount (count code-list)
  :cur-num 0
  }))

(defn state-stack [s] (:stack s))
(defn state-lineno [s] (:lineno s))
(defn state-charno [s] (:charno s))
(defn state-num [s] (:num s))
(defn state-input [s] (:input s))
(defn state-code [s] (:code s))
(defn state-linecount [s] (:linecount s))
(defn state-cur-num [s] (:cur-num s))

(defn setval [orig newval] newval)
(defn state-set-charno [s n] (update-in s [:charno] setval n))
(defn state-set-lineno [s n] (-> s
    (update-in [:lineno] setval n)
    (update-in [:charno] setval -1)))
    
(defn state-set-num [s n] (update-in s [:num] setval n))
(defn state-set-cur-num [s n] (update-in s [:cur-num] setval n))
(defn state-set-stack [s n] (update-in s [:stack] setval n))
(defn state-add-to-cur-num [s n] (state-set-cur-num s (+ (* 7 (state-cur-num s)) n)))

(defn inc-lineno [s] (let [state (state-set-lineno s (inc (state-lineno s)))]
    (if (> (state-lineno state) (count (state-code state)))
      (state-set-lineno state 0) state)))

(defn inc-charno [s] (let [
  state (update-in s [:charno] inc)
  cur-line (nth (state-code state) (dec (state-lineno state)))
  ]
  (if (>= (state-charno state) (count cur-line)) 
    (-> state 
      (inc-lineno) 
      (state-set-charno 0)) state)))


(defn execute [state chr]
  (let [top (stack-top (state-stack state)) top2 (stack-top (stack-pop (state-stack state))) stack (state-stack state)]
    (if (state-num state)
      (case chr
        (\h \H) (state-add-to-cur-num state 0)
        (\t \T) (state-add-to-cur-num state 1)
        (\a \A) (state-add-to-cur-num state 2)
        (\o \O) (state-add-to-cur-num state 3)
        (\i \I) (state-add-to-cur-num state 4)
        (\n \N) (state-add-to-cur-num state 5)
        (\s \S) (state-add-to-cur-num state 6)
        (\e \E) (do 
          (-> state
            (state-set-stack (stack-push stack (state-cur-num state)))
            (state-set-num false)
            (state-set-cur-num 0)))
        state)
      (case chr
        (\o \O) (do
                  (when top (print (char top)))
                  (state-set-stack state (stack-pop stack)))
        (\a \A) (state-set-stack state (stack-push stack (inc (state-lineno state))))
        (\n \N) (state-set-num state true)
        (\i \I) (do 
                    (flush)
                    (state-set-stack state (stack-push stack (.read rdr))))
        (\h \H) (state-set-stack state (halibut (stack-pop stack) top))
        (\e \E) (state-set-stack state 
                  (stack-push
                    (stack-push (stack-pop (stack-pop stack)) (/ top2 top))
                    (rem top2 top)))
        (\s \S) (state-set-stack state (stack-push (stack-pop (stack-pop stack)) (- top2 top)))
        (\t \T) (if (not= 0 top2)
                  (-> state
                      (state-set-lineno top)
                      (state-set-stack (stack-pop (stack-pop stack))))
                  (state-set-stack state (stack-pop (stack-pop stack))))
        state))))

(defn process-file [file-name]
  (loop [state (state-new (slurp file-name))]
    (let [line (nth (state-code state) (dec (state-lineno state)))
          new-state (execute state (nth line (state-charno state)))
          lineno (state-lineno new-state)]
      (if (and (> lineno 0) (< lineno (state-linecount new-state))) (recur (inc-charno new-state))))))

(defn -main [& args]
  (do
    (process-file (first args))
    (flush)))
