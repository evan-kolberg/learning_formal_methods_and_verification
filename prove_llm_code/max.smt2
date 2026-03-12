; this smt-lib script is about prooving wheter or not an
; llm-written function called 'max' is defensible

; here is the function below:

;	int max2(int a, int b) {
;    	if (a >= b) return a;
;    	else return b;
;	}


; this tells the solver what kind of math it should expect
; LIA stands for Linear Integer Arithmetic
(set-logic LIA)


; this introduces 'a' as some arbitrary integer
; essentially saying "let 'a' be any integer input"
(declare-const a Int)

; same for b
(declare-const b Int)

; declare r as well, the return value
(declare-const r Int)

; this here is the heart of the encoding:
; assert tells the solver that the condition must be true
; '(>= a b)' is the condition from the if, a >= b
; ite means if-then-else
; general form: (ite condition then_branch else_branch)
; this is logically equivalent to (a >= b) ? a : b
; and '(= r (ite...))' sets r equal to that if-then-else value
(assert
	(= r 
		(ite
			(>= a b)
			 a
			 b
			 )
		)
	)


; this tries to find a bug within the function (i.e., not a valid function)
(assert
  (or
    (< r a)
    (< r b)
    (and (not (= r a)) (not (= r b)))))

; checks satisfiability
(check-sat)








