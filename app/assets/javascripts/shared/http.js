// app/assets/javascripts/shared/http.js


import { AppDebug } from "../application/debug";


AppDebug.file("shared/http");

// ============================================================================
// HTTP response codes
// ============================================================================

/** @const */ export const failed                 = 0;   // no response
//* @const */ export const continue               = 100;
//* @const */ export const switching_protocols    = 101;
//* @const */ export const processing             = 102;
//* @const */ export const early_hints            = 103;
/** @const */ export const ok                     = 200;
/** @const */ export const created                = 201;
/** @const */ export const accepted               = 202;
//* @const */ export const non_authoritative      = 203;
//* @const */ export const no_content             = 204;
//* @const */ export const reset_content          = 205;
//* @const */ export const partial_content        = 206;
//* @const */ export const multi_status           = 207;
//* @const */ export const already_reported       = 208;
//* @const */ export const im_used                = 226;
//* @const */ export const multiple_choices       = 300;
//* @const */ export const moved_permanently      = 301;
//* @const */ export const found                  = 302;
//* @const */ export const see_other              = 303;
//* @const */ export const not_modified           = 304;
//* @const */ export const use_proxy              = 305;
//* @const */ export const switch_proxy           = 306; // deprecated
//* @const */ export const temporary_redirect     = 307;
//* @const */ export const permanent_redirect     = 308;
/** @const */ export const bad_request            = 400;
/** @const */ export const unauthorized           = 401;
//* @const */ export const payment_required       = 402;
/** @const */ export const forbidden              = 403;
/** @const */ export const not_found              = 404;
//* @const */ export const method_not_allowed     = 405;
//* @const */ export const not_acceptable         = 406;
//* @const */ export const proxy_auth_required    = 407;
//* @const */ export const request_timeout        = 408;
//* @const */ export const conflict               = 409;
//* @const */ export const gone                   = 410;
//* @const */ export const length_required        = 411;
//* @const */ export const precondition_failed    = 412;
/** @const */ export const payload_too_large      = 413;
//* @const */ export const uri_too_long           = 414;
//* @const */ export const unsupported_media_type = 415;
//* @const */ export const range_not_satisfiable  = 416;
//* @const */ export const expectation_failed     = 417;
//* @const */ export const im_a_teapot            = 418;
//* @const */ export const misdirected_request    = 421;
//* @const */ export const unprocessable_entity   = 422;
//* @const */ export const locked                 = 423;
//* @const */ export const failed_dependency      = 424;
//* @const */ export const too_early              = 425;
//* @const */ export const upgrade_required       = 426;
//* @const */ export const precondition_required  = 428;
//* @const */ export const too_many_requests      = 429;
//* @const */ export const header_field_too_large = 431;
//* @const */ export const unavailable_illegal    = 451;
/** @const */ export const internal_server_error  = 500;
//* @const */ export const not_implemented        = 501;
/** @const */ export const bad_gateway            = 502;
/** @const */ export const service_unavailable    = 503;
/** @const */ export const gateway_timeout        = 504;
//* @const */ export const version_not_supported  = 505;
//* @const */ export const variant_negotiates     = 506;
//* @const */ export const insufficient_storage   = 507;
//* @const */ export const loop_detected          = 508;
//* @const */ export const not_extended           = 510;
//* @const */ export const network_auth_required  = 511;
