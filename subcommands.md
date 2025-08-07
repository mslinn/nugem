# Options Parser Subcommands

Subcommands of `Nugem` are implemented using the `NestedOptionsParser` class.
This allows for a flexible command-line interface with a single level of subcommands:

1. A command can have multiple subcommands.
2. At most one subcommand can be specified per command line.
3. The subcommand name is the first positional parameter.
4. No options can appear before the subcommand name.
5. Each subcommand can have its own set of options and positional parameters.
6. Sub-subcommands are not supported, i.e., a subcommand cannot have sub-subcommands.

The following formats are valid and provide the same functionality:

```shell
$ cmd [subcommand] [options] [positional_parameters]
$ cmd [subcommand] [options] [positional_parameters] [options]
```

The `nugem` program supports two subcommands: `gem` and `jekyll`.

```shell
$ nugem -h
$ nugem gem my_gem_name
$ nugem jekyll my_jekyll_plugin_name
```

You can place options anywhere on the command line,
so long as the subcommand name is the first positional parameter.
The following command lines are valid and equivalent:

```shell
$ nugem gem --out-dir=$HOME my_gem_name
$ nugem gem my_gem_name --out-dir=$HOME
```
