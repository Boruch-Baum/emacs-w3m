;;; sb-atmarkit.el --- shimbun backend for atmarkit -*- coding: iso-2022-7bit; -*-

;; Copyright (C) 2003, 2004, 2005 NAKAJIMA Mikio <minakaji@namazu.org>

;; Author: NAKAJIMA Mikio <minakaji@namazu.org>
;; Keywords: news
;; Created: Jun 15, 2003

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
;; Inc.; 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.

;;; Commentary:

;;; Code:

(require 'shimbun)
(require 'sb-rss)

(luna-define-class shimbun-atmarkit (shimbun-rss) ())

(defvar shimbun-atmarkit-from-address  "info@atmarkit.co.jp")
(defvar shimbun-atmarkit-coding-system 'euc-japan)

(defvar shimbun-atmarkit-group-path-alist
  '( ;; $B%K%e!<%97O(B
    ;; NewsInsight
    ("news". "http://www.atmarkit.co.jp/rss/news/rss2dc.xml")

    ;; $B%U%)!<%i%`7O(B
    ;; Windows Server Insider$B%U%)!<%i%`(B
    ("fwin2k" . "http://www.atmarkit.co.jp/rss/fwin2k/rss2dc.xml")
    ;; Insider.NET$B%U%)!<%i%`(B
    ("fdotnet" . "http://www.atmarkit.co.jp/rss/fdotnet/rss2dc.xml")
    ;; System Insider$B%U%)!<%i%`(B
    ("fsys" . "http://www.atmarkit.co.jp/rss/fsys/rss2dc.xml")
    ;; XML & Web Services$B%U%)!<%i%`(B
    ("fxml" . "http://www.atmarkit.co.jp/rss/fxml/rss2dc.xml")
    ;; Database Expert$B%U%)!<%i%`(B
    ("fdb". "http://www.atmarkit.co.jp/rss/fdb/rss2dc.xml")
    ;; Linux Square$B%U%)!<%i%`(B
    ("flinux" . "http://www.atmarkit.co.jp/rss/flinux/rss2dc.xml")
    ;; Master of IP Network$B%U%)!<%i%`(B
    ("fnetwork" . "http://www.atmarkit.co.jp/rss/fnetwork/rss2dc.xml")
    ;; Java Solution$B%U%)!<%i%`(B
    ("fjava" . "http://www.atmarkit.co.jp/rss/fjava/rss2dc.xml")
    ;; Security&Trust$B%U%)!<%i%`(B
    ("fsecurity". "http://www.atmarkit.co.jp/rss/fsecurity/rss2dc.xml")
    ;; IT Architect$B%U%)!<%i%`(B
    ("farc" . "http://www.atmarkit.co.jp/rss/farc/rss2dc.xml")

    ;; obsolete $B%U%)!<%i%`7O(B
    ;; Business Computing$B%U%)!<%i%`(B
    ("fbiz"  . "http://www.atmarkit.co.jp/rss/fbiz/rss2dc.xml")

    ;; $B!w(BIT$B<+J,@oN,8&5f=j(B
    ("jibun" . "http://jibun.atmarkit.co.jp/rss/rss2dc.xml")
    ))

(luna-define-method shimbun-groups ((shimbun shimbun-atmarkit))
  (mapcar 'car shimbun-atmarkit-group-path-alist))

(luna-define-method shimbun-index-url ((shimbun shimbun-atmarkit))
  (cdr (assoc (shimbun-current-group-internal shimbun)
	      shimbun-atmarkit-group-path-alist)))

(luna-define-method shimbun-rss-build-message-id
  ((shimbun shimbun-atmarkit) url date)
  (unless (string-match "http://[^\/]+/\\(.+\\)\\.html" url)
    (error "Cannot find message-id base"))
  (format "<%s%%%s@atmarkit.co.jp>" (match-string-no-properties 1 url)
	  (shimbun-current-group-internal shimbun)))

(luna-define-method shimbun-article-url ((shimbun shimbun-atmarkit) header)
  "http://www.atmarkit.co.jp/club/print/print.php")

(luna-define-method shimbun-make-contents ((shimbun shimbun-atmarkit) header)
  (re-search-forward "<body[^>]*>" nil t)
  (delete-region (point-min) (point))
  (goto-char (point-max))
  (re-search-backward "</body[^>]*>" nil t)
  (delete-region (point) (point-max))
  (goto-char (point-min))
  (shimbun-make-html-contents shimbun header))

(luna-define-method shimbun-clear-contents ((shimbun shimbun-atmarkit) header)
  (shimbun-remove-tags "<script" "</script *>")
  (shimbun-remove-tags "<noscript" "</noscript *>")
  (shimbun-remove-tags "<form" "</form *>"))

(provide 'sb-atmarkit)

;;; sb-atmarkit.el ends here
