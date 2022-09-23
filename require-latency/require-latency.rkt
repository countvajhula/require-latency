#!/usr/bin/env racket
#lang cli

(provide time-module-ms)

(require racket/port
         racket/format
         racket/string)

#|
This uses the following method to estimate the require latency:
  racket -l racket/base -e "(time (dynamic-require <module_name> 0))"

where <module_name> is the argument you specified at the command line,
e.g. ./require-latency.rkt racket/list

The idea is to subtract out the contribution from racket/base, so that
what remains is just the time contributed by requiring the specified module.

Methodology based on discussion with Grzegorz Szansa, Sam Tobin-Hochstadt,
Michael Ballantyne, and others.
|#

(define (time-command-absolute module-name)
  (~a "(let () (define-values (_0 _1 ms _2) " "(time-apply (lambda () (dynamic-require " "'" module-name " 0)) null)) ms)"))

(define (time-command-relative module-name)
  (~a "(let () (define-values (_0 _1 ms _2) " "(time-apply (lambda () (dynamic-require " "\"" module-name "\"" " 0)) null)) ms)"))

(define (time-module-ms module-name)
  (define-values (sp out in err)
    (subprocess #f
                #f
                #f
                (find-executable-path "racket")
                "-l"
                "racket/base"
                "-e"
                ((if (file)
                     time-command-relative
                     time-command-absolute)
                 module-name)))
  (define ms (string->number (string-trim (port->string out))))
  (close-input-port out)
  (close-output-port in)
  (close-input-port err)
  (subprocess-wait sp)
  ms)

(flag (file)
  ("-f" "--file" "Treat the input as a relative path to a file instead of an installed module in a collection.")
  (file #t))

(program (require-latency [module-name "module path"])
  (let ([result (time-module-ms module-name)])
    (if result
        (printf (~a result " ms\n"))
        (fprintf (current-error-port) "Module not found!\n"))))

(module+ main
  (run require-latency))
