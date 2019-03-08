;;; w3m-download.el --- use wget, show progress, save metadata -*- coding: utf-8 ; lexical-binding: t -*-

;; Copyright © 2019 Boruch Baum <boruch_baum@gmx.com>

;; Authors:    Boruch Baum <boruch_baum@gmx.com>
;; Keywords:   w3m, WWW, hypermedia
;; Homepage:   http://emacs-w3m.namazu.org/
;; Repository: https://github.com/emacs-w3m/emacs-w3m

;; This file is part of `emacs-w3m'.

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

;; This file provides download features for the `emacs-w3m' project.
;; Although the project is meant to be a front-end to the `w3m'
;; browser, this code uses elisp and external back-end programs
;; (currently `wget') in order to offer additional download features
;; not native to `w3m':
;;
;;   1) Individual detailed download progress logs in dedicated
;;      buffers, automatically deleted upon successful completion.
;;
;;   2) Partial downloads are stored on disk, not in memory (yes...).
;;
;;   3) Resumption of partial downloads that were interrupted due to
;;      aborts or other failures.
;;
;;   4) Optional appending of meta-data to a download, currently
;;      offered for png and jpeg files. The image link's "alt" caption
;;      is stored as meta-data element "Exif.Image.ImageDescription".
;;      Note that enabling this option will modify the file's
;;      checksum. This option currently uses `exif' and `exiv2' as
;;      external back-end programs.
;;
;;      4.1) Some ways to view from the command-line an embedded
;;           caption are:
;;             exiv2 -g "Exif.Image.ImageDescription" foo.png
;;             exif --ifd=0 -t0x010e  foo.jpg |grep value



;;; TODO
;; + use emacs-w3m cache when appropriate
;; + integrate the code into the main-line
;; + danger of 'feature-creep':
;;   + an alist of extensions and metadata commands
;;   + an alist of download commands (eg. aria2, curl)
;;   + offloading to a dedicated downloader (eg. uget)
;;   + persistence across crashes (ie. maintain a disk file)
;;   + warn if more than 'n' concurrent downloads in progress
;;   + queue when more than 'n' concurrent downloads in progress
;;   + renice download processes
;;   + pause a download
;;   + delete a partially downloaded file when manually aborted
;;     (eg. when killing the progress buffer)



;;; Code



;;; Temporary compatability operation(s)

;; My development git fork has a different messaging standard, based
;; upon a pending pull request from my branch `bb_messaging', so
;; support this git branch being merged into a branch lacking that
;; other merge.
(eval-when-compile
  (if (not (fboundp 'w3m--message))
    (defun w3m--message (timeout face message)
      (w3m-message message))))



;;; Global variables

;;Global list of all running `w3m-download' processes.
(setq w3m--download-processes-list nil)



;;; User-options

(defcustom w3m-download-save-metadata t
  "Whether image downloads should save their descriptions.

This sets a feature for function `w3m-download' that operates on
jpeg and png images, and saves their link 'alt' caption strings
as the file's \"Exif.Image.ImageDescription\" metadata element.
From within emas-w3m you can see what the value would be by
moving point to the link (the string will appear in the
mini-buffer).

This operation is performed by calls to external programs; if
those programs are not executable on your system, a message will
be logged. Currently, the selected programs are hard-coded,
`exif' for jpeg files, and `exiv2' for png files.

Note that enabling this option will modify the file's checksum."
  :group 'w3m
  :type 'boolean)



;;; Buffer-local variables

(defvar-local w3m--download-metadata-operation nil
  "Text string of the complete shell command to be used to tag a
  download. It is set buffer-local in the download's progress
  buffer.")

(defvar-local w3m--download-local-proc nil
  "The process id of the download associated with the current
  download progress buffer.")



;;; Hook functions
;;
;; Maybe (see 'feature creep' discussion above) there should be hook
;; functions to optionally kill running downloads, for
;; `kill-emacs-hook' (without user interaction),
;; `kill-emacs-query-functions' (with user interaction), and the mode
;; exit hook for `emacs-w3m' (look it up, what is it?). Maybe there
;; should also be download recovery/resume/re-attach hooks for either
;; `after-init-hook', `emacs-startup-hook' or the startup hook for
;; `emacs-w3m' (look it up, what is it?)

(defun w3m--download-kill-all-asociated-processes ()
;; NOTE: This function can be used directly in development to clean up
;; any stray processes.
;;
;; TODO: Consider calling this function upon exiting emacs-w3m. The
;; argument against doing so is that it allows operating downloads to
;; continue. The argument for is that the progress of such processes
;; will no longer be trackable. The argument against would propose to
;; maintain a record on disk of `w3m--download-processes-list', and
;; offer the user to either re-create the tracking buffers, or to kill
;; the processes.
;;
;; TODO: Double check that if emacs crashes during a download, the
;; wget sub-processes also die. If for some reason not, we could
;; programmatically find the processes and possibly re-attach their
;; STDOUT/STDERR to a new tracking buffer, or we could kill them.
  (let (x)
    (while (setq x (pop w3m--download-processes-list))
      (when (processp (car x))
        (delete-process (car x)))
      (when (bufferp (cdr x))
        (kill-buffer (cdr x))))))



;;; Internal functions

(defun w3m--download-apply-metadata-tags ()
  "The download buffer is checked for the buffer-local variable
`w3m--download-metadata-operation' which is the literal text of
the shell command to run to tag the file."
  (when w3m--download-metadata-operation
    (goto-char (point-max))
    (insert (format "\nAdding meta-data to file... \n  %s\n"
                    w3m--download-metadata-operation))
    (shell-command w3m--download-metadata-operation t)))

(defun w3m--download-kill-associated-process ()
  "Hook function for `Kill-buffer-hook' for w3m download buffers.
PROC should have been set as a local variable at buffer creation."
  (if (not (processp w3m--download-local-proc))
    (w3m--message t 'w3m-warning "Warning: no process found to kill (w3m-download).")
   (delete-process w3m--download-local-proc)
   (setq w3m--download-processes-list
     (assq-delete-all w3m--download-local-proc w3m--download-processes-list))))

(defun w3m--download-sentinel (proc event)
  "This function is called when a download process 'changes state'.
Reference `set-process-sentinel'."
  (let ((buf (process-buffer proc)))
   (with-current-buffer buf
     (let ((inhibit-read-only t))
      (goto-char (point-max))
      (insert (concat "\n" event))
      (cond
       ((string-match "^open" event) t)
       ((string-match "^finished" event)
         ;; TODO: Maybe keep buffer open if there was an error in
         ;; performing the metadata tagging?
         (w3m--download-apply-metadata-tags)
         (w3m--message t t "Download completed successfully.")
         (setq w3m--download-processes-list
           (assq-delete-all proc w3m--download-processes-list))
         (kill-buffer buf))
       ((string-match "\\(deleted\\)\\|\\(terminated\\)\\|\\(interrupt\\)\\|\\(killed\\)" event)
         (insert (format "\nDownload encountered '%s' event." (substring event 0 -2)))
         (setq w3m--download-processes-list
           (assq-delete-all proc w3m--download-processes-list)))
       (t
         (w3m--message t 'w3m-error
            "Possible failed download. Check buffer %s for details." buf)
         (insert (format "\nPossible failed download. Encountered event '%s'.\n
 IMPORTANT: wget ocassionally reports errors even though it
 it really has successfully performed its download, so it's
 always a good idea to check the file itself.\n\n"
                 (substring event 0 -2)))
         (w3m--download-apply-metadata-tags)
         (setq w3m--download-processes-list
           (assq-delete-all proc w3m--download-processes-list))))))))

(defun w3m--download-process-filter (proc input-string)
  "Download buffers should handle 'carriage return' characters.
`wget' sends a \r at the beginning of every progress message in
order to over-write its prior message. "
  (let ((proc-buf (process-buffer proc))
        proc-mark point-moved-by-user)
   (when (buffer-live-p proc-buf)
     (with-current-buffer proc-buf
       (let ((inhibit-read-only t))
        ;; FIXME: Selecting and copying text from this buffer doesn't work
        ;; while the process is active. What is copied to the kill ring is
        ;; always the value of `input-string'. `save-excursion' only helps
        ;; us by giving us the ability to move `point'.
        (save-excursion
          (goto-char (point-max))
          (if (not (string= "\r" (substring input-string 0 1)))
            (insert input-string)
           (kill-line 0)
           (insert (substring input-string 1)))))))))

(defun w3m--download-using-wget (url save-path resume metadata)
  (let* (proc
        (buf (generate-new-buffer "*w3m-download*")))
    (with-current-buffer buf
      (insert (format "emacs-w3m download log\n
  Killing this buffer will abort the download!\n
Time: %s\nURL : %s\nExec: %s%s %s %s %s\n\n"
                (current-time-string) url "wget" (if resume " -c" " ") "-O" save-path url))
      (setq buffer-read-only t)
      (setq w3m--download-local-proc
        (apply 'start-process "w3m-download" buf
          (list "wget" (if resume "-c" "") "-O" save-path url)))
      (set-process-filter w3m--download-local-proc 'w3m--download-process-filter)
      (setq w3m--download-metadata-operation metadata)
      (push (cons w3m--download-local-proc buf) w3m--download-processes-list)
      (add-hook 'kill-buffer-hook 'w3m--download-kill-associated-process nil t)
      (set-process-sentinel w3m--download-local-proc 'w3m--download-sentinel)
      (goto-char (point-max))))
  (w3m--message t t "Requesting download."))

(defun w3m--download-validate-basename (url &optional verbose)
  "Returns a valid basename."
  ;; TODO: Check the project codebase to see if this is duplicated anywhere
  (let ((basename (file-name-nondirectory (w3m-url-strip-query url))))
    (when (string-match "^[\t ]*$" basename)
      (when (string-match
              "^[\t ]*$"
              (setq basename (file-name-nondirectory url)))
        (when verbose
          (w3m--message t 'w3m-warning
            "Undefined file-name. Saving as \'index.html\'")
          (sit-for 2))
        (setq basename "index.html")))
    basename))



;;; Interactive and user-facing functions

(defun w3m-download-using-wget (url &optional save-path interactive)
  "Download URL to `w3m-default-save-directory'.
With prefix argument, prompt for an alternate SAVE-PATH,
including alternate file name.

This function uses the external download program `wget', and
indicates the download progress in a dedicated buffer, which is
deleted upon success.

Additionally, for certain downloads, if variable
`w3m-download-save-metadata' is non-nil, then certain metadata
will be attached to the file."
  (interactive (list (w3m-active-region-or-url-at-point) nil t))
  (let* (basename resume extension metadata caption
        (num-in-progress (length w3m--download-processes-list))
        (others-in-progress-prompt
          (if (zerop num-in-progress) ""
           (format "(%d other download%s in progress)"
                   num-in-progress
                   (if (= 1 num-in-progress) "" "s"))))
        (download-prompt
          (concat "Download URL"
                  (if (zerop num-in-progress) ""
                   (concat "(" others-in-progress-prompt ")"))
                  ": "))
        (resume-prompt
          (format "%s%s"
            (if (zerop num-in-progress) ""
             (concat others-in-progress-prompt "\n"))
            "File(%s) already exists.
Are you trying to resume an aborted partial download? ")))
    (when (not url)
      (while (string-equal ""
               (setq url (w3m-input-url download-prompt nil
                           "" nil nil 'no-initial)))
        (w3m--message t 'w3m-error "A url is required")
        (sit-for 1)))
    (when current-prefix-arg
      (setq basename
        (w3m--download-validate-basename url))
      (setq save-path
        (w3m-read-file-name
          (format "Download %s to: " url)
          w3m-default-save-directory
          basename)))
    (setq save-path
      (concat
        (if save-path (file-name-directory save-path) w3m-default-save-directory)
        (w3m--download-validate-basename (or save-path url) t)))
    (when (and w3m-download-save-metadata
              (setq caption (w3m-image-alt))
              (setq extension (downcase (file-name-extension save-path))))
      (setq metadata
        (cond
         ((and (string= "png" extension) (executable-find "exiv2"))
          (format "exiv2 -M\"add Exif.Image.ImageDescription %s\" %s"
                  caption save-path))
         ((and (string-match "^jpe?g$" extension) (executable-find "exif"))
          (format "exif --create-exif --ifd=0 -t0x10e \
                   --set-value=\"%s\" --output=\"%s\" %s"
                  caption save-path save-path))
         (t nil))))
    (if (not (file-exists-p save-path))
      (w3m--download-using-wget url save-path nil metadata)
     (cond
      ((or (not interactive)
           (y-or-n-p (format resume-prompt save-path)))
       (w3m--download-using-wget url save-path t metadata))
      ((y-or-n-p (format "Overwrite? (%s)" save-path))
       (w3m--download-using-wget url save-path nil metadata))))))



;;; Development



;;; lgrep: uses of original function w3m-download
;;
;;    Conclusions: Most uses enable pulling target from the cache,
;;                 which isn't supported in my version.
;;
;; (defun mew-w3m-ext-url-fetch (dummy url)
;;   mew-w3m.el 378: (w3m-download url nil nil handler)
;;
;; (defun w3m-external-view (url &optional no-cache handler)
;;   w3m.el 7421: (w3m-download url nil no-cache handler)))
;;   w3m.el 7441: (success (w3m-download url file no-cache handler))
;;   w3m.el 7447: (w3m-download url nil no-cache handler))))))))))))
;;
;; (defun w3m-save-image ()
;;   w3m.el 7503: (w3m-download url)
;;
;; (defun w3m-download-this-url ()
;;   w3m.el 7567: (success (w3m-download url nil nil handler))
;;
;; (defun w3m-download-this-image ()
;;   w3m.el 7590: (success (w3m-download url nil nil handler))
;;
;; (defcustom w3m-lnum-actions-image-alist
;;   w3m-lnum.el 126: (?S (lambda (info) (w3m-download (nth 2 info))) "Save")
;;
;; (defun w3m-lnum-save-image ()
;;   w3m-lnum.el 1018: (cond (im (w3m-download im))
;;   w3m-lnum.el 1020: (w3m-download (nth 2 im)))



;;; lgrep: uses of cache, based upon w3m-cache-available-p, w3m-cache-request-contents
;;
;; (defun w3m-toggle-inline-images-internal (status
;;   w3m.el 4015: (w3m-cache-available-p iurl))))
;;
;; (defun w3m-w3m-retrieve-1 (url post-data referer no-cache counter handler)
;;   w3m.el 5776: (cachep (w3m-cache-available-p url))
;;   w3m.el 5808: (w3m-cache-request-contents url)
;;
;; (defun w3m--goto-url--valid-url (url reload charset post-data referer handler
;;   w3m.el 9848: (or (w3m-cache-available-p url)
;;
;; (defun w3m-about-retrieve (url &optional no-uncompress no-cache
;;   w3m.el 5873: ((w3m-cache-request-contents url)
;;
;; (defun w3m-show-error-information (url charset page-buffer)
;;   w3m.el 6574: (when (w3m-cache-request-contents url)
;;   w3m.el 6586: (when (w3m-cache-request-contents url)
