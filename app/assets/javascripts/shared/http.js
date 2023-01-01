// app/assets/javascripts/shared/http.js


import { AppDebug } from '../application/debug';


AppDebug.file('shared/http');

// ============================================================================
// Constants
// ============================================================================

/**
 * HTTP response codes.
 *
 * @readonly
 * @type {Object.<string,number>}
 */
export const HTTP = Object.freeze({
    failed:                 0,   // no response (xhr.status === 0)
    ok:                     200,
    created:                201,
    accepted:               202,
    non_authoritative:      203,
    no_content:             204,
    reset_content:          205,
    partial_content:        206,
    im_used:                226,
    multiple_choices:       300,
    moved_permanently:      301,
    found:                  302,
    see_other:              303,
    not_modified:           304,
    use_proxy:              305,
    switch_proxy:           306, // deprecated
    temporary_redirect:     307,
    permanent_redirect:     308,
    bad_request:            400,
    unauthorized:           401,
    payment_required:       402,
    forbidden:              403,
    not_found:              404,
    method_not_allowed:     405,
    not_acceptable:         406,
    proxy_auth_required:    407,
    request_timeout:        408,
    conflict:               409,
    gone:                   410,
    length_required:        411,
    precondition_failed:    412,
    payload_too_large:      413,
    uri_too_long:           414,
    unsupported_media_type: 415,
    range_not_satisfiable:  416,
    expectation_failed:     417,
    im_a_teapot:            418,
    misdirected_request:    421,
    too_early:              425,
    upgrade_required:       426,
    precondition_required:  428,
    too_many_requests:      429,
    header_field_too_large: 431,
    unavailable_illegal:    451,
    internal_server_error:  500,
    not_implemented:        501,
    bad_gateway:            502,
    service_unavailable:    503,
    gateway_timeout:        504,
    version_not_supported:  505,
    variant_negotiates:     506,
    not_extended:           510,
    network_auth_required:  511,
});
