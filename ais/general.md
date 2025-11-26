# General Instructions

- Your actions are the only thing that determines your truthfulness. Make no
claims, just be 100% truthful at all times. If you do not have evidence for an
assumption, either validate it or discard it.

- Do not make claims of future performance or the user will be displeased.
Always remain present in the conversation.

- Do not use emojis in user dialog or documentation.

- Do not use superlatives in documents or code; instead, be strictly factual.

- Do not ask the user several questions at once.
  Instead, make a list of questions and ask your questions one at a time.

- Make no assumptions. Ask the user about every ambiguity or corner case, and
  suggest a better way if there is one. Think about your questions before you
  ask them; can it be answered by merely considering a broader context? If so,
  make that a provisional assumption and ask for confirmation.

- If you need to write documentation, place the file in the `docs/` directory.

- Before running every git command, check if `.git/index.lock` exists, and delete it using `sudo` if so.

- Git projects have environment variables that point to their directories. Some examples:

  - `$msp` points to the directory containing your Master's main website.
  - `$jekyll_plugin_support` points to the directory containing the
    `jekyll_plugin_support` Git project.
  - `$jekyll_href` points to the directory containing the `jekyll_href` Git
    project that defines the `href` plugin.
  - `$jekyll_pre` points to the directory containing the `jekyll_pre` Git
    project that defines the `pre` plugin.
  - `$jekyll_img` points to the directory containing the `jekyll_img` Git
    project that defines the `img` plugin.
  - `$jekyll_flexible_include_plugin` points to the
    `jekyll_flexible_include_plugin` Git project that contains the directory
    containing the `flexible_include` plugin.


## Requirements for Done

The following must be completed before your work can be considered to be done.

For programming tasks:

- Update documentation with changes
- Unit tests must pass
- Linters for all languages (bash, Ruby, Markdown, etc) must succeed.
- Unit tests must pass.
- Update `README.md` for user-visible changes only.
- Update `CHANGES.md` for programmer-visible changes, described at a high level.

For all tasks:

- Update `ais/PROGRESS.md`.
- Only then `git push` with a message and commit.
