// app/assets/javascripts/controllers/search.js


import { AppDebug }               from '../application/debug';
import { appSetup }               from '../application/setup'
import { cloneTitle }             from '../feature/search-analysis';
import { Emma }                   from '../shared/assets';
import { selector, toggleHidden } from '../shared/css';
import { makeUrl, urlParameters } from '../shared/url';
import {
    isDefined,
    isEmpty,
    isMissing,
    notDefined,
} from '../shared/definitions';
import {
    handleClickAndKeypress,
    handleEvent,
} from '../shared/events';


const MODULE = 'Search';
const DEBUG  = false;

AppDebug.file('controllers/search', MODULE, DEBUG);

appSetup(MODULE, function() {

    /**
     * Search page `<body>`.
     *
     * @type {jQuery}
     */
    const $body = $('body.search-index');

    // Only perform these actions on the appropriate pages.
    if (isMissing($body)) {
        return;
    }

    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

    // ========================================================================
    // Constants
    // ========================================================================

    const ITEM_CLASS      = 'search-list-item';
    const TOGGLE_CLASS    = 'toggle';
    const CONTROL_CLASS   = `${TOGGLE_CLASS} for-item`;
    const OPEN_MARKER     = 'open';
    const DISABLED_MARKER = 'disabled';

    /**
     * Selector for item sub-sections.
     *
     * @readonly
     * @type {string}
     */
    const SUBSECTION = '.pair.field-section';
    const ITEM       = selector(ITEM_CLASS);
    const TOGGLE     = selector(TOGGLE_CLASS);
    const CONTROL    = selector(CONTROL_CLASS);
    const OPEN       = selector(OPEN_MARKER);
    const DISABLED   = selector(DISABLED_MARKER);

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * Search list container.
     *
     * @type {jQuery}
     */
    const $item_list = $body.find('.search-list');

    /**
     * Elements of .search-list.
     *
     * @type {jQuery}
     */
    const $list_parts = $item_list.children();

    /**
     * Search list results entries.
     *
     * @type {jQuery}
     */
    const $result_items = $list_parts.filter(ITEM);

    /**
     * Results type selection menu.
     *
     * @type {jQuery}
     */
    const $mode_menu = $('.results.menu-control select');

    /**
     * The current results type ("title" or "file").
     *
     * @type {string}
     */
    const current_mode = $mode_menu.val();

    const FILE_RESULTS  = (current_mode === 'file');
    const TITLE_RESULTS = !FILE_RESULTS;

    // ========================================================================
    // Actions - results type
    // ========================================================================

    handleEvent($mode_menu, 'change', function(event) {
        const $menu    = $(event.currentTarget || event.target);
        const new_mode = $menu.val();
        if (new_mode !== current_mode) {
            const path   = $menu.attr('data-path') || window.location.pathname;
            const params = { ...urlParameters(), results: new_mode };
            window.location.href = makeUrl(path, params);
        }
    });

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Log a console warning if the provided item does not represent a single
     * HTML element.
     *
     * @param {jQuery} $item
     * @param {string} [caller]
     * @param {string} [arg_name]
     *
     * @returns {boolean}
     */
    function onlyOne($item, caller, arg_name) {
        const only_one = ($item.length === 1);
        if (!only_one) {
            const func    = caller   || 'onlyOne';
            const arg     = arg_name || 'selector';
            const problem = $item.length ? 'too many' : 'no';
            OUT.warn(`${func}: ${arg}: ${problem} elements`);
        }
        return only_one;
    }

    /**
     * Make one or more items present as a buttons for title results.
     *
     * @param {Selector} items
     * @param {string}   controls     ID of the element the button controls.
     * @param {boolean}  [open]       Initially expanded (default: **false**).
     *
     * @returns {jQuery}
     */
    function makeButton(items, controls, open) {
        const func   = 'makeButton';
        const $items = $(items);
        const attrs  = {
            role:            'button',
            tabindex:        0,
            'aria-controls': controls,
            'aria-expanded': !!open,
        };
        if (isEmpty(controls)) {
            OUT.error(`${func}: no id for aria-controls`);
        }
        $items.each((_, item) => {
            const $item = $(item);
            for (const [name, value] of Object.entries(attrs)) {
                if (notDefined($item.attr(name))) {
                    $item.attr(name, value);
                }
            }
        });
        return $items;
    }

    // ========================================================================
    // Functions - collapsible items
    // ========================================================================

    /**
     * Mark a collapsible element as open/closed.
     *
     * @param {Selector} element
     * @param {boolean}  [open]       If **false**, mark as closed.
     */
    function markAsOpen(element, open) {
        const is_open = notDefined(open) || open;
        $(element).toggleClass(OPEN_MARKER, is_open);
    }

    /**
     * Toggle visibility of the associated list item.
     *
     * @param {jQuery.Event|UIEvent} event
     * @param {boolean}              [open]
     */
    function toggleItem(event, open) {
        /** @type {jQuery} */
        const $target = $(event.currentTarget || event.target);
        let $item, $number;
        if ($target.is(CONTROL)) {
            $number  = $target.parents('.number');
            $item    = $number.next();
        } else if ($target.is(ITEM)) {
            $item    = $target;
            $number  = $item.prev();
        } else {
            $item    = $target.parents(ITEM);
            $number  = $item.prev();
        }

        /** @type {jQuery} */
        const $children = $item.children();
        const $title    = $children.filter('.field-Title').find('.title');
        const $contents = $children.not('.field-Title');
        const $controls = $number.find(CONTROL);
        const opening   = isDefined(open) ? open : !$item.is(OPEN);

        markAsOpen($item, opening);
        markAsOpen($title, opening);
        markAsVisible($contents, opening);

        if (opening) {
            const $sections = $contents.filter(SUBSECTION);
            $sections.each((_, section) => updateSectionOpenClosed(section));
        }

        updateControl($controls, $number, opening);
    }

    /**
     * Set the control to indicate whether the element it controls is expanded
     * and change its attributes to indicate that its function is to reverse
     * that state.
     *
     * @param {jQuery}  $control
     * @param {jQuery}  [$container]
     * @param {boolean} [open]          Default: `$control.is(OPEN)`.
     */
    function updateControl($control, $container, open) {
        const is_open = isDefined(open) ? open : $control.is(OPEN);
        if ($container) {
            markAsOpen($container, is_open);
            markAsOpen($container.find('button,[role="button"]'), is_open);
        }
        const config = is_open ? Emma.Tree.closer : Emma.Tree.opener;
        $control.text(config.label);
        $control.attr('title', config.tooltip);
        $control.attr('aria-expanded', is_open);
        return $control;
    }

    /**
     * Create a new open/close toggle control.
     *
     * @param {number}  row
     * @param {string}  target
     * @param {boolean} [open]        If **true**, start in the open state.
     *
     * @returns {jQuery}
     */
    function createToggleControl(row, target, open) {
        const is_open  = !!open;
        const $control = $('<button>');
        $control.addClass(`${CONTROL_CLASS} ${row}`);
        $control.toggleClass(OPEN_MARKER, is_open);
        $control.attr('type',          'button');
        $control.attr('data-row',      `.${row}`);
        $control.attr('aria-controls', target);
        return updateControl($control);
    }

    /**
     * Create and assign event handlers for a pair of open/close controls
     * (one for "wide" and "medium" screens; the other for "narrow" screens).
     *
     * NOTE: probably the controls should be in the generated HTML, along with
     *  the setting of *data-row* so that this code only has to attach the
     *  event handlers.
     *
     * @param {Selector} parent
     */
    function setupToggleControl(parent) {
        const func    = 'setupControl';
        const $number = $(parent);
        if (!onlyOne($number, func, 'number')) {
            return;
        }

        const classes = $number[0].classList;
        const row     = $.map(classes, cls => cls.match(/^row-\d+$/)).pop();
        if (isEmpty(row)) {
            OUT.warn(`${func}: could not determine row for ${classes}`);
            return;
        }

        // Find or create the toggle control visible for wide and
        // medium-width screens.
        /** @type {jQuery} */
        const $children   = $number.children();
        let $wide_control = $children.filter(CONTROL);
        if (isMissing($wide_control)) {
            const $item   = $number.next();
            const target  = $item.attr('id');
            $wide_control = createToggleControl(row, target).appendTo($number);
        }
        handleClickAndKeypress($wide_control, toggleItem);

        // Find or create the toggle control visible for narrow screens.
        const $container    = $children.filter('.container');
        let $narrow_control = $container.find(CONTROL);
        if (isMissing($narrow_control)) {
            $narrow_control = $wide_control.clone().appendTo($container);
        }
        handleClickAndKeypress($narrow_control, toggleItem);
    }

    // ========================================================================
    // Actions - collapsible items
    // ========================================================================

    // Create and setup item display toggle controls.
    $list_parts.filter('.number').each((_, num) => setupToggleControl(num));

    $result_items.each((_, item) => {
        const $item = $(item);
        const id    = item.id;

        // Make clicking on the title toggle the display of that item.
        let title_id, $title = $item.find('.value.field-Title .title');
        if (TITLE_RESULTS) {
            title_id = `title_${id}`;
            $title.attr('id', title_id);
        } else if ($title.length > 1) {
            title_id = $title.filter('[data-mode="txt"]').attr('id');
            $title   = $title.filter('[data-mode="btn"]');
        } else if (Emma.SEARCH_ANALYSIS) {
            title_id = cloneTitle($item, $title);
        }
        $title = makeButton($title, id);
        handleClickAndKeypress($title, toggleItem);

        // Make the item's title present as the label for the number.
        const $number = $item.prev();
        $number.attr('aria-labelledby', title_id);
    });

    // ========================================================================
    // Functions - collapsible sections
    // ========================================================================

    /**
     * Mark previously-hidden element(s) as visible.
     *
     * @param {Selector} element
     * @param {boolean}  [visible]    If **false**, make hidden.
     */
    function markAsVisible(element, visible) {
        const $element = $(element).not(DISABLED);
        const hidden   = (visible === false);
        toggleHidden($element, hidden);
    }

    /**
     * Mark section elements as visible.
     *
     * @param {Selector} section
     * @param {boolean}  [visible]    If **false**, make hidden.
     */
    function markSectionVisible(section, visible) {
        const $section  = $(section).not(DISABLED);
        const $elements = getSection($section);
        markAsVisible($elements, visible);
    }

    /**
     * Update the open/closed state of a sub-section. <p/>
     *
     * **Usage Notes** <p/>
     * This function expects that "section" resolves to a single HTML element
     * unless "open" is provided.
     *
     * @param {Selector} section
     * @param {Selector} [toggle]
     * @param {boolean}  [open]       Default: current section open state.
     */
    function updateSectionOpenClosed(section, toggle, open) {
        const func     = 'updateSectionOpenClosed';
        const $section = $(section);
        let is_open;
        if (isDefined(open)) {
            is_open = open;
        } else if (onlyOne($section, func, 'section')) {
            is_open = $section.is(OPEN);
        } else {
            return;
        }
        markAsOpen($section.children(), is_open);
        markSectionVisible($section, is_open);
        const $t = toggle ? $(toggle) : $section.find(TOGGLE).not('.for-item');
        updateControl($t, $section, is_open);
    }

    /**
     * Toggle open/closed state of the associated item sub-section.
     *
     * @param {jQuery.Event|UIEvent} event
     * @param {boolean}              [open]     Def: opposite state.
     */
    function toggleSection(event, open) {
        const $tgt    = $(event.currentTarget || event.target);
        const $toggle = $tgt.is(TOGGLE) ? $tgt : $tgt.siblings(TOGGLE);
        const id      = $toggle.attr('aria-controls');
        const $sect   = id ? $(`#${id}`) : $toggle.parents(SUBSECTION).first();
        const opening = isDefined(open) ? open : !$sect.is(OPEN);
        markAsOpen($sect, opening);
        updateSectionOpenClosed($sect, $toggle, opening);
    }

    /**
     * Get the set of elements controlled by the tree control at the given
     * element.
     *
     * @param {Selector} section
     *
     * @returns {jQuery}    Section contents (empty for file results).
     */
    function getSection(section) {
        const lines = [];
        $(section).each((_, sec) => {
            const $section = $(sec);
            const classes  = $section[0].classList;
            const this_row = $.map(classes, c => c.match(/^row-\d+$/)).pop();
            const related  = sectionSelector($section);
            const $lines   = $section.siblings(related).not(`.${this_row}`);
            lines.push(...$lines.toArray());
        });
        return $(lines);
    }

    /**
     * Build a string for use as a selector to match all of the lines related
     * to the given item.
     *
     * @param {Selector} item
     *
     * @returns {string}
     */
    function sectionSelector(item) {
        let v;
        const $item = $(item);
        const attrs = ['data-part', 'data-format', 'data-file'];
        return attrs.map(a => (v = $item.attr(a)) && `[${a}="${v}"]`).join('');
    }

    // ========================================================================
    // Actions - collapsible sections
    // ========================================================================

    $result_items.each((_, item) => {
        const $item = $(item);

        // Ensure that open/closed items have the right CSS marker classes
        // ARIA attributes.
        /** @type {jQuery} */
        const $sections = $item.children(SUBSECTION);
        const is_open   = $item.is(OPEN);
        markSectionVisible($sections, is_open);

        // Make clicking on sub-section toggles and associated labels
        // open/close that sub-section, but hide toggles/labels which are not
        // actually part of the item display.
        $sections.find(TOGGLE).not('.for-item').each((_, toggle) => {
            const $toggle = $(toggle);
            const $label  = $toggle.parent();
            if ($label.attr('data-value')) {
                const target = $toggle.attr('aria-controls');
                const $text  = makeButton($toggle.siblings('.text'), target);
                handleClickAndKeypress($text,   toggleSection);
                handleClickAndKeypress($toggle, toggleSection);
            } else {
                const $section = $label.parent();
                markAsVisible($section, false);
                $section.toggleClass(DISABLED_MARKER, true);
            }
        });
    });

});
