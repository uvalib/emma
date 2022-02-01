// app/assets/javascripts/shared/http.js


// ============================================================================
// Constants - HTTP
// ============================================================================

/**
 * HTTP response codes.
 *
 * @constant
 * @type {object}
 */
export const HTTP = Object.freeze({
    ok:                     200,
    created:                201,
    accepted:               202,
    non_authoritative:      203,
    no_content:             204,
    multiple_choices:       300,
    moved_permanently:      301,
    found:                  302,
    not_modified:           304,
    temporary_redirect:     307,
    permanent_redirect:     308,
    bad_request:            400,
    unauthorized:           401,
    forbidden:              403,
    request_timeout:        408,
    conflict:               409,
    internal_server_error:  500,
    not_implemented:        501,
    bad_gateway:            502,
    service_unavailable:    503,
    gateway_timeout:        504,
});
