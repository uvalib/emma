// app/assets/javascripts/feature/panel.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    var $toggle_buttons = $('.toggle');

    // Only perform these actions on the appropriate pages.
    if (isMissing($toggle_buttons)) {
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

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * Toggle visibility of a toggle button and its panel.
     *
     * @param {Event} event
     */
    function togglePanel(event) {
        var $button = $(event && event.target || this);
        var target  = getPanelSelector($button);
        var $panel  = target && $(target);
        if (isPresent($panel)) {
            var opening = !$panel.hasClass(OPEN_MARKER);
            if (DEBUGGING) {
                debug((opening ? 'SHOW' : 'HIDE') + ' ' + target + ' panel');
            }
            setState(target, opening);
            updatePanelDisplay($button, $panel, opening);
        }
    }

    /**
     * Get the selector for the panel associated with the given button.
     *
     * @param {Selector} selector
     *
     * @return {string|undefined}
     */
    function getPanelSelector(selector) {
        return $(selector).data('selector');
    }

    /**
     * Save the state of advanced search controls in the session.
     *
     * @param {string}         target
     * @param {boolean|string} opening
     */
    function setState(target, opening) {
        var state = opening;
        if (typeof state !== 'string') {
            state = state ? OPEN : CLOSED;
        }
        sessionStorage.setItem(target, state);
    }

    /**
     * Get the state of advanced search controls.
     *
     * @param {string} target
     *
     * @return {string}
     */
    function getState(target) {
        return sessionStorage.getItem(target);
    }

    /**
     * Set the current state of advanced search controls.
     */
    function initializeState() {
        $toggle_buttons.each(function() {
            var $button = $(this);
            var target  = getPanelSelector($button);
            var $panel  = target && $(target);
            if (isMissing($panel)) {
                $button.hide();
            } else {
                var was_open = getState(target);
                var is_open  = $panel.hasClass(OPEN_MARKER) ? OPEN : CLOSED;
                if (was_open !== is_open) {
                    if (was_open === OPEN) {
                        updatePanelDisplay($button, $panel, true);
                    } else if (was_open === CLOSED) {
                        updatePanelDisplay($button, $panel, false);
                    } else {
                        setState(target, is_open);
                    }
                }

            }
        });
    }

    /**
     * Update the advanced search display.
     *
     * @param {jQuery}  $button
     * @param {jQuery}  $panel
     * @param {boolean} opening
     */
    function updatePanelDisplay($button, $panel, opening) {
        updateToggleButton($button, opening);
        $panel.toggleClass(OPEN_MARKER, opening);
    }

    /**
     * Update the advanced search button label.
     *
     * @param {jQuery}  $button
     * @param {boolean} opening
     */
    function updateToggleButton($button, opening) {
        /** @type {{label: string, tooltip: string}} */
        var value = opening ? Emma.Panel.closer : Emma.Panel.opener;
        $button.html(value.label).attr('title', value.tooltip);
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($toggle_buttons, togglePanel);

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
