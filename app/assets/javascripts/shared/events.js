// app/assets/javascripts/shared/events.js


import { AppDebug }                           from "../application/debug";
import { appEventListener, DOC_KEY, WIN_KEY } from "../application/setup";


AppDebug.file("shared/events");

// ============================================================================
// Type definitions
// ============================================================================

/**
 * For event handlers processed by jQuery, a *false* return will result in
 * `event.stopPropagation()` and `event.preventDefault()`.
 *
 * @typedef {boolean|undefined} EventHandlerReturn
 *
 * @see https://api.jquery.com/on/ jQuery.on()
 */

/**
 * @callback jQueryEventHandler
 * @param {ElementEvt} [event]
 * @returns {EventHandlerReturn}
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * The default delay for {@link delayedBy} in milliseconds.
 *
 * @readonly
 * @type {number}
 */
export const DEFAULT_DELAY = 100;

/**
 * The default delay for {@link debounce} in milliseconds.
 *
 * @readonly
 * @type {number}
 */
export const DEBOUNCE_DELAY = 250;

export const PHASE = [
    "NONE",         // Event.NONE
    "CAPTURING",    // Event.CAPTURING_PHASE
    "AT_TARGET",    // Event.AT_TARGET
    "BUBBLING",     // Event.BUBBLING_PHASE
];

// ============================================================================
// Functions
// ============================================================================

/**
 * Indicate whether the item is an Event or jQuery.Event.
 *
 * @param {*} item
 * @param {*} [type]
 *
 * @returns {boolean}
 */
export function isEvent(item, type) {
    const jq    = (item instanceof jQuery.Event);
    const ev    = (item instanceof Event);
    const event = (jq && item.originalEvent) || (ev && item);
    switch (typeof type) {
        case "undefined": return !!event;
        case "string":    return !!event && (event.type === type);
        default:          return !!event && (event instanceof type);
    }
}

/**
 * A description of the event phase for diagnostics.
 *
 * @param {jQuery.Event|Event|undefined} event
 *
 * @returns {string}
 */
export function phase(event) {
    const value = event?.eventPhase;
    return PHASE[value] || `${value}`;
}

/**
 * Generate a wrapper function which executes the callback function only after
 * the indicated delay.
 *
 * @param {function} callback
 * @param {number}   [wait]           Default: {@link DEBOUNCE_DELAY}.
 *
 * @returns {function}
 */
export function debounce(callback, wait = DEBOUNCE_DELAY) {
    return delayedBy(wait, callback);
}

/**
 * Generate a wrapper function which executes the callback function only after
 * the indicated delay.
 *
 * @param {number|undefined} wait     Default: {@link DEFAULT_DELAY}.
 * @param {function}         callback
 *
 * @returns {function}
 */
export function delayedBy(wait, callback) {
    const delay = wait || DEFAULT_DELAY;
    let timeout;
    return function(...args) {
        const _this = this;
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            timeout = null;
            callback.call(_this, ...args);
        }, delay);
    }
}

/**
 * Set an event handler without concern that it may already set.
 *
 * @param {Selector}                                element
 * @param {string}                                  name        Event name.
 * @param {jQueryEventHandler|jQueryEventHandler[]} callback    Event handlers.
 *
 * @returns {jQuery}
 */
export function handleEvent(element, name, callback) {
    const $element = $(element);
    if (Array.isArray(callback)) {
        callback.forEach(cb => $element.off(name, cb).on(name, cb));
    } else {
        $element.off(name, callback).on(name, callback);
    }
    return $element;
}

/**
 * Set hover and focus event handlers.
 *
 * @param {Selector}           element
 * @param {jQueryEventHandler} cbEnter      Event handler for "enter".
 * @param {jQueryEventHandler} [cbLeave]    Event handler for "leave".
 */
export function handleHoverAndFocus(element, cbEnter, cbLeave) {
    const $element = $(element);
    if (cbEnter) {
        handleEvent($element, "mouseenter", cbEnter);
        handleEvent($element, "focus",      cbEnter);
    }
    if (cbLeave) {
        handleEvent($element, "mouseleave", cbLeave);
        handleEvent($element, "blur",       cbLeave);
    }
}

/**
 * Set an event handler for the capturing phase. <p/>
 *
 * If **options** includes "{listen: false}" then the only action is to remove
 * a previous event handler.
 *
 * @param {Selector}                                element
 * @param {string}                                  name        Event name.
 * @param {EventListenerOrEventListenerObject|null} callback
 * @param {EventListenerOptionsExt|boolean}         [options]
 */
export function handleCapture(element, name, callback, options) {
    let opt = { capture: true, remove: true, listen: true };
    if (typeof options === "object") {
        opt = { ...opt, ...options };
    } else if (options === false) {
        opt.capture = false;
    }
    const elems  = $(element).toArray();
    const remove = opt.remove;
    const listen = opt.listen;
    delete opt.remove;
    delete opt.listen;
    remove && elems.forEach(el => el.removeEventListener(name, callback, opt));
    listen && elems.forEach(el => el.addEventListener(name, callback, opt));
}

// ============================================================================
// Functions - window/document events
// ============================================================================

/**
 * Set a window event handler without concern that it may already set.
 *
 * @param {string}                                  type
 * @param {EventListenerOrEventListenerObject|null} callback
 * @param {EventListenerOptionsExt|boolean}         [options]
 */
export function windowEvent(type, callback, options) {
    appEventListener(WIN_KEY, type, callback, options);
}

/**
 * Set a document event handler without concern that it may already set.
 *
 * @param {string}                                  type
 * @param {EventListenerOrEventListenerObject|null} callback
 * @param {EventListenerOptionsExt|boolean}         [options]
 */
export function documentEvent(type, callback, options) {
    appEventListener(DOC_KEY, type, callback, options);
}

/**
 * Invoke a callback when leaving the page, either
 * [1] via history.back() or history.forward(), or
 * [2] due to clicking on a link.
 *
 * @param {EventListener|function():void} callback
 * @param {boolean} [_debug] If *true* show console warnings on events.
 */
export function onPageExit(callback, _debug) {
/*
    const cb = debug ? (
        e => { console.warn(`>>>>> ${e.type} EVENT <<<<<`, e); callback(e) }
    ) : callback;
    windowEvent("beforeunload", cb);        // [1]
    documentEvent("turbolinks:click", cb);  // [2]
*/
    // TODO: Generating an internal callback function makes it impossible to
    //  teardown these handlers
    windowEvent("beforeunload", callback);        // [1]
    documentEvent("turbolinks:click", callback);  // [2]
}
