<!-- lib/doc/workflow.md -->
# Upload Workflow

Two views of the upload workflow, which includes "sub-workflows" for:

|     ACTION |                                                  |
|-----------:|--------------------------------------------------|
| **Create** | Submitting a new item to create a new EMMA entry |
| **Modify** | Updating an existing EMMA entry                  |
| **Remove** | Deleting an existing EMMA entry                  |

In each action, bolder transition lines indicate the preferred/expected path
through the workflow.

## Basic View

![cached image][basic_cached]

## Grouped View

![cached image][grouped_cached]

&nbsp;
____

## UML Sources

This file uses the PlantUML Server to render the state diagrams dynamically
from within the Markdown viewer (e.g., on GitHub or within RubyMine via the
PlantUML plugin).

### Basic View

This is a straightforward rendering of the workflow states.

```PlantUML

  @startuml UploadWorkflow

  title Upload Workflow

' left to right direction
  hide empty description

  ' === STYLING ===============================================================

  skinparam Shadowing false
  skinparam nodesep 25
  skinparam ranksep 75
  'skinparam linetype polyline
  'skinparam linetype ortho

  ' === Properties for a state that should not be rendered

  skinparam <<Hidden>> {
    StateBackgroundColor Transparent
    StateFontColor       Transparent
    StateBorderColor     Transparent
    StateStartColor      Transparent
  }

  ' === System-type state properties

  skinparam <<System>> {
    StateBackgroundColor  DarkGray
    StateFontStyle        normal
    StateFontColor        White
  }

  ' === Mixed-type state properties

  skinparam <<Mixed>> {
    StateBackgroundColor  DarkTurquoise
    StateFontStyle        bold
    StateFontColor        White
  }

  ' === Reviewer-type state properties

  skinparam <<Reviewer>> {
    StateBackgroundColor  Orchid
    StateFontStyle        bold
    StateFontColor        White
  }

  ' === User-type state properties

  skinparam <<User>> {
    StateBackgroundColor  LimeGreen
    StateFontStyle        bold
    StateFontColor        White
    StateFontSize         16
  }

  ' === Sequence-type state properties

  skinparam <<Sequence>> {
    Shadowing        false
    StateBorderColor Green
    StateFontColor   Blue
    StateFontSize    18
    'StateFontStyle   italic
  }

  ' === STATE DEFINITIONS =====================================================

  ' === Initial (pseudo) state
  state "ACTION" as starting <<Mixed>>

  ' === "Create new entry" sequence
' state "Create" as Creating <<Sequence>> {
    state creating    <<User>>
    state validating  <<Mixed>>
    state submitting  <<System>>
    state submitted   <<System>>
' }

  ' === "Modify existing entry" sequence
' state "Modify" as Editing <<Sequence>> {
    state editing     <<User>>
    state replacing   <<Mixed>>
    state modifying   <<System>>
    state modified    <<System>>
' }

  ' === "Remove existing entry" sequence
' state "Remove" as Removing <<Sequence>> {
    state removing    <<User>>
    state removed     <<System>>
' }

  ' === Sub-sequence: Review
' state "Review" as Reviewing <<Sequence>> {
    state scheduling  <<System>>
    state assigning   <<System>>
    state holding     <<Mixed>>
    state assigned    <<Mixed>>
    state reviewing   <<Reviewer>>
    state rejected    <<User>>
    state approved    <<System>>
' }

  ' === Sub-sequence: Submission
' state "Submission" as Staging <<Sequence>> {
    state staging     <<System>>
    state unretrieved <<System>>
    state retrieved   <<System>>
' }

  ' === Sub-sequence: Finalization
' state "Finalization" as Indexing <<Sequence>> {
    state indexing    <<System>>
    state indexed     <<System>>
' }

  ' === Sub-sequence: Termination
' state Termination <<Sequence>> {
    state suspended   <<System>>
    state failed      <<System>>
    state canceled    <<System>>
    state completed   <<System>>
    state purged      <<System>>
' }

  ' === Pseudo states for use by Termination states
  state "PREV" as resuming <<Hidden>>

  ' === Final (pseudo) state
  state end_state <<join>>

  ' === STATE TRANSITIONS =====================================================

  [*]                              -> starting
' starting          -[hidden,norank]> starting      : [start]
  starting    -[dotted,thickness=5]-> creating      : [create]
  starting    -[dotted,thickness=5]-> editing       : [edit]
  starting    -[dotted,thickness=5]-> removing      : [remove]

' state Creating {

'   [*]<<Hidden>>  -[hidden,norank]-> creating

    creating              -[dashed]-> canceled      : [cancel]
    creating                      --> submitting    : [submit]
    creating         -[thickness=3]-> validating    : [upload]

'   validating      -[dotted,norank]> purged        : [purge]
    validating                  -up-> creating      : [reject]
    validating            -[dashed]-> canceled      : [cancel]
    validating       -[thickness=3]-> submitting    : [submit]

'   submitting      -[dotted,norank]> purged        : [purge]
    submitting                  -up-> creating      : [reject]
    submitting       -[thickness=3]-> submitted

'   submitted       -[dotted,norank]> purged        : [purge]
    submitted        -[thickness=4]-> scheduling    : [schedule]
    submitted                     --> staging

' }

' state Editing {

'   [*]<<Hidden>>  -[hidden,norank]-> editing

    editing               -[dashed]-> canceled      : [cancel]
    editing          -[thickness=3]-> modifying     : [submit]
    editing          -[thickness=3]-> replacing     : [upload]

'   replacing       -[dotted,norank]> purged        : [purge]
    replacing                   -up-> editing       : [reject]
    replacing             -[dashed]-> canceled      : [cancel]
    replacing        -[thickness=3]-> modifying     : [submit]

'   modifying       -[dotted,norank]> purged        : [purge]
    modifying                   -up-> editing       : [reject]
    modifying        -[thickness=3]-> modified

'   modified        -[dotted,norank]> purged        : [purge]
    modified         -[thickness=4]-> scheduling    : [schedule]
    modified                      --> staging

' }

' state Removing {

'   [*]<<Hidden>>  -[hidden,norank]-> removing

    removing              -[dashed]-> canceled      : [cancel]
    removing         -[thickness=3]-> removed       : [submit]

    removed               -[dashed]-> failed        : [fail]
    removed   --------[thickness=4]-> staging

' }

' state Reviewing {

'   [*]<<Hidden>>   -[hidden,norank]> scheduling

    scheduling       -[thickness=3]-> assigned      : [assign]
    scheduling                    --> assigning

    assigning                -right-> holding       : [hold]
'   assigning       -[hidden,norank]> assigned      : [assign]
    assigning                     --> assigned

'   holding         -[dotted,norank]> editing       : [edit]
'   holding         -[dotted,norank]> canceled      : [cancel]
'   holding         -[dotted,norank]> purged        : [purge]
    holding                     -up-> holding       : [timeout]
    holding               -[dashed]-> failed        : [fail]
    holding                       --> assigning

'   assigned        -[dotted,norank]> editing       : [edit]
'   assigned        -[dotted,norank]> canceled      : [cancel]
'   assigned        -[dotted,norank]> purged        : [purge]
    assigned         -[thickness=3]-> reviewing     : [review]

    reviewing        -[thickness=2]-> rejected      : [reject]
    reviewing        -[thickness=3]-> approved      : [approve]

'   rejected        -[dotted,norank]> purged        : [purge]
    rejected       -up[thickness=2]-> editing       : [edit]
    rejected    ------[thickness=2]-> canceled      : [cancel]

    approved         -[thickness=4]-> staging

' }

' state Staging {

'   [*]<<Hidden>>   -[hidden,norank]> staging

    staging                       --> indexing      : [index]
    staging          -[thickness=3]-> unretrieved

    unretrieved        ----[dashed]-> failed        : [fail]
    unretrieved                 -up-> unretrieved   : [timeout]
    unretrieved      -[thickness=3]-> retrieved

    retrieved        -[thickness=4]-> indexing

' }

' state Indexing {

'   [*]<<Hidden>>  -[hidden,norank]-> indexing

    indexing              -[dashed]-> failed        : [fail]
    indexing                      --> indexing      : [timeout]
    indexing         -[thickness=3]-> indexed

    indexed          -[thickness=4]-> completed

' }

' state Termination {

'   suspended       -[dotted,norank]> starting      : [reset]
'   suspended       -[dotted,norank]> resuming      : [resume]
    suspended                     --> purged

'   failed          -[dotted,norank]> starting      : [reset]
'   failed          -[dotted,norank]> resuming      : [resume]
    failed                        --> purged
    failed                        --> end_state

'   canceled        -[dotted,norank]> starting      : [reset]
'   canceled        -[dotted,norank]> resuming      : [resume]
    canceled                      --> purged
    canceled                      --> end_state

'   completed       -[dotted,norank]> starting      : [reset]
    completed                     --> purged
    completed                     --> end_state

    purged                        --> end_state

' }

  ' === NOTE: not actually in the workflow; just needed for the diagram:
  end_state --> [*]

  @enduml

```

### Grouped View

The constraints of enclosing states within states seem to present a real
challenge to the rendering logic.  The following code required a *lot* of
fiddling and still results in a rather sub-optimal layout.

```PlantUML

  @startuml UploadWorkflowGrouped

  title Upload Workflow (grouped)

' left to right direction
  hide empty description

  ' === STYLING ===============================================================

  skinparam Shadowing false
  skinparam nodesep 25
  skinparam ranksep 150
  'skinparam linetype polyline
  'skinparam linetype ortho

  ' === Properties for a state that should not be rendered

  skinparam <<Hidden>> {
    StateBackgroundColor Transparent
    StateFontColor       Transparent
    StateBorderColor     Transparent
    StateStartColor      Transparent
  }

  ' === System-type state properties

  skinparam <<System>> {
    StateBackgroundColor  DarkGray
    StateFontStyle        normal
    StateFontColor        White
  }

  ' === Mixed-type state properties

  skinparam <<Mixed>> {
    StateBackgroundColor  DarkTurquoise
    StateFontStyle        bold
    StateFontColor        White
  }

  ' === Reviewer-type state properties

  skinparam <<Reviewer>> {
    StateBackgroundColor  Orchid
    StateFontStyle        bold
    StateFontColor        White
  }

  ' === User-type state properties

  skinparam <<User>> {
    StateBackgroundColor  LimeGreen
    StateFontStyle        bold
    StateFontColor        White
    StateFontSize         16
  }

  ' === Sequence-type state properties

  skinparam <<Sequence>> {
    Shadowing        false
    StateBorderColor Green
    StateFontColor   Blue
    StateFontSize    18
    'StateFontStyle   italic
  }

  ' === STATE DEFINITIONS =====================================================

  ' === Initial (pseudo) state
  state "ACTION" as starting <<Mixed>>

  ' === "Create new entry" sequence
  state "Create" as Creating <<Sequence>> {
    state creating    <<User>>
    state validating  <<Mixed>>
    state submitting  <<System>>
    state submitted   <<System>>
  }

  ' === "Modify existing entry" sequence
  state "Modify" as Editing <<Sequence>> {
    state editing     <<User>>
    state replacing   <<Mixed>>
    state modifying   <<System>>
    state modified    <<System>>
  }

  ' === "Remove existing entry" sequence
  state "Remove" as Removing <<Sequence>> {
    state removing    <<User>>
    state removed     <<System>>
  }

  ' === Sub-sequence: Review
  state "Review" as Reviewing <<Sequence>> {
    state scheduling  <<System>>
    state assigning   <<System>>
    state holding     <<Mixed>>
    state assigned    <<Mixed>>
    state reviewing   <<Reviewer>>
    state rejected    <<User>>
    state approved    <<System>>
  }

  ' === Sub-sequence: Submission
  state "Submission" as Staging <<Sequence>> {
    state staging     <<System>>
    state unretrieved <<System>>
    state retrieved   <<System>>
  }

  ' === Sub-sequence: Finalization
  state "Finalization" as Indexing <<Sequence>> {
    state indexing    <<System>>
    state indexed     <<System>>
  }

  ' === Sub-sequence: Termination
  state Termination <<Sequence>> {
    state suspended   <<System>>
    state failed      <<System>>
    state canceled    <<System>>
    state completed   <<System>>
    state purged      <<System>>
  }

  ' === Pseudo states for use by Termination states
  state "PREV" as resuming <<Hidden>>

  ' === Final (pseudo) state
  state end_state <<join>>

  ' === STATE TRANSITIONS =====================================================

  [*]                              -> starting
' starting          -[hidden,norank]> starting      : [start]
  starting    -[dotted,thickness=5]-> creating      : [create]
  starting    -[dotted,thickness=5]-> editing       : [edit]
  starting     -[dotted,thickness=5]> removing      : [remove]

  state Creating {

    [*]<<Hidden>>  -[hidden,norank]-> creating

    creating              -[dashed]-> canceled      : [cancel]
    creating                      --> submitting    : [submit]
    creating         -[thickness=3]-> validating    : [upload]

'   validating      -[dotted,norank]> purged        : [purge]
    validating                    --> creating      : [reject]
    validating            -[dashed]-> canceled      : [cancel]
    validating       -[thickness=3]-> submitting    : [submit]

'   submitting      -[dotted,norank]> purged        : [purge]
    submitting                    --> creating      : [reject]
    submitting       -[thickness=3]-> submitted

'   submitted       -[dotted,norank]> purged        : [purge]
    submitted        -[thickness=4]-> scheduling    : [schedule]
    submitted                     --> staging

  }

  state Editing {

    [*]<<Hidden>>  -[hidden,norank]-> editing

    editing               -[dashed]-> canceled      : [cancel]
    editing          -[thickness=3]-> modifying     : [submit]
    editing          -[thickness=3]-> replacing     : [upload]

'   replacing       -[dotted,norank]> purged        : [purge]
    replacing                     --> editing       : [reject]
    replacing             -[dashed]-> canceled      : [cancel]
    replacing        -[thickness=3]-> modifying     : [submit]

'   modifying       -[dotted,norank]> purged        : [purge]
    modifying                     --> editing       : [reject]
    modifying        -[thickness=3]-> modified

'   modified        -[dotted,norank]> purged        : [purge]
    modified         -[thickness=4]-> scheduling    : [schedule]
    modified                      --> staging

  }

  state Removing {

    [*]<<Hidden>>  -[hidden,norank]-> removing

    removing              -[dashed]-> canceled      : [cancel]
    removing         -[thickness=3]-> removed       : [submit]

    removed          ------[dashed]-> failed        : [fail]
    removed          -[thickness=4]-> staging

  }

  state Reviewing {

    [*]<<Hidden>>   -[hidden,norank]> scheduling

    scheduling       -[thickness=3]-> assigned      : [assign]
    scheduling                    --> assigning

    assigning                     --> holding       : [hold]
'   assigning       -[hidden,norank]> assigned      : [assign]
    assigning                     --> assigned

'   holding         -[dotted,norank]> editing       : [edit]
'   holding         -[dotted,norank]> canceled      : [cancel]
'   holding         -[dotted,norank]> purged        : [purge]
    holding                     -up-> holding       : [timeout]
    holding               -[dashed]-> failed        : [fail]
    holding                       --> assigning

'   assigned        -[dotted,norank]> editing       : [edit]
'   assigned        -[dotted,norank]> canceled      : [cancel]
'   assigned        -[dotted,norank]> purged        : [purge]
    assigned         -[thickness=3]-> reviewing     : [review]

    reviewing        -[thickness=2]-> rejected      : [reject]
    reviewing        -[thickness=3]-> approved      : [approve]

'   rejected        -[dotted,norank]> purged        : [purge]
    rejected       -up[thickness=2]-> editing       : [edit]
    rejected         -[thickness=2]-> canceled      : [cancel]

    approved         -[thickness=4]-> staging

  }

  state Staging {

    [*]<<Hidden>>   -[hidden,norank]> staging

    staging                       --> indexing      : [index]
    staging          -[thickness=3]-> unretrieved

    unretrieved           -[dashed]-> failed        : [fail]
    unretrieved                 -up-> unretrieved   : [timeout]
    unretrieved      -[thickness=3]-> retrieved

    retrieved    -left[thickness=4]-> indexing

  }

  state Indexing {

    [*]<<Hidden>>  -[hidden,norank]-> indexing

    indexing              -[dashed]-> failed        : [fail]
    indexing                    -up-> indexing      : [timeout]
    indexing         -[thickness=3]-> indexed

    indexed          -[thickness=4]-> completed

  }

  state Termination {

'   suspended       -[dotted,norank]> starting      : [reset]
'   suspended       -[dotted,norank]> resuming      : [resume]
    suspended                     --> purged

'   failed          -[dotted,norank]> starting      : [reset]
'   failed          -[dotted,norank]> resuming      : [resume]
    failed                        --> purged
    failed                        --> end_state

'   canceled        -[dotted,norank]> starting      : [reset]
'   canceled        -[dotted,norank]> resuming      : [resume]
    canceled                      --> purged
    canceled                      --> end_state

'   completed       -[dotted,norank]> starting      : [reset]
    completed                     --> purged
    completed                     --> end_state

    purged                        --> end_state

  }

  ' === NOTE: not actually in the workflow; just needed for the diagram:
  end_state --> [*]

  @enduml

```

&nbsp;
____

## Maintenance Notes

The code from the `UploadWorkflow` section is derived from the code in
`UploadWorkflowGrouped` and then the lines for the enclosing states are
commented out so that only the basic states are rendered.

### Workflow updates

If there are changes to the workflow states or transitions in the
`UploadWorkflow` class, the preferred strategy is to update the
`UploadWorkflowGrouped` section first, and then reflect the changes as
appropriate in the `UploadWorkflow` section.

_Keeping the equivalent (but commented-out lines) in that section makes it
easier to compare the two in order to see where they diverge._

### Other tips

In both sections a number of transitions are hidden because displaying them
(even as dashed lines) makes the resulting diagram far too busy.  However, it's
not enough to just use the "hidden" attribute because the lines are still
"rendered" invisibly -- for that reason, all hidden transitions are also
commented-out (in both sections) so that their invisible presence does not have
unexpected (and hard to cope with) consequences to the positioning of states
and transitions that _are_ visible.

### References
* [The Hitchhiker's Guide to PlantUML][layout]
* [PlantUML State Diagram][plantuml_state]
* [PlantUML colors][plantuml_color] OR:

All PlantUML Colors:

```
@startuml
colors
@enduml
```

Neighboring PlantUML Colors

```
@startuml
colors cyan
@enduml
```

<!--========================================================================-->

[basic_cached]:     https://www.plantuml.com/plantuml/proxy?src=https://raw.github.com/uvalib/emma/master/lib/doc/workflow.md&idx=0
[basic_uncached]:   https://www.plantuml.com/plantuml/proxy?src=https://raw.github.com/uvalib/emma/master/lib/doc/workflow.md&idx=0&cache=no

[grouped_cached]:   https://www.plantuml.com/plantuml/proxy?src=https://raw.github.com/uvalib/emma/master/lib/doc/workflow.md&idx=1
[grouped_uncached]: https://www.plantuml.com/plantuml/proxy?src=https://raw.github.com/uvalib/emma/master/lib/doc/workflow.md&idx=1&cache=no

[plantuml_server]:  https://www.plantuml.com/plantuml
[example_cached]:   https://www.plantuml.com/plantuml/proxy?src=https://raw.github.com/plantuml/plantuml-server/master/src/main/webapp/resource/test2diagrams.txt
[example_uncached]: https://www.plantuml.com/plantuml/proxy?src=https://raw.github.com/plantuml/plantuml-server/master/src/main/webapp/resource/test2diagrams.txt&cache=no

[hitchhiker]:       https://crashedmind.github.io/PlantUMLHitchhikersGuide
[layout]:           https://crashedmind.github.io/PlantUMLHitchhikersGuide/layout/layout.html
[plantuml]:         https://plantuml.com
[plantuml_state]:   https://plantuml.com/state-diagram
[plantuml_color]:   https://plantuml.com/color
