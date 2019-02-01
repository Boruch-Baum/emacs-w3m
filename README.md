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

* `bb_filters`
  * New filter: github main page for each repository
  * New filter: xkcd
