;; ./guile-3.0 12-03.scm

(use-modules (gnutls)
             (ice-9 receive)
             (ice-9 regex)
	     (srfi srfi-1)
             (web client))

;; again, need the cookie set to get your input
(define (get-input)
  (receive (response-header response-body)
      (http-get "https://adventofcode.com/2024/day/3/input"
		#:headers `((Cookie . ,(getenv "AOC_COOKIE"))))
    response-body))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; part 1 specific ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (parse-input-p1 input)
  (map (lambda (y) (map string->number y))
       (map (lambda (x) (map match:substring (list-matches "[0-9]+" x)))
	    (map match:substring (list-matches "mul\\([0-9]+,[0-9]+\\)" input)))))

(define (process-input-p1 parsed-input)
  (fold + 0
       (map (lambda (x) (fold * 1 x)) parsed-input)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; part 2 specific ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (parse-input-p2 input)
  (map match:substring
       (list-matches "mul\\([0-9]+,[0-9]+\\)|do\\(\\)|don't\\(\\)" input)))

;; I'm sure there's a better way some weird take-while or something, but
;;    I couldn't figure it out, so just creating a recusive function that passes
;;    state as it iterates

(define (process-row-p2 row isDo)
  (cond
   ((not isDo) 0)
   ((string=? row "do()") 0)
   ((string=? row "don't()") 0)
   (#t (fold * 1
	     (map (lambda (y) (string->number y))
		  (map match:substring (list-matches "[0-9]+" row)))))))

(define (process-input-p2 i lst isDo acc)
  (cond
   ((null? lst) (+ (process-row-p2 i isDo) acc))
   ((string=? i "do()") (process-input-p2 (car lst) (cdr lst) #t acc))
   ((string=? i "don't()") (process-input-p2 (car lst) (cdr lst) #f acc))
   (#t (process-input-p2 (car lst) (cdr lst) isDo (+ (process-row-p2 i isDo) acc)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; output ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(display (string-append "part1 : "
 			(number->string (process-input-p1
 					 (parse-input-p1 (get-input))))
			"\n"))

(display (string-append "part2 : "
			(let ((input (parse-input-p2 (get-input))))
			  (number->string (process-input-p2 (car input) (cdr input) #t 0)))
			"\n"))
