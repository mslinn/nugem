# `Nugem` [![Gem Version](https://badge.fury.io/rb/nugem.svg)](https://badge.fury.io/rb/nugem)

`Nugem` creates a scaffold project for a new gem in a new git repository.
After you add your special code to the gem scaffold and test it,
the project can be released to a public or private gem server.

This gem generates a new working Visual Studio Code project with the following features:

- Compatible with `rbenv`.
- `Gemfile` and `.gemspec` files set up.
- Generates a README with badges.
- Generates a new Visual Studio Code project, set up with current Ruby extensions.
  - Rubocop configured.
  - Shellcheck configured.
  - Markdown lint configured.
  - Launch configurations set up for testing.
- Can automatically create a public or private git repository on GitHub, GitLab or Bitbucket for your new gem.
- Creates a test infrastructure based on `rspec`.
- Your gem can be publicly released to `rubygems.org`.
- Optionally create the gem as:
  - A plain old gem.
  - A Jekyll plugin (tag or block tag).

The following features are still in development, so they probably do not work yet:

- Automatically creates git repositories on BitBucket or GitLab.
  Your gem can include [executables](https://guides.rubygems.org/make-your-own-gem/#adding-an-executable).
- Optionally create the gem as:
  - Jekyll plugins (block tags, inline tags, filters, generators, or hooks).


## Installation

```shell
$ gem install nugem
```

If you are using [rbenv](https://www.mslinn.com/ruby/1000-ruby-setup.html#rbenv) to manage Ruby instances, type:

```shell
$ rbenv rehash
```

To update the program:

```shell
$ gem update nugem
```


## Subcommands and Option Positions

See [`subcommands.md`](subcommands.md) for details on `nugem` subcommands and option positions.


### Common Options

The `gem` and `jekyll` subcommands have common options.

The default option values assume that:

- You do not want an executable for your gem scaffold
- The gem project will be hosted on a public GitHub git repository
- The gem will be released to `rubygems.org`

Common options for the `gem` and `jekyll` subcommands are:

<dl>
  <dt><code>-e</code> <code>--executable</code></dt>
    <dd>add an executable based on Thor.</dd>

  <dt><code>-H</code> <code>--host</code></dt>
    <dd>
      specifies the git host; possible values are <code>bitbucket</code>,
      <code>github</code> and <code>geminabox</code>.
    </dd>

  <dt><code>--out_dir</code></dt>
    <dd>
      specifies the directory to write the generated gem to.
      The default is <code>~/nugem_generated/</code>.
    </dd>

  <dt><code>--private</code></dt>
    <dd>the remote repository is made private,
        and on release the gem will be pushed to a private Geminabox server.
    </dd>

  <dt><code>--verbosity</code></dt>
    <dd>specifies verbosity.</dd>

  <dt><code>--no-todos</code></dt>
    <dd>do not generate `TODO:` strings in generated code.</dd>
</dl>


### Common Behavior

The `gem` and `jekyll` subcommands have common behavior.

Gem scaffolds are created by default within the `~/nugem_generated/` directory.

If your user name is not already stored in your git global config,
you will be asked for your GitHub or BitBucket user name.
You will also be asked to enter your GitHub or BitBucket password when the remote repository is created for you.

After you create the gem, edit the `gemspec` and change the summary and the description.

The supported test framework is `rspec`.

Commit the changes to git and invoke `rake release`,
and your gem will be published.


### `gem` Subcommand

```shell
$ nugem gem NAME [COMMON_OPTIONS]
```

`NAME` is the name of the gem to be generated.

For more information, type:

```shell
$ nugem gem -h
```


### `jekyll` Subcommand

The `jekyll` subcommand extends the `gem` subcommand and creates a new Jekyll plugin with the given NAME:

```shell
$ nugem jekyll NAME [COMMON_OPTIONS] [JEKYLL_OPTIONS]
```

`NAME` is the name of the Jekyll plugin gem to be generated.

In addition to the common options, the `JEKYLL_OPTIONS` are:

`--block`, `--blockn`, `--filter`, `--hooks`, `--tag`, and `--tagn`.

(Warning: only `--block` and `--tag` been properly tested.)

Each of these options causes `nugem` to prompt the user for additional input.

All of the above options can be specified more than once, except the `--hooks` option.
For example:

```shell
$ nugem jekyll test_tags --tag my_tag1 --tag my_tag2
```

The above creates a Jekyll plugin called `test_tags`,
which defines Jekyll tags called `my_tag1` and `my_tag2`.
You might use these tags in an HTML document like this:

```html
<pre>
my_tag1 usage: {% my_tag1 %}
my_tag2 usage: {% my_tag2 %}
</pre>
```

For more information, type:

```shell
$ nugem jekyll -h
```


## Did It Work?

The following shows all files that were committed to the newly created git repository,
after `nugem jekyll` finished making two tag blocks:

```shell
$ git ls-tree --name-only --full-tree -r HEAD
.gitignore
.rspec
.rubocop.yml
.vscode/extensions.json
.vscode/launch.json
.vscode/settings.json
CHANGELOG.md
Gemfile
LICENCE.txt
README.md
Rakefile
bin/attach
bin/console
bin/rake
bin/setup
demo/Gemfile
demo/_bin/debug
demo/_config.yml
demo/_drafts/2022/2022-05-01-test2.html
demo/_includes/block_tag_template_wrapper
demo/_layouts/default.html
demo/_posts/2022/2022-01-02-redact-test.html
demo/assets/css/style.css
demo/assets/images/404-error.png
demo/assets/images/404-error.webp
demo/assets/images/favicon.png
demo/assets/images/jekyll.png
demo/assets/images/jekyll.webp
demo/assets/js/clipboard.min.js
demo/assets/js/jquery-3.4.1.min.js
demo/blog/blogsByDate.html
demo/blog/index.html
demo/index.html
jekyll_test.code-workspace
jekyll_test.gemspec
lib/jekyll_test.rb
lib/jekyll_test/version.rb
lib/my_block1.rb
lib/my_block2.rb
spec/jekyll_test_spec.rb
spec/spec_helper.rb
test/jekyll_test_test.rb
test/test_helper.rb
```


## Visual Studio Code Support

### Nugem Project

#### Plugins

If you have not installed the
[Snippets](https://marketplace.visualstudio.com/items?itemName=devonray.snippet) extension,
Visual Studio Code will suggest that you do so the first time you open this project with Visual Studio Code.
You can also review the list of suggested extensions of with the <kbd>Ctrl</kbd>-<kbd>P</kbd>
`Extensions: Show Recommended Extensions` command.


#### Snippets

The predefined snippets for `nugem` are defined in
[`.vscode/nugem.json.code-snippets`](.vscode/nugem.json.code-snippets).
These snippets are focused on maintaining `nugem` itself.


#### File Associations

`.vscode/settings.json` defines file associations for templates in the `"files.associations"` section.
You can disable them by commenting out the definitions.


### Generated Projects

#### Plugins

Similarly, for each gem project generated by `nugem`, Visual Studio Code will suggest
the user install missing extensions the first time those projects are opened.


#### Snippets

The predefined snippets for gem projects generated by `nugem` are defined in
their `.vscode/gem.json.code-snippets` file.
These snippets are focused on writing Jekyll plugins.


## Development

After checking out the repository, run `bin/setup` to install dependencies.
Then, run `rake test` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run:

```shell
$ bundle exec rake install
```

To release a new version, run:

```shell
$ bundle exec rake release
```

The above will create a git tag for the version, push git commits and tags,
and push the `.gem` file to https://rubygems.org.


### Tests

Run all tests with:

```shell
$ bin/rspec
```

Run a specific test file with:

```shell
$ bin/rspec spec/template_spec.rb
```



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mslinn/nugem.


## See Also

- [`gem-release`](https://rubygems.org/gems/gem-release)
- [`bundle gem`](https://bundler.io/v2.4/man/bundle-gem.1.html)
- [Deveoping a RubyGem using Bundler](https://bundler.io/guides/creating_gem.html)
