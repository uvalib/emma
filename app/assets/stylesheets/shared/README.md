# Shared SCSS (SASS) definitions

Files in this directory hold only general SASS definitions, _i.e._:
* `@mixin` definitions
* `@function` definitions
* SASS variable assignments

These files do not contain general non-SASS-specific items, _i.e._:
* CSS class definitions
* SASS placeholder (`%`) definitions

This division allows any of the files in this directory to be freely included
via `@use` without causing duplication in the resulting compiled file in
`app/assets/builds/application.css`.

## Contents

|                                                         FILE | USAGE                                                 |
|-------------------------------------------------------------:|:------------------------------------------------------|
|                       **[_variables.scss](_variables.scss)** | General-use SASS variable assignments                 |
|                       **[_functions.scss](_functions.scss)** | General-use SASS `@function` definitions              |
|                             **[_mixins.scss](_mixins.scss)** | General-use SASS `@mixin` definitions                 |
|         **[controls/_buttons.scss](controls/_buttons.scss)** | Definitions supporting button controls                |
|             **[controls/_grids.scss](controls/_grids.scss)** | Definitions supporting grid controls                  |
|             **[controls/_lists.scss](controls/_lists.scss)** | Definitions supporting lists and list elements        |
|             **[controls/_popup.scss](controls/_popup.scss)** | Definitions supporting pop-up elements                |
|           **[controls/_shapes.scss](controls/_shapes.scss)** | Definitions supporting shaped elements                |
|            **[controls/_table.scss](controls/_tables.scss)** | Definitions supporting tables and table elements      |
|   **[layouts/_header.scss](../shared/layouts/_header.scss)** | Shared definitions used in `layouts/header/*`         |
|   **[feature/_images.scss](../shared/feature/_images.scss)** | Shared definitions supporting `feature/_images.scss`  |
|     **[feature/_model.scss](../shared/feature/_model.scss)** | Shared definitions supporting `feature/_model.scss`   |
| **[feature/_overlay.scss](../shared/feature/_overlay.scss)** | Shared definitions supporting `feature/_overlay.scss` |

## Implementation Notes

This directory does not contain an `index.scss` because it is not intended to
be imported _en masse_.
Each of the files should be incorporated with `@use` on a file-by-file basis
where required.

<!--========================================================================-->
