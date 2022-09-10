#lang info

(define version "0.0")
(define collection "pkg")
(define deps '("base"
               "cli"))
(define raco-commands
  '(("require-latency" (submod pkg/require-latency main) "measure module import time (factoring out racket/base)" #f)))
