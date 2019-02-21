# emacs-w3m

[![Emacs logo]("https://download-mirror.savannah.gnu.org/releases/emacs/icons/emacs6-128.png)]

[//]: # License badges: https://gist.github.com/lukas-h/2a5d00690736b4c3a7ba
[![License: GPL
v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

[![Build Status](https://travis-ci.com/Boruch-Baum/emacs-w3m.svg?branch=bb_travis)](https://travis-ci.com/boruch-baum/emacs-w3m)



This is a fork of the
[emacs-w3m](https://github.com/emacs-w3m/emacs-w3m) git repository.
The `master` branch here provides my tested modifications to the
original, while the `bb_upstream`branch here _should_ track the
official repository's `master` branch. Additionally, this fork will
have unique branches for development experiments, projects, and
pending pull requests.

## Unique branches here

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

* `bb_filters`<sub>[_~~pr #7~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/7)</sub>
  * New filter: github main page for each repository
  * New filter: xkcd

* `bb_quibbles`
  * This isn't supposed to be a feature branch, or a bug-fixing
    branch; it's for issues of programming style, efficiency,
    and documentation, but occassionally some substantive stuff may
    creep in by accident ...
    * <sub>[_~~pr #8~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/8)</sub>
    * <sub>[_~~pr #13~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/13)</sub>
    * <sub>[_pr #15_](https://github.com/emacs-w3m/emacs-w3m/pull/15)</sub>
  * BUGFIX <sub>[_~~pr #8~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/8)</sub>: w3m-cleanup-temp-files: The regexp wasn't including
    tmp/cache files.

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
