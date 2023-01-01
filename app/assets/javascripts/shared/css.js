// app/assets/javascripts/shared/css.js


import { AppDebug }                      from '../application/debug';
import { arrayWrap }                     from './arrays';
import { Emma }                          from './assets';
import { isDefined, isEmpty, isPresent } from './definitions';
import { compact }                       from './objects';


AppDebug.file('shared/css');

// ============================================================================
// Constants
// ============================================================================

export const HIDDEN_MARKER = Emma.Popup.hidden.class;
export const HIDDEN        = selector(HIDDEN_MARKER);

// ============================================================================
// Functions
// ============================================================================

/**
 * Toggle the presence of a CSS class for one or more disjoint elements.
 *
 * @param {Selector|Selector[]} target
 * @param {string}              cls
 * @param {boolean}             [setting]
 */
export function toggleClass(target, cls, setting) {
    arrayWrap(target).forEach(element => $(element).toggleClass(cls, setting));
}

/**
 * Hide/show an element.
 *
 * @param {Selector} target
 * @param {boolean}  [hide]       Default: toggle state.
 *
 * @returns {jQuery}
 */
export function toggleHidden(target, hide) {
    const $target = $(target);
    $target.toggleClass(HIDDEN_MARKER, hide);
    $target.attr('aria-hidden', (isDefined(hide) ? hide : isHidden($target)));
    return $target;
}

/**
 * Indicate whether an element has the {@link HIDDEN_MARKER} class.
 *
 * @param target
 *
 * @returns {boolean}
 */
export function isHidden(target) {
    return $(target).is(HIDDEN);
}

// ============================================================================
// Functions
// ============================================================================

/**
 * Normalize singletons and/or arrays of CSS class names.
 *
 * @param {...string|Array} args
 *
 * @returns {string[]}
 */
export function cssClasses(...args) {
    const result = [];
    args.forEach(function(arg) {
        let values = undefined;
        if (typeof arg === 'string') {
            values = arg.trim().replace(/[.\s]+/g, ' ').split(' ');
        } else if (Array.isArray(arg)) {
            values = cssClasses(...arg);
        } else if (typeof arg === 'object') {
            values = cssClasses(arg['class']);
        }
        values = compact(values);
        if (isPresent(values)) {
            result.push(...values);
        }
    });
    return result;
}

/**
 * Join one or more CSS class names or arrays of class names with spaces.
 *
 * @param {...string|Array} args      Passed to {@link cssClasses}.
 *
 * @returns {string}
 */
export function cssClass(...args) {
    return cssClasses(...args).join(' ');
}

/**
 * Form a selector from one or more selectors or class names.
 *
 * @param {...string|Array} args      Passed to {@link cssClasses}.
 *
 * @returns {string}
 */
export function selector(...args) {
    const func   = 'selector';
    const result = [];
    args.forEach(function(arg) {
        let entry;
        if (isEmpty(arg)) {
            console.warn(`${func}: skipping empty ${typeof arg} = ${arg}`);

        } else if (Array.isArray(arg)) {
            entry = arg.map(v => v.trim().replace(/\s*,$/, ''));
            entry = entry.map(v => v.startsWith('.') ? v : `.${v}`);
            entry = entry.join(', ');

        } else if (typeof arg === 'object') {
            entry = selector(arg['class']);

        } else if (typeof arg !== 'string') {
            console.warn(`${func}: ignored ${typeof arg} = ${arg}`);

        } else if (arg === ',') {
            entry = ', ';

        } else if (arg.includes(',')) {
            entry = arg.trim().replace(/\s*,\s*/g, ',').split(',');
            entry = cssClasses(...entry);
            entry = entry.map(v => v.startsWith('.') ? v : `.${v}`);
            entry = entry.join(', ');

        } else if (arg.includes(' ')) {
            entry = arg.trim().replace(/\./g, ' ').split(/\s+/);
            entry = '.' + entry.join('.');

        } else if (arg[0] === '#') {    // ID selector
            result.unshift(arg);

        } else if (arg[0] === '[') {    // Attribute selector
            result.unshift(arg);

        } else if (arg[0] === '.') {    // CSS class selector
            entry = arg;

        } else {                        // CSS class
            entry = `.${arg}`;
        }
        entry = compact(entry);
        if (isPresent(entry)) {
            result.push(entry);
        }
    });
    return result.join('').trim();
}

/**
 * Return an identifying selector for an element -- based on the element ID if
 * it has one.
 *
 * @param {jQuery|HTMLElement} element
 *
 * @returns {string}
 */
export function elementSelector(element) {
    const e = $(element)[0];
    if (!e) {
        return '';
    } else if (e.id) {
        return `#${e.id}`;
    } else if (e.className) {
        return e.localName + '.' + e.className.replace(/\s+/g, '.');
    } else {
        return e.localName;
    }
}
