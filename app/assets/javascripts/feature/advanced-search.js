// app/assets/javascripts/feature/advanced-search.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    var $advanced_toggle = $('.advanced-search-toggle');

    // Only perform these actions on the appropriate pages.
    if (isMissing($advanced_toggle)) {
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
     * All search sections.
     *
     * @constant {jQuery}
     */
    var $search_sections = $('.layout-section.search');

    /**
     * The search controls container.
     *
     * @constant {jQuery}
     */
    var $control_panel = $search_sections.find('.search-controls');

    /**
     * All instances of the search filter reset button.
     *
     * @constant {jQuery}
     */
    var $reset_button = $search_sections.find('.menu-button');

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
        }
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
        var text = opening ? ADV_SEARCH_CLOSER_LABEL : ADV_SEARCH_OPENER_LABEL;
        $advanced_toggle.html(text);
    }

    /**
     * Update the search reset button display.
     *
     * Each specific .menu-button element may have custom CSS properties set
     * according to the layout determined by the width of the medium:
     *
     * If '--disabled' is 'true', then this function should not modify the
     *   display or visibility of the element.
     *
     * If '--invisible-when-closed' is set to 'true', then this function should
     *   modify the visibility of the element (toggling between 'visible' and
     *   'hidden').  Otherwise this function modifies the display, toggling
     *   between 'block' and 'none'.
     *
     * @param {boolean} opening
     *
     * @see .layout-section.search.input.menu-button in shared/_header.scss.
     */
    function updateResetButton(opening) {
        $reset_button.each(function() {
            var $button  = $(this);
            var disabled = $button.css('--disabled');
            if (notDefined(disabled) || (disabled.trim() !== 'true')) {
                var css_property, css_value;
                var visibility = $button.css('--invisible-when-closed');
                if (isDefined(visibility) && (visibility.trim() === 'true')) {
                    css_property = 'visibility';
                    css_value    = opening ? 'visible' : 'hidden';
                } else {
                    css_property = 'display';
                    css_value    = opening ? 'block' : 'none';
                }
                $button.css(css_property, css_value);
            }
        });
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    $advanced_toggle
        .off('click', toggleAdvancedSearch)
        .on('click', toggleAdvancedSearch);

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
