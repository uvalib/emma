// app/assets/javascripts/shared/css.js


import { AppDebug }                      from "../application/debug";
import { arrayWrap }                     from "./arrays";
import { Emma }                          from "./assets";
import { isDefined, isEmpty, isPresent } from "./definitions";
import { isObject }                      from "./objects";


AppDebug.file("shared/css");

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
 * @note A *hidden* element is effectively removed from the display; an
 *  *invisible* element still takes up space on the display.  Both cases result
 *  in `aria-hidden` being set to make it unavailable to screen readers.
 *
 * @param {Selector} target
 * @param {boolean}  [hide]       Default: toggle state.
 *
 * @returns {jQuery}
 *
 * @see toggleVisibility
 */
export function toggleHidden(target, hide) {
    /** @type {jQuery} */
    const $target = $(target);
    $target.toggleClass(HIDDEN_MARKER, hide);
    if (isDefined(hide) ? hide : isHidden($target)) {
        $target.attr("aria-hidden", true);
    } else {
        $target.removeAttr("aria-hidden");
    }
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
    // noinspection FunctionWithInconsistentReturnsJS
    return args.map(arg => {
        if (typeof arg === "string") {
            const vals = arg.replace(/[.\s]+/g, " ").replace(/[#[]/g, " $&");
            return vals.trim().split(/\s*,\s*|\s+/);
        } else if (arg instanceof Element) {
            return [...arg.classList];
        } else if (arg instanceof jQuery) {
            return cssClasses(...arg.get());
        } else if (Array.isArray(arg)) {
            return cssClasses(...arg);
        } else if (isObject(arg)) {
            return arg["class"] && cssClasses(arg["class"]);
        }
    }).flat().filter(v => isPresent(v));
}

/**
 * Join one or more CSS class names or arrays of class names with spaces.
 *
 * @param {...string|Array} args      Passed to {@link cssClasses}.
 *
 * @returns {string}
 */
export function cssClassList(...args) {
    return cssClasses(...args).join(" ");
}

/**
 * Form a selector from one or more selectors or class names.
 *
 * @param {...string|Array} args      Passed to {@link cssClasses}.
 *
 * @returns {string}
 */
export function selector(...args) {
    const func   = "selector";
    const result = [];
    args.forEach(arg => {
        let insert, append;
        if (isEmpty(arg)) {
            //console.warn(`${func}: skipping empty ${typeof arg} = ${arg}`);

        } else if (Array.isArray(arg)) {
            append = arg.map(v => selector(v)).join(", ");

        } else if (typeof arg === "object") {
            append = arg["class"] && selector(arg["class"]);

        } else if (typeof arg !== "string") {
            console.warn(`${func}: ignored ${typeof arg} = ${arg}`);

        } else if (arg === ",") {
            append = ", ";

        } else if (arg.includes(",")) {
            append = cssClasses(arg).map(v => selector(v)).join(", ");

        } else if (arg.includes(" ")) {
            append = cssClasses(arg).map(v => selector(v)).join("");

        } else if (arg[0] === "#") {    // ID selector
            insert = arg;

        } else if (arg[0] === "[") {    // Attribute selector
            insert = arg;

        } else if (arg[0] === ".") {    // CSS class selector
            append = arg;

        } else {                        // CSS class
            append = `.${arg}`;
        }
        insert && result.unshift(insert);
        append && result.push(append);
    });
    return result.join("").trim().replace(/\s*,$/, "");
}

/**
 * Make a selector out of an array of attributes.
 *
 * @param {string|string[]|[string,string][]|Object.<string,string>} attributes
 *
 * @returns {string}
 */
export function attributeSelector(attributes) {
    if (isEmpty(attributes)) { return "" }

    let attr = attributes;
    if (typeof attr === "string") {
        attr = attr.split(",");
    } else if (isObject(attr)) {
        attr = Object.entries(attr);
    } else if (!Array.isArray(attr)) {
        attr = arrayWrap(attr);
    } else if (!Array.isArray(attr[0])) {
        attr = attr.join(",").split(",");
    }

    if (Array.isArray(attr[0])) {
        attr = attr.map(([k,v]) => [k, (v ? `${v}`.trim() : "")]);
        attr = attr.map(([k,v]) => `[${k}="${v}"]`);
    } else {
        attr = attr.map(v => v && `${v}`.trim()).filter(v => v);
        attr = attr.map(v => v.match(/^\[.*]$/) ? v : `[${v}]`);
    }
    return attr.join(", ");
}

/**
 * Return an identifying selector for an element -- based on the element ID if
 * it has one.
 *
 * @param {jQuery|HTMLElement} element
 *
 * @returns {string}
 */
export function elementName(element) {
    const e = $(element)[0];
    if (!e)   { return "" }
    if (e.id) { return `#${e.id}` }
    const [name, css] = [e.localName, e.className];
    return css ? [name, ...css.split(/\s+/)].join(".") : name;
}

/**
 * Get a list of all the CSS for the element and its descendents.
 *
 * @param {Selector}      root
 * @param {string|RegExp} [filter]    Limit results to matching names.
 *
 * @returns {string[]}
 */
export function classesWithin(root, filter) {
    const array = [];
    const $root = $(root);
    [...$root, ...$root.find('*')].forEach(element => {
        let names = Array.from(element.classList);
        if (filter) { names = names.filter(name => name.match(filter)) }
        array.push(...names);
    });
    return [...new Set(array)].sort();
}
