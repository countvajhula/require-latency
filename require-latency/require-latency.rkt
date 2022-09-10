#!/usr/bin/env racket
#lang cli

(provide time-racket
         time-module-ms)

(require racket/port
         racket/format)

#|
This works by:
1. Running `racket -l <module_name>` and `racket -l racket/base` independently
2. Subtracting the latter from the former.
3. Printing that result in milliseconds.

where <module_name> is the argument you specified at the command line,
e.g. ./require-latency.rkt racket/list

The idea is to subtract out the contribution from racket/base, so that
what remains is just the time contributed by requiring the specified module.

Methodology based on discussion with Grzegorz Szansa, Sam Tobin-Hochstadt,
and others.
|#

(define (time-racket [module-name "racket/base"])
  (define-values (sp out in err)
    (subprocess #f #f #f (find-executable-path "time") "-p" (find-executable-path "racket") "-l" module-name))
  (define result (port->string err))
  (define seconds (string->number
                   (car
                    (regexp-match #px"[\\d|\\.]+"
                                  (car
                                   (regexp-match #rx"(?m:^real.*)"
                                                 result))))))
  (close-input-port out)
  (close-output-port in)
  (close-input-port err)
  (subprocess-wait sp)
  seconds)

(define (time-module-ms module-name)
  (* 1000
     (- (time-racket module-name)
        (time-racket))))

(program (require-latency [module-name "module name"])
  (displayln (~a (time-module-ms module-name) " ms")))

(module+ main
  (run require-latency))
