// app/assets/javascripts/feature/panel.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    var $toggle_buttons = $('.toggle').not('.for-help');

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
     * State value indicating that the panel is displayed.
     *
     * @constant {string}
     */
    var OPEN = 'open';

    /**
     * State value indicating that the panel is hidden.
     *
     * @constant {string}
     */
    var CLOSED = 'closed';

    /**
     * Marker class indicating that the panel is displayed.
     *
     * @constant {string}
     */
    var OPEN_MARKER = 'open';

    /**
     * If *true*, save the open/closed state of panels to session storage and
     * restore the state when returning to the page.
     *
     * @type {boolean}
     */
    var RESTORE_PANEL_STATE = false;

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
        var $panel  = getPanel($button);
        if (isPresent($panel)) {
            var opening = !$panel.hasClass(OPEN_MARKER);
            if (DEBUGGING) {
                var action = opening ? 'SHOW' : 'HIDE';
                debug(action, getPanelId($button), 'panel');
            }
            if (RESTORE_PANEL_STATE) {
                setState($button, opening);
            }
            updatePanelDisplay($button, $panel, opening);
        }
    }

    /**
     * Get the panel associated with the given button.
     *
     * @param {Selector} button
     *
     * @return {jQuery|undefined}
     */
    function getPanel(button) {
        var panel = getPanelId(button);
        return panel && $('#' + panel);
    }

    /**
     * Get the ID for the panel associated with the given button.
     *
     * @param {Selector} button
     *
     * @return {string|undefined}
     */
    function getPanelId(button) {
        return $(button).attr('aria-controls');
    }

    /**
     * Get the selector for the panel associated with the given button.
     *
     * @param {Selector} button
     *
     * @return {string|undefined}
     */
    function getPanelSelector(button) {
        var $button = $(button);
        return $button.data('selector') || ('#' + getPanelId($button));
    }

    /**
     * Save the state of the panel in the session.
     *
     * @param {string|Selector} target
     * @param {boolean|string}  opening
     */
    function setState(target, opening) {
        var panel = target;
        var state = opening;
        if (typeof panel !== 'string') { panel = getPanelSelector(panel); }
        if (typeof state !== 'string') { state = state ? OPEN : CLOSED; }
        sessionStorage.setItem(panel, state);
    }

    /**
     * Get the state of the panel.
     *
     * @param {string|Selector} target
     *
     * @return {string}
     */
    function getState(target) {
        var panel = target;
        if (typeof panel !== 'string') { panel = getPanelSelector(panel); }
        return sessionStorage.getItem(panel);
    }

    /**
     * Set the current state of panel(s) on the page.
     */
    function initializeState() {
        $toggle_buttons.each(function() {
            var $button = $(this);
            var $panel  = getPanel($button);
            if (isMissing($panel)) {
                $button.hide();
            } else if (RESTORE_PANEL_STATE) {
                var selector = getPanelSelector($button);
                var was_open = getState(selector);
                var is_open  = $panel.hasClass(OPEN_MARKER) ? OPEN : CLOSED;
                if (was_open !== is_open) {
                    if (was_open === OPEN) {
                        updatePanelDisplay($button, $panel, true);
                    } else if (was_open === CLOSED) {
                        updatePanelDisplay($button, $panel, false);
                    } else {
                        setState(selector, is_open);
                    }
                }
            }
        });
    }

    /**
     * Update the toggle panel display.
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
     * Update the toggle button label.
     *
     * @param {jQuery}  $button
     * @param {boolean} opening
     */
    function updateToggleButton($button, opening) {
        /** @type {{label: string, tooltip: string}} */
        var value = opening ? Emma.Panel.closer : Emma.Panel.opener;
        $button.html(value.label);
        $button.attr('title', value.tooltip);
        $button.attr('aria-expanded', opening);
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
