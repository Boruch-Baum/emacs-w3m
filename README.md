# emacs-w3m

This is a fork of the [emacs-w3m](https://github.com/emacs-w3m/emacs-w3m) git repository. The `master` branch here  provides my tested modifications to the original, while the `bb_upstream`branch here _should_ track the official repository's `master` branch. Additionally, this fork will have unique branches for development experiments, projects, and pending pull requests.

## Unique branches here

* `bb_history-scrub`<sub>[_pr #2_](https://github.com/emacs-w3m/emacs-w3m/pull/2)</sub>
  * New feature `w3m-history-scrub` (keybinding `S-C-delete`) to
    delete web browsing resources (history, cookies, cache, temporary
    files, form data).

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

* `bb_quibbles`<sub>[_pr #8_](https://github.com/emacs-w3m/emacs-w3m/pull/8)</sub>
  * This isn't supposed to be a feature branch, or a bug-fixing
    branch; it's for issues of programming style, efficiency,
    and documentation, but occassionally some substantive stuff may
    creep in by accident ...
  * BUGFIX: w3m-cleanup-temp-files: The regexp wasn't including
   tmp/cache files.

* `bb_utf`<sub>[_pr #9_](https://github.com/emacs-w3m/emacs-w3m/pull/9)</sub>
  * This branch is for converting the codebase to be fully UTF-8. The
    project is over 20 years old, and has a lot pre-unicode artifacts.
    I originally did this in September 2018 before the project moved
    to git on a [separate git
    repository](https://github.com/Boruch-Baum/emacs-w3m-development);
    with all the unrelated histories between the two, and an awful
    experience trying to work with that, I'm tring to commit based
    upon a straight git diff. On that other repository, the code was
    tested by me for the period September 2018 - January 2019  without
    any trouble noticed; OTOH, I wasn't using it with Japansese or
    other CJK codesets ...
