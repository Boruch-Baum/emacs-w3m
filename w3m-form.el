;;; w3m-form.el --- Stuffs to handle <form> tag.

;; Copyright (C) 2001 TSUCHIYA Masatoshi <tsuchiya@namazu.org>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@namazu.org>,
;;          Yuuichi Teranishi  <teranisi@gohome.org>,
;;          Hideyuki SHIRAI    <shirai@meadowy.org>,
;;          Shun-ichi GOTO     <gotoh@taiyo.co.jp>,
;;          Akihiro Arisawa    <ari@atesoft.advantest.co.jp>
;; Keywords: w3m, WWW, hypermedia

;; This file is a part of emacs-w3m.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, you can either send email to this
;; program's maintainer or write to: The Free Software Foundation,
;; Inc.; 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.


;;; Commentary:

;; This file contains the stuffs to handle <form> tag on emacs-w3m.
;; For more detail about emacs-w3m, see:
;;
;;    http://emacs-w3m.namazu.org/


;;; Code:

(require 'w3m)

(defface w3m-form-face
  '((((class color) (background light)) (:foreground "cyan" :underline t))
    (((class color) (background dark)) (:foreground "red" :underline t))
    (t (:underline t)))
  "*Face to fontify forms."
  :group 'w3m-face)

(defvar w3m-current-forms nil "Forms of this buffer.")
(make-variable-buffer-local 'w3m-current-forms)

(defcustom w3m-form-default-coding-system 'shift_jis
  "*Default coding system for form encoding."
  :group 'w3m
  :type 'coding-system)

;;; w3m-form structure:

(defun w3m-form-new (method action &optional baseurl charlst)
  "Return new form object."
  (vector 'w3m-form-object
	  (if (stringp method)
	      (intern method)
	    method)
	  (if baseurl
	      (w3m-expand-url action baseurl)
	    action)
	  charlst
	  nil))

(defsubst w3m-form-p (obj)
  "Return t if OBJ is a form object."
  (and (vectorp obj)
       (symbolp (aref 0 obj))
       (eq (aref 0 obj) 'w3m-form-object)))

(defmacro w3m-form-method (form)
  (` (aref (, form) 1)))
(defmacro w3m-form-action (form)
  (` (aref (, form) 2)))
(defmacro w3m-form-charlst (form)
  (` (aref (, form) 3)))
(defmacro w3m-form-plist (form)
  (` (aref (, form) 4)))
(defmacro w3m-form-put (form name value)
  (let ((tempvar (make-symbol "formobj")))
    (` (let (((, tempvar) (, form)))
	 (aset (, tempvar) 4
	       (plist-put (w3m-form-plist (, tempvar))
			  (intern (, name)) (, value)))))))
(defmacro w3m-form-get (form name)
  (` (plist-get (w3m-form-plist (, form)) (intern (, name)))))

(defun w3m-form-goto-next-field ()
  "Move to next form field and return the point.
If no field in forward, return nil without moving."
  (let* ((id (get-text-property (point) 'w3m-form-field-id))
	 (beg (if id
		  (next-single-property-change (point) 'w3m-form-field-id)
		(point)))
	 (next (next-single-property-change beg 'w3m-form-field-id)))
    (if next
	(goto-char next)
      nil)))

(defun w3m-form-make-form-urlencoded (form)
  (current-buffer)
  (let ((plist (w3m-form-plist form))
	(coding (w3m-form-charlst form))
	buf)
    (setq coding
	  (or (catch 'det
		(while coding
		  (if (w3m-charset-to-coding-system (car coding))
		      (throw 'det (w3m-charset-to-coding-system (car coding)))
		    (setq coding (cdr coding)))))
	      (w3m-charset-to-coding-system
	       (w3m-content-charset w3m-current-url))
	      w3m-form-default-coding-system))
    (while plist
      (let ((name (symbol-name (car plist)))
	    (value (cadr plist)))
	(cond
	 ((and (consp value)
	       (consp (cdr value))
	       (consp (cadr value)))	; select.
	  (setq buf (cons (cons name (car value)) buf)))
	 ((consp value)			; checkbox
	  (setq buf (append (mapcar (lambda (x) (cons name x)) value)
			    buf)))
	 (value
	  (setq buf (cons (cons name value) buf))))
	(setq plist (cddr plist))))
    (when buf
      (mapconcat (lambda (elem)
		   (format "%s=%s" 
			   (w3m-url-encode-string (car elem) coding)
			   (w3m-url-encode-string (cdr elem) coding)))
		 buf "&"))))

;;;###autoload
(defun w3m-form-parse-region (start end &optional charset)
  "Parse HTML data in this buffer and return form/map objects."
  (save-restriction
    (narrow-to-region start end)
    (let (forms str)
      (if (memq w3m-type '(w3mmee w3m-m17n))
	  ;; *w3m-work* buffer is 'binary.
	  (let ((str (buffer-string)))
	    (with-temp-buffer
	      (insert str)
	      (goto-char (point-min))
	      (when (and (eq w3m-type 'w3mmee)
			 (or (re-search-forward
			      w3m-meta-content-type-charset-regexp nil t)
			     (re-search-forward
			      w3m-meta-charset-content-type-regexp nil t))
			 (string= "x-moe-internal"
				  (downcase
				   (match-string-no-properties 2))))
		(setq charset (w3m-x-moe-decode-buffer)))
	      (decode-coding-region (point-min) (point-max)
				    (or (w3m-charset-to-coding-system charset)
					'undecided))
	      (setq forms (w3m-form-parse-forms))))
	(setq forms (w3m-form-parse-forms)))
      (save-current-buffer
	(when (or (bufferp w3m-current-buffer)
		  (stringp w3m-current-buffer))
	  (set-buffer w3m-current-buffer))
	(setq w3m-current-forms (nreverse forms))))))

(defun w3m-form-parse-forms ()
  "Parse Form/usemap objects in this buffer."
  (let ((case-fold-search t)
	forms tag)
    (goto-char (point-min))
    (while (re-search-forward (w3m-tag-regexp-of "form" "img") nil t)
      (setq tag (downcase (match-string 1)))
      (goto-char (match-end 1))
      (cond
       ((string= tag "img")
	;; Parse USEMAP property of IMG tag
	(w3m-parse-attributes (usemap)
	  (when usemap
	    (if (not (string-match "^#" usemap))
		(setq forms (cons nil forms)) ;; Sure ?
	      (setq usemap (substring usemap 1))
	      (setq forms
		    (cons (w3m-form-new "map"
					usemap
					w3m-current-url
					nil)
			  forms))
	      (save-excursion
		(goto-char (point-min))
		(let (candidates)
		  (when (re-search-forward
			 (concat "<map +name=\"" usemap "\"[^>]*>") nil t)
		    (while (and (re-search-forward
				 (w3m-tag-regexp-of "area" "/map") nil t)
				(not (char-equal (char-after (match-beginning 1)) ?/)))
		      (goto-char (match-end 1))
		      (w3m-parse-attributes (href alt)
			(when href
			  (setq candidates (cons (cons href (or alt href)) candidates)))))
		    (when candidates
		      (w3m-form-put (car forms)
				    "link"
				    (nreverse candidates))))))))))
       (t
	;; Parse attribute of FORM tag
	;; accept-charset <= charset,charset,...
	;; charset <= valid only w3mmee with frame
	(w3m-parse-attributes (action (method :case-ignore)
				      (accept-charset :case-ignore)
				      (charset :case-ignore))
	  (if accept-charset
	      (setq accept-charset (split-string accept-charset ","))
	    (when (and charset (eq w3m-type 'w3mmee))
	      (cond
	       ((string= charset "e")	;; w3mee without libmoe
		(setq accept-charset (list "euc-jp")))
	       ((string= charset "s")	;; w3mee without libmoe
		(setq accept-charset (list "shift-jis")))
	       ((string= charset "n")	;; w3mee without libmoe
		(setq accept-charset (list "iso-2022-7bit")))
	       (t				;; w3mee with libmoe
		(setq accept-charset (list charset))))))
	  (setq forms
		(cons (w3m-form-new (or method "get")
				    (or action w3m-current-url)
				    w3m-current-url
				    accept-charset)
		    forms)))
	;; Parse form fields until </FORM>
	(while (and (re-search-forward 
		     (w3m-tag-regexp-of "input" "textarea" "select" "/form")
		     nil t)
		    (not (char-equal (char-after (match-beginning 1)) ?/)))
	  (setq tag (downcase (match-string 1)))
	  (goto-char (match-end 1))	; go to end of tag name
	  (cond
	   ((string= tag "input") 
	    ;; When <INPUT> is found.
	    (w3m-parse-attributes (name value (type :case-ignore)
					(checked :bool))
	      (when name
		(cond
		 ((string= type "submit")
		  ;; Submit button input, not set name and value here.
		  ;; They are set in `w3m-form-submit'.
		  nil)
		 ((string= type "checkbox")
		  ;; Check box input, one name has multiple values
		  ;; Value is list of item VALUE which has same NAME.
		  (let ((cvalue (w3m-form-get (car forms) name)))
		    (w3m-form-put (car forms) name
				  (if checked
				      (cons value cvalue)
				    cvalue))))
		 ((string= type "radio")
		  ;; Radio button input, one name has one value
		  (w3m-form-put (car forms) name
				(if checked value
				  (w3m-form-get (car forms) name))))
		 (t
		  ;; ordinaly text input
		  (w3m-form-put (car forms)
				name
				(or value (w3m-form-get (car forms) name))))))))
	   ((string= tag "textarea")
	    ;; When <TEXTAREA> is found.
	    (w3m-parse-attributes (name)
	      (let ((start (point))
		    value)
		(setq value (buffer-substring start (point)))
		(when name
		  (w3m-form-put (car forms)
				name
				(or value (w3m-form-get (car forms) name)))))))
	   ;; When <SELECT> is found.
	   ((string= tag "select")
	    (let (vbeg svalue cvalue candidates)
	      (goto-char (match-end 1)) 
	      (w3m-parse-attributes (name)
		;; Parse FORM SELECT fields until </SELECT> (or </FORM>)
		(while (and (re-search-forward 
			     (w3m-tag-regexp-of "option" "/select" "/form")
			     nil t)
			    (not (char-equal (char-after (match-beginning 1)) ?/)))
		  ;; <OPTION> is found
		  (goto-char (match-end 1)) ; goto very after "<xxxx"
		  
		  (w3m-parse-attributes (value (selected :bool))
		    (setq vbeg (point))
		    (skip-chars-forward "^<")
		    (setq svalue
			  (mapconcat 'identity
				     (split-string
				      (buffer-substring vbeg (point)) "\n")
				     ""))
		    (if selected (setq cvalue value))
		    (setq candidates (cons (cons value svalue)
					   candidates))))
		(when name
		  (w3m-form-put (car forms) name (cons
						  cvalue ; current value
						  (nreverse
						   candidates))))))))))))
    forms))

;;;###autoload
(defun w3m-fontify-forms ()
  "Process half-dumped data in this buffer and fontify <input_alt> tags."
  (goto-char (point-min))
  (while (search-forward "<input_alt " nil t)
    (let (start)
      (setq start (match-beginning 0))
      (goto-char (match-end 0))
      (w3m-parse-attributes ((fid :integer)
			     (type :case-ignore)
			     (width :integer)
			     (maxlength :integer)
			     name value)
	(search-forward "</input_alt>")
	(goto-char (match-end 0))
	(let ((form (nth fid w3m-current-forms)))
	  (when form
	    (cond
	     ((and (string= type "hidden")
		   (string= name "link"))
	      (add-text-properties start (point)
				   (list 'face 'w3m-form-face
					 'w3m-action
					 `(w3m-form-input-map ,form ,name)
					 'w3m-cursor-anchor
					 `(w3m-form-input-map ,form ,name))))
	     ((string= type "submit")
	      (add-text-properties start (point)
				   (list 'face 'w3m-form-face
					 'w3m-action
					 `(w3m-form-submit ,form ,name ,value)
					 'w3m-submit
					 `(w3m-form-submit ,form ,name
							   (w3m-form-get ,form ,name))
					 'w3m-cursor-anchor
					 `(w3m-form-submit ,form))))
	     ((string= type "reset")
	      (add-text-properties start (point)
				   (list 'face 'w3m-form-face
					 'w3m-action
					 `(w3m-form-reset ,form)
					 'w3m-cursor-anchor
					 `(w3m-form-reset ,form))))
	     ((string= type "textarea")
	      (add-text-properties start (point)
				   (list 'face 'w3m-form-face
					 'w3m-action
					 `(w3m-form-input-textarea ,form ,name)
					 'w3m-submit
					 `(w3m-form-submit ,form ,name
							   (w3m-form-get ,form ,name))
					 'w3m-cursor-anchor
					 `(w3m-form-input-textarea ,form ,name))))
	     ((string= type "select")
	      (add-text-properties start (point)
				   (list 'face 'w3m-form-face
					 'w3m-action
					 `(w3m-form-input-select ,form ,name)
					 'w3m-submit
					 `(w3m-form-submit ,form ,name
							   (w3m-form-get ,form ,name))
					 'w3m-cursor-anchor
					 `(w3m-form-input-select ,form ,name))))
	     ((string= type "password")
	      (add-text-properties start (point)
				   (list 'face 'w3m-form-face
					 'w3m-action
					 `(w3m-form-input-password ,form ,name)
					 'w3m-submit
					 `(w3m-form-submit ,form ,name
							   (w3m-form-get ,form ,name))
					 'w3m-cursor-anchor
					 `(w3m-form-input-password ,form ,name))))
	     ((string= type "checkbox")
	      (add-text-properties start (point)
				   (list 'face 'w3m-form-face
					 'w3m-action
					 `(w3m-form-input-checkbox ,form ,name ,value)
					 'w3m-submit
					 `(w3m-form-submit ,form ,name
							   (w3m-form-get ,form ,name))
					 'w3m-cursor-anchor
					 `(w3m-form-input-checkbox ,form ,name ,value))))
	     ((string= type "radio")
	      (add-text-properties start (point)
				   (list 'face 'w3m-form-face
					 'w3m-action
					 `(w3m-form-input-radio ,form ,name ,value)
					 'w3m-submit
					 `(w3m-form-submit ,form ,name
							   (w3m-form-get ,form ,name))
					 'w3m-cursor-anchor
					 `(w3m-form-input-radio ,form ,name ,value))))
	     (t ;; input button.
	      (add-text-properties start (point)
				   (list 'face 'w3m-form-face
					 'w3m-action
					 `(w3m-form-input ,form
							  ,name
							  ,type
							  ,width
							  ,maxlength
							  ,value)
					 'w3m-submit
					 `(w3m-form-submit ,form ,name
							   (w3m-form-get ,form ,name))
					 'w3m-cursor-anchor
					 `(w3m-form-input ,form
							  ,name
							  ,type
							  ,width
							  ,maxlength
							  ,value)))))))
	(put-text-property start (point) 
			   'w3m-form-field-id
			   (format "fid=%d/type=%s/name=%s" fid type name))))))

(defun w3m-form-replace (string &optional invisible)
  (save-excursion
    (let* ((start (text-property-any
		   (point-min)
		   (point-max)
		   'w3m-action
		   (get-text-property (point) 'w3m-action)))
	   (width (string-width
		   (buffer-substring
		    start
		    (next-single-property-change start 'w3m-action))))
	   (prop (text-properties-at start))
	   (buffer-read-only))
      (goto-char start)
      (insert (setq string
		    (if invisible
			(make-string (length string) ?.)
		      (mapconcat 'identity 
				 (split-string
				  (truncate-string string width) "\n")
				 "")))
	      (make-string (- width (string-width string)) ?\ ))
      (delete-region (point)
		     (next-single-property-change (point) 'w3m-action))
      (add-text-properties start (point) prop)
      (point))))

(defun w3m-form-input (form name type width maxlength value)
  (save-excursion
    (let* ((fvalue (w3m-form-get form name))
	   (input (read-from-minibuffer (concat (upcase type) ": ") fvalue)))
      (w3m-form-put form name input)
      (w3m-form-replace input))))

(defun w3m-form-input-password (form name)
  (let* ((fvalue (w3m-form-get form name))
	 (input (read-passwd (concat "PASSWORD"
				     (if fvalue
					 " (default is no change)")
				     ": ")
			     nil
			     fvalue)))
    (w3m-form-put form name input)
    (w3m-form-replace input 'invisible)))

(defun w3m-form-input-checkbox (form name value)
  (let ((fvalue (w3m-form-get form name)))
    (if (member value fvalue)		; already checked
	(progn
	  (w3m-form-put form name (delete value fvalue))
	  (w3m-form-replace " "))
      (w3m-form-put form name (cons value fvalue))
      (w3m-form-replace "*"))))

(defun w3m-form-input-radio (form name value)
  ;; Uncheck all RADIO input having same NAME
  (save-excursion
    (let ((id (get-text-property (point) 'w3m-form-field-id)))
      (goto-char 1)
      (while (w3m-form-goto-next-field)
	(if (string= id (get-text-property (point) 'w3m-form-field-id))
	    (w3m-form-replace " "))))) ; erase check
  ;; Then set this field as checked.
  (w3m-form-put form name value)
  (w3m-form-replace "*"))


;;; TEXTAREA

(defcustom w3m-form-input-textarea-buffer-lines 10
  "*Buffer lines for form textarea buffer."
  :group 'w3m
  :type 'integer)

(defcustom w3m-form-input-textarea-mode-hook nil
  "*A hook called after w3m-form-input-textarea-mode."
  :group 'w3m
  :type 'hook)

(defcustom w3m-form-input-textarea-set-hook nil
  "*A Hook called before w3m-form-input-textarea-set."
  :group 'w3m
  :type 'hook)

(defvar w3m-form-input-textarea-keymap nil)
(unless w3m-form-input-textarea-keymap
  (setq w3m-form-input-textarea-keymap (make-sparse-keymap))
  (define-key w3m-form-input-textarea-keymap "\C-c\C-c"
    'w3m-form-input-textarea-set))
(defvar w3m-form-input-textarea-buffer nil)
(defvar w3m-form-input-textarea-form nil)
(defvar w3m-form-input-textarea-name nil)
(defvar w3m-form-input-textarea-point nil)
(defvar w3m-form-input-textarea-wincfg nil)
(make-variable-buffer-local 'w3m-form-input-textarea-buffer)
(make-variable-buffer-local 'w3m-form-input-textarea-form)
(make-variable-buffer-local 'w3m-form-input-textarea-name)
(make-variable-buffer-local 'w3m-form-input-textarea-point)
(make-variable-buffer-local 'w3m-form-input-textarea-wincfg)

(defun w3m-form-input-textarea-set ()
  "Save and exit from w3m form textarea mode."
  (interactive)
  (run-hooks 'w3m-form-input-textarea-set-hook)
  (let ((input (buffer-string))
	(buffer (current-buffer))
	(name w3m-form-input-textarea-name)
	(form w3m-form-input-textarea-form)
	(point w3m-form-input-textarea-point)
	(w3mbuffer w3m-form-input-textarea-buffer)
	(wincfg w3m-form-input-textarea-wincfg))
    (when (buffer-live-p w3mbuffer)
      (or (one-window-p) (delete-window))
      (kill-buffer buffer)
      (pop-to-buffer w3mbuffer)
      (set-window-configuration wincfg)
      (when (and form point)
	(goto-char point)
	(w3m-form-put form name input)
	(w3m-form-replace input)))))

(defun w3m-form-input-textarea-mode ()
  "Major mode for w3m form textarea."
  (setq mode-name "w3m form textarea"
	major-mode 'w3m-form-input-textarea-mode)
  (use-local-map w3m-form-input-textarea-keymap)
  (run-hooks 'w3m-form-input-textarea-mode-hook))

(defun w3m-form-input-textarea (form name)
  (let* ((value (w3m-form-get form name))
	 (cur-win (selected-window))
	 (wincfg (current-window-configuration))
	 (w3mbuffer (current-buffer))
	 (point (point))
	 (size (min
		(- (window-height cur-win)
		   window-min-height 1)
		(- (window-height cur-win)
		   (max window-min-height
			(1+ w3m-form-input-textarea-buffer-lines)))))
	 (buffer (generate-new-buffer "*w3m form textarea*")))
    (condition-case nil
	(split-window cur-win (if (> size 0) size window-min-height))
      (error
       (delete-other-windows)
       (split-window cur-win (- (window-height cur-win)
				w3m-form-input-textarea-buffer-lines))))
    (select-window (next-window))
    (let ((pop-up-windows nil))
      (switch-to-buffer buffer)
      (set-buffer buffer)
      (setq w3m-form-input-textarea-form form)
      (setq w3m-form-input-textarea-name name)      
      (setq w3m-form-input-textarea-buffer w3mbuffer)
      (setq w3m-form-input-textarea-point point)
      (setq w3m-form-input-textarea-wincfg wincfg)
      (if value (insert value))
      (goto-char (point-min))
      (w3m-form-input-textarea-mode))))

;;; SELECT

(defcustom w3m-form-input-select-buffer-lines 10
  "*Buffer lines for form select buffer."
  :group 'w3m
  :type 'integer)

(defcustom w3m-form-input-select-mode-hook nil
  "*A hook called after w3m-form-input-select-mode."
  :group 'w3m
  :type 'hook)

(defcustom w3m-form-input-select-set-hook nil
  "*A Hook called before w3m-form-input-select-set."
  :group 'w3m
  :type 'hook)

(defcustom w3m-form-mouse-face 'highlight
  "*Mouse face to highlight selected value."
  :group 'w3m
  :type 'face)

(defvar w3m-form-input-select-keymap nil)
(unless w3m-form-input-select-keymap
  (setq w3m-form-input-select-keymap (make-sparse-keymap))
  (define-key w3m-form-input-select-keymap "\C-c\C-c"
    'w3m-form-input-select-set)
  (define-key w3m-form-input-select-keymap "\r"
    'w3m-form-input-select-set)
  (define-key w3m-form-input-select-keymap "\C-m"
    'w3m-form-input-select-set)
  (if (featurep 'xemacs)
      (define-key w3m-form-input-select-keymap [(button2)]
	'w3m-form-input-select-set-mouse)
    (define-key w3m-form-input-select-keymap [mouse-2]
      'w3m-form-input-select-set-mouse)))
(defvar w3m-form-input-select-buffer nil)
(defvar w3m-form-input-select-form nil)
(defvar w3m-form-input-select-name nil)
(defvar w3m-form-input-select-point nil)
(defvar w3m-form-input-select-candidates nil)
(defvar w3m-form-input-select-wincfg nil)
(make-variable-buffer-local 'w3m-form-input-select-buffer)
(make-variable-buffer-local 'w3m-form-input-select-form)
(make-variable-buffer-local 'w3m-form-input-select-name)
(make-variable-buffer-local 'w3m-form-input-select-point)
(make-variable-buffer-local 'w3m-form-input-select-candidates)
(make-variable-buffer-local 'w3m-form-input-select-wincfg)

(defun w3m-form-input-select-set-mouse (event)
  (interactive "e")
  (mouse-set-point event)
  (w3m-form-input-select-set))

(defun w3m-form-input-select-set ()
  "Save and exit from w3m form select mode."
  (interactive)
  (run-hooks 'w3m-form-input-select-set-hook)
  (let* ((cur (get-text-property (point)
				 'w3m-form-select-value))
	 (buffer (current-buffer))
	 (name w3m-form-input-select-name)
	 (form w3m-form-input-select-form)
	 (point w3m-form-input-select-point)
	 (w3mbuffer w3m-form-input-select-buffer)
	 (wincfg w3m-form-input-select-wincfg)
	 input)
    (setcar w3m-form-input-select-candidates cur)
    (setq input w3m-form-input-select-candidates)
    (when (buffer-live-p w3mbuffer)
      (or (one-window-p) (delete-window))
      (kill-buffer buffer)
      (pop-to-buffer w3mbuffer)
      (set-window-configuration wincfg)
      (when (and form point)
	(goto-char point)
	(w3m-form-put form name input)
	(w3m-form-replace (cdr (assoc cur (cdr input))))))))

(defun w3m-form-input-select-mode ()
  "Major mode for w3m form select."
  (setq mode-name "w3m form select"
	major-mode 'w3m-form-input-select-mode)
  (setq buffer-read-only t)
  (use-local-map w3m-form-input-select-keymap)
  (run-hooks 'w3m-form-input-select-mode-hook))

(defun w3m-form-input-select (form name)
  (let* ((value (w3m-form-get form name))
	 (cur-win (selected-window))
	 (wincfg (current-window-configuration))
	 (w3mbuffer (current-buffer))
	 (point (point))
	 (size (min
		(- (window-height cur-win)
		   window-min-height 1)
		(- (window-height cur-win)
		   (max window-min-height
			(1+ w3m-form-input-select-buffer-lines)))))
	 (buffer (generate-new-buffer "*w3m form select*"))
	 cur pos)
    (condition-case nil
	(split-window cur-win (if (> size 0) size window-min-height))
      (error
       (delete-other-windows)
       (split-window cur-win (- (window-height cur-win)
				w3m-form-input-select-buffer-lines))))
    (select-window (next-window))
    (let ((pop-up-windows nil))
      (switch-to-buffer buffer)
      (set-buffer buffer)
      (setq w3m-form-input-select-form form)
      (setq w3m-form-input-select-name name)      
      (setq w3m-form-input-select-buffer w3mbuffer)
      (setq w3m-form-input-select-point point)
      (setq w3m-form-input-select-candidates value)
      (setq w3m-form-input-select-wincfg wincfg)
      (when value
	(setq cur (car value))
	(setq value (cdr value))
	(dolist (candidate value)
	  (setq pos (point))
	  (insert (cdr candidate))
	  (add-text-properties pos (point)
			       (list 'w3m-form-select-value (car candidate)
				     'mouse-face w3m-form-mouse-face))
	  (insert "\n")))
      (goto-char (point-min))
      (while (and (not (eobp))
		  (not (equal cur (get-text-property (point)
						     'w3m-form-select-value))))
	(goto-char (next-single-property-change (point)
						'w3m-form-select-value)))
      (set-buffer-modified-p nil)
      (beginning-of-line)
      (w3m-form-input-select-mode))))


;;; MAP

(defcustom w3m-form-input-map-buffer-lines 10
  "*Buffer lines for form select map buffer."
  :group 'w3m
  :type 'integer)

(defcustom w3m-form-input-map-mode-hook nil
  "*A hook called after w3m-form-input-map-mode."
  :group 'w3m
  :type 'hook)

(defcustom w3m-form-input-map-set-hook nil
  "*A Hook called before w3m-form-input-map-set."
  :group 'w3m
  :type 'hook)

(defvar w3m-form-input-map-keymap nil)
(unless w3m-form-input-map-keymap
  (setq w3m-form-input-map-keymap (make-sparse-keymap))
  (define-key w3m-form-input-map-keymap "\C-c\C-c"
    'w3m-form-input-map-set)
  (define-key w3m-form-input-map-keymap "\r"
    'w3m-form-input-map-set)
  (define-key w3m-form-input-map-keymap "\C-m"
    'w3m-form-input-map-set)
  (if (featurep 'xemacs)
      (define-key w3m-form-input-map-keymap [(button2)]
	'w3m-form-input-map-set-mouse)
    (define-key w3m-form-input-map-keymap [mouse-2]
      'w3m-form-input-map-set-mouse)))
(defvar w3m-form-input-map-buffer nil)
(defvar w3m-form-input-map-wincfg nil)
(make-variable-buffer-local 'w3m-form-input-map-buffer)
(make-variable-buffer-local 'w3m-form-input-map-wincfg)

(defun w3m-form-input-map-set-mouse (event)
  (interactive "e")
  (mouse-set-point event)
  (w3m-form-input-map-set))

(defun w3m-form-input-map-set ()
  "Save and exit from w3m form select mode."
  (interactive)
  (run-hooks 'w3m-form-input-map-set-hook)
  (let* ((map (get-text-property (point) 'w3m-form-map-value))
	 (buffer (current-buffer))
	 (w3mbuffer w3m-form-input-map-buffer)
	 (wincfg w3m-form-input-map-wincfg)
	 input)
    (when (buffer-live-p w3mbuffer)
      (or (one-window-p) (delete-window))
      (kill-buffer buffer)
      (pop-to-buffer w3mbuffer)
      (set-window-configuration wincfg)
      (w3m-goto-url (w3m-expand-url map w3m-current-url)))))

(defun w3m-form-input-map-mode ()
  "Major mode for w3m map select."
  (setq mode-name "w3m map select"
	major-mode 'w3m-form-input-map-mode)
  (setq buffer-read-only t)
  (use-local-map w3m-form-input-map-keymap)
  (run-hooks 'w3m-form-input-map-mode-hook))

(defun w3m-form-input-map (form name)
  (let* ((value (w3m-form-get form name))
	 (cur-win (selected-window))
	 (wincfg (current-window-configuration))
	 (w3mbuffer (current-buffer))
	 (size (min
		(- (window-height cur-win)
		   window-min-height 1)
		(- (window-height cur-win)
		   (max window-min-height
			(1+ w3m-form-input-map-buffer-lines)))))
	 (buffer (generate-new-buffer "*w3m map select*"))
	 cur pos)
    (condition-case nil
	(split-window cur-win (if (> size 0) size window-min-height))
      (error
       (delete-other-windows)
       (split-window cur-win (- (window-height cur-win)
				w3m-form-input-map-buffer-lines))))
    (select-window (next-window))
    (let ((pop-up-windows nil))
      (switch-to-buffer buffer)
      (set-buffer buffer)
      (setq w3m-form-input-map-buffer w3mbuffer)
      (setq w3m-form-input-map-wincfg wincfg)
      (when value
	(dolist (candidate value)
	  (setq pos (point))
	  (insert (cdr candidate))
	  (add-text-properties pos (point)
			       (list 'w3m-form-map-value (car candidate)
				     'mouse-face w3m-form-mouse-face))
	  (insert "\n")))
      (goto-char (point-min))
      (set-buffer-modified-p nil)
      (beginning-of-line)
      (w3m-form-input-map-mode))))

;;; 

(defun w3m-form-submit (form &optional name value)
  (when (and name (not (zerop (length name))))
    (w3m-form-put form name value))
  (let ((url (cond ((w3m-form-action form)
		    (w3m-expand-url (w3m-form-action form) w3m-current-url))
		   ((string-match "\\?" w3m-current-url)
		    (substring w3m-current-url 0 (match-beginning 0)))
		   (t w3m-current-url))))
    (cond ((eq 'get (w3m-form-method form))
	   (w3m-goto-url
	    (concat url "?" (w3m-form-make-form-urlencoded form))))
	  ((eq 'post (w3m-form-method form))
	   (w3m-goto-url url 'reload nil
			 (w3m-form-make-form-urlencoded form)))
	  (t
	   (w3m-message "This form's method has not been supported: %s"
			(let (print-level print-length)
			  (prin1-to-string (w3m-form-method form))))))))

(defsubst w3m-form-real-reset (form sexp)
  (and (eq 'w3m-form-input (car sexp))
       (eq form (nth 1 sexp))
       (w3m-form-put form (nth 2 sexp) (nth 6 sexp))
       (w3m-form-replace (nth 6 sexp))))

(defun w3m-form-reset (form)
  (save-excursion
    (let (pos prop)
      (when (setq prop (get-text-property
			(goto-char (point-min))
			'w3m-action))
	(goto-char (or (w3m-form-real-reset form prop)
		       (next-single-property-change pos 'w3m-action))))
      (while (setq pos (next-single-property-change (point) 'w3m-action))
	(goto-char pos)
	(goto-char (or (w3m-form-real-reset form (get-text-property pos 'w3m-action))
		       (next-single-property-change pos 'w3m-action)))))))


(provide 'w3m-form)
;;; w3m-form.el ends here.
