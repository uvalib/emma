// app/assets/javascripts/feature/advanced-search.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    var $toggle = $('.advanced-search-toggle');

    // Only perform these actions on the appropriate pages.
    if (isMissing($toggle)) {
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
     * CSS class for the search controls container.
     *
     * @constant {jQuery}
     */
    var $controls = $('.search-controls');

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * Toggle visibility of advanced search controls.
     *
     * @returns {boolean}             Menu visibility.
     */
    function toggleAdvancedSearch() {
        if (DEBUGGING) {
            var change = $controls.hasClass('open') ? 'HIDE' : 'SHOW';
            debug(change + ' advanced search controls');
        }
        $controls.toggleClass('open');
        var now_open = $controls.hasClass('open');
        setState(now_open);
        updateButton(now_open);
        return now_open;
    }

    /**
     * Update the advanced search button label.
     *
     * @param {boolean} now_open
     */
    function updateButton(now_open) {
        var label;
        if (now_open) {
            label = ADVANCED_SEARCH_CLOSER_LABEL;
        } else {
            label = ADVANCED_SEARCH_OPENER_LABEL;
        }
        $toggle.html(label);
    }

    /**
     * Save the state of advanced search controls in the session.
     *
     * @param {string|boolean} is_open
     */
    function setState(is_open) {
        var state;
        if (typeof is_open === 'boolean') {
            state = is_open ? 'open' : 'closed';
        } else {
            state = is_open;
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
        if (isPresent($controls)) {
            var was_open = getState();
            var is_open  = $controls.hasClass('open') ? 'open' : 'closed';
            if (was_open !== is_open) {
                if (was_open === 'open') {
                    $controls.addClass('open');
                    updateButton(true);
                } else if (was_open === 'closed') {
                    $controls.removeClass('open');
                    updateButton(false);
                } else {
                    setState(is_open);
                }
            }
            $toggle.show();
        } else {
            $toggle.hide();
        }
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    $toggle
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
