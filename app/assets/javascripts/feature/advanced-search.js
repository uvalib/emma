// app/assets/javascripts/feature/advanced-search.js


import { AppDebug }                       from "../application/debug";
import { appSetup }                       from "../application/setup";
import { arrayWrap }                      from "../shared/arrays";
import { Emma }                           from "../shared/assets";
import { debounce, handleEvent, isEvent } from "../shared/events";
import { turnOffAutocomplete }            from "../shared/form";
import { compact, deepFreeze }            from "../shared/objects";
import { randomizeName }                  from "../shared/random";
import { urlParameters }                  from "../shared/url";
import {
    toggleVisibility,
    handleClickAndKeypress,
} from "../shared/accessibility";
import {
    HIDDEN,
    isHidden,
    selector,
    toggleHidden,
} from "../shared/css";
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
} from "../shared/definitions";
import {
    DATA_ORIGINAL,
    getOriginalMenuValue,
    initializeMenuControls,
    setOriginalMenuValue,
} from "../shared/menu";


const MODULE = "AdvancedSearch";
const DEBUG  = true;

AppDebug.file("feature/advanced-search", MODULE, DEBUG);

// noinspection FunctionTooLongJS
appSetup(MODULE, function() {

    /**
     * All search sections.
     *
     * @type {jQuery}
     */
    const $search_sections = $('.layout-section.search');

    // Only perform these actions on the appropriate pages.
    if (isMissing($search_sections)) { return }

    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

    // ========================================================================
    // Constants
    // ========================================================================

    const IMMEDIATE_MARKER          = "immediate-search-marker";
    const SEARCH_BAR_CLASS          = "search-bar-container";
    const SEARCH_BAR_ROW_CLASS      = "search-bar-row";
    const SEARCH_BUTTON_CLASS       = "search-button";
    const SEARCH_CLEAR_CLASS        = "search-clear";
    const SEARCH_CONTROLS_CLASS     = "search-controls";
    const SEARCH_FILTER_CLASS       = "menu-control";
    const SEARCH_FILTERS_CLASS      = "search-filter-container";
    const SEARCH_INPUT_CLASS        = "search-input";
    const SEARCH_TOGGLE_CLASS       = "advanced-search-toggle";
    const SEARCH_TYPE_LABEL_CLASS   = "search-input-label";
    const SEARCH_TYPE_MENU_CLASS    = "search-input-select";

    const IMMEDIATE                 = selector(IMMEDIATE_MARKER);
    const SEARCH_BAR                = selector(SEARCH_BAR_CLASS);
    const SEARCH_BAR_ROW            = selector(SEARCH_BAR_ROW_CLASS);
    const SEARCH_BUTTON             = selector(SEARCH_BUTTON_CLASS);
    const SEARCH_CLEAR              = selector(SEARCH_CLEAR_CLASS);
    const SEARCH_CONTROLS           = selector(SEARCH_CONTROLS_CLASS);
    const SEARCH_FILTER             = selector(SEARCH_FILTER_CLASS);
    const SEARCH_FILTERS            = selector(SEARCH_FILTERS_CLASS);
    const SEARCH_INPUT              = selector(SEARCH_INPUT_CLASS);
    const SEARCH_TOGGLE             = selector(SEARCH_TOGGLE_CLASS);
    const SEARCH_TYPE_LABEL         = selector(SEARCH_TYPE_LABEL_CLASS);
    const SEARCH_TYPE_MENU          = selector(SEARCH_TYPE_MENU_CLASS);

    /**
     * State value indicating the search filter panel is open (expanded).
     *
     * @readonly
     * @type {string}
     */
    const OPEN = "open";

    /**
     * State value indicating the search filter panel is closed (contracted).
     *
     * @readonly
     * @type {string}
     */
    const CLOSED = "closed";

    /**
     * Marker class indicating the search filter panel is open (expanded).
     *
     * @readonly
     * @type {string}
     */
    const OPEN_MARKER = "open";

    /**
     * The search target controller embedded in the HTML.
     *
     * @readonly
     * @type {string}
     */
    const SEARCH_TARGET = $search_sections.attr("data-target") || "search";

    /**
     * Search types and their display properties.
     *
     * @readonly
     * @type {object}
     */
    const SEARCH_TYPE = Emma.Search.type[SEARCH_TARGET] || [];

    /**
     * Search types.
     *
     * @readonly
     * @type {string[]}
     */
    const SEARCH_TYPES = deepFreeze(Object.keys(SEARCH_TYPE));

    /**
     * How long to wait after the user enters characters into a search input
     * box before re-checking search readiness.
     *
     * @readonly
     * @type {number}
     *
     * @see monitorSearchFields
     */
    const DEBOUNCE_DELAY = 1000; // milliseconds

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * The advanced-search toggle button.
     *
     * @type {jQuery}
     */
    const $advanced_toggle = $search_sections.find(SEARCH_TOGGLE);

    /**
     * All instances of the search filter reset button.
     *
     * @type {jQuery}
     */
    const $reset_button = $search_sections.find('.menu-button.reset');

    /**
     * The element with the search bar and related controls.
     *
     * @type {jQuery}
     */
    const $search_bar_container = $search_sections.find(SEARCH_BAR);

    /**
     * One or more rows containing a search bar and, optionally, a search input
     * select menu and search row controls.
     *
     * @type {jQuery}
     */
    const $search_bar_rows = $search_bar_container.find(SEARCH_BAR_ROW);

    /**
     * The menu(s) which change the type for their associated search input.
     *
     * @type {jQuery}
     */
    const $search_input_select = $search_bar_rows.find(SEARCH_TYPE_MENU);

    /**
     * The search term input boxes.
     *
     * @type {jQuery}
     */
    const $search_input = $search_bar_rows.find(SEARCH_INPUT);

    /**
     * The search term input clear buttons.
     *
     * @type {jQuery}
     */
    const $search_clear = $search_bar_rows.find(SEARCH_CLEAR);

    /**
     * Buttons to reveal the next search term input row.
     *
     * @type {jQuery}
     */
    const $row_show_buttons =
        $search_bar_container.find('.search-row-control.add');

    /**
     * Buttons to hide the current search term input row (and remove it from
     * the search request).
     *
     * @type {jQuery}
     */
    const $row_hide_buttons =
        $search_bar_container.find('.search-row-control.remove');

    /**
     * The button that performs the search.
     *
     * @type {jQuery}
     */
    const $search_button = $search_sections.find(SEARCH_BUTTON);

    /**
     * The search filters container.
     *
     * @type {jQuery}
     */
    const $filter_controls = $search_sections.find(SEARCH_FILTERS);

    /**
     * The search filter controls (menu containers).
     *
     * @type {jQuery}
     */
    const $search_filters = $filter_controls.find(SEARCH_FILTER);

    /**
     * Indicate whether search filters take immediate effect (causing a new
     * search using the selected value).
     *
     * @readonly
     * @type {boolean}
     */
    const IMMEDIATE_SEARCH = isPresent($filter_controls.siblings(IMMEDIATE));

    // ========================================================================
    // Functions - initialization
    // ========================================================================

    /**
     * Set the current state of advanced search inputs and controls.
     */
    function initializeAdvancedSearch() {
        if (isMissing($filter_controls)) {
            toggleHidden($advanced_toggle, true);
            toggleHidden($reset_button,    true);
        } else {
            guaranteeSearchButton();
            reorderSearchControls();

            // If there is only one row of filter buttons, take away the
            // toggle and make sure that the panel is open (regardless of the
            // persisted state).
            let was_open;
            if (isMissing($search_filters.filter('.row-2'))) {
                $advanced_toggle.toggleClass("visible", false);
                toggleHidden($advanced_toggle, true);
                was_open = true;
            } else {
                was_open = getFilterPanelState();
            }

            // Put the filter panel in the last state set by the user (unless
            // in this case it's required to be open no matter what).
            const is_open = isExpandedFilterPanel() ? OPEN : CLOSED;
            if (was_open !== is_open) {
                if (was_open === OPEN) {
                    setFilterPanelDisplay(true);
                } else if (was_open === CLOSED) {
                    setFilterPanelDisplay(false);
                } else {
                    setFilterPanelState(is_open);
                }
            }
        }

        const url_params = urlParameters();
        initializeSearchTerms(url_params);
        initializeSearchFilters(url_params);
        initializeImmediateSearch();
        initializeMenus();
        updateSearchReady();
        monitorSearchFields();
        turnOffAutocomplete($search_input);
    }

    /**
     * Initialize input select menus and search boxes. <p/>
     *
     * The menus will have been pre-filled on the initial page load, however
     * multiple terms of the same type will have already been squashed into a
     * single input.  This function wipes those assignments and starts over so
     * that distinct
     *
     * @param {object} [url_params]   Default: {@link urlParameters}
     */
    function initializeSearchTerms(url_params) {
        const func   = "initializeSearchTerms";
        const params = url_params || urlParameters();
        const $rows  = $search_bar_rows;

        // Reset search selection menus and inputs.
        $rows.each((_, row) => {
            const $row = $(row);
            const type = SEARCH_TYPES[0];
            setSearchType($row, type, func, false);
            setSearchInput($row, "", func, false);
        });

        // noinspection FunctionWithInconsistentReturnsJS
        $.each(SEARCH_TYPES, (_index, type) => {
            let param = compact(arrayWrap(params[type]));
            if (isEmpty(param)) { return true } // continue

            const $matching_rows = $rows.has(`input[name="${type}"]`);
            // noinspection FunctionWithInconsistentReturnsJS
            $matching_rows.each((_, row) => {
                const $row   = $(row);
                const $input = getSearchInput($row);
                if (isEmpty($input.val())) {
                    setSearchInput($row, param.shift(), func, true);
                    toggleHidden($row, false);
                    if (isEmpty(param)) { return false } // break inner loop
                }
            });
            if (isEmpty(param)) { return true } // continue outer loop

            /** @type {jQuery[]} */
            const remaining_rows = [];
            $rows.not($matching_rows).each((_, row) => {
                const $row = $(row);
                if (!searchTerm($row)) {
                    remaining_rows.push($row);
                }
            });
            if (isEmpty(remaining_rows)) {
                OUT.error(`${func}: ignoring`, type, param.join(","));
                return true; // continue outer loop
            }

            // If there aren't enough remaining rows, collapse the last two
            // param rows until there are.
            while (param.length > remaining_rows.length) {
                OUT.debug(`${func}: condensing ${type} param:`, param);
                param = [...param.slice(0, -2), param.slice(-2).join(" ")];
            }

            // Fill remaining rows with param term(s).
            param.forEach(term => {
                const $row = remaining_rows.shift();
                setSearchType($row,  type, func, true);
                setSearchInput($row, term, func, true);
                toggleHidden($row, false);
            });
        });
    }

    /**
     * Initialize search filter control menus. <p/>
     *
     * Although the menus will have been pre-filled on the initial page load,
     * this is necessary to restore the settings after a `history.back()`.
     *
     * @param {object} [url_params]   Default: {@link urlParameters}
     */
    function initializeSearchFilters(url_params) {
        const func   = "initializeSearchFilters";
        const params = url_params || urlParameters();
        $search_filters.each((_, element) => {
            const $menu = getSearchFilterMenu(element, func);
            const name  = $menu.attr("name");
            const type  = name.replace("[]", "");
            const param = params[type] || $menu.attr("data-default");
            const array = (type === name) && Array.isArray(param);
            const value = array ? param.pop() : param;
            $menu.val(value);
        });
    }

    /**
     * Initialize search filter menus.
     *
     * NOTE: This must be invoked after URL parameters have been processed.
     *
     * @param {boolean} [immediate]
     */
    function initializeMenus(immediate = IMMEDIATE_SEARCH) {
        /** @type {MenuOptions} */
        const opt = { on_change: updateSearchReady };
        if (immediate) {
            opt.immediate = preChange;
        } else {
            opt.form_id   = getSearchForm().attr("id");
        }
        initializeMenuControls($search_filters, opt);
    }

    /**
     * For the edge case of a controller type which does not have search term
     * inputs -- only search filters -- make sure that the hidden search button
     * within the filter controls is enabled.
     */
    function guaranteeSearchButton() {
        /** @type {jQuery} */
        const $controls  = $filter_controls.siblings(SEARCH_CONTROLS),
              $filter_sb = $controls.find(SEARCH_BUTTON);
        if (isMissing($search_button.filter(':visible'))) {
            if (!$search_button.attr("value")) {
                const label = Emma.Terms.search_bar.button.label;
                $search_button.attr("value", label);
                $search_button.css("row-gap", "0.5rem");
            }
            toggleHidden($filter_sb, false).toggleClass("visible", true);
        } else if ($filter_sb.is(':visible')) {
            toggleHidden($filter_sb, true ).toggleClass("visible", false);
        }
    }

    /**
     * Re-arrange the search controls so that tabbing advances in the way
     * defined by their `order` attribute defined by CSS styling.
     *
     * @see file:app/assets/stylesheets/layouts/header/_search.scss
     */
    function reorderSearchControls() {
        const order    = (elem) => Number($(elem).css("order"));
        const by_order = (elem1, elem2) => order(elem1) - order(elem2);
        $(SEARCH_CONTROLS).each((_, container) => {
            const $container = $(container);
            const $children  = $container.children();
            const reordered  = $children.toArray().sort(by_order);
            $children.detach();
            $container.append(reordered);
        });
    }

    // ========================================================================
    // Functions - initialization -- immediate mode
    // ========================================================================

    /**
     * Initialize operation for immediate action when a filter is selected.
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     */
    function initializeImmediateSearch() {
        if (!IMMEDIATE_SEARCH) { return }
        OUT.debug("initializeImmediateSearch");
        initializeSearchFormParams();
        initializeSearchFilterParams();
        persistImmediateSearch();
    }

    /**
     * Add `immediate=true` as a hidden input to the search form and all filter
     * controls (menu form wrappers).
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     */
    function persistImmediateSearch() {
        const $form = getSearchForm();
        const id    = $form.attr("id");
        const name  = "immediate_search";
        const value = "true";
        addHiddenInputTo($form, value, { name: name, id: `${id}-${name}` });
        setSearchFilterParams(name, value);
    }

    /**
     * Actions before a multi-select menu selection is changed.
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     *
     * @param {ElementEvt} event
     */
    function preChange(event) {
        const $menu = $(event.currentTarget || event.target);
        OUT.debug("preChange: $menu =", $menu);
        // setSearchFormParamsFromFilters($menu);
        // setSearchFilterParamsFromFilters($menu);
    }

    // ========================================================================
    // Functions - search
    // ========================================================================

    /**
     * Actions to take before the search happens.
     *
     * @param {ElementEvt} event
     */
    function performSearch(event) {
        OUT.debug("performSearch:", event);
        resolveFormFields();
    }

    /**
     * Before completing the search request:
     *
     * - Hide fields which are not intended to be part of the search terms by
     *   blanking their `name` attributes.
     *
     * - If multiple instances of the same `name` are present, ensure that it
     *   is transformed to `name[]` so that they will be present in the form
     *   submission as multiple values.
     */
    function resolveFormFields() {
        const func    = "resolveFormFields";
        const $rows   = $search_bar_rows;
        const $hidden = $rows.find('input[type="hidden"]');
        const count   = {};

        // Check search input fields.
        $rows.each((_, row) => {
            const $row      = $(row);
            const $input    = getSearchInput($row);
            const ignore_if = isHidden($row);
            checkInput($input, ignore_if);
        });

        // Check hidden input fields (if any).
        $hidden.each((_, input) => {
            const $input    = $(input);
            const ignore_if = (value) => (value === "*");
            checkInput($input, ignore_if);
        });

        // Make sure that if a name is repeated, each element will be included
        // in the form parameters.
        $rows.each((_, row) => adjustInputName(getSearchInput(row)));
        $hidden.each((_, input) => adjustInputName(input));

        // Disregard any filter which has the default value to avoid adding a
        // URL parameter that is unneeded.
        getSearchFilter().each((_, element) => {
            const $menu = getSearchFilterMenu(element);
            if ($menu.val() === $menu.attr("data-default")) {
                $menu.attr("name", "");
            }
        });

        /**
         * Blank name if the input should definitely be ignored; add to the
         * count otherwise.
         *
         * @param {jQuery}           $input
         * @param {function|boolean} [skip]     If this resolves to *true* then
         *                                        the input should be ignored.
         */
        function checkInput($input, skip) {
            const name  = $input.attr("name");
            if (!name) { return }
            const type  = name.replace("[]", "");
            count[type] = count[type] || 0;
            const text  = ($input.val() || "").trim();
            if (!text || ((typeof skip === "function") ? skip(text) : skip)) {
                $input.attr("name", "");
                OUT.debug(`${func}: ignoring ${type} ("${text}")`);
            } else {
                count[type]++;
            }
        }

        /**
         * Adjust the name if there are multiple inputs of the given type.
         *
         * @param {jQuery} $input
         */
        function adjustInputName($input) {
            const curr = $input.attr("name");
            if (!curr) { return }
            const type = curr.replace("[]", "");
            let name;
            switch (count[type]) {
                case 0:  name = "";          break; // "can't happen"
                case 1:  name = type;        break;
                default: name = `${type}[]`; break;
            }
            $input.attr("name", name);
        }
    }

    // ========================================================================
    // Functions - search readiness
    // ========================================================================

    // noinspection JSUnusedLocalSymbols
    /**
     * Indicate whether a new search has been defined.
     *
     * @returns {boolean}
     */
    function searchReady() {
        return $search_button.hasClass("ready");
    }

    /**
     * Evaluate whether the search button should indicate readiness for a new
     * search.
     */
    function updateSearchReady() {
        setSearchReady();
    }

    /**
     * Change the state of the search button to indicate whether a new search
     * has been specified. <p/>
     *
     * If a new state is not given, readiness is determined based on whether
     * search terms and/or filters have been added and/or modified.
     *
     * @param {boolean} [state]
     */
    function setSearchReady(state) {
        let ready = state;
        if (notDefined(ready)) {
            const $rows = $search_bar_rows;
            ready ||= isPresent(newSearchTerms($rows));
            ready ||= isPresent(newSearchFilters());
            ready &&= isPresent(compact(allSearchTerms($rows)));
        }
        const tooltip = ready ? "data-ready" : "data-not-ready";
        const title   = $search_button.attr(tooltip);
        if (isDefined(title)) {
            $search_button.attr("title", title);
        }
        $search_button.toggleClass("ready", ready);
    }

    /**
     * Listen for changes on search box input fields.
     *
     * @see updatedSearchTerm
     */
    function monitorSearchFields() {

        handleEvent($search_input_select, "change", updatedSearchType);
        handleEvent($search_input,        "change", onChange);
        handleEvent($search_input,        "input",  debounce(onInput));

        /**
         * Check readiness after the element's content changes.
         *
         * @param {ElementEvt} event
         */
        function onChange(event) {
            //OUT.debug("*** CHANGE ***");
            updatedSearchTerm(event);
        }

        /**
         * Respond to key presses only after the user has paused, rather than
         * re-validating the entire form with every key stroke.  This also
         * applies to cut, paste, drag, drop, and delete input event types.
         *
         * @param {InputEvt} event
         *
         * @see https://www.w3.org/TR/input-events-1#interface-InputEvent
         */
        function onInput(event) {
            const type = (event?.originalEvent || event)?.inputType || "";
            //OUT.debug(`*** INPUT ${type} ***`);
            if (!type.startsWith("format")) {
                updatedSearchTerm(event);
            }
        }
    }

    // ========================================================================
    // Functions - search filter panel
    // ========================================================================

    /**
     * Indicate whether the search filter panel is expanded (open).
     *
     * @returns {boolean}
     */
    function isExpandedFilterPanel() {
        return $filter_controls.hasClass(OPEN_MARKER);
    }

    /**
     * Toggle visibility of search filters.
     */
    function toggleFilterPanel() {
        const opening = !isExpandedFilterPanel();
        OUT.debug((opening ? "SHOW" : "HIDE"), "search filters");
        setFilterPanelState(opening);
        setFilterPanelDisplay(opening);
    }

    /**
     * Save the state of search filters in the session.
     *
     * @param {boolean|string} opening
     */
    function setFilterPanelState(opening) {
        let state = opening;
        if (typeof state !== "string") {
            state = state ? OPEN : CLOSED;
        }
        sessionStorage.setItem(SEARCH_CONTROLS_CLASS, state);
    }

    /**
     * Get the state of search filters.
     *
     * @returns {string}
     */
    function getFilterPanelState() {
        return sessionStorage.getItem(SEARCH_CONTROLS_CLASS);
    }

    /**
     * Set the state of the filter panel display.
     *
     * @param {boolean} opening
     */
    function setFilterPanelDisplay(opening) {
        setFilterPanelToggle(opening);
        setResetButton(opening);
        $filter_controls.toggleClass(OPEN_MARKER, opening);
    }

    /**
     * Set the state of the filter panel toggle button label.
     *
     * @param {boolean} opening
     */
    function setFilterPanelToggle(opening) {
        const action = opening ? "closer" : "opener";
        const button = Emma.Search.Filter.control[action];
        $advanced_toggle.html(button.label);
        $advanced_toggle.attr("title", button.tooltip);
    }

    /**
     * Set the state of the search reset button.
     *
     * @param {boolean} opening
     *
     * @see "LayoutHelper::SearchFilters#reset_button"
     * @see file:app/assets/stylesheets/shared/_header.scss .menu-button.reset
     */
    function setResetButton(opening) {
        toggleHidden($reset_button, !opening);
    }

    // ========================================================================
    // Functions - search inputs
    // ========================================================================

    /**
     * Get the search `<form>` element.
     *
     * @param {Selector} [form]       Default: {@link $search_bar_container}.
     *
     * @returns {jQuery}
     */
    function getSearchForm(form) {
        const selector = "form";
        const $form    = form ? $(form) : $search_bar_container;
        return $form.is(selector) ? $form : $form.find(selector).first();
    }

    /**
     * Get the search bar input row associated with the target. <p/>
     *
     * All search bar rows are returned if **target** is not given.
     *
     * @param {SelectorOrEvent} [target]
     * @param {string}          [caller]    For logging.
     *
     * @returns {jQuery}
     */
    function getSearchRow(target, caller) {
        const func = caller || "getSearchRow";
        const tgt  = target || getSearchForm();
        return getContainerElement(tgt, SEARCH_BAR_ROW, func);
    }

    /**
     * Get the search type selection menu associated with the target.
     *
     * @param {SelectorOrEvent} [target]
     * @param {string}          [caller]    For logging.
     *
     * @returns {jQuery}
     */
    function getSearchInputSelect(target, caller) {
        const selector = SEARCH_TYPE_MENU;
        return getContainedElement(target, selector, caller, getSearchRow);
    }

    /**
     * Get the search input box associated with the target.
     *
     * @param {SelectorOrEvent} [target]
     * @param {string}          [caller]    For logging.
     *
     * @returns {jQuery}
     */
    function getSearchInput(target, caller) {
        return getContainedElement(target, SEARCH_INPUT, caller, getSearchRow);
    }

    /**
     * Get the clear-search control associated with the target.
     *
     * @param {SelectorOrEvent} [target]
     * @param {string}          [caller]    For logging.
     *
     * @returns {jQuery}
     */
    function getSearchClear(target, caller) {
        return getContainedElement(target, SEARCH_CLEAR, caller, getSearchRow);
    }

    // ========================================================================
    // Functions - search inputs - row controls
    // ========================================================================

    /**
     * Cause the first hidden search bar row in the sequence to be revealed.
     *
     * @param {ElementEvt} event
     */
    function showNextRow(event) {
        const func      = "showNextRow";
        const $this_row = getSearchRow(event, func);
        const $hidden   = $this_row.siblings(HIDDEN);
        const available = $hidden.length;
        if (available >= 1) { toggleHidden($hidden.first(), false) }
        if (available <= 1) { toggleVisibility($row_show_buttons, false) }
        updateSearchReady();
    }

    /**
     * Hide the search bar row associated with this control. <p/>
     *
     * The implementation assumes that the first row cannot be deleted.
     *
     * @param {ElementEvt} event
     */
    function hideThisRow(event) {
        const func      = "hideThisRow";
        const $this_row = getSearchRow(event, func);
        if ($this_row.is('.first')) {
            OUT.error(`${func}: cannot hide first row`);
        } else {
            toggleHidden($this_row, true);
            toggleVisibility($row_show_buttons, true);
            updateSearchReady();
        }
    }

    // ========================================================================
    // Functions - search inputs - search terms
    // ========================================================================

    /**
     * The current search terms as defined by the contents of the input box
     * associated with the target.
     *
     * @param {Selector} target       Passed to {@link getSearchInput}
     *
     * @returns {string}
     */
    function searchTerm(target) {
        return getSearchInput(target, "searchTerm").val() || "";
    }

    /**
     * Set (or clear) the contents of the given search input. <p/>
     *
     * If there was a change, the new search input box value is returned; or
     * undefined if no change.
     *
     * @param {Selector}        target          Passed to {@link getSearchRow}
     * @param {string|string[]} [new_terms]     New search terms (default: "").
     * @param {string}          [caller]        For logging.
     * @param {boolean}         [set_original]  Update {@link DATA_ORIGINAL}.
     *
     * @returns {string|undefined}
     */
    function setSearchInput(target, new_terms, caller, set_original) {
        if (!target) {
            const func = caller || "setSearchInput";
            return OUT.error(`${func}: target: missing/empty`);
        }
        const $row   = getSearchRow(target);
        const $input = getSearchInput($row);
        let terms    = new_terms &&
            arrayWrap(new_terms)
                .map(term => term?.trim())
                .filter(term => term)
                .map(term => decodeURIComponent(term.replaceAll("+", " ")))
                .join(" ");
        if (terms === "*") { terms = "" }

        $input.val(terms);
        updateSearchClear($input);

        if (notDefined(set_original)) {
            const original = $input.attr(DATA_ORIGINAL);
            if (notDefined(original)) {
                $input.attr(DATA_ORIGINAL, "");
            } else if (terms === original) {
                terms = undefined;
            }
            updateSearchReady();
        } else if (set_original) {
            $input.attr(DATA_ORIGINAL, terms);
        }
        return terms;
    }

    /**
     * Set (or clear) the search term of the given search input.
     *
     * @param {SelectorOrEvent} target
     * @param {string}          new_terms   Sets or clears the input box.
     * @param {string}          [caller]    For logging.
     */
    function setSearchTerm(target, new_terms, caller) {
        const func = caller || "setSearchTerm";
        setSearchInput(target, new_terms, func);
        if (IMMEDIATE_SEARCH) {
            setSearchFilterParams(searchType(target), searchTerm(target));
        }
    }

    /**
     * Respond to a user-initiated change in the content of a search input.
     *
     * @param {ElementEvt} event
     *
     * @see monitorSearchFields
     */
    function updatedSearchTerm(event) {
        const func   = "updatedSearchTerm";
        const target = event.currentTarget || event.target;
        const $input = getSearchInput(target, func);
        const time   = "timestamp";
        const prev_t = $input.data(time);
        const this_t = event.timeStamp;
        if (!prev_t || (prev_t < this_t)) {
            $input.data(time, this_t);
        }
        if (!prev_t || ((prev_t + (2 * DEBOUNCE_DELAY)) < this_t)) {
            setSearchTerm($input, $input.val(), func);
        }
    }

    /**
     * Clear the associated search input.
     *
     * @param {ElementEvt} [event]
     * @param {boolean} [allow_default]   If *true*, do not mark the event as
     *                                      handled (*false* by default because
     *                                      the SEARCH_CLEAR control is an
     *                                      `<a>` to preserve tab order).
     */
    function clearSearchTerm(event, allow_default) {
        const func   = "clearSearchTerm";
        const target = event.currentTarget || event.target;
        setSearchTerm(target, "", func);
        if (isEvent(event) && !allow_default) {
            event.preventDefault();
        }
    }

    /**
     * Show the SEARCH_CLEAR control if the associated search input has content
     * and hide it if it does not.
     *
     * @param {SelectorOrEvent} [target]    Passed to {@link getSearchInput}
     */
    function updateSearchClear(target) {
        const $input  = getSearchInput(target);
        const $button = getSearchClear($input);
        const text    = ($input.val() || "").trim();
        toggleVisibility($button, isPresent(text));
    }

    /**
     * A table of search types and queries. <p/>
     *
     * Search types which are disabled will appear in the result with a blank
     * query (regardless of whether the input control happens to have a value).
     *
     * @param {Selector} [target]     Default: all rows.
     * @param {string}   [caller]     For logging.
     * @param {boolean}  [new_only]   If *true* include only non-blank entries
     *                                  that have been added/modified.
     *
     * @returns {{type: string, query: string|string[]}}
     */
    function allSearchTerms(target, caller, new_only) {
        const func    = caller || "allSearchTerms";
        const $rows   = target ? getSearchRow(target, func) : $search_bar_rows;
        const queries = {}
        $rows.each((_, row) => {
            const $row   = $(row);
            const $input = getSearchInput($row);
            const $menu  = getSearchInputSelect($row);
            const hidden = isHidden($row);
            const name   = $input.attr("name") || "";
            const type   = isPresent($menu) ? searchType($menu) : name;
            const value  = $input.val().trim();

            let skip;
            if (!name) {
                skip = "ignored";
            } else if (new_only) {
                const original_value = $input.attr(DATA_ORIGINAL) || "";
                const original_type  = getOriginalMenuValue($menu);
                if (original_type && (type !== original_type)) {
                    // Whatever the value, if the type has changed then this
                    // constitutes a new search, so this type should appear in
                    // the return value.
                } else if (hidden && original_value) {
                    // If an original row has been hidden, we want that to show
                    // up as a change (to guarantee that newSearchTerms() will
                    // not return an empty object.
                } else if (hidden) {
                    skip = "hidden";
                } else if (value === original_value) {
                    skip = `"${value}" same as ${DATA_ORIGINAL}`;
                }
            } else if (hidden) {
                skip = "hidden";
            }

            if (skip) {
                OUT.debug(`${func}: skipping ${type}: ${skip}`);
            } else if (Array.isArray(queries[type])) {
                queries[type].push(value);
            } else if (isDefined(queries[type])) {
                queries[type] = [queries[type], value];
            } else {
                queries[type] = value;
            }
        });
        return queries;
    }

    /**
     * A table of added/modified search types and queries. <p/>
     *
     * The result will include entries only for non-blank search terms.
     *
     * @param {Selector} [target]     Default: all rows.
     *
     * @returns {{type: string, query: string|string[]}}
     */
    function newSearchTerms(target) {
        return allSearchTerms(target, "newSearchTerms", true);
    }

    // ========================================================================
    // Functions - search inputs - search type
    // ========================================================================

    /**
     * The current search type as defined by the search type selection menu.
     *
     * @param {Selector} target       Passed to {@link getSearchInputSelect}
     *
     * @returns {string}
     */
    function searchType(target) {
        return getSearchInputSelect(target, "searchType").val() || "";
    }

    /**
     * Set the search type for a search bar as defined by its search type
     * selection menu. <p/>
     *
     * If there was a change, the new search type is returned; or undefined if
     * no change.
     *
     * @param {Selector}        target          Passed to {@link getSearchRow}
     * @param {string}          new_type        Sets the new search type.
     * @param {string}          [caller]        For logging.
     * @param {boolean}         [set_original]  Update {@link DATA_ORIGINAL}.
     *
     * @returns {string|undefined}
     */
    function setSearchType(target, new_type, caller, set_original) {
        if (!target) {
            const func = caller || "setSearchType";
            return OUT.error(`${func}: target: missing/empty`);
        }
        const $row   = getSearchRow(target);
        const $menu  = getSearchInputSelect($row);
        const name   = new_type ? new_type.trim().toLowerCase() : "";
        let type     = name.replace("[]", "");
        const config = SEARCH_TYPE[type];

        $menu.val(type);
        const $input = getSearchInput($row);
        $input.attr({ name: name, placeholder: config.placeholder });
        $input.siblings(SEARCH_TYPE_LABEL).html(config.label);

        if (notDefined(set_original)) {
            const original = getOriginalMenuValue($menu);
            if (notDefined(original)) {
                setOriginalMenuValue($menu, "");
            } else if (type === original) {
                type = undefined;
            }
            updateSearchReady();
        } else if (set_original) {
            setOriginalMenuValue($menu, type);
        }
        return type;
    }

    /**
     * Respond to a user-initiated change in a search input selection menu.
     *
     * @param {ElementEvt} event
     */
    function updatedSearchType(event) {
        const func   = "updatedSearchType"; OUT.debug(`${func}:`, event);
        const target = event.currentTarget || event.target;
        const $menu  = getSearchInputSelect(target);
        const type   = $menu.val();
        setSearchType($menu, type, func);
        if (IMMEDIATE_SEARCH) {
            setSearchFilterParams(type, searchTerm($menu));
        }
    }

    // ========================================================================
    // Functions - search filters
    // ========================================================================

    /**
     * Get the search filter control associated with the target. <p/>
     *
     * All search filter controls are returned if **target** is not given.
     *
     * @param {SelectorOrEvent} [target]
     * @param {string}          [caller]    For logging.
     *
     * @returns {jQuery}
     */
    function getSearchFilter(target, caller) {
        const func = caller || "getSearchFilter";
        const tgt  = target || $search_filters;
        return getContainerElement(tgt, SEARCH_FILTER, func);
    }

    /**
     * Get the search filter menu associated with the target.
     *
     * @param {SelectorOrEvent} target
     * @param {string}          [caller]
     *
     * @returns {jQuery}
     */
    function getSearchFilterMenu(target, caller) {
        return getContainedElement(target, 'select', caller, getSearchFilter);
    }

    /**
     * A table of current search filter values.
     *
     * @param {Selector} [target]     Default: {@link $search_filters}.
     * @param {string}   [caller]     For logging.
     * @param {boolean}  [new_only]   If *true* include only non-blank entries
     *                                  that have been added/modified.
     *
     * @returns {{type: string, query: string|string[]}}
     */
    function allSearchFilters(target, caller, new_only) {
        const func    = caller || "allSearchFilters"; OUT.debug(func);
        const filters = {}
        const array   = (item) => {
            if (isEmpty(item))       { return [] }
            if (Array.isArray(item)) { return item.sort() }
            return item.split(",").sort();
        };
        getSearchFilter(target).each((_, element) => {
            const $ctrl = $(element);
            const $menu = getSearchFilterMenu($ctrl);
            const name  = $menu.attr("name") || "";
            const arr   = name.endsWith("[]");
            const type  = arr ? name.replace("[]", "")  : name;
            const value = arr ? array($menu.val()) : ($menu.val() || "");

            let skip;
            if (!name) {
                skip = "ignored";
            } else if (isHidden($ctrl)) {
                skip = "hidden";
            } else if (new_only) {
                const original = getOriginalMenuValue($menu);
                const val      = value.toString();
                if (notDefined(original) && !val) {
                    skip = "empty value";
                } else if (val === array(original).toString()) {
                    skip = `"${val}" same as ${DATA_ORIGINAL}`;
                }
            }

            if (skip) {
                OUT.debug(`${func}: skipping ${type}: ${skip}`);
            } else if (isDefined(filters[type])) {
                const current = new Set(arrayWrap(filters[type]));
                arrayWrap(value).forEach(v => current.add(v));
                filters[type] = [...current];
            } else {
                filters[type] = value;
            }
        });
        return filters;
    }

    /**
     * A table of modified search filter values. <p/>
     *
     * The result will include entries only for non-blank selections.
     *
     * @param {Selector} [target]     Default: all rows.
     *
     * @returns {{type: string, query: string|string[]}}
     */
    function newSearchFilters(target) {
        const func = "newSearchFilters";
        return allSearchFilters(target, func, true);
    }

    // ========================================================================
    // Functions - search filters - immediate mode - inputs hidden parameters
    // ========================================================================

    /**
     * Set hidden inputs for the search input form.
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     */
    function initializeSearchFormParams() {
        setSearchFormParamsFromFilters();
    }

    /**
     * Set search input form hidden inputs from search filters.
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     *
     * @param {Selector} [src]        Default: {@link $search_filters}.
     */
    function setSearchFormParamsFromFilters(src) {
        setSearchFormParams($search_bar_container, src);
    }

    /**
     * Update all hidden inputs in the destination element which track the
     * settings of search filters.
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     *
     * @param {Selector} [dst]        Default: {@link $search_bar_container}.
     * @param {Selector} [src]        Default: {@link $search_filters}.
     */
    function setSearchFormParams(dst, src) {
        const $dst = dst ? $(dst) : $search_bar_container;
        const $src = src ? $(src) : $search_filters;
        $src.each((_, s) => setSearchFormHiddenInputs($dst, s));
    }

    /**
     * Create/modify/delete a hidden input from a destination element which
     * tracks tracks the settings of search filters.
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     *
     * @param {Selector} dst          Destination with hidden inputs.
     * @param {Selector} src          Source filter control.
     */
    function setSearchFormHiddenInputs(dst, src) {
        const $menu = getSearchFilterMenu(src);
        updateHiddenInputs(dst, $menu);
    }

    // ========================================================================
    // Functions - search filters - immediate mode - filters hidden parameters
    // ========================================================================

    /**
     * Set hidden input parameters for each search filter control.
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     */
    function initializeSearchFilterParams() {
        setSearchFilterParamsFromInputs();
        setSearchFilterParamsFromFilters();
    }

    /**
     * Set search input form hidden inputs from search filters.
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     *
     * @param {Selector} [src]        Default: all search inputs.
     */
    function setSearchFilterParamsFromInputs(src) {
        const terms = allSearchTerms(src);
        setSearchFilterParams(terms);
    }

    /**
     * Update all hidden inputs in the destination element which track the
     * settings of search filters.
     *
     * @param {Selector} [src]        Default: {@link $search_filters}.
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     */
    function setSearchFilterParamsFromFilters(src) {
        const $controls = src ? $(src) : $search_filters;
        $controls.each((_, ctrl) => {
            const $ctrl = getSearchFilter(ctrl);
            const $menu = getSearchFilterMenu($ctrl);
            const $dst  = $controls.not($ctrl);
            updateHiddenInputs($dst, $menu);
        });
    }

    /**
     * Modify the hidden input parameters of each filter control based on the
     * new search type and search terms.
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     *
     * @param {object|string} new_type
     * @param {string}        [new_value]
     */
    function setSearchFilterParams(new_type, new_value) {
        $search_filters.each((_, element) => {
            setSearchFilterHiddenInputs(element, new_type, new_value);
        });
    }

    /**
     * Add and/or subtract hidden input parameters from a filter control so
     * that selecting it will result in the proper search URL.
     *
     * @param {Selector}      control       Filter control to modify.
     * @param {object|string} new_type
     * @param {string}        [new_value]
     *
     * @note Only applicable if {@link IMMEDIATE_SEARCH} is *true*.
     */
    function setSearchFilterHiddenInputs(control, new_type, new_value) {
        const $control = getSearchFilter(control);
        const $menu    = getSearchFilterMenu($control);
        updateHiddenInputs($control, $menu, new_type, new_value);
    }

    // ========================================================================
    // Functions - search filters - immediate mode - general
    // ========================================================================

    /**
     * Create/update/delete hidden input(s) on **dst**.
     *
     * @param {Selector}           dst
     * @param {Selector|undefined} menu
     * @param {string|object}      [new_type]
     * @param {string}             [new_value]
     */
    function updateHiddenInputs(dst, menu, new_type, new_value) {
        const func  = "updateHiddenInputs";
        const $menu = menu && $(menu);
        const base  = $menu?.attr("name")?.replace("[]", "") || "input";
        let values;
        if (typeof new_type === "object") {
            values = new_type;
        } else if (new_type) {
            values = Object.fromEntries([[new_type, new_value]]);
        } else if ($menu) {
            values = Object.fromEntries([[$menu.attr("name"), $menu.val()]]);
        } else {
            OUT.error(`${func}: no menu selector given`);
            return;
        }
        $(dst).each((_, element) => {
            /** @type {jQuery} */
            const $dst    = $(element);
            const $hidden = $dst.find('input[type="hidden"]');
            const base_id = $dst.attr("id") || randomizeName(base);
            for (const [name, value] of Object.entries(values)) {
                const type     = name.replace("[]", "");
                const selector = `[name="${type}"]`;
                const input_id = `${base_id}-${type}`;
                if ((type !== name) || Array.isArray(value)) {
                    // Blow away any matching hidden inputs and re-create.
                    $hidden.filter(selector + `, [name="${type}[]"]`).remove();
                    const attr = { name: `${type}[]` };
                    compact(arrayWrap(value)).forEach((v, i) => {
                        attr.id = `${input_id}-${i}`;
                        addHiddenInputTo($dst, v, attr);
                    });
                } else {
                    const $input = $hidden.filter(selector);
                    if (isPresent($input)) {
                        if (value) {
                            $input.val(value);
                        } else {
                            $input.remove();
                        }
                    } else if (value) {
                        const attr = { name: type, id: input_id };
                        addHiddenInputTo($dst, value, attr);
                    }
                }
            }
        });
    }

    /**
     * Create a hidden `<input>` and prepend to the given element. <p/>
     *
     * (Because it is prepended, a control inside the element having the same
     * `name` attribute will take precedence.)
     *
     * @param {Selector} dst          Destination for hidden input.
     * @param {string} [value]
     * @param {object} [attributes]
     *
     * @returns {jQuery}
     */
    function addHiddenInputTo(dst, value, attributes) {
        const $input = $('<input type="hidden">');
        if (isDefined(attributes)) { $input.attr(attributes) }
        if (isDefined(value))      { $input.val(value) }
        if (isDefined(dst))        { $input.prependTo($(dst)) }
        return $input;
    }

    // ========================================================================
    // Functions - general
    // ========================================================================

    /**
     * Get the element associated with the target, which encloses one or more
     * elements accessible via {@link getContainedElement}.
     *
     * @param {SelectorOrEvent}   target
     * @param {Selector}          selector
     * @param {string}            caller        For logging.
     * @param {Selector|function} [def_target]
     *
     * @returns {jQuery}
     */
    function getContainerElement(target, selector, caller, def_target) {
        /** @type {jQuery} */
        let $target;
        let func    = caller || "getContainerElement";
        if (isEvent(target)) {
            func    = caller || `${target.type} handler`;
            $target = $(target.currentTarget || target.target);
        } else if (target) {
            $target = $(target);
        } else if (typeof def_target === "function") {
            $target = def_target();
        } else if (def_target) {
            $target = $(def_target);
        }
        /** @type {jQuery} */
        let $result, $inside, $outside;
        if (isMissing($target)) {
            OUT.warn(`${func}: target missing/empty`);
        } else if ($target.is(selector)) {
            $result = $target;
        } else if (isPresent(($outside = $target.parents(selector)))) {
            $result = $outside;
        } else if (isPresent(($inside = $target.find(selector)))) {
            $result = $inside;
        } else {
            OUT.error(`${func}: invalid target:`, target);
        }
        return $result || $();
    }

    /**
     * Get the element associated with the target, which is contained within
     * an element accessible via {@link getContainerElement}.
     *
     * @param {SelectorOrEvent}   target
     * @param {Selector}          selector
     * @param {string}            caller        For logging.
     * @param {Selector|function} container
     *
     * @returns {jQuery}
     */
    function getContainedElement(target, selector, caller, container) {
        /** @type {jQuery} */
        let $target;
        let func    = caller || "getContainedElement";
        if (isEvent(target)) {
            func    = caller || `${target.type} handler`;
            $target = $(target.currentTarget || target.target);
        } else if (target) {
            $target = $(target);
        }
        /** @type {jQuery} */
        let $result;
        if (isMissing($target)) {
            OUT.error(`${func}: target missing/empty`);
        } else if ($target.is(selector)) {
            $result = $target;
        } else if (typeof container === "function") {
            $result = container($target, func).find(selector);
        } else if (container) {
            $result = $(container).find(selector);
        }
        return $result || $();
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($search_button,    performSearch);
    handleClickAndKeypress($search_clear,     clearSearchTerm);
    handleClickAndKeypress($row_show_buttons, showNextRow);
    handleClickAndKeypress($row_hide_buttons, hideThisRow);
    handleClickAndKeypress($advanced_toggle,  toggleFilterPanel);

    // ========================================================================
    // Actions
    // ========================================================================

    initializeAdvancedSearch();

});
