// app/assets/javascripts/feature/search-analysis.js


import { AppDebug }                     from '../application/debug';
import { appSetup }                     from '../application/setup'
import { handleClickAndKeypress }       from '../shared/accessibility';
import { arrayWrap }                    from '../shared/arrays';
import { Emma }                         from '../shared/assets';
import { BaseClass }                    from '../shared/base-class';
import { rgbColor, rgbColorInverse }    from '../shared/color';
import { selector, toggleHidden }       from '../shared/css';
import { DB }                           from '../shared/database';
import { unreverseFlexChildren }        from '../shared/html';
import { compact, hasKey }              from '../shared/objects';
import { CallbackQueue }                from '../shared/queue';
import { DEF_HEX_DIGITS, HEX_BASE }     from '../shared/random';
import { SessionState, removeByPrefix } from '../shared/session-state';
import { NNBS }                         from '../shared/unicode';
import { makeUrl, urlParameters }       from '../shared/url';
import {
    isDefined,
    isMissing,
    isPresent,
    notDefined,
} from '../shared/definitions';


const MODULE = 'SearchAnalysis';
const DEBUG  = false;

AppDebug.file('feature/search-analysis', MODULE, DEBUG);

// ============================================================================
// Exported functions
// ============================================================================

/**
 * Make a hidden clone of an item's title to prepare it for use by the
 * ToggleCollapse advanced feature for file-level results.
 *
 * @param {Selector} item
 * @param {Selector} [title]    Default: from item.
 *
 * @returns {string}            ID of the visible title element.
 */
export function cloneTitle(item, title) {
    /** @type {jQuery} */
    const $item  = $(item);
    const $title = title ? $(title) : $item.find('.value.field-Title .title');

    const item_id  = $item.attr('id');
    const title_id = `title_${item_id}_txt`;

    // By default the title element is just text for file results.
    const $text_title = $title.clone();
    $text_title.attr('id',        title_id);
    $text_title.attr('data-mode', 'txt');
    $text_title.removeAttr('role tabindex aria-controls');
    $text_title.insertBefore($title);

    // Set up the title button as a hidden element to which search.js
    // will add event handlers.
    $title.attr('id',        `title_${item_id}_btn`);
    $title.attr('data-mode', 'btn');
    $title.attr('role',      'button');
    $title.attr('tabindex',  0);
    toggleHidden($title, true).toggleClass('disabled', true);

    return title_id;
}

// ============================================================================
// Actions
// ============================================================================

// noinspection FunctionTooLongJS
Emma.SEARCH_ANALYSIS && appSetup(MODULE, function() {

    /**
     * Search page `<body>`.
     *
     * @type {jQuery}
     */
    const $body = $('body.search-index');

    // Only perform these actions on the appropriate pages.
    if (isMissing($body)) { return }

    /**
     * The database holding search result item data across pages.
     *
     * @readonly
     * @type {string}
     */
    const DB_NAME = 'emma_search';

    /**
     * The current version of the database.
     *
     * @note This must be incremented every time DB_STORE_TEMPLATE or DB_STORES
     *  are changed in any way.
     *
     * @readonly
     * @type {number}
     */
    const DB_VERSION = 2;

    /**
     * Search analysis items in sessionStorage all begin with this prefix.
     *
     * @readonly
     * @type {string}
     */
    const KEY_PREFIX = 'search-analysis';

    /**
     * Reset search analysis data on normal search pages then leave.
     *
     * NOTE: The database is touched *only* if session settings were found;
     *  otherwise, on a pristine browser, the database would have to be created
     *  just for the sake of clearing it.
     */
    if (!$body.hasClass('dev-style')) {
        sessionStorage.removeItem('search-colorize'); // TODO: temporary
        removeByPrefix(KEY_PREFIX) && DB.clearAllStores(DB_NAME);
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Active search style(s).
     *
     * @type {Object.<string,boolean>}
     */
    const SEARCH_STYLE = {
        aggregate: $body.hasClass('aggregate-style'),
        compact:   $body.hasClass('compact-style'),
        grid:      $body.hasClass('grid-style'),
    };

    const DEFAULT_STYLE    = 'normal';

    const TIMESTAMP        = new Date();

    const FIRST_PAGE       = 1;
    const DEFAULT_LIMIT    = 100; // Items per page.

    const ITEM_CLASS       = 'search-list-item';
    const ITEM_SELECTOR    = selector(ITEM_CLASS);

    /**
     * Current URL parameters.
     *
     * @readonly
     * @type {object}
     */
    const params = urlParameters();

    /**
     * Current search page.
     *
     * @readonly
     * @type {number}
     */
    const PAGE_NUMBER = Number(params['page']) || FIRST_PAGE;

    /**
     * Current search page size.
     *
     * @readonly
     * @type {number}
     */
    const PAGE_SIZE = Number(params['limit']) || DEFAULT_LIMIT;

    /**
     * Item number offset for the first search result item on the current page.
     *
     * @readonly
     * @type {number}
     */
    const PAGE_OFFSET = 1 + (PAGE_SIZE * (PAGE_NUMBER - FIRST_PAGE));

    /**
     * CSS class for the style control buttons.
     *
     * @readonly
     * @type {string}
     */
    const BUTTON_TRAY_CLASS = Emma.Search.Style.container.class;

    /**
     * Advanced experimental controls.
     *
     * @readonly
     * @type {Object.<string,StyleControlProperties>}
     */
    const BUTTON_CONFIG = Emma.Search.Style.control.buttons;

    /**
     * CSS class for the button(s) for removing advanced feature controls.
     *
     * @readonly
     * @type {string}
     */
    const EXIT_BUTTON_CLASS = BUTTON_CONFIG.restore.class;

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
    const $result_items = $list_parts.filter(ITEM_SELECTOR);

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

    /**
     * The page element containing the button(s) used to activate advanced
     * features.
     *
     * @type {jQuery}
     */
    const $button_tray = $(`.heading-bar .${BUTTON_TRAY_CLASS}`);

    /**
     * Button(s) for removing advanced feature controls.
     *
     * @type {jQuery}
     */
    const $exit_button = $button_tray.find(selector(EXIT_BUTTON_CLASS));

    // ========================================================================
    // Constants - feature activation
    // ========================================================================

    const FILE_RESULTS  = (current_mode === 'file');
    const TITLE_RESULTS = !FILE_RESULTS;

    const RELEVANCY_SCORES = SEARCH_STYLE['aggregate'];
    const FIELD_GROUPS     = true;
    const FORMAT_COUNTS    = TITLE_RESULTS;
    const COLLAPSE_ITEMS   = FILE_RESULTS;
    const COLORIZE_TITLES  = true;

    // ========================================================================
    // Actions
    // ========================================================================

    // Fix tab order of buttons if necessary.
    $button_tray.each((_, tray) => unreverseFlexChildren(tray));

    // Make the button (labeled "Debug") appear "active" so that clicking on
    // it appears to deactivate it.
    $exit_button.addClass('active');
    handleClickAndKeypress($exit_button, removeDebugControls);

    // Initialize identification tooltips for each item.
    $result_items.each((index, item) => {
        /** @type {jQuery} */
        const $item  = $(item);
        const $title = $item.find('.value.field-Title .title');
        if (COLLAPSE_ITEMS && ($title.length === 1)) {
            cloneTitle($item, $title);
        }
        const number = index + PAGE_OFFSET;
        const title  = $title.text();
        $item.attr('title', `Item ${number} - "${title}"`);
    });

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Restore the current search results page to the normal display (without
     * debugging controls).
     */
    function removeDebugControls() {
        window.location.href = makeUrl(params, 'app.search.debug=false');
    }

    /**
     * Current search list display style.
     *
     * @note Can't rely on *params* because *params['style']* will have already
     *  been removed via the server redirect.
     *
     * @returns {string}
     */
    function listStyle() {
        let result;
        $.each(SEARCH_STYLE, (style, active) => {
            result = active && style;
            return !!result; // continue if not active
        });
        return result || DEFAULT_STYLE;
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
        const result = { ...params };
        delete result.page;
        delete result.offset;
        return result;
    }

    /**
     * Show the title button elements; hide the text title elements.
     */
    function buttonTitles() {
        const $titles = $result_items.find('.value.field-Title .title');
        $titles.filter('[data-mode="txt"]').each((_, text) => {
            const $text   = $(text);
            const $button = $text.siblings('.title'); //.not($text);
            toggleHidden($text,   true ).toggleClass('disabled', true);
            toggleHidden($button, false).toggleClass('disabled', false);
        });
    }

    /**
     * Show the text title elements; hide the title button elements.
     */
    function textTitles() {
        const $titles = $result_items.find('.value.field-Title .title');
        $titles.filter('[data-mode="btn"]').each((_, button) => {
            const $button = $(button);
            const $text   = $button.siblings('.title'); //.not($button);
            toggleHidden($button, true ).toggleClass('disabled', true);
            toggleHidden($text,   false).toggleClass('disabled', false);
        });
    }

    // ========================================================================
    // Functions - page data
    // ========================================================================

    /**
     * Return the *emma_titleId* value of the given search result item.
     *
     * @param {Selector} item
     *
     * @returns {string}
     */
    function titleId(item) {
        /** @type {jQuery} */
        const $item = $(item);
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
        /** @type {jQuery} */
        const $item = $(item);
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
        /** @type {jQuery} */
        const $item = $(item);
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
        /** @type {jQuery} */
        const $item = $(item);
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
        /** @type {jQuery} */
        const $item = $(item);
        const $ids  = $item.find('.field-Identifier.value').children();
        return $ids.toArray().map(element => $(element).text());
    }

    // ========================================================================
    // Constants - page data
    // ========================================================================

    // noinspection JSValidateTypes
    /**
     * Properties for each object store.
     *
     * @readonly
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
     * @readonly
     * @type {StoreTemplates}
     */
    const DB_STORES = (function() {
        const styles = [DEFAULT_STYLE, ...Object.keys(SEARCH_STYLE)];
        const pairs  = styles.map(s => [`style_${s}`, DB_STORE_TEMPLATE]);
        return Object.fromEntries(pairs);
    })();

    /**
     * The current object store.
     *
     * @readonly
     * @type {string}
     */
    const DB_STORE_NAME = `style_${listStyle()}`;

    // ========================================================================
    // Variables - page data
    // ========================================================================

    /**
     * @typedef {object} SearchDataRecord
     *
     * @property {number}   page
     * @property {string}   title_text
     * @property {string}   title_id
     * @property {string}   record_id
     * @property {string}   repo_id
     * @property {string[]} identifier
     * @property {Date}     db_timestamp
     */

    /**
     * @typedef {object} PageItem
     *
     * @property {jQuery}           element
     * @property {SearchDataRecord} data
     */

    /**
     * Data gathered for items on the current page.
     *
     * @type {PageItem[]}
     */
    let page_items;

    /**
     * Data copied from the database object store. <p/>
     *
     * Each record_id key is associated with an object containing records
     * keyed by page number.
     *
     * @type {Object.<string, Object.<string,SearchDataRecord[]>>}
     */
    const store_items = {};

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
            $result_items.each((_, item) => {
                const $item  = $(item);
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
                const item_data = pageItems().map(item => item.data);
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
        const result = {};
        const $item  = $(item);
        for (const [key, prop] of Object.entries(DB_STORE_TEMPLATE.record)) {
            result[key] = prop.func ? prop.func($item) : prop.default;
        }
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
        store_items[key] ||= {};
        store_items[key][page] ||= [];
        store_items[key][page].push(record);
    }

    // ========================================================================
    // Variables - page data - callbacks
    // ========================================================================

    /**
     * Callbacks which are deferred until items have been stored.
     *
     * @type {CallbackQueue}
     */
    const store_cb_queue = new CallbackQueue();

    // ========================================================================
    // Functions - page data - callbacks
    // ========================================================================

    /**
     * Whether update of the database has finished.
     *
     * @return {boolean}
     */
    function getStoreItemsComplete() {
        return store_cb_queue.finished;
    }

    /**
     * Process all queued callbacks.
     *
     * @return {boolean}
     */
    function setStoreItemsComplete() {
        return store_cb_queue.process();
    }

    /**
     * Execute a set of function callbacks directly if store_cb_queue is
     * finished or queue them for execution.
     *
     * @param {function|function[]} callbacks
     */
    function whenStoreItemsComplete(...callbacks) {
        if (getStoreItemsComplete()) {
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
     * database, version and object stores. <p/>
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
            } catch (error) {
                console.warn(`${func}: ${error}`);
            }
        });
    }

    /**
     * Open the database and the designated object store. <p/>
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

        if (!hasKey(DB_STORES, store)) {
            console.error(`${func}: invalid store name "${store}"`);

        } else if (db.name !== name) {
            console.error(`${func}: must run setupDatabase() first`);

        } else if (!hasKey(db.template, store)) {
            console.error(`${func}: "${store}" not in database "${name}"`);

        } else {
            DB.openObjectStore(store, callback);
        }
    }

    // ========================================================================
    // Actions - page data - database
    // ========================================================================

    setupDatabase();
    updateDatabase();

    // ========================================================================
    // Constants - relevancy score
    // ========================================================================

    /**
     * Current search results sort order.
     *
     * @readonly
     * @type {string}
     */
    const SORT_ORDER = params['sort'] || 'relevancy';

    /**
     * @readonly
     * @type {StringTable}
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
     * @readonly
     * @type {string}
     */
    const BLANK = Emma.Field.empty;

    // ========================================================================
    // Constants - colorize titles
    // ========================================================================

    /**
     * CSS marker class indicating an erroneous item.
     *
     * @readonly
     * @type {string}
     */
    const ERROR_MARKER = 'error';

    /**
     * CSS marker class indicating the metadata field associated with the
     * current topic.
     *
     * @readonly
     * @type {string}
     */
    const IDENTITY_MARKER = 'identity-highlight';

    /**
     * CSS marker class indicating an erroneous item.
     *
     * @readonly
     * @type {string}
     */
    const EXILE_MARKER = 'exile';

    /**
     * Tooltip text for an erroneous item.
     *
     * @readonly
     * @type {string}
     */
    const LATE_EXILE_TIP = Emma.Messages.search_analysis.late_exile;

    /**
     * Tooltip text for an erroneous item.
     *
     * @readonly
     * @type {string}
     */
    const EARLY_EXILE_TIP = Emma.Messages.search_analysis.early_exile;

    /**
     * Maximum integer color value.
     *
     * @readonly
     * @type {number}
     */
    const COLOR_RANGE = HEX_BASE ** DEF_HEX_DIGITS;

    /**
     * Used when generating a new contrasting item title background color.
     *
     * @readonly
     * @type {number}
     */
    const COLOR_OFFSET_LIMIT = 0x0f0000;

    // ========================================================================
    // Classes - advanced features
    // ========================================================================

    /**
     * Encapsulates handling of guesses about index relevancy scores.
     *
     * @extends BaseClass
     */
    class RelevancyScores extends BaseClass {

        static CLASS_NAME = 'RelevancyScores';

        // ====================================================================
        // Methods
        // ====================================================================

        initialize() { this._validateRelevancyScores() }

        // ====================================================================
        // Methods - internal
        // ====================================================================

        /**
         * Mark suspicious relevancy scores.
         *
         * @param {Selector} [items]      Default: {@link $result_items}.
         *
         * @protected
         */
        _validateRelevancyScores(items) {
            const mark_disabled   = (el) => this._markDisabledRelevancy(el);
            const mark_suspicious = (el) => this._markSuspiciousRelevancy(el);
            const $items          = items ? $(items) : $result_items;
            if (Object.keys(SORTED).includes(SORT_ORDER)) {
                $items.each((_, item) => mark_disabled(item));
            } else {
                let error_score, next_score = 0;
                $items.toArray().reverse().forEach(item => {
                    const $item = $(item);
                    const score = Number($item.attr('data-item_score')) || 0;
                    if (score < next_score) {
                        error_score = score;
                    } else if (score > next_score) {
                        error_score = undefined;
                    }
                    if (error_score) {
                        mark_suspicious($item);
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
         * @protected
         */
        _markDisabledRelevancy(item) {
            /** @type {jQuery} */
            const $item  = $(item);
            const $score = $item.find('.item-score');
            const order  = SORTED[SORT_ORDER];
            const desc   = order || Emma.Messages.search_analysis.fields;
            const tip    = `${Emma.Messages.search_analysis.tooltip} ${desc}`;
            return $score.addClass('disabled').attr('title', tip).text(BLANK);
        }

        /**
         * Mark the score for the item as problematic.
         *
         * @param {Selector} item
         *
         * @returns {jQuery}              The score element.
         * @protected
         */
        _markSuspiciousRelevancy(item) {
            /** @type {jQuery} */
            const $item  = $(item);
            const $score = $item.find('.item-score');
            let tip = $score.attr('title');
            tip += "\n\nNOTE:";
            tip += "The placement of this item seems to be anomalous, ";
            tip += "however that may just be due to a bad guess about how ";
            tip += "the actual relevancy is determined by the index."
            return $score.addClass('error').attr('title', tip);
        }
    }

    /**
     * Base class for dynamic activation of special features for visualizing
     * patterns in search results.
     *
     * @extends SessionState
     */
    class AdvancedFeature extends SessionState {

        static CLASS_NAME = 'AdvancedFeature';
        static DEBUGGING  = DEBUG;

        // ====================================================================
        // Fields
        // ====================================================================

        /** @type {boolean}   */ valid = true;
        /** @type {string}    */ button_class;
        /** @type {optString} */ topic;

        // ====================================================================
        // Fields - internal
        // ====================================================================

        /**
         * The page element containing the button(s) used to activate
         * features.
         *
         * @type {jQuery}
         * @protected
         */
        _button_tray;

        /**
         * The subset of button tray button(s) associated with the feature.
         *
         * @type {jQuery}
         * @protected
         *
         * @see $buttons
         */
        _feature_buttons;

        // ====================================================================
        // Constructor
        // ====================================================================

        /**
         * Create a new instance.
         *
         * @param {string|RegExp} key_base
         * @param {optString}     [button_class]
         * @param {optString}     [topic]
         */
        constructor(key_base, button_class, topic) {
            /** @type {string|RegExp} */
            let bc   = button_class;
            let base = key_base;
            if (base instanceof RegExp) {
                bc ||= base;
                base = base.source;
            }
            bc ||= base;
            bc &&= bc.endsWith('-button') ? bc : `${bc}-button`;
            base = base?.replace(/-button$/, '');

            super(base);

            this.button_class = bc;
            this.topic        = topic;

            this._button_tray = $button_tray;
        }

        // ====================================================================
        // Properties
        // ====================================================================

        /**
         * The subset of button tray button(s) associated with the feature.
         *
         * @returns {jQuery}
         */
        get $buttons() {
            return this._feature_buttons ||=
                this._findButton(this.button_class);
        }

        /**
         * Indicate whether the feature is active.
         *
         * @returns {boolean}
         */
        get active() {
            return this.$buttons?.hasClass('active') || false;
        }

        /**
         * Indicate whether the feature is disabled.
         *
         * @returns {boolean}
         */
        get disabled() {
            return !this.$buttons || this.$buttons.hasClass('disabled');
        }

        // ====================================================================
        // Methods
        // ====================================================================

        /**
         * Activate the associated feature. <p/>
         *
         * Derived classes extend this method to include the operations for
         * modifying the display.
         *
         * @param {*} [_arg]           Unused in the base class.
         */
        activate(_arg) {
            this.update();
        }

        /**
         * De-activate the associated feature. <p/>
         *
         * Derived classes extend this method to include the operations for
         * modifying the display.
         */
        deactivate() {
            this.clear();
        }

        /**
         * Disable the feature by hiding its control button(s).
         */
        disable() {
            this.disabled || this.$buttons.addClass('disabled');
        }

        /**
         * Set up the control button(s) associated with the feature.
         *
         * @param {boolean} [refresh]
         * @param {string}  [active_topic]
         *
         * @returns {jQuery|undefined}  The active button.
         */
        initialize(refresh, active_topic) {
            if (!this.valid) {
                return undefined;
            }
            const any_topic = notDefined(active_topic);
            let $active     = undefined;
            let count       = 0;
            for (const [topic, config] of Object.entries(BUTTON_CONFIG)) {
                const $button = this._setupButton(topic, config);
                if ($button && (any_topic || (topic === active_topic))) {
                    count++;
                    if (refresh) {
                        $active ||= $button.first();
                    }
                }
            }
            if ((this.valid = !!count)) {
                $active?.trigger('click');
            } else {
                this._debug('feature not present');
            }
            return $active;
        }

        /**
         * Set up the control button(s) associated with the feature.  If the
         * class instance is or becomes invalid, disable the associated button
         * control.
         *
         * @param {boolean} [refresh]
         * @param {string}  [active_topic]
         *
         * @returns {jQuery|undefined}  The active button.
         */
        initializeOrDisable(refresh, active_topic) {
            let $active_button = this.initialize(refresh, active_topic);
            if (!this.valid) {
                this.disable();
                $active_button = undefined;
            }
            return $active_button;
        }

        // ====================================================================
        // Methods - internal
        // ====================================================================

        /**
         * Indicate whether the name is associated with a valid button class.
         *
         * @param {string} name
         *
         * @returns {boolean}
         * @protected
         */
        _isControlButton(name) {
            const match = this.button_class;
            if (typeof match === 'string') {
                return (name === match) || name.includes(match);
            } else {
                // noinspection JSUnresolvedFunction
                return (match instanceof RegExp) && match.test(name);
            }
        }

        /**
         * Find the indicated button(s) in the button tray.
         *
         * @param {string|null|undefined} class_name
         *
         * @returns {jQuery|null|undefined}
         * @protected
         */
        _findButton(class_name) {
            return class_name && this._button_tray.find(selector(class_name));
        }

        // noinspection FunctionWithInconsistentReturnsJS
        /**
         * Assign event handlers to the indicated button if it matches
         * {@link button_class}.
         *
         * @param {string}                 topic    {@link BUTTON_CONFIG} key
         * @param {StyleControlProperties} [config] {@link BUTTON_CONFIG} value
         *
         * @returns {jQuery|undefined}
         * @protected
         */
        _setupButton(topic, config) {
            const t      = topic  || this.topic;
            const func   = `_setupButton: ${t}`;
            /** @type {StyleControlProperties} */
            const button = config || BUTTON_CONFIG[t] || {};

            if (isMissing(button.class)) {
                return this._error(`${func}: invalid topic`);
            } else if (!this._isControlButton(button.class)) {
                return this._debug(`${func}: skip button '${button.class}'`);
            } else if (!button.enabled) {
                return this._debug(`${func}: inactive topic`);
            }

            const $topic_buttons = this._findButton(button.class);
            if (isMissing($topic_buttons)) {
                if (button.enabled === 'dev_only') {
                    return this._debug(`${func}: inactive topic`);
                } else {
                    return this._warn(`${func}: no control button`);
                }
            }

            const $tray_buttons = this.$buttons;
            const activate      = button.func || (() => this.activate(topic));
            const deactivate    = (() => this.deactivate());
            handleClickAndKeypress($topic_buttons, function() {
                const $this = $(this);
                if ($this.hasClass('active')) {
                    $this.removeClass('active');
                    deactivate();
                } else {
                    $tray_buttons.removeClass('active');
                    $this.addClass('active');
                    activate();
                }
            });

            return $topic_buttons.removeClass('active');
        }

        // ====================================================================
        // Class properties - SessionState overrides
        // ====================================================================

        static get keyPrefix() { return KEY_PREFIX }
    }

    /**
     * Manage a feature controlled by toggling a marker class on $item_list.
     *
     * @extends AdvancedFeature
     */
    class ToggleFeature extends AdvancedFeature {

        static CLASS_NAME = 'ToggleFeature';

        // ====================================================================
        // Fields
        // ====================================================================

        /** @type {string} */ list_class;

        // ====================================================================
        // Constructor
        // ====================================================================

        /**
         * Create a new instance.
         *
         * @param {string|RegExp} key_base
         * @param {optString}     [button_class]
         * @param {optString}     [list_class]
         * @param {optString}     [topic]
         */
        constructor(key_base, button_class, list_class, topic) {
            let bc = button_class;
            let re = (key_base instanceof RegExp);
            let kb = re ? key_base.source : key_base;
            if (kb?.endsWith('-button')) {
                bc ||= kb;
                kb   = kb.replace(/-button$/, '');
            } else if (re) {
                bc ||= RegExp(`${kb}-button`);
            } else if (kb) {
                bc ||= `${kb}-button`;
            }
            super(kb, bc, (topic || kb));
            this.list_class = list_class || kb;
            this.valid      = this._validate();
        }

        // ====================================================================
        // Methods - internal
        // ====================================================================

        /**
         * _validate
         *
         * @returns {boolean}
         * @protected
         */
        _validate() {
            const item_values = {
                button_class: this.button_class,
                list_class:   this.list_class,
                topic:        this.topic,
            };
            const error = [];
            for (const [item, value] of Object.entries(item_values)) {
                if (!value) {
                    error.push(`missing ${item}`);
                } else if (typeof value !== 'string') {
                    error.push(`${item}: '${value}' is not a string`);
                }
            }
            error.forEach(msg => this._error(msg));
            return isMissing(error);
        }

        // ====================================================================
        // Properties - SessionState overrides
        // ====================================================================

        /**
         * Get the feature state from sessionStorage.
         *
         * @returns {boolean}
         */
        get value() {
            return super.value.enabled === true;
        }

        /**
         * Set the feature state in sessionStorage.
         *
         * @param {boolean|ToggleState} new_value
         */
        set value(new_value) {
            super.value = this._objectify(new_value || false);
        }

        // ====================================================================
        // Properties
        // ====================================================================

        /**
         * An alias for this.value.
         *
         * @returns {boolean}
         */
        get enabled() { return this.value }

        /**
         * The page element to which the list_class is added or removed in
         * order to enable or disable the associated feature.
         *
         * @returns {jQuery}
         */
        get $root() { return $item_list }

        // ====================================================================
        // Methods - SessionState overrides
        // ====================================================================

        /**
         * Persist current settings to sessionStorage.
         *
         * @param {boolean|ToggleState} new_value   Default: **true**.
         */
        update(new_value) {
            this.value = notDefined(new_value) || new_value;
        }

        // ====================================================================
        // Methods - AdvancedFeature overrides
        // ====================================================================

        /**
         * Activate the associated feature.
         *
         * @param {*} [arg]
         */
        activate(arg) {
            super.activate(arg);
            this.$root.addClass(this.list_class);
        }

        /**
         * De-activate the associated feature.
         */
        deactivate() {
            super.deactivate();
            this.$root.removeClass(this.list_class);
        }

        /**
         * Set up the control button(s) associated with the feature.
         *
         * @param {boolean} [refresh]       `this.enabled` by default.
         * @param {string}  [_prev_topic]   Ignored.
         *
         * @returns {jQuery|undefined}      The active button.
         */
        initialize(refresh, _prev_topic) {
            const show = isDefined(refresh) ? refresh : this.enabled;
            return super.initialize(show);
        }
    }

    /**
     * Highlight field groups.
     *
     * @extends ToggleFeature
     */
    class ToggleFieldGroups extends ToggleFeature {

        static CLASS_NAME = 'ToggleFieldGroups';

        // ====================================================================
        // Constructor
        // ====================================================================

        constructor(key_base = 'field_groups') { super(key_base) }

        // ====================================================================
        // Methods - AdvancedFeature overrides
        // ====================================================================

        /**
         * Activate the associated feature.
         *
         * @param {*} [arg]
         */
        activate(arg) {
            const scope_note       = ($pair) => this.scopeNote($pair);
            const saved_title_attr = 'data-pre-field-group-title';
            this.$root.find('.pair').each((_, pair) => {
                const $pair     = $(pair);
                const cur_title = $pair.attr('title');
                let note;
                if (cur_title && (note = scope_note($pair))) {
                    let old_title = $pair.attr(saved_title_attr);
                    if (!old_title) {
                        old_title = cur_title;
                        $pair.attr(saved_title_attr, old_title);
                    }
                    $pair.attr('title', `${old_title}\n\n${note}`);
                }
            });
            super.activate(arg);
        }

        /**
         * De-activate the associated feature.
         */
        deactivate() {
            super.deactivate();
            const saved_title_attr = 'data-pre-field-group-title';
            this.$root.find('.pair').each((_, pair) => {
                const $pair     = $(pair);
                const old_title = $pair.attr(saved_title_attr);
                if (old_title) {
                    $pair.attr('title', old_title);
                }
            });
        }

        // ====================================================================
        // Methods
        // ====================================================================

        /**
         * Create a tooltip addition base on the item's "scope-*" classes.
         *
         * @param {Selector} item
         *
         * @returns {string}
         */
        scopeNote(item) {
            const $item = $(item);
            const part  = [];
            arrayWrap($item[0]?.classList)
                .filter(cls => cls.startsWith('scope-'))
                .forEach(cls => {
                    const scope = cls.replace('scope-', '').toUpperCase();
                    switch (scope) {
                        case 'PARTS': case 'FORMATS':                break;
                        case 'FILES': part[0] = 'FILE-level';        break;
                        case 'TITLE': part[0] = 'TITLE-level';       break;
                        default:      part[1] = `${scope} metadata`; break;
                    }
                });
            return compact(part).join(' ');
        }
    }

    /**
     * Show counts of formats associated with a hierarchical title entry.
     *
     * @extends ToggleFeature
     */
    class ToggleFormatCounts extends ToggleFeature {

        static CLASS_NAME = 'ToggleFormatCounts';

        // ====================================================================
        // Constructor
        // ====================================================================

        constructor(key_base = 'format_counts') { super(key_base) }
    }

    /**
     * Collapse (file-level) search result items.
     *
     * @extends ToggleFeature
     */
    class ToggleCollapsed extends ToggleFeature {

        static CLASS_NAME = 'ToggleCollapsed';

        // ====================================================================
        // Constructor
        // ====================================================================

        constructor(key_base = 'collapsed') { super(key_base) }

        // ====================================================================
        // Methods - AdvancedFeature overrides
        // ====================================================================

        /**
         * Activate the associated feature.
         *
         * @param {*} [arg]
         */
        activate(arg) {
            buttonTitles();
            toggleHidden($result_items.children().not('.disabled'), false);
            $result_items.removeClass('open');
            super.activate(arg);
        }

        /**
         * Collapse result items.
         */
        deactivate() {
            textTitles();
            toggleHidden($result_items.children().not('.disabled'), false);
            $result_items.removeClass('open');
            super.deactivate();
        }
    }

    /**
     * Manage title colorization.
     *
     * @extends AdvancedFeature
     */
    class ColorizeFeature extends AdvancedFeature {

        static CLASS_NAME = 'ColorizeFeature';

        // ====================================================================
        // Type definitions
        // ====================================================================

        /**
         * @typedef {object} ColorizeState
         *
         * @property {string} [topic]
         * @property {object} [search]
         */

        // ====================================================================
        // Fields
        // ====================================================================

        /**
         * Identity topics.
         *
         * @type {string[]}
         */
        TOPICS = [];

        // ====================================================================
        // Constructor
        // ====================================================================

        /**
         * Create a new instance.
         *
         * @param {string} [key_base]
         */
        constructor(key_base = 'colorize') {
            super(key_base);
            this.topic = '';
            this.TOPICS = $.map(BUTTON_CONFIG,
                (prop, topic) => isDefined(prop.field) ? topic : undefined
            );
        }

        // ====================================================================
        // Properties
        // ====================================================================

        /**
         * The CSS class which marks the current topic.
         *
         * @returns {string|undefined}
         */
        get topicClass() {
            return this._topicClass(this.topic);
        }

        /**
         * The CSS class which marks the current topic.
         *
         * @returns {string|undefined}
         */
        get topicSelector() {
            const topic_class = this.topicClass;
            return topic_class && selector(topic_class);
        }

        /**
         * The button for the current topic.
         *
         * @returns {jQuery|undefined}
         */
        get $topicButton() {
            const match   = this.topicSelector;
            const $button = match && this.$buttons?.filter(match);
            return isPresent($button) ? $button : undefined;
        }

        // ====================================================================
        // Properties - SessionState overrides
        // ====================================================================

        /** @returns {ColorizeState} */
        get value() { return super.value }

        /** @param {ColorizeState} new_value */
        set value(new_value) { super.value = new_value }

        // ====================================================================
        // Methods - SessionState overrides
        // ====================================================================

        /**
         * Persist current settings to sessionStorage.
         *
         * @param {ColorizeState} [new_value]
         */
        update(new_value) {
            if (typeof new_value === 'object') {
                this.topic = new_value.topic || this.topic;
                this.value = new_value;
            } else {
                this.value = { topic: this.topic, search: currentSearch() };
            }
        }

        // ====================================================================
        // Properties - AdvancedFeature overrides
        // ====================================================================

        /**
         * Indicate whether the feature is active.
         *
         * @returns {boolean}
         */
        get active() {
            return this.$topicButton?.hasClass('active') || false;
        }

        // ====================================================================
        // Methods - AdvancedFeature overrides
        // ====================================================================

        /**
         * Colorize titles.
         *
         * @param {string} [topic]    Update the topic.
         */
        activate(topic) {
            this.topic = topic || this.topic;
            super.activate();
            this._colorize(this.topic);
        }

        /**
         * Remove colorization of titles.
         */
        deactivate() {
            super.deactivate();
            this._unColorize();
        }

        /**
         * Set up the container for the colorize buttons.
         *
         * @param {boolean} [refresh]
         * @param {string}  [new_topic]
         *
         * @returns {jQuery|undefined}  The active button.
         */
        initialize(refresh, new_topic) {
            const previous = this.value;
            const topic    = new_topic || previous.topic;
            const colorize = isDefined(refresh) ? refresh : isDefined(topic);
            return super.initialize(colorize, topic);
        }

        // ====================================================================
        // Methods - internal
        // ====================================================================

        /**
         * Colorize list items based on the given topic.
         *
         * @param {string} by_topic
         * @param {string} [data_tag]
         *
         * @protected
         */
        _colorize(by_topic, data_tag) {
            const item_lists = this._buildLists(by_topic);
            this._validateLists(item_lists, by_topic);
            this._colorizeLists(item_lists, by_topic, data_tag);
        }

        /**
         * Create a table of lists of items related by the indicated identity.
         *
         * @param {string} by_topic
         *
         * @returns {object[]}
         * @protected
         */
        _buildLists(by_topic) {
            const related_item_lists = {};
            const index_key = by_topic.replace(/^by_/, '');
            pageItems().forEach(page_item => {
                const $item = page_item.element;
                arrayWrap(page_item.data[index_key]).forEach(value => {
                    const id = `${value}-`; // Bust sorting behavior of Object.
                    const related_items = related_item_lists[id] || [];
                    related_items.push($item);
                    related_item_lists[id] = related_items;
                });
            });
            return Object.values(related_item_lists);
        }

        /**
         * Mark as errors items which are not being displayed in the proper
         * order.
         *
         * @param {object[]} item_lists
         * @param {string}   _by_topic
         *
         * @protected
         */
        _validateLists(item_lists, _by_topic) {
            const mark_as_error = this._markItemAsError.bind(this);
            const mark_as_exile = this._markItemAsExile.bind(this);
            item_lists.forEach(item_list => {
                let prev;
                item_list.forEach(item => {
                    const $item = $(item);

                    // Mark items that belong with a set of item(s) encountered
                    // earlier on the page.
                    if (prev && ($item.prevAll(ITEM_SELECTOR)[0].id !== prev)){
                        mark_as_error($item);
                    } else {
                        prev = $item[0].id;
                    }

                    // Mark items which were encountered on other pages.
                    whenStoreItemsComplete(() => mark_as_exile($item));
                });
            });
        }

        /**
         * Give the same color to each set of associated list items and
         * annotate them with a marker to help identify related items.
         *
         * @param {object[]} item_lists
         * @param {string}   by_topic
         * @param {string}   data_tag
         *
         * @protected
         */
        _colorizeLists(item_lists, by_topic, data_tag) {

            // Because not every search result item may be visited below, clear
            // out all non-relevant identity tags and highlighting of metadata
            // fields.
            const others = this.TOPICS.filter(topic => (topic !== by_topic));
            this._removeIdentityNumber($result_items, others);
            this._unmarkIdentityFields($result_items);

            const add_identity_number = this._addIdentityNumber.bind(this);
            const mark_identity_field = this._markIdentityField.bind(this);
            const color_offset        = this._semiRandomColorOffset.bind(this);

            const tag = data_tag || this._tagChar(by_topic);
            let color = Math.floor(Math.random() * COLOR_RANGE);
            item_lists.forEach((item_list, index) => {
                const number   = `${tag}-${index+1}`;
                const bg_color = rgbColor(color);
                const fg_color = rgbColorInverse(color);
                item_list.forEach((item, position) => {
                    /** @type {jQuery} */
                    const $item  = $(item);
                    const $title = $item.find('.field-Title.value');
                    $title.css({ color: fg_color, background: bg_color });
                    if (!$item.is(`.colorized.${by_topic}`)) {
                        add_identity_number($item, by_topic, number, position);
                        $item.addClass(`colorized ${by_topic}`);
                    }
                    mark_identity_field($item, by_topic);
                });
                color = color_offset(color);
            });
        }

        /**
         * Restore colorized items.
         *
         * @protected
         */
        _unColorize() {
            this._removeIdentityNumber($result_items);
            this._unmarkIdentityFields($result_items);
            const item_classes = ['colorized', ...this.TOPICS];
            $result_items.each((_, item) => {
                /** @type {jQuery} */
                const $item  = $(item);
                const $title = $item.find('.field-Title.value');
                $title.css({ color: '', background: '' });
                $item.removeClass(item_classes);
            });
        }

        // ====================================================================
        // Methods - internal
        // ====================================================================

        /**
         * Add or replace the portion of the item tooltip indicating the nature
         * of the result list item.
         *
         * @param {Selector} item
         * @param {string}   state_text
         * @param {string}   [separator]
         *
         * @protected
         */
        _itemStateTip(item, state_text, separator = "\n\n") {
            const $item = $(item);
            const tip   = $item.attr('title') || '';
            const parts = tip.split(separator, 2);
            let new_tip = parts[0].trimEnd();
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
         * @protected
         */
        _markItemAsError(item) {
            const $item = $(item);
            $item.addClass(ERROR_MARKER)
            this._itemStateTip($item, Emma.Messages.search_analysis.error);
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
         * @protected
         */
        _markItemAsExile(item) {
            /** @type {jQuery} */
            const $item      = $(item);
            const store_keys = $item.attr('data-title_id') || '';
            const curr_page  = pageNumber();
            let found;
            store_keys.split(',').forEach(key => {
                if (!found) {
                    $.each(store_items[key], (page, recs) => {
                        found = isPresent(recs) && (Number(page) - curr_page);
                        return !found; // continue unless related item found
                    });
                }
            });
            if (found) {
                // Update the item's identity number tag.
                const $title = $item.find('.field-Title.value');
                const $tag   = $title.children('.identity-number');
                $tag.addClass(EXILE_MARKER);

                // Update the item itself.
                const tip = (found < 0) ? LATE_EXILE_TIP : EARLY_EXILE_TIP;
                this._itemStateTip($item, tip);
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
         *
         * @protected
         */
        _addIdentityNumber(item, by_topic, identity, position) {
            /** @type {jQuery} */
            const $item  = $(item);
            const error  = $item.hasClass(ERROR_MARKER);
            const exile  = $item.hasClass(EXILE_MARKER);
            const $title = $item.find('.field-Title.value');
            const $logo  = $title.children('.logo');
            let $t_tag;
            if (error) {
                $t_tag = $(`<a href="#${identity}">`).addClass(ERROR_MARKER);
                $t_tag.attr('title', Emma.Messages.search_analysis.jump);
                if (exile) { $t_tag.addClass(EXILE_MARKER) }
            } else if (exile) {
                $t_tag = $('<div>').addClass(EXILE_MARKER);
            } else if (position) {
                $t_tag = $('<div>').attr('id', null);
            } else {
                $t_tag = $('<div>').attr('id', identity);
                const tip = `First occurrence of identity "${identity}"`;
                this._itemStateTip($item, tip);
            }
            $t_tag.addClass(`identity-number ${by_topic}`);
            $t_tag.text(`[${NNBS}${identity}${NNBS}]`);
            $t_tag.insertBefore($logo);
        }

        /**
         * Remove an identity number previously added to an item's title.
         *
         * @param {Selector}        [item]      Default: {@link $result_items}.
         * @param {string|string[]} [by_topic]  Default: {@link TOPICS}.
         *
         * @protected
         */
        _removeIdentityNumber(item, by_topic) {
            const $items = item ? $(item) : $result_items;
            const topics = by_topic ? arrayWrap(by_topic) : this.TOPICS;
            let $tags    = $items.find('.identity-number');
            if (by_topic) {
                $tags = $tags.filter(topics.map(t => `.${t}`).join(', '));
            }
            topics.forEach(topic => $items.removeClass(topic));
            $tags.remove();
        }

        /**
         * Highlight the item's metadata field associated with the current
         * topic.
         *
         * @param {Selector} item
         * @param {string}   by_topic
         *
         * @protected
         */
        _markIdentityField(item, by_topic) {
            const config = BUTTON_CONFIG[by_topic];
            const field  = config?.field;
            if (field) {
                const $items = item ? $(item) : $result_items;
                $items.find(`.value.${field}`).addClass(IDENTITY_MARKER);
            }
        }

        /**
         * Clear highlighting of item metadata field(s).
         *
         * @param {Selector} [item]   Default {@link $result_items}.
         *
         * @protected
         */
        _unmarkIdentityFields(item) {
            const $items = item ? $(item) : $result_items;
            $items.find(IDENTITY_MARKER).removeClass(IDENTITY_MARKER);
        }

        /**
         * Generate a new color value which is random but sufficiently
         * different that it is contrasting.
         *
         * @param {number} color
         * @param {number} [offset_limit]
         *
         * @returns {number}
         * @protected
         */
        _semiRandomColorOffset(color, offset_limit = COLOR_OFFSET_LIMIT) {
            let result = color + Math.floor(Math.random() * COLOR_RANGE);
            if (result < offset_limit) {
                result += offset_limit;
            } else if (result > (COLOR_RANGE - offset_limit)) {
                result -= offset_limit;
            }
            return result % COLOR_RANGE;
        }

        /**
         * Generate a tag character used to mark the given topic in the title
         * line.
         *
         * @param {string} by_topic
         *
         * @returns {string}
         * @protected
         */
        _tagChar(by_topic) {
            const special = { by_title_text: 'T' };
            return special[by_topic] || by_topic.replace(/^by_/, '')[0];
        }

        /**
         * The CSS class which indicates the given topic.
         *
         * @param {string} topic
         *
         * @returns {string|undefined}
         * @protected
         */
        _topicClass(topic) {
            if (typeof topic === 'string') {
                return 'by_' + topic.replace(/^\./, '').replace(/^by_/, '');
            }
        }
    }

    // ========================================================================
    // Actions - advanced features
    // ========================================================================

    RELEVANCY_SCORES && new RelevancyScores().initialize();
    FIELD_GROUPS     && new ToggleFieldGroups().initializeOrDisable();
    FORMAT_COUNTS    && new ToggleFormatCounts().initializeOrDisable();
    COLLAPSE_ITEMS   && new ToggleCollapsed().initializeOrDisable();
    COLORIZE_TITLES  && new ColorizeFeature().initializeOrDisable();
});
