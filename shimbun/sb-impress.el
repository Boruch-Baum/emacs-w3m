;;; sb-impress.el --- shimbun backend for www.watch.impress.co.jp -*- coding: iso-2022-7bit; -*-

;; Copyright (C) 2001, 2002, 2003, 2004, 2005, 2006, 2008
;; Yuuichi Teranishi <teranisi@gohome.org>

;; Author: Yuuichi Teranishi <teranisi@gohome.org>
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
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Code:

(require 'shimbun)
(require 'sb-rss)

(luna-define-class shimbun-impress (shimbun-rss) ())

(defvar shimbun-impress-url "http://www.watch.impress.co.jp/")

(defvar shimbun-impress-groups-alist
  '( ;; group (rss | link-regexp) start end address?
    ("enterprise" rss
     "<!-- $BK\J83+;O(B -->" "<!-- $BK\J8=*N;(B -->"
     "http://enterprise.watch.impress.co.jp/cda/rss/enterprise.rdf")
    ("pc" rss
     "<!-- $B5-;v8+=P$7(B -->" "<!-- /$B5-;v=pL>(B -->"
     "http://pc.watch.impress.co.jp/sublink/pc.rdf")
    ("dc" rss
     "<!-- $BK\J83+;O(B -->" "<!-- $BK\J8=*N;(B -->"
     "http://dc.watch.impress.co.jp/cda/rss/digicame.rdf")
    ("akiba" "<a href=\"\\(hotline/\\([0-9][0-9][0-9][0-9]\\)\\([0-9][0-9]\\)\
\\([0-9][0-9]\\)/\\([^>]*\\)\\)\">"
     "<!-- $B",",!!!z(B2002/10/01 Modify End$B!z!!",",(B -->"
     "\\(<!-- $B"-"-!!!z(B2002/10/01 Modify start$B!z!!"-"-(B -->\\|<!-- 500x144 -->\\)")
    ("av" rss
     "\\(<!-- title -->\\|<hr size=3>\\)" "\\(<!-- /$B5-;v=pL>(B -->\\|<!-- 500x144 -->\\)"
     "http://www.watch.impress.co.jp/av/sublink/av.rdf")
    ("game" rss
     "<!-- $B5-;vCf1{3+;O(B -->" "\\(<!-- $B5-;vCf1{=*N;(B -->\\|<!-- /$B5-;v=pL>(B -->\\)"
     "http://www.watch.impress.co.jp/game/sublink/game.rdf")
    ("k-tai" rss
     "<!-- ?$BK\J83+;O(B ?-->" "<!-- ?$BK\J8=*N;(B ?-->"
     "http://k-tai.impress.co.jp/cda/rss/ktai.rdf")
    ("internet" rss
     "<!-- $BK\J83+;O(B -->" "<!-- $BK\J8=*N;(B -->"
     "http://internet.watch.impress.co.jp/cda/rss/internet.rdf")
    ("bb" rss
     "<!-- ?$BK\J83+;O(B ?-->" "<!-- ?$BK\J8=*N;(B ?-->"
     "http://bb.watch.impress.co.jp/cda/rss/broadband.rdf")
    ("forest"
     "<a href=\"\\(/?article/\\([0-9][0-9][0-9][0-9]\\)/\\([0-9][0-9]\\)/\
\\([0-9][0-9]\\)/\\([^>]*\\)\\)\">"
     "<!-- ?\\($B"%"%"%%@%$%l%/%H4XO""%"%"%(B\\|$BK\J83+;O(B\\) ?-->"
     "<!-- ?\\($BK\J8=*N;(B\\|$B"#"#"#"#K\J8%;%k1&%9%Z!<%9%;%k"#"#"#"#(B\\|$B"#(Bgoostick$B3+;O"#(B\\) ?-->"
     "http://www.forest.impress.co.jp/")
    ("robot" rss
     "<!-- $BK\J83+;O(B -->" "<!-- $BK\J8=*N;(B -->"
     "http://robot.watch.impress.co.jp/cda/rss/robot.rdf")
    ("kaden" rss
     "<!-- $BK\J83+;O(B -->" "<!-- $BK\J8=*N;(B -->"
     "http://kaden.watch.impress.co.jp/cda/rss/kaden.rdf")
    ))

(defvar shimbun-impress-groups (mapcar 'car shimbun-impress-groups-alist))
(defvar shimbun-impress-from-address "www-admin@impress.co.jp")
(defvar shimbun-impress-x-face-alist
  '(("default" . "X-Face: F3zvh@X{;Lw`hU&~@uiX9J0dwTeROiIz\
oSoe'Y.gU#(EqHA5K}v}2ah,QlHa[S^}5ZuTefR\n ZA[pF1_ZNlDB5D_D\
JzTbXTM!V{ecn<+l,RDM&H3CKdu8tWENJlbRm)a|Hk+limu}hMtR\\E!%r\
9wC\"6\n ebr5rj1[UJ5zDEDsfo`N7~s%;P`\\JK'#y.w^>K]E~{`wZru")))
;;(defvar shimbun-impress-expiration-days 7)
(defvar shimbun-impress-ignored-subject-regexp "^\\(AD\\|PR\\):")

(luna-define-method shimbun-index-url ((shimbun shimbun-impress))
  (or (nth 4 (assoc (shimbun-current-group-internal shimbun)
		    shimbun-impress-groups-alist))
      (concat (shimbun-url-internal shimbun)
	      (shimbun-current-group-internal shimbun) "/")))

(luna-define-method shimbun-rss-build-message-id ((shimbun shimbun-impress)
						  url &optional date)
  (concat "<" (md5 url) "%" (shimbun-current-group shimbun)
	  "@www.watch.impress.co.jp>"))

(defsubst shimbun-impress-get-headers (shimbun &optional range)
  "Get headers without RSS."
  (let ((case-fold-search t)
	(regexp (nth 1 (assoc (shimbun-current-group-internal shimbun)
			      shimbun-impress-groups-alist)))
	ids
	headers)
    (goto-char (point-min))
    (while (re-search-forward regexp nil t)
      (let ((apath (match-string 1))
	    (year  (string-to-number (match-string 2)))
	    (month (string-to-number (match-string 3)))
	    (mday  (string-to-number (match-string 4)))
	    (uniq  (match-string 5))
	    (pos (point))
	    subject
	    id)
	(when (re-search-forward "</TD>" nil t)
	  (setq subject (buffer-substring pos (match-beginning 0))
		subject (with-temp-buffer
			  (insert subject)
			  (goto-char (point-min))
			  (when (re-search-forward "<br>\\($B!](B\\|$B!A(B\\).*" nil t)
			    (replace-match "")
			    (goto-char (point-min)))
			  (while (re-search-forward "[\r\n]" nil t)
			    (replace-match ""))
			  (shimbun-remove-markup)
			  (buffer-string))))
	(setq id (format "<%d%d%d%s%%%s@www.watch.impress.co.jp>"
			 year month mday uniq (shimbun-current-group-internal
					       shimbun)))
	(unless (member id ids)
	  (setq ids (cons id ids))
	  (push (shimbun-create-header
		 0
		 (or subject "")
		 (shimbun-from-address shimbun)
		 (shimbun-make-date-string year month mday)
		 id
		 "" 0 0
		 (shimbun-expand-url apath (shimbun-index-url shimbun)))
		headers))))
    headers))

(luna-define-method shimbun-headers :around ((shimbun shimbun-impress)
					     &optional range)
  (if (eq (nth 1 (assoc (shimbun-current-group-internal shimbun)
			shimbun-impress-groups-alist))
	  'rss)
      (delq nil
	    (mapcar
	     (lambda (header)
	       (let ((subject (shimbun-header-subject header)))
		 (unless (string-match shimbun-impress-ignored-subject-regexp
				       subject)
		   header)))
	     (luna-call-next-method)))
    (with-temp-buffer
      (shimbun-fetch-url shimbun (shimbun-index-url shimbun) t)
      (shimbun-remove-tags "<!--" "-->") ;; clear comment-outed html source
      (shimbun-impress-get-headers shimbun range))))

(luna-define-method shimbun-article-url :around ((shimbun shimbun-impress) header)
  (shimbun-real-url (luna-call-next-method)))

(luna-define-method shimbun-make-contents :around ((shimbun shimbun-impress)
						   &optional header)
  (let ((entry (assoc (shimbun-current-group-internal shimbun)
		      shimbun-impress-groups-alist))
	(case-fold-search t))
    (shimbun-set-content-start-internal shimbun (nth 2 entry))
    (shimbun-set-content-end-internal shimbun (nth 3 entry))
    ;; Fix broken image tags.  Should it be moved to shimbun.el?
    (goto-char (point-min))
    (while (re-search-forward
	    (eval-when-compile
	      (let ((s0 "[\t\n\f\r ]*")
		    (s1 "[\t\n\f\r ]+"))
		(concat "<" s0 "\\(img\\)" s1 "\\(src\\)"
			s0 "=" s0 "\"" s1 "/")))
	    nil t)
      (replace-match "<\\1 \\2=\"/"))
    (goto-char (point-min))
    (when  (and (re-search-forward "<!--\\($B"#(B*$B5-;v8x3+F|"#(B*\\| *$B8x3+F|(B *\\| *date *\\)-->" nil t)
		(or (re-search-forward "[^($B!J(B]*[($B!J(B]\\([0-9][0-9]\\)/\
\\([0-9][0-9]\\)/\\([0-9][0-9]\\)[ $B!!(B]*\\([0-9][0-9]:[0-9][0-9]\\)?" nil t)
		    (re-search-forward "[^<]*<br ?/?>[^0-9]*\\([0-9][0-9][0-9][0-9]\\)/\
\\([0-9][0-9]\\)/\\([0-9][0-9]\\) *\\([0-9][0-9]:[0-9][0-9]\\)?" nil t)
		    (re-search-forward "\\([0-9][0-9][0-9][0-9]\\)/\
\\([0-9][0-9]\\)/\\([0-9][0-9]\\) *\\([0-9][0-9]:[0-9][0-9]\\)?" nil t)))
      (let ((year  (string-to-number (match-string-no-properties 1)))
	    (month (string-to-number (match-string-no-properties 2)))
	    (day   (string-to-number (match-string-no-properties 3)))
	    (time  (or (match-string-no-properties 4)
		       "00:00"))
	    (date nil))
	(when (> 100 year)
	  (if (< 70 year)
	      (setq year (+ year 1900))
	    (setq year (+ year 2000))))
	(setq date (shimbun-make-date-string
		    year month day time))
	(when date
	  (shimbun-header-set-date header date))))
    (goto-char (point-min))
    (luna-call-next-method)))

(provide 'sb-impress)

;;; sb-impress.el ends here
