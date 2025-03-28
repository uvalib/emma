# Controller Tests

These tests focus on ensuring that each controller's endpoints respond with the
expected HTTP status depending on the combination of user and requested format.

Because of this, each individual test typically performs its associated request
for users of differing roles for all allowable formats.

EMMA does not support a full-fledged API, so write tests only accept HTML
requests.  Many read tests cover HTML, JSON, and XML requests.

## Naming Convention

In order to ensure that the test class covers all of the endpoints defined by
the controller, tests have names of the form
`'CTRLR ACTION - optional description'` where CTRLR matches the CTRLR constant
for the test class and ACTION matches the `action` variable defined within the
test.

This allows the test class "meta test" named `'CTRLR controller test coverage'`
to use `TestHelper::Utility#check_controller_coverage` to verify that each
controller endpoint has a matching controller test.
