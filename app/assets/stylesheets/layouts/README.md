# Shared CSS class definitions

Files in this directory contain general non-SASS-specific items, _i.e._:
* CSS class definitions
* SASS placeholder (`%`) definitions

These files do not contain general SASS definitions, _i.e._:
* `@mixin` definitions
* `@function` definitions
* SASS variable assignments

In order to avoid duplication in the resulting compiled file in
`app/assets/builds/application.css`,
files in this directory should be incorporated once at the start of the
manifest (`app/assets/stylesheets/application.sass.scss`).

## Contents

|                                       FILE | USAGE                                                |
|-------------------------------------------:|------------------------------------------------------|
|               **[_root.scss](_root.scss)** | Base page definitions                                |
|           **[_common.scss](_common.scss)** | General-use CSS classes and SCSS placeholder classes |
|         **[_content.scss](_content.scss)** | Classes related to generic page styles               |
| **[controls/*.scss](controls/index.scss)** | Classes related to generic control styles            |
|             **[_debug.scss](_debug.scss)** | CSS classes used only when debugging                 |
|     **[header/*.scss](header/index.scss)** | Classes related to generic page header styles        |
|           **[_footer.scss](_footer.scss)** | Classes related to generic page footer styles        |
|             **[_print.scss](_print.scss)** | Variations only for "@media print"                   |

<!--========================================================================-->
