// app/assets/javascripts/shared/manifests.js


import { AppDebug }                   from "../application/debug";
import { Api }                        from "./api";
import { Emma }                       from "./assets";
import { pageAction, pageAttributes } from "./controller";
import { isMissing }                  from "./definitions";
import { flashError, flashMessage }   from "./flash";
import { selfOrParent }               from "./html";
import { hasKey }                     from "./objects";


const MODULE = "Manifest";
const DEBUG  = true;

AppDebug.file("shared/manifests", MODULE, DEBUG);

/**
 * Console output functions for this module.
 */
const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {ActionProperties} ActionPropertiesExt
 *
 * @property {boolean} [highlight]  If *true*, add BEST_CHOICE_MARKER.
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * Base name (singular of the related database table).
 *
 * @readonly
 * @type {string}
 */
export const MANIFEST_MODEL = "manifest";

/**
 * Base name (singular of the related database table).
 *
 * @readonly
 * @type {string}
 */
export const ITEM_MODEL = "manifest_item";

export const BULK_CONTROLLER = MANIFEST_MODEL;
export const ROW_CONTROLLER  = ITEM_MODEL;

/**
 * Name of the attribute indicating the ID of the Manifest database record
 * associated with an element or its ancestor.
 *
 * @type {string}
 */
export const MANIFEST_ATTR = "data-manifest";

/**
 * Name of the attribute indicating the ID of the ManifestItem database
 * record associated with an element or its ancestor.
 *
 * @type {string}
 */
export const ITEM_ATTR = "data-item-id";

export const DISABLED_MARKER = "disabled";

export const BEST_CHOICE_MARKER = "best-choice";

// ============================================================================
// Functions
// ============================================================================

/**
 * The attribute value which applies to the given target (either directly
 * or from a parent element).
 *
 * @param {Selector} target
 * @param {string}   name         Attribute name.
 *
 * @returns {string}
 */
export function attribute(target, name) {
    const func = "attribute"; //OUT.debug(`${func}: ${name}: target =`, target)
    return selfOrParent(target, `[${name}]`, func).attr(name);
}

// ============================================================================
// Functions - buttons
// ============================================================================

/**
 * initializeButtonSet
 *
 * @param {Object.<string,jQuery>} buttons
 * @param {string}                 [caller]
 */
export function initializeButtonSet(buttons, caller) {
    if (OUT.debugging()) {
        const func = caller || "initializeButtonSet";
        OUT.debug(func);
        for (const [type, $button] of Object.entries(buttons)) {
            if (isMissing($button)) {
                OUT.error(`${func}: no button for "${type}"`);
            }
        }
    }
}

/**
 * Return the button indicated by **type**.
 *
 * @param {string}                 type
 * @param {Object.<string,jQuery>} buttons
 * @param {string}                 [caller]
 *
 * @returns {jQuery|undefined}
 */
export function buttonFor(type, buttons, caller) {
    const $button = buttons[type];
    if (isMissing($button)) {
        const func  = caller || "buttonFor";
        const types = Object.keys(buttons);
        if (types.includes(type)) {
            return OUT.error(`${func}: no button for "${type}"`);
        } else {
            return OUT.error(`${func}: "${type}" not in`, types);
        }
    }
    return $button;
}

/**
 * Change button state.
 *
 * @param {Selector}                button
 * @param {boolean}                 [enable]
 * @param {string|ActionProperties} [config]
 * @param {ActionPropertiesExt}     [override]  Overrides to **config**.
 *
 * @returns {jQuery|undefined}
 */
export function enableButton(button, enable, config, override) {
    OUT.debug(`enableButton: enable = "${enable}"`, button);
    if (!button) { return }
    /** @type {jQuery} */
    const $button  = $(button);
    const enabling = (enable !== false);
    const type     = (typeof(config) === "string") ? config : "";
    let prop       = type ? configFor(type, enabling) : (config || {});
    if (override)     { prop = { ...prop, ...properties(override, enabling) } }
    if (prop.label)   { $button.text(prop.label) }
    if (prop.tooltip) { $button.attr("title", prop.tooltip) }
    if (hasKey(prop, "highlight")) {
        $button.toggleClass(BEST_CHOICE_MARKER, prop.highlight);
    }
    if (enabling) {
        $button.removeAttr("tabindex");
    } else {
        $button.attr("tabindex", -1);
    }
    $button.attr("disabled", !enabling);
    $button.attr("aria-disabled", !enabling);
    $button.toggleClass(DISABLED_MARKER, !enabling);
    return $button;
}

// ============================================================================
// Functions - configuration
// ============================================================================

/**
 * Configuration values entries for the given **type**.
 *
 * @param {string}  type
 * @param {boolean} [enabled]
 * @param {string}  [page_action]     Default: {@link pageAction}
 *
 * @returns {ActionPropertiesExt}
 */
export function configFor(type, enabled, page_action) {
    //OUT.debug(`configFor: type = "${type}"; action = "${action}"`);
    const page       = pageAttributes();
    const action     = page_action || page.action;
    const ctrlr_cfg  = page.properties?.Action || {};
    const action_cfg = ctrlr_cfg[action] || ctrlr_cfg.new || {};
    return properties(action_cfg[type], enabled);
}

/**
 * Get configuration property values based on context.
 *
 * @param {ActionProperties} [config]
 * @param {boolean}          [enabled]
 *
 * @returns {ActionPropertiesExt}
 */
export function properties(config, enabled = undefined) {
    switch (enabled) {
        case true:  return { ...config, ...config?.if_enabled };
        case false: return { ...config, ...config?.if_disabled };
        default:    return { ...config };
    }
}

// ============================================================================
// Functions - page - server interface
// ============================================================================

let api_server;

/**
 * The server controller for most operations.
 *
 * @returns {string}
 */
export function apiController() {
    return ROW_CONTROLLER;
}

/**
 * Interface to the server.
 *
 * @param {string}       [controller]   Default: {@link apiController}.
 * @param {XmitCallback} [callback]
 *
 * @returns {Api}
 */
export function server(controller, callback) {
    if (controller || callback) {
        const ctrlr   = controller || apiController();
        const options = callback ? { callback: callback } : {};
        return new Api(ctrlr, options);
    } else {
        return api_server ||= new Api(apiController());
    }
}

/**
 * Option values for the {@link serverSend} function.
 *
 * @typedef {object} SendOptions
 *
 * @property {boolean}            [_ignoreBody]
 * @property {string}             [method]
 * @property {string}             [controller]
 * @property {string}             [action]
 * @property {Object.<string,*>}  [params]
 * @property {StringTable}        [headers]
 * @property {string}             [caller]
 * @property {XmitCallback}       [onSuccess]
 * @property {XmitCallback}       [onError]
 * @property {XmitCallback}       [onComplete]
 * @property {XmitCallback}       [onCommStatus]
 */

/**
 * Post to a "manifest" controller endpoint.
 *
 * @param {string}      action
 * @param {SendOptions} [send_options]
 */
export function serverBulkSend(action, send_options) {
    const func       = "serverBulkSend";
    const controller = BULK_CONTROLLER;
    const override   = send_options?.controller;
    if (typeof action !== "string") {
        OUT.error(`${func}: invalid action`, action);
    }
    if (override && (override !== controller)) {
        OUT.warn(`${func}: ignored controller override "${override}"`);
    }
    serverSend([controller, action], send_options);
}

/**
 * Post to a server endpoint.
 *
 * @param {string|string[]|SendOptions} ctr_act
 * @param {SendOptions}                 [send_options]
 *
 * @overload serverSend(controller_action, send_options)
 *  Controller/action followed by options.
 *  @param {string[]}    ctr_act
 *  @param {SendOptions} [send_options]
 *
 * @overload serverSend(action, send_options)
 *  Action followed by options (optionally specifying controller).
 *  @param {string}      ctr_act
 *  @param {SendOptions} [send_options]
 *
 * @overload serverSend(send_options)
 *  Options which specify action (and optionally controller).
 *  @param {SendOptions} [send_options]
 */
export function serverSend(ctr_act, send_options) {
    const func = "serverItemSend";
    const opt  = { ...send_options };
    let ctrlr, action;
    if (Array.isArray(ctr_act))      { [ctrlr, action] = ctr_act } else
    if (typeof ctr_act === "string") { action = ctr_act }          else
    if (typeof ctr_act === "object") { Object.assign(opt, ctr_act) }
    ctrlr  ||= opt.controller;
    action ||= opt.action;

    const params   = opt.params  || {};
    const headers  = opt.headers || {};
    const options  = { headers: headers };
    const cb_ok    = opt.onSuccess;
    const cb_err   = opt.onError;
    const cb_done  = opt.onComplete;
    const cb_comm  = opt.onCommStatus;
    const debug    = OUT.debugging();
    const caller   = debug && (opt.caller ? `${opt.caller}: ${func}` : func);
    const callback = (result, warning, error, xhr) => {
        debug            && OUT.debug(`${caller}: result  =`, result);
        debug && warning && OUT.debug(`${caller}: warning =`, warning);
        debug && error   && OUT.debug(`${caller}: error   =`, error);
        debug && xhr     && OUT.debug(`${caller}: xhr     =`, xhr);
        let [err, warn, offline] = [error, warning, !xhr.status];
        if (!err && !warn && !offline) {
            cb_ok?.(result, warn, err, xhr);
        } else if (offline && !cb_comm) {
            err = Emma.Terms.status.offline;
        }
        if (err || warn) {
            if (!offline || !cb_comm) {
                if (err) { flashError(err) } else { flashMessage(warn) }
            }
            cb_err?.(result, warn, err, xhr);
        }
        cb_done?.(result, warn, err, xhr);
        cb_comm?.(!offline, warn, err, xhr);
    }
    if (debug) {
        OUT.debug(`${caller}: ctrlr   = "${ctrlr || apiController()}"`);
        OUT.debug(`${caller}: action  = "${action}"`);
        OUT.debug(`${caller}: params  =`, params);
        OUT.debug(`${caller}: options =`, options);
    }
    if (action) {
        const method = opt.method?.toUpperCase() || "POST";
        options._ignoreBody = opt._ignoreBody;
        server(ctrlr).xmit(method, action, params, options, callback);
    } else {
        OUT.error(`${caller}: no action given`);
    }
}
