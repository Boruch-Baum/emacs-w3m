;;; sb-w3m-dev.el --- shimbun backend for w3m-dev

;; Author: NAKAJIMA Mikio <minakaji@osaka.email.ne.jp>

;; Keywords: news

;;; Copyright:

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
(require 'sb-fml)

(luna-define-class shimbun-w3m-dev (shimbun-fml) ())

(defvar shimbun-w3m-dev-url "http://mi.med.tohoku.ac.jp/~satodai/w3m-dev/")
(defvar shimbun-w3m-dev-groups '("w3m-dev"))
(defvar shimbun-w3m-dev-coding-system 'iso-2022-jp)

(luna-define-method shimbun-reply-to ((shimbun shimbun-w3m-dev))
  "w3m-dev@mi.med.tohoku.ac.jp")

;;(luna-define-method shimbun-get-headers :before ((shimbun shimbun-w3m-dev)
;;						   &optional header)
;;  (shimbun-set-use-entire-index-internal shimbun t)
;;  (luna-call-next-method))

(provide 'sb-w3m-dev)

;;; sb-w3m-dev.el ends here
