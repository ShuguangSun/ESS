;;; ess-mode.el --- Support for editing ESS source code

;; Copyright (C) 1989-1994 Bates, Kademan, Ritter, Smith, Hornik,
;; Maechler, and Rossini.

;; Author: David Smith <dsmith@stats.adelaide.edu.au>
;; Maintainer: A.J. Rossini <rossinI@stat.sc.edu>
;; Created: 7 Jan 1994
;; Modified: $Date: 1997/11/17 14:58:35 $
;; Version: $Revision: 1.70 $
;; RCS: $Id: ess-mode.el,v 1.70 1997/11/17 14:58:35 rossini Exp $


;; This file is part of ess-mode

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; Code for editing ESS source code.

;;; Code:

 ; Requires and autoloads

(require 'ess)

;;; AJR: THIS IS GROSS AND DISGUSTING (but I wrote it).
(autoload 'ess-mode-minibuffer-map "ess-inf" "" nil 'keymap)
(autoload 'ess-read-object-name "ess-inf" "" nil)
(autoload 'ess-list-object-completions "ess-inf" "" nil)

(autoload 'ess-load-file "ess-inf" "" nil)
(autoload 'get-ess-process "ess-inf" "" nil)
(autoload 'ess-switch-to-ESS "ess-inf" "" nil)
(autoload 'ess-request-a-process "ess-inf" "" nil)
(autoload 'ess-modtime-gt "ess-inf" "" nil)
(autoload 'ess-create-temp-buffer "ess-inf" "" nil)
(autoload 'ess-command "ess-inf" "" nil)
(autoload 'ess-eval-visibly "ess-inf" "" nil)
(autoload 'ess-make-buffer-current "ess-inf" "" nil)
(autoload 'ess-object-modtime "ess-inf" "" nil)
(autoload 'ess-display-temp-buffer "ess-inf" "" nil)
(autoload 'ess-force-buffer-current "ess-inf" "" nil)
(autoload 'ess-switch-process "ess-inf" "" nil)

 ; ESS mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; In this section:
;;;;
;;;; * The major mode ess-mode
;;;; * Commands for ess-mode
;;;; * Code evaluation commands
;;;; * Indenting code and commands
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;*;; Major mode definition

(if ess-eval-map
    nil
  (cond ((string-match "XEmacs\\|Lucid" emacs-version)
	 ;; Code for XEmacs
 	 (setq ess-eval-map (make-keymap)))
	((not (string-match "XEmacs\\|Lucid" emacs-version))
	 ;; Code for GNU Emacs
	 (setq ess-eval-map (make-sparse-keymap))))

  (define-key ess-eval-map "\C-r"    'ess-eval-region)
  (define-key ess-eval-map "\M-r"    'ess-eval-region-and-go)
  (define-key ess-eval-map "\C-b"    'ess-eval-buffer)
  (define-key ess-eval-map "\M-b"    'ess-eval-buffer-and-go)
  (define-key ess-eval-map "\C-f"    'ess-eval-function)
  (define-key ess-eval-map "\M-f"    'ess-eval-function-and-go)
  (define-key ess-eval-map "\C-x"    'ess-eval-function)
  (define-key ess-eval-map "\C-n"    'ess-eval-line-and-next-line)
  (define-key ess-eval-map "\C-j"    'ess-eval-line)
  (define-key ess-eval-map "\M-j"    'ess-eval-line-and-go))


(if ess-mode-map
    nil

  (cond ((string-match "XEmacs\\|Lucid" emacs-version)
	 ;; Code for XEmacs
 	 (setq ess-mode-map (make-keymap))
	 (set-keymap-parent ess-mode-map text-mode-map)) ;; was comint?!?
	((not (string-match "XEmacs\\|Lucid" emacs-version))
	 ;; Code for GNU Emacs
	 (setq ess-mode-map (make-sparse-keymap))))

  ;; By popular demand:
  (define-key ess-mode-map "\C-m"        'newline-and-indent)

  (define-key ess-mode-map "\C-c\C-r"    'ess-eval-region)
  (define-key ess-mode-map "\C-c\M-r"    'ess-eval-region-and-go)
  (define-key ess-mode-map "\C-c\C-b"    'ess-eval-buffer)
  (define-key ess-mode-map "\C-c\M-b"    'ess-eval-buffer-and-go)
  (define-key ess-mode-map "\C-c\C-f"    'ess-eval-function)
  (define-key ess-mode-map "\C-c\M-f"    'ess-eval-function-and-go)
  (define-key ess-mode-map "\M-\C-x"     'ess-eval-function)
  (define-key ess-mode-map "\C-c\C-n"    'ess-eval-line-and-next-line)
  (define-key ess-mode-map "\C-c\C-j"    'ess-eval-line)
  (define-key ess-mode-map "\C-c\M-j"    'ess-eval-line-and-go)
  (define-key ess-mode-map "\M-\C-a"     'ess-beginning-of-function)
  (define-key ess-mode-map "\M-\C-e"     'ess-end-of-function)
  (define-key ess-mode-map "\C-c\C-y"    'ess-switch-to-ESS)
  (define-key ess-mode-map "\C-c\C-z"    'ess-switch-to-end-of-ESS)
  (define-key ess-mode-map "\C-c\C-l"    'ess-load-file)
  (define-key ess-mode-map "\C-c\C-v"    'ess-display-help-on-object)
  (define-key ess-mode-map "\C-c\C-d"    'ess-dump-object-into-edit-buffer)
;(define-key ess-mode-map "\C-c5\C-d"'ess-dump-object-into-edit-buffer-other-frame)
  (define-key ess-mode-map "\C-c\C-s"    'ess-switch-process) ; use a
					; different process for the buffer.
  (define-key ess-mode-map "\C-c\C-t"    'ess-execute-in-tb)
  (define-key ess-mode-map "\C-c\t"      'ess-complete-object-name)
  (define-key ess-mode-map "\M-\t"       'comint-replace-by-expanded-filename)
  (define-key ess-mode-map "\M-?"        'ess-list-object-completions)
  ;; wrong here (define-key ess-mode-map "\C-c\C-k" 'ess-request-a-process)
  (define-key ess-mode-map "\C-c\C-k"    'ess-force-buffer-current)
  (define-key ess-mode-map "\C-c`"       'ess-parse-errors) ; \C-x reserved!
  (define-key ess-mode-map "{"           'ess-electric-brace)
  (define-key ess-mode-map "}"           'ess-electric-brace)
  (define-key ess-mode-map "\e\C-h"      'ess-mark-function)
  (define-key ess-mode-map "\e\C-q"      'ess-indent-exp)
  (define-key ess-mode-map "\177"        'backward-delete-char-untabify)
  (define-key ess-mode-map "\t"          'ess-indent-command)
  (define-key ess-mode-map "\C-c\C-e"    ess-eval-map))


(easy-menu-define
 ess-mode-menu ess-mode-map
 "Menu for use in ess-mode"
 '("ESS" ; ESS-mode
   ["Load file"  ess-load-file t]
   ("Eval and Go"
    ["Eval buffer"   ess-eval-buffer-and-go   t]
    ["Eval region"   ess-eval-region-and-go   t]
    ["Eval function" ess-eval-function-and-go t]
    ["Eval line"     ess-eval-line-and-go     t]
    ["About" (lambda nil (interactive) (ess-goto-info "Evaluating code")) t]
    )
   ("ESS Eval"
    ["Eval buffer"       ess-eval-buffer             t]
    ["Eval region"       ess-eval-region             t]
    ["Eval function"     ess-eval-function           t]
    ["Step through line" ess-eval-line-and-next-line t]
    ["Enter expression"  ess-execute-in-tb           t]
    ["Eval line"         ess-eval-line               t]
    ["About" (lambda nil (interactive) (ess-goto-info "Evaluating code"))]
    )
   ("Motion..."
    ["Edit new object"       ess-dump-object-into-edit-buffer t]
    ["Goto end of ESS buffer"  ess-switch-to-end-of-ESS           t]
    ["Switch to ESS buffer"    ess-switch-to-ESS                  t]
    ["End of function"	    ess-end-of-function              t]
    ["Beginning of function" ess-beginning-of-function        t])
   ("ESS list..."
    ["Backward list"         backward-list                   t]
    ["Forward list"          forward-list                    t]
    ["Next parenthesis"      down-list                       t]
    ["Enclosing parenthesis" backward-up-list                t]
    ["Backward sexp"         backward-sexp                   t]
    ["Forward sexp"          forward-sexp                    t]
    ["About"                 (Info-goto-node "(Emacs)Lists") t]
    )
   ("ESS Edit"
    ["Complete Filename" comint-replace-by-expanded-filename t]
    ["Complete Object"   ess-complete-object-name              t]
    ["Kill sexp"         kill-sexp                           t]
    ["Mark function"     ess-mark-function                     t]
    ["Indent expression" ess-indent-exp                        t]
    ["Indent line"       ess-indent-command                    t]
    ["Undo"              undo                                t]
    ["About"   (lambda nil (interactive) (ess-goto-info "Edit buffer")) t]
    )
   "------"
   ["Describe"  describe-mode t]
   ["About"  (lambda nil (interactive) (ess-goto-info "Editing")) t]
   ["Send bug report"  ess-submit-bug-report t]
   ))

;; NOT NEEDED!
;;(if (not (string-match "XEmacs" emacs-version))
;;    (progn
;;      (if (featurep 'ess-mode)
;;	   (define-key ess-mode-map
;;	     [menu-bar ess-mode]
;;	     (cons "ess-mode" ess-mode-menu))
;;	 (eval-after-load "ess-mode"
;;			  '(define-key ess-mode-map
;;			     [menu-bar ess-mode]
;;			     (cons "ess-mode"
;;				   ess-mode-menu))))))

(defun ess-mode-xemacs-menu ()
  "Hook to install ess-mode menu for XEmacs (w/ easymenu)"
  (if 'ess-mode
        (easy-menu-add ess-mode-menu)
    (easy-menu-remove ess-mode-menu)))

(if (string-match "XEmacs" emacs-version)
    (add-hook 'ess-mode-hook 'ess-mode-xemacs-menu))

(defun ess-mode (&optional alist proc-name)
  "Major mode for editing ESS source.
Optional arg ALIST describes how to customize the editing mode.
Optional arg PROC-NAME is name of associated inferior process.

\\{ess-mode-map}

Customization: Entry to this mode runs the hooks in ess-mode-hook.

You can send text to the inferior ESS process from other buffers containing
ESS source.
    ess-eval-region sends the current region to the ESS process.
    ess-eval-buffer sends the current buffer to the ESS process.
    ess-eval-function sends the current function to the ESS process.
    ess-eval-line sends the current line to the ESS process.
    ess-beginning-of-function and ess-end-of-function move the point to
        the beginning and end of the current ESS function.
    ess-switch-to-ESS switches the current buffer to the ESS process buffer.
    ess-switch-to-end-of-ESS switches the current buffer to the ESS process
        buffer and puts point at the end of it.

    ess-eval-region-and-go, ess-eval-buffer-and-go,
        ess-eval-function-and-go, and ess-eval-line-and-go switch to the S
        process buffer after sending their text.

    ess-load-file sources a file of commands to the ESS process.

\\[ess-indent-command] indents for ESS code.
\\[backward-delete-char-untabify] converts tabs to spaces as it moves back.
Comments are indented in a similar way to Emacs-lisp mode:
       `###'     beginning of line
       `##'      the same level of indentation as the code
       `#'       the same column on the right, or to the right of such a
                 column if that is not possible.(default value 40).
                 \\[indent-for-comment] command automatically inserts such a
                 `#' in the right place, or aligns such a comment if it is
                 already inserted.
\\[ess-indent-exp] command indents each line of the ESS grouping following point.

Variables controlling indentation style:
 ess-tab-always-indent
    Non-nil means TAB in ESS mode should always reindent the current line,
    regardless of where in the line point is when the TAB command is used.
 ess-auto-newline
    Non-nil means automatically newline before and after braces inserted in S
    code.
 ess-indent-level
    Indentation of ESS statements within surrounding block.
    The surrounding block's indentation is the indentation of the line on
    which the open-brace appears.
 ess-continued-statement-offset
    Extra indentation given to a substatement, such as the then-clause of an
    if or body of a while.
 ess-continued-brace-offset
    Extra indentation given to a brace that starts a substatement.
    This is in addition to ess-continued-statement-offset.
 ess-brace-offset
    Extra indentation for line if it starts with an open brace.
 ess-arg-function-offset
    Extra indent for internal substatements of function `foo' that called
    in `arg=foo(...)' form.
   If not number, the statements are indented at open-parenthesis following
   `foo'.
 ess-expression-offset
    Extra indent for internal substatements of `expression' that specified
    in `obj <- expression(...)' form.
    If not number, the statements are indented at open-parenthesis following
    `expression'.
 ess-brace-imaginary-offset
    An open brace following other text is treated as if it were
    this far to the right of the start of its line.
 ess-else-offset
    Extra indentation for line if it starts with `else'.
 ess-close-brace-offset
    Extra indentation for closing braces.
 ess-fancy-comments
    Non-nil means distinguish between #, ##, and ### for indentation.

Furthermore, \\[ess-set-style] command enables you to set up predefined ess-mode
indentation style. At present, predefined style are `BSD', `GNU', `K&R', `C++',
`CLB' (quoted from C language style)."
  (interactive)
  (kill-all-local-variables) ;; NOTICE THIS!
  (ess-setq-vars-local alist (current-buffer))
  (ess-write-to-dribble-buffer
   (format "(ess-mode-1): ess-language=%s, ess-dialect=%s buf=%s \n"
	   ess-language
	   ess-dialect
	   (current-buffer)))
;;  (ess-write-to-dribble-buffer
;;   (format "(ess-mode-1.2): ess-process= %s \n"
;;	   (ess-local-process-name ess-local-process-name "none")))
  (ess-write-to-dribble-buffer
   (format "(ess-mode-1.5): alist=%s \n"
	   alist))
  (setq major-mode 'ess-mode)
  (setq mode-name (concat "ESS[" ess-language "]")) ; was ess-dialect
  ;; The following line does the next 20 or so :-).
  (ess-write-to-dribble-buffer
   (format "(ess-mode-1.6): editing-alist=%s \n"
	   ess-mode-editing-alist))
  (ess-setq-vars-local ess-mode-editing-alist (current-buffer))

  (use-local-map ess-mode-map)
  (set-syntax-table ess-mode-syntax-table)

  ;;; Keep <tabs> out of the code.
  (make-local-variable 'indent-tabs-mode)
  (setq indent-tabs-mode nil)


;;  (make-local-variable 'paragraph-start)
;;  (setq paragraph-start (concat "^$\\|" page-delimiter))
;;  (make-local-variable 'paragraph-separate)
;;  (setq paragraph-separate paragraph-start)
;;  (make-local-variable 'paragraph-ignore-fill-prefix)
;;  (setq paragraph-ignore-fill-prefix t)
;;  (make-local-variable 'indent-line-function)
;;  (setq indent-line-function 'ess-indent-line)
;;  (make-local-variable 'require-final-newline)
;;  (setq require-final-newline t)
;;  (make-local-variable 'comment-start)
;;  (setq comment-start "#")
;;  (make-local-variable 'comment-start-skip)
;;  (setq comment-start-skip "#+ *")
;;  (make-local-variable 'comment-column)
;;  (setq comment-column 40)
;;  (make-local-variable 'comment-indent-function)
;;  (setq comment-indent-function 'ess-comment-indent)
;;  (make-local-variable 'parse-sexp-ignore-comments)
;;  (setq parse-sexp-ignore-comments t)
;;  (ess-set-style ess-default-style)
;;  (make-local-variable 'ess-local-process-name)
;;  (make-local-variable 'ess-keep-dump-files)
  (put 'ess-local-process-name 'permanent-local t) ; protect from RCS
  (setq mode-line-process ;; AJR: in future, XEmacs will use modeline-process.
	'(" [" (ess-local-process-name ess-local-process-name "none") "]"))


  (ess-load-object-name-db-file)
  (run-hooks 'ess-mode-hook)
  (ess-write-to-dribble-buffer "\nFinished setting up ESS-mode.\n"))

;;*;; User commands in ess-mode

;;;*;;; Handy commands

(defun ess-execute-in-tb ()
  "Like ess-execute, but always evaluates in temp buffer."
  (interactive)
  (let ((ess-execute-in-process-buffer nil))
    (call-interactively 'ess-execute)))

;;;*;;; Buffer motion/manipulation commands

(defun ess-beginning-of-function ()
  "Leave the point at the beginning of the current ESS function."
  (interactive)
  (let ((init-point (point))
 	beg end done)
    (if (search-forward "(" nil t) (forward-char 1))
    ;; in case we're sitting in a function header
    (while (not done)
      (if
 	  (re-search-backward ess-function-pattern (point-min) t)
 	  nil
 	(goto-char init-point)
 	(error "Point is not in a function."))
      (setq beg (point))
      (forward-list 1)			; get over arguments
      (forward-sexp 1)			; move over braces
      (setq end (point))
      (goto-char beg)
      ;; current function must begin and end around point
      (setq done (and (>= end init-point) (<= beg init-point))))))


(defun ess-end-of-function nil
  "Leave the point at the end of the current ESS function."
  (interactive)
  (ess-beginning-of-function)
  (forward-list 1)			; get over arguments
  (forward-sexp 1)			; move over braces
  )

(defun ess-extract-word-name ()
  "Get the word you're on."
  (save-excursion
    (re-search-forward "\\<\\w+\\>" nil t)
    (buffer-substring (match-beginning 0) (match-end 0))))

;;; Original ess-mode 4.8.6 version
;;(defun ess-mark-function ()
;;  "Put mark at end of ESS function, point at beginning."
;;  (interactive)
;;  (push-mark (point))
;;  (ess-end-of-function)
;;  (push-mark (point))
;;  (ess-beginning-of-function))

;;; Kurt's version, suggested 970306.
(defun ess-mark-function ()
  "Put mark at end of ESS function, point at beginning."
  (interactive)
  (ess-beginning-of-function)
  (push-mark (point))
  (ess-end-of-function)
  (exchange-point-and-mark))


;;*;; Loading files

(defun ess-check-modifications nil
  "Check whether loading this file would overwrite some ESS objects
which have been modified more recently than this file, and confirm
if this is the case."
  ;; FIXME: this should really cycle through all top-level assignments in
  ;; the buffer
  (and (buffer-file-name) ess-filenames-map
       (let ((sourcemod (nth 5 (file-attributes (buffer-file-name))))
	     (objname))
	 (save-excursion
	   (goto-char (point-min))
	   ;; Get name of assigned object, if we can find it
	   (setq objname
		 (and
		  (re-search-forward
		   "^\\s *\"?\\(\\(\\sw\\|\\s_\\)+\\)\"?\\s *[<_]"
		   nil
		   t)
		  (buffer-substring (match-beginning 1)
				    (match-end 1)))))
	 (and
	  sourcemod			; the file may have been deleted
	  objname			; may not have been able to
					; find name
	  (ess-modtime-gt (ess-object-modtime objname) sourcemod)
	  (not (y-or-n-p

		(format
		 "The ESS object %s is newer than this file. Continue?"
		 objname)))
	  (error "Aborted")))))

(defun ess-check-source (fname)
  "If file FNAME has an unsaved buffer, offer to save it.
Returns t if the buffer existed and was modified, but was not saved"
  (let ((buff (get-file-buffer fname)))
    ;; RMH: Corrections noted below are needed for C-c C-l to work
    ;; correctly when issued from *S* buffer.
    ;; The following barfs since
    ;; 1. `if' does not accept a buffer argument, `not' does.
    ;; 2. (buffer-file-name) is not necessarily defined for *S*
    ;;(if buff
    ;; (let ((deleted (not (file-exists-p (buffer-file-name)))))
    ;; Next 2 lines are RMH's solution:
    (if (not(not buff))
	(let ((deleted (not (file-exists-p fname))))
	  (if (and deleted (not (buffer-modified-p buff)))
	      ;; Buffer has been silently deleted, so silently save
	      (save-excursion
		(set-buffer buff)
		(set-buffer-modified-p t)
		(save-buffer))
	    (if (and (buffer-modified-p buff)
		     (or ess-mode-silently-save
			 (y-or-n-p
			  (format "Save buffer %s first? "
				  (buffer-name buff)))))
		(save-excursion
		  (set-buffer buff)
		  (save-buffer))))
	  (buffer-modified-p buff)))))

(defun ess-parse-errors (showerr)
  "Jump to error in last loaded ESS source file.
With prefix argument, only shows the errors ESS reported."
  (interactive "P")
  (ess-make-buffer-current)
  (let ((errbuff (get-buffer ess-error-buffer-name)))
    (if (not errbuff)
	(error "You need to do a load first!")
      (set-buffer errbuff)
      (goto-char (point-max))
      (if
	  (re-search-backward
	   "^\\(Syntax error: .*\\) at line \\([0-9]*\\), file \\(.*\\)$"
	   nil
	   t)
	  (let* ((filename (buffer-substring (match-beginning 3) (match-end 3)))
		 (fbuffer (get-file-buffer filename))
		 (linenum (string-to-int (buffer-substring (match-beginning 2) (match-end 2))))
		 (errmess (buffer-substring (match-beginning 1) (match-end 1))))
	    (if showerr
		  (ess-display-temp-buffer errbuff)
	      (if fbuffer nil
		(setq fbuffer (find-file-noselect filename))
		(save-excursion
		  (set-buffer fbuffer)
		  (ess-mode)))
	      (pop-to-buffer fbuffer)
	      (goto-line linenum))
	    (princ errmess t))
	(message "Not a syntax error.")
	(ess-display-temp-buffer errbuff)))))

;;*;; ESS code formatting/indentation

;;;*;;; User commands

(defun ess-electric-brace (arg)
  "Insert character and correct line's indentation."
  (interactive "P")
  (let (insertpos)
    (if (and (not arg)
	     (eolp)
	     (or (save-excursion
		   (skip-chars-backward " \t")
		   (bolp))
		 (if ess-auto-newline (progn (ess-indent-line) (newline) t) nil)))
	(progn
	  (insert last-command-char)
	  (ess-indent-line)
	  (if ess-auto-newline
	      (progn
		(newline)
		;; (newline) may have done auto-fill
		(setq insertpos (- (point) 2))
		(ess-indent-line)))
	  (save-excursion
	    (if insertpos (goto-char (1+ insertpos)))
	    (delete-char -1))))
    (if insertpos
	(save-excursion
	  (goto-char insertpos)
	  (self-insert-command (prefix-numeric-value arg)))
      (self-insert-command (prefix-numeric-value arg)))))

(defun ess-indent-command (&optional whole-exp)
  "Indent current line as ESS code, or in some cases insert a tab character.
If ess-tab-always-indent is non-nil (the default), always indent current line.
Otherwise, indent the current line only if point is at the left margin
or in the line's indentation; otherwise insert a tab.

A numeric argument, regardless of its value,
means indent rigidly all the lines of the expression starting after point
so that this line becomes properly indented.
The relative indentation among the lines of the expression are preserved."
  (interactive "P")
  (if whole-exp
      ;; If arg, always indent this line as S
      ;; and shift remaining lines of expression the same amount.
      (let ((shift-amt (ess-indent-line))
	    beg end)
	(save-excursion
	  (if ess-tab-always-indent
	      (beginning-of-line))
	  (setq beg (point))
	  (backward-up-list 1)
	  (forward-list 1)
	  (setq end (point))
	  (goto-char beg)
	  (forward-line 1)
	  (setq beg (point)))
	(if (> end beg)
	    (indent-code-rigidly beg end shift-amt)))
    (if (and (not ess-tab-always-indent)
	     (save-excursion
	       (skip-chars-backward " \t")
	       (not (bolp))))
	(insert-tab)
      (ess-indent-line))))

(defun ess-indent-exp ()
  "Indent each line of the ESS grouping following point."
  (interactive)
  (let ((indent-stack (list nil))
	(contain-stack (list (point)))
	(case-fold-search nil)
	;; restart
	outer-loop-done	innerloop-done state ostate
	this-indent
	last-sexp
	last-depth
	at-else at-brace
	(opoint (point))
	(next-depth 0))
    (save-excursion
      (forward-sexp 1))
    (save-excursion
      (setq outer-loop-done nil)
      (while (and (not (eobp)) (not outer-loop-done))
	(setq last-depth next-depth)
	;; Compute how depth changes over this line
	;; plus enough other lines to get to one that
	;; does not end inside a comment or string.
	;; Meanwhile, do appropriate indentation on comment lines.
	(setq innerloop-done nil)
	(while (and (not innerloop-done)
		    (not (and (eobp) (setq outer-loop-done t))))
	  (setq ostate state)
	  (setq state (parse-partial-sexp (point) (progn (end-of-line) (point))
					  nil nil state))
	  (setq next-depth (car state))
	  (if (and (car (cdr (cdr state)))
		   (>= (car (cdr (cdr state))) 0))
	      (setq last-sexp (car (cdr (cdr state)))))
	  (if (or (nth 4 ostate))
	      (ess-indent-line))
	  (if (nth 4 state)
	      (and (ess-indent-line)
		   (setcar (nthcdr 4 state) nil)))
	  (if (or (nth 3 state))
	      (forward-line 1)
	    (setq innerloop-done t)))
	(if (<= next-depth 0)
	    (setq outer-loop-done t))
	(if outer-loop-done
	    nil
	  ;; If this line had ..))) (((.. in it, pop out of the levels
	  ;; that ended anywhere in this line, even if the final depth
	  ;; doesn't indicate that they ended.
	  (while (> last-depth (nth 6 state))
	    (setq indent-stack (cdr indent-stack)
		  contain-stack (cdr contain-stack)
		  last-depth (1- last-depth)))
	  (if (/= last-depth next-depth)
	      (setq last-sexp nil))
	  ;; Add levels for any parens that were started in this line.
	  (while (< last-depth next-depth)
	    (setq indent-stack (cons nil indent-stack)
		  contain-stack (cons nil contain-stack)
		  last-depth (1+ last-depth)))
	  (if (null (car contain-stack))
	      (setcar contain-stack (or (car (cdr state))
					(save-excursion (forward-sexp -1)
							(point)))))
	  (forward-line 1)
	  (skip-chars-forward " \t")
	  (if (eolp)
	      nil
	    (if (and (car indent-stack)
		     (>= (car indent-stack) 0))
		;; Line is on an existing nesting level.
		;; Lines inside parens are handled specially.
		(if (/= (char-after (car contain-stack)) ?{)
		    (setq this-indent (car indent-stack))
		  ;; Line is at statement level.
		  ;; Is it a new statement?  Is it an else?
		  ;; Find last non-comment character before this line
		  (save-excursion
		    (setq at-else (looking-at "else\\W"))
		    (setq at-brace (= (following-char) ?{))
		    (ess-backward-to-noncomment opoint)
		    (if (ess-continued-statement-p)
			;; Preceding line did not end in comma or semi;
			;; indent this line  ess-continued-statement-offset
			;; more than previous.
			(progn
			  (ess-backward-to-start-of-continued-exp (car contain-stack))
			  (setq this-indent
				(+ ess-continued-statement-offset (current-column)
				   (if at-brace ess-continued-brace-offset 0))))
		      ;; Preceding line ended in comma or semi;
		      ;; use the standard indent for this level.
		      (if at-else
			  (progn (ess-backward-to-start-of-if opoint)
				 (setq this-indent (+ ess-else-offset
						      (current-indentation))))
			(setq this-indent (car indent-stack))))))
	      ;; Just started a new nesting level.
	      ;; Compute the standard indent for this level.
	      (let ((val (ess-calculate-indent
			   (if (car indent-stack)
			       (- (car indent-stack))))))
		(setcar indent-stack
			(setq this-indent val))))
	    ;; Adjust line indentation according to its contents
	    (if (= (following-char) ?})
		;;(setq this-indent (- this-indent ess-indent-level)))
 		(setq this-indent (+ this-indent
 				     (- ess-close-brace-offset ess-indent-level))))
	    (if (= (following-char) ?{)
		(setq this-indent (+ this-indent ess-brace-offset)))
	    ;; Put chosen indentation into effect.
	    (or (= (current-column) this-indent)
		(= (following-char) ?\#)
		(progn
		  (delete-region (point) (progn (beginning-of-line) (point)))
		  (indent-to this-indent)))
	    ;; Indent any comment following the text.
	    (or (looking-at comment-start-skip)
		(if (re-search-forward comment-start-skip (save-excursion (end-of-line) (point)) t)
		    (progn (indent-for-comment) (beginning-of-line))))))))))
;; (message "Indenting ESS expression...done")

;;;*;;; Support functions for indentation

(defun ess-comment-indent ()
  (if (looking-at "###")
      (current-column)
    (if (looking-at "##")
	(let ((tem (ess-calculate-indent)))
	  (if (listp tem) (car tem) tem))
      (skip-chars-backward " \t")
      (max (if (bolp) 0 (1+ (current-column)))
	   comment-column))))

(defun ess-indent-line ()
  "Indent current line as ESS code.
Return the amount the indentation changed by."
  (let ((indent (ess-calculate-indent nil))
	beg shift-amt
	(case-fold-search nil)
	(pos (- (point-max) (point))))
    (beginning-of-line)
    (setq beg (point))
    (cond ((eq indent nil)
	   (setq indent (current-indentation)))
	  (t
	   (skip-chars-forward " \t")
	   (if (and ess-fancy-comments (looking-at "###"))
	       (setq indent 0))
	   (if (and ess-fancy-comments
		    (looking-at "#")
		    (not (looking-at "##")))
	       (setq indent comment-column)
	     (if (eq indent t) (setq indent 0))
	     (if (listp indent) (setq indent (car indent)))
	     (cond ((and (looking-at "else\\b")
			 (not (looking-at "else\\s_")))
		    (setq indent (save-excursion
				   (ess-backward-to-start-of-if)
				   (+ ess-else-offset (current-indentation)))))
		   ((= (following-char) ?})
		    (setq indent
			  (+ indent
			     (- ess-close-brace-offset ess-indent-level))))
		   ((= (following-char) ?{)
		    (setq indent (+ indent ess-brace-offset)))))))
    (skip-chars-forward " \t")
    (setq shift-amt (- indent (current-column)))
    (if (zerop shift-amt)
	(if (> (- (point-max) pos) (point))
	    (goto-char (- (point-max) pos)))
      (delete-region beg (point))
      (indent-to indent)
      ;; If initial point was within line's indentation,
      ;; position after the indentation.
      ;; Else stay at same point in text.
      (if (> (- (point-max) pos) (point))
	  (goto-char (- (point-max) pos))))
    shift-amt))

(defun ess-calculate-indent (&optional parse-start)
  "Return appropriate indentation for current line as ESS code.
In usual case returns an integer: the column to indent to.
Returns nil if line starts inside a string, t if in a comment."
  (save-excursion
    (beginning-of-line)
    (let ((indent-point (point))
	  (case-fold-search nil)
	  state
	  containing-sexp)
      (if parse-start
	  (goto-char parse-start)
	(beginning-of-defun))
      (while (< (point) indent-point)
	(setq parse-start (point))
	(setq state (parse-partial-sexp (point) indent-point 0))
	(setq containing-sexp (car (cdr state))))
      (cond ((or (nth 3 state) (nth 4 state))
	     ;; return nil or t if should not change this line
	     (nth 4 state))
	    ((null containing-sexp)
	     ;; Line is at top level.  May be data or function definition,
	     (beginning-of-line)
	     (if (and (/= (following-char) ?\{)
		      (save-excursion
			(ess-backward-to-noncomment (point-min))
			(ess-continued-statement-p)))
		 ess-continued-statement-offset
	       0))   ; Unless it starts a function body
	    ((/= (char-after containing-sexp) ?{)
	     ;; line is expression, not statement:
	     ;; indent to just after the surrounding open.
	     (goto-char containing-sexp)
	     (let ((bol (save-excursion (beginning-of-line) (point))))

	       ;; modified by shiba@isac 7.3.1992
	       (cond ((and (numberp ess-expression-offset)
			   (re-search-backward "[ \t]*expression[ \t]*" bol t))
		      ;; This regexp match every "expression".
		      ;; modified by shiba
		      ;;(forward-sexp -1)
		      (beginning-of-line)
		      (skip-chars-forward " \t")
		      ;; End
		      (+ (current-column) ess-expression-offset))
		     ((and (numberp ess-arg-function-offset)
			   (re-search-backward "=[ \t]*\\s\"*\\(\\w\\|\\s_\\)+\\s\"*[ \t]*" bol t))
		      (forward-sexp -1)
		      (+ (current-column) ess-arg-function-offset))
		     ;; "expression" is searched before "=".
		     ;; End

		     (t
		      (progn (goto-char (1+ containing-sexp))
			     (current-column))))))
	    (t
	     ;; Statement level.  Is it a continuation or a new statement?
	     ;; Find previous non-comment character.
	     (goto-char indent-point)
	     (ess-backward-to-noncomment containing-sexp)
	     ;; Back up over label lines, since they don't
	     ;; affect whether our line is a continuation.
	     (while (eq (preceding-char) ?\,)
	       (ess-backward-to-start-of-continued-exp containing-sexp)
	       (beginning-of-line)
	       (ess-backward-to-noncomment containing-sexp))
	     ;; Now we get the answer.
	     (if (ess-continued-statement-p)
		 ;; This line is continuation of preceding line's statement;
		 ;; indent  ess-continued-statement-offset  more than the
		 ;; previous line of the statement.
		 (progn
		   (ess-backward-to-start-of-continued-exp containing-sexp)
		   (+ ess-continued-statement-offset (current-column)
		      (if (save-excursion (goto-char indent-point)
					  (skip-chars-forward " \t")
					  (eq (following-char) ?{))
			  ess-continued-brace-offset 0)))
	       ;; This line starts a new statement.
	       ;; Position following last unclosed open.
	       (goto-char containing-sexp)
	       ;; Is line first statement after an open-brace?
	       (or
		 ;; If no, find that first statement and indent like it.
		 (save-excursion
		   (forward-char 1)
		   (while (progn (skip-chars-forward " \t\n")
				 (looking-at "#"))
		     ;; Skip over comments following openbrace.
		     (forward-line 1))
		   ;; The first following code counts
		   ;; if it is before the line we want to indent.
		   (and (< (point) indent-point)
			(current-column)))
		 ;; If no previous statement,
		 ;; indent it relative to line brace is on.
		 ;; For open brace in column zero, don't let statement
		 ;; start there too.  If ess-indent-level is zero,
		 ;; use ess-brace-offset + ess-continued-statement-offset instead.
		 ;; For open-braces not the first thing in a line,
		 ;; add in ess-brace-imaginary-offset.
		 (+ (if (and (bolp) (zerop ess-indent-level))
			(+ ess-brace-offset ess-continued-statement-offset)
		      ess-indent-level)
		    ;; Move back over whitespace before the openbrace.
		    ;; If openbrace is not first nonwhite thing on the line,
		    ;; add the ess-brace-imaginary-offset.
		    (progn (skip-chars-backward " \t")
			   (if (bolp) 0 ess-brace-imaginary-offset))
		    ;; If the openbrace is preceded by a parenthesized exp,
		    ;; move to the beginning of that;
		    ;; possibly a different line
		    (progn
		      (if (eq (preceding-char) ?\))
			  (forward-sexp -1))
		      ;; Get initial indentation of the line we are on.
		      (current-indentation))))))))))

(defun ess-continued-statement-p ()
  (let ((eol (point)))
    (save-excursion
      (cond ((memq (preceding-char) '(nil ?\, ?\; ?\} ?\{ ?\]))
	     nil)
	    ;; ((bolp))
	    ((= (preceding-char) ?\))
	     (forward-sexp -2)
	     (looking-at "if\\b[ \t]*(\\|function\\b[ \t]*(\\|for\\b[ \t]*(\\|while\\b[ \t]*("))
	    ((progn (forward-sexp -1)
		    (and (looking-at "else\\b\\|repeat\\b")
			 (not (looking-at "else\\s_\\|repeat\\s_"))))
	     (skip-chars-backward " \t")
	     (or (bolp)
		 (= (preceding-char) ?\;)))
	    (t
	     (progn (goto-char eol)
		    (skip-chars-backward " \t")
		    (or (and (> (current-column) 1)
			     (save-excursion (backward-char 1)
					     (looking-at "[-:+*/_><=]")))
			(and (> (current-column) 3)
			     (progn (backward-char 3)
				    (looking-at "%[^ \t]%"))))))))))

(defun ess-backward-to-noncomment (lim)
  (let (opoint stop)
    (while (not stop)
      (skip-chars-backward " \t\n\f" lim)
      (setq opoint (point))
      (beginning-of-line)
      (search-forward "#" opoint 'move)
      (skip-chars-backward " \t#")
      (setq stop (or (/= (preceding-char) ?\n) (<= (point) lim)))
	(if stop (point)
	  (beginning-of-line)))))

(defun ess-backward-to-start-of-continued-exp (lim)
  (if (= (preceding-char) ?\))
      (forward-sexp -1))
  (beginning-of-line)
  (if (<= (point) lim)
      (goto-char (1+ lim)))
  (skip-chars-forward " \t"))

(defun ess-backward-to-start-of-if (&optional limit)
  "Move to the start of the last ``unbalanced'' if."
  (or limit (setq limit (save-excursion (beginning-of-defun) (point))))
  (let ((if-level 1)
	(case-fold-search nil))
    (while (not (zerop if-level))
      (backward-sexp 1)
      (cond ((looking-at "else\\b")
	     (setq if-level (1+ if-level)))
	    ((looking-at "if\\b")
	     (setq if-level (1- if-level)))
	    ((< (point) limit)
	     (setq if-level 0)
	     (goto-char limit))))))

;;;*;;; Predefined indentation styles

(defun ess-set-style (&optional style)
  "Set up the ess-mode style variables from the ess-style variable or if
  STYLE argument is given, use that.  It makes the ESS indentation style
  variables buffer local."

  (interactive)

  (let ((ess-styles (mapcar 'car ess-style-alist)))

    (if (interactive-p)
	(setq style
	      (let ((style-string ; get style name with completion
		     (completing-read
		      (format "Set ESS mode indentation style to (default %s): "
			      ess-default-style)
		      (vconcat ess-styles)
		      (function (lambda (arg) (memq arg ess-styles)))
		      )))
		(if (string-equal "" style-string)
		    ess-default-style
		  (intern style-string))
		)))

    (setq style (or style ess-style)) ; use ess-style if style is nil

    (make-local-variable 'ess-style)
    (if (memq style ess-styles)
	(setq ess-style style)
      (error (concat "Bad ESS style: " style))
      )
    (message "ESS-style: %s" ess-style)

    ; finally, set the indentation style variables making each one local
    (mapcar (function (lambda (ess-style-pair)
			(make-local-variable (car ess-style-pair))
			(set (car ess-style-pair)
			     (cdr ess-style-pair))))
	    (cdr (assq ess-style ess-style-alist)))
    ess-style))

;;*;; Creating and manipulating dump buffers

;;;*;;; The user command

(defun ess-dump-object-into-edit-buffer (object)
  "Edit an ESS object in its own buffer.

Without a prefix argument, this simply finds the file pointed to by
ess-source-directory. If this file does not exist, or if a
prefix argument is given, a dump() command is sent to the ESS process to
generate the source buffer."
  (interactive
   (progn
     (require 'ess-inf)
     (ess-force-buffer-current "Process to dump from: ")
     (ess-read-object-name "Object to edit: ")))
  (let* ((dirname (file-name-as-directory
		   (if (stringp ess-source-directory)
		       ess-source-directory
		     (save-excursion
		       (set-buffer
			(process-buffer (get-ess-process
					 ess-local-process-name)))
		       (ess-setq-vars-local ess-customize-alist)
		       (apply ess-source-directory nil)))))
	 (filename (concat dirname (format ess-dump-filename-template object)))
	 (old-buff (get-file-buffer filename)))

    ;; If the directory doesn't exist, offer to create it
    (if (file-exists-p (directory-file-name dirname)) nil
      (if (y-or-n-p	; Approved
	   (format "Directory %s does not exist. Create it? " dirname))
	  (make-directory (directory-file-name dirname))
	(error "Directory %s does not exist." dirname)))

    ;; Three options:
    ;;  (1) Pop to an existing buffer containing the file in question
    ;;  (2) Find an existing file
    ;;  (3) Create a new file by issuing a dump() command to S
    ;; Force option (3) if there is a prefix arg

    (if current-prefix-arg
	(ess-dump-object object filename)
      (if old-buff
	  (progn
	    (pop-to-buffer old-buff)
	    (message "Popped to edit buffer."))
	;; No current buffer containing desired file
	(if (file-exists-p filename)
	    (progn
	      (ess-find-dump-file-other-window filename)
	      (message "Read %s" filename))
	  ;; No buffer and no file
	  (ess-dump-object object filename))))))

(defun ess-dump-object (object filename)
  "Dump the ESS object OBJECT into file FILENAME."
  (let ((complete-dump-command (format inferior-ess-dump-command
				       object filename)))
    (if (file-writable-p filename) nil
      (error "Can't dump %s as %f is not writeable." object filename))

    ;; Make sure we start fresh
    (if (get-file-buffer filename)
	(or (kill-buffer (get-file-buffer filename))
	    (error "Aborted.")))

    (ess-command complete-dump-command)
    (message "Dumped in %s" filename)

    (ess-find-dump-file-other-window filename)

    ;; PD, 1Apr97
    ;;This ensures that the object gets indented according to ess-mode,
    ;;not as the R/S deparser does it. At the same time, it gets rid
    ;;of the mess generated by sending TAB characters to the readline
    ;;functions in R when you eval-buffer-*.
    (indent-region (point-min-marker) (point-max-marker) nil)

    ;; Don't make backups for temporary files; it only causes clutter.
    ;; The ESS object itself is a kind of backup, anyway.
    (if ess-keep-dump-files nil
      (make-local-variable 'make-backup-files)
      (setq make-backup-files nil))

    ;; Don't get confirmation to delete dumped files when loading
    (if (eq ess-keep-dump-files 'check)
	(setq ess-keep-dump-files nil))

    ;; Delete the file if necessary
    (if ess-delete-dump-files
	(delete-file (buffer-file-name)))))

(defun ess-find-dump-file-other-window (filename)
  "Find ESS source file FILENAME in another window."

  (if (file-exists-p filename) nil
    (ess-write-to-dribble-buffer
     (format "%s does not exist. Bad dump, starting fresh." filename)))

  ;; Generate a buffer with the dumped data
  (find-file-other-window filename)
  (ess-mode ess-customize-alist)

  (auto-save-mode 1)		; Auto save in this buffer
  (setq ess-local-process-name ess-current-process-name)

  (if ess-function-template
      (progn
	(goto-char (point-max))
	(if (re-search-backward ess-dumped-missing-re nil t)
	    (progn
	      (replace-match ess-function-template t t)
	      (set-buffer-modified-p nil) ; Don't offer to save if killed now
	      (goto-char (point-min))
	      (condition-case nil
		  ;; This may fail if there are no opens
		  (down-list 1)
		(error nil)))))))


;; AJR: XEmacs, makes sense to dump into "other frame".

(defun ess-dump-object-into-edit-buffer-other-frame (object)
  "Edit an ESS object in its own frame."
  (switch-to-buffer-other-frame (ess-dump-object-into-edit-buffer object)))



(provide 'ess-mode)

 ; Local variables section

;;; This file is automatically placed in Outline minor mode.
;;; The file is structured as follows:
;;; Chapters:     ^L ;
;;; Sections:    ;;*;;
;;; Subsections: ;;;*;;;
;;; Components:  defuns, defvars, defconsts
;;;              Random code beginning with a ;;;;* comment

;;; Local variables:
;;; mode: emacs-lisp
;;; outline-minor-mode: nil
;;; mode: outline-minor
;;; outline-regexp: "\^L\\|\\`;\\|;;\\*\\|;;;\\*\\|(def[cvu]\\|(setq\\|;;;;\\*"
;;; End:

;;; ess-mode.el ends here

