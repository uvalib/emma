// app/assets/javascripts/controllers/search.js


import { Emma }                                from '../shared/assets'
import { handleClickAndKeypress, handleEvent } from '../shared/events'
import { makeUrl, urlParameters }              from '../shared/url'
import { selector }                            from '../shared/css'
import {
    isDefined,
    isEmpty,
    isMissing,
    notDefined,
} from '../shared/definitions'
import { cloneTitle } from '../feature/search-analysis'


$(document).on('turbolinks:load', function() {

    /**
     * Search page <body>.
     *
     * @type {jQuery}
     */
    let $body = $('body.search-index');

    // Only perform these actions on the appropriate pages.
    if (isMissing($body)) {
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    const ITEM_CLASS       = 'search-list-item';
    const ITEM_SELECTOR    = selector(ITEM_CLASS);

    const CONTROL_CLASS    = 'toggle for-item';
    const CONTROL_SELECTOR = selector(CONTROL_CLASS);

    /**
     * Selector for item sub-sections.
     *
     * @constant
     * @type {string}
     */
    const SUBSECTION_SELECTOR = '.pair.field-section';

    /**
     * Marker class indicating that the list item should be fully displayed.
     *
     * @constant
     * @type {string}
     */
    const OPEN_MARKER = 'open';

    /**
     * Marker class indicating that an element should not be visible.
     *
     * @constant
     * @type {string}
     */
    const HIDDEN_MARKER = 'hidden';

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * Search list container.
     *
     * @type {jQuery}
     */
    let $item_list = $body.find('.search-list');

    /**
     * Elements of .search-list.
     *
     * @type {jQuery}
     */
    let $list_parts = $item_list.children();

    /**
     * Search list results entries.
     *
     * @type {jQuery}
     */
    let $result_items = $list_parts.filter(ITEM_SELECTOR);

    /**
     * Results type selection menu.
     *
     * @type {jQuery}
     */
    let $mode_menu = $('.results.menu-control select');

    /**
     * The current results type ('title' or 'file').
     *
     * @type {string}
     */
    let current_mode = $mode_menu.val();

    const FILE_RESULTS  = (current_mode === 'file');
    const TITLE_RESULTS = !FILE_RESULTS;

    // ========================================================================
    // Actions - results type
    // ========================================================================

    handleEvent($mode_menu, 'change', function(event) {
        let $menu = $(event.currentTarget || event.target || event);
        const new_mode = $menu.val();
        if (new_mode !== current_mode) {
            const path   = $menu.attr('data-path') || window.location.pathname;
            const params = $.extend(urlParameters(), { results: new_mode });
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
        if ($item.length === 1) {
            return true;
        }
        const func    = caller   || 'onlyOne';
        const arg     = arg_name || 'selector';
        const problem = $item.length ? 'too many' : 'no';
        console.warn(`${func}: ${arg}: ${problem} elements`);
        return false;
    }

    /**
     * Make one or more items present as a buttons for title results.
     *
     * @param {Selector} items
     * @param {string}   [controls]     ID of the element the button controls.
     *
     * @returns {jQuery}
     */
    function makeButton(items, controls) {
        let $items  = $(items);
        const attrs = {
            role:            'button',
            tabindex:        0,
            'aria-controls': controls
        };
        $items.each(function() {
            let $item = $(this);
            $.each(attrs, function(name, value) {
                if (notDefined($item.attr(name))) {
                    $item.attr(name, value);
                }
            });
        });
        return $items;
    }

    // ========================================================================
    // Functions - collapsible items
    // ========================================================================

    /**
     * Mark a collapsible element as open.
     *
     * @param {Selector} element
     * @param {boolean}  [aria]
     */
    function markAsOpen(element, aria) {
        let $element = $(element);
        $element.addClass(OPEN_MARKER);
        if (aria !== false) {
            updateOpenClosed($element);
        }
    }

    /**
     * Mark a collapsible element as closed.
     *
     * @param {Selector} element
     * @param {boolean}  [aria]
     */
    function markAsClosed(element, aria) {
        let $element = $(element);
        $element.removeClass(OPEN_MARKER);
        if (aria !== false) {
            updateOpenClosed($element);
        }
    }

    /**
     * Mark elements with the proper ARIA attribute based on the presence of
     * {@link OPEN_MARKER}.
     *
     * @param {Selector} element
     */
    function updateOpenClosed(element) {
        let $element   = $(element);
        const expanded = $element.hasClass(OPEN_MARKER);
        $element.attr('aria-expanded', expanded);
    }

    /**
     * Collapse a search results item.
     *
     * @param {Selector} item
     * @param {Selector} [number]
     *
     * == Usage Notes
     * This function expects that "item" resolves to a single HTML element.
     */
    function closeItem(item, number) {
        // noinspection DuplicatedCode
        const func = 'closeItem';
        let $item  = $(item);

        if (!onlyOne($item, func, 'item')) { return }

        /** @type {jQuery} */
        let $children = $item.children();
        let $title    = $children.filter('.field-Title').find('.title');
        let $contents = $children.not('.field-Title');

        markAsClosed($item);
        markAsClosed($title);
        markAsHidden($contents);

        let $number   = number ? $(number) : $item.prev();
        let $controls = $number.find(CONTROL_SELECTOR);

        openerControl($controls, $number);
    }

    /**
     * Expand a search results item.
     *
     * @param {Selector} item
     * @param {Selector} [number]
     *
     * == Usage Notes
     * This function expects that "item" resolves to a single HTML element.
     */
    function openItem(item, number) {
        // noinspection DuplicatedCode
        const func = 'openItem';
        let $item  = $(item);

        if (!onlyOne($item, func, 'item')) { return }

        /** @type {jQuery} */
        let $children = $item.children();
        let $title    = $children.filter('.field-Title').find('.title');
        let $contents = $children.not('.field-Title');

        markAsOpen($item);
        markAsOpen($title);
        markAsVisible($contents);
        $contents.filter(SUBSECTION_SELECTOR).each(function() {
            updateSectionOpenClosed(this);
        });

        let $number   = number ? $(number) : $item.prev();
        let $controls = $number.find(CONTROL_SELECTOR);

        closerControl($controls, $number);
    }

    /**
     * Toggle visibility of the associated list item.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function toggleItem(event) {
        /** @type {jQuery} */
        let $target = $(event.currentTarget || event.target);
        let $item, $number;
        if ($target.is(CONTROL_SELECTOR)) {
            $number  = $target.parents('.number');
            $item    = $number.next();
        } else if ($target.is(ITEM_SELECTOR)) {
            $item    = $target;
            $number  = $item.prev();
        } else {
            $item    = $target.parents(ITEM_SELECTOR);
            $number  = $item.prev();
        }

        // Update the toggle control(s) and the item itself.
        if ($item.hasClass(OPEN_MARKER)) {
            closeItem($item, $number);
        } else {
            openItem($item, $number);
        }
    }

    // noinspection DuplicatedCode
    /**
     * Set the control to indicate that its function is to close the associated
     * list item.
     *
     * @param {jQuery} $control
     * @param {jQuery} [$container]
     */
    function closerControl($control, $container) {
        let $parent = $container || $control.parent();
        markAsOpen($parent, false);
        markAsOpen($parent.find('button,[role="button"]'));
        $control.attr('title', Emma.Tree.closer.tooltip);
        $control.text(Emma.Tree.closer.label);
    }

    // noinspection DuplicatedCode
    /**
     * Set the control to indicate that its function is to open the associated
     * list item.
     *
     * @param {jQuery} $control
     * @param {jQuery} [$container]
     */
    function openerControl($control, $container) {
        let $parent = $container || $control.parent();
        markAsClosed($parent, true);
        markAsClosed($parent.find('button,[role="button"]'));
        $control.attr('title', Emma.Tree.opener.tooltip);
        $control.text(Emma.Tree.opener.label);
    }

    /**
     * Create a new open/close toggle control.
     *
     * @param {number}  row
     * @param {string}  target
     * @param {boolean} [closer]      By default, control created as an opener.
     *
     * @returns {jQuery}
     */
    function createToggleControl(row, target, closer) {
        let $control = $(`<button class="${CONTROL_CLASS} ${row}">`);
        $control.attr('data-row',      `.${row}`);
        $control.attr('aria-controls', target);
        if (closer) {
            closerControl($control);
        } else {
            openerControl($control);
        }
        return $control;
    }

    /**
     * Create and assign event handlers for a pair of open/close controls
     * (one for 'wide' and 'medium' screens; the other for 'narrow' screens).
     *
     * NOTE: probably the controls should be in the generated HTML, along with
     *  the setting of 'data-row' so that this code only has to attach the
     *  event handlers.
     *
     * @param {Selector} parent
     */
    function setupToggleControl(parent) {
        const func  = 'setupControl';
        let $number = $(parent);
        if (!onlyOne($number, func, 'number')) {
            return;
        }

        const classes = $number[0].classList;
        const row     = $.map(classes, cls => cls.match(/^row-\d+$/)).pop();
        if (isEmpty(row)) {
            console.warn(`${func}: could not determine row for ${classes}`);
            return;
        }

        // Find or create the toggle control visible for wide and
        // medium-width screens.
        /** @type {jQuery} */
        let $children = $number.children();
        let $control  = $children.filter(CONTROL_SELECTOR);
        if (isMissing($control)) {
            let $item    = $number.next();
            const target = $item.attr('id');
            $control = createToggleControl(row, target).appendTo($number);
        }
        handleClickAndKeypress($control, toggleItem);

        // Find or create the toggle control visible for narrow screens.
        let $container      = $children.filter('.container');
        let $narrow_control = $container.find(CONTROL_SELECTOR);
        if (isMissing($narrow_control)) {
            $narrow_control = $control.clone().appendTo($container);
        }
        handleClickAndKeypress($narrow_control, toggleItem);
    }

    // ========================================================================
    // Actions - collapsible items
    // ========================================================================

    // Create and setup item display toggle controls.
    $list_parts.filter('.number').each(function() {
        setupToggleControl(this);
    });

    $result_items.each(function() {
        let $item  = $(this);
        let $title = $item.find('.value.field-Title .title');

        // Make clicking on the title toggle the display of that item.
        let title_id;
        if (TITLE_RESULTS) {
            title_id = `title_${this.id}`;
            $title.attr('id', title_id);
        } else if ($title.length > 1) {
            title_id = $title.filter('[data-mode="txt"]').attr('id');
            $title   = $title.filter('[data-mode="btn"]');
        } else {
            title_id = cloneTitle($item, $title);
        }
        $title = makeButton($title, this.id);
        handleClickAndKeypress($title, toggleItem);

        // Make the item's title present as the label for the number.
        let $number = $item.prev();
        $number.attr('aria-labelledby', title_id);
    });

    // ========================================================================
    // Functions - collapsible sections
    // ========================================================================

    /**
     * Mark element(s) as hidden.
     *
     * @param {Selector} element
     */
    function markAsHidden(element) {
        let $element = $(element).not('.disabled');
        $element.addClass(HIDDEN_MARKER);
        updateVisibility($element);
    }

    /**
     * Mark previously-hidden element(s) as visible.
     *
     * @param {Selector} element
     */
    function markAsVisible(element) {
        let $element = $(element).not('.disabled');
        $element.removeClass(HIDDEN_MARKER);
        updateVisibility($element);
    }

    /**
     * Mark elements with the proper ARIA attribute based on the presence of
     * {@link HIDDEN_MARKER}.
     *
     * @param {Selector} elements
     */
    function updateVisibility(elements) {
        $(elements).each(function() {
            let $element = $(this);
            if ($element.hasClass(HIDDEN_MARKER)) {
                $element.attr('aria-hidden', true);
            } else {
                $element.removeAttr('aria-hidden');
            }
        });
    }

    /**
     * Mark section elements as hidden.
     *
     * @param {Selector} section
     */
    function markSectionHidden(section) {
        let $section  = $(section).not('.disabled');
        let $elements = getSection($section);
        markAsHidden($elements);
    }

    /**
     * Mark section elements as visible.
     *
     * @param {Selector} section
     */
    function markSectionVisible(section) {
        let $section  = $(section).not('.disabled');
        let $elements = getSection($section);
        markAsVisible($elements);
    }

    /**
     * Mark elements with the proper ARIA attribute.
     *
     * @param {Selector} section
     * @param {boolean}  [open]
     *
     * == Usage Notes
     * This function expects that "section" resolves to a single HTML element
     * unless "open" is provided.
     */
    function updateSectionVisibility(section, open) {
        const func   = 'updateSectionVisibility';
        let $section = $(section);
        let is_open;
        if (isDefined(open)) {
            is_open = open;
        } else if (onlyOne($section, func, 'section')) {
            is_open = $section.hasClass(OPEN_MARKER);
        } else {
            return;
        }
        if (is_open) {
            markSectionVisible($section);
        } else {
            markSectionHidden($section);
        }
    }

    /**
     * Update the open/closed state of a sub-section.
     *
     * @param {Selector} section
     * @param {Selector} [toggle]
     *
     * == Usage Notes
     * This function expects that "section" resolves to a single HTML element.
     */
    function updateSectionOpenClosed(section, toggle) {
        const func   = 'updateSectionOpenClosed';
        let $section = $(section);
        if (!onlyOne($section, func, 'section')) {
            return;
        }
        let $toggle =
            toggle ? $(toggle) : $section.find('.toggle').not('.for-item');
        if ($section.hasClass(OPEN_MARKER)) {
            markAsOpen($section.children());
            markSectionVisible($section);
            closerControl($toggle, $section);
        } else {
            markAsClosed($section.children());
            markSectionHidden($section);
            openerControl($toggle, $section);
        }
    }

    /**
     * Collapse a search results item sub-section.
     *
     * @param {Selector} section
     * @param {Selector} [toggle]
     */
    function closeSection(section, toggle) {
        let $section = $(section);
        markAsClosed($section, true);
        updateSectionOpenClosed($section, toggle);
    }

    /**
     * Expand a search results item sub-section.
     *
     * @param {Selector} section
     * @param {Selector} [toggle]
     */
    function openSection(section, toggle) {
        let $section = $(section);
        markAsOpen($section, false);
        updateSectionOpenClosed($section, toggle);
    }

    /**
     * Toggle open/closed state of the associated item sub-section.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function toggleSection(event) {
        let $tgt      = $(event.currentTarget || event.target || event);
        let $toggle   = $tgt.is('.toggle') ? $tgt : $tgt.siblings('.toggle');
        const section = $toggle.attr('aria-controls');
        let $section;
        if (section) {
            $section = $(`#${section}`);
        } else {
            $section = $toggle.parents(SUBSECTION_SELECTOR).first();
        }
        if ($section.hasClass(OPEN_MARKER)) {
            closeSection($section, $toggle);
        } else {
            openSection($section, $toggle);
        }
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
        let lines = [];
        $(section).each(function() {
            let $section   = $(this);
            const classes  = $section[0].classList;
            const this_row = $.map(classes, c => c.match(/^row-\d+$/)).pop();
            const related  = sectionSelector($section);
            let $lines     = $section.siblings(related).not(`.${this_row}`);
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
        let $item = $(item);
        return ['part', 'format', 'file'].map(function(k) {
            const v = $item.attr(`data-${k}`);
            return v && `[data-${k}="${v}"]`;
        }).join('');
    }

    // ========================================================================
    // Actions - collapsible sections
    // ========================================================================

    $result_items.each(function() {
        let $item = $(this);
        updateOpenClosed($item);

        // Ensure that open/closed items have the right CSS marker classes
        // ARIA attributes.
        const is_open = $item.hasClass(OPEN_MARKER);
        let $sections = $item.children(SUBSECTION_SELECTOR);
        updateSectionVisibility($sections, is_open);

        // Make clicking on sub-section toggles and associated labels
        // open/close that sub-section, but hide toggles/labels which are not
        // actually part of the item display.
        //
        // noinspection JSCheckFunctionSignatures
        $sections.find('.toggle').not('.for-item').each(function() {
            let $toggle = $(this);
            let $label  = $toggle.parent();
            if ($label.attr('data-value')) {
                const target = $toggle.attr('aria-controls');
                let $text    = $toggle.siblings('.text');
                makeButton($text, target);
                handleClickAndKeypress($text,   toggleSection);
                handleClickAndKeypress($toggle, toggleSection);
            } else {
                let $section = $label.parent();
                markAsHidden($section);
                $section.addClass('disabled');
            }
        });
    });

});
