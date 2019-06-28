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

See [below](#project-readme-documentation) for the project's [README documentation](#project-readme-documentation).

## Unique branches here

* `bb_content_type`<sub>[_pr #55_](https://github.com/emacs-w3m/emacs-w3m/pull/55)</sub>
  * Fixes many bugs related to recognizing a URL's content-type and
    respecting user's wishes for how to handle them. See the commit
    message of c2917160b7162049 and the pull-request message, for a
    full explanation.

* `bb_quick-search_POST-DATA_issue_0052`<sub>[_pr #54_](https://github.com/emacs-w3m/emacs-w3m/pull/54)</sub>
  * Fixes bug that was preventing the likes of duckduckgo searches
    from functioning when using the emacs-w3m 'quick-saerch' feature,
    eg. ddg:foo.

* `bb_toggle_unread`<sub>[_pr #50_](https://github.com/emacs-w3m/emacs-w3m/pull/50)</sub>
  * New feature: In the buffer select pop-up window, toggle whether a
    buffer is considered and labeled 'unread'. Bound to 'u'.

* `bb_sessions_copy`<sub>[_pr #49_](https://github.com/emacs-w3m/emacs-w3m/pull/49)</sub>
  * New feature: copy a session, bound to 'c' and 'C'.
  * Bugfixes: properly position point after operations.
  * Bugfix: delete a session when deleting its last element.

* `bb_local_files`<sub>[_pr #48_](https://github.com/emacs-w3m/emacs-w3m/pull/48)</sub>
  * Expands environment variables (eg. $HOME, $TEMPDIR, ~)
  * Respects documentation for w3m-local-find-file-regexps, in terms
    of what the included and excluded regexes do.
  * Doesn't hide a new find-file buffer when creating it using
    function w3m-goto-url-new-session.

* `bb_query_trackers`<sub>[_pr #47_](https://github.com/emacs-w3m/emacs-w3m/pull/47)</sub>
  * Allow users to remove trackers embedded in URLs.
  * See `defcustom` `w3m-strip-queries-alist`.

* `bb_page_anchors`<sub>[_pr #46_](https://github.com/emacs-w3m/emacs-w3m/pull/46)</sub>
  * Make old interactive feature usable: `w3m-search-name-anchor` to
    jump to an HTML anchor on the current page.
  * Default keybinding 'C-c j'.

* `bb_sessions_merge`<sub>[_~~pr #43~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/43)</sub>
  * New feature: copy session element(s) into another session.
  * Default keybinding 'm', 'M'.

* `bb_sessions_2`<sub>[_~~pr #42~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/42)</sub>
  * Bugfix: Don't quit the session buffer after opening a session.
  * Bugfix: Retain session buffer in its window (it was being replaced
    with the created buffer(s)).
  * Bugfix: Don't create duplicate buffers.

* `bb_sessions`<sub>[_based upon pr #26_](https://github.com/emacs-w3m/emacs-w3m/pull/26)</sub>
  * Change the way the session pop-up window behaves when deleting
    buffers and when exiting the pop-up, so that the currently
    displayed buffer is the one that remains 'on top'. This is mainly
    the contribution of Eugene Sharygin (@eush77) commit 390c4622eae.

* `bb_magnet` <sub>[_~~pr #37~~
  merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/37), [_~~pr
  #38~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/38)</sub>
  * New feature: Download torrents and magnet links. This feature
    requires external command-line utilities from the
    `transmission` project (`transmission-daemon`, `transmission-cli`)
    and recommends `transmission-remote-cli` from the same source.

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
  * Bugfixes: The global history display now properly handles page
    size control, ie. you can select where in the history to begin
    displaying and how many entries to display per page.
  * Cosmetic changes to the global history listing, including better timestamping.
  * Improved docstrings.

* `bb_bookmarks` <sub>[_~~pr #40~~ merged!_](https://github.com/emacs-w3m/emacs-w3m/pull/40)</sub>
  * Improvements: w3m-bookmark-add-all prompts only once for a section
    name, using a sane timestamp-based default, doesn't add bookmark
    buffers to the bookmark file, auto-refreshes bookmark buffers, and
    improve error handling.
  * Bugfixes: Operate in all display modes, correct coding errors for
    functions string-match and switch-to-buffer.

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
  * Use clone-buffer to copy tabs in order to improve performance.

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

* `bb_view_url` <sub>[~~_pr #44~~_](https://github.com/emacs-w3m/emacs-w3m/pull/44)</sub>
  * remove duplicate code by replacing use of `w3m-view-this-url-1'
    with calls to w3m-goto-url{,-new-session}.

* `bb_documentation`<sub>[_pr #22_](https://github.com/emacs-w3m/emacs-w3m/pull/22)</sub>
  * Suggested improvements to all documentation files.

* `bb_compiler_warnings`<sub>[_pr #24_](https://github.com/emacs-w3m/emacs-w3m/pull/24)</sub>

* `bb_xemacs_kill` <sub>[_pr #28_](https://github.com/emacs-w3m/emacs-w3m/pull/28)</sub>
  * Remove support for xemacs. The upstream has not been in
    development for years, there doesn't seem to be a user-base, and I
    understand from the mailing list that it doesn't work anyway, so
    this will remove the cruft from the code-base.
  * This will probably be a slow process of incremental commits, just
    to be sure there are no side-effects.

## Project README documentation

Use Emacs as a full-featured and secure internet browser!<br>
(Does not support javascript).

<a href="https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html">
   <img alt="license: GPL 2.0" src="https://img.shields.io/badge/License-GPL%20v2-blue.svg"></img></a>

<p>
<table border=1 cellpadding=10><tr><td>
<b>NEWS! (2019-02)</b>: We are now on github!<br>
<ul>
<li><a href="http://github.com/emacs-w3m/emacs-w3m/">Repository home
  page</a><br>
<li><a href="https://emacs-w3m.github.io">Project home page</a><br>
<li><a href="https://github.com/emacs-w3m/emacs-w3m/wiki">Wiki @ github</a>
(but <a href="https://www.emacswiki.org/emacs/emacs-w3m">emacswiki</a> is still our primary)
</ul></td></tr></table>
</p>


<p>
<ul>
 <li><a href="image/screenshot-en.html">Screenshots</a>
 <li><a href="#features">Features</a>
 <li><a href="#history">History</a>
 <li><a href="#download">Download</a>
 <li><a href="#requirements">Requirements</a>
 <li><a href="#installation">Installation</a>
 <li><a href="#configuration">Configuration</a>
 <li><a href="http://emacs-w3m.namazu.org/info/emacs-w3m.html">Usage</a>
 <li><a href="#mailing_list">Mailing List</a>
 <li><a href="#link">Links</a>
 <li><a href="#contact">Contact</a>
</ul>


<hr>
<h2><a name="features">Features</a></h2>
<ul>
 <li>Tabs</li>
 <li>Images</li>
 <li>Forms</li>
 <li>HTTPS preferred</li>
 <li>Bookmark management</li>
 <li>Cookie management</li>
 <li>Session management</li>
 <li>History management</li>
 <li>Asynchronous operations</li>
 <li>Greasemonkey-type filtering</li>
 <li>Quick-search</li>
 <li>ELisp scripting</li>
 <li><a href=http://emacs-w3m.namazu.org/info>More (on-line Info documentation)</a> ...</li>
</ul>

<hr>
<h2><a name="history">History</a></h2>

This project has been in active development continuously since 2000.
<p>
Originally, there had been a separate project <i>Emacs/W3</i> which in its
time was the most popular web browser on Emacs, but it suffered from
slow operation. The decision was made to create this alternative,
based upon <b>Akinori Ito</b>'s
<a href="http://w3m.sourceforge.net/index.en.html">w3m</a> text-mode
pager which had WWW capability.
<p>
As of 2019, the project has been actively developed and supported for
nearly two decades, but since 2005 it has been releasing updates in
a "rolling" manner, directly from its CVS repository. Since early
2019, the project has also been hosted on <a href=https://melpa.org/#/w3m>MELPA</a>
and <a href=https://github.com/emacs-w3m/emacs-w3m>github</a>.
<p>
 Here's the history of the old milestones under the prior system of
issuing '<i>stable</i>' releases:
</p>
<ul>
 <li>github rolling release, from 2019
 <li>CVS rolling release, from 2005 to 2018+
 <li><a href="http://emacs-w3m.namazu.org/ml/7990">Emacs-w3m-1.4.4 was released</a> on March 25th, 2005.
 <li><a href="http://emacs-w3m.namazu.org/ml/7039">Emacs-w3m-1.4.3 was released</a> on August 17th, 2004.
 <li><a href="http://emacs-w3m.namazu.org/ml/7004">Emacs-w3m-1.4.2 was released</a> on July 14th, 2004.
 <li><a href="http://emacs-w3m.namazu.org/ml/6989">Emacs-w3m-1.4.1 was released</a> on July 7th, 2004.
 <li>All services were restored on June 23rd, 2004.
      All contents of this site and CVS repository had been throughly inspected.
 <li><a href="http://emacs-w3m.namazu.org/announce-en.txt">This site was cracked</a> on May 23rd, 2004.
 <li><a href="http://emacs-w3m.namazu.org/ml/6759">Emacs-w3m-1.4 was released</a> on April 29th, 2004.
</ul>


<hr>
<h2><a name="download">Download</a></h2>

Since 2019, the official current version is always available from
<a href=https://melpa.org/#/w3m>MELPA</a> and
<a href=https://github.com/emacs-w3m/emacs-w3m>github</a>, as well as
from our legacy CVS repository. For most users, it will probably be
most convenient to download, install, and maintain the package from
within emacs via MELPA.
<p>
For people who would like to use the legacy
<a href=http://www.nongnu.org/cvs/>cvs</a><font size=1>[<a href=https://en.wikipedia.org/wiki/Concurrent_Versions_System>1</a>]</font>
repository, the following commands will download the package once you
have cvs installed.
</p>
<blockquote>
<pre>
% cvs -d :pserver:anonymous@cvs.namazu.org:/storage/cvsroot login
CVS password: # No password is set.  Just hit Enter/Return key.
% cvs -d :pserver:anonymous@cvs.namazu.org:/storage/cvsroot co emacs-w3m
</pre>
</blockquote>
<p>
Source code access to the legacy cvs repository with <a href="http://cvs.namazu.org/Development/emacs-w3m/">ViewVC</a>
is also available.
</p>

<ul>
 <li>Historical versions:
     <ul>
      <li><code><a href="http://emacs-w3m.namazu.org/emacs-w3m-1.4.4.tar.gz">emacs-w3m-1.4.4.tar.gz</a></code> (March 25th, 2005)
      <li><code><a href="http://emacs-w3m.namazu.org/emacs-w3m-1.4.3.tar.gz">emacs-w3m-1.4.3.tar.gz</a></code> (August 17th, 2004)
      <li><code><a href="http://emacs-w3m.namazu.org/emacs-w3m-1.4.2.tar.gz">emacs-w3m-1.4.2.tar.gz</a></code> (July 14th, 2004)
      <li><code><a href="http://emacs-w3m.namazu.org/emacs-w3m-1.4.1.tar.gz">emacs-w3m-1.4.1.tar.gz</a></code> (July 7th, 2004)
      <li><code><a href="http://emacs-w3m.namazu.org/emacs-w3m-1.4.tar.gz">emacs-w3m-1.4.tar.gz</a></code> (April 29th, 2004)
      <li><code><a href="http://emacs-w3m.namazu.org/emacs-w3m-1.3.6.tar.gz">emacs-w3m-1.3.6.tar.gz</a></code> (July 18th, 2003)
      <li><code><a href="http://emacs-w3m.namazu.org/emacs-w3m-1.3.5.tar.gz">emacs-w3m-1.3.5.tar.gz</a></code> (July 5th, 2003)
      <li><code><a href="http://emacs-w3m.namazu.org/emacs-w3m-1.3.4.tar.gz">emacs-w3m-1.3.4.tar.gz</a></code> (June 18th, 2003)
      <li><code><a href="http://emacs-w3m.namazu.org/emacs-w3m-1.3.3.tar.gz">emacs-w3m-1.3.3.tar.gz</a></code> (October 25th, 2002)
      <li><code><a href="http://emacs-w3m.namazu.org/emacs-w3m-1.3.2.tar.gz">emacs-w3m-1.3.2.tar.gz</a></code> (September 3rd, 2002)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.3.1.tar.gz">w3m_el-1.3.1.tar.gz</a></code> (July 17th, 2002)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.3.tar.gz">w3m_el-1.3.tar.gz</a></code> (July 7th, 2002)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.2.8.tar.gz">w3m_el-1.2.8.tar.gz</a></code> (June 20th, 2002)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.2.7.tar.gz">w3m_el-1.2.7.tar.gz</a></code> (June 3rd, 2002)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.2.6.tar.gz">w3m_el-1.2.6.tar.gz</a></code> (March 12th, 2002)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.2.5.tar.gz">w3m_el-1.2.5.tar.gz</a></code> (March 2nd, 2002)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.2.4.tar.gz">w3m_el-1.2.4.tar.gz</a></code> (January 8th, 2002)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.2.3.tar.gz">w3m_el-1.2.3.tar.gz</a></code> (December 21st, 2001)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.2.2.tar.gz">w3m_el-1.2.2.tar.gz</a></code> (December 6th, 2001)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.2.1.tar.gz">w3m_el-1.2.1.tar.gz</a></code> (November 12th, 2001)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.2.tar.gz">w3m_el-1.2.tar.gz</a></code> (November 6th, 2001)
      <li><code><a href="http://emacs-w3m.namazu.org/w3m_el-1.0.tar.gz">w3m_el-1.0.tar.gz</a></code> (May 9th, 2001)
     </ul>
</ul>
<p>

<hr>
<h2><a name="requirements">Requirements</a></h2>
<ul>
<li>Emacs versions
  <p>Emacs-w3m supports the latest two major stable versions of Emacs.
     Thus, when the latest stable Emacs was 26.1, Emacs-w3m was
     supporting versions 26.1, 25.3, 25.2, and 25.1.</p>

  <p>Older versions of Emacs may still be able to successfully use the
    current version of emacs-w3m, but as the current versions of
    Emacs or ELisp themselves change, deprecate, or remove features,
    the latest version of emacs-w3m can be expected to keep pace,
    and thus will gradually lose functionality when run in older
    Emacs versions.</p>

  <p>Pre-release versions of Emacs and even development snapshots are
    unofficially supported, as we do try to keep the code up-to-date,
    so if you are using a "bleeding edge" Emacs version and do
    experience a problem, please do file a bug report by contacting
    us on our mailing list!</p>

<li>w3m
  <p>Emacs-w3m requires the latest version of <a href="https://salsa.debian.org/debian/w3m">w3m</a>.</p>
</ul>

Optionally, if you would like to use
the <a href="info/goto.cgi?file=emacs-w3m&node=Shimbun+Library">shimbun
library</a> included in the emacs-w3m distribution, you have to
install the Emacs
packages <a href="https://github.com/wanderlust/apel">APEL</a> and
<a href="https://github.com/wanderlust/flim">FLIM</a>.</p>
</ul>

<hr>
<h2><a name="installation">Installation</a></h2>
If you are installing from the  MELPA
repository, the install process follows the standard MELPA procedure.
The rest of this section describes how to install manually from source.
<p>
Before installing emacs-w3m, check whether your environment
meets <a href="#requirements">the requirements</a>.
</p>
<dl>
 <dt><h3><a name="installation_unix">Installing emacs-w3m on UNIX-like systems</a></h3>
 <dd><p>
     First, run the <code>configure</code> script.
     </p>
<blockquote>
<pre>
% ./configure
</pre>
</blockquote>
     <p>
     However, if you've installed APEL and FLIM in non-standard
     directories (ie. somewhere not on the <b>default</b>
     <code>load-path</code>), you must specify them
     using the <em>--with-addpath</em> option as follows:
     </p>
<blockquote>
<pre>
% ./configure --with-addpath=/your/path/to//apel:/your/path/to/flim
</pre>
</blockquote>
     <p>
     Next, execute the following commands to install emacs-w3m to an
     appropriate directory.
     </p>
<blockquote>
<pre>
% make
# make install
</pre>
</blockquote>

 <dt><h3><a name="installation_nonunix">Installing on non-UNIX-like systems</a></h3>
 <dd><p>
     If you cannot execute the <code>configure</code> script on your
     system, or if no <code>make</code> command is available, execute
     the following command:
     </p>
<blockquote>
<pre>
# emacs -batch -q -no-site-file -l w3mhack.el NONE -f w3mhack-nonunix-install
</pre>
</blockquote>
     <p>
     However, if APEL, FLIM (or any other library) are installed in
     non-standard directories (ie. somewhere not on the <b>default</b>
     <code>load-path</code>), the installer won't find them.  In such a
     case, it is necessary to tell the installer where they are, as
     shown below:
     </p>
<blockquote>
<pre>
# emacs -batch -q -no-site-file -l w3mhack.el //c/your/path/to/apel://c/your/path/to/flim -f w3mhack-nonunix-install
</pre>
</blockquote>
</dl>


<hr>
<h2><a name="configuration">Configuration</a></h2>
<p>
Emacs-w3m has many configuration options, but the minimum that is required
is just to put this line into your <code>~/.emacs</code> file:
</p>
<blockquote>
<pre>
(require 'w3m-load)
</pre>
</blockquote>
<p>
Just type <i>M-x w3m</i>, and you can use emacs-w3m.
</p>
<p>
In order to handle text/html part with emacs-w3m under SEMI MUAs such as
Wanderlust, put the following line in your
<code>~/.emacs</code> file:
</p>
<blockquote>
<pre>
(require 'mime-w3m)
</pre>
</blockquote>
<p>
For more details, see <a href="http://emacs-w3m.namazu.org/info/emacs-w3m.html">Info manual</a>,
or browse the emacs-w3m customization group within Emacs.
</p>

<hr>
<h2><a name="mailing_list">Mailing List</a></h2>
<p>
The project mailing list, <code>emacs-w3m&#64;namazu.org</code>, is
bi-lingual Japanese / English. It is open to the public, and its
archive is accessible via <a href="http://emacs-w3m.namazu.org/ml/index.html">the emacs-w3m
mailing list archive</a>. You can also subscribe to the
gmane.emacs.w3m newsgroup which is gateway'd to this list
bidirectionally (connect to news.gmane.org using nntp).
</p>
<p>
If you want to subscribe to this list, check
<a href="http://www.namazu.org/disclaimer.html.en">the disclaimer</a>
and send a mail containing
</p>
<blockquote>
<pre>
subscribe Your Name
</pre>
</blockquote>
<p>
(not your email address) in the body to
<code>emacs-w3m-ctl&#64;namazu.org</code>.
To unsubscribe, send a mail containing just
</p>
<blockquote>
<pre>
# bye
</pre>
</blockquote>
<p>
in the body to <code>emacs-w3m-ctl&#64;namazu.org</code>.
</p>
<hr>
<h3>Follow us on github</h3>
If you have a github account, you can use github's features
to 'watch' and 'star' the project.
<hr>
<h2><a name="link">Related Links</a></h2>
<ul>
 <li><a href="https://www.emacswiki.org/emacs/emacs-w3m">emacs-w3m</a>
   (EmacsWiki)
 <li><a href="http://w3m.sourceforge.net/index.en.html">w3m</a>
 <li><a href="https://github.com/wanderlust/apel">APEL</a>
 <li><a href="https://github.com/wanderlust/flim">FLIM</a>
 <li><a href="https://github.com/vermiculus/sx.el">sx.el</a>,
  StackExchange interface for Emacs
 <li><a href="https://github.com/vermiculus/magithub">magithub</a>,
 Github interface for Emacs
</ul>


<hr>
<h2><a name="members">Authors</a></h2>
(alphabetical order in the family names)
<ul>
 <li>Akihiro Arisawa
 <li>Boruch Baum
 <li>Tsuyoshi CHO
 <li>Shun-ichi GOTO
 <li>Kazuyoshi KOREEDA
 <li>MIYOSHI Masanori
 <li>Mikio NAKAJIMA
 <li>Yoichi NAKAYAMA
 <li>Keisuke Nishida
 <li>Masaru Nomiya
 <li>OHASHI Akira
 <li>Koichiro Ohba
 <li>Hideyuki SHIRAI
 <li>Taiki SUGAWARA
 <li><a href="http://namazu.org/~satoru/">Satoru Takabayashi</a>
 <li>Yuuichi Teranishi
 <li><a href="http://namazu.org/~tsuchiya/">TSUCHIYA Masatoshi</a>
 <li><a href="https://www.yamaoka.cc/">Katsumi Yamaoka</a>
</ul>
<p>
Thanks to the many other people for their great contributions.
</p>


<hr>
<h2><a name="contact">Contact</a></h2>
<p>
In order to contact us, please send a mail to
<code>emacs-w3m&#64;namazu.org</code>.  This
<a href="#mailing_list">mailing list</a> is gateway'd to the
gmane.emacs.w3m newsgroup bidirectionally and accepts even messages
posted from nonsubscribers.
</p>

<hr>
<h3>Bug reports and feature requests</h3>
Now that the project is on github, you can there submit bug reports or
feature requests, using the github
'<a href="https://github.com/emacs-w3m/emacs-w3m/issues">issues</a>'
interface.

<hr>
<h3>Code contributions</h3>
Prior to migratng to git, the project accepted patch files via email.
While that is still possible, in most casses it's probably best for
all concerned to post submissions via github, prferably as a pull request.
<p>
<font size=-1><i>last updated 2019-02-19</i></font>
