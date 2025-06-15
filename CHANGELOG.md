# Change Log

## 1.0.0 / 2025-06-14

* Rails support has been removed.
* Geminabox support has been removed.
* `OptionParser` is now used instead of `Thor` for command line options.
* Jekyll gems are now
  [structured for better testability](https://mslinn.com/jekyll/10700-designing-for-testability.html).
* Added `spec.platform` to `templates/common/gem_scaffold/%gem_name%.gemspec.tt`
  because `RubyGems.org` now requires .
* Very little of the original code from `creategem` remains.


## 0.9.0

* Added `OptionParser` starter for gems in `templates/common/executable_scaffold/lib/%gem_name%/options.rb.tt`.
* Renamed 'plain' to 'gem'
* Reorganized generated gem files so they all enhance the same module
* All generated Ruby files are included on startup
* Rails apps are deprecated, will be removed soon


## 0.8.5

* Added `-y` option to suppress confirmation messages and default to `yes`.
* Suppresses the huge chunk of JSON that used to be displayed after the remote repository was created.


## 0.8.4

* Added `-o` option for specifying output directory
* Added aliases for class options


## 0.8.3

* Added more files to generated projects.
* Improved generated scripts and settings.
* `plain` command has been tested.
* `jekyll` and `rails` commands are not ready yet.

## 0.8.2

* Added `.markdownlint.json` to generated projects and this project.


## 0.8.1

* Corrected broken gemspec.


## 0.8.0

* Updated dependencies and `README`.
* Renamed the `gem` subcommand to `plain`.
* Renamed the `plugin` subcommand to `rails`.
* Added `CHANGELOG`, `.rspec`, `.rubocop` and `.vscode/`.
* Added `binstubs/`.
* Using `require_relative` where appropriate.
* Changed the default for including an executable to `false`.
* Added the `--quiet` and `--todos` options, common to the `plain`, `jekyll` and `rails` subcommands.


## 0.7.4

* Last release was 7 years prior without a change history.
