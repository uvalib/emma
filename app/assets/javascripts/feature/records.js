// app/assets/javascripts/feature/records.js


import { delegateInputClick, toggleVisibility } from '../shared/accessibility'
import { Emma }                                 from '../shared/assets'
import { pageController }                       from '../shared/controller'
import { isMissing, isPresent }                 from '../shared/definitions'
import { camelCase, singularize }               from '../shared/strings'
import { asParams }                             from '../shared/url'
import {
    handleEvent,
    handleHoverAndFocus,
    isEvent,
} from '../shared/events'


$(document).on('turbolinks:load', function() {

    /**
     * Current controller.
     *
     * @readonly
     * @type {string}
     */
    const CONTROLLER = pageController();

    /**
     * Base name (singular of the related database table).
     *
     * @readonly
     * @type {string}
     */
    const MODEL = singularize(CONTROLLER);

    /**
     * Controller assets.js properties.
     *
     * @readonly
     * @type {ModelProperties}
     */
    const CONTROLLER_PROPERTIES = Emma[camelCase(MODEL)];

    /**
     * Page assets.js properties.
     *
     * @readonly
     * @type {RecordProperties}
     */
    const PROPERTY = CONTROLLER_PROPERTIES?.Record;

    /**
     * The element containing the submission workflow state select controls.
     *
     * @type {jQuery}
     */
    let $group_select_panel = PROPERTY && $(`.${PROPERTY.GroupPanel.class}`);

    /**
     * The element containing the submission list filter controls.
     *
     * @type {jQuery}
     */
    let $list_filter_panel = PROPERTY && $(`.${PROPERTY.ListFilter.class}`);

    // Only perform these actions on the appropriate pages.
    if (isMissing($group_select_panel) && isMissing($list_filter_panel)) {
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @readonly
     * @type {boolean}
     */
    const DEBUGGING = false;

    // ========================================================================
    // Variables - group select
    // ========================================================================

    /**
     * Buttons which change the set of records displayed based on workflow
     * state group.
     *
     * @type {jQuery}
     */
    let $group_select_links =
        $group_select_panel.find(`.${PROPERTY.GroupPanel.Control.class}`);

    /**
     * An element which receives a description of the state group button being
     * hovered over or focused on.
     *
     * @type {jQuery}
     */
    let $group_select_note = $group_select_panel.find('.note-tray .note');

    // ========================================================================
    // Variables - list filter
    // ========================================================================

    /**
     * The workflow state group controls (each is an element containing a radio
     * button and a label).
     *
     * @type {jQuery}
     */
    let $list_filter_controls =
        $list_filter_panel.find(`.${PROPERTY.ListFilter.Control.class}`);

    /**
     * Radio buttons which cause the set of displayed records to be filtered.
     *
     * @type {jQuery}
     */
    let $list_filter_radio_buttons =
        $list_filter_controls.find('input[type="radio"]');

    // ========================================================================
    // Variables - filter options
    // ========================================================================

    /**
     * The container for $filter_options checkboxes.
     *
     * @type {jQuery}
     */
    let $filter_options_panel = $(`.${PROPERTY.FilterOptions.class}`);

    /**
     * The filter option controls (each is an element containing a checkbox and
     * label).
     *
     * @type {jQuery}
     */
    let $filter_options_controls =
        $filter_options_panel.find(`.${PROPERTY.FilterOptions.Control.class}`);

    /**
     * The debug-only checkboxes to enable/disable the presence of
     * filter buttons manually.
     *
     * @type {jQuery}
     */
    let $filter_options_checkboxes =
        $filter_options_controls.find('input[type="checkbox"]');

    // ========================================================================
    // Variables - records list
    // ========================================================================

    /**
     * The container for the list of displayed records.
     *
     * @type {jQuery}
     */
    let $record_list = $(`.${PROPERTY.List.class}`);

    /**
     * The record list elements actually related to record display (not
     * including top- and bottom-page controls for example).
     *
     * @type {jQuery}
     */
    let $record_lines = $record_list.children(`.number, .${MODEL}-list-item`);

    /**
     * The record list elements that are shown when there are no records.
     * (One element fills the ".number" column with a blank.)
     *
     * @type {jQuery}
     */
    const $no_record_lines = $record_list.children('.no-records');

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * The group specified through URL parameters.
     *
     * @returns {string|undefined}
     */
    function requestedStateGroup() {
        return asParams(window.location).group;
    }

    /**
     * Get the highest-priority workflow state group represented by the given
     * elements.
     *
     * @param {string[]} [group_list]   Default: PROPERTY.StateGroup.
     * @param {Selector} [match]        Default: $record_lines.
     *
     * @returns {string|undefined}
     */
    function defaultStateGroup(group_list, match) {
        const groups  = group_list || PROPERTY.StateGroup;
        let $elements = (match ? $(match) : $record_lines).filter(':visible');
        let result    = undefined;
        // noinspection FunctionWithInconsistentReturnsJS
        $.each(groups, function(_, group) {
            if ($elements.has(`[data-group="${group}"]`)) {
                result = group;
                return false; // break loop
            }
        });
        return result;
    }

    // ========================================================================
    // Functions - state group selection
    // ========================================================================

    /**
     * Display a description of the workflow state group button of interest
     * within the element dedicated to that purpose.
     *
     * @param {SelectorOrEvent} ev
     */
    function showGroupNote(ev) {
        let target   = isEvent(ev) ? (ev.currentTarget || ev.target) : ev;
        let $target  = $(target);
        const indent = $target.position().left;
        const text   = $target.attr('aria-label') || $target.attr('title');
        $group_select_note.css('margin-left', indent);
        $group_select_note.text(text);
        toggleVisibility($group_select_note, true);
    }

    /**
     * Hide the workflow state group button description when none is hovered
     * over or focused on.
     */
    function hideGroupNote() {
        $group_select_note.html('&nbsp;'); // Keep filled to maintain height.
        toggleVisibility($group_select_note, false);
    }

    // ========================================================================
    // Functions - list filter
    // ========================================================================

    /**
     * The current record filtering selection.
     *
     * @returns {string}
     */
    function listFilterCurrent() {
        return $list_filter_radio_buttons.filter(':checked').val();
    }

    /**
     * Update the current record filtering selection (and trigger a change to
     * the displayed set of records).
     *
     * @param {string}   [new_group]
     */
    function listFilterSelect(new_group) {
        let $buttons = $list_filter_radio_buttons.filter(':visible');
        let group    = new_group;
        group ||= requestedStateGroup();
        group ||= defaultStateGroup($buttons.map((_, button) => button.value));
        group ||= 'done';
        $buttons.filter(`[value="${group}"]`).prop('checked', true).change();
    }

    /**
     * Update the displayed set of records based on state group.
     *
     * @param {string|null} [new_group]     Default {@link listFilterCurrent}
     *
     * @see "BaseCollectionDecorator::List#list_filter"
     */
    function filterPageDisplay(new_group) {
        const func  = 'filterPageDisplay';
        const group = new_group || listFilterCurrent();
        _debug(`${func}: arg = "${new_group}"; group = "${group}"`);
        if (group === 'all') {
            filterPageDisplayAll();
        } else {
            filterPageDisplayOnly(`[data-group="${group}"]`);
        }
    }

    /**
     * Show all records regardless of workflow state.
     */
    function filterPageDisplayAll() {
        $record_lines.show();
        $no_record_lines.hide();
    }

    /**
     * Show only the matching records.
     *
     * @param {Selector} match        Selector for visible records.
     */
    function filterPageDisplayOnly(match) {
        let $records = $record_lines.hide();
        let $visible = $records.filter(match);
        if (isPresent($visible)) {
            $visible.show();
            $no_record_lines.hide();
        } else {
            $no_record_lines.show();
        }
    }

    // ========================================================================
    // Functions - list filter
    // ========================================================================

    /**
     * Set the value and state of the "ALL_FILTERS" checkbox and return with
     * an indication of whether any filter radio buttons should be displayed.
     *
     * @returns {boolean}
     */
    function initializeFilterOptions() {
        let all;
        let checked   = 0;
        let unchecked = 0;
        $filter_options_checkboxes.each(function() {
            let $checkbox = $(this);
            if ($checkbox.val() === 'ALL_FILTERS') {
                all = this;
            } else if ($checkbox.is(':checked')) {
                checked++;
            } else {
                unchecked++;
            }
        });
        if (all) {
            all.checked       = !!(checked && !unchecked);
            all.indeterminate = !!(checked && unchecked);
        }
        return !!checked;
    }

    /**
     * If the checkbox is checked, show the matching filter radio button;
     * if the checkbox is unchecked, hide the matching filter radio button.
     *
     * @param {Selector} checkbox
     *
     * @see "BaseCollectionDecorator::List#list_filter_options"
     */
    function filterOptionToggle(checkbox) {
        const func    = 'filterOptionToggle';
        let $checkbox = $(checkbox);
        const enable  = $checkbox.is(':checked');
        const group   = $checkbox.val();
        _debug(`${func}: group = "${group}"; enable = "${enable}"`);
        let $sel_controls, $pag_controls, any_checked;
        if (group === 'ALL_FILTERS') {
            $filter_options_checkboxes.each(function() {
                let $checkbox = $(this);
                if ($checkbox.val() === 'ALL_FILTERS') {
                    // noinspection JSUnusedGlobalSymbols
                    this.indeterminate = false;
                } else {
                    $checkbox.prop('checked', enable);
                }
            });
            $sel_controls = $group_select_links;
            $pag_controls = $list_filter_controls;
            any_checked   = enable;
        } else {
            const only    = `[data-group="${group}"]`;
            $sel_controls = $group_select_links.filter(only);
            $pag_controls = $list_filter_controls.filter(only);
            any_checked   = initializeFilterOptions();
        }
        $sel_controls.toggleClass('hidden', !enable);
        $pag_controls.toggleClass('hidden', !enable);
        $list_filter_panel.toggleClass('hidden', !any_checked);
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function _debug(...args) {
        if (DEBUGGING) { console.log(...args); }
    }

    // ========================================================================
    // Actions
    // ========================================================================

    // Broaden click targets for radio buttons and checkboxes that are paired
    // with labels.
    $list_filter_controls.each((_, ctrl) => delegateInputClick(ctrl));
    $filter_options_controls.each((_, ctrl) => delegateInputClick(ctrl));

    // Listen for a change to the record filter selection.
    handleEvent($list_filter_radio_buttons, 'change', (event) => {
        const $target = $(event.target);
        if ($target.is(':checked')) {
            filterPageDisplay($target.val());
        }
    });

    // Listen for a change to the debug-only filter options checkboxes.
    handleEvent($filter_options_checkboxes, 'change', (event) => {
        filterOptionToggle(event.target);
    });

    // When hovering/focusing on a group selection button, display its
    // description below the group selection panel.
    handleHoverAndFocus($group_select_links, showGroupNote, hideGroupNote);

    // Initialize controls and the initial record filtering.
    initializeFilterOptions();
    if ($list_filter_panel.is(':visible')) {
        listFilterSelect();
    } else {
        filterPageDisplayAll();
    }

});
