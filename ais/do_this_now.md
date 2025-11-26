# General Instructions

Read the following for general instructions governing all requests.

- `./general.md`
- `./output.md`

## Do this now

This directory contains the Nugem program in $nugem. This is a cli that users
interact with using a command line.

The nugem program is being rewritten. A lot of progress has been made, but work
remains. `README.md` is an accurate description of the desired end result.

This project creates the `nugem` command in `/home/mslinn/.rbenv/shims/nugem` when`rake install` is executed.

Your job is to work with me step by step to complete the rewrite.

The previous version is provided in this same Git repo, with the last release at
[tag 0.7.4](https://github.com/igorj/creategem/tree/v0.7.4). We will refer to
that source code to complete the work because an older version of most of the
code that we need can be found there.

We are working on the `nugem jekyll` subcommand option processing.
The first thing you should do is write two scripts to help perform the work:

`driver.sh`:

For every Jekyll plugin-related Nugem option (`--block`, `--blockn`, `--filter`,
`--hooks`, `--tag`, and `--tagn`):

1. The command with the option must be run, and the user needs to interact with the command:

   ```shell
   $ nugem jekyll -o /tmp/nugem_test --block test # for example
   # A command-line dialog may ensure, so the user must be able to interact with the nugem cli.
   ```

2. Verify that the generated project in `/tmp/nugem_test` is correct by running the
   following without error. Directory paths relative to the project root are
   shown below.

   1. Run `bin/setup`
   2. Run unit tests `binstub/rspec`. if there is a failure, the script should halt.
   3. Run the demo Jekyll server in `demo/` and ask the user to inspect the test
      website.
   4. Launch Visual Studio Code in the project `code /tmp/nugem_test` and ask
      the user to inspect the generated code.
   5. The user probably will ask you to make changes to nugem. When he says he is done,
      run `cleanup.sh` and repeat from step 1.
   6. When the user has no more changes, move to the next Jekyll plugin-related Nugem option.

`cleanup.sh`:

1. Stop the demo Jekyll server if it is running,
2. Delete the generated project in `/tmp/nugem_test/`
