// app/assets/javascripts/shared/events.js


import { handleKeypressAsClick } from './accessibility'
import { ensureTabbable }        from './html'


// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {Selector|jQuery.Event|Event} SelectorOrEvent
 */

/**
 * @callback jQueryEventHandler
 * @param {jQuery.Event|Event} [event]
 * @returns {?boolean}
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * The default delay for {@link debounce}.
 *
 * @readonly
 * @type {number}
 */
export const DEBOUNCE_DELAY = 250; // milliseconds

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
    if (item instanceof jQuery.Event) {
        return !type || (item.originalEvent instanceof type);
    } else if (item instanceof Event) {
        return !type || (item instanceof type);
    } else {
        return false;
    }
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
export function debounce(callback, wait) {
    const delay = wait || DEBOUNCE_DELAY; // milliseconds
    let timeout;
    return function() {
        const _this = this;
        const args  = arguments;
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            timeout = null;
            callback.apply(_this, args);
        }, delay);
    }
}

/**
 * Set an event handler without concern that it may already set.
 *
 * @param {jQuery}             $element
 * @param {string}             name     Event name.
 * @param {jQueryEventHandler} func     Event handler.
 *
 * @returns {jQuery}
 */
export function handleEvent($element, name, func) {
    return $element.off(name, func).on(name, func);
}

/**
 * Set click and keypress event handlers without concern that it may already
 * set.
 *
 * @param {jQuery}             $element
 * @param {jQueryEventHandler} func     Event handler.
 *
 * @returns {jQuery}
 */
export function handleClickAndKeypress($element, func) {
    ensureTabbable($element);
    return handleEvent($element, 'click', func).each(handleKeypressAsClick);
}

/**
 * Set hover and focus event handlers.
 *
 * @param {jQuery}             $element
 * @param {jQueryEventHandler} funcEnter    Event handler for 'enter'.
 * @param {jQueryEventHandler} [funcLeave]  Event handler for 'leave'.
 */
export function handleHoverAndFocus($element, funcEnter, funcLeave) {
    if (funcEnter) {
        handleEvent($element, 'mouseenter', funcEnter);
        handleEvent($element, 'focus',      funcEnter);
    }
    if (funcLeave) {
        handleEvent($element, 'mouseleave', funcLeave);
        handleEvent($element, 'blur',       funcLeave);
    }
}

/**
 * Invoke a callback when leaving the page.
 *
 * @param {function} callback
 * @param {boolean}  [debug]        If *true* show console warnings on events.
 */
export function onPageExit(callback, debug) {
    if (debug) {
        handleEvent($(document), 'turbolinks:click', function() {
            // Leaving the page due to clicking on a link.
            console.warn('>>>>> turbolinks:click EVENT <<<<<');
            callback();
        });
        handleEvent($(window), 'beforeunload', function() {
            // Leaving the page via history.back() or history.forward().
            console.warn('>>>>> window beforeunload EVENT <<<<<');
            callback();
        });
    } else {
        handleEvent($(document), 'turbolinks:click', callback);
        handleEvent($(window),   'beforeunload',     callback);
    }
}
