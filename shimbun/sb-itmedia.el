;;; sb-itmedia.el --- shimbun backend for ITmedia -*- coding: iso-2022-7bit -*-

;; Copyright (C) 2004, 2005, 2006 Yuuichi Teranishi <teranisi@gohome.org>

;; Author: TSUCHIYA Masatoshi <tsuchiya@namazu.org>,
;;         Yuuichi Teranishi  <teranisi@gohome.org>
;;         ARISAWA Akihiro    <ari@mbf.sphere.ne.jp>
;; Keywords: news

;; This file is a part of shimbun.

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
;; Inc.; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;; Original code was nnshimbun.el written by
;; TSUCHIYA Masatoshi <tsuchiya@namazu.org>.

;;; Code:

(eval-when-compile
  (require 'cl))

(require 'shimbun)
(require 'sb-rss)

(luna-define-class shimbun-itmedia (shimbun-rss) ())

(defvar shimbun-itmedia-group-alist
  `(,@(mapcar
       (lambda (group)
	 (list (concat "news." group) (concat "news_" group)))
       '("bursts" "domestic" "foreign" "products" "technology" "web20"
	 "nettopics" "society" "security" "industry" "research" "sp_amd"))
    ("anchordesk" nil "http://www.itmedia.co.jp/anchordesk/"
     shimbun-itmedia-anchordesk-get-headers)
    ("enterprise" "enterprise")
    ,@(mapcar
       (lambda (group)
	 (list (concat "+D." group) group))
       '("plusd" "mobile" "pcupdate" "lifestyle" "games" "docomo" "au_kddi"
	 "vodafone" "shopping"))))

(defvar shimbun-itmedia-x-face-alist
  '(("\\+D" . "X-Face: #Ur~tK`JhZFFHPEVGKEi`MS{55^~&^0KUuZ;]-@WQ[8\
@,Ex'EeAAE}6xF<K#]pULF@5r24J
 |8/oP)(lCAzF0}.C@@}!k8!Qiz6b{]V")
    ("default" . "X-Face: %JzFW&0lP]xKGl{Bk3\\`yC0zZp|!;\\KT9'rqE2AIk\
R[TQ[*i0d##D=I3|g`2yr@sc<pK1SB
 j`}1YEnKc;U0:^#LQB*})Q}y=45<lIE4q<gZ88e2qS8a@Tys6S")))

(luna-define-method shimbun-groups ((shimbun shimbun-itmedia))
  (mapcar 'car shimbun-itmedia-group-alist))

(luna-define-method shimbun-from-address ((shimbun shimbun-itmedia))
  (format "ITmedia (%s)" (shimbun-current-group shimbun)))

(luna-define-method shimbun-index-url ((shimbun shimbun-itmedia))
  (let ((elem (assoc (shimbun-current-group shimbun)
		     shimbun-itmedia-group-alist)))
    (if (nth 1 elem)
	(format "http://rss.itmedia.co.jp/rss/2.0/%s.xml" (nth 1 elem))
      (nth 2 elem))))

(luna-define-method shimbun-headers :around ((shimbun shimbun-itmedia)
					     &optional range)
  (let ((elem (assoc (shimbun-current-group shimbun)
		     shimbun-itmedia-group-alist)))
    (if (nth 1 elem)
	(luna-call-next-method)
      (with-temp-buffer
	(shimbun-fetch-url shimbun (nth 2 elem) t)
	(funcall (nth 3 elem) shimbun)))))

(defun shimbun-itmedia-anchordesk-get-headers (shimbun)
  (let ((case-fold-search t)
	(base (shimbun-index-url shimbun))
	headers)
    (goto-char (point-min))
    (while (re-search-forward "<a href=\"\\(/anchordesk/articles/\
\\([0-9][0-9]\\)\\([01][0-9]\\)/\\([0-3][0-9]\\)/news[0-9][0-9][0-9].html\\)\">"
			      nil t)
      (let ((url (shimbun-expand-url (match-string 1) base))
	    (date (shimbun-make-date-string
		   (+ 2000 (string-to-number (match-string 2)))
		   (string-to-number (match-string 3))
		   (string-to-number (match-string 4)))))
	(push (shimbun-create-header
	       0
	       (buffer-substring (point)
				 (if (search-forward "</a>" (point-at-eol) t)
				     (match-beginning 0)
				   (point-at-eol)))
	       (shimbun-from-address shimbun) date
	       (shimbun-rss-build-message-id shimbun url) "" 0 0
	       url)
	      headers)))
    (shimbun-sort-headers headers)))

(defun shimbun-itmedia-clean-text-page ()
  (let ((case-fold-search t) (start))
    (goto-char (point-min))
    (when (and (search-forward "<!--BODY-->" nil t)
	       (setq start (match-end 0))
	       (re-search-forward "<!--BODY ?END-->" nil t))
      (delete-region (match-beginning 0) (point-max))
      (delete-region (point-min) start)
      ;; Remove anchors to both the next page and the previous page.
      ;; These anchors are inserted into the head and the tail of the
      ;; article body.
      (skip-chars-backward " \t\r\f\n")
      (forward-line 0)
      (when (looking-at "<P ALIGN=\"CENTER\"><[AB]")
	(delete-region (point) (point-max)))
      (goto-char (point-min))
      (skip-chars-forward " \t\r\f\n")
      (when (looking-at "<P ALIGN=\"CENTER\"><[AB]")
	(delete-region (point-min) (point-at-eol))))
    (shimbun-remove-tags "<!-- AD START -->" "<!-- AD END -->")
    (shimbun-remove-tags "\
<IMG [^>]*SRC=\"http:/[^\"]*/\\(ad\\.itmedia\\.co\\.jp\\|\
a1100\\.g\\.akamai\\.net\\)/[^>]+>")
    (shimbun-remove-tags "\
<A [^>]*HREF=\"http:/[^\"]*/\\(ad\\.itmedia\\.co\\.jp\\|\
a1100\\.g\\.akamai\\.net\\)/[^>]+>[^<]*</A>")))

(defun shimbun-itmedia-retrieve-next-pages (shimbun base-cid url
						    &optional images cont)
  (let ((case-fold-search t) (next) (credit))
    (goto-char (point-min))
    (when (re-search-forward
	   "<b><a href=\"\\([^\"]+\\)\">$B<!$N%Z!<%8(B</a></b>\
\\|<span id=\"next\"><a href=\"\\([^\"]+\\)\">$B<!$N%Z!<%8$X(B</a></span>" nil t)
      (setq next (shimbun-expand-url (or (match-string 1) (match-string 2))
				     url)))
    (when (and (not cont)
	       (progn
		 (goto-char (point-min))
		 (re-search-forward "<!--$B"#%/%l%8%C%H(B-->[\t\n ]*" nil t))
	       (looking-at "<p\\( [^\n>]+>[^\n]+</\\)p>"))
      (setq credit (match-string 1))
      (when (string-match "<b>\\[ITmedia\\]</b>" credit)
	(setq credit nil)))
    (shimbun-itmedia-clean-text-page)
    (goto-char (point-min))
    (insert "<html>\n<head>\n<base href=\"" url "\">\n</head>\n<body>\n")
    (when credit
      (insert "<div" credit "div>\n"))
    (goto-char (point-max))
    (insert "\n</body>\n</html>\n")
    (when shimbun-encapsulate-images
      (setq images (shimbun-mime-replace-image-tags base-cid url images)))
    (let ((body (shimbun-make-text-entity "text/html" (buffer-string)))
	  (result (when next
		    (with-temp-buffer
		      (shimbun-fetch-url shimbun next)
		      (shimbun-itmedia-retrieve-next-pages shimbun base-cid
							   next images t)))))
      (list (cons body (car result))
	    (or (nth 1 result) images)))))

(defun shimbun-itmedia-make-contents (shimbun header)
  (let ((case-fold-search t)
	(base-cid (shimbun-header-id header)))
    (when (string-match "\\`<\\([^>]+\\)>\\'" base-cid)
      (setq base-cid (match-string 1 base-cid)))
    (let (body)
      (multiple-value-bind (texts images)
	  (shimbun-itmedia-retrieve-next-pages shimbun base-cid
					       (shimbun-header-xref header))
	(erase-buffer)
	(if (= (length texts) 1)
	    (setq body (car texts))
	  (setq body (shimbun-make-multipart-entity))
	  (let ((i 0))
	    (dolist (text texts)
	      (setf (shimbun-entity-cid text)
		    (format "shimbun.%d.%s" (incf i) base-cid))))
	  (apply 'shimbun-entity-add-child body texts))
	(when images
	  (setf (shimbun-entity-cid body) (concat "shimbun.0." base-cid))
	  (let ((new (shimbun-make-multipart-entity)))
	    (shimbun-entity-add-child new body)
	    (apply 'shimbun-entity-add-child new
		   (mapcar 'cdr (nreverse images)))
	    (setq body new))))
      (shimbun-header-insert shimbun header)
      (insert "MIME-Version: 1.0\n")
      (shimbun-entity-insert body)))
  (buffer-string))

(luna-define-method shimbun-make-contents ((shimbun shimbun-itmedia) header)
  (when (re-search-forward "\\([0-9]+\\)$BG/(B\\([0-9]+\\)$B7n(B\\([0-9]+\\)$BF|(B \
\\([0-9]+\\)$B;~(B\\([0-9]+\\)$BJ,(B $B99?7(B" nil t)
    (shimbun-header-set-date
     header
     (shimbun-make-date-string
      (string-to-number (match-string 1))
      (string-to-number (match-string 2))
      (string-to-number (match-string 3))
      (concat (match-string 4) ":" (match-string 5)))))
    (shimbun-itmedia-make-contents shimbun header))

(provide 'sb-itmedia)

;;; sb-itmedia.el ends here
