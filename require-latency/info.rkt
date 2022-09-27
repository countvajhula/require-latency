#lang info

(define version "0.0")
(define collection "pkg")
(define deps '("base"
               "cli"))
(define raco-commands
  '(("require-latency" (submod pkg/require-latency require-latency) "measure module import time (factoring out racket/base)" #f)
    ("modules-loaded" (submod pkg/require-latency modules-loaded) "show all modules loaded by the given module" #f)))
