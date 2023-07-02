// app/assets/javascripts/shared/manifests.js


import { AppDebug }                   from '../application/debug';
import { Api }                        from './api';
import { pageAction, pageAttributes } from './controller';
import { isDefined, isMissing }       from './definitions';
import { flashError, flashMessage }   from './flash';
import { selfOrParent }               from './html';
import { compact, hasKey }            from './objects';


const MODULE = 'Manifest';
const DEBUG  = true;

AppDebug.file('shared/manifests', MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {ActionProperties} ActionPropertiesExt
 *
 * @property {boolean} [highlight]  If **true** add BEST_CHOICE_MARKER.
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
export const MANIFEST_MODEL = 'manifest';

/**
 * Base name (singular of the related database table).
 *
 * @readonly
 * @type {string}
 */
export const ITEM_MODEL = 'manifest_item';

export const BULK_CONTROLLER = MANIFEST_MODEL;
export const ROW_CONTROLLER  = ITEM_MODEL;

/**
 * Name of the attribute indicating the ID of the Manifest database record
 * associated with an element or its ancestor.
 *
 * @type {string}
 */
export const MANIFEST_ATTR = 'data-manifest';

/**
 * Name of the attribute indicating the ID of the ManifestItem database
 * record associated with an element or its ancestor.
 *
 * @type {string}
 */
export const ITEM_ATTR = 'data-item-id';

export const DISABLED_MARKER = 'disabled';

export const BEST_CHOICE_MARKER = 'best-choice';

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
    const func = 'attribute';
    //_debug(`${func}: name = ${name}; target =`, target);
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
    if (_debugging()) {
        const func = caller || 'initializeButtonSet';
        _debug(func);
        $.each(buttons, (type, $button) => {
            if (isMissing($button)) {
                _error(`${func}: no button for "${type}"`);
            }
        });
    }
}

/**
 * Return the button indicated by *type*.
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
        const func  = caller || 'buttonFor';
        const types = Object.keys(buttons);
        if (types.includes(type)) {
            console.error(`${func}: no button for "${type}"`);
        } else {
            console.error(`${func}: "${type}" not in`, types);
        }
        return;
    }
    return $button;
}

/**
 * Change button state.
 *
 * @param {Selector}                button
 * @param {boolean}                 [enable]
 * @param {string|ActionProperties} [config]
 * @param {ActionPropertiesExt}     [override]  Overrides to *config*.
 *
 * @returns {jQuery|undefined}
 */
export function enableButton(button, enable, config, override) {
    _debug(`enableButton: enable = "${enable}"`, button);
    if (!button) { return }
    const $button  = $(button);
    const enabling = (enable !== false);
    const type     = (typeof(config) === 'string') ? config : '';
    let prop       = type ? configFor(type, enabling) : (config || {});
    if (override)     { prop = { ...prop, ...properties(override, enabling) } }
    if (prop.label)   { $button.text(prop.label) }
    if (prop.tooltip) { $button.attr('title', prop.tooltip) }
    if (hasKey(prop, 'highlight')) {
        $button.toggleClass(BEST_CHOICE_MARKER, prop.highlight);
    }
    $button.attr('aria-disabled', !enabling);
    $button.toggleClass(DISABLED_MARKER, !enabling);
    return $button;
}

// ============================================================================
// Functions - configuration
// ============================================================================

/**
 * Configuration values entries for the given *type*.
 *
 * @param {string}  type
 * @param {boolean} [enabled]
 * @param {string}  [page_action]     Default: {@link pageAction}
 *
 * @returns {ActionPropertiesExt}
 */
export function configFor(type, enabled, page_action) {
    //_debug(`configFor: type = "${type}"; action = "${action}"`);
    const page       = pageAttributes();
    const action     = page_action || page.action;
    const ctrlr_cfg  = page.properties.Action || {};
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
        case true:  return { ...config, ...config?.enabled };
        case false: return { ...config, ...config?.disabled };
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
 * @typedef {object} SendOptions
 *
 * Option values for the {@link serverSend} function.
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
 * @param {string|SendOptions} action
 * @param {SendOptions}        [send_options]
 */
export function serverBulkSend(action, send_options) {
    const func       = 'serverBulkSend';
    const controller = BULK_CONTROLLER;
    const override   = send_options?.controller;
    if (typeof action !== 'string') {
        console.error(`${func}: invalid action`, action);
    } else if (override && (override !== controller)) {
        console.warn(`${func}: ignored controller override "${override}"`);
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
    const func = 'serverItemSend';
    let ctrlr, action, opt;
    if (Array.isArray(ctr_act))      { [ctrlr, action] = ctr_act } else
    if (typeof ctr_act === 'string') { action = ctr_act }          else
    if (typeof ctr_act === 'object') { opt    = ctr_act }
    opt    ||= { ...send_options };
    action ||= opt.action;
    ctrlr  ||= opt.controller;

    const params   = opt.params  || {};
    const headers  = opt.headers || {};
    const options  = { headers: headers };
    const cb_ok    = opt.onSuccess;
    const cb_err   = opt.onError;
    const cb_done  = opt.onComplete;
    const cb_comm  = opt.onCommStatus;
    const caller   = compact([opt.caller, func]).join(': ');
    const callback = (result, warning, error, xhr) => {
        if (_debugging()) {
            _debug(`${caller}: result =`, result);
            warning && _debug(`${caller}: warning =`, warning);
            error   && _debug(`${caller}: error   =`, error);
            xhr     && _debug(`${caller}: xhr     =`, xhr);
        }
        let [err, warn, offline] = [error, warning, !xhr.status];
        if (!err && !warn && !offline) {
            cb_ok?.(result, warn, err, xhr);
        } else if (offline && !cb_comm) {
            err = 'EMMA is offline'; // TODO: I18n
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
    if (_debugging()) {
        _debug(`${caller}: ctrlr   = "${ctrlr || apiController()}"`);
        _debug(`${caller}: action  = "${action}"`);
        _debug(`${caller}: params  =`, params);
        _debug(`${caller}: options =`, options);
    }
    if (action) {
        const method = opt.method?.toUpperCase() || 'POST';
        options._ignoreBody = opt._ignoreBody;
        server(ctrlr).xmit(method, action, params, options, callback);
    } else {
        _error(`${caller}: no action given`);
    }
}

// ============================================================================
// Functions - diagnostics
// ============================================================================

/**
 * Indicate whether console debugging is active.
 *
 * @returns {boolean}
 */
function _debugging() {
    return AppDebug.activeFor(MODULE, DEBUG);
}

/**
 * Emit a console message if debugging.
 *
 * @param {...*} args
 */
function _debug(...args) {
    _debugging() && console.log(`${MODULE}:`, ...args);
}

/**
 * Emit a console error and display as a flash error if debugging.
 *
 * @param {string} caller
 * @param {string} [message]
 */
function _error(caller, message) {
    const msg = isDefined(message) ? `${caller}: ${message}` : caller;
    console.error(msg);
    _debugging() && flashError(msg);
}
