# CHANGELOG

## Next Release
* added support for per-project modules.

## v1.6.1 (2023-OCT-07)
* differences from [previous tag](/../../compare/v1.6.0…v1.6.1).
* __bme_load_project() now runs in the directory it gets as param so it can properly load root's .bme_env file.

## v1.6.0 (2023-OCT-01)
* differences from [previous tag](/../../compare/v1.5.0…v1.6.0).
* New module: [githooks](./src/bash-magin-enviro_modules/githooks.module).

## v1.5.0 (2023-SEP-30)
* differences from [previous tag](/../../compare/v1.4.7-1…v1.5.0).
* *bme_env* at project's root always loaded, not only current dir's.
* CHANGELOG added.
* `make install` *"remembers"* where it was deployed so `make uninstall` can do the proper thing.

## Changelog started on version 1.5.0
