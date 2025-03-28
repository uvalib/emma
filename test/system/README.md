# System Tests

These tests focus on the interactive behavior of each controller's
browser-accessible endpoint from the perspective of a user with a particular
role.

## Naming Convention

In order to ensure that the test class covers all of the endpoints defined by
the controller, tests have names of the form
`'CTRLR - ACTION - optional description'` where CTRLR matches the CTRLR
constant for the test class (or its plural) and ACTION matches the
`params[:action]` value defined within the test.

This allows the test class "meta test" named `'CTRLR system test coverage'`
to use `TestHelper::Utility#check_system_coverage` to verify that each
controller endpoint has a matching system test.
