// app/assets/javascripts/feature/advanced-search.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /**
     * All search sections.
     *
     * @type {jQuery}
     */
    var $search_sections = $('.layout-section.search');

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
     * @constant {boolean}
     */
    var DEBUGGING = true;

    /**
     * State value indicating that advanced search is open.
     *
     * @constant {string}
     */
    var OPEN = 'open';

    /**
     * State value indicating that advanced search is open.
     *
     * @constant {string}
     */
    var CLOSED = 'closed';

    /**
     * Marker class indicating that advanced search is open.
     *
     * @constant {string}
     */
    var OPEN_MARKER = 'open';

    /**
     * Events exposed by Select2.
     *
     * @constant {string[]}
     */
    var MULTI_SELECT_EVENTS = [
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
     * @constant {number}
     *
     * @see logSelectEvent
     */
    var MULTI_SELECT_EVENTS_WIDTH = (function() {
        var max = 0;
        MULTI_SELECT_EVENTS.forEach(function(type) {
            max = Math.max(max, type.length);
        });
        return max;
    })();

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * The advanced-search toggle button.
     *
     * @type {jQuery}
     */
    var $advanced_toggle = $search_sections.find('.advanced-search-toggle');

    /**
     * All instances of the search filter reset button.
     *
     * @type {jQuery}
     */
    var $reset_button = $search_sections.find('.menu-button.reset');

    /**
     * The input box associated with the advanced search toggle.
     *
     * @type {jQuery}
     */
    var $search_input = $('#q');

    /**
     * The input clear button.
     *
     * @type {jQuery}
     */
    var $search_clear = $search_input.siblings('.search-clear');

    /**
     * The search controls container.
     *
     * @type {jQuery}
     */
    var $control_panel = $search_sections.find('.search-controls');

    /**
     * The search control menu <form> elements.
     *
     * @type {jQuery}
     */
    var $controls = $control_panel.find('.menu-control');

    /**
     * Multi-select dropdown menus.
     *
     * @type {jQuery}
     */
    var $multi_select = $controls.find('select[multiple]');

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * Toggle visibility of advanced search controls.
     */
    function toggleAdvancedSearch() {
        var opening = !$control_panel.hasClass(OPEN_MARKER);
        if (DEBUGGING) {
            debug((opening ? 'SHOW' : 'HIDE') + ' advanced search controls');
        }
        setState(opening);
        updateSearchDisplay(opening);
    }

    /**
     * Save the state of advanced search controls in the session.
     *
     * @param {boolean|string} opening
     */
    function setState(opening) {
        var state = opening;
        if (typeof state !== 'string') {
            state = state ? OPEN : CLOSED;
        }
        sessionStorage.setItem('search-controls', state);
    }

    /**
     * Get the state of advanced search controls.
     *
     * @return {string}
     */
    function getState() {
        return sessionStorage.getItem('search-controls');
    }

    /**
     * Set the current state of advanced search controls.
     */
    function initializeState() {
        if (isMissing($control_panel)) {
            $advanced_toggle.hide();
            $reset_button.hide();
        } else {
            var was_open = getState();
            var is_open = $control_panel.hasClass(OPEN_MARKER) ? OPEN : CLOSED;
            if (was_open !== is_open) {
                if (was_open === OPEN) {
                    updateSearchDisplay(true);
                } else if (was_open === CLOSED) {
                    updateSearchDisplay(false);
                } else {
                    setState(is_open);
                }
            }
            initializeMultiSelect();
        }
        updateSearchClearButton();
    }

    /**
     * Update the advanced search display.
     *
     * @param {boolean} opening
     */
    function updateSearchDisplay(opening) {
        updateAdvancedButton(opening);
        updateResetButton(opening);
        $control_panel.toggleClass(OPEN_MARKER, opening);
    }

    /**
     * Update the advanced search button label.
     *
     * @param {boolean} opening
     */
    function updateAdvancedButton(opening) {
        var value = opening ? Emma.AdvSearch.closer : Emma.AdvSearch.opener;
        $advanced_toggle.html(value.label).attr('title', value.tooltip);
    }

    /**
     * Update the search reset button display.
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
    function updateResetButton(opening) {
        $reset_button.each(function() {
            var $button = $(this);
            var manage  = $button.css('--manage-visibility');
            if (isDefined(manage) && (manage.trim() === 'true')) {
                $button.css('visibility', (opening ? 'visible' : 'hidden'));
            }
        });
    }

    /**
     * Do not show the search clear control if this search box is empty.
     */
    function updateSearchClearButton() {
        if ($search_input.val()) {
            $search_clear.css('visibility', 'visible');
        } else {
            $search_clear.css('visibility', 'hidden');
        }
    }

    // ========================================================================
    // Function definitions - multi-select
    // ========================================================================

    /**
     * Select2 events which precede the change which causes a new search to be
     * performed.
     *
     * @constant {string[]}
     */
    var PRE_CHANGE_EVENTS = ['select2:selecting', 'select2:unselecting'];

    /**
     * Select2 events which follow a change which causes a new search to be
     * performed.
     *
     * @constant {string[]}
     */
    var POST_CHANGE_EVENTS = ['select2:select', 'select2:unselect'];

    /**
     * Select2 events which should detect whether to suppress the opening of
     * the drop-down menu.
     *
     * @constant {string[]}
     */
    var CHECK_SUPPRESS_MENU_EVENTS = ['select2:opening'];

    /**
     * Initialize Select2 for multi-select menus.
     *
     * @see https://select2.org/configuration/options-api
     * @see https://select2.org/programmatic-control/events
     */
    function initializeMultiSelect() {
        var $select = $multi_select.not('.select2-hidden-accessible');
        if (isPresent($select)) {
            $select.select2({
                width:      '100%',
                allowClear: true,
                debug:      DEBUGGING,
                language:   select2Language()
            });
            if (DEBUGGING) {
                MULTI_SELECT_EVENTS.forEach(function(type) {
                    handleEvent($select, type, logSelectEvent);
                });
            }
            PRE_CHANGE_EVENTS.forEach(function(type) {
                handleEvent($select, type, updateQuery);
            });
            POST_CHANGE_EVENTS.forEach(function(type) {
                handleEvent($select, type, updateEvent);
            });
            CHECK_SUPPRESS_MENU_EVENTS.forEach(function(type) {
                handleEvent($select, type, suppressMenuOpen);
            });
        }
    }

    /**
     * Generate message translations for Select2.
     *
     * @return {object}
     *
     * @see https://select2.org/i18n
     * @see ../../../node_modules/select2/src/js/select2/i18n/en.js
     */
    function select2Language() {
        var translations = {};
        var text = { // TODO: I18n
            //errorLoading:    'The results could not be loaded.',
            //inputTooLong:    'Please delete {n} character',
            //inputTooShort:   'Please enter {n} or more characters',
            //loadingMore:     'Loading more results…',
            //maximumSelected: 'You can only select {n} item',
            //noResults:       'No results found',
            //searching:       'Searching…',
            removeAllItems:  'Remove all selected values'
        };
        $.each(text, function(name, value) {
            switch (name) {
                case 'inputTooLong':
                    translations[name] =
                        function(args) {
                            var overage = args.input.length - args.maximum;
                            var result  = value.replace(/{n}/, overage);
                            if (overage !== 1) { result += 's'; }
                            return result;
                        };
                    break;
                case 'inputTooShort':
                    translations[name] =
                        function(args) {
                            var remaining = args.minimum - args.input.length;
                            return value.replace(/{n}/, remaining);
                        };
                    break;
                case 'maximumSelected':
                    translations[name] =
                        function(args) {
                            var limit  = args.maximum;
                            var result = value.replace(/{n}/, limit);
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
     * This supports the ability for a multi-select menu to be used without
     * having to also press "Search".
     *
     * @param {Event} e
     */
    function updateQuery(e) {
        var query    = $search_input.val() || '*';
        var name     = 'q';
        var $target  = $(e.target);
        var $control = $target.parents('.menu-control');
        var $hidden  = $control.find('input[name="' + name + '"]');
        if (isMissing($hidden)) {
            $hidden = $('<input type="hidden">');
            $hidden.attr('id',   ($target.attr('id') + '-' + name));
            $hidden.attr('name', name);
            $hidden.appendTo($control);
        }
        $hidden.val(query);
    }

    /**
     * Cause the current event to be remembered for coordination with the
     * {@link suppressMenuOpen} handler.
     *
     * @param {Event} e
     */
    function updateEvent(e) {
        var $target = $(e.target);
        $target.prop('ongoing-event', e.type);
    }

    /**
     * If in the midst of an ongoing event (adding or removing a selection)
     * then suppress the opening of the menu.
     *
     * This way, deselecting a facet selection performs its action without the
     * unnecessary opening-and-closing of the drop down menu.
     *
     * @param {Event} e
     */
    function suppressMenuOpen(e) {
        var $target = $(e.target);
        if ($target.prop('ongoing-event')) {
            e.preventDefault();
            e.stopImmediatePropagation();
            $target.removeProp('ongoing-event').select2('close');
        }
    }

    /**
     * Log a Select2 event.
     *
     * @param {Event} e
     */
    function logSelectEvent(e) {
        var spaces = Math.max(0, (MULTI_SELECT_EVENTS_WIDTH - e.type.length));
        var evt    = e.type + ' '.repeat(spaces);
        var tgt    = e.target;
        var target = '';
        //if (tgt.localName) { target += tgt.localName; }
          if (tgt.id)        { target += '#' + tgt.id; }
        //if (tgt.className) { target += '.' + tgt.className; }
        //if (tgt.type)      { target += '[' + tgt.type + ']'; }
        var $selected = $(tgt).siblings().find('[aria-activedescendant]');
        var selected  = $selected.attr('aria-activedescendant');
        if (selected) { target += ' ' + selected; }
        console.log('SELECT2', evt, target);
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleEvent($search_input, 'keyup', updateSearchClearButton);
    handleClickAndKeypress($advanced_toggle, toggleAdvancedSearch);

    // ========================================================================
    // Actions
    // ========================================================================

    initializeState();

    // ========================================================================
    // Internal functions
    // ========================================================================

    /**
     * Emit a console message if debugging.
     */
    function debug() {
        if (DEBUGGING) {
            consoleLog.apply(null, arguments);
        }
    }

});
