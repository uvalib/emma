// app/assets/javascripts/feature/flash.js

// ============================================================================
// Constants
// ============================================================================

/**
 * Container element for flash messages.
 *
 * @constant
 * @type {string}
 */
const FLASH_CONTAINER_CLASS = 'flash-messages';

/**
 * Selector root for flash messages.
 *
 * @constant
 * @type {Selector}
 */
const FLASH_ROOT_SELECTOR = selector(FLASH_CONTAINER_CLASS);

// ============================================================================
// Variables
// ============================================================================

// noinspection ES6ConvertVarToLetConst
/**
 * Control  display of flash messages by type.
 *
 * @type {object}
 */
var show_flash = {
    messages: true,
    errors:   true
};

// ============================================================================
// Functions
// ============================================================================

/**
 * The flash message container.
 *
 * @param {Selector} [selector]         Default: {@link FLASH_ROOT_SELECTOR}.
 *
 * @return {jQuery}
 */
function flashContainer(selector) {
    return $(selector || FLASH_ROOT_SELECTOR);
}

/**
 * Prevent flash messages from being generated.
 *
 * @param {boolean} [all]
 */
function suppressFlash(all) {
    // noinspection AssignmentResultUsedJS, NestedAssignmentJS
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
 */
function enableFlash(all) {
    // noinspection AssignmentResultUsedJS, NestedAssignmentJS
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
 * @param {string}   text
 * @param {string}   [type]
 * @param {string}   [role]
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 */
function flashMessage(text, type, role, fc) {
    if (show_flash.messages) {
        let $fc = clearFlash(fc);
        addFlashMessage(text, type, role, $fc);
    }
}

/**
 * Replace all flashes messages with a new flash error message.
 *
 * If show_flash.errors is not *true* then no actions will be taken.
 *
 * @param {string}   text
 * @param {string}   [type]
 * @param {string}   [role]
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 */
function flashError(text, type, role, fc) {
    if (show_flash.errors) {
        let $fc = clearFlash(fc);
        addFlashError(text, type, role, $fc);
    }
}

/**
 * Display flash message container.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @return {jQuery}
 */
function showFlash(fc) {
    return flashContainer(fc).removeClass('hidden').removeClass('invisible');
}

/**
 * Hide flash message container.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @return {jQuery}
 */
function hideFlash(fc) {
    return flashContainer(fc).addClass('hidden');
}

/**
 * Remove all flash messages and hide the flash message container.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @return {jQuery}
 */
function clearFlash(fc) {
    let $fc = hideFlash(fc);
    $fc.children().remove();
    return $fc;
}

/**
 * Indicate whether no flash message(s) are present.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @return {boolean}
 */
function flashEmpty(fc) {
    return flashContainer(fc).is(':empty');
}

/**
 * Indicate whether flashes are hidden.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @return {boolean}
 */
function flashHidden(fc) {
    let $fc = flashContainer(fc);
    return $fc.hasClass('hidden') || $fc.hasClass('invisible');
}

// noinspection JSUnusedGlobalSymbols
/**
 * Indicate whether flash message(s) are being displayed.
 *
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 *
 * @return {boolean}
 */
function flashDisplayed(fc) {
    let $fc = flashContainer(fc);
    return !flashHidden($fc) && !flashEmpty($fc);
}

/**
 * Add a flash message, un-hiding the flash message container if needed.
 *
 * @param {string}   text
 * @param {string}   [type]
 * @param {string}   [role]
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 */
function addFlashMessage(text, type, role, fc) {
    const css_class = type || 'notice';
    const aria_role = role || 'alert';
    const msg       = text ? text.replace("\n", '<br/>') : '???';
    let $msg = $('<p>').addClass(css_class).attr('role', aria_role).html(msg);
    showFlash(fc).append($msg);
}

/**
 * Add a flash error message, un-hiding the flash message container if needed.
 *
 * @param {string}   text
 * @param {string}   [type]
 * @param {string}   [role]
 * @param {Selector} [fc]             Default: `{@link flashContainer}()`.
 */
function addFlashError(text, type, role, fc) {
    const css_class = type || 'alert';
    const aria_role = role || 'alert';
    addFlashMessage(text, css_class, aria_role, fc);
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
 * @return {array}
 *
 * @see "UploadController#post_response"
 */
function extractFlashMessage(xhr) {
    const func = 'extractFlashMessage:';
    const data = xhr && xhr.getResponseHeader('X-Flash-Message');
    let lines  = [];
    if (data) {
        try {
            const messages = JSON.parse(data);
            if (Array.isArray(messages)) {
                messages.forEach(function(msg) {
                    lines.push(msg.toString());
                });
            } else if (typeof messages === 'object') {
                $.each(messages, function(k, v) {
                    lines.push(`${k}: ${v}`);
                });
            } else {
                lines.push(messages.toString());
            }
        }
        catch (err) {
            consoleWarn(func, err);
            lines.push(data.toString());
        }
    }
    return lines;
}
