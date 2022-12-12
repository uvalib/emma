// app/assets/javascripts/shared/flash.js


import { arrayWrap }                       from './arrays'
import { selector }                        from './css'
import { isDefined, isMissing, isPresent } from './definitions'
import { noScroll, scrollIntoView }        from './html'
import { SECONDS }                         from './time'
import { HEAVY_X }                         from './unicode'
import {
    handleClickAndKeypress,
    handleEvent,
    isEvent,
    windowEvent,
} from './events'


// ============================================================================
// Constants
// ============================================================================

/**
 * If *false*, the flash container is inline.  If *true* it appears above the
 * main page content.
 *
 * @type {boolean}
 */
const FLOAT = true;

/**
 * Container element for flash messages.
 *
 * @readonly
 * @type {string}
 */
const CONTAINER_CLASS = 'flash-messages';
const INLINE_CLASS    = 'inline';
const FLOATING_CLASS  = 'floating';
const NO_RESET_CLASS  = 'no-reset';
const VISIBLE_MARKER  = 'visible';
const ITEM_CLASS      = 'flash';
const CLOSER_CLASS    = 'closer';

/**
 * Selector root for flash messages.
 *
 * @readonly
 * @type {Selector}
 */
const CONTAINER  = selector(CONTAINER_CLASS);
const INLINE     = selector(INLINE_CLASS);
const FLOATING   = selector(FLOATING_CLASS);
const NO_RESET   = selector(NO_RESET_CLASS);
const VISIBLE    = selector(VISIBLE_MARKER);
const FLASH_ITEM = selector(ITEM_CLASS);
const CLOSER     = selector(CLOSER_CLASS);

/**
 * Default display of flash messages by type.
 *
 * @type {{messages: boolean, errors: boolean}}
 */
const DEFAULT_SHOW = {
    messages: true,
    errors:   true,
};

// ============================================================================
// Variables
// ============================================================================

/**
 * Control display of flash messages by type.
 *
 * @type {object}
 */
const show_flash = DEFAULT_SHOW;

// ============================================================================
// Functions
// ============================================================================

/**
 * The flash message container.
 *
 * @param {Selector} [selector]       Default: {@link CONTAINER}.
 *
 * @returns {jQuery}
 */
export function flashContainer(selector) {
    if (selector instanceof jQuery) {
        return selector;
    } else if (typeof selector === 'string') {
        return $(selector);
    } else {
        return $(CONTAINER);
    }
}

/**
 * Initialize the flash message container.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @returns {boolean}                 *false* if only inline flash.
 *
 * @see file:app/views/layouts/_flash.html.erb
 */
export function flashInitialize(fc) {
    const $fc    = flashContainer(fc);
    const $items = $fc.find(FLASH_ITEM);
    let $first_closer;
    if (floating($fc)) {
        $items.each(function() {
            const $item = $(this);
            let $closer = $item.find(CLOSER);
            if (isMissing($closer)) {
                $closer = makeCloser();
                const $m = $('<div>').addClass('text').html($item.html());
                $item.empty().append($m, $closer);
            } else {
                initializeCloser($closer);
            }
            $first_closer ||= $closer;
            initializeFlashItem($item);
        });
        $fc.toggleClass(FLOATING_CLASS, true);
    }
    if (isPresent($items)) {
        $first_closer?.focus();
        showFlash($fc, true);
    }
    return !!$first_closer;
}

/**
 * Clear the flash message container on refreshed pages.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 */
export function flashReset(fc) {
    const $fc = flashContainer(fc);
    if (!flashEmpty($fc)) {
        if ($fc.is(NO_RESET)) {
            showFlash($fc);
        } else {
            clearFlash($fc);
        }
    }
    if (floating($fc)) {
        $fc.toggleClass(FLOATING_CLASS, true);
    }
}

/**
 * Prevent flash messages from being generated.
 *
 * @param {boolean} [all]
 *
 * @returns {void}
 */
export function suppressFlash(all) {
    switch (all) {
        case false: enableFlash(true);                                  break;
        case true:  show_flash.messages = show_flash.errors = false;    break;
        default:    show_flash.messages = false;                        break;
    }
}

/**
 * Restore generation of flash messages.
 *
 * @param {boolean} [all]
 *
 * @returns {void}
 */
export function enableFlash(all) {
    switch (all) {
        case false: suppressFlash(true);                                break;
        case true:  show_flash.messages = show_flash.errors = true;     break;
        default:    show_flash.messages = true;                         break;
    }
}

/**
 * Replace all flashes messages with a new one.
 *
 * If show_flash.messages is not *true* then no actions will be taken.
 *
 * @param {string|string[]} text
 * @param {string}          [type]
 * @param {string}          [role]
 * @param {Selector}        [fc]      Default: `{@link flashContainer}()`.
 *
 * @returns {jQuery}                  The flash container.
 */
export function flashMessage(text, type, role, fc) {
    const $fc = flashContainer(fc);
    if (show_flash.messages) {
        $fc.empty();
        addFlashMessage(text, type, role, $fc);
    }
    return $fc;
}

/**
 * Replace all flashes messages with a new flash error message.
 *
 * If show_flash.errors is not *true* then no actions will be taken.
 *
 * @param {string|string[]} text
 * @param {string}          [type]
 * @param {string}          [role]
 * @param {Selector}        [fc]      Default: `{@link flashContainer}()`.
 *
 * @returns {jQuery}                  The flash container.
 */
export function flashError(text, type, role, fc) {
    const $fc = flashContainer(fc);
    if (show_flash.errors) {
        $fc.empty();
        addFlashError(text, type, role, $fc);
    }
    return $fc;
}

/**
 * Remove all flash messages and hide the flash message container.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @returns {jQuery}                  The flash container.
 */
export function clearFlash(fc) {
    return hideFlash(fc).empty();
}

/**
 * Indicate whether no flash message(s) are present.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @returns {boolean}
 */
export function flashEmpty(fc) {
    const $fc    = flashContainer(fc);
    const $items = $fc.find(FLASH_ITEM);
    return isMissing($items);
}

/**
 * Indicate whether flashes are hidden.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @returns {boolean}
 */
export function flashHidden(fc) {
    return !flashContainer(fc).is(VISIBLE);
}

// ============================================================================
// Functions - internal
// ============================================================================

/**
 * Indicate whether the flash containing is a floating container.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @returns {boolean}
 */
function floating(fc) {
    const $fc = flashContainer(fc);
    return FLOAT && !$fc.is(INLINE) || $fc.is(FLOATING);
}

/**
 * Display flash message container.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 * @param {boolean}  [force]          Don't check {@link flashHidden}
 *
 * @returns {jQuery}                  The flash container.
 */
function showFlash(fc, force) {
    const $fc   = flashContainer(fc);
    const show  = force || flashHidden($fc);
    const float = floating($fc);
    if (show && float) {
        noScroll(() => toggleFlashContainer($fc, true));
        monitorWindowEvents(true);
    } else if (show) {
        toggleFlashContainer($fc, true);
    }
    if (!float) {
        scrollIntoView($fc);
    }
    return $fc;
}

/**
 * Hide flash message container.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 * @param {boolean}  [force]          Don't check {@link flashHidden}
 *
 * @returns {jQuery}                  The flash container.
 */
function hideFlash(fc, force) {
    const $fc = flashContainer(fc);
    if (force || !flashHidden($fc)) {
        if (floating($fc)) {
            monitorWindowEvents(false);
        }
        toggleFlashContainer($fc, false);
    }
    return $fc;
}

/**
 * Show/hide the flash container.
 *
 * (Only for use within {@link showFlash} and {@link hideFlash}.
 *
 * @param {jQuery}  $fc
 * @param {boolean} show
 *
 * @return {jQuery}
 */
function toggleFlashContainer($fc, show) {
    if (show) {
        $fc.removeAttr('aria-hidden');
    } else {
        $fc.attr('aria-hidden', true);
    }
    return $fc.toggleClass(VISIBLE_MARKER, show);
}

// ============================================================================
// Functions - flash items
// ============================================================================

/**
 * Display a new flash message.
 *
 * @param {string|string[]} text
 * @param {string}          [type]
 * @param {string}          [role]
 * @param {Selector}        [fc]      Default: `{@link flashContainer}()`.
 *
 * @returns {jQuery}                  The flash container.
 */
export function addFlashMessage(text, type, role, fc) {
    return addFlashItem(text, (type || 'notice'), role, fc);
}

/**
 * Display a new flash error message.
 *
 * @param {string|string[]} text
 * @param {string}          [type]
 * @param {string}          [role]
 * @param {Selector}        [fc]      Default: `{@link flashContainer}()`.
 *
 * @returns {jQuery}                  The flash container.
 */
export function addFlashError(text, type, role, fc) {
    return addFlashItem(text, (type || 'alert'), role, fc);
}

// ============================================================================
// Functions - flash items - internal
// ============================================================================

/**
 * Add a flash item, un-hiding the flash message container if needed.
 *
 * @param {string|string[]} text
 * @param {string}          [type]
 * @param {string}          [role]    Default: 'alert'.
 * @param {Selector}        [fc]      Default: `{@link flashContainer}()`.
 *
 * @returns {jQuery}                  The flash container.
 */
function addFlashItem(text, type, role, fc) {
    const css_class = `${ITEM_CLASS} ${type}`.trim();
    const aria_role = role || 'alert';
    const plain     = (typeof text === 'string') && !text.startsWith('<');
    const lines     = plain ? text.split(/<br\/?>|\n/) : arrayWrap(text);
    const message   = lines.map(v => v?.toString ? v?.toString() : '???');
    const $message  = $('<div>').html(message.join('<br/>'));

    let $item, $closer;
    const $fc = flashContainer(fc);
    if (floating($fc)) {
        $message.addClass('text');
        $closer = makeCloser();
        $item   = $('<div>').append($message, $closer);
    } else {
        $item   = $message;
    }
    initializeFlashItem($item).addClass(css_class).attr('role', aria_role);

    showFlash($fc).append($item);
    $closer?.focus();
    return $fc;
}

/**
 * Setup event handlers a flash item.
 *
 * @param {jQuery} $item
 *
 * @returns {jQuery}
 */
function initializeFlashItem($item) {
    handleEvent($item, 'keyup',     onKeyUpFlashItem);
    handleEvent($item, 'mousedown', onMouseDownFlashItem);
    return $item;
}

/**
 * Return the flash item associated with the argument.
 *
 * @param {jQuery.Event|Event|Selector} arg
 *
 * @returns {jQuery}
 */
function flashItem(arg) {
    const $elem = isEvent(arg) ? $(arg.currentTarget || arg.target) : $(arg);
    return $elem.is(FLASH_ITEM) ? $elem : $elem.parents(FLASH_ITEM).first();
}

/**
 * Callback invoked to remove a flash item from view.
 *
 * @param {jQuery.Event} event
 */
function closeFlashItem(event) {
    flashItem(event).remove();
    const $fc = flashContainer();
    if (flashEmpty($fc)) {
        hideFlash($fc, true);
    }
}

/**
 * Allow "Escape" key to close a specific flash item.
 *
 * @param {jQuery.Event|KeyboardEvent} event
 */
function onKeyUpFlashItem(event) {
    //console.log(`onKeyUpFlashItem: key = "${event.key}"; event =`, event);
    if (event.key === 'Escape') {
        console.log(`onKeyUpFlashItem: key = "${event.key}"; event =`, event);
        event.stopImmediatePropagation();
        closeFlashItem(event);
    }
}

/**
 * Allow mouse down inside a flash item to avoid closing any flash item by
 * preventing {@link onMouseDownWindow} from being invoked.
 *
 * @param {jQuery.Event|KeyboardEvent} event
 */
function onMouseDownFlashItem(event) {
    console.log('onMouseDownFlashItem: event =', event);
    event.stopPropagation();
}

// ============================================================================
// Functions - closer control - internal
// ============================================================================

/**
 * Generate a flash closer control.
 *
 * @returns {jQuery}
 */
function makeCloser() {
    const $closer = $('<button>').addClass('closer').text(HEAVY_X);
    return initializeCloser($closer);
}

/**
 * Setup event handlers for a flash closer control.
 *
 * @param {jQuery} $closer
 *
 * @returns {jQuery}
 */
function initializeCloser($closer) {
    handleClickAndKeypress($closer, closeFlashItem);
    return $closer;
}

// ============================================================================
// Functions - window events - internal
// ============================================================================

/**
 * Window events that could result in clearing all flash messages.
 *
 * @type {Object.<string,function(jQuery.Event)>}
 */
const WINDOW_EVENTS = {
    'keyup':     onKeyUpWindow,
    'mousedown': onMouseDownWindow,
};

/**
 * Begin monitoring for window events that could result in removing all flash
 * messages from the display.
 *
 * @param {boolean} [on]
 */
function monitorWindowEvents(on = true) {
    $.each(WINDOW_EVENTS,
        (type, callback) => windowEvent(type, callback, { listen: on })
    );
}

/**
 * Allow "Escape" key to close all flash items.
 *
 * @param {jQuery.Event|KeyboardEvent} event
 */
function onKeyUpWindow(event) {
    if (event.key === 'Escape') {
        event.stopImmediatePropagation();
        clearFlash();
    }
}

/**
 * Allow mouse down outside of a flash item to close all flash items.
 *
 * @param {jQuery.Event|MouseEvent} event
 */
function onMouseDownWindow(event) {
    clearFlash();
}

// ============================================================================
// Functions - server flash messages
// ============================================================================

/**
 * Get the message(s) to display which are passed back from the server via the
 * 'X-Flash-Message' header.
 *
 * @param {XMLHttpRequest} xhr
 *
 * @returns {array}
 *
 * @see "UploadController#post_response"
 */
export function extractFlashMessage(xhr) {
    const func = 'extractFlashMessage';
    let lines  = [];
    let text   = xhr && xhr.getResponseHeader('X-Flash-Message') || '';
    text = text.startsWith('http') ? fetchFlashMessage(text) : xhrDecode(text);
    if (text.startsWith('{') || text.startsWith('[')) {
        try {
            const messages = JSON.parse(text);
            if (Array.isArray(messages)) {
                messages.forEach(msg => lines.push(msg.toString()));
            } else if (typeof messages === 'object') {
                $.each(messages, (k, v) => lines.push(`${k}: ${v}`));
            } else {
                lines.push(messages.toString());
            }
            text = undefined; // Indicate that *lines* is valid.
        }
        catch (err) {
            console.warn(`${func}:`, err);
        }
    }
    return isDefined(text) ? text.split("\n") : lines;
}

/**
 * Decode a string used in HTTP message headers to transmit flash messages.
 *
 * @param {*} data
 *
 * @returns {string}
 *
 * @see "EncodingHelper#xhr_encode"
 */
export function xhrDecode(data) {
    if (isMissing(data)) { return '' }
    const string  = data.toString();
    const encoded = !!string.match(/%[0-9A-F][0-9A-F]/i);
    return (encoded ? decodeURIComponent(string) : string).trim();
}

/**
 * Synchronously fetch message content specified from a URL (specified via
 * 'X-Flash-Message').
 *
 * @param {string} url
 *
 * @returns {string}
 */
export function fetchFlashMessage(url) {
    const func = 'fetchFlash';
    let error  = 'could not fetch message'; // TODO: I18n
    let content;

    function onSuccess(data) {
        if (isMissing(data)) {
            error = 'no data for message'; // TODO: I18n
        } else if (typeof(data) !== 'string') {
            error = `unexpected data type ${typeof data}`; // TODO: I18n
        } else {
            content = data;
        }
    }

    function onError(xhr, status, message) {
        error = `${status}: ${xhr.status} ${message}`;
        console.warn(`${func}:`, error);
    }

    $.ajax({
        url:      url,
        type:     'GET',
        dataType: 'text',
        async:    false,
        timeout:  3 * SECONDS,
        success:  onSuccess,
        error:    onError
    });
    return content || `[[ ${error} ]]`;
}
