# emacs-w3m

[![Emacs logo](https://download-mirror.savannah.gnu.org/releases/emacs/icons/emacs6-128.png)]
[![License: GPL
v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![MELPA](http://melpa.org/packages/w3m-badge.svg)](http://melpa.org/#/w3m)
[![Build Status](https://travis-ci.com/Boruch-Baum/emacs-w3m.svg?branch=bb_travis)](https://travis-ci.com/boruch-baum/emacs-w3m)



This is a fork of the
[emacs-w3m](https://github.com/emacs-w3m/emacs-w3m) git repository.
The `master` branch here provides my tested modifications to the
original, while the `bb-upstream`branch here _should_ track the
official repository's `master` branch. Additionally, this fork will
have unique branches for development experiments, projects, and
pending pull requests.

## Unique branches here

* `bb_magnet` <sub>[_pr #37_](https://github.com/emacs-w3m/emacs-w3m/pull/37)</sub>
  * New feature: Download torrents and magnet links. This feature
    requires three external command-line utilities from the
    `transmission` project (`transmission-daemon`, `transmission-cli`,
    and `transmission-remote-cli`).

* `bb_download` <sub>[_pr #27_](https://github.com/emacs-w3m/emacs-w3m/pull/27)</sub>
  * New feature: Use `wget` for downloads, when available.
  * New feature: Allow resumption of aborted downloads.
  * Downloads are queued, and the queue can be examined and
    re-arranged from a special buffer.
  * New feature: Detailed individual progress buffers for each
    download.
  * New feature: Download status display buffer to view, resequence,
    pause, resume, or kill any download.
  * New feature: Ability to abort a download just by killing its
    progress buffer.
  * New feature: The number of simultaneous downloads may be
    controlled, and can be dynamically changed.
  * New feature: Option to save an image's caption as metadata (this
    requires external programs `exif` for png files and `exiv2` for
    jpg files).
  * New feature: For file-systems that support extended attributes, it
    is possible to have `wget` save URL and HTTP header information as
    metadata.
  * New feature: Use `youtube-dl` when available, for downloading videos.
  * New file `w3m-download.el` collects most downloaded-related functions.

* `bb_history-scrub`<sub>[_pr #2_](https://github.com/emacs-w3m/emacs-w3m/pull/2)</sub>
  * New feature `w3m-history-scrub` (keybinding `S-C-delete`) to
    delete web browsing resources (history, cookies, cache, temporary
    files, form data).
  * Full screen messages. I snuck in a function to display important
    messages in a full-sized emacs-w3m buffer, not just in the echo
    area. This should really have been part of branch `bb_messaging`,
    and there is more related work to port over from my old
    development repository.
  * Quibble for `w3m-save-list`. Return a defined value based upon
    operation success or failure.

* `bb_history-display`<sub>[_pr #4_](https://github.com/emacs-w3m/emacs-w3m/pull/4)</sub>
  * New option `w3m-history-in-new-buffer`.
  * BUGFIXES: The global history display now properly handles page
    size control, ie. you can select where in the history to begin
    displaying and how many entries to display per page.
  * Cosmetic changes to the global history listing, including better timestamping.
  * Improved docstrings.

* `bb_filters`
  * New filter: github main page for each repository <sub>[_~~pr #7~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/7)</sub>
  * New filter: xkcd <sub>[_~~pr #7~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/7)</sub>
  * fix-filter: rt <sub>[_~~pr #30~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/30)</sub>
  * fix filter: stackexchange <sub>[_~~pr #31~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/31)</sub>

* `bb_background_tab`<sub>[_~~pr #32~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/32)</sub>
  * BUGFIX: allow new tabs to be loaded in background
  * New options: Functions `w3m-goto-url-new-session` and
    `w3m-copy-buffer` accept `C-u` to invert your default setting for
    background / foreground of new tabs.

* `bb_move_tabs`<sub>[_~~pr #33~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/33)</sub>
  * New feature: Change the order of tabs from within the buffer
    listing (ie. w3m-select-buffer). The new functions are
    `w3m-tab-move-next`, `w3m-tab-move-prior`, aliased to
    `w3m-tab-move-right`, `w3m-tab-move-left`.
  * The docstring for `w3m-select-mode` was updated and improved.
  * Console-friendly keybindings were added for functions
    `w3m-tab-move-left` (`C-c <`) and `w3m-tab-move-right` (`C-c >`).

* `bb_quibbles`
  * This isn't supposed to be a feature branch, or a bug-fixing
    branch; it's for issues of programming style, efficiency,
    and documentation, but occassionally some substantive stuff may
    creep in by accident ...
    * <sub>[_~~pr #8~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/8)</sub>
    * <sub>[_~~pr #13~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/13)</sub>
    * <sub>[~~_pr #15~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/15)</sub>
      Commit 99db1df of this turned out to be a small disaster, and ought
      to be reverted until it can be fixed. The worst of it was
      reverted in [_pr #23 ](https://github.com/emacs-w3m/emacs-w3m/pull/23)</sub>

  * BUGFIX <sub>[_~~pr #8~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/8)</sub>: w3m-cleanup-temp-files: The regexp wasn't including tmp/cache files.

* `bb_utf`<sub>[_~~pr #9~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/9)</sub>
  * This branch is for converting the codebase to be fully UTF-8. The
    project is over 20 years old, and has a lot pre-unicode artifacts.
    I originally did this on a [separate git
    repository](https://github.com/Boruch-Baum/emacs-w3m-development)
    in September 2018, before the project moved to git. With all the
    unrelated histories between the two, and an awful experience
    trying to work with those discrepancies, I'm trying here to
    perform a commit based upon a straight git diff. On that other
    repository, the code was tested by me for the period September
    2018 - January 2019 without any trouble noticed; OTOH, I wasn't
    using it with Japansese or other CJK codesets ...

* `bb_small_bug_fixes
  * w3m-dtree shouldn't abort on subdir permission restriction `<sub>[_~~pr #10~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/10)</sub>
  * w3m-favicon-convert needed basic bounds checking  `<sub>[_~~pr #21~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/21)</sub>

* `bb_messaging` <sub>[_pr #14_](https://github.com/emacs-w3m/emacs-w3m/pull/14)</sub>
  * Adds timeouts and colorization to w3m messages in the echo area. Also standardizes
    use of the w3m message function (use `w3m--message`) and the method of clearing
    the echo area (use (`w3m-message nil)`).
  * This is a large and hasn't been exhaustively tested, but the refactor was pretty
    straightforward, it seems to work, and if there is a mistake hiding in there, it
    shouldn't have earth-shatteringconsequences, so its ready for this master branch.

* `bb_clipboard`<sub>[_pr #12_](https://github.com/emacs-w3m/emacs-w3m/pull/12)</sub>
  * Functions that copy urls to the emacs kill-ring also copy them to
    the operating system clipboard.
  * NOTE: This is an imperfect pull-request in that it is only
    pre-configured for linux. For other operating systems, cons cells
    need to be added to the new variable `w3m-gui-clipboard-commands`
    with the OS type and the command string that OS would use to put
    text into its clipboard. At this point, do *NOT* use `M-x
    customize-variable` to modify the variable; the defcustom for the
    variable has a known bug. Other than that, it all seems to work great.

* `bb_travis`<sub>[_~~pr #16~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/16)</sub>
  * Adds multiple combinations of operating systems and emacs versions
    to .travis.yml
  * Demonstrates how to use travis 'badges' to embed images in README.md

  * Small bug fix to perform bounds checking.

* `bb_documentation`<sub>[_pr #22_](https://github.com/emacs-w3m/emacs-w3m/pull/22)</sub>
  * Suggested improvements to all documentation files.

* `bb_compiler_warnings`<sub>[_pr #24_](https://github.com/emacs-w3m/emacs-w3m/pull/24)</sub>

* `bb_sessions`<sub>[_based upon pr #26_](https://github.com/emacs-w3m/emacs-w3m/pull/26)</sub>
  * Change the way the session pop-up window behaves when deleting
    buffers and when exiting the pop-up, so that the currently
    displayed buffer is the one that remains 'on top'. This is mainly
    the contribution of Eugene Sharygin (@eush77) commit 390c4622eae.

* `bb_xemacs_kill` <sub>[_pr #28_](https://github.com/emacs-w3m/emacs-w3m/pull/28)</sub>
  * Remove support for xemacs. The upstream has not been in
    development for years, there doesn't seem to be a user-base, and I
    understand from the mailing list that it doesn't work anyway, so
    this will remove the cruft from the code-base.
  * This will probably be a slow process of incremental commits, just
    to sure there are no side-effects.
