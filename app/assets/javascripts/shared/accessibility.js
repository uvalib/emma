// app/assets/javascripts/shared/accessibility.js


import { AppDebug }                    from '../application/debug';
import { attributeSelector, selector } from './css';
import { handleEvent }                 from './events';
import { keyCombo, modifiersOnly }     from './keyboard';
import { deepFreeze }                  from './objects';
import {
    isDefined,
    isPresent,
    notDefined,
    presence,
} from './definitions';
import {
    CHECKBOX,
    RADIO,
    sameElements,
    selfOrDescendents,
    single,
} from './html';


const MODULE = 'Accessibility';
const DEBUG  = true;

AppDebug.file('shared/accessibility', MODULE, DEBUG);

/**
 * Console output functions for this module.
 */
const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {object} TabOrderOptions
 *
 * @property {boolean}  [all]               Include non-focusable <p/>
 * @property {Selector} [root]              Stay within the root element <p/>
 * @property {boolean}  [siblings_only]     Stay at the same depth <p/>
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * Tags of elements that can receive focus.
 *
 * @readonly
 * @type {string[]}
 */
export const FOCUSABLE_ELEMENTS = deepFreeze([
    'a',
    'area',
    'button',
    'details',
    'input',
    'select',
    'textarea',
]);

/**
 * Selector for FOCUSABLE_ELEMENTS elements.
 *
 * @readonly
 * @type {string}
 */
export const FOCUSABLE_ELEMENT = FOCUSABLE_ELEMENTS.join(', ');

/**
 * Attributes indicating that an element should receive focus.
 *
 * @readonly
 * @type {string[]}
 */
export const FOCUSABLE_ATTRS = deepFreeze([
    'controls',
    'data-path',
    'draggable',
    'href',
    'role="cell"',
    'role="columnheader"',
    'role="grid"',
    'role="gridcell"',
    'role="listbox"',
    'role="rowheader"',
    'tabindex',
]);

/**
 * Selector for FOCUSABLE_ATTRS elements.
 *
 * @readonly
 * @type {string}
 */
export const FOCUSABLE_ATTRIBUTE = attributeSelector(FOCUSABLE_ATTRS);

/**
 * Selector for focusable elements.
 *
 * @readonly
 * @type {string}
 */
export const FOCUSABLE = FOCUSABLE_ELEMENT + ', ' + FOCUSABLE_ATTRIBUTE;

/**
 * Attributes indicating that an element should not be interactive.
 *
 * @readonly
 * @type {string[]}
 */
export const NO_TOUCH_ATTRS = deepFreeze(['disabled', 'inert']);

/**
 * Selector for elements that should not be interactive.
 *
 * @readonly
 * @type {string}
 */
export const NON_TOUCHABLE = attributeSelector(NO_TOUCH_ATTRS);

/**
 * Attributes indicating that an element should NOT receive focus.
 *
 * @readonly
 * @type {string[]}
 */
export const NO_FOCUS_ATTRS = deepFreeze(['tabindex="-1"', ...NO_TOUCH_ATTRS]);

/**
 * Selector for focusable elements that should not receive focus.
 *
 * @readonly
 * @type {string}
 */
export const NON_FOCUSABLE = attributeSelector(NO_FOCUS_ATTRS);

/**
 * Attribute added to elements by these functions to indicate whether an item
 * started out as being non-focusable.
 *
 * @type {string}
 */
export const ORIG_TABINDEX_ATTR = 'data-original-tabindex';

/**
 * Selector for elements that have been initialized via {@link setFocusable}.
 *
 * @readonly
 * @type {string}
 */
export const ORIG_TABINDEX = attributeSelector(ORIG_TABINDEX_ATTR);

/**
 * Selector matching potentially-focusable items that started out in a
 * non-focusable state.
 *
 * @type {string}
 */
export const ORIGINALLY_NONFOCUSABLE = `[${ORIG_TABINDEX_ATTR}="-1"]`;

export const INVISIBLE_MARKER = 'invisible';
export const INVISIBLE        = selector(INVISIBLE_MARKER);

// ============================================================================
// Functions - events
// ============================================================================

/**
 * Set event handlers so that the target responds to an activation key press in
 * the same way as a mouse click.
 *
 * @param {Selector}           element
 * @param {jQueryEventHandler} callback     Event handler.
 *
 * @returns {jQuery}
 */
export function handleClickAndKeypress(element, callback) {
    OUT.debug('handleClickAndKeypress:', element, callback);
    const $elem = ensureFocusable(element);
    return handleEvent($elem, 'click', callback).each(handleActivationAsClick);
}

/**
 * For "buttons" or "links" which are not `<a>` tags (or otherwise don't
 * respond by default to a carriage return as an equivalent to a click).
 *
 * @param {Selector}       selector  Specification of node(s) containing
 *                                     elements which must respond to a
 *                                     carriage return like a mouse click. <p/>
 *
 * @param {boolean}        [direct]  If **true** then the target is the nodes
 *                                     indicated by *selector* and not the
 *                                     descendents of those nodes. <p/>
 *
 * @param {string|boolean} [match]   If **false** then $(selector) specifies
 *                                     the target elements directly; if
 *                                     **true** or missing then all focusable
 *                                     elements at or below $(selector) are
 *                                     chosen; if a string then it is used
 *                                     instead of FOCUSABLE_ATTRIBUTE. <p/>
 *
 * @param {string|boolean} [except]  If **false** then all matches are chosen;
 *                                     otherwise elements matching
 *                                     FOCUSABLE_ELEMENT are eliminated.  In
 *                                     either case, NON_FOCUSABLE elements are
 *                                     skipped. Def.: elements like `<a>`. <p/>
 *
 * @returns {jQuery}
 */
function handleActivationAsClick(selector, direct, match, except) {
    //OUT.debug('handleActivationAsClick:', selector, direct, match, except);

    // noinspection JSCheckFunctionSignatures
    /**
     * Determine the target(s) based on the *direct* argument.
     *
     * @type {jQuery}
     */
    let $elements = (typeof selector === 'number') ? $(this) : $(selector);

    // Apply match criteria to select all elements that would be expected to
    // receive a key press based on their attributes.
    const criteria = [];
    if (match && (typeof match === 'string')) {
        criteria.push(match);
    } else if (direct || (match === true) || notDefined(match)) {
        criteria.push(FOCUSABLE_ATTRIBUTE);
    }
    if (isPresent(criteria)) {
        const sel = criteria.join(', ');
        $elements = direct ? $elements.filter(sel) : $elements.find(sel);
    }

    // Ignore elements that won't be reached by tabbing to them.
    const exceptions = [NON_FOCUSABLE];
    if (except && (typeof except === 'string')) {
        exceptions.push(except);
    }
    if (isPresent(exceptions)) {
        const sel = exceptions.join(', ');
        $elements = $elements.not(sel);
    }

    // Attach the handler to any remaining elements, ensuring that the
    // handler is not added twice.
    return handleEvent($elements, 'keydown', handleActivationKeypress);
}

/**
 * Translate a carriage return or space bar press to a click. <p/>
 *
 * Not intended for links (where the key press will be handled by the browser
 * itself).
 *
 * @param {KeyboardEvt} event
 *
 * @returns {EventHandlerReturn}
 */
function handleActivationKeypress(event) {
    const key = keyCombo(event);
    if (OUT.debugging() && key && !modifiersOnly(key)) {
        OUT.debug('handleActivationKeypress:', event);
    }
    if ((key === ' ') || (key === 'Enter')) {
        const $target = $(event.target);
        const href    = $target.attr('href');
        if (!href || (href === '#')) {
            $target.trigger('click');
            $target.trigger('focusin');
            return false;
        }
    }
}

// ============================================================================
// Functions - navigation
// ============================================================================

/**
 * The next element that will receive focus if tabbing forward.
 *
 * @param {Selector}        from
 * @param {TabOrderOptions} [opt]
 *
 * @returns {jQuery|undefined}
 */
export function nextInTabOrder(from, opt = {}) {
    let $found;
    const { all, root, siblings_only } = opt;
    const $from = $(from);
    $from.nextAll().each((_, sibling) => {
        const $sibling = $(sibling);
        const display  = $sibling.css('display');
        if (display === 'contents') {
            // This will not be ':visible' and it will not be focusable but it
            // may still have focusable descendent(s).
        } else if (display === 'none') {
            // Otherwise, this is not focusable and it does not have any
            // descendents that could be part of the tab order.
            return true; // continue loop
        } else if (isFocusable($sibling, all)) {
            $found = $sibling;
        }
        $found ||= presence(focusablesIn($sibling, all).first());
        return !$found; // break if found
    });
    if (!$found && !siblings_only) {
        const $parent = presence($from.parent());
        if ($parent && !sameElements($parent, root)) {
            $found = nextInTabOrder($parent, opt);
        }
    }
    return $found;
}

/**
 * The previous element that will receive focus if tabbing backward.
 *
 * @param {Selector}        from
 * @param {TabOrderOptions} [opt]
 *
 * @returns {jQuery|undefined}
 */
export function prevInTabOrder(from, opt = {}) {
    let $found;
    const { all, root, siblings_only } = opt;
    const $from = $(from);
    $from.prevAll().each((_, sibling) => {
        const $sibling = $(sibling);
        const display  = $sibling.css('display');
        if (display === 'contents') {
            // This will not be ':visible' and it will not be focusable but it
            // may still have focusable descendent(s).
        } else if (display === 'none') {
            // Otherwise, this is not focusable and it does not have any
            // descendents that could be part of the tab order.
            return true; // continue loop
        } else if (isFocusable($sibling, all)) {
            $found = $sibling;
        }
        $found ||= presence(focusablesIn($sibling, all).last());
        return !$found; // break if found
    });
    if (!$found && !siblings_only) {
        const $parent = presence($from.parent());
        if ($parent && !sameElements($parent, root)) {
            $found = prevInTabOrder($parent, opt);
        }
    }
    return $found;
}

// ============================================================================
// Functions - other
// ============================================================================

/**
 * Allow a click anywhere within the element holding a label/button pair
 * to be delegated to the enclosed input.  This broadens the "click target"
 * and allows clicks in the "void" between the input and the label to be
 * associated with the input element that the user intended to click.
 *
 * @param {Selector} element
 *
 * @returns {undefined}
 */
export function delegateInputClick(element) {

    const func     = 'delegateInputClick';
    const $element = $(element);
    const $input   = selfOrDescendents($element, `${CHECKBOX}, ${RADIO}`);
    const count    = $input.length;

    if (count < 1) {
        return OUT.error(`${func}: no targets within element`, element);
    } else if (count > 1) {
        OUT.warn(`${func}: ${count} targets`);
    }

    handleClickAndKeypress($element, function(event) {
        if (!sameElements($input, event.target)) {
            event.preventDefault();
            $input.trigger('click');
        }
    });
}

// ============================================================================
// Functions - focus
// ============================================================================

/**
 * Indicate whether any of the element(s) identified by *item* could have tab
 * focus.
 *
 * @param {Selector} item
 * @param {boolean}  [all]            Include potentially focusable elements.
 *
 * @returns {boolean}
 */
export function isFocusable(item, all) {
    //OUT.debug(`isFocusable: all = "${all}"; item =`, item);
    return !!item && isPresent(getFocusables(item, all));
}

/**
 * Indicate whether any of the element(s) identified by *item* have the
 * potential to receive tab focus.
 *
 * @param {Selector} item
 *
 * @returns {boolean}
 */
export function maybeFocusable(item) {
    return isFocusable(item, true);
}

/**
 * Indicate whether any of the element(s) identified by *item* currently can
 * receive tab focus.
 *
 * @param {Selector} item
 *
 * @returns {boolean}
 */
export function currentlyFocusable(item) {
    return isFocusable(item, false);
}

/**
 * The subset of element(s) identified by *item* that could have tab focus.
 *
 * @param {Selector} item
 * @param {boolean}  [all]            Include potentially focusable elements.
 *
 * @returns {jQuery}
 */
export function getFocusables(item, all) {
    //OUT.debug(`getFocusables: all = "${all}"; item =`, item);
    const $focusable = $(item).filter(FOCUSABLE).not(ORIGINALLY_NONFOCUSABLE);
    return all ? $focusable : $focusable.not(NON_FOCUSABLE);
}

/**
 * The subset of element(s) identified by *item* that have the potential to
 * receive tab focus.
 *
 * @param {Selector} item
 *
 * @returns {jQuery}
 */
export function getMaybeFocusables(item) {
    return getFocusables(item, true);
}

/**
 * The subset of element(s) identified by *item* that currently can receive
 * tab focus.
 *
 * @param {Selector} item
 *
 * @returns {jQuery}
 */
export function getCurrentFocusables(item) {
    return getFocusables(item, false);
}

/**
 * The subset of element(s) contained within *item* that could receive tab
 * focus.
 *
 * @param {Selector} item
 * @param {boolean}  [all]            Include potentially focusable elements.
 *
 * @returns {jQuery}
 */
export function focusablesIn(item, all) {
    //OUT.debug(`focusablesIn: all = "${all}"; item =`, item);
    const $focusable = $(item).find(FOCUSABLE).not(ORIGINALLY_NONFOCUSABLE);
    return all ? $focusable : $focusable.not(NON_FOCUSABLE);
}

/**
 * The subset of element(s) contained within *item* that have the potential to
 * receive tab focus.
 *
 * @param {Selector} item
 *
 * @returns {jQuery}
 */
export function maybeFocusablesIn(item) {
    return focusablesIn(item, true);
}

/**
 * The subset of element(s) contained within *item* that currently can receive
 * tab focus.
 *
 * @param {Selector} item
 *
 * @returns {jQuery}
 */
export function currentFocusablesIn(item) {
    return focusablesIn(item, false);
}

/**
 * Ensure that the indicated element(s) will be included in the tab order,
 * adding a *tabindex* attribute if necessary.
 *
 * @param {Selector} item
 *
 * @returns {jQuery}
 */
export function ensureFocusable(item) {
    const func = 'ensureFocusable'; //OUT.debug(`${func}:`, item);
    return $(item).each((_, element) => {
        const $element = $(element);
        if (!$element.is(FOCUSABLE_ELEMENT) && !$element.attr('tabindex')) {
            setFocusable($element, true, func);
        }
    });
}

// ============================================================================
// Functions - focusable elements
// ============================================================================

/**
 * Set *tabindex* for the single *element* is in the tab order.
 *
 * @param {Selector}              elem
 * @param {boolean|0|-1|"0"|"-1"} [value]   Default: **true**.
 * @param {string}                [caller]  For diagnostics.
 * @param {boolean}               [log]     No debug log entry if **false**.
 *
 * @returns {boolean}
 */
export function setFocusable(elem, value, caller, log) {
    const func      = 'setFocusable'; //OUT.debug(`${func}: ${value};`, elem);
    const tag       = caller ? `${caller}: ${func}` : func;
    const enable    = (value !== false) && (String(value) !== '-1');
    const $elem     = single(elem);
    const disabled  = $elem.is(`${NON_TOUCHABLE}, ${ORIGINALLY_NONFOCUSABLE}`);
    const focusable = enable && !disabled;
    if (enable && !focusable) {
        OUT.warn(`${tag}: disallowed for disabled element`, $elem);
    } else if (log !== false) {
        OUT.debug(`${tag}: "${focusable}" for element`, $elem);
    }
    if (!$elem.is(ORIG_TABINDEX)) {
        const orig = disabled && -1 || Number($elem.attr('tabindex')) || 0;
        $elem.attr(ORIG_TABINDEX_ATTR, orig);
    }
    $elem.attr('tabindex', (focusable ? 0 : -1));
    return focusable;
}

/**
 * Make all focusable elements within *element* non-focusable.
 *
 * - If *except* is a Selector, the matching element(s) are skipped.
 * - If *except* is **false**, all interior element(s) are skipped.
 *
 * @param {Selector}         element
 * @param {Selector|boolean} [except]
 * @param {number}           [depth]    Internal use.
 *
 * @returns {undefined}
 *
 * @see restoreFocusables
 */
export function neutralizeFocusables(element, except, depth = 0) {
    const func     = 'neutralizeFocusables';
    const bool_arg = (typeof except === 'boolean');
    const children = !bool_arg || except;
    const rejected = !bool_arg && except;
    const $element = element ? $(element) : undefined;
    const $here    = rejected ? $element?.not(rejected) : $element;

    if (!$element) { return OUT.warn(`${func}: blank element`, element) }
    //depth || OUT.debug(`${func}:`, $element, except, $here);

    getMaybeFocusables($here).each((_, el) => {
        setFocusable(el, false, func, false);
    });

    if (children) {
        const level = depth + 1;
        $element.children().each((_, ch) => {
            neutralizeFocusables(ch, except, level);
        });
    }
}

/**
 * Make all focusable elements within *element* non-focusable.
 *
 * - If *except* is a Selector, the matching element(s) are skipped.
 * - If *except* is **false**, all interior element(s) are skipped.
 *
 * @note Assumes elements were previously "neutralized".
 *
 * @param {Selector}         element
 * @param {Selector|boolean} [except]
 * @param {number}           [depth]    Internal use.
 *
 * @returns {undefined}
 *
 * @see neutralizeFocusables
 */
export function restoreFocusables(element, except, depth = 0) {
    const func     = 'restoreFocusables';
    const bool_arg = (typeof except === 'boolean');
    const children = !bool_arg || except;
    const rejected = !bool_arg && except;
    const $element = element && $(element);
    const $here    = rejected ? $element?.not(rejected) : $element;

    if (!$element) { return OUT.warn(`${func}: blank element`, element) }
    //depth || OUT.debug(`${func}:`, $element, except, $here);

    getMaybeFocusables($here).each((_, el) => {
        const $el     = $(el);
        const visible = ($el.attr('aria-hidden') !== 'true');
        setFocusable($el, visible, func, false);
    });

    if (children) {
        const level = depth + 1;
        $element.each((_, el) => {
            const $el = $(el);
            if ($el.attr('aria-hidden') !== 'true') {
                $el.children().each((_, ch) => {
                    restoreFocusables(ch, except, level);
                });
            }
        });
    }
}

// ============================================================================
// Functions - other
// ============================================================================

/**
 * Hide/show elements by adding/removing {@link INVISIBLE_MARKER}. <p/>
 *
 * If *setting* is not given then visibility is toggled to the opposite state.
 *
 * @note An "invisible" element still takes up space on the display; a "hidden"
 *  element does not.  Both cases result in 'aria-hidden' being set to make it
 *  unavailable to screen readers.
 *
 * @param {Selector} element
 * @param {boolean}  [setting]
 *
 * @returns {boolean} If **true** then *element* is becoming visible.
 *
 * @see toggleHidden
 */
export function toggleVisibility(element, setting) {
    //OUT.debug('toggleVisibility: setting =', setting, 'for', element);
    /** @type {jQuery} */
    const $element = $(element);
    let becoming_visible, now_hidden, visibility;
    if (isDefined(setting)) {
        becoming_visible = setting;
    } else if ((now_hidden = $element.attr('aria-hidden'))) {
        becoming_visible = (now_hidden === 'true');
    } else if ((visibility = $element.css('visibility'))) {
        becoming_visible = (visibility === 'hidden');
    } else {
        becoming_visible = isInvisible($element);
    }
    $element.toggleClass(INVISIBLE_MARKER, !becoming_visible);
    $element.attr('aria-hidden', !becoming_visible);
    return becoming_visible;
}

/**
 * Indicate whether an element has the {@link INVISIBLE_MARKER} class.
 *
 * @param target
 *
 * @returns {boolean}
 */
export function isInvisible(target) {
    return $(target).is(INVISIBLE);
}
