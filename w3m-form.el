;;; w3m-form.el --- Stuffs to handle <form> tag

;; Copyright (C) 2001, 2002, 2003, 2004
;; TSUCHIYA Masatoshi <tsuchiya@namazu.org>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@namazu.org>,
;;          Yuuichi Teranishi  <teranisi@gohome.org>,
;;          Hideyuki SHIRAI    <shirai@meadowy.org>,
;;          Shun-ichi GOTO     <gotoh@taiyo.co.jp>,
;;          Akihiro Arisawa    <ari@mbf.sphere.ne.jp>
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

(eval-when-compile
  (require 'cl))

(require 'w3m-util)
(require 'w3m)

(eval-when-compile
  (defvar w3m-current-forms))

(defcustom w3m-form-use-fancy-faces t
  "*Use fancy faces to fontify <form> tags."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-form-treat-textarea-size t
  "*Non-nil means to process textarea size (treat textarea rows)."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-form-use-textarea-backup t
  "*Use automatic backup file of textarea input."
  :group 'w3m
  :type 'boolean)

(defcustom w3m-form-textarea-directory
  (expand-file-name ".textarea" w3m-profile-directory)
  "*Name of the directory to save the file of textarea input."
  :group 'w3m
  :type '(directory :size 0))

(defface w3m-form-face
  '((((class color) (background light)) (:foreground "cyan" :underline t))
    (((class color) (background dark)) (:foreground "red" :underline t))
    (t (:underline t)))
  "*Face to fontify forms."
  :group 'w3m-face)

;;; w3m-form structure:

(defsubst w3m-form-normalize-action (action url)
  "Normalize the ACTION using URL as a current URL."
  ;; "!CURRENT_URL!" is magic string of w3m.
  (if (and action (not (string= action "!CURRENT_URL!")))
      (w3m-expand-url action url)
    (and url
	 (string-match w3m-url-components-regexp url)
	 (substring url 0 (or (match-beginning 6)
			      (match-beginning 8))))))

(defun w3m-form-new (method action &optional baseurl charlst enctype)
  "Return new form object."
  (vector 'w3m-form-object
	  (if (stringp method)
	      (intern method)
	    method)
	  action
	  charlst
	  (or enctype 'application/x-www-form-urlencoded)
	  nil))

(defsubst w3m-form-p (obj)
  "Return t if OBJ is a form object."
  (and (vectorp obj)
       (symbolp (aref 0 obj))
       (eq (aref 0 obj) 'w3m-form-object)))

(defsubst w3m-form-set-method (form method)
  (aset form 1 (if (stringp method)
		   (intern method)
		 method)))
(defsetf w3m-form-method w3m-form-set-method)

(defmacro w3m-form-method (form)
  (` (aref (, form) 1)))
(defmacro w3m-form-action (form)
  (` (aref (, form) 2)))
(defmacro w3m-form-charlst (form)
  (` (aref (, form) 3)))
(defmacro w3m-form-enctype (form)
  (` (aref (, form) 4)))
(defmacro w3m-form-plist (form)
  (` (aref (, form) 5)))
(defsubst w3m-form-put-property (form name property value)
  (aset form 5
	(plist-put (w3m-form-plist form)
		   (setq name (if (stringp name) (intern name) name))
		   (plist-put (plist-get (w3m-form-plist form) name)
			      property value)))
  value)
(defmacro w3m-form-get-property (form name property)
  (` (plist-get (plist-get (w3m-form-plist (, form))
			   (if (stringp (, name))
			       (intern (, name))
			     (, name)))
		(, property))))
(defmacro w3m-form-put (form id name value)
  (` (w3m-form-put-property (, form) (, id) :value (cons (, name) (, value)))))
(defmacro w3m-form-get (form id)
  (` (cdr (w3m-form-get-property (, form) (, id) :value))))
(defun w3m-form-get-by-name (form name)
  (let ((plist (w3m-form-plist form))
	pair value)
    (while plist
      (setq pair (plist-get (cadr plist) :value))
      (when (and pair
		 (string= (car pair) name))
	(setq value (cdr pair)
	      plist nil))
      (setq plist (cddr plist)))
    value))
(defun w3m-form-put-by-name (form id name value)
  (let ((plist (w3m-form-plist form))
	pair found)
    (while plist
      (setq pair (plist-get (cadr plist) :value))
      (when (and pair
		 (string= (car pair) name))
	(setcar plist id)
	(setcdr pair value)
	(setq found t
	      plist nil))
      (setq plist (cddr plist)))
    (unless found
      (w3m-form-put form id name value))))

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

(defun w3m-form-get-coding-system (coding)
  (or (catch 'det
	(while coding
	  (if (w3m-charset-to-coding-system (car coding))
	      (throw 'det (w3m-charset-to-coding-system (car coding)))
	    (setq coding (cdr coding)))))
      w3m-current-coding-system
      (w3m-charset-to-coding-system
       (w3m-content-charset w3m-current-url))
      w3m-default-coding-system))

(defun w3m-form-make-form-data (form)
  (let ((plist (w3m-form-plist form))
	(coding (w3m-form-charlst form))
	buf bufs)
    (setq coding (w3m-form-get-coding-system coding))
    (while plist
      (let* ((number (car plist))
	     (pair (plist-get (cadr plist) :value))
	     (name (car pair))
	     (value (cdr pair)))
	(cond
	 ((and (consp value)
	       (eq (car value) 'file))
	  (setq bufs (cons (cons number (cons name value)) bufs)))
	 ((and (consp value)
	       (consp (cdr value))
	       (consp (cadr value)))	; select.
	  (setq bufs (cons (cons number (cons name (car value))) bufs)))
	 ((consp value)			; checkbox
	  (setq bufs (append (mapcar (lambda (x) (cons number (cons name x))) value)
			     bufs)))
	 (value
	  (setq bufs (cons (cons number (cons name value)) bufs))))
	(setq plist (cddr plist))))
    (when bufs
      (setq bufs (sort bufs (lambda (x y) (< (car x) (car y)))))
      (if (eq (w3m-form-enctype form) 'multipart/form-data)
	  (let ((boundary (apply 'format "--_%d_%d_%d" (current-time)))
		file type)
	    ;; (setq buf (nreverse buf))
	    (cons
	     (concat "multipart/form-data; boundary=" boundary)
	     (with-temp-buffer
	       (set-buffer-multibyte nil)
	       (while (setq buf (cdr (car bufs)))
		 (if (and (consp (cdr buf))
			  (eq (car (cdr buf)) 'file))
		     (progn
		       (setq file (expand-file-name (cdr (cdr buf))))
		       (if (string= (setq type (w3m-local-content-type file))
				    "unknown")
			   (setq type "application/octet-stream"))
		       (insert "--" boundary "\r\n"
			       "Content-Disposition: form-data; name=\""
			       (car buf)
			       "\"; filename=\"" file "\"\r\n"
			       "Content-Type: " type "\r\n"
			       "Content-Transfer-Encoding: binary\r\n\r\n")
		       (when (file-exists-p file)
			 (insert-file-contents-literally file)
			 (goto-char (point-max)))
		       (insert "\r\n"))
		   (insert "--" boundary "\r\n"
			   "Content-Disposition: form-data; name=\""
			   (car buf)
			   "\"\r\n\r\n"
			   (encode-coding-string (cdr buf) coding)
			   "\r\n"))
		 (setq bufs (cdr bufs)))
	       (insert "--" boundary "--\r\n")
	       (buffer-string))))
	(mapconcat (lambda (elem)
		     (setq elem (cdr elem))
		     (format "%s=%s"
			     (w3m-url-encode-string (car elem) coding)
			     (w3m-url-encode-string (if (stringp (cdr elem))
							(cdr elem)
						      "")
						    coding)))
		   bufs "&")))))

(defun w3m-form-resume (forms)
  "Resume content of all forms in the current buffer using FORMS."
  (when forms
    (if (eq (car forms) t)
	(setq forms (cdr forms)))
    (save-excursion
      (goto-char (point-min))
      (let (textareas)
	(while (w3m-form-goto-next-field)
	  (let ((fid (get-text-property (point) 'w3m-form-field-id)))
	    (when (and fid
		       (string-match "\
fid=\\([^/]+\\)/type=\\([^/]+\\)/name=\\([^/]+\\)/id=\\(.*\\)$"
				     fid))
	      (let ((form (nth (string-to-number (match-string 1 fid))
			       forms))
		    (cform (nth (string-to-number (match-string 1 fid))
				w3m-current-forms))
		    (type (match-string 2 fid))
		    (name (match-string 3 fid))
		    (id (string-to-number (match-string 4 fid))))
		(when form
		  (cond
		   ((or (string= type "submit")
			(string= type "image"))
		    ;; Remove status to support forms containing multiple
		    ;; submit buttons.
		    (w3m-form-put cform id name nil))
		   ((or (string= type "reset")
			(string= type "hidden")
			;; Do nothing.
			))
		   ((string= type "password")
		    (w3m-form-replace (w3m-form-get form id)
				      'invisible)
		    (unless (eq form cform)
		      (w3m-form-put cform id name (w3m-form-get form id))))
		   ((string= type "radio")
		    (let ((value (w3m-form-get-by-name form name)))
		      (when value
			(w3m-form-replace
			 (if (string= value (nth 4 (w3m-action (point))))
			     "*" " ")))
		      (unless (eq form cform)
			(w3m-form-put-by-name cform id name value))))
		   ((string= type "checkbox")
		    (let ((value (w3m-form-get form id)))
		      (when value
			(w3m-form-replace
			 (if (member (nth 4 (w3m-action (point))) value)
			     "*" " ")))
		      (unless (eq form cform)
			(w3m-form-put cform id name value))))
		   ((string= type "select")
		    (let ((selects (w3m-form-get form id)))
		      (when (car selects)
			(w3m-form-replace (cdr (assoc (car selects)
						      (cdr selects)))))
		      (unless (eq form cform)
			(w3m-form-put cform id name selects))))
		   ((string= type "textarea")
		    (let ((hseq (nth 2 (w3m-action (point))))
			  (value (w3m-form-get form id)))
		      (when (> hseq 0)
			(setq textareas (cons (cons hseq value) textareas)))
		      (unless (eq form cform)
			(w3m-form-put cform id name value))))
		   ((string= type "file")
		    (let ((value (w3m-form-get form id)))
		      (when (and value
				 (consp value))
			(w3m-form-replace (cdr value)))
		      (unless (eq form cform)
			(w3m-form-put cform id name value))))
		   (t
		    (let ((value (w3m-form-get form id)))
		      (when (stringp value)
			(w3m-form-replace value))
		      (unless (eq form cform)
			(w3m-form-put cform id name value))))))))))
	(unless w3m-form-treat-textarea-size
	  (dolist (textarea textareas)
	    (when (cdr textarea)
	      (w3m-form-textarea-replace (car textarea) (cdr textarea)))))))))

;;;###autoload
(defun w3m-fontify-forms ()
  "Process half-dumped data and fontify forms in this buffer."
  ;; If `w3m-current-forms' is resumed from history, reuse it.
  (w3m-form-parse-and-fontify
   (when (eq t (car w3m-current-forms))
     (setq w3m-current-forms (cdr w3m-current-forms)))))

(eval-and-compile
  (unless (fboundp 'w3m-form-make-button)
    (defun w3m-form-make-button (start end properties)
      "Make button on the region from START to END."
      (add-text-properties start end (append '(face w3m-form-face)
					     properties)))))

;;; w3mmee
;;
(eval-and-compile
  (defalias 'w3m-char-to-int (if (fboundp 'char-to-int)
				 'char-to-int
			       'identity))
  (defalias 'w3m-string-to-char-list (if (fboundp 'string-to-list)
					 'string-to-list
				       (lambda (str)
					 (mapcar 'identity str))))
  (defalias 'w3m-int-to-char (if (fboundp 'int-to-char)
				 'int-to-char
			       'identity)))

(defmacro w3m-form-mee-attr-unquote (x)
  "Unquote form attribute of w3mmee."
  '(let (attr)
     (when (eq (car x) ?T)
       (setq x (cdr x))
       (while (and x (not (eq (w3m-char-to-int (car x)) 0)))
	 (setq attr (concat attr (char-to-string (car x))))
	 (setq x (cdr x))))
     attr))

(defun w3m-form-mee-new (x)
  "Decode form information of w3mmee."
  (setq x (w3m-string-to-char-list (w3m-url-decode-string x)))
  (let (method enctype action charset target name)
    (setq method (case (/ (w3m-char-to-int (car x)) 16)
		   (0 "get")
		   (1 "post")
		   (2 "internal")
		   (3 "head"))
	  enctype (case (% (w3m-char-to-int (car x)) 16)
		    (0 'application/x-www-form-urlencoded)
		    (1 'multipart/form-data)))
    (setq x (cdr x))
    (setq action (w3m-form-normalize-action (w3m-form-mee-attr-unquote x)
					    w3m-current-url))
    (setq x (cdr x))
    (if (member "lang=many" w3m-compile-options)
	(setq charset (w3m-form-mee-attr-unquote x))
      (setq charset (case (car x)
		      (?e "euc-jp")
		      (?s "shift-jis")
		      (?n "iso-2022-7bit"))))
    (setq x (cdr x))
    (setq target (w3m-form-mee-attr-unquote x))	; not used.
    (setq x (cdr x))
    (setq name (w3m-form-mee-attr-unquote x)) ; not used.
    (w3m-form-new method action nil (and charset (list charset)) enctype)))

(defun w3m-form-mee-select-value (value)
  "Decode select form information of w3mmee."
  (let ((clist (w3m-string-to-char-list (w3m-url-decode-string value)))
	label val s selected candidates)
    (while clist
      (setq s (eq (car clist) (w3m-int-to-char 1))
	    label nil
	    val nil)
      (setq clist (cdr clist))
      (while (not (eq (car clist) (w3m-int-to-char 0)))
	(setq label (concat label (char-to-string (car clist))))
	(setq clist (cdr clist)))
      (if label
	  (setq label (decode-coding-string label w3m-output-coding-system)))
      (setq clist (cdr clist))
      (while (not (eq (car clist) (w3m-int-to-char 0)))
	(setq val (concat val (char-to-string (car clist))))
	(setq clist (cdr clist)))
      (if val
	  (setq val (decode-coding-string val w3m-output-coding-system)))
      (if s (setq selected val))
      (push (cons val label) candidates)
      (setq clist (cdr clist)))
    (cons selected (nreverse candidates))))

(defun w3m-fontify-textareas ()
  "Process and fontify textareas in this buffer."
  (when w3m-form-treat-textarea-size
    (save-excursion
      (goto-char (point-min))
      (let (form fid start end type name rows start-column end-column
		 hseq abs-hseq buffer-read-only text id)
	(while (w3m-form-goto-next-field)
	  (setq fid (get-text-property (point) 'w3m-form-field-id))
	  (when
	      (and
	       fid
	       (string-match
		"fid=\\([^/]+\\)/type=\\([^/]+\\)/name=\\([^/]+\\)/id=\\(.*\\)$"
		fid))
	    (setq form (nth (string-to-number (match-string 1 fid))
			    w3m-current-forms)
		  type (match-string 2 fid)
		  name (match-string 3 fid)
		  id (string-to-number (match-string 4 fid)))
	    (when (string= type "textarea")
	      (setq rows (get-text-property (point) 'w3m-textarea-rows)
		    hseq (get-text-property (point) 'w3m-form-hseq)
		    abs-hseq (w3m-anchor-sequence))
	      (setq start-column (- (current-column) 1))
	      (goto-char (next-single-property-change (point)
						      'w3m-form-hseq))
	      (setq end-column (current-column))
	      (save-excursion
		(dotimes (i (- rows 1))
		  (forward-line -1)
		  (save-excursion
		    (move-to-column start-column)
		    (delete-char 1)
		    (insert "[")
		    (setq start (point))
		    (move-to-column end-column)
		    (delete-char 1)
		    (setq end (point))
		    (insert "]"))
		  (add-text-properties
		   start end
		   `(w3m-form-field-id
		     ,(format "fid=%s/type=%s/name=%s/id=%d" fid type name id)
		     face w3m-form-face
		     w3m-action (w3m-form-input-textarea ,form ,hseq)
		     w3m-submit (w3m-form-submit ,form ,id ,name
						 (w3m-form-get ,form ,id))
		     w3m-form-hseq ,hseq
		     w3m-anchor-sequence ,abs-hseq
		     w3m-form-id ,id
		     w3m-form-name ,name)))
		(when (setq text (w3m-form-get form id))
		  (w3m-form-textarea-replace hseq text))))))))))

(defun w3m-form-parse-and-fontify (&optional reuse-forms)
  "Parse forms of the half-dumped data in this buffer and fontify them.
Result form structure is saved to the local variable `w3m-current-forms'.
If optional REUSE-FORMS is non-nil, reuse it as `w3m-current-form'."
  (let ((case-fold-search t)
	(id 0)
	tag start end internal-start textareas selects forms maps mapval
	form)
    (goto-char (point-min))
    (while (if (eq w3m-type 'w3mmee)
	       (w3m-search-tag "_f" "map" "img_alt" "input_alt"
			       "/input_alt")
	     (w3m-search-tag "form_int" "map" "img_alt" "input_alt"
			     "/input_alt"))
      (setq tag (downcase (match-string 1)))
      (goto-char (match-end 1))
      (setq start (match-end 0))
      (cond
       ((string= tag (if (eq w3m-type 'w3mmee) "_f" "form_int"))
	(if (eq w3m-type 'w3mmee)
	    (w3m-parse-attributes (_x)
	      (setq forms (nconc forms (list (w3m-form-mee-new _x)))))
	  (w3m-parse-attributes (action (method :case-ignore)
					(fid :integer)
					(accept-charset :case-ignore)
					(enctype :case-ignore)
					(charset :case-ignore))
	    (when action
	      (setq action (w3m-url-transfer-encode-string
			    (w3m-decode-anchor-string action)
			    (if charset
				(w3m-charset-to-coding-system charset)
			      w3m-current-coding-system))))
	    (if (setq form (cdr (assq fid forms)))
		(progn
		  (setf (w3m-form-method form) (or method "get"))
		  (setf (w3m-form-action form)
			(w3m-form-normalize-action action w3m-current-url))
		  (setf (w3m-form-charlst form)
			(if accept-charset
			    (setq accept-charset
				  (split-string accept-charset ","))))
		  (setf (w3m-form-enctype form)
			(if enctype
			    (intern enctype)
			  'application/x-www-form-urlencoded)))
	      (setq form (w3m-form-new
			  (or method "get")
			  (w3m-form-normalize-action action w3m-current-url)
			  nil
			  (if accept-charset
			      (setq accept-charset
				    (split-string accept-charset ",")))
			  (if enctype
			      (intern enctype)
			    'application/x-www-form-urlencoded)))
	      (setq forms (cons (cons fid form) forms))))))
       ((string= tag "map")
	(let (candidates)
	  (w3m-parse-attributes (name)
	    (while (and (w3m-search-tag "area" "/map")
			(not (char-equal
			      (char-after (match-beginning 1))
			      ?/)))
	      (goto-char (match-end 1))
	      (w3m-parse-attributes (href alt)
		(when href
		  (setq candidates (cons (cons href (or alt href))
					 candidates)))))
	    (unless maps (setq maps (w3m-form-new "map" ".")))
	    (when candidates
	      (w3m-form-put maps
			    (incf id)
			    name
			    (nreverse candidates))))))
       ((string= tag "img_alt")
	(w3m-parse-attributes (usemap)
	  (w3m-search-tag "/img_alt")
	  (when (or usemap mapval)
	    (unless maps (setq maps (w3m-form-new "map" ".")))
	    (unless usemap (setq usemap mapval))
	    (when mapval (setq mapval nil))
	    (add-text-properties
	     start (match-beginning 0)
	     `(face w3m-form-face
		    w3m-action (w3m-form-input-map ,maps ,usemap))))))
       ((string= tag "/input_alt")
	(replace-match ""))
       ((string= tag "input_alt")
	(w3m-parse-attributes ((fid :integer)
			       (type :case-ignore)
			       (width :integer)
			       (maxlength :integer)
			       (hseq :integer)
			       (selectnumber :integer)	 ; select
			       (textareanumber :integer) ; textarea
			       (size :integer)		 ; textarea
			       (rows :integer)		 ; textarea
			       (top_mergin :integer)	 ; textarea
			       (checked :bool) ; checkbox, radio
			       no_effect       ; map
			       name value)
	  (incf id)
	  (when value
	    (setq value (w3m-decode-entities-string value)))
	  (save-excursion
	    (search-forward "</input_alt>")
	    (setq end (match-beginning 0)))
	  (let ((abs-hseq (or (and (null hseq) 0) (abs hseq))))
	    (setq w3m-max-anchor-sequence
		  (max abs-hseq w3m-max-anchor-sequence))
	    (if (eq w3m-type 'w3mmee)
		(setq form (nth fid forms))
	      (setq form (cdr (assq fid forms))))
	    (unless form
	      (setq forms (cons (cons fid (setq form
						(w3m-form-new nil nil)))
				forms)))
	    (cond
	     ((and (string= type "hidden")
		   (string= name "link"))
	      (setq mapval value))
	     ((or (string= type "submit")
		  (string= type "image"))
	      (unless (string= no_effect "true")
		(w3m-form-make-button
		 start end
		 `(w3m-form-field-id
		   ,(format "fid=%d/type=%s/name=%s/id=%d" fid type name id)
		   w3m-action (w3m-form-submit ,form ,id ,name ,value)
		   w3m-submit (w3m-form-submit ,form ,id ,name
					       (w3m-form-get ,form ,id))
		   w3m-anchor-sequence ,abs-hseq))))
	     ((string= type "reset")
	      (w3m-form-make-button
	       start end
	       `(w3m-form-field-id
		 ,(format "fid=%d/type=%s/name=%s/id=%d" fid type name id)
		 w3m-action (w3m-form-reset ,form)
		 w3m-anchor-sequence ,abs-hseq)))
	     ((string= type "textarea")
	      (if (eq w3m-type 'w3mmee)
		  (w3m-form-put form id
				name
				(decode-coding-string
				 (w3m-url-decode-string value)
				 w3m-output-coding-system))
		(setq textareas (cons (list textareanumber form id name)
				      textareas)))
	      (add-text-properties
	       start end
	       `(w3m-form-field-id
		 ,(format "fid=%d/type=%s/name=%s/id=%d" fid type name id)
		 face w3m-form-face
		 w3m-action (w3m-form-input-textarea ,form ,hseq)
		 w3m-submit (w3m-form-submit ,form ,id ,name
					     (w3m-form-get ,form ,id))
		 w3m-textarea-rows ,rows
		 w3m-form-hseq ,hseq
		 w3m-anchor-sequence ,abs-hseq
		 w3m-form-id ,id
		 w3m-form-name ,name)))
	     ((string= type "select")
	      (when (if (eq w3m-type 'w3mmee)
			(when value
			  (w3m-form-put form id name
					(w3m-form-mee-select-value value))
			  t)
		      (setq selects (cons (list selectnumber form id name)
					  selects)))
		(add-text-properties
		 start end
		 `(w3m-form-field-id
		   ,(format "fid=%d/type=%s/name=%s/id=%d" fid type name id)
		   face w3m-form-face
		   w3m-action (w3m-form-input-select ,form ,id ,name)
		   w3m-submit (w3m-form-submit ,form ,id ,name
					       (w3m-form-get ,form ,id))
		   w3m-anchor-sequence ,abs-hseq))))
	     ((string= type "password")
	      (add-text-properties
	       start end
	       `(w3m-form-field-id
		 ,(format "fid=%d/type=%s/name=%s/id=%d" fid type name id)
		 face w3m-form-face
		 w3m-action (w3m-form-input-password ,form ,id ,name)
		 w3m-submit (w3m-form-submit ,form ,id ,name
					     (w3m-form-get ,form ,id))
		 w3m-anchor-sequence ,abs-hseq)))
	     ((string= type "checkbox")
	      (let ((cvalue (w3m-form-get form id)))
		(w3m-form-put form id name
			      (if checked
				  (cons value cvalue)
				cvalue)))
	      (add-text-properties
	       start end
	       `(w3m-form-field-id
		 ,(format "fid=%d/type=%s/name=%s/id=%d" fid type name id)
		 face w3m-form-face
		 w3m-action (w3m-form-input-checkbox ,form ,id ,name ,value)
		 w3m-submit (w3m-form-submit ,form ,id ,name
					     (w3m-form-get ,form ,id))
		 w3m-anchor-sequence ,abs-hseq)))
	     ((string= type "radio")
	      ;; Radio button input, one name has one value
	      (if checked
		  (w3m-form-put-by-name form id name value))
	      (add-text-properties
	       start end
	       `(w3m-form-field-id
		 ,(format "fid=%d/type=%s/name=%s/id=%d" fid type name id)
		 face w3m-form-face
		 w3m-action (w3m-form-input-radio ,form ,id ,name ,value)
		 w3m-submit (w3m-form-submit ,form ,id ,name
					     (w3m-form-get-by-name
					      ,form ,name))
		 w3m-anchor-sequence ,abs-hseq)))
	     ((string= type "file")
	      (add-text-properties
	       start end
	       `(w3m-form-field-id
		 ,(format "fid=%d/type=%s/name=%s/id=%d" fid type name id)
		 face w3m-form-face
		 w3m-action (w3m-form-input-file ,form ,id ,name ,value)
		 w3m-submit (w3m-form-submit ,form ,id ,name
					     (w3m-form-get ,form ,id))
		 w3m-anchor-sequence ,abs-hseq)))
	     (t
	      (w3m-form-put form
			    id
			    name
			    (or value (w3m-form-get form id)))
	      (add-text-properties
	       start end
	       `(w3m-form-field-id
		 ,(format "fid=%d/type=%s/name=%s/id=%d" fid type name id)
		 face w3m-form-face
		 w3m-action (w3m-form-input ,form ,id ,name ,type
					    ,width ,maxlength ,value)
		 w3m-submit (w3m-form-submit ,form ,id ,name
					     (w3m-form-get ,form ,id))
		 w3m-anchor-sequence ,abs-hseq)))))))))
    ;; Process <internal> tag.
    (when (search-forward "<internal>" nil t)
      (setq internal-start (match-beginning 0))
      (while (and (null reuse-forms)
		  (re-search-forward "<\\([a-z]+\\)_int" nil t))
	(incf id)
	(cond
	 ((string= (match-string 1) "select")
	  (w3m-parse-attributes ((selectnumber :integer))
	    (let ((selectinfo (cdr (assq selectnumber selects)))
		  current candidates)
	      (when selectinfo
		;; Parse FORM SELECT fields until </SELECT> (or </FORM>)
		(while (and (w3m-search-tag "option_int" "/select_int")
			    (not (char-equal (char-after (match-beginning 1))
					     ?/)))
		  ;; <option_int> is found
		  (goto-char (match-end 1))
		  (w3m-parse-attributes ((value :decode-entity)
					 (label :decode-entity)
					 (selected :bool))
		    (push (cons value label) candidates)
		    (if selected (setq current value))
		    (skip-chars-forward ">\n")))
		(setq candidates (nreverse candidates))
		(w3m-form-put (nth 0 selectinfo)
			      (nth 1 selectinfo)
			      (nth 2 selectinfo)
			      (cons (or current	; current value
					(caar candidates))
				    candidates))))))
	 ((string= (match-string 1) "textarea")
	  (w3m-parse-attributes ((textareanumber :integer))
	    (forward-char 1)		; skip newline character.
	    (let ((textareainfo (cdr (assq textareanumber textareas)))
		  (buffer (current-buffer))
		  end text)
	      (when textareainfo
		(setq start (point))
		(skip-chars-forward "^<")
		(setq end (point))
		(with-temp-buffer
		  (insert-buffer-substring buffer start end)
		  (w3m-decode-entities)
		  (goto-char (point-min))
		  (while (search-forward "\r\n" nil t) (replace-match "\n"))
		  (setq text (buffer-string)))
		(w3m-form-put (nth 0 textareainfo)
			      (nth 1 textareainfo)
			      (nth 2 textareainfo)
			      text)))))))
      (when (search-forward "</internal>" nil t)
	(delete-region internal-start (match-end 0))))
    (setq w3m-current-forms (if (eq w3m-type 'w3mmee)
				forms
			      (mapcar 'cdr
				      (sort forms (lambda (x y)
						    (< (car x)(car y)))))))
    (w3m-form-resume (or reuse-forms w3m-current-forms))))

(defun w3m-form-replace (string &optional invisible)
  (let* ((start (text-property-any (point-min) (point-max)
				   'w3m-action (w3m-action (point))))
	 (width (string-width
		 (buffer-substring
		  start
		  (next-single-property-change start 'w3m-action))))
	 (prop (text-properties-at start))
	 (p (point))
	 (buffer-read-only))
    (goto-char start)
    (insert (setq string
		  (if invisible
		      (make-string (length string) ?.)
		    (mapconcat 'identity
			       (split-string
				(w3m-truncate-string (or string "")
						     width) "\n")
			       "")))
	    (make-string (max (- width (string-width string)) 0) ?\ ))
    (delete-region (point)
		   (next-single-property-change (point) 'w3m-action))
    (add-text-properties start (point) prop)
    (set-buffer-modified-p nil)
    (prog1 (point)
      (goto-char p))))

(defun w3m-form-input (form id name type width maxlength value)
  (save-excursion
    (let* ((fvalue (w3m-form-get form id))
	   (input (read-from-minibuffer (concat (upcase type) ": ") fvalue)))
      (w3m-form-put form id name input)
      (w3m-form-replace input))))

(defun w3m-form-input-password (form id name)
  (let* ((fvalue (w3m-form-get form id))
	 (input (read-passwd (concat "PASSWORD"
				     (if fvalue
					 " (default is no change)")
				     ": ")
			     nil
			     fvalue)))
    (w3m-form-put form id name input)
    (w3m-form-replace input 'invisible)))

(defun w3m-form-input-checkbox (form id name value)
  (let ((fvalue (w3m-form-get form id)))
    (if (member value fvalue)		; already checked
	(progn
	  (w3m-form-put form id name (delete value fvalue))
	  (w3m-form-replace " "))
      (w3m-form-put form id name (cons value fvalue))
      (w3m-form-replace "*"))))

(defsubst w3m-form-field-parse (fid)
  (when (and fid
	     (string-match
	      "fid=\\([^/]+\\)/type=\\([^/]+\\)/name=\\([^/]+\\)/id=\\(.*\\)$"
	      fid))
    (list (match-string 1 fid)
	  (match-string 2 fid)
	  (match-string 3 fid)
	  (match-string 4 fid))))

(defun w3m-form-input-radio (form id name value)
  (save-excursion
    (let ((fid (w3m-form-field-parse
		(get-text-property (point) 'w3m-form-field-id)))
	  cur-fid)
      (when fid
	;; Uncheck all RADIO input having same NAME
	(goto-char 1)
	(while (w3m-form-goto-next-field)
	  (setq cur-fid (w3m-form-field-parse
			 (get-text-property (point)
					    'w3m-form-field-id)))
	  (when (and (string= (nth 0 fid) (nth 0 cur-fid))
		     (string= (nth 1 fid) (nth 1 cur-fid))
		     (string= (nth 2 fid) (nth 2 cur-fid)))
	    (w3m-form-put-by-name
	     form (string-to-number (nth 3 fid)) (nth 2 fid) nil)
	    (w3m-form-replace " ")))))) ; erase check
  ;; Then set this field as checked.
  (w3m-form-put-by-name form id name value)
  (w3m-form-replace "*"))

(defun w3m-form-input-file (form id name value)
  (let ((input (read-file-name "File name: "
			       (or (cdr (w3m-form-get form id))
				   "~/"))))
    (w3m-form-put form id name (cons 'file input))
    (w3m-form-replace input)))

;;; TEXTAREA

(defcustom w3m-form-input-textarea-buffer-lines 10
  "*Buffer lines for form textarea buffer."
  :group 'w3m
  :type '(integer :size 0))

(defcustom w3m-form-input-textarea-mode-hook nil
  "*A hook called after w3m-form-input-textarea-mode."
  :group 'w3m
  :type 'hook)

(defcustom w3m-form-input-textarea-set-hook nil
  "*A Hook called before w3m-form-input-textarea-set."
  :group 'w3m
  :type 'hook)

(defun w3m-form-text-chop (text)
  "Return a list of substrings of TEXT which are separated by newline
character."
  (when text
    (let ((start 0) parts)
      (while (string-match "\n" text start)
	(setq parts (cons (substring text start (match-beginning 0)) parts)
	      start (match-end 0)))
      (nreverse (cons (substring text start) parts)))))

(defun w3m-form-search-textarea (hseq direction)
  (let ((point (point))
	(next-single-property-change-function
	 (if (eq direction 'forward)
	     'next-single-property-change
	   'previous-single-property-change))
	found)
    (if (get-text-property point 'w3m-form-hseq)
	(setq point (funcall next-single-property-change-function point
			     'w3m-form-hseq)))
    (when point
      (while (and (not found)
		  (setq point (funcall next-single-property-change-function
				       point 'w3m-form-hseq)))
	(when (eq (get-text-property point 'w3m-form-hseq) hseq)
	  (setq found t)))
      (if point (goto-char point)))))

(defun w3m-form-textarea-replace (hseq string)
  (let ((chopped (w3m-form-text-chop string))
	(p (point)))
    (goto-char (point-min))
    (while (w3m-form-search-textarea hseq 'forward)
      (w3m-form-replace (or (car chopped) ""))
      (setq chopped (cdr chopped)))
    (goto-char p)))

(defun w3m-form-textarea-info ()
  "Return a list of (ID NAME LINE) for current text area."
  (let ((s (get-text-property (point) 'w3m-form-hseq))
	(lines 1))
    (save-excursion
      (while (w3m-form-search-textarea s 'backward)
	(incf lines))
      (list (get-text-property (point) 'w3m-form-id)
	    (get-text-property (point) 'w3m-form-name)
	    lines))))

(defvar w3m-form-input-textarea-keymap nil)
(unless w3m-form-input-textarea-keymap
  (setq w3m-form-input-textarea-keymap (make-sparse-keymap))
  (define-key w3m-form-input-textarea-keymap "\C-c\C-c"
    'w3m-form-input-textarea-set)
  (define-key w3m-form-input-textarea-keymap "\C-c\C-q"
    'w3m-form-input-textarea-exit)
  (define-key w3m-form-input-textarea-keymap "\C-c\C-k"
    'w3m-form-input-textarea-exit)
  (define-key w3m-form-input-textarea-keymap "\C-x\C-s"
    'w3m-form-input-textarea-save))

(defvar w3m-form-input-textarea-buffer nil)
(defvar w3m-form-input-textarea-form nil)
(defvar w3m-form-input-textarea-hseq nil)
(defvar w3m-form-input-textarea-point nil)
(defvar w3m-form-input-textarea-wincfg nil)
(defvar w3m-form-input-textarea-file nil)
(defvar w3m-form-input-textarea-coding-system nil)
(make-variable-buffer-local 'w3m-form-input-textarea-buffer)
(make-variable-buffer-local 'w3m-form-input-textarea-form)
(make-variable-buffer-local 'w3m-form-input-textarea-hseq)
(make-variable-buffer-local 'w3m-form-input-textarea-point)
(make-variable-buffer-local 'w3m-form-input-textarea-wincfg)
(make-variable-buffer-local 'w3m-form-input-textarea-file)
(make-variable-buffer-local 'w3m-form-input-textarea-coding-system)

(defun w3m-form-input-textarea-filename (url id)
  ;; replace is
  (let ((file "")
	;; Interdit chars of Windows
	(replace (regexp-opt '("\\" "/" ":" "*" "?" "\"" "<" ">" "|"))))
    (while (string-match replace url)
      (setq file (concat file (substring url 0 (match-beginning 0)) "_"))
      (setq url (substring url (match-end 0))))
    (setq file (concat file url "-"))
    (while (string-match replace id)
      (setq file (concat file (substring id 0 (match-beginning 0)) "_"))
      (setq id (substring id (match-end 0))))
    (setq file (concat file id ".txt"))
    (convert-standard-filename file)))

(defun w3m-form-input-textarea-save (&optional buffer file)
  "Save textarea buffer."
  (interactive)
  (setq buffer (or buffer (current-buffer)))
  (setq file (or file w3m-form-input-textarea-file))
  (with-current-buffer buffer
    (if (/= (buffer-size) 0)
	(when (or w3m-form-use-textarea-backup
		  (eq this-command 'w3m-form-input-textarea-save))
	  (let ((buffer-file-coding-system w3m-form-input-textarea-coding-system)
		(file-coding-system w3m-form-input-textarea-coding-system)
		(coding-system-for-write w3m-form-input-textarea-coding-system))
	    (write-region (point-min) (point-max) file nil 'nomsg)))
      (when (file-exists-p file)
	(delete-file file))
      (when (file-exists-p (make-backup-file-name file))
	(delete-file (make-backup-file-name file))))
    (set-buffer-modified-p nil)))

(defun w3m-form-input-textarea-set ()
  "Save and exit from w3m form textarea mode."
  (interactive)
  (run-hooks 'w3m-form-input-textarea-set-hook)
  (let ((input (buffer-string))
	(buffer (current-buffer))
	(hseq w3m-form-input-textarea-hseq)
	(form w3m-form-input-textarea-form)
	(point w3m-form-input-textarea-point)
	(w3mbuffer w3m-form-input-textarea-buffer)
	(wincfg w3m-form-input-textarea-wincfg)
	(file w3m-form-input-textarea-file)
	info)
    (w3m-form-input-textarea-save buffer file)
    (when (buffer-live-p w3mbuffer)
      (or (one-window-p) (delete-window))
      (kill-buffer buffer)
      (pop-to-buffer w3mbuffer)
      (set-window-configuration wincfg)
      (when (and form point)
	(goto-char point)
	(setq info (w3m-form-textarea-info))
	(w3m-form-put form (nth 0 info) (nth 1 info) input)
	(w3m-form-textarea-replace hseq input)))))

(defun w3m-form-input-textarea-exit ()
  "Exit from w3m form textarea mode."
  (interactive)
  (let ((buffer (current-buffer))
	(point w3m-form-input-textarea-point)
	(w3mbuffer w3m-form-input-textarea-buffer)
	(wincfg w3m-form-input-textarea-wincfg)
	(file w3m-form-input-textarea-file))
    (w3m-form-input-textarea-save buffer file)
    (when (buffer-live-p w3mbuffer)
      (or (one-window-p) (delete-window))
      (kill-buffer buffer)
      (pop-to-buffer w3mbuffer)
      (set-window-configuration wincfg)
      (when point (goto-char point)))))

(defun w3m-form-input-textarea-mode ()
  "\\<w3m-form-input-textarea-keymap>
   Major mode for w3m form textarea.

\\[w3m-form-input-textarea-set]	Save and exit from w3m form textarea mode.
\\[w3m-form-input-textarea-exit]	Exit from w3m form textarea mode.
\\[w3m-form-input-textarea-save]	Save textarea.
"
  (setq mode-name "w3m form textarea"
	major-mode 'w3m-form-input-textarea-mode)
  (use-local-map w3m-form-input-textarea-keymap)
  (run-hooks 'w3m-form-input-textarea-mode-hook))

(defun w3m-form-input-textarea (form hseq)
  (let* ((info  (w3m-form-textarea-info))
	 (value (w3m-form-get form (car info)))
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
	 (buffer (generate-new-buffer "*w3m form textarea*"))
	 (file (expand-file-name
		(w3m-form-input-textarea-filename
		 w3m-current-url
		 (get-text-property (point) 'w3m-form-field-id))
		w3m-form-textarea-directory))
	 (dir (file-chase-links (expand-file-name w3m-form-textarea-directory)))
	 (coding (w3m-form-charlst form)))
    (setq coding (w3m-form-get-coding-system coding))
    (unless (and (file-exists-p dir)
		 (file-directory-p dir))
      (when (file-regular-p dir) (delete-file dir))
      (make-directory dir))
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
      (setq w3m-form-input-textarea-hseq hseq)
      (setq w3m-form-input-textarea-buffer w3mbuffer)
      (setq w3m-form-input-textarea-point point)
      (setq w3m-form-input-textarea-wincfg wincfg)
      (setq w3m-form-input-textarea-file file)
      (setq w3m-form-input-textarea-coding-system coding)
      (when (file-exists-p file)
	(if (y-or-n-p "Exist the editted file of this form. Read it? ")
	    (let ((buffer-file-coding-system w3m-form-input-textarea-coding-system)
		  (file-coding-system w3m-form-input-textarea-coding-system)
		  (coding-system-for-read w3m-form-input-textarea-coding-system))
	      (insert-file-contents file)
	      (setq value nil))
	  (delete-file file)
	  (when (file-exists-p (make-backup-file-name file))
	    (delete-file (make-backup-file-name file)))))
      (if value (insert value))
      (goto-char (point-min))
      (forward-line (1- (nth 2 info)))
      (w3m-form-input-textarea-mode))))

;;; SELECT

(defcustom w3m-form-input-select-buffer-lines 10
  "*Buffer lines for form select buffer."
  :group 'w3m
  :type '(integer :size 0))

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
  (define-key w3m-form-input-select-keymap "\C-c\C-q"
    'w3m-form-input-select-exit)
  (define-key w3m-form-input-select-keymap "\C-c\C-k"
    'w3m-form-input-select-exit)
  (define-key w3m-form-input-select-keymap "q"
    'w3m-form-input-select-exit)
  (define-key w3m-form-input-select-keymap "h" 'backward-char)
  (define-key w3m-form-input-select-keymap "j" 'next-line)
  (define-key w3m-form-input-select-keymap "k" 'previous-line)
  (define-key w3m-form-input-select-keymap "l" 'forward-char)
  (if (featurep 'xemacs)
      (define-key w3m-form-input-select-keymap [(button2)]
	'w3m-form-input-select-set-mouse)
    (define-key w3m-form-input-select-keymap [mouse-2]
      'w3m-form-input-select-set-mouse)))
(defvar w3m-form-input-select-buffer nil)
(defvar w3m-form-input-select-form nil)
(defvar w3m-form-input-select-name nil)
(defvar w3m-form-input-select-id nil)
(defvar w3m-form-input-select-point nil)
(defvar w3m-form-input-select-candidates nil)
(defvar w3m-form-input-select-wincfg nil)
(make-variable-buffer-local 'w3m-form-input-select-buffer)
(make-variable-buffer-local 'w3m-form-input-select-form)
(make-variable-buffer-local 'w3m-form-input-select-name)
(make-variable-buffer-local 'w3m-form-input-select-id)
(make-variable-buffer-local 'w3m-form-input-select-point)
(make-variable-buffer-local 'w3m-form-input-select-candidates)
(make-variable-buffer-local 'w3m-form-input-select-wincfg)

(defun w3m-form-input-select-set-mouse (event)
  "Save and exit from w3m form select mode with mouse."
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
	 (id w3m-form-input-select-id)
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
	(w3m-form-put form id name input)
	(w3m-form-replace (cdr (assoc cur (cdr input))))))))

(defun w3m-form-input-select-exit ()
  "Exit from w3m form select mode."
  (interactive)
  (let* ((buffer (current-buffer))
	 (point w3m-form-input-select-point)
	 (w3mbuffer w3m-form-input-select-buffer)
	 (wincfg w3m-form-input-select-wincfg))
    (when (buffer-live-p w3mbuffer)
      (or (one-window-p) (delete-window))
      (kill-buffer buffer)
      (pop-to-buffer w3mbuffer)
      (set-window-configuration wincfg)
      (when point (goto-char point)))))

(defun w3m-form-input-select-mode ()
  "\\<w3m-form-input-select-keymap>
   Major mode for w3m form select.

\\[w3m-form-input-select-set]\
	Save and exit from w3m form select mode.
\\[w3m-form-input-select-exit]\
	Exit from w3m form select mode.
\\[w3m-form-input-select-set-mouse]\
	Save and exit from w3m form select mode with mouse.
"
  (setq mode-name "w3m form select"
	major-mode 'w3m-form-input-select-mode)
  (setq buffer-read-only t)
  (use-local-map w3m-form-input-select-keymap)
  (run-hooks 'w3m-form-input-select-mode-hook))

(defun w3m-form-input-select (form id name)
  (let* ((value (w3m-form-get form id))
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
      (setq w3m-form-input-select-id id)
      (setq w3m-form-input-select-buffer w3mbuffer)
      (setq w3m-form-input-select-point point)
      (setq w3m-form-input-select-candidates value)
      (setq w3m-form-input-select-wincfg wincfg)
      (when value
	(setq cur (car value))
	(setq value (cdr value))
	(dolist (candidate value)
	  (setq pos (point))
	  (insert (if (zerop (length (cdr candidate)))
		      " "		; "" -> " "
		    (cdr candidate)))
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
  :type '(integer :size 0))

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
  (define-key w3m-form-input-map-keymap "\C-c\C-q"
    'w3m-form-input-map-exit)
  (define-key w3m-form-input-map-keymap "\C-c\C-k"
    'w3m-form-input-map-exit)
  (define-key w3m-form-input-map-keymap "q"
    'w3m-form-input-map-exit)
  (define-key w3m-form-input-map-keymap "h" 'backward-char)
  (define-key w3m-form-input-map-keymap "j" 'next-line)
  (define-key w3m-form-input-map-keymap "k" 'previous-line)
  (define-key w3m-form-input-map-keymap "l" 'forward-char)
  (if (featurep 'xemacs)
      (define-key w3m-form-input-map-keymap [(button2)]
	'w3m-form-input-map-set-mouse)
    (define-key w3m-form-input-map-keymap [mouse-2]
      'w3m-form-input-map-set-mouse)))
(defvar w3m-form-input-map-buffer nil)
(defvar w3m-form-input-map-wincfg nil)
(defvar w3m-form-input-map-point nil)
(make-variable-buffer-local 'w3m-form-input-map-buffer)
(make-variable-buffer-local 'w3m-form-input-map-wincfg)
(make-variable-buffer-local 'w3m-form-input-map-point)

(defun w3m-form-input-map-set-mouse (event)
  "Save and exit from w3m form select map mode with mouse."
  (interactive "e")
  (mouse-set-point event)
  (w3m-form-input-map-set))

(defun w3m-form-input-map-set ()
  "Save and exit from w3m form select map mode."
  (interactive)
  (run-hooks 'w3m-form-input-map-set-hook)
  (let* ((map (get-text-property (point) 'w3m-form-map-value))
	 (buffer (current-buffer))
	 (w3mbuffer w3m-form-input-map-buffer)
	 (wincfg w3m-form-input-map-wincfg)
	 (point w3m-form-input-map-point))
    (when (buffer-live-p w3mbuffer)
      (or (one-window-p) (delete-window))
      (kill-buffer buffer)
      (pop-to-buffer w3mbuffer)
      (set-window-configuration wincfg)
      (when point (goto-char point))
      (w3m-goto-url (w3m-expand-url map)))))

(defun w3m-form-input-map-exit ()
  "Exit from w3m form select map mode."
  (interactive)
  (let* ((buffer (current-buffer))
	 (w3mbuffer w3m-form-input-map-buffer)
	 (wincfg w3m-form-input-map-wincfg)
	 (point w3m-form-input-map-point))
    (when (buffer-live-p w3mbuffer)
      (or (one-window-p) (delete-window))
      (kill-buffer buffer)
      (pop-to-buffer w3mbuffer)
      (set-window-configuration wincfg)
      (when point (goto-char point)))))

(defun w3m-form-input-map-mode ()
  "\\<w3m-form-input-map-keymap>
   Major mode for w3m map select.

\\[w3m-form-input-map-set]\
	Save and exit from w3m form select map mode.
\\[w3m-form-input-map-exit]\
	Exit from w3m form select map mode.
\\[w3m-form-input-map-set-mouse]\
	Save and exit from w3m form select map mode with mouse.
"
  (setq mode-name "w3m map select"
	major-mode 'w3m-form-input-map-mode)
  (setq buffer-read-only t)
  (use-local-map w3m-form-input-map-keymap)
  (run-hooks 'w3m-form-input-map-mode-hook))

(defun w3m-form-input-map (form name)
  (let* ((value (w3m-form-get-by-name form name))
	 (cur-win (selected-window))
	 (wincfg (current-window-configuration))
	 (w3mbuffer (current-buffer))
	 (point (point))
	 (size (min
		(- (window-height cur-win)
		   window-min-height 1)
		(- (window-height cur-win)
		   (max window-min-height
			(1+ w3m-form-input-map-buffer-lines)))))
	 (buffer (generate-new-buffer "*w3m map select*"))
	 pos)
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
      (setq w3m-form-input-map-point point)
      (when value
	(dolist (candidate value)
	  (setq pos (point))
	  (insert (if (zerop (length (cdr candidate)))
		      (car candidate)
		    (cdr candidate)))
	  (add-text-properties pos (point)
			       (list 'w3m-form-map-value (car candidate)
				     'mouse-face w3m-form-mouse-face))
	  (insert "\n")))
      (goto-char (point-min))
      (set-buffer-modified-p nil)
      (beginning-of-line)
      (w3m-form-input-map-mode))))

;;;

(defun w3m-form-submit (form &optional id name value)
  (when (and id name
	     (> (length name) 0))
    (w3m-form-put form id name value))
  (let* ((orig-url w3m-current-url)
	 (url (or (w3m-form-action form)
		  (if (string-match "\\?" w3m-current-url)
		      (substring w3m-current-url 0 (match-beginning 0))
		    w3m-current-url))))
    (cond ((and (not (string= url orig-url))
		(string-match "^https://" orig-url)
		(string-match "^http://" url)
		(not (y-or-n-p (format "Send POST data to '%s'?" url))))
	   (ding))
	  ((eq 'get (w3m-form-method form))
	   (w3m-goto-url
	    (concat url "?" (w3m-form-make-form-data form))))
	  ((eq 'post (w3m-form-method form))
	   (w3m-goto-url url 'reload nil
			 (w3m-form-make-form-data form)
			 w3m-current-url))
	  (t
	   (w3m-message "This form's method has not been supported: %s"
			(let (print-level print-length)
			  (prin1-to-string (w3m-form-method form))))))))

(defsubst w3m-form-real-reset (form sexp)
  (and (eq 'w3m-form-input (car sexp))
       (eq form (nth 1 sexp))
       (w3m-form-put form (nth 2 sexp) (nth 3 sexp) (nth 7 sexp))
       (w3m-form-replace (nth 7 sexp))))

(defun w3m-form-reset (form)
  (save-excursion
    (let (pos prop)
      (when (setq prop (w3m-action (goto-char (point-min))))
	(goto-char (or (w3m-form-real-reset form prop)
		       (next-single-property-change pos 'w3m-action))))
      (while (setq pos (next-single-property-change (point) 'w3m-action))
	(goto-char pos)
	(goto-char (or (w3m-form-real-reset form (w3m-action pos))
		       (next-single-property-change pos 'w3m-action)))))))


(provide 'w3m-form)

;;; w3m-form.el ends here
