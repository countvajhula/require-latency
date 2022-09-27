#!/usr/bin/env racket
#lang cli

(provide time-module-ms)

(require racket/port
         racket/format
         racket/string
         racket/match)

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
  (~a "(let () (define-values (_0 _1 ms _2) "
      "(time-apply (lambda () (dynamic-require "
      "'"
      module-name
      " 0)) null)) ms)"))

(define (time-command-relative module-name)
  (~a "(let () (define-values (_0 _1 ms _2) "
      "(time-apply (lambda () (dynamic-require "
      "\""
      module-name
      "\""
      " 0)) null)) ms)"))

(define (require-command-absolute module-name)
  (~a "(dynamic-require "
      "'"
      module-name
      " 0)"))

(define (require-command-relative module-name)
  (~a "(dynamic-require "
      "\""
      module-name
      "\""
      " 0)"))

(define (time-module-ms module-name)
  (define-values (sp out in err)
    (apply subprocess
           `(#f
             #f
             #f
             ,(find-executable-path "racket")
             ,@(apply append
                      (for/list ([m (modulus)])
                        (list "-l" m)))
             "-e"
             ,((if (file)
                   time-command-relative
                   time-command-absolute)
               module-name))))
  (define ms (string->number (string-trim (port->string out))))
  (define error (port->string err))
  (close-input-port out)
  (close-output-port in)
  (close-input-port err)
  (subprocess-wait sp)
  (if ms
      (cons 'result ms)
      (cons 'error error)))

(define (capture-modules-loaded module-name)
  (define-values (sp out in err)
    (apply subprocess
           `(#f
             #f
             #f
             ,(find-executable-path "racket")
             ,@(apply append
                      (for/list ([m (modulus)])
                        (list "-l" m)))
             "-e"
             ,(~a
               "(let ([old (current-load/use-compiled)])"
               "(current-load/use-compiled"
               "(lambda (p n)"
               "(displayln p)"
               "(old p n))))")
             "-e"
             ,(~a "(require " module-name ")")
             ,((if (file)
                   require-command-relative
                   require-command-absolute)
               module-name))))
  (define result (string-trim (port->string out)))
  (define error (port->string err))
  (close-input-port out)
  (close-output-port in)
  (close-input-port err)
  (subprocess-wait sp)
  (if result
      (cons 'result result)
      (cons 'error error)))

(flag (file)
  ("-f" "--file" "Treat the input as a relative path to a file instead of an installed module in a collection.")
  (file #t))

(flag (modulus #:param [modulus (list "racket/base")] module)
  ("-m" "--modulo" "Specify modules to be loaded as the starting point against which latency will be measured.")
  (modulus (cons module (modulus))))

(constraint (multi modulus))

(program (require-latency [module-name "module path"])
  (match-let ([(cons tag result) (time-module-ms module-name)])
    (if (eq? 'error tag)
        (fprintf (current-error-port)
                 (~a "There was an error loading the module:\n"
                     result))
        (printf (~a result " ms\n")))))

(program (modules-loaded [module-name "module path"])
  (match-let ([(cons tag result) (capture-modules-loaded module-name)])
    (if (eq? 'error tag)
        (fprintf (current-error-port)
                 (~a "There was an error loading the module:\n"
                     result))
        (printf (~a result "\n")))))

(module+ require-latency
  (run require-latency))

(module+ modules-loaded
  (run modules-loaded))
