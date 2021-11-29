// app/assets/javascripts/controllers/search.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging
//= require feature/database

// noinspection FunctionTooLongJS
$(document).on('turbolinks:load', function() {

    /**
     * Search page <body>.
     *
     * @type {jQuery}
     */
    let $body = $('body.search-index, body.search.new-style');

    // Only perform these actions on the appropriate pages.
    if (isMissing($body)) {
        return;
    }

    // Reset remembered colorization on original-style search pages.
    if (!$body.hasClass('new-style')) {
        sessionStorage.removeItem('search-colorize');
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Active search style(s).
     *
     * @type {Object<boolean>}
     */
    const SEARCH_STYLE = {
        aggregate:  $body.hasClass('aggregate-style'),
        compact:    $body.hasClass('compact-style'),
        grid:       $body.hasClass('grid-style'),
        v2:         $body.hasClass('search-v2'),
        v3:         $body.hasClass('search-v3'),
        normal:     !$body.hasClass('new-style'),
    };

    const TIMESTAMP        = new Date();
    const DEV_CONTROLS     = $body.hasClass('dev-style');

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

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Current search page style.
     *
     * @note Can't rely on `params` because `params['style']` will have already
     *  been removed via the server redirect.
     *
     * @returns {string}
     */
    function pageStyle() {
        let result;
        $.each(SEARCH_STYLE, function(style, active) {
            result = style;
            return !active; // continue if not active
        });
        return result || 'normal';
    }

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
     * The current search terms (ignoring page/offset).
     *
     * @returns {object}
     */
    function currentSearch() {
        let result = { ...params };
        delete result.page;
        delete result.offset;
        return result;
    }

    // ========================================================================
    // Functions
    // ========================================================================

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
        return value || $item.find('.field-TitleId.value').text();
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
        return value || $item.find('.field-RecordId.value').text();
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
     * @constant
     * @type {string}
     */
    const DB_NAME = 'emma_search';

    /**
     * The current version of the database.
     *
     * @note This must be incremented every time DB_STORE_TEMPLATE or DB_STORES
     *  are changed in any way.
     *
     * @constant
     * @type {number}
     */
    const DB_VERSION = 1;

    /**
     * Properties for each object store.
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

    /**
     * Individual object stores within the search data database.
     *
     * @constant
     * @type {Object<StoreTemplate>}
     */
    const DB_STORES =
        Object.fromEntries(
            Object.keys(SEARCH_STYLE).map(
                s => [`style_${s}`, DB_STORE_TEMPLATE]
            )
        );

    /**
     * The current object store.
     *
     * @constant
     * @type {string}
     */
    const DB_STORE_NAME = `style_${pageStyle()}`;

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
    let store_items = {};

    // ========================================================================
    // Functions - page data
    // ========================================================================

    /**
     * Data for each item on the page of search results.
     *
     * @returns {PageItem[]}
     */
    function pageItems() {
        if (!page_items) {
            page_items = [];
            $result_items.each(function() {
                let $item    = $(this);
                const record = extractItemData($item);
                localStoreItem(record);
                page_items.push({ element: $item, data: record });
            });
        }
        return page_items;
    }

    /**
     * Persist data for all result items to the database object store after
     * completing store_items with items seen on other pages.
     */
    function storeItems() {
        DB.fetchItems(function(cursor, number) {
            if (cursor) {
                localStoreItem({ ...cursor.value });
            } else if (number < 0) {
                // TODO: should store_cb_queue be cleared here first?
                setStoreItemsComplete();
            } else {
                let item_data = pageItems().map(item => item.data);
                DB.storeItems(item_data, setStoreItemsComplete);
            }
        });
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
    // Variables - page data - callbacks
    // ========================================================================

    /**
     * Callbacks which are deferred until store_items_complete is true.
     *
     * @type {CallbackQueue}
     */
    let store_cb_queue = new CallbackQueue();

    /**
     * Set to true when update of the database has finished.
     *
     * @type {boolean|undefined}
     */
    let store_items_complete;

    // ========================================================================
    // Functions - page data - callbacks
    // ========================================================================

    /**
     * Whether update of the database has finished.
     *
     * @return {boolean}
     */
    function getStoreItemsComplete() {
        return !!store_items_complete;
    }

    /**
     * Process all queued callbacks and set store_items_complete.
     *
     * @return {boolean}
     */
    function setStoreItemsComplete() {
        return store_items_complete = store_cb_queue.process();
    }

    /**
     * Execute a set of function callbacks directly if store_items_complete is
     * true or queue them for execution.
     *
     * @param {function|function[]} callbacks
     */
    function whenStoreItemsComplete(...callbacks) {
        if (store_items_complete) {
            callbacks.forEach(fn => fn());
        } else {
            store_cb_queue.push(...callbacks);
        }
    }

    // ========================================================================
    // Functions - page data - database
    // ========================================================================

    /**
     * Initialize the DB closure for use by this page by informing it of the
     * database, version and object stores.
     *
     * No actual IDBDatabase changes occur until `DB.openObjectStore` is run.
     *
     * @param {string} [name]
     * @param {number} [version]
     */
    function setupDatabase(name = DB_NAME, version = DB_VERSION) {
        const db = DB.getProperties();
        if ((db.name !== name) || (db.version < version)) {
            console.warn(`===== SETUP DATABASE "${name}" v.${version} =====`);
            if (db.name && (db.name !== name)) {
                DB.closeDatabase();
            }
            DB.setDatabase(name, version);
            DB.addStoreTemplates(DB_STORES);
            DB.defaultStore(DB_STORE_NAME);
        }
    }

    /**
     * Open the database and the designated object store.
     *
     * This will trigger IDBDatabase changes if required.
     *
     * @param {string}   store        Object store name.
     * @param {function} [callback]
     */
    function openDatabase(store, callback) {
        const func = 'openDatabase';
        const name = DB_NAME;
        const db   = DB.getProperties();

        if (!DB_STORES.hasOwnProperty(store)) {
            console.error(`${func}: invalid store name "${store}"`);

        } else if (db.name !== name) {
            console.error(`${func}: must run setupDatabase() first`);

        } else if (!(db.template || {}).hasOwnProperty(store)) {
            console.error(`${func}: "${store}" not in database "${name}"`);

        } else {
            DB.openObjectStore(store, callback);
        }
    }

    /**
     * Open the database and fill the object store with items from the current
     * page of search results.
     *
     * @param {string} [store]
     */
    function updateDatabase(store = DB_STORE_NAME) {
        const func = 'updateDatabase';
        openDatabase(store, function() {
            console.warn(`======== OPENING OBJECT STORE "${store}" ========`);
            try {
                if (newSearch()) {
                    DB.clearObjectStore(store, storeItems);
                } else {
                    DB.deleteItems('page', pageNumber(), storeItems);
                }
            }
            catch (err) {
                console.warn(`${func}: ${err}`);
            }
        });
    }

    /**
     * This is a temporary transitional function. // TODO: remove eventually
     */
    function deleteOldDatabase() {
        const func    = 'deleteOldDatabase';
        const db_name = 'emma';
        console.warn(`======== CLEANING UP OLD "${db_name}" ========`);
        let request = window.indexedDB.deleteDatabase(db_name);
        request.onupgradeneeded = evt => console.log(`${func}: upgrade:`, evt);
        request.onblocked       = evt => console.warn(`${func}: in use`);
        request.onerror         = evt => console.error(`${func}:`, evt);
        request.onsuccess       = evt => console.log(`${func}: success`);
    }

    // ========================================================================
    // Actions - page data - database
    // ========================================================================

    deleteOldDatabase(); // TODO: remove eventually
    setupDatabase();
    updateDatabase();

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
     * @type {Object<string>}
     */
    const SORTED = {
        title:               'dc_title for sort=title',
        sortDate:            'sort_date for sort=sortDate',
        publicationDate:     'pub_date for sort=publicationDate',
        lastRemediationDate: 'rem_date for sort=lastRemediationDate',
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

    if (SEARCH_STYLE['aggregate']) {
        validateRelevancyScores();
    }

    // ========================================================================
    // Constants - colorize titles
    // ========================================================================

    /**
     * CSS class for the style control buttons.
     *
     * @constant
     * @type {string}
     */
    const BUTTON_TRAY_CLASS = Emma.SearchStyle.container.class;

    /**
     * Advanced experimental controls.
     *
     * @constant
     * @type {Object<StyleControlProperties>}
     */
    const BUTTON_CONFIG =
        $.extend(true, {}, Emma.SearchStyle.control.buttons, {
            restore: { func: revertStyle }
        });

    /**
     * Identity topics.
     *
     * @type {string[]}
     */
    const TOPICS = $.map(BUTTON_CONFIG,
        (prop, topic) => isDefined(prop.field) ? topic : undefined
    );

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

    /**
     * Session storage key for remembering the colorization selection.
     *
     * @const
     * @type {string}
     */
    const COLORIZE_STATE_KEY = 'search-colorize';

    // ========================================================================
    // Constants - highlight fields
    // ========================================================================

    /**
     * Session storage key for remembering the field highlighting selection.
     *
     * @const
     * @type {string}
     */
    const FIELD_HIGHLIGHT_STATE_KEY = 'search-highlight-fields';

    // ========================================================================
    // Variables - colorize/highlight
    // ========================================================================

    /**
     * Location of colorize controls.
     *
     * (This will actually be two elements, only one of which will be visible
     * for the current form factor (wide, medium, or narrow).
     *
     * @type {jQuery}
     */
    let $button_tray = $(`.heading-bar .${BUTTON_TRAY_CLASS}`);

    // ========================================================================
    // Functions - colorize titles
    // ========================================================================

    /**
     * Revert the current search results page to the normal display style.
     */
    function revertStyle() {
        const new_params = { ...params, style: 'normal' };
        window.location.href = makeUrl(new_params);
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
                whenStoreItemsComplete(() => markItemAsExile($item));
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

        const tag = data_tag || tagChar(by_topic);
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

    /**
     * Restore colorized items.
     */
    function unColorize() {
        removeIdentityNumber($result_items);
        unmarkIdentityFields($result_items);
        const item_classes = ['colorized', ...TOPICS];
        $result_items.each(function() {
            let $item  = $(this);
            let $title = $item.children('.field-Title.value');
            $title.css({ color: '', background: '' });
            $item.removeClass(item_classes);
        });
    }

    // ========================================================================
    // Functions - colorize titles
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
     * @note Must be run only after store_items is complete.
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function markItemAsExile(item) {
        let $item          = $(item);
        const store_key    = $item.attr('data-title_id');
        const current_page = pageNumber();
        let found;
        $.each(store_items[store_key], function(page, records) {
            found = isPresent(records) && (Number(page) - current_page);
            return !found; // continue unless a related item was found
        });
        if (found) {
            // Update the item's identity number tag.
            let $title = $item.children('.field-Title.value');
            let $tag   = $title.children('.identity-number');
            $tag.addClass(EXILE_MARKER);

            // Update the item itself.
            const tip = (found < 0) ? LATE_EXILE_TOOLTIP : EARLY_EXILE_TOOLTIP;
            itemStateTip($item, tip);
            $item.addClass(EXILE_MARKER);
        }
        return true;
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
        const config = BUTTON_CONFIG[by_topic];
        const field  = config?.field;
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

    /**
     * Generate a tag character used to mark the given topic in the title line.
     *
     * @param {string} by_topic
     *
     * @returns {string}
     */
    function tagChar(by_topic) {
        const special = { by_title_text: 'T' };
        return special[by_topic] || by_topic.replace(/^by_/, '')[0];
    }

    // ========================================================================
    // Functions - colorize titles
    // ========================================================================

    /**
     * ColorizeState
     *
     * @typedef {{
     *     topic:  ?(string|null|undefined),
     *     search: ?(string|null|undefined)
     * }} ColorizeState
     */

    /**
     * Get the state of colorization.
     *
     * @returns {ColorizeState}
     */
    function getColorizeState() {
        const entry = sessionStorage.getItem(COLORIZE_STATE_KEY);
        // console.log('GET COLORIZE STATE', entry);
        return fromJSON(entry) || {};
    }

    /**
     * Remember the current colorization selection in the session.
     *
     * @param {string} topic
     * @param {string} [criteria]
     */
    function setColorizeState(topic, criteria) {
        const search = criteria || currentSearch();
        const values = { topic: topic, search: search };
        const entry  = JSON.stringify(values) || '';
        // console.log('SET COLORIZE STATE', entry);
        sessionStorage.setItem(COLORIZE_STATE_KEY, entry);
    }

    /**
     * Clear the state of colorization.
     */
    function clearColorizeState() {
        // console.log('REMOVE COLORIZE STATE');
        sessionStorage.removeItem(COLORIZE_STATE_KEY);
    }

    // ========================================================================
    // Functions - colorize titles
    // ========================================================================

    /**
     * Assign event handlers to the colorize button.
     *
     * @param {string}                 topic    {@link BUTTON_CONFIG} key.
     * @param {StyleControlProperties} [config] {@link BUTTON_CONFIG} value.
     *
     * @returns {jQuery|undefined}
     */
    function setupColorizeButton(topic, config) {
        const func   = 'setupColorizeButton';
        const button = config || BUTTON_CONFIG[topic];
        let $button  = $button_tray.find(selector(button?.class));
        let action   = button?.func;
        let $result;
        if (isMissing(button)) {
            console.error(`${func}: ${topic}: invalid topic`);
        } else if (!button.active) {
            // console.log(`${func}: ${topic}: inactive topic`);
        } else if (isMissing($button)) {
            if (button.active === 'dev_only') {
                // console.log(`${func}: ${topic}: inactive topic`);
            } else {
                console.warn(`${func}: ${topic}: no buttons`);
            }
        } else if (button.class.includes('highlight')) {
            // console.log(`${func}: ${topic}: skip field highlight control`);
        } else if (button.class.includes('colorize')) {
            action ||= () => colorize(topic);
            handleClickAndKeypress($button, function() {
                let $this = $(this);
                if ($this.hasClass('active')) {
                    $this.removeClass('active');
                    clearColorizeState();
                    unColorize(topic);
                } else {
                    $this.addClass('active');
                    setColorizeState(topic);
                    action();
                }
            });
            $result = $button.removeClass('active');
        } else {
            action ||= () => console.error(`${func}: ${topic}: no action`);
            handleClickAndKeypress($button, action);
        }
        return $result;
    }

    /**
     * Set up the container for colorization controls.
     *
     * @param {Object<StyleControlProperties>} [button_config]
     *
     * @returns {jQuery|undefined}    The active button.
     */
    function setupColorizeButtons(button_config = BUTTON_CONFIG) {
        const previous    = getColorizeState();
        const re_colorize = equivalent(previous.search, currentSearch());
        // const func        = 'setupColorizeButtons';
        // console.log(`${func}: PREV TOPIC=`, previous.topic);
        // console.log(`${func}: PREV SEARCH`, previous.search);
        // console.log(`${func}: CURR SEARCH`, currentSearch());
        // console.log(`${func}: RE_COLORIZE`, re_colorize);
        let $active_button;
        $.each(button_config, function(topic, config) {
            let $button = setupColorizeButton(topic, config);
            if ($button && re_colorize && (topic === previous.topic)) {
                $active_button ||= $button.first();
            }
        });
        $active_button?.click();
        return $active_button;
    }

    // ========================================================================
    // Functions - highlight fields
    // ========================================================================

    /**
     * Highlight field groups.
     */
    function highlightFields() {
        $result_items.addClass('highlight-fields');
    }

    /**
     * Restore field display.
     */
    function unHighlightFields() {
        $result_items.removeClass('highlight-fields');
    }

    // ========================================================================
    // Functions - highlight fields
    // ========================================================================

    /**
     * FieldHighlightState
     *
     * @typedef {{
     *     enabled: ?(string|null|undefined),
     * }} FieldHighlightState
     */

    /**
     * Get the state of field highlighting.
     *
     * @returns {FieldHighlightState}
     */
    function getFieldHighlightState() {
        const entry = sessionStorage.getItem(FIELD_HIGHLIGHT_STATE_KEY);
        // console.log('GET FIELD HIGHLIGHT STATE', entry);
        return fromJSON(entry) || {};
    }

    /**
     * Remember the current field highlighting selection in the session.
     *
     * @param {boolean|FieldHighlightState} [enabled]
     */
    function setFieldHighlightState(enabled) {
        let value;
        if (typeof enabled === 'object') {
            value = enabled;
        } else {
            value = { enabled: (enabled !== false) };
        }
        const entry = JSON.stringify(value);
        // console.log('SET FIELD HIGHLIGHT STATE', entry);
        sessionStorage.setItem(FIELD_HIGHLIGHT_STATE_KEY, entry);
    }

    /**
     * Clear the state of field highlighting.
     */
    function clearFieldHighlightState() {
        // console.log('REMOVE FIELD HIGHLIGHT STATE');
        sessionStorage.removeItem(FIELD_HIGHLIGHT_STATE_KEY);
    }

    // ========================================================================
    // Functions - highlight fields
    // ========================================================================

    /**
     * Assign event handlers to the field highlighting button.
     *
     * @param {string}                 topic    {@link BUTTON_CONFIG} key.
     * @param {StyleControlProperties} [config] {@link BUTTON_CONFIG} value.
     *
     * @returns {jQuery|undefined}
     */
    function setupFieldHighlightButton(topic, config) {
        const func   = 'setupFieldHighlightButton';
        const button = config || BUTTON_CONFIG[topic];
        let $button  = $button_tray.find(selector(button?.class));
        let action   = button?.func;
        let $result;
        if (isMissing(button)) {
            console.error(`${func}: ${topic}: invalid topic`);
        } else if (!button.active) {
            // console.log(`${func}: ${topic}: inactive topic`);
            console.log(`${func}: ${topic}: inactive topic`);
        } else if (isMissing($button)) {
            if (button.active === 'dev_only') {
                // console.log(`${func}: ${topic}: inactive topic`);
                console.log(`${func}: ${topic}: inactive topic`);
            } else {
                console.warn(`${func}: ${topic}: no buttons`);
            }
        } else if (button.class.includes('colorize')) {
            // console.log(`${func}: ${topic}: skip title colorize control`);
            console.log(`${func}: ${topic}: skip title colorize control`);
        } else if (button.class.includes('highlight')) {
            action ||= () => highlightFields();
            handleClickAndKeypress($button, function() {
                let $this = $(this);
                if ($this.hasClass('active')) {
                    $this.removeClass('active');
                    clearFieldHighlightState();
                    unHighlightFields();
                } else {
                    $this.addClass('active');
                    setFieldHighlightState();
                    action();
                }
            });
            $result = $button.removeClass('active');
            console.log(`${func}: ${topic}: HIGHLIGHT CONTROL`);
        } else {
            action ||= () => console.error(`${func}: ${topic}: no action`);
            handleClickAndKeypress($button, action);
            console.warn(`${func}: ${topic}: NO ACTION`);
        }
        console.log(`${func}: result:`, $result);
        return $result;
    }

    /**
     * Set up the container for only field highlight controls.
     *
     * @param {Object<StyleControlProperties>} [button_config]
     *
     * @returns {jQuery|undefined}    The active button.
     */
    function setupFieldHighlightButtons(button_config = BUTTON_CONFIG) {
        const was_highlighting = getFieldHighlightState().enabled;
        let $active_button;
        $.each(button_config, function(topic, config) {
            let $button = setupFieldHighlightButton(topic, config);
            if ($button && was_highlighting) {
                $active_button ||= $button.first();
            }
        });
        $active_button?.click();
        return $active_button;
    }

    // ========================================================================
    // Actions - colorize
    // ========================================================================

    setupColorizeButtons();
    setupFieldHighlightButtons();

});
