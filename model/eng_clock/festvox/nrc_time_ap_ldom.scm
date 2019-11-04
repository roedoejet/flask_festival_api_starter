;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                     ;;;
;;;                     Carnegie Mellon University                      ;;;
;;;                  and Alan W Black and Kevin Lenzo                   ;;;
;;;                      Copyright (c) 1998-2000                        ;;;
;;;                        All Rights Reserved.                         ;;;
;;;                                                                     ;;;
;;; Permission is hereby granted, free of charge, to use and distribute ;;;
;;; this software and its documentation without restriction, including  ;;;
;;; without limitation the rights to use, copy, modify, merge, publish, ;;;
;;; distribute, sublicense, and/or sell copies of this work, and to     ;;;
;;; permit persons to whom this work is furnished to do so, subject to  ;;;
;;; the following conditions:                                           ;;;
;;;  1. The code must retain the above copyright notice, this list of   ;;;
;;;     conditions and the following disclaimer.                        ;;;
;;;  2. Any modifications must be clearly marked as such.               ;;;
;;;  3. Original authors' names are not deleted.                        ;;;
;;;  4. The authors' names are not used to endorse or promote products  ;;;
;;;     derived from this software without specific prior written       ;;;
;;;     permission.                                                     ;;;
;;;                                                                     ;;;
;;; CARNEGIE MELLON UNIVERSITY AND THE CONTRIBUTORS TO THIS WORK        ;;;
;;; DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING     ;;;
;;; ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT  ;;;
;;; SHALL CARNEGIE MELLON UNIVERSITY NOR THE CONTRIBUTORS BE LIABLE     ;;;
;;; FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES   ;;;
;;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN  ;;;
;;; AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,         ;;;
;;; ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF      ;;;
;;; THIS SOFTWARE.                                                      ;;;
;;;                                                                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                       ;;
;;;  A generic voice definition file for a limited domain synthesizer     ;;
;;;  Cutomsized for: time                                                 ;;
;;;                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require_module 'clunits)
(require 'clunits)

(if (assoc 'nrc_time_ap_ldom voice-locations)
    (defvar nrc_time_ap::ldom_dir 
      (cdr (assoc 'nrc_time_ap_ldom voice-locations)))
    (defvar nrc_time_ap::ldom_dir (string-append (pwd) "/")))

(if (not (probe_file (path-append nrc_time_ap::ldom_dir "festvox/")))
    (begin
     (format stderr "nrc_time_ap::ldom: Can't find voice scm files they are not in\n")
     (format stderr "   %s\n" (path-append  nrc_time_ap::ldom_dir "festvox/"))
     (format stderr "   Either the voice isn't linked in Festival library\n")
     (format stderr "   or you are starting festival in the wrong directory\n")
     (error)))

;;;  Add the directory contains general voice stuff to load-path
(set! load-path (cons (path-append nrc_time_ap::ldom_dir "festvox/") 
		      load-path))

;;; Flag to save multiple loading of db
(defvar nrc_time_ap::ldom_loaded nil)
;;; When set to non-nil ldom voices *always* use their closest voice
;;; this is used when generating the prompts
(defvar nrc_time_ap::ldom_prompting_stage nil)
;;; Flag to allow new lexical items to be added only once
(defvar nrc_time_ap::added_extra_lex_items nil)

;;; Use backup voice, or use excuse phrase, if this is non-nill
;;; it will use a backup phrase to speak instead of using the
;;; backup voice
(defvar nrc_time_ap::backup_phrase nil)
;;; Show time to synthesize
(defvar nrc_time_ap::show_times nil)
;;; Show unit selection
(defvar nrc_time_ap::show_unit_selection nil)

;;; The front end to the limited domain
(require 'nrc_time_ap)

;;; You may wish to change this 
(set! nrc_time_ap::closest_voice 'voice_kal_diphone)

;;;  These are the parameters which are needed at run time
;;;  build time parameters are added to his list in nrc_time_ap_build.scm
(set! nrc_time_ap::dt_params
      (list
       (list 'db_dir nrc_time_ap::ldom_dir)
       '(name nrc_time_ap)
       '(index_name nrc_time_ap)
       '(f0_join_weight 0.0)
       '(join_weights
         (0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5))
       '(trees_dir "festival/trees/")
       '(catalogue_dir "festival/clunits/")
       '(coeffs_dir "mcep/")
       '(coeffs_ext ".mcep")
       '(clunit_name_feat lisp_nrc_time_ap::clunit_name)
       ;;  Run time parameters 
;       '(join_method windowed)
       ;; if pitch mark extraction is bad this is better than the above
       '(join_method smoothedjoin)
       '(continuity_weight 100)
       '(optimal_coupling 2)
       '(extend_selections 10)
       '(pm_coeffs_dir "mcep/")
       '(pm_coeffs_ext ".mcep")
       '(sig_dir "wav/")
       '(sig_ext ".wav")
;       '(clunits_debug 1)
))

(define (nrc_time_ap::clunit_name i)
  "(nrc_time_ap::clunit_name i)
Defines the unit name for unit selection for time.  The can be modified
changes the basic claissifncation of unit for the clustering.  By default
this does segment plus word, which is reasonable for many ldom domains."
  (let ((name (item.name i)))
    (if (string-equal 
	 name (car (cadr (car (PhoneSet.description '(silences))))))
	;; Do something simpler around pauses
	(string-append
	 name
	 "_"
	 (item.feat i "p.name"))
	;; For all other phones do phone plus word
	;; You could add other things here (like word position)
	(let ((downcasedword 
	       (downcase 
		(item.feat i "R:SylStructure.parent.parent.name"))))
	  (string-append
	   name   ;; segment name
	   "_"
	   (if (string-matches downcasedword ".*'.*")
	       (format nil "%s%s" (string-before downcasedword "'")
		       (string-after downcasedword "'"))
	       (format nil "%s" downcasedword)))))))

(define (nrc_time_ap::ldom_load)
  "(nrc_time_ap::ldom_load)
Function that actual loads in the databases and selection trees.
SHould only be called once per session."
  (set! dt_params nrc_time_ap::dt_params)
  (set! clunits_params nrc_time_ap::dt_params)
  (clunits:load_db clunits_params)
  (load (string-append
	 (string-append 
	  nrc_time_ap::ldom_dir "/"
	  (get_param 'trees_dir dt_params "trees/")
	  (get_param 'index_name dt_params "all")
	  ".tree")))
  (set! nrc_time_ap::ldom_clunit_selection_trees clunits_selection_trees)
  (set! nrc_time_ap::ldom_loaded t))

(set! nrc_time_ap::phrase_cart_tree
'
((lisp_token_end_punc in ("'" "\"" "?" "." "," ":" ";"))
  ((B))
  ((n.name is 0)
   ((B))
   ((n.name in ("." "..." "...."))
    ((name is ".")
     ((NB))
     ((B)))
    ((NB))))))

(define (nrc_time_ap::token_to_words token name)
  (cond
   ;; Domain specific token to word rules
   (t
    (nrc_time_ap::old_token_to_words token name))))

(define (nrc_time_ap::domain_specific_voice_setup)
  "(nrc_time_ap::domain_specific_voice_setup)
Setups an token to word rules, lexical entries, prosody mopdels specific
to this domain.  This function is also called at prompt generation time
to ensure the prompts follow the same rules."
  ;; Let the cluster stuff decide about vowel reduction
  (set! nrc_time_ap::old_postlex_vowel_reduce_table 
	           postlex_vowel_reduce_table)
  (set! postlex_vowel_reduce_table nil)

  ;; Seems things work better with explicit punctuation phrase breaks
  ;; in limited domain (as things will be more consistent
  (set! phrase_cart_tree nrc_time_ap::phrase_cart_tree)
  (Parameter.set 'Phrase_Method 'cart_tree)

  ;; If you want to have domain specific text processing this will
  ;; cause nrc_time_ap::token_to_word to be called
  (set! nrc_time_ap::old_token_to_words english_token_to_words)

  (set! english_token_to_words nrc_time_ap::token_to_words)
  (set! token_to_words nrc_time_ap::token_to_words)

  (if (not nrc_time_ap::added_extra_lex_items)
      (begin
	;; (lex.add.entry '("dadada" nn (((d aa) 1) (( d aa) 1) ((d aa) 1))))
	(set! nrc_time_ap::added_extra_lex_items t)
	))
)

(define (nrc_time_ap::voice_reset)
  "(nrc_time_ap::voice_reset)
Reset global variables back to previous voice."
  (set! english_token_to_words nrc_time_ap::old_token_to_words)
  (set! token_to_words nrc_time_ap::old_token_to_words)
  (set! utt.synth nrc_time_ap::real_utt.synth)
  (set! tts_hooks (delq nrc_time_ap::utt.synth tts_hooks))
  (set! tts_hooks (cons utt.synth tts_hooks))
  (set! postlex_vowel_reduce_table 
	nrc_time_ap::old_postlex_vowel_reduce_table)
  (set! cluster_synth_pre_hooks nil)
  (set! cluster_synth_post_hooks nil)
  t
)

(define (nrc_time_ap::utt.synth utt)
  "(nrc_time_ap::utt.synth utt)
Uses the time voice to synthesize utt, but if that fails 
back off to the defined closest voice (probably a diphone synthesizer)."
  (let ((starttime (clunits::time)))
  (if nrc_time_ap::show_times
      (format t "START: %s\n"
	      (read-from-string (utt.feat utt "iform"))))
  (unwind-protect 
   (begin
     (nrc_time_ap::real_utt.synth utt)
     ;; Successful synthesis
     )
   (begin
     ;; The above failed, so resynthesize with the backup voice
;     (format stderr "ldom/clunits failed\n")
     (if nrc_time_ap::backup_phrase
	 (begin
            (set! utt (nrc_time_ap::real_utt.synth 
		(eval
		 (list 'Utterance 'Text
		       nrc_time_ap::backup_phrase))))
	   )
	 (begin  ;; else use the backup voices
	   (eval (list nrc_time_ap::closest_voice))  ;; call backup voice
	   (set! utt2 (nrc_time_ap::copy_tokens utt))
	   (set! utt (utt.synth utt2))
	   (voice_nrc_time_ap_ldom)                 ;; return to ldom voice
	   ))
     ))
  (if nrc_time_ap::show_unit_selection
      (nrc_time_ap::clunits_units_selected utt "-"))
  (if nrc_time_ap::show_times
      (let ((synthtime (- (clunits::time) starttime))
	    (wavelength 
	     (/ (cadr (assoc 'num_samples (wave.info (utt.wave utt))))
		(cadr (assoc 'sample_rate (wave.info (utt.wave utt)))))))
	(format t "END: synthtime %2.3f wavelength %2.3f (%2.3f)\n"
		synthtime
		wavelength
		(/ wavelength synthtime))))
  utt)
)

(define (nrc_time_ap::fix_pauses utt)
  "(nrc_time_ap::fix_pauses utt)
Remove double pauses at start and end of utterance."
  (mapcar
   (lambda (s)
     (cond
      ;; remove final pause
      ((and (not (item.next s))
	    (string-equal (item.name s)
		  (car (cadr (car (PhoneSet.description '(silences)))))))
       (item.delete s))
      ;; remove inital pause
      ((and (not (item.prev s))
	    (string-equal (item.name s)
	     (car (cadr (car (PhoneSet.description '(silences)))))))
       (item.delete s))))
   (utt.relation.items utt 'Segment))
  utt
)

(define (nrc_time_ap::copy_tokens utt)
  "(nrc_time_ap::copy_tokens utt)
This should be standard library, of in fact not even needed.  It constructs
a new utterance from the tokens in utt so it may be safely resynthesized."
  (let ((utt2 (Utterance Tokens nil))
	(oldtok (utt.relation.first utt 'Token)))
    (utt.relation.create utt2 'Token)
    (while oldtok
      (let ((ntok (utt.relation.append utt2 'Token)))
	(mapcar
	 (lambda (fp)
	   (item.set_feat ntok (car fp) (car (cdr fp))))
	 (cdr (item.features oldtok)))
	(set! oldtok (item.next oldtok))))
    utt2))

(define (voice_nrc_time_ap_ldom)
  "(voice_nrc_time_ap_ldom)
Define voice for limited domain: time."
  ;; Blindly use basic parameters of closest voice
  (eval (list nrc_time_ap::closest_voice))

  (nrc_time_ap::domain_specific_voice_setup)

  ;; When using a backup voice for out of domain utts
  ;; we redefine utt.synth to our own (if we haven't already)
  (if (not (equal? utt.synth nrc_time_ap::utt.synth))
      (begin
	;; This actually isn't general enough, but it will do.
	(set! tts_hooks (delq utt.synth tts_hooks))
	(set! tts_hooks (cons nrc_time_ap::utt.synth tts_hooks))
	(set! nrc_time_ap::real_utt.synth utt.synth)
	(set! utt.synth nrc_time_ap::utt.synth)))

  ;; Load in the clunits databases (or select it if its already loaded)
  (if (not nrc_time_ap::ldom_prompting_stage)
      (begin
	(if (not nrc_time_ap::ldom_loaded)
	    (nrc_time_ap::ldom_load)
	    (clunits:select 'nrc_time_ap))
	(set! clunits_selection_trees 
	      nrc_time_ap::ldom_clunit_selection_trees)
	(Parameter.set 'Synth_Method 'Cluster)))
  

;  (set! cluster_synth_pre_hooks (list nrc_time_ap::fix_pauses))
  (set! cluster_synth_pre_hooks nil)

  ;; This is where you can modify power (and sampling rate) if desired
  (set! after_synth_hooks nil)
;  (set! after_synth_hooks
;      (list
;        (lambda (utt)
;          (utt.wave.rescale utt 2.1))))

  (set! current_voice_reset nrc_time_ap::voice_reset)

  (set! current-voice 'nrc_time_ap_ldom)
)

(if (not (boundp 'clunits::time))
    ;;; Its an older version of clunits and doesn't have this so fake it
    (define (clunits::time)
      "(clunits::time)
      An improper version of clunits::time. upgrade your festopt_clunits
      to get a more accurate one."
      (let ((tmpfile (make_tmp_filename))
	    (hms))
	(system (format nil "date %s >%s" "+%H%t%M%t%S" tmpfile))
	(set! hms (load tmpfile t))
	(delete-file tmpfile)
	(+ (* 12 (car hms))
	   (* 60 (cadr hms))
	   (caddr hms)))))

(define (nrc_time_ap::clunits_units_selected utt filename)
  "(nrc_time_ap::clunits_units_selected utt filename)
Output selected unitsfile indexes for each unit in the given utterance.
Results saved in given file name, or stdout if filename is \"-\"."
  (let ((fd (if (string-equal filename "-")
		t
		(fopen filename "w")))
	(sample_rate
	 (cadr (assoc 'sample_rate (wave.info (utt.wave utt))))))
    (mapcar
     (lambda (s)
       (format fd "%s\t%s\t%10s\t%f\t%f\n"
	       (string-before (item.name s) "_")
	       (item.name s)
	       (item.feat s "fileid")
	       (item.feat s "middle")
	       (+ 
		(item.feat s "middle")
		(/ (- (item.feat s "samp_end")
		      (item.feat s "samp_start"))
		   sample_rate)))
       )
     (utt.relation.items utt 'Unit))
    (if (not (string-equal filename "-"))
	(fclose fd))
    t))

(provide 'nrc_time_ap_ldom)

