;;; w3m-filter.el --- filtering utility of advertisements on WEB sites.

;; Copyright (C) 2001 TSUCHIYA Masatoshi <tsuchiya@pine.kuee.kyoto-u.ac.jp>

;; Authors: TSUCHIYA Masatoshi <tsuchiya@pine.kuee.kyoto-u.ac.jp>
;; Keywords: w3m, WWW, hypermedia

;; w3m-filter.el is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; w3m-filter.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with w3m.el; if not, write to the Free Software Foundation,
;; Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


;;; Commentary:

;; w3m-filter.el is the add-on utility to filter advertisements on WEB
;; sites.


;;; Code:

(provide 'w3m-filter)
(require 'w3m)


(defcustom w3m-filter-rules
  '(("http://www.geocities.co.jp/Technopolis/"
     "<DIV ALIGN=CENTER>\n<!--*/GeoGuide/*-->" "<!--*/GeoGuide/*-->\n</DIV>")
    ("http://linux.ascii24.com/linux/"
     "<!-- DAC CHANNEL AD START -->" "<!-- DAC CHANNEL AD END -->")
    ("http://lwn.net/" . w3m-filter-lwn.net))
  "Rules to filter advertisements on WEB sites."
  :group 'w3m
  :type '(repeat
	  (cons
	   (string :tag "URL")
	   (choice
	    (list (string :tag "Start pattern")
		  (string :tag "End pattern"))
	    (function :tag "Filtering function")))))


(defvar w3m-filter-db nil) ; nil means non-initialized.
(defconst w3m-filter-db-size 1023)

;; FIXME: $BK\Ev$O(B URL $B$r$-$A$s$H2r@O$9$k4X?t$,I,MW(B
(defconst w3m-filter-server-regexp "^\\([-+\\.A-z0-9]+://[^/]+/\\)")


(defun w3m-filter-setup ()
  "Initialize hash database of filtering rules."
  (unless w3m-filter-db
    (let ((db (make-vector w3m-filter-db-size nil)))
      (dolist (site w3m-filter-rules)
	(let* ((url (car site))
	       (func (cdr site))
	       (server (when (string-match w3m-filter-server-regexp url)
			 (match-string 1 url)))
	       (ident (intern server db)))
	  (unless (symbolp func)
	    ;; Process simple filtering rules.
	    (setq func (` (lambda (&rest args)
			    (w3m-filter-delete-region
			     (, (nth 1 site))
			     (, (nth 2 site)))))))
	  (set ident
	       (cons (cons (concat "^" (regexp-quote url)) func)
		     (when (boundp ident)
		       (symbol-value ident))))))
      (setq w3m-filter-db db))))

(defun w3m-filter (url)
  "Exec filtering rule of URL to contents in this buffer."
  (w3m-filter-setup)
  (when (string-match w3m-filter-server-regexp url)
    (let ((ident (intern-soft (match-string 1 url) w3m-filter-db)))
      (when ident
	(let (functions)
	  (dolist (site (symbol-value ident) nil)
	    (when (string-match (car site) url)
	      (push (cdr site) functions)))
	  (w3m-with-work-buffer
	    (save-match-data
	      (run-hook-with-args-until-success 'functions url))))))))

(defun w3m-filter-delete-region (start end)
  "Delete region from START pattern to END pattern."
  (goto-char (point-min))
  (let (p)
    (and (search-forward start nil t)
	 (setq p (match-beginning 0))
	 (search-forward end nil t)
	 (progn
	   (delete-region p (match-end 0))
	   t))))


;; Filter functions:
(defun w3m-filter-lwn.net (url)
  "Filtering function of lwn.net."
  (goto-char (point-min))
  (let (p)
    (while (and (re-search-forward "<!-- Start of Ad ([-A-z0-9]+) -->" nil t)
		(setq p (match-beginning 0))
		(search-forward "<!-- End of Ad -->" nil t))
      (delete-region p (match-end 0)))
    t))


;;; w3m-filter.el ends here.
