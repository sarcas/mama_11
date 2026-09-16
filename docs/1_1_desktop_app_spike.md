Hey Claude. I'd like to spike something, so we can be loose with it.

I've got the beginnings of a Hanami backend here that I want to use to
  build a MacOS desktop app. The DSL to use for this is Glimmer I think (https://github.com/AndyObtiva/glimmer), but I'm happy with other options.

Ideally we're replacing an app I already have, so it'll injest a JSON data file I can define later.

A screenshot is provided at digimo_screenshot.png

The spike is to understand
a) how easy is it to build a mac desktop app using Ruby, Hanami and Glimmer
b) what does the rough shape of that solution look like?

## Spike findings (2026-09-16)

**Verdict: yes, it works.** Ruby + Hanami (in-process, no HTTP) + `glimmer-dsl-libui`
can drive a real native macOS window, read/write SQLite through the existing
ROM repos, and be packaged into a double-clickable `.app` with its own icon.
See `desktop/` for the code and `CONTEXT.md` for the domain model that came
out of grilling this (Teammate, Meeting, Note, Topic, Tag, Sentiment).

### Difficulties hit along the way

- **Ruby 4.0 dropped `fiddle` from default gems.** `libui` (a `glimmer-dsl-libui`
  dependency) still does a bare `require "fiddle/import"` without declaring
  it. Silent `LoadError` until you add `gem "fiddle"` explicitly.
- **Zeitwerk didn't autoload `lib/mama_11/*` for a standalone script.**
  `desktop/app.rb` isn't booted the way `bin/hanami` boots the app, so
  `Mama11::Topic` needed an explicit `require_relative` rather than relying
  on autoloading like the rest of the codebase does.
- **`.env` loading blocks in sandboxed/non-interactive shells.** Not a
  concern for you running locally, but worth knowing if this is ever driven
  from CI or another automated context.
- **libui tables have no simple "selected row" event** in this gem version —
  had to fall back to a plain button per row (teammate list, meeting-date
  selector, topic selector) instead of a real list/table widget. That also
  means no native "selected" highlight; we fake it with a `●` prefix.

  Dug into *why*, since the original Digamo app was SwiftUI and definitely
  had real `NSTableView`-backed selection — this turns out to be a pure
  library/binding gap, not a macOS limitation:
  - The vendored `libui.dylib` (checked via `nm -gU`) exports no
    `uiTable*Selection*` symbols at all, while `uiComboboxOnSelected` /
    `uiRadioButtonsOnSelected` do exist — selection as a concept exists in
    this C library, it's just never been wired up for `Table`.
  - The Ruby `libui` gem vendors "the official release of the libui shared
    library... alpha4.1" (its own README) — a tag from the original,
    now-stalled `andlabs/libui`, not `libui-ng`, the actively maintained
    fork it's named after.
  - `libui-ng`'s real `ui.h` (checked directly on GitHub) *does* have a full
    table-selection API — `uiTableSelectionMode`, `uiTableGetSelection` /
    `SetSelection`, `uiTableOnSelectionChanged`, `uiTableOnRowClicked` /
    `OnRowDoubleClicked` — but its `CHANGELOG.md` lists all of it under
    "[Unreleased]": only on `master`, no tagged release ships it, and
    `libui-ng` publishes no prebuilt binaries via GitHub Releases at all.
  - So getting real selection on this stack means: build `libui-ng` from
    source (Meson) → point the gem at the result with the `LIBUIDIR` env var
    → declare the missing functions from your own code with
    `LibUI::FFI.try_extern` → teach `glimmer-dsl-libui`'s `table_proxy.rb`
    to use them. Only that last step needs gem-level work — see "Updating
    the vendored native libraries" below.
    SWT wraps the OS table widget directly and has this today — but see the
    SWT section below: its vendored toolkit does not render here, so it is
    not actually an available escape hatch right now.
- **Platypus (the packaging tool `glimmer-dsl-libui`'s own README
  recommends) is Homebrew-disabled** for failing Gatekeeper (disabled
  2026-09-01). Had to hand-roll a minimal `.app` bundle instead (see
  `desktop/Mama 1-1 Spike.app/`) — which works, but:
- **A hand-rolled `.app` launched from Finder has almost no `PATH`** — no
  chruby/rbenv shims from your shell rc files. The launcher script hardcodes
  absolute paths to your Ruby (`/Users/james/.rubies/ruby-4.0.5/...`) and
  Bundler. Fine for a personal spike, not portable to another machine or
  even a future Ruby upgrade without editing the script.

### Open/unknown questions for a deliberate build

- **Sentiment values are undecoded.** The Digamo export's `meetingSentiment`
  / `personalSentiment` / `counterpartSentiment` are opaque integers with no
  label in the data itself; the spike just shows "Option N". Reproducing the
  real emoji picker needs the actual mapping (from memory, or Digamo's
  source if available).
- **Topic 0–8 ordering is inferred, not confirmed.** We mapped identifiers to
  names by matching the screenshot's visual order against the export's
  `identifier` values — plausible, but never checked against Digamo's own
  source/config.
- **`flag` field in the export is unexplained** (always `0` in the real
  data) — unclear if it's the screenshot's ⚠️ warning icon, something else,
  or dead data.
- **"Last Note" per topic (across all of a teammate's meetings) isn't
  built.** The screenshot's topic table shows a last-written date per topic
  spanning meetings; that needs a cross-meeting query we haven't written.
- **Team Summary, Status, and Learn** (three of the five toolbar items in
  the screenshot) are entirely unscoped — no idea yet what they'd need to do
  for a real replacement of Digamo.
- **Search ("Search notes for Teammate") and tag-filtering** aren't built.

### JRuby/SWT counter-spike (2026-09-16)

Before deciding between `glimmer-dsl-libui` (CRuby) and `glimmer-dsl-swt`
(JRuby), we checked the one thing that could have killed the JRuby path
outright: **does this app's data layer even work on JRuby?** `sqlite3` (what
`hanami-db` uses on CRuby) is a native C extension and can't load under
JRuby at all.

Ran an isolated throwaway spike (not part of the repo — lived in a scratch
dir, `sequel` + `jdbc-sqlite3` + `rom-sql`, nothing touching `mama_11`'s own
Gemfile): booted a ROM container against SQLite via the JDBC adapter,
inserted and read back a row. **It works.** So the JRuby path is genuinely
viable, not ruled out by the DB layer — though this only proves `rom-sql`
itself is fine; `hanami-db`'s own assumptions on top of that are still
untested.

Friction hit getting there, worth knowing before committing to JRuby:

- **A JDK has to be installed and wired up separately.** JRuby needs a JVM;
  none was present (chruby had a `jruby-10.1.1.0` install already, but
  pointed at a since-removed `openjdk15`). Installed via
  `brew install openjdk`, then had to set `JAVA_HOME` explicitly — Homebrew's
  JDK isn't auto-registered with `/usr/libexec/java_home`.
- **Switching to JRuby by hand (rather than through chruby's shell
  function) leaves stale `GEM_HOME`/`GEM_PATH` pointing at the MRI Ruby's
  gems.** Bundler then tries to load MRI-only native gems (e.g. `date`) under
  JRuby and fails with a `LoadError` that doesn't obviously say "wrong
  Ruby." Needed `env -u GEM_HOME -u GEM_PATH` to fix. A real project would
  want this baked into scripts/CI rather than discovered by trial and error
  each time.
- **JDK 26 warns on `jdbc-sqlite3`'s native access**
  (`java.lang.System::load`), saying restricted methods "will be blocked in
  a future release unless native access is enabled." Not a problem today,
  but a forward-looking maintenance item if/when a future JDK tightens this
  by default.

### SWT GUI attempt — the widgets never render (2026-09-16)

With the data layer cleared, we built the actual SWT counter-spike in
`desktop_swt/` (its own Gemfile, plain `rom-sql` over `jdbc-sqlite3`, and a
`Glimmer::UI::CustomShell` mirroring `desktop/app.rb`'s feature set).
**The widgets never render properly on this machine.**

What we established on the way there:

- **A shared Gemfile across both rubies doesn't work here.**
  `bundle lock --add-platform java` fails because every gem must resolve for
  every locked platform, and `sqlite3` publishes only native per-platform
  builds with no generic `ruby` variant — even when scoped inside a
  `platforms(:ruby)` block. Hence `desktop_swt/` carries its own
  Gemfile/lockfile and talks to SQLite directly instead of booting Hanami.
- `glimmer-setup` is required on macOS to set `-J-XstartOnFirstThread`
  (Cocoa insists on owning the main thread).
- Glimmer's `selection <=>` binding on `list`/`combo` derives its items from
  a `<attr>_options` method by convention, and **does not coexist with a
  separate `items <=>` binding** — an easy trap whose error message
  ("invalid keyword `..._options`") doesn't explain itself.
- A plain `ROM::Configuration` returns **Hashes, not method-accessible
  structs**, unlike the `hanami-db`-booted app — `teammate[:name]`, not
  `teammate.name`.

Then the wall: the teammate list rendered and **nothing else did** — no
exception, no warning, an empty log. Dumping the live SWT widget tree showed
every widget present, correctly parented, with sensible non-zero bounds and
`visible=true`, occupying exactly the region that drew blank. A forced
`layout(true, true)` + `redraw` didn't help, and neither did manually
resizing the window. A static probe with no database and no data binding
failed identically, ruling out our own code.

A four-variant probe (one window, four sibling composites) showed painting is
simply unreliable: a label-only composite drew its text; a label+list
composite drew only the list's focus ring, with no label text and no items;
and composites containing a `group`+`combo`, or `text` widgets, drew nothing
at all — not even their borders.

Likely cause, but **not proven**: the gem vendors **SWT 4.30 /
Implementation-Version 3.123.100** (`vendor/swt/mac_aarch64/swt.jar`, built
with JDK 17, Eclipse 2023-12) while this machine runs macOS 26 on JDK 26 — a
native Cocoa backend roughly two years older than the OS it is drawing on.

A second, equally untested explanation: **we ran well outside the gem's
stated prerequisites.** Its README asks for JRuby 9.4.10.0 and JDK 21 (17
minimum on Mac ARM64), and says plainly that other versions carry "no
guarantees". We used JRuby 10.1.1.0 on JDK 26. Painting is pure native Cocoa
and has little to do with the Ruby runtime, which is why the stale-SWT theory
is the favourite — but nothing we did distinguishes the two, and neither was
tested.

**Note the symmetry with the libui finding: both Ruby GUI options here are
blocked by a stale vendored native binary in the gem, not by Ruby and not by
Glimmer.** libui ships the abandoned `andlabs/libui` alpha4.1 (no table
selection); glimmer-dsl-swt ships an SWT that will not paint here. In both
cases the fix is to supply a newer binary yourself — and, as it turns out,
both gems support exactly that. See the next section.

### Updating the vendored native libraries (2026-09-17)

The first write-up of this spike claimed refreshing these binaries was
unsupported, fork-the-gem work. **That was wrong.** Both gems have a
supported override; it is just badly signposted.

| gem | vendored binary | override | documented where |
|---|---|---|---|
| `glimmer-dsl-swt` | SWT 4.30 jar | `SWT_JAR_FILE_PATH` env var | one line in the README's *Pre-requisites* section |
| `libui` (under `glimmer-dsl-libui`) | `libui.dylib` alpha4.1 | `LIBUIDIR` env var | nowhere — only in `lib/libui.rb:14` |

For libui there is a second, equally undocumented extension point:
`LibUI::FFI.try_extern` is a public method, so missing C functions can be
declared **from your own application code** without touching the gem.
Verified here:

```ruby
require "libui"
LibUI::FFI.try_extern "void uiControlShow(uiControl *c)"
# => binds fine from user code

LibUI::FFI.try_extern "void uiTableOnSelectionChanged(uiTable *t, ...)"
# => Fiddle::DLError: cannot find the function: uiTableOnSelectionChanged()
```

That second error is the whole libui story in one line: the binding mechanism
is fine and reachable from user code, and the *only* thing missing is a dylib
new enough to contain the symbol.

So the realistic cost of each unblock is lower than first recorded:

- **libui → libui-ng**: build from source (Meson), set `LIBUIDIR`,
  `try_extern` the table-selection functions from app code, then teach
  `table_proxy.rb` to use them. Only the last step touches the gem.
- **SWT → current SWT**: download `org.eclipse.platform:org.eclipse.swt.cocoa.macosx.aarch64`
  (Maven Central) and set `SWT_JAR_FILE_PATH`. No code changes at all — this
  is roughly a ten-minute experiment, and the cheapest way to settle whether
  the blank-pane bug is really the stale toolkit. If it still fails, drop to
  JRuby 9.4.10.0 + JDK 21 to match the supported matrix before concluding
  anything. Vendored SWT is **4.30**; Eclipse is currently on **4.41** —
  eleven release trains, roughly two and three quarter years.

### Is there a better-maintained Glimmer to move to? (2026-09-17)

Not for native desktop. Last push per repo:

- `glimmer-dsl-web` 2026-09-15, `glimmer` (core) 2026-09-07,
  `glimmer-dsl-css` 2026-09-12 — **the active development is all web**
- `glimmer-dsl-wx` 2026-03-14 — but v0.1.0 with 14 stars, and its own README
  says it "is not fully developed yet" and recommends using
  `glimmer-dsl-libui` or `glimmer-dsl-swt` instead
- `glimmer-dsl-libui` 2026-02-17
- `glimmer-dsl-swt` 2025-03-21 — **the least maintained of the three**, and
  `v4.30.1.1` (what we used) is still its newest release
- `glimmer-dsl-tk` 2024-02, `glimmer-dsl-swing` / `glimmer-dsl-jfx` 2023-06

So the toolkit already chosen for the working spike, libui, is also the
best-maintained native-desktop option in the family. Nothing to migrate to.

Also checked: `glimmer-dsl-swt` has seven open issues and **none of them
describe this rendering failure**, so it is not a known/reported bug. The
nearest signal of version drift is issue #40, `undefined method 'exists?'
for class File` — a method removed in newer Rubies.

### Choices to make before a deliberate build

- **GUI toolkit: stick with `glimmer-dsl-libui`, or move to
  `glimmer-dsl-swt` (JRuby)?** Deferred at the start of the spike ("decide
  later on CRuby vs JRuby for threads and so on"), and now much better
  informed — not in SWT's favour. JRuby itself is fine and the data layer
  works, but SWT's vendored toolkit doesn't render here, and
  `glimmer-dsl-swt` is the least-maintained desktop DSL in the family (see
  the two sections above). libui genuinely works today, with a button-row
  workaround for list selection and a hand-rolled, machine-specific `.app`
  bundle. Realistic options, cheapest first: stay on libui and live with the
  workarounds; spend ten minutes on `SWT_JAR_FILE_PATH` with a current SWT
  jar to learn whether SWT is salvageable at all; refresh the libui binary
  via `LIBUIDIR` + `libui-ng` to get real table selection; or step outside
  Ruby GUI toolkits altogether (a small native Swift shell, or the existing
  web UI in a WKWebView wrapper) on the grounds that both Ruby options
  depend on someone else's unmaintained binary. Hard to reverse and
  trade-off-laden — worth an ADR once decided.
- **Packaging/distribution for real use**: hand-rolled `.app` with hardcoded
  paths, a proper packaging tool (if one exists for your chosen toolkit), or
  something like `ruby-packer`/`traveling-ruby` to bundle a Ruby runtime so
  it isn't tied to your machine's chruby setup.
- **Architecture between GUI and data**: the spike calls repos directly from
  Glimmer callbacks with no validation layer. The web actions use
  dry-validation; a deliberate build probably wants an Operation layer
  shared between web and desktop rather than two divergent paths into the
  same repos.
- **Autosave behavior**: the note editor currently persists on every
  keystroke (`on_changed`) with no debounce — fine for a spike, would
  hammer SQLite in real use.
- **Whether the desktop app and any future web UI coexist** against the
  same database, or this fully replaces the web app.
- **Real import semantics**: the rake task always creates fresh teammates
  with no de-duplication/idempotency — fine for a one-time migration, worth
  confirming that's genuinely one-shot before relying on it twice.
