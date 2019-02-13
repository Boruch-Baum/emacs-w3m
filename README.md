# emacs-w3m

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

* `bb_quibbles`<sub>[_~~pr #8~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/8)</sub>
  * This isn't supposed to be a feature branch, or a bug-fixing
    branch; it's for issues of programming style, efficiency,
    and documentation, but occassionally some substantive stuff may
    creep in by accident ...
  * BUGFIX: w3m-cleanup-temp-files: The regexp wasn't including
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

* `bb_messaging`
  * Adds timeouts and colorization to w3m messages in the echo area. I
    haven't yet made a pull request for this, because it was a large
    refactor and I haven't tested it fully, but the refactor was
    pretty straightforward, it seems to work, and if there is a
    mistake hiding in there, it shouldn't have earth-shattering
    consequences, so its ready for this master branch.

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
