## v0.1.4 (2023-04-09)

- support path globbing: `Virtfs.glob`
- vendored path globbing package, since it's an unpublished fork
- removed `typed_struct` package (keeping dependencies low)

## v0.1.3 (2023-03-28)

- Feat: add generator from Mix with adjustments for Virtfs

## v0.1.2 (2023-03-28)

- Feat: add `expand` command
- Feat: add `relative_to_cwd` command
- Fix: dumper fails for some files because the folder is not created yet

## v0.1.1 (2023-03-28)

- Feat: add `cwd` command
- Fix: normalise paths by removing trailing ‘/’
- Fix: cd only possible to existing folders

## v0.1.0 (2023-03-26)

### First release

- Very usable first release, can be used for real work.
