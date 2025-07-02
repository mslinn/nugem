# Options Parser Subcommands

Subcommands of `Nugem` are implemented using the `NestedOptionsParser` class.
This allows for a flexible command-line interface with a single level of subcommands:

1. A command can have multiple subcommands.
2. At most one subcommand can be specified per command line.
3. Each subcommand can have its own set of options and positional parameters.
4. The subcommand name must be the first positional parameter.
5. Sub-subcommands are not supported, i.e., a subcommand cannot have sub-subcommands.

All of the following formats are valid and provide the same functionality:

```shell
$ cmd [subcommand] [options] [positional_parameters]
$ cmd [options] [subcommand] [positional_parameters]
$ cmd [options] [subcommand] [options] [positional_parameters] [options]
```

The `nugem` program supports two subcommands: `plain` and `jekyll`.

```shell
$ nugem -h
$ nugem plain my_gem_name
$ nugem jekyll my_jekyll_plugin_name
```

You can place options anywhere on the command line,
so long as the subcommand name is the first positional parameter.
The following command lines are all valid and equivalent:

```shell
$ nugem --out-dir $HOME plain my_gem_name
$ nugem plain --out-dir $HOME my_gem_name
$ nugem plain my_gem_name --out-dir $HOME
```

I favor the first format, which positions options after the command name and before the subcommand name.
