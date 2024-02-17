# CHANGELOG

## Next Release
* differences from [previous tag](/../../compare/v1.7.1…main).
* Added [version-related unit tests](./tests/test_bme_version.sh).

## v1.7.1 (2024-FEB-04)
* differences from [previous tag](/../../compare/v1.7.0…v1.7.1).
* Version comes now from [VERSION file](./VERSION).
* Added a minimal unit testing framework.
* Added .editorconfig file.
* python3-virtualenvs module: load_virtualenv() now accepts an optional param to use a requirements file to build a virtualenv.

## v1.7.0 (2023-OCT-20)
* differences from [previous tag](/../../compare/v1.6.1…v1.7.0).
* Added support for per-project modules.
* BUG CORRECTED: message erratum on githooks module.
* BUG CORRECTED: bme_eval_dir() loaded project root's .bme_env file twice.

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
