// app/assets/javascripts/controllers/search.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging
//= require feature/database

// noinspection FunctionTooLongJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    let $body = $('body');

    /** @type {jQuery} */
    let $item_list = $body.filter('.new-style').find('.search-list');

    // Only perform these actions on the appropriate pages.
    if (isMissing($item_list)) {
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    const TIMESTAMP        = new Date();
    const DEV_CONTROLS     = $body.hasClass('dev-style');
    const AGGREGATE_STYLE  = $body.hasClass('aggregate-style');

    const FIRST_PAGE       = 1;
    const DEFAULT_LIMIT    = 100; // Items per page.

    const ITEM_CLASS       = 'search-list-item';
    const ITEM_SELECTOR    = selector(ITEM_CLASS);

    const CONTROL_CLASS    = 'control';
    const CONTROL_SELECTOR = selector(CONTROL_CLASS);

    /**
     * Current URL parameters.
     *
     * @constant
     * @type {object}
     */
    const params = urlParameters();

    /**
     * Current search page.
     *
     * @constant
     * @type {number}
     */
    const PAGE_NUMBER = Number(params['page']) || FIRST_PAGE;

    /**
     * Current search page size.
     *
     * @constant
     * @type {number}
     */
    const PAGE_SIZE = Number(params['limit']) || DEFAULT_LIMIT;

    /**
     * Item number offset for the first search result item on the current page.
     *
     * @constant
     * @type {number}
     */
    const PAGE_OFFSET = 1 + (PAGE_SIZE * (PAGE_NUMBER - FIRST_PAGE));

    // ========================================================================
    // Variables
    // ========================================================================

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

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Current search page.
     *
     * @returns {number}
     */
    function pageNumber() {
        return PAGE_NUMBER;
    }

    /**
     * Indicate whether the current page represents a new search.
     *
     * @returns {boolean}
     */
    function newSearch() {
        return pageNumber() === FIRST_PAGE;
    }

    /**
     * Return the *emma_titleId* value of the given search result item.
     *
     * @param {Selector} item
     *
     * @returns {string}
     */
    function titleId(item) {
        let $item   = $(item);
        const value = $item.attr('data-title_id');
        return value || $item.find('.field-EmmaTitleId.value').text();
    }

    /**
     * Return the normalized title of the given search result item.
     *
     * @param {Selector} item
     *
     * @returns {string}
     */
    function normalizedTitle(item) {
        let $item = $(item);
        let value = $item.attr('data-normalized_title');
        if (!value) {
            value = $item.find('.field-Title.value .title').text();
            value = value.replace(/^(\p{punct}|\p{space})+/u, '');
            value = value.replace(/(\p{punct}|\p{space})+$/u, '');
            value = value.replace(/(\p{punct}|\p{space})+/ug, ' ');
            value = value.toLowerCase();
        }
        return value;
    }

    /**
     * Return the *emma_recordId* value of the given search result item.
     *
     * @param {Selector} item
     *
     * @returns {string}
     */
    function recordId(item) {
        let $item   = $(item);
        const value = $item.attr('data-record_id');
        return value || $item.find('.field-EmmaRecordId.value').text();
    }

    /**
     * repositoryRecordId
     *
     * @param {Selector} item
     *
     * @returns {string}
     */
    function repositoryRecordId(item) {
        let $item   = $(item);
        const value = $item.attr('data-repo_id');
        return value || $item.find('.field-RepositoryRecordId.value').text();
    }

    /**
     * Return the *dc_identifier* values of the given search result item.
     *
     * @param {Selector} item
     *
     * @returns {string[]}
     */
    function standardIdentifiers(item) {
        let $ids = $(item).find('.field-Identifier.value').children();
        return $ids.toArray().map(element => $(element).text());
    }

    // ========================================================================
    // Actions
    // ========================================================================

    // Initialize identification tooltips for each item.
    $result_items.each(function(index) {
        $(this).attr('title', `Item ${index + PAGE_OFFSET}`);
    });

    // ========================================================================
    // Constants - collapsible items
    // ========================================================================

    /**
     * Marker class indicating that the list item should be fully displayed.
     *
     * @constant
     * @type {string}
     */
    const OPEN_MARKER = 'open';

    const OPENED_TIP  = 'Close';
    const OPENED_ICON = '▲';

    const CLOSED_TIP  = 'Open';
    const CLOSED_ICON = '▼';

    // ========================================================================
    // Functions - collapsible items
    // ========================================================================

    /**
     * Toggle visibility of the associated list item.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function toggleItem(event) {
        /** @type {jQuery} $target, $item, $control */
        let $target = $(event.currentTarget || event.target);
        let $item, $number;
        if ($target.is(CONTROL_SELECTOR)) {
            $number = $target.parents('.number');
            $item   = $number.next();
        } else if ($target.is(ITEM_SELECTOR)) {
            $item   = $target;
            $number = $item.prev();
        } else {
            $item   = $target.parents(ITEM_SELECTOR);
            $number = $item.prev();
        }

        // Update the toggle control(s).
        let $controls = $number.find(CONTROL_SELECTOR);
        if ($item.hasClass(OPEN_MARKER)) {
            openerControl($controls);
        } else {
            closerControl($controls);
        }

        // Update the item itself.
        $item.toggleClass(OPEN_MARKER);
    }

    /**
     * Set the control to indicate that its function is to close the associated
     * list item.
     *
     * @param {jQuery} $control
     *
     * @returns {jQuery}              The $control (for chaining).
     */
    function closerControl($control) {
        $control.attr('title', OPENED_TIP);
        $control.text(OPENED_ICON);
        $control.addClass(OPEN_MARKER);
        $control.parent().addClass(OPEN_MARKER);
        return $control;
    }

    /**
     * Set the control to indicate that its function is to open the associated
     * list item.
     *
     * @param {jQuery} $control
     *
     * @returns {jQuery}              The $control (for chaining).
     */
    function openerControl($control) {
        $control.attr('title', CLOSED_TIP);
        $control.text(CLOSED_ICON);
        $control.removeClass(OPEN_MARKER);
        $control.parent().removeClass(OPEN_MARKER);
        return $control;
    }

    /**
     * Create a new open/close toggle control.
     *
     * @param {number}  row
     * @param {boolean} [closer]      By default, control created as an opener.
     *
     * @returns {jQuery}
     */
    function createToggleControl(row, closer) {
        let $control = $(`<button class="${CONTROL_CLASS} ${row}">`);
        $control.attr('data-row', `.${row}`);
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
        const func    = 'setupControl';
        let $number   = $(parent);
        const classes = $number[0].classList;
        const row     = $.map(classes, cls => cls.match(/^row-\d+$/)).pop();
        if (isEmpty(row)) {
            console.warn(`${func}: could not determine row for ${classes}`);
        } else {
            // The toggle control visible for wide and medium-width screens:
            let $control = createToggleControl(row).appendTo($number);
            handleClickAndKeypress($control, toggleItem);

            // The toggle control visible for narrow screens:
            let $container      = $number.children('.container');
            let $narrow_control = $control.clone().appendTo($container);
            handleClickAndKeypress($narrow_control, toggleItem);
        }
    }

    // ========================================================================
    // Actions - collapsible items
    // ========================================================================

    // Create the "heading-bar" to contain the page heading and the top
    // pagination bar.  Move the bottom pagination bar below the item list.
    //
    // NOTE: Probably an interim solution until the HTML-generating code is
    //  changed to accommodate the new style.

    let $heading     = $('.layout-content > h1.heading');
    let $heading_bar = $('<div>').addClass('heading-bar');

    $heading_bar.insertBefore($heading);
    $heading.detach().appendTo($heading_bar);
    $list_parts.filter('.pagination-top').detach().appendTo($heading_bar);
    $list_parts.filter('.pagination-bottom').detach().insertAfter($item_list);

    // Create and setup item display toggle controls.

    $list_parts.filter('.number').each(function() {
        setupToggleControl(this);
    });

    // Make clicking on the title toggle the display of that item.

    $result_items.find('.field-Title.value .title').each(function() {
        handleClickAndKeypress($(this), toggleItem);
    });

    // ========================================================================
    // Constants - page data
    // ========================================================================

    /**
     * The database holding search result item data across pages.
     *
     * @type {string}
     */
    const DB_STORE_NAME = 'search_data';

    /**
     * Properties for the DB_STORE_NAME object store.
     *
     * @constant
     * @type {StoreTemplate}
     */
    const DB_STORE_TEMPLATE = {
        options: { autoIncrement: true },
        record: {
            page:         { default: 0,  func: pageNumber },
            title_text:   { default: '', func: normalizedTitle },
            title_id:     { default: '', func: titleId },
            record_id:    { default: '', func: recordId },
            repo_id:      { default: '', func: repositoryRecordId },
            identifier:   { default: [], func: standardIdentifiers },
            db_timestamp: { default: TIMESTAMP, index: false, },
        }
    };

    // ========================================================================
    // Variables - page data
    // ========================================================================

    /**
     * SearchDataRecord
     *
     * @typedef {{
     *     page:         number,
     *     title_text:   string,
     *     title_id:     string,
     *     record_id:    string,
     *     repo_id:      string,
     *     identifier:   string[],
     *     db_timestamp: Date
     * }} SearchDataRecord
     */

    /**
     * PageItem
     *
     * @typedef {{
     *     element: jQuery,
     *     data:    SearchDataRecord
     * }} PageItem
     */

    /**
     * Data gathered for items on the current page.
     *
     * @type {PageItem[]}
     */
    let page_items;

    /**
     * Data copied from the database object store.
     *
     * Each record_id key is associated with an object containing records
     * keyed by page number.
     *
     * @type {Object<Object<SearchDataRecord[]>>}
     */
    let store_items;

    // ========================================================================
    // Functions - page data
    // ========================================================================

    /**
     * Data for each item on the page of search results.
     *
     * @returns {PageItem[]}
     */
    function pageItems() {
        return page_items || storeItems();
    }

    /**
     * Persist data for all result items to the database object store.
     *
     * @returns {PageItem[]}
     */
    function storeItems() {
        page_items  = [];
        store_items = {}

        // Build page_items from items on the current page, and initialize
        // store_items with records from the current page.
        let item_data = [];
        $result_items.each(function() {
            let $item    = $(this);
            const record = extractItemData($item);
            localStoreItem(record);
            item_data.push(record);
            page_items.push({ element: $item, data: record });
        });

        // Complete store_items with items seen on other pages.  After the last
        // item has been retrieved, update the object store with items from the
        // current page.
        DB.fetchItems(function(cursor) {
            if (cursor) {
                localStoreItem({ ...cursor.value });
            } else {
                DB.storeItems(item_data);
            }
        });

        return page_items;
    }

    /**
     * extractItemData
     *
     * @param {Selector} item
     *
     * @returns {SearchDataRecord}
     */
    function extractItemData(item) {
        let result = {};
        let $item  = $(item);
        $.each(DB_STORE_TEMPLATE.record, function(key, prop) {
            result[key] = prop.func ? prop.func($item) : prop.default;
        });
        return result;
    }

    /**
     * Include the given record in the local in-memory reflection of the
     * database object store.
     *
     * @param {SearchDataRecord} record
     */
    function localStoreItem(record) {
        const key  = record.title_id;
        const page = record.page;
        store_items ||= {}
        store_items[key] ||= {};
        store_items[key][page] ||= [];
        store_items[key][page].push(record);
    }

    // ========================================================================
    // Actions - page data
    // ========================================================================

    // Set the database and version.
    DB.setDatabase('emma', 2);

    // Register the object store.
    DB.addStoreTemplate(DB_STORE_NAME, DB_STORE_TEMPLATE);

    // Open the database and fill the object store with items from the current
    // page of search results.
    DB.openObjectStore(DB_STORE_NAME, function() {
        console.warn('============= OPENING OBJECT STORE ===========');
        if (newSearch()) {
            DB.clearObjectStore(DB_STORE_NAME, storeItems);
        } else {
            DB.deleteItems('page', pageNumber(), storeItems);
        }
    });

    // ========================================================================
    // Constants - relevancy score
    // ========================================================================

    /**
     * Current search results sort order.
     *
     * @constant
     * @type {string}
     */
    const SORT_ORDER = params['sort'] || 'relevancy';

    /**
     * @const
     * @type {{string: string}}
     */
    const SORTED = {
        title:               'dc_title for sort=title',
        sortDate:            'sort_date for sort=sortDate',
        lastRemediationDate: 'remediation_date for sort=lastRemediationDate',
    };

    /**
     * Indication of a blank value.
     *
     * @constant
     * @type {string}
     */
    const BLANK = Emma.Upload.Field.empty;

    // ========================================================================
    // Functions - relevancy score
    // ========================================================================

    /**
     * Mark suspicious relevancy scores.
     *
     * @param {Selector} [items]      Default: {@link $result_items}.
     */
    function validateRelevancyScores(items) {
        let $items   = items ? $(items) : $result_items;
        if (Object.keys(SORTED).includes(SORT_ORDER)) {
            $items.each(function() { markDisabledRelevancy(this) });
        } else {
            let error_score, next_score = 0;
            $items.get().reverse().forEach(function(item) {
                let $item   = $(item);
                const score = Number($item.attr('data-item_score'));
                if (score < next_score) {
                    error_score = score;
                } else if (score > next_score) {
                    error_score = undefined;
                }
                if (error_score) {
                    markSuspiciousRelevancy($item);
                }
                next_score = score;
            });
        }
    }

    /**
     * Mark the score for the item as irrelevant to the current sort order.
     *
     * @param {Selector} item
     *
     * @returns {jQuery}              The score element.
     */
    function markDisabledRelevancy(item) {
        let $score = $(item).find('.item-score');
        const desc = SORTED[SORT_ORDER] || 'specific metadata field(s)';
        const tip  = `Relevancy based on ${desc}`;
        return $score.addClass('disabled').attr('title', tip).text(BLANK);
    }

    /**
     * Mark the score for the item as problematic.
     *
     * @param {Selector} item
     *
     * @returns {jQuery}              The score element.
     */
    function markSuspiciousRelevancy(item) {
        let $score = $(item).find('.item-score');
        let tip    = $score.attr('title');
        tip += "\n\nNOTE:";
        tip += "The placement of this item seems to be anomalous, ";
        tip += "however that may just be due to a bad guess about how the ";
        tip += "actual relevancy is determined by the index."
        return $score.addClass('error').attr('title', tip);
    }

    // ========================================================================
    // Actions - relevancy score
    // ========================================================================

    if (AGGREGATE_STYLE) {
        validateRelevancyScores();
    }

    // ========================================================================
    // Constants - colorize
    // ========================================================================

    /**
     * Advanced experimental controls.
     *
     * NOTE: The order here is the reverse of the order of display.
     *
     * @constant
     * @type {{
     *     restore:       ElementProperties,
     *     by_repo_id:    ElementProperties,
     *     by_identifier: ElementProperties,
     *     by_title_text: ElementProperties,
     *     by_title_id:   ElementProperties,
     * }}
     */
    const BUTTON = {
        restore: {
            active:  true,
            tag:     'button',
            class:   'restore-button',
            text:    'Normal',
            tooltip: 'Restore the normal search results display',
            func:    revertStyle,
        },
        by_repo_id: {
            active:  DEV_CONTROLS,
            tag:     'button',
            class:   'colorize-button by_repo_id',
            text:    'Repo ID',
            tooltip: 'Mark entries with the same "repository record ID" ' +
                         'in the same color',
            func:    () => colorize('by_repo_id'),
        },
        by_identifier: {
            active:  DEV_CONTROLS,
            tag:     'button',
            class:   'colorize-button by_identifier',
            text:    'ISBN',
            tooltip: 'Mark entries with the same standard identifier ' +
                         'in the same color',
            func:    () => colorize('by_identifier'),
        },
        by_title_text: {
            active:  DEV_CONTROLS,
            tag:     'button',
            class:   'colorize-button by_title_text',
            text:    'Title',
            tooltip: 'Mark entries with matching title text ' +
                         'in the same color',
            func:    () => colorize('by_title_text', 'T'),
        },
        by_title_id: {
            active:  true,
            tag:     'button',
            class:   'colorize-button by_title_id',
            text:    'Title ID',
            tooltip: 'Mark entries with the same "title ID" ' +
                         'in the same color',
            func:    () => colorize('by_title_id'),
        },
    };

    /**
     * Map identity type to relevant metadata field class name.
     *
     * @constant
     * @type {{string: string|null}}
     */
    const IDENTITY_FIELD = {
        by_repo_id:    'field-RepositoryRecordId',
        by_identifier: 'field-Identifier',
        by_title_text: null,
        by_title_id:   'field-EmmaTitleId'
    };

    /**
     * Identity topics.
     *
     * @type {string[]}
     */
    const TOPICS = Object.keys(IDENTITY_FIELD);

    /**
     * CSS marker class indicating an erroneous item.
     *
     * @constant
     * @type {string}
     */
    const ERROR_MARKER = 'error';

    /**
     * Tooltip text for an erroneous item. // TODO: I18n
     *
     * @constant
     * @type {string}
     */
    const ERROR_TOOLTIP = 'THIS ITEM IS OUT-OF-SEQUENCE';

    /**
     * Tooltip text for an erroneous item. // TODO: I18n
     *
     * @constant
     * @type {string}
     */
    const ERROR_JUMP_TOOLTIP =
        'Jump to the first occurrence on the page of this identity';

    /**
     * CSS marker class indicating an erroneous item.
     *
     * @constant
     * @type {string}
     */
    const EXILE_MARKER = 'exile';

    /**
     * Tooltip text for an erroneous item. // TODO: I18n
     *
     * @constant
     * @type {string}
     */
    const LATE_EXILE_TOOLTIP =
        'THIS ITEM BELONGS ON AN EARLIER PAGE OF SEARCH RESULTS';

    /**
     * Tooltip text for an erroneous item. // TODO: I18n
     *
     * @constant
     * @type {string}
     */
    const EARLY_EXILE_TOOLTIP =
        'A LATER PAGE OF SEARCH RESULTS HAS ITEM(S) MATCHING THIS ONE';

    // noinspection SpellCheckingInspection
    /**
     * Narrow no-break space.
     *
     * @constant
     * @type {string}
     */
    const NNBS = "\u202F";

    /**
     * Maximum integer color value.
     *
     * @constant
     * @type {number}
     */
    const COLOR_RANGE = HEX_BASE ** DEFAULT_HEX_DIGITS;

    /**
     * Used when generating a new contrasting item title background color.
     *
     * @constant
     * @type {number}
     */
    const COLOR_OFFSET_LIMIT = 0x0f0000;

    // ========================================================================
    // Variables - colorize
    // ========================================================================

    /**
     * Location of colorize controls.
     *
     * @type {jQuery}
     */
    let $button_tray = $heading_bar.find('.pagination-top');

    // ========================================================================
    // Functions - colorize
    // ========================================================================

    /**
     * Revert the current search results page to the normal display style.
     */
    function revertStyle() {
        params['style'] = 'normal';
        window.location.href = makeUrl(params);
    }

    /**
     * Colorize list items based on the given topic.
     *
     * @param {string} by_topic
     * @param {string} [data_tag]
     */
    function colorize(by_topic, data_tag) {
        const item_lists = buildLists(by_topic);
        validateLists(item_lists, by_topic);
        colorizeLists(item_lists, by_topic, data_tag);
    }

    /**
     * Create a table of lists of items related by the indicated identity.
     *
     * @param {string} by_topic
     *
     * @returns {object[]}
     */
    function buildLists(by_topic) {
        let related_item_lists = {};
        const index_key = by_topic.replace(/^by_/, '');
        pageItems().forEach(function(page_item) {
            let $item = page_item.element;
            arrayWrap(page_item.data[index_key]).forEach(function(value) {
                const id = `${value}-`; // Bust sorting behavior of Object.
                let related_items = related_item_lists[id] || [];
                related_items.push($item);
                related_item_lists[id] = related_items;
            });
        });
        return Object.values(related_item_lists);
    }

    /**
     * Mark as errors items which are not being displayed in the right order.
     *
     * @param {object[]} item_lists
     * @param {string}   by_topic
     */
    function validateLists(item_lists, by_topic) {
        const current_page = pageNumber();
        item_lists.forEach(function(item_list) {
            let prev;
            item_list.forEach(function(item) {
                let $item = $(item);

                // Mark items that belong with a set of item(s) encountered
                // earlier on the page.
                if (prev && ($item.prevAll(ITEM_SELECTOR)[0].id !== prev)) {
                    markItemAsError($item);
                } else {
                    prev = $item[0].id;
                }

                // Mark items which were encountered on other pages.
                const store_key = $item.attr('data-title_id');
                $.each(store_items[store_key], function(page, _records) {
                    return !markItemAsExile($item, page, current_page);
                });
            });
        });
    }

    /**
     * Give the same color to each set of associated list items and annotate
     * them with a marker to help identify related items.
     *
     * @param {object[]} item_lists
     * @param {string}   by_topic
     * @param {string}   data_tag
     */
    function colorizeLists(item_lists, by_topic, data_tag) {

        // Because not every search result item may be visited below, clear out
        // all non-relevant identity tags and highlighting of metadata fields.
        const other_topics = TOPICS.filter(topic => (topic !== by_topic));
        removeIdentityNumber($result_items, other_topics);
        unmarkIdentityFields($result_items);

        const tag = data_tag || by_topic.replace(/^by_/, '')[0];
        let color = Math.floor(Math.random() * COLOR_RANGE);
        item_lists.forEach(function(item_list, index) {
            const number   = `${tag}-${index+1}`;
            const bg_color = rgbColor(color);
            const fg_color = rgbColorInverse(color);
            item_list.forEach(function(item, position) {
                let $item  = $(item);
                let $title = $item.children('.field-Title.value');
                $title.css({ color: fg_color, background: bg_color });
                if (!$item.is(`.colorized.${by_topic}`)) {
                    addIdentityNumber($item, by_topic, number, position);
                    $item.addClass(`colorized ${by_topic}`);
                }
                markIdentityField($item, by_topic);
            });
            color = semiRandomColorOffset(color);
        });
    }

    // ========================================================================
    // Functions - colorize
    // ========================================================================

    /**
     * Add or replace the portion of the item tooltip indicating the nature of
     * the result list item.
     *
     * @param {Selector} item
     * @param {string}   state_text
     * @param {string}   [separator]
     */
    function itemStateTip(item, state_text, separator = ' -- ') {
        let $item   = $(item);
        const tip   = $item.attr('title') || '';
        const parts = tip.split(separator, 2);
        let new_tip = parts[0].trimRight();
        const added = (state_text || '').trim();
        if (added) {
            new_tip += separator + added;
        }
        $item.attr('title', new_tip);
    }

    /**
     * Mark the item as being erroneous.
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function markItemAsError(item) {
        let $item = $(item);
        $item.addClass(ERROR_MARKER)
        itemStateTip($item, ERROR_TOOLTIP);
        return true;
    }

    /**
     * Mark the item as being separated from other item(s) with the same
     * identity on an earlier or later page.
     *
     * @param {Selector} item
     * @param {number}   original_page
     * @param {number}   current_page
     *
     * @returns {boolean}
     */
    function markItemAsExile(item, original_page, current_page) {
        const diff = (Number(original_page) - Number(current_page)) || 0;
        if (diff) {
            let $item = $(item);
            $item.addClass(EXILE_MARKER);
            const tip = (diff < 0) ? LATE_EXILE_TOOLTIP : EARLY_EXILE_TOOLTIP;
            itemStateTip($item, tip);
        }
        return (diff !== 0);
    }

    /**
     * Add an identity number to an item's title.
     *
     * @param {Selector} item
     * @param {string}   by_topic
     * @param {string}   identity
     * @param {number}   [position]
     */
    function addIdentityNumber(item, by_topic, identity, position) {
        let $item   = $(item);
        const error = $item.hasClass(ERROR_MARKER);
        const exile = $item.hasClass(EXILE_MARKER);
        let $title  = $item.children('.field-Title.value');
        let $t_text = $title.children('.title');
        let $t_tag;
        if (error) {
            $t_tag = $(`<a href="#${identity}">`).addClass(ERROR_MARKER);
            $t_tag.attr('title', ERROR_JUMP_TOOLTIP);
            if (exile) { $t_tag.addClass(EXILE_MARKER); }
        } else if (exile) {
            $t_tag = $('<div>').addClass(EXILE_MARKER);
        } else if (position) {
            $t_tag = $('<div>').attr('id', null);
        } else {
            $t_tag = $('<div>').attr('id', identity);
            itemStateTip($item, `first occurrence of identity "${identity}"`);
        }
        $t_tag.addClass(`identity-number ${by_topic}`);
        $t_tag.text(`[${NNBS}${identity}${NNBS}]`);
        $t_tag.insertAfter($t_text);
    }

    /**
     * Remove an identity number previously added to an item's title.
     *
     * @param {Selector}        [item]      Default: {@link $result_items}.
     * @param {string|string[]} [by_topic]  Default: {@link TOPICS}.
     */
    function removeIdentityNumber(item, by_topic) {
        let $items = item ? $(item) : $result_items;
        let topics = by_topic ? arrayWrap(by_topic) : TOPICS;
        let $tags  = $items.find('.identity-number');
        if (by_topic) {
            $tags = $tags.filter(topics.map(t => `.${t}`).join(', '));
        }
        topics.forEach(topic => $items.removeClass(topic));
        $tags.remove();
    }

    /**
     * Highlight the item's metadata field associated with the current
     * identity selection.
     *
     * @param {Selector} item
     * @param {string}   by_topic
     */
    function markIdentityField(item, by_topic) {
        const field = IDENTITY_FIELD[by_topic];
        if (field) {
            let $items = item ? $(item) : $result_items;
            $items.find(`.value.${field}`).addClass('identity-highlight');
        }
    }

    /**
     * Clear highlighting of item metadata field(s).
     *
     * @param {Selector} [item]       Default {@link $result_items}.
     */
    function unmarkIdentityFields(item) {
        let $items = item ? $(item) : $result_items;
        $items.find('.identity-highlight').removeClass('identity-highlight');
    }

    /**
     * Generate a new color value which is random but sufficiently different
     * that it is contrasting.
     *
     * @param {number} color
     * @param {number} [offset_limit]
     *
     * @returns {number}
     */
    function semiRandomColorOffset(color, offset_limit = COLOR_OFFSET_LIMIT) {
        let result = color + Math.floor(Math.random() * COLOR_RANGE);
        if (result < offset_limit) {
            result += offset_limit;
        } else if (result > (COLOR_RANGE - offset_limit)) {
            result -= offset_limit;
        }
        return result % COLOR_RANGE;
    }

    // ========================================================================
    // Functions - colorize
    // ========================================================================

    /**
     * Assign event handlers to the colorize button, creating it if necessary.
     *
     * @param {string}            topic     {@link BUTTON} key.
     * @param {ElementProperties} [config]  {@link BUTTON} value.
     */
    function setupColorizeButton(topic, config) {
        const button = config || BUTTON[topic];
        let $button  = $(selector(button.class));
        if (isMissing($button)) {
            $button = create(button).appendTo($button_tray);
        }
        handleClickAndKeypress($button, function() {
            $button_tray.children().removeClass('active');
            $(this).addClass('active');
            button.func ? button.func() : colorize(topic);
        });
    }

    // ========================================================================
    // Actions - colorize
    // ========================================================================

    $.each(BUTTON, function(topic, button) {
        if (button.active) {
            setupColorizeButton(topic, button);
        }
    });

});
