// app/assets/javascripts/shared/html.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }                       from '../application/debug';
import { cssClassList }                   from './css';
import { isDefined, isPresent, presence } from './definitions';
import { isObject }                       from './objects';
import { hexRand }                        from './random';


AppDebug.file('shared/html');

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {Window.jQuery} jQuery
 */

/**
 * @typedef {jQuery|HTMLElement|EventTarget|string} Selector
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * When replacing newlines with HTML breaks, it's important to retain the
 * newline itself so that `.text().split("\n")` can be used to reconstitute
 * arrays of values.
 *
 * @readonly
 * @type {string}
 */
export const HTML_BREAK = "<br/>\n";

/**
 * Conversion of character to HTML entity.
 *
 * @readonly
 * @type {StringTable}
 */
export const HTML_ENTITY = {
    "'": '&apos;',
    '"': '&quot;',
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
};

export const CHECKBOX = '[type="checkbox"]';
export const RADIO    = '[type="radio"]';

// ============================================================================
// Functions
// ============================================================================

/**
 * Transform a string into one that can be used wherever HTML is expected.
 *
 * @param {*} arg
 *
 * @returns {string}
 */
export function htmlEncode(arg) {
    const txt = arg?.toString()?.trim() || '';
    const str = txt.includes('&') ? htmlDecode(txt) : txt;
    return str ? [...str].map(c => HTML_ENTITY[c] || c).join('') : '';
}

/**
 * Safely transform HTML-encoded text.
 *
 * @param {*} arg
 *
 * @returns {string}
 */
export function htmlDecode(arg) {
    const str = arg?.toString()?.trim() || '';
    const doc = str && new DOMParser().parseFromString(str, 'text/html');
    return doc?.documentElement?.textContent || '';
}

// ============================================================================
// Functions
// ============================================================================

/**
 * Return all elements and descendents which match.
 *
 * @param {Selector} target
 * @param {Selector} match
 *
 * @returns {jQuery}
 */
export function allMatching(target, match) {
    //console.log(`allMatching: match = "${match}"; target =`, target);
    const $target = $(target);
    return $target.filter(match).add($target.find(match));
}

/**
 * Return a flattened traversal of the item(s) and all of their descendents
 * excluding elements in subtrees matching the given criterion.
 *
 * @param {Selector} target
 * @param {Selector} [prune]
 *
 * @returns {jQuery}
 */
export function selfAndDescendents(target, prune) {
    const result = [];
    const $items = isPresent(prune) ? $(target).not(prune) : $(target);
    $items.each((_, item) => {
        result.push(item);
        $(item).children().each((_, child) => {
            result.push(...selfAndDescendents(child, prune));
        });
    });
    return $(result);
}

/**
 * Return the target if it matches or all descendents that match.
 *
 * @param {Selector} target
 * @param {Selector} match
 *
 * @returns {jQuery}
 */
export function selfOrDescendents(target, match) {
    //console.log(`selfOrDescendents: match = "${match}";`, target, prune);
    const $target = $(target);
    return presence($target.filter(match)) || $target.find(match);
}

/**
 * Return the target if it matches or the first parent that matches.
 *
 * @param {Selector}     target
 * @param {Selector}     match
 * @param {string|false} [caller]     Name of caller (for diagnostics).
 *
 * @returns {jQuery}
 */
export function selfOrParent(target, match, caller) {
    //console.log(`selfOrParent: match = "${match}"; target =`, target);
    const func = (caller !== false) && (caller || 'selfOrParent');
    const $t   = $(target);
    return $t.is(match) ? single($t, func) : $t.parents(match).first();
}

/**
 * Ensure that the target resolves to exactly one element.
 *
 * @param {Selector}     target
 * @param {string|false} [caller]     Name of caller (for diagnostics).
 *
 * @returns {jQuery}
 */
export function single(target, caller) {
    const $elem = $(target);
    const count = $elem?.length || 0;
    if (count === 1) { return $elem }
    if (caller !== false) {
        const func = caller || 'single';
        console.warn(`${func}: ${count} results; 1 expected`);
    }
    return $elem.first();
}

/**
 * Indicate whether *a* specifies the same DOM element(s) as *b*.
 *
 * @param {Selector|null|undefined} a
 * @param {Selector|null|undefined} b
 *
 * @returns {boolean}
 */
export function sameElements(a, b) {
    const [$a, $b] = [$(a), $(b)];
    const [la, lb] = [$a?.length, $b?.length];
    switch (true) {
        case (!la && !lb):  return true;
        case (la !== lb):   return false;
        case (la === 0):    return true;
        case (la === 1):    return $a[0] === $b[0];
        default:            return $a.toArray().every(elem => $b.is(elem));
    }
}

/**
 * Indicate whether any descendent of *target* matches.
 *
 * @param {Selector|null|undefined} target
 * @param {Selector|null|undefined} match
 *
 * @returns {boolean}
 */
export function contains(target, match) {
    return !!target && !!match && isPresent($(target).has(match));
}

/**
 * Indicate whether any ancestor of *target* matches.
 *
 * @param {Selector|null|undefined} target
 * @param {Selector|null|undefined} match
 *
 * @returns {boolean}
 */
export function containedBy(target, match) {
    return !!target && !!match && isPresent($(target).parents(match));
}

// ============================================================================
// Functions
// ============================================================================

/**
 * If necessary scroll the indicated element so that it is within the viewport.
 *
 * @param {Selector} element
 *
 * @returns {jQuery}
 */
export function scrollIntoView(element) {
    const $element = $(element);
    const elem     = $element[0];
    if (elem) {
        const r = elem.getBoundingClientRect();
        const t = 0;
        const b = window.innerHeight || document.documentElement.clientHeight;
        if (r.top < t) {
            elem.scrollIntoView(true);
        } else if (r.bottom > b) {
            elem.scrollIntoView(false);
        }
    } else {
        console.error('scrollIntoView: empty element:', element);
    }
    return $element;
}

/**
 * For use in situations where actions cause an undesirable scroll.
 *
 * NOTE: This was discovered implementing the floating flash container. Firefox
 *  and MS Edge show it in the middle of the viewport as intended, but Chrome
 *  shifts to the top of the page first.  This locking strategy keeps it from
 *  doing that (whereas simply setting window.scroll() afterwards results in a
 *  "flashing" effect that is more severe as scrollY increases).
 *
 * @param {function} callback
 */
export function noScroll(callback) {
    const [current_x, current_y] = [window.scrollX, window.scrollY];
    const scroll_lock = () => window.scroll(current_x, current_y);
    window.addEventListener('scroll', scroll_lock);
    callback();
    setTimeout(() => window.removeEventListener('scroll', scroll_lock));
}

/**
 * For a flex container with "row-reverse" or "column-reverse", in order to
 * ensure that tab order advances with the displayed order of the children,
 * reverse the physical order of the children and remove the "-reverse" from
 * the container's *flex-direction*.
 *
 * @param {Selector} container
 *
 * @returns {jQuery}
 */
export function unreverseFlexChildren(container) {
    const $container = $(container);
    const direction  = $container.css('flex-direction') || '';
    if (direction.endsWith('-reverse')) {
        const wrap      = $container.css('flex-wrap') || '';
        const $children = $container.children();
        const reversed  = $children.toArray().reverse();
        $children.detach();
        if (wrap.endsWith('-reverse')) {
            $container.attr('data-original-flex-wrap', wrap);
            $container.css('flex-wrap', wrap.replace('-reverse', ''));
        }
        $container.attr('data-original-flex-direction', direction);
        $container.css('flex-direction', direction.replace('-reverse', ''));
        $container.append(reversed);
    }
    return $container;
}

/**
 * Create an HTML element.
 *
 * @param {string|ElementProperties} element
 * @param {ElementProperties}        [properties]
 *
 * @returns {jQuery}
 */
export function create(element, properties) {
    const obj  = isObject(element);
    const prop = (obj ? element     : properties) || {};
    const tag  = (obj ? element.tag : element)    || 'div';

    // noinspection HtmlUnknownTag
    const $element = (tag[0] === '<') ? $(tag) : $(`<${tag}>`);
    prop.class   && $element.addClass(cssClassList(prop.class));
    prop.type    && $element.attr('type',  prop.type);
    prop.tooltip && $element.attr('title', prop.tooltip);

    if      (typeof prop.html  === 'string') { $element.html(prop.html)  }
    else if (typeof prop.label === 'string') { $element.text(prop.label) }
    else if (typeof prop.text  === 'string') { $element.text(prop.text)  }
    return $element;
}

// ============================================================================
// Functions - attributes
// ============================================================================

/**
 * HTML attributes which should be made unique.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input [input]
 * @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/label [label]
 * @see https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes#relationship_attributes [aria]
 *
 * @type {string[]}
 */
export const ID_ATTRIBUTES = [
    'aria-activedescendant',
    'aria-controls',
    'aria-describedby',
    'aria-details',
    'aria-errormessage',
    'aria-flowto',
    'aria-labelledby',
    'aria-owns',
    'for',                      // @see [label]#attr-for
    'form',                     // @see [input]#form
    'id',                       // @see [input]#id
    'list',                     // @see [input]#list
  //'name',                     // NOTE: Must *not* be included.
];

/**
 * Make attributes unique within an element and all of its descendents.
 *
 * @param {Selector}      root
 * @param {string|number} [unique]
 * @param {string[]}      [attributes]  Default: {@link ID_ATTRIBUTES}
 * @param {boolean}       [append_only]
 *
 * @returns {jQuery}                    The element (for chaining).
 */
export function uniqAttrsTree(root, unique, attributes, append_only) {
    const $root = $(root);
    const uniq  = unique || hexRand();
    const attr  = attributes;
    const app   = append_only;
    $root.find('*').each((_, elem) => uniqAttrs(elem, uniq, attr, app));
    return uniqAttrs($root, uniq, attr, app);
}

/**
 * Make attributes unique within an element.
 *
 * @param {Selector}      element
 * @param {string|number} unique
 * @param {string[]}      [attributes]  Default: {@link ID_ATTRIBUTES}
 * @param {boolean}       [append_only]
 *
 * @returns {jQuery}                    The element (for chaining).
 */
export function uniqAttrs(element, unique, attributes, append_only) {
    const $element = $(element);
    const attrs    = attributes || ID_ATTRIBUTES;
    attrs.forEach(name => {
        const old_attr = $element.attr(name);
        if (isDefined(old_attr)) {
            const new_attr = uniqAttr(old_attr, unique, append_only);
            $element.attr(name, new_attr);
        }
    });
    return $element;
}

/**
 * Make an attribute value unique.
 *
 * @param {string}        value
 * @param {string|number} unique
 * @param {boolean}       [append_only]
 *
 * @returns {string}
 */
export function uniqAttr(value, unique, append_only) {
    if (!append_only && (/-0$/.test(value) || /-\d+-\d+$/.test(value))) {
        return value.replace(/-\d+$/, `-${unique}`);
    } else {
        return `${value}-${unique}`;
    }
}
