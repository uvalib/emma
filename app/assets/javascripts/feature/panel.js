// app/assets/javascripts/feature/panel.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    let $toggle_buttons = $('.toggle.for-panel').not('.for-example');

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
     * @constant
     * @type {boolean}
     */
    const DEBUGGING = true;

    /**
     * If *true*, save the open/closed state of panels to session storage and
     * restore the state when returning to the page.
     *
     * @type {boolean}
     */
    const RESTORE_PANEL_STATE = false;

    /**
     * State value indicating that the panel is displayed.
     *
     * @constant
     * @type {string}
     */
    const OPEN = 'open';

    /**
     * State value indicating that the panel is hidden.
     *
     * @constant
     * @type {string}
     */
    const CLOSED = 'closed';

    /**
     * Marker class indicating that the panel is displayed.
     *
     * @constant
     * @type {string}
     */
    const OPEN_MARKER = 'open';

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($toggle_buttons, onTogglePanel);

    // ========================================================================
    // Actions
    // ========================================================================

    initializeState();

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Toggle visibility of a toggle button and its panel.
     *
     * @param {jQuery.Event} event
     */
    function onTogglePanel(event) {
        let $button = $(event?.target || this);
        let $panel  = getPanel($button);
        if (isPresent($panel)) {
            const opening = !$panel.hasClass(OPEN_MARKER);
            if (DEBUGGING) {
                const action = opening ? 'SHOW' : 'HIDE';
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
     * @returns {jQuery|undefined}
     */
    function getPanel(button) {
        const panel = getPanelId(button);
        return panel && $('#' + panel);
    }

    /**
     * Get the ID for the panel associated with the given button.
     *
     * @param {Selector} button
     *
     * @returns {string|undefined}
     */
    function getPanelId(button) {
        return $(button).attr('aria-controls');
    }

    /**
     * Get the selector for the panel associated with the given button.
     *
     * @param {Selector} button
     *
     * @returns {string|undefined}
     */
    function getPanelSelector(button) {
        let $button = $(button);
        return $button.data('selector') || ('#' + getPanelId($button));
    }

    /**
     * Save the state of the panel in the session.
     *
     * @param {string|Selector} target
     * @param {boolean|string}  opening
     */
    function setState(target, opening) {
        let panel = target;
        let state = opening;
        if (typeof panel !== 'string') { panel = getPanelSelector(panel); }
        if (typeof state !== 'string') { state = state ? OPEN : CLOSED; }
        sessionStorage.setItem(panel, state);
    }

    /**
     * Get the state of the panel.
     *
     * @param {string|Selector} target
     *
     * @returns {string}
     */
    function getState(target) {
        let panel = target;
        if (typeof panel !== 'string') { panel = getPanelSelector(panel); }
        return sessionStorage.getItem(panel);
    }

    /**
     * Set the current state of panel(s) on the page.
     */
    function initializeState() {
        $toggle_buttons.each(function() {
            let $button = $(this);
            let $panel  = getPanel($button);
            if (isMissing($panel)) {
                $button.hide();
            } else if (RESTORE_PANEL_STATE) {
                const selector = getPanelSelector($button);
                const was_open = getState(selector);
                const is_open  = $panel.hasClass(OPEN_MARKER) ? OPEN : CLOSED;
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
        const value = opening ? Emma.Panel.closer : Emma.Panel.opener;
        $button.html(value.label);
        $button.attr('title', value.tooltip);
        $button.attr('aria-expanded', opening);
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
