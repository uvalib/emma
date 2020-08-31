// app/assets/javascripts/feature/advanced-search.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS, FunctionTooLongJS
$(document).on('turbolinks:load', function() {

    /**
     * All search sections.
     *
     * @type {jQuery}
     */
    let $search_sections = $('.layout-section.search');

    // Only perform these actions on the appropriate pages.
    if (isMissing($search_sections)) {
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @constant
     * @type {boolean}
     */
    const DEBUGGING = true;

    /**
     * State value indicating that the advanced search control panel is open.
     *
     * @constant
     * @type {string}
     */
    const OPEN = 'open';

    /**
     * State value indicating that the advanced search control panel is closed.
     *
     * @constant
     * @type {string}
     */
    const CLOSED = 'closed';

    /**
     * Marker class indicating that the advanced search control panel is open.
     *
     * @constant
     * @type {string}
     */
    const OPEN_MARKER = 'open';

    /**
     * Search types and their display properties.
     *
     * @constant
     * @type {object}
     */
    const SEARCH_TYPE = Emma.AdvSearch.search_type;

    /**
     * Search types.
     *
     * @constant
     * @type {string[]}
     */
    const SEARCH_TYPES = Object.keys(SEARCH_TYPE);

    // ========================================================================
    // Constants - multi-select menus
    // ========================================================================

    /**
     * Events exposed by Select2.
     *
     * @constant
     * @type {string[]}
     */
    const MULTI_SELECT_EVENTS = [
        'change',
        'change.select2',
        'select2:clearing',
        'select2:clear',
        'select2:opening',
        'select2:open',
        'select2:selecting',
        'select2:select',
        'select2:unselecting',
        'select2:unselect',
        'select2:closing',
        'select2:close'
    ];

    /**
     * The longest Select2 event name.
     *
     * @constant
     * @type {number}
     *
     * @see logSelectEvent
     */
    const MULTI_SELECT_EVENTS_WIDTH = (function() {
        let max = 0;
        MULTI_SELECT_EVENTS.forEach(function(type) {
            max = Math.max(max, type.length);
        });
        return max;
    })();

    /**
     * Select2 events which precede the change which causes a new search to be
     * performed.
     *
     * @constant
     * @type {string[]}
     */
    const PRE_CHANGE_EVENTS = ['select2:selecting', 'select2:unselecting'];

    /**
     * Select2 events which follow a change which causes a new search to be
     * performed.
     *
     * @constant
     * @type {string[]}
     */
    const POST_CHANGE_EVENTS = ['select2:select', 'select2:unselect'];

    /**
     * Select2 events which should detect whether to suppress the opening of
     * the drop-down menu.
     *
     * @constant
     * @type {string[]}
     */
    const CHECK_SUPPRESS_MENU_EVENTS = ['select2:opening'];

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * The advanced-search toggle button.
     *
     * @type {jQuery}
     */
    let $advanced_toggle = $search_sections.find('.advanced-search-toggle');

    /**
     * All instances of the search filter reset button.
     *
     * @type {jQuery}
     */
    let $reset_button = $search_sections.find('.menu-button.reset');

    /**
     * The element with the search bar and related controls.
     *
     * @type {jQuery}
     */
    let $search_bar_container = $search_sections.find('.search-bar-container');

    /**
     * The menu which changes the search type.
     *
     * @type {jQuery}
     */
    let $input_select = $search_bar_container.find('.search-input-select');

    /**
     * The form enclosing the search input box.
     *
     * @type {jQuery}
     */
    let $search_input_form = $search_bar_container.find('.search-input-bar');

    /**
     * The input box associated with the advanced search toggle.
     *
     * @type {jQuery}
     */
    let $search_input = $search_input_form.find('.search-input');

    /**
     * The input clear button.
     *
     * @type {jQuery}
     */
    let $search_clear = $search_input_form.find('.search-clear');

    /**
     * The button that performs the search.
     *
     * @type {jQuery}
     */
    let $search_button = $search_input_form.find('.search-button');

    /**
     * The search controls container.
     *
     * @type {jQuery}
     */
    let $control_panel = $search_sections.find('.search-controls');

    /**
     * The search control menu <form> elements.
     *
     * @type {jQuery}
     */
    let $controls = $control_panel.find('.menu-control');

    /**
     * Multi-select dropdown menus.
     *
     * @type {jQuery}
     */
    let $multi_select = $controls.find('select[multiple]');

    /**
     * An indicator that is presented during a time-consuming search.
     *
     * @type {jQuery}
     */
    let $search_in_progress = $('body').children('.search-in-progress');

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleEvent($controls,     'change', showInProgress);
    handleEvent($input_select, 'change', updateSearchType);
    handleEvent($search_input, 'change', updateSearchTerms);
    handleEvent($search_input, 'keyup',  setSearchClearButton);

    handleClickAndKeypress($search_button,   showInProgress);
    handleClickAndKeypress($reset_button,    showInProgress);
    handleClickAndKeypress($search_clear,    clearSearchTerms);
    handleClickAndKeypress($advanced_toggle, toggleControlPanel);

    // ========================================================================
    // Actions
    // ========================================================================

    initializeAdvancedSearch();
    hideInProgress();

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Set the current state of advanced search controls.
     */
    function initializeAdvancedSearch() {
        if (isMissing($control_panel)) {
            $advanced_toggle.hide();
            $reset_button.hide();
        } else {
            let was_open = getControlPanelState();
            let is_open = $control_panel.hasClass(OPEN_MARKER) ? OPEN : CLOSED;
            if (was_open !== is_open) {
                if (was_open === OPEN) {
                    setControlPanelDisplay(true);
                } else if (was_open === CLOSED) {
                    setControlPanelDisplay(false);
                } else {
                    setControlPanelState(is_open);
                }
            }
            initializeMultiSelect();
        }
        updateSearchType();
        setSearchClearButton();
    }

    // ========================================================================
    // Functions - control panel
    // ========================================================================

    /**
     * Toggle visibility of advanced search controls.
     */
    function toggleControlPanel() {
        const opening = !$control_panel.hasClass(OPEN_MARKER);
        if (DEBUGGING) {
            const action = opening ? 'SHOW' : 'HIDE';
            debug(action, 'advanced search controls');
        }
        setControlPanelState(opening);
        setControlPanelDisplay(opening);
    }

    /**
     * Save the state of advanced search controls in the session.
     *
     * @param {boolean|string} opening
     */
    function setControlPanelState(opening) {
        let state = opening;
        if (typeof state !== 'string') {
            state = state ? OPEN : CLOSED;
        }
        sessionStorage.setItem('search-controls', state);
    }

    /**
     * Get the state of advanced search controls.
     *
     * @returns {string}
     */
    function getControlPanelState() {
        return sessionStorage.getItem('search-controls');
    }

    /**
     * Set the state of the control panel display.
     *
     * @param {boolean} opening
     */
    function setControlPanelDisplay(opening) {
        setControlPanelToggle(opening);
        setResetButton(opening);
        $control_panel.toggleClass(OPEN_MARKER, opening);
    }

    /**
     * Set the state of the control panel toggle button label.
     *
     * @param {boolean} opening
     */
    function setControlPanelToggle(opening) {
        /** @type {{label: string, tooltip: string}} */
        const value = opening ? Emma.AdvSearch.closer : Emma.AdvSearch.opener;
        $advanced_toggle.html(value.label).attr('title', value.tooltip);
    }

    /**
     * Set the state of the search reset button.
     *
     * Each specific .menu-button element may have custom CSS properties set
     * according to the layout determined by the width of the medium:
     *
     * If '--manage-visibility' is set to 'true', then this function should
     *   modify the visibility of the element (toggling between 'visible' and
     *   'hidden').
     *
     * @param {boolean} opening
     *
     * @see ".search-bar-container.menu-button.reset in shared/_header.scss"
     */
    function setResetButton(opening) {
        const state = opening ? 'visible' : 'hidden';
        $reset_button.each(function() {
            let $button = $(this);
            let manage  = $button.css('--manage-visibility');
            if (isDefined(manage) && (manage.trim() === 'true')) {
                $button.css('visibility', state);
            }
        });
    }

    // ========================================================================
    // Functions - search terms
    // ========================================================================

    /**
     * The current search terms as defined by the contents of the input box.
     *
     * @returns {string}
     */
    function searchTerms() {
        return $search_input.val();
    }

    /**
     * Sets (or clears) the contents of the search input box.
     *
     * @param {string} [new_terms]    New search terms ('' if missing).
     */
    function setSearchInput(new_terms) {
        let terms = undefined;
        if (new_terms) {
            terms = new_terms.replace(/\+/g, ' ');
            terms = decodeURIComponent(terms);
            if (terms === '*') { terms = ''; }
        }
        $search_input.val(terms || '');
        setSearchClearButton();
    }

    /**
     * The current search terms as defined by the contents of the input box.
     *
     * @param {string} new_terms      Sets the new search terms if provided.
     */
    function setSearchTerms(new_terms) {
        setSearchInput(new_terms);
        setMenuParameters();
    }

    /**
     * Update the search box and menus.
     *
     * @param {jQuery.Event} event
     */
    function updateSearchTerms(event) {
        setSearchTerms(event.target.value);
    }

    /**
     * Clear the search box.
     *
     * @param {jQuery.Event} [event]
     * @param {boolean} [allow_default]   If *true*, do not mark the event as
     *                                      handled (*false* by default because
     *                                      the '.search-clear' control is an
     *                                      <a> in order to preserve tab order)
     */
    function clearSearchTerms(event, allow_default) {
        if (event && !allow_default) { event.preventDefault(); }
        setSearchTerms('');
    }

    /**
     * Do not show the search clear control if this search box is empty.
     */
    function setSearchClearButton() {
        const state = $search_input.val() ? 'visible' : 'hidden';
        $search_clear.css('visibility', state);
    }

    // ========================================================================
    // Functions - search type
    // ========================================================================

    /**
     * The current search type as defined by the input selection menu.
     *
     * @returns {string}
     */
    function searchType() {
        return $input_select.val();
    }

    /**
     * The current search type as defined by the input selection menu.
     *
     * @param {string} new_type       Sets the new search type.
     * @param {string} [new_terms]    Sets the search terms if provided.
     */
    function setSearchType(new_type, new_terms) {
        const search_type  = new_type  || searchType();
        const search_terms = new_terms || searchTerms();
        $input_select.val(search_type);
        setSearchInput(search_terms);
        setSearchBar(search_type);
        setMenuParameters(search_type);
    }

    /**
     * Update the search input based on the selected search type and create
     * blank hidden inputs for the other search types.
     *
     * @param {string} [new_type]
     */
    function setSearchBar(new_type) {
        const search_type = new_type || searchType();
        let $hidden       = $search_input_form.find('input[type="hidden"]');
        SEARCH_TYPES.forEach(function(type) {
            // noinspection JSCheckFunctionSignatures
            let $input = $hidden.filter(`[name="${type}"]`);
            if (type === search_type) {
                // Make sure that there is no hidden input for this type then
                // update the search input element.
                $input.remove();
                $search_input.attr({
                    'name':        type,
                    'placeholder': SEARCH_TYPE[type].placeholder
                });
            } else if (isMissing($input)) {
                // Create a hidden input for this type.
                // noinspection ReuseOfLocalVariableJS
                $input = $('<input type="hidden">');
                $input.attr('name', type);
                $input.attr('id',   `search-input-select-${type}`);
                $input.appendTo($search_input_form);
                $input.val('');
            } else {
                $input.val('');
            }
        });
    }

    /**
     * Update the input select menu, search box, and menus.
     *
     * @param {jQuery.Event} [event]
     */
    function updateSearchType(event) {
        let [type, query] = [];
        if (event) {
            type = event.target.value;
        } else {
            $.each(urlParameters(), function(param, value) {
                if (SEARCH_TYPES.includes(param)) {
                    type  = param;
                    query = value;
                }
            });
        }
        // noinspection JSUnusedAssignment
        setSearchType(type, query);
    }

    // ========================================================================
    // Functions - menus
    // ========================================================================

    /**
     * Modify the hidden input parameters of each menu control based on the new
     * search type and search terms.
     *
     * @param {string} [new_type]     Default: {@link searchType}.
     * @param {string} [new_value]    Default: {@link searchTerms}.
     */
    function setMenuParameters(new_type, new_value) {
        const type  = new_type  || searchType();
        const query = new_value || searchTerms();
        $controls.each(function() {
            setHiddenParameters(this, type, query);
        });
    }

    /**
     * Add and/or subtract hidden input parameters from a menu control so that
     * selecting it will result in the proper search URL.
     *
     * @param {Selector} control      Menu control to modify.
     * @param {string}   [new_type]   Default: {@link searchType}.
     * @param {string}   [new_value]  Default: {@link searchTerms}.
     */
    function setHiddenParameters(control, new_type, new_value) {
        const search = new_type  || searchType();
        const query  = new_value || searchTerms();
        let $control, $menu;
        let $this = $(control);
        if ($this.hasClass('menu-control')) {
            $control = $this;
            $menu    = $this.children('select');
        } else {
            $control = $this.parents('.menu-control');
            $menu    = $this;
        }
        const menu_id = $menu.attr('id');
        let $hidden   = $control.find('input[type="hidden"]');
        SEARCH_TYPES.forEach(function(type) {
            let $input = $hidden.filter(`[name="${type}"]`);
            if (isMissing($input)) {
                // noinspection ReuseOfLocalVariableJS
                $input = $('<input type="hidden">');
                $input.attr('name', type);
                $input.attr('id',   `${menu_id}-${type}`);
                $input.appendTo($control);
            }
            $input.val((type === search) ? query : '');
        });
    }

    // ========================================================================
    // Functions - multi-select menus
    // ========================================================================

    /**
     * Initialize Select2 for multi-select menus.
     *
     * @see https://select2.org/configuration/options-api
     * @see https://select2.org/programmatic-control/events
     */
    function initializeMultiSelect() {
        let $select = $multi_select.not('.select2-hidden-accessible');
        if (isPresent($select)) {
            $select.select2({
                width:      '100%',
                allowClear: true,
                debug:      DEBUGGING,
                language:   select2Language()
            });
            $select.each(function() {
                let attrs      = {};
                let $control   = $(this);
                const label    = $control.attr('aria-label');
                const label_id = $control.attr('aria-labelledby');
                if (label)    { attrs['aria-label']      = label; }
                if (label_id) { attrs['aria-labelledby'] = label_id; }
                // noinspection JSCheckFunctionSignatures
                $control.siblings('.select2').find('input').attr(attrs);
            });
            if (DEBUGGING) {
                MULTI_SELECT_EVENTS.forEach(function(type) {
                    handleEvent($select, type, logSelectEvent);
                });
            }
            PRE_CHANGE_EVENTS.forEach(function(type) {
                handleEvent($select, type, updateHiddenParameters);
            });
            POST_CHANGE_EVENTS.forEach(function(type) {
                handleEvent($select, type, updateEvent);
            });
            CHECK_SUPPRESS_MENU_EVENTS.forEach(function(type) {
                handleEvent($select, type, suppressMenuOpen);
            });
        }
    }

    // noinspection FunctionNamingConventionJS
    /**
     * Generate message translations for Select2.
     *
     * @returns {object}
     *
     * @see https://select2.org/i18n
     * @see ../../../node_modules/select2/src/js/select2/i18n/en.js
     */
    function select2Language() {
        const text = { // TODO: I18n
            //errorLoading:    'The results could not be loaded.',
            //inputTooLong:    'Please delete {n} character',
            //inputTooShort:   'Please enter {n} or more characters',
            //loadingMore:     'Loading more results…',
            //maximumSelected: 'You can only select {n} item',
            //noResults:       'No results found',
            //searching:       'Searching…',
            removeAllItems:  'Remove all selected values'
        };
        let translations = {};
        $.each(text, function(name, value) {
            switch (name) {
                case 'inputTooLong':
                    translations[name] =
                        function(args) {
                            const overage = args.input.length - args.maximum;
                            let result    = value.replace(/{n}/, overage);
                            if (overage !== 1) { result += 's'; }
                            return result;
                        };
                    break;
                case 'inputTooShort':
                    translations[name] =
                        function(args) {
                            const remaining = args.minimum - args.input.length;
                            return value.replace(/{n}/, remaining);
                        };
                    break;
                case 'maximumSelected':
                    translations[name] =
                        function(args) {
                            const limit = args.maximum;
                            let result  = value.replace(/{n}/, limit);
                            if (limit !== 1) { result += 's'; }
                            return result;
                        };
                    break;
                default:
                    translations[name] = function() { return value; };
                    break;
            }
        });
        return translations;
    }

    /**
     * Update the hidden query input for the menu from the characters currently
     * in the query input box.
     *
     * This supports the ability for a multi-select menu to be used to modify
     * search results without having to also press "Search".
     *
     * @param {jQuery.Event} event
     */
    function updateHiddenParameters(event) {
        // noinspection JSCheckFunctionSignatures
        setHiddenParameters(event.target);
    }

    /**
     * Cause the current event to be remembered for coordination with the
     * {@link suppressMenuOpen} handler.
     *
     * @param {jQuery.Event} event
     */
    function updateEvent(event) {
        let $target = $(event.target);
        $target.prop('ongoing-event', event.type);
    }

    /**
     * If in the midst of an ongoing event (adding or removing a selection)
     * then suppress the opening of the menu.
     *
     * This way, deselecting a facet selection performs its action without the
     * unnecessary opening-and-closing of the drop down menu.
     *
     * @param {jQuery.Event} event
     */
    function suppressMenuOpen(event) {
        let $target = $(event.target);
        if ($target.prop('ongoing-event')) {
            event.preventDefault();
            event.stopImmediatePropagation();
            $target.removeProp('ongoing-event').select2('close');
        }
    }

    /**
     * Log a Select2 event.
     *
     * @param {jQuery.Event} event
     */
    function logSelectEvent(event) {
        const type   = event.type;
        const spaces = Math.max(0, (MULTI_SELECT_EVENTS_WIDTH - type.length));
        const evt    = type + ' '.repeat(spaces);
        const tgt    = event.target;
        let target   = '';
      //if (tgt.localName) { target += tgt.localName; }
        if (tgt.id)        { target += '#' + tgt.id; }
      //if (tgt.className) { target += '.' + tgt.className; }
      //if (tgt.type)      { target += `[${tgt.type}]`; }
        // noinspection JSCheckFunctionSignatures
        let $selected  = $(tgt).siblings().find('[aria-activedescendant]');
        const selected = $selected.attr('aria-activedescendant');
        if (selected) { target += ' ' + selected; }
        console.log('SELECT2', evt, target);
    }

    // ========================================================================
    // Functions - search overlay
    // ========================================================================

    /**
     * Show the indicator that is presented during a time-consuming search.
     */
    function showInProgress() {
        $search_in_progress.toggleClass('visible', true);
    }

    /**
     * Hide the indicator that is presented during a time-consuming search.
     */
    function hideInProgress() {
        $search_in_progress.toggleClass('visible', false);
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function debug(...args) {
        if (DEBUGGING) { consoleLog(...args); }
    }

});
