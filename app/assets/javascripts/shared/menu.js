// app/assets/javascripts/shared/menu.js
//
// Advanced menus with Select2.


import { AppDebug }                      from "../application/debug";
import { arrayWrap, maxSize }            from "./arrays";
import { Emma }                          from "./assets";
import { selector }                      from "./css";
import { isMissing, isPresent }          from "./definitions";
import { handleEvent }                   from "./events";
import { selfOrDescendents }             from "./html";
import { compact, deepFreeze, toObject } from "./objects";


const MODULE = "Menu";
const DEBUG  = true;

AppDebug.file("shared/menu", MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {object} MenuOptions
 *
 * @property {function|function[]} [on_change]
 * - Callback(s) to invoke when a menu selection has changed.
 *
 * @property {function|function[]|boolean} [immediate]
 * - Indicate that a menu performs an immediate change to a new page.
 * - If a function, that function is invoked for {@link PRE_CHANGE_EVENTS}.
 *
 * @property {string} [form_id]
 * - The element ID of the form associated with the menu control.
 *
 * @property {Select2Options} [options]
 * - Options to override those set in {@link initializeSelect2Menus}.
 *
 * <hr/>
 * Options for initializing menus.
 */

// ============================================================================
// Variables -- internal
// ============================================================================

/**
 * Console output functions for this module.
 */
const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

// ============================================================================
// Constants
// ============================================================================

/**
 * CSS class used to indicate that a menu should be handled by Select2 logic.
 *
 * @readonly
 * @type {string}
 */
const ADVANCED_MARKER = "advanced";

/**
 * CSS class for `<select>` elements managed by Select2.
 *
 * @readonly
 * @type {string}
 */
const SELECT2_ATTACHED_CLASS = "select2-hidden-accessible";

const MENU_CLASS        = "menu-control";
const SINGLE_CLASS      = "single";
const MULTIPLE_CLASS    = "multiple";

const ADVANCED          = selector(ADVANCED_MARKER);
const SELECT2_ATTACHED  = selector(SELECT2_ATTACHED_CLASS);
const MENU              = selector(MENU_CLASS);
const SINGLE            = selector(SINGLE_CLASS);
const MULTIPLE          = selector(MULTIPLE_CLASS);

/**
 * Events exposed by Select2 for menus.
 *
 * @readonly
 * @type {string[]}
 */
const SELECT2_EVENTS = deepFreeze([
    "change",
    "change.select2",
    "select2:clearing",
    "select2:clear",
    "select2:opening",
    "select2:open",
    "select2:selecting",
    "select2:select",
    "select2:unselecting",
    "select2:unselect",
    "select2:closing",
    "select2:close",
]);

/**
 * Select2 events which precede the change which causes a new search to be
 * performed.
 *
 * @readonly
 * @type {string[]}
 */
const PRE_CHANGE_EVENTS =
    deepFreeze(["select2:selecting", "select2:unselecting"]);

/**
 * Select2 events which follow a change which causes a new search to be
 * performed.
 *
 * @readonly
 * @type {string[]}
 */
const POST_CHANGE_EVENTS =
    deepFreeze(["select2:select", "select2:unselect"]);

// ============================================================================
// Functions
// ============================================================================

/**
 * The "data-*" attribute used to save the originally selected menu item(s).
 *
 * @type {string}
 */
export const DATA_ORIGINAL = "data-original";

/**
 * Return the originally selected menu item(s).
 *
 * @param {Selector} menu
 *
 * @returns {string|undefined}
 */
export function getOriginalMenuValue(menu) {
    return menuFor(menu).attr(DATA_ORIGINAL);
}

/**
 * Record the originally selected menu item(s).
 *
 * @param {Selector} menu
 * @param {*}        value
 *
 * @returns {string|undefined}
 */
export function setOriginalMenuValue(menu, value) {
    menuFor(menu).attr(DATA_ORIGINAL, (value || ""));
}

// ============================================================================
// Functions
// ============================================================================

/**
 * Initialize all menus.
 *
 * @param {Selector}    [root]        Default: `#main`.
 * @param {MenuOptions} [opt]
 */
export function initializeMenuControls(root, opt) {
    const $root    = $(root || '#main');
    const $entries = selfOrDescendents($root, MENU);
    initializeSingleSelect($entries, opt);
    initializeMultiSelect($entries, opt);
}

/**
 * Initialize single-select menus.
 *
 * @param {Selector}    entries
 * @param {MenuOptions} [opt]
 *
 * @returns {undefined}
 */
export function initializeSingleSelect(entries, opt) {
    const func = "initializeSingleSelect";
    const $all = menusIn(entries, SINGLE);
    if (isMissing($all)) { return OUT.debug(`${func}: no menus found`) }

    initializeGenericMenu($all, opt);

    // If there are no menus to be controlled by Select2 then return now.
    const $advanced = $all.filter((_, menu) => isAdvanced(menu));
    if (isMissing($advanced)) { return }

    // If all menus have already been initialized then return now.
    const $menus = $advanced.not(SELECT2_ATTACHED);
    if (isMissing($menus)) {
        return OUT.debug(`${func}: already initialized:`, $advanced);
    }

    // Initialize Select2 and attach event handlers.
    initializeSingleSelectMenus($menus, opt);
    if (OUT.debugging()) {
        eventHandlers($menus, SELECT2_EVENTS, logSelectEvent);
    }
    if (opt?.on_change) {
        eventHandlers($menus, "change", opt.on_change);
    }
    eventHandlers($menus, "select2:open", _event => {
        const $dropdown = $('.select2-container--open');
        const $input    = $dropdown.find('input.select2-search__field');
        const text      = "Search in list..."; // TODO: I18n
        $input.attr("placeholder", text);
        $input.attr("data-lpignore", true); // Needed for LastPass.
    });
}

/**
 * Initialize multi-select menus.
 *
 * @param {Selector}    entries
 * @param {MenuOptions} [opt]
 *
 * @returns {undefined}
 */
export function initializeMultiSelect(entries, opt) {
    const func = "initializeMultiSelect";
    const $all = menusIn(entries, MULTIPLE);
    if (isMissing($all)) { return OUT.debug(`${func}: no menus found`) }

    initializeGenericMenu($all, opt);

    // If there are no menus to be controlled by Select2 then return now.
    const $advanced = $all.filter((_, menu) => isAdvanced(menu));
    if (isMissing($advanced)) { return }

    // If all menus have already been initialized then return now.
    const $menus = $advanced.not(SELECT2_ATTACHED);
    if (isMissing($menus)) {
        return OUT.debug(`${func}: already initialized:`, $advanced);
    }

    // Initialize Select2 and attach event handlers.
    initializeMultiSelectMenus($menus, opt);
    if (OUT.debugging()) {
        eventHandlers($menus, SELECT2_EVENTS, logSelectEvent);
    }
    if (opt?.on_change) {
        eventHandlers($menus, POST_CHANGE_EVENTS, opt.on_change);
    }
    if (opt?.immediate) {
        const pre_change = (opt.immediate === true) ? [] : opt.immediate;
        initializeImmediate($menus, pre_change);
    }
}

// ============================================================================
// Functions -- menus
// ============================================================================

/**
 * General menu setup.
 *
 * @param {jQuery}              $menus
 * @param {MenuOptions}         [opt]
 */
function initializeGenericMenu($menus, opt) {
    const form_id   = opt?.form_id;
    const on_change = opt?.on_change;
    $menus.each((_, menu) => {
        const $menu = menuFor(menu);
        if ($menu.not(SELECT2_ATTACHED)) {
            if (form_id)   { $menu.attr("form", form_id) }
            if (on_change) { handleEvent($menu, "change", on_change) }
            setOriginalMenuValue($menu, $menu.val());
        }
    });
}

/**
 * Setup single-select menus managed by Select2.
 *
 * @param {jQuery}      $menus
 * @param {MenuOptions} [opt]
 */
function initializeSingleSelectMenus($menus, opt) {
    /** @type {Select2Options} */
    const opt_options = {
        allowClear:         false,
        dropdownCssClass:   SINGLE_CLASS,
        ...opt?.options
    };
    $menus.each((_, menu) => {
        let options = opt_options;
        const $menu = $(menu);

        // Special handling for form-based dropdown menus (i.e. those not
        // generated from LayoutHelper::SearchFilters#menu_control).
        if (!$menu.attr("data-unset")) {

            // Set an explicit width style to satisfy Select2 configuration
            // width settings "style" or (the default) "resolve" including
            // extra room for the arrow which Select2 adds.
            const width = $menu.outerWidth(false) + 20;
            $menu.css("width", width);

            // The text of initial `<option>` entries which do not represent ""
            // as a valid data selection need to be represented to Select2 as a
            // placeholder so that it doesn't appear as an actual menu choice.
            const $first = $menu.find('option').first();
            const text   = $first.text();
            if (!text.startsWith("(")) {
                options = { ...options, placeholder: text };
                $first.text("");
            }
        }

        initializeSelect2Menus($menu, options);
    });
}

/**
 * Setup multi-select menus managed by Select2.
 *
 * @param {jQuery}      $menus
 * @param {MenuOptions} [opt]
 */
function initializeMultiSelectMenus($menus, opt) {
    /** @type {Select2Options} */
    const opt_options = {
        allowClear:         true,
        dropdownCssClass:   MULTIPLE_CLASS,
        ...opt?.options
    };
    const aria_attrs     = ["aria-label", "aria-labelledby"];
    const to_be_labelled = "[aria-haspopup], [tabindex]";
    $menus.each((_, menu) => {
        let options = opt_options;
        const $menu = $(menu);

        // Adjust elements which Firefox Accessibility expects to be labelled.
        const attrs = compact(toObject(aria_attrs, a => $menu.attr(a)));
        if (isPresent(attrs)) {
            // noinspection JSCheckFunctionSignatures
            $menu.siblings().find(to_be_labelled).attr(attrs);
        }

        // Special handling for multi-select menus generated by
        // LayoutHelper::SearchFilters#menu_control.
        const text = $menu.attr("data-unset");
        if (text) {
            options = { ...options, placeholder: text };
        }

        initializeSelect2Menus($menu, options);
    });
}

/**
 * Setup one or more `<select>` elements managed by Select2.
 *
 * @param {jQuery}         $menus
 * @param {Select2Options} [opt]
 *
 * @see https://select2.org/configuration/options-api
 * @see https://select2.org/programmatic-control/events
 */
function initializeSelect2Menus($menus, opt) {
    /** @type {Select2Options} */
    const options = {
        width:                      "resolve",
        debug:                      OUT.debugging(),
        language:                   select2Language(),
        minimumResultsForSearch:    10,
        ...opt
    };
    // noinspection JSUnresolvedReference
    $menus.select2(options);
}

// ============================================================================
// Functions -- messages
// ============================================================================

/**
 * @type {Object.<string,function:string>}
 */
let select2_language;

/**
 * Message translations for Select2.
 *
 * @returns {Object.<string,function:string>}
 */
function select2Language() {
    return select2_language ||= generateSelect2Language();
}

/**
 * Generate message translations for Select2.
 *
 * @returns {Object.<string,function:string>}
 *
 * @see https://select2.org/i18n
 * @see file:node_modules/select2/src/js/select2/i18n/en.js
 */
function generateSelect2Language() {
    const text = {
      //errorLoading:    "The results could not be loaded.",
      //inputTooLong:    "Please delete {n} character",
      //inputTooShort:   "Please enter {n} or more characters",
      //loadingMore:     "Loading more results…",
      //maximumSelected: "You can only select {n} item",
      //noResults:       "No results found",
      //searching:       "Searching…",
        removeAllItems:  Emma.Terms.search_filters.remove_all,
    };
    const translations = {};
    for (const [name, value] of Object.entries(text)) {
        let fn;
        switch (name) {
            case "inputTooLong":
                fn = (args) => {
                    const overage = args.input.length - args.maximum;
                    const result  = value.replace(/{n}/, `${overage}`);
                    return (overage === 1) ? result : `${result}s`;
                };
                break;
            case "inputTooShort":
                fn = (args) => {
                    const remaining = args.minimum - args.input.length;
                    return value.replace(/{n}/, `${remaining}`);
                };
                break;
            case "maximumSelected":
                fn = (args) => {
                    const limit  = args.maximum;
                    const result = value.replace(/{n}/, limit);
                    return (limit === 1) ? result : `${result}s`;
                };
                break;
            default:
                fn = () => value;
                break;
        }
        translations[name] = fn;
    }
    return translations;
}

// ============================================================================
// Functions -- immediate
// ============================================================================

const IMMEDIATE_EVENT_PROP = "ongoing-event";

/**
 * Set up the given menus for immediate action leading to replacement of the
 * page based on the menu selection.
 *
 * @param {jQuery}              $menus
 * @param {function|function[]} [pre_change]
 */
function initializeImmediate($menus, pre_change) {
    if (isPresent(pre_change)) {
        eventHandlers($menus, PRE_CHANGE_EVENTS, pre_change);
    }
    eventHandlers($menus, POST_CHANGE_EVENTS, multiSelectPostChange);
    eventHandlers($menus, "select2:opening",  suppressMenuOpen);
}

/**
 * Cause the current event to be remembered for coordination with
 * {@link suppressMenuOpen}.
 *
 * @param {ElementEvt} event
 */
function multiSelectPostChange(event) {
    const $menu = $(event.currentTarget || event.target);
    $menu.prop(IMMEDIATE_EVENT_PROP, event.type);
}

/**
 * If in the midst of an ongoing event (adding or removing a selection)
 * then suppress the opening of the menu. <p/>
 *
 * This way, deselecting a menu selection performs its action without the
 * unnecessary opening-and-closing of the dropdown menu.
 *
 * @param {ElementEvt} event
 */
function suppressMenuOpen(event) {
    const $menu = $(event.currentTarget || event.target);
    if ($menu.prop(IMMEDIATE_EVENT_PROP)) {
        event.preventDefault();
        event.stopImmediatePropagation();
        $menu.removeProp(IMMEDIATE_EVENT_PROP).select2("close");
    }
}

// ============================================================================
// Functions -- other
// ============================================================================

/**
 * Indicate whether *elem* is a menu `<select>` element.
 *
 * @param {Selector} elem
 *
 * @returns {boolean}
 */
function isMenu(elem) {
    return $(elem).is('select');
}

/**
 * Return the menu `<select>` element associated with *elem*.
 *
 * @param {Selector} elem
 *
 * @returns {jQuery}
 */
function menuFor(elem) {
    const $elem = $(elem);
    return isMenu($elem) ? $elem : $elem.find('select');
}

/**
 * Indicate whether Select2 is intended to be attached to a menu.
 *
 * @param {Selector} menu
 *
 * @returns {boolean}
 */
function isAdvanced(menu) {
    const $elem = $(menu);
    if ($elem.is(ADVANCED)) {
        return true;
    } else if (isMenu($elem)) {
        return $elem.is(SELECT2_ATTACHED) || $elem.parent().is(ADVANCED);
    } else {
        const $menu = menuFor($elem);
        return $menu.is(SELECT2_ATTACHED) || $menu.is(ADVANCED);
    }
}

/**
 * Get all menus at or below the element(s) described by *base*, limited to
 * "single" or "multiple" if *type* is given.
 *
 * @param {Selector} base
 * @param {string}   [type]           Either SINGLE_CLASS or MULTIPLE_CLASS.
 *
 * @returns {jQuery}
 */
function menusIn(base, type) {
    const $entries   = selfOrDescendents(base, MENU);
    const $all_menus = selfOrDescendents($entries, 'select');
    if (type) {
        const $type = $entries.filter(type);
        const menus = selfOrDescendents($type, 'select').toArray();
        return $([...menus, ...$all_menus.filter(type).not(menus)]);
    } else {
        return $all_menus;
    }
}

/**
 * Set up handlers for Select2 event(s).
 *
 * @param {jQuery}              $menus
 * @param {string[]|string}     events
 * @param {function|function[]} callbacks
 */
function eventHandlers($menus, events, callbacks) {
    arrayWrap(events).forEach(type => handleEvent($menus, type, callbacks));
}

// ============================================================================
// Functions -- diagnostics
// ============================================================================

const SELECT2_EVENTS_WIDTH = maxSize(SELECT2_EVENTS);

/**
 * Log a Select2 event.
 *
 * @param {ElementEvt} event
 */
function logSelectEvent(event) {
    const type = `${event.type}`.padEnd(SELECT2_EVENTS_WIDTH);
    const menu = event.currentTarget || event.target;
    let target = "";
  //if (menu.localName) { target += menu.localName }
    if (menu.id)        { target += "#" + menu.id }
  //if (menu.className) { target += "." + menu.className }
  //if (menu.type)      { target += `[${menu.type}]` }
    // noinspection JSCheckFunctionSignatures
    const $selected = $(menu).siblings().find('[aria-activedescendant]');
    const selected  = $selected.attr("aria-activedescendant");
    if (selected) { target += " " + selected }
    OUT.debug("SELECT2", type, target);
}
