// app/assets/javascripts/feature/database.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

/**
 * RecordProperties
 *
 * @note The optional "default" entry is only used by the database client.
 *
 * @typedef {{
 *     default: ?*,
 *     index:   ?(boolean|IDBIndexParameters),
 *     func:    ?function:IDBValidKey,
 * }} RecordProperties
 */

/**
 * StoreTemplate
 *
 * @typedef {{
 *     options: IDBObjectStoreParameters,
 *     record:  Object<RecordProperties>,
 * }} StoreTemplate
 */

/**
 * DatabaseProperties
 *
 * @typedef {{
 *      name:     string,
 *      version:  number,
 *      store:    string,
 *      template: Object<StoreTemplate>,
 * }} DatabaseProperties
 */

/**
 * @typedef {Object<StoreTemplate>} StoreTemplates
 */

/**
 * @typedef {
 *      function(StoreTemplates|string,?StoreTemplate):StoreTemplates
 * } FunctionStoreTemplate
 */

/**
 * @typedef {
 *      function(StoreTemplates|string,?StoreTemplate):StoreTemplates
 * } FunctionObjectStore
 */

/**
 * @typedef {
 *      function(?function(IDBCursorWithValue|null,?number))
 * } FunctionWithCursorCallback
 */

/**
 * @typedef {
 *      function(string,any,?function(object[]))
 * } FunctionWithObjectsCallback
 */

/**
 * @typedef {
 *      function(string,any,?function(number))
 * } FunctionWithNumberCallback
 */

/**
 * @typedef {
 *      function(string,any,?function(IDBValidKey[]))
 * } FunctionWithKeysCallback
 */

/**
 * An interface to the browser object store.
 *
 * @type {object}
 * @property {function:DatabaseProperties}          getProperties
 * @property {function(string,?number)}             setDatabase
 * @property {function(?string):string}             defaultStore
 * @property {function(?string):StoreTemplate}      getStoreTemplate
 * @property {FunctionStoreTemplate}                addStoreTemplates
 * @property {FunctionObjectStore}                  openObjectStore
 * @property {FunctionObjectStore}                  clearObjectStore
 * @property {function(object|object[], ?function)} storeItems
 * @property {FunctionWithCursorCallback}           fetchItems
 * @property {FunctionWithObjectsCallback}          lookupItems
 * @property {FunctionWithNumberCallback}           countItems
 * @property {FunctionWithKeysCallback}             lookupStoreKeys
 * @property {function(string,any)}                 deleteItems
 * @property {function:IDBDatabase}                 database
 * @property {function}                             closeDatabase
 */
let DB = (function() {

    /**
     * IndexQueryValue
     *
     * @typedef {IDBValidKey|IDBKeyRange} IndexQueryValue
     */

    /**
     * IndexQueryArgs
     *
     * @typedef {{
     *     name:      string,
     *     value:     ?IndexQueryValue,
     *     count:     ?number,
     *     direction: ?(IDBCursorDirection|undefined),
     * }} IndexQueryArgs
     */

    // ========================================================================
    // Constants
    // ========================================================================

    const DEBUG = false;

    /**
     * Database for applications uses.
     *
     * @constant
     * @type {string}
     */
    const DEFAULT_DB_NAME = 'emma';

    /**
     * Current version of the client database schemas.
     *
     * @constant
     * @type {number}
     */
    const DEFAULT_DB_VERSION = 1;

    /**
     * Transaction modes.
     *
     * @constant
     * @type {string[]}
     */
    const TRANSACTION_MODE = ['readonly', 'readwrite', 'versionchange'];

    /**
     * Normal transaction mode.
     *
     * @constant
     * @type {string}
     */
    const DEFAULT_TRANSACTION_MODE = 'readwrite';

    // ========================================================================
    // Variables - analysis
    // ========================================================================

    /**
     * An instance of a database object.
     *
     * @type {IDBDatabase}
     */
    let db_handle;

    /**
     * The name of the current database.
     *
     * @type {string}
     */
    let db_name;

    /**
     * The version of the current database.
     *
     * @type {number}
     */
    let db_version;

    /**
     * Default object store name.
     *
     * @type {string}
     */
    let default_store;

    /**
     * Properties for each named object store.
     *
     * @type {Object<StoreTemplate>}
     */
    let store_template = {};

    /**
     * A flag to allow details of the object store to be displayed only once.
     *
     * @type {boolean}
     */
    let debug_store = DEBUG;

    // ========================================================================
    // Functions - internal
    // ========================================================================

    function dbError(...args) {
        const tag     = 'DB ERROR';
        const message = args.join(': ');
        console.error(tag, message);
        //addFlashError(message || tag);
    }

    function dbWarn(...args) {
        const tag     = 'DB ERROR';
        const message = args.join(': ');
        console.warn(tag, message);
        //addFlashMessage(message || tag);
    }

    function dbLog(...args) {
        const tag     = 'DB';
        const message = args.join(': ') || 'EMPTY MESSAGE';
        console.log(tag, message);
    }

    function dbDebug(...args) {
        if (DEBUG) {
            dbLog(...args);
        }
    }

    // ========================================================================
    // Functions - internal
    // ========================================================================

    /**
     * dbMakeIndexQueryArgs
     *
     * @param {string}          index_key
     * @param {IndexQueryValue} [index_value]
     *
     * @returns {IndexQueryArgs}
     */
    function dbMakeIndexQueryArgs(index_key, index_value) {
        /** @type {IndexQueryArgs} */
        let result  = {};
        result.name = index_key;
        if (isDefined(index_value)) {
            result.value = index_value;
        }
        return result;
    }

    /**
     * Coalesce runs of object store keys into one or more key ranges.
     *
     * @note This assumes that the keys are integers.
     *
     * @param {number[]} store_keys
     *
     * @returns {IDBKeyRange[]}
     */
    function dbNumberKeyRanges(store_keys) {
        let result = [];
        if (notEmpty(store_keys)) {
            const last_slot = store_keys.length - 1;
            let first_key   = store_keys[0];
            let prev_key    = first_key - 1;
            store_keys.forEach(function(store_key, array_slot) {
                const close_range = (store_key !== (prev_key + 1));
                const final_range = (array_slot === last_slot);
                if (close_range && final_range) {
                    result.push(IDBKeyRange.bound(first_key, prev_key));
                    result.push(IDBKeyRange.bound(store_key, store_key));
                } else if (final_range) {
                    result.push(IDBKeyRange.bound(first_key, store_key));
                } else if (close_range) {
                    result.push(IDBKeyRange.bound(first_key, prev_key));
                    prev_key = first_key = store_key;
                } else {
                    prev_key = store_key;
                }
            });
        }
        return result;
    }

    /**
     * Get/set the persisted name of the current database.
     *
     * @param {string} [new_name]
     *
     * @returns {string}
     */
    function savedDbName(new_name) {
        if (new_name) {
            localStorage.setItem('idb-current', new_name);
        }
        return new_name || localStorage.getItem('idb-current');
    }

    /**
     * Get/set the persisted version of the current database.
     *
     * @param {number} [new_version]
     *
     * @returns {number}
     */
    function savedDbVersion(new_version) {
        const table = fromJSON(localStorage.getItem('idb-version')) || {};
        const name  = dbName();
        if (new_version) {
            table[name] = new_version;
            localStorage.setItem('idb-version', asString(table));
        }
        return table[name];
    }

    // ========================================================================
    // Functions - internal
    // ========================================================================

    /**
     * Get/set the name of the current database.
     *
     * @param {string} [new_name]
     *
     * @returns {string}
     */
    function dbName(new_name) {
        if (new_name) {
            return db_name = savedDbName(new_name);
        } else {
            return db_name ||= savedDbName() || DEFAULT_DB_NAME;
        }
    }

    /**
     * Get/set the version of the current database.
     *
     * @param {number} [new_version]
     *
     * @returns {number}
     */
    function dbVersion(new_version) {
        if (new_version) {
            return db_version = savedDbVersion(new_version);
        } else {
            return db_version ||= savedDbVersion() || DEFAULT_DB_VERSION;
        }
    }

    /**
     * Return *db_handle* or assign a new *db_handle* and set up generic event
     * handlers for it.
     *
     * @param {IDBDatabase} [new_db]
     *
     * @returns {IDBDatabase}
     */
    function dbDatabase(new_db) {
        if (new_db && (db_handle !== new_db)) {
            const func = 'dbDatabase';

            if (db_handle) {
                dbCloseDatabase(func);
            }

            db_handle = new_db;
            db_handle.onversionchange = event => dbSetupDatabase(event, func);
            db_handle.onclose         = event => onClose(event);
            db_handle.onabort         = event => onGenericAbort(event);
            db_handle.onerror         = event => onGenericError(event);

            // ================================================================
            // Event handlers
            // ================================================================

            function onClose(event) {
                dbLog(func, 'DATABASE CLOSING');
                console.log(event);
            }

            function onGenericAbort(event) {
                dbWarn(func, 'OPERATION ABORTED');
                console.log(event);
            }

            function onGenericError(event) {
                dbError(func, 'OPERATION ERROR', asString(event));
                console.log(event);
            }
        }
        return db_handle;
    }

    /**
     * Create the named object store and set up indices according to its
     * associated template's record properties.
     *
     * @param {string} [store_name]
     */
    function dbCreateObjectStore(store_name = defaultStore()) {
        const func     = 'dbCreateObjectStore';
        const template = getStoreTemplate(store_name);
        try {
            const db   = dbDatabase();
            dbLog(func, `creating "${store_name}" for database ${db.name}`);
            let store  = db.createObjectStore(store_name, template.options);
            $.each(template.record, function(key, properties) {
                let index_options;
                if (typeof properties.index === 'object') {
                    index_options = properties.index;
                } else if (properties.index !== false) {
                    index_options = { unique: false };
                }
                if (index_options) {
                    dbLog(func, store_name, `creating index for "${key}"`);
                    store.createIndex(key, key, index_options);
                }
            });
        }
        catch (error) {
            dbError(func, `failed for object store ${store_name}`);
            dbError(func, 'error', error);
        }
    }

    /**
     * Create the default object store for a new database.
     *
     * @param {Event|IDBDatabase} arg
     * @param {string}            func
     */
    function dbSetupDatabase(arg, func) {
        /** @type {IDBDatabase} */
        const db     = (arg instanceof IDBDatabase) ? arg : arg.target.result;
        const name   = `"${db.name}"`;
        const stores = Object.keys(store_template);
        try {
            dbLog(`dbSetupDatabase: db = ${name}; object stores = ${stores}`);
            dbDatabase(db);
            stores.forEach(store => dbCreateObjectStore(store));
        }
        catch (error) {
            dbError(func, `failed for database ${name}`);
            dbError(func, 'error', error);
        }
    }

    /**
     * Close the current database.
     *
     * @param {string}      caller
     * @param {IDBDatabase} [db]
     */
    function dbCloseDatabase(caller, db) {
        let tgt_db = db || db_handle;
        if (tgt_db) {
            const clear = (tgt_db === db_handle);
            const func  = caller || 'dbCloseDatabase';
            dbLog(func, 'closing database', tgt_db.name);
            tgt_db.close();
            if (clear) { db_handle = undefined; }
        }
    }

    // ========================================================================
    // Functions - internal
    // ========================================================================

    /**
     * dbTransaction
     *
     * @param {string} func           For logging.
     * @param {...(IDBTransaction|IDBTransactionMode|IDBDatabase|string)} args
     *
     * @returns {IDBTransaction}
     */
    function dbTransaction(func, ...args) {
        let db, tr, tr_mode, store_name;
        args.forEach(function(arg) {
            if      (arg instanceof IDBDatabase)     { db         = arg; }
            else if (arg instanceof IDBTransaction)  { tr         = arg; }
            else if (TRANSACTION_MODE.includes(arg)) { tr_mode    = arg; }
            else if (typeof arg === 'string')        { store_name = arg; }
            else { dbWarn(func, 'dbTransaction', 'unexpected', asString(arg)) }
        });
        if (!tr) {
            db         ||= dbDatabase();
            store_name ||= defaultStore();
            tr_mode    ||= DEFAULT_TRANSACTION_MODE;
            tr = db.transaction(store_name, tr_mode);
            tr.onabort    = _ => dbError(func, 'transaction aborted');
            tr.onerror    = _ => dbError(func, 'transaction failed', tr.error);
            tr.oncomplete = _ => dbDebug(func, 'transaction complete');
        }
        return tr;
    }

    /**
     * dbObjectStore
     *
     * @param {string}                                    func  For logging.
     * @param {...(IDBObjectStore|IDBTransaction|string)} args
     *
     * @returns {IDBObjectStore}
     */
    function dbObjectStore(func, ...args) {
        let store, transaction, store_name;
        args.forEach(function(arg) {
            if      (arg instanceof IDBObjectStore) { store       = arg; }
            else if (arg instanceof IDBTransaction) { transaction = arg; }
            else if (typeof arg === 'string')       { store_name  = arg; }
            // Anything else would be passed to dbTransaction.
        });
        if (!store) {
            transaction ||= dbTransaction(func, ...args);
            store_name  ||= transaction.objectStoreNames[0] || defaultStore();
            store = transaction.objectStore(store_name);
            if (debug_store) {
                dbLog(func, `object store "${store_name}" properties:`)
                console.log(`    .name          =`, store.name);
                console.log(`    .keyPath       =`, store.keyPath);
                console.log(`    .indexNames    =`, store.indexNames);
                console.log(`    .autoIncrement =`, store.autoIncrement);
                console.log(`    .transaction   =`, store.transaction);
                debug_store = false;
            }
        }
        return store;
    }

    /**
     * Prepare a request by providing default event handlers.
     *
     * @param {string}          func            For logging.
     * @param {IDBRequest}      request
     * @param {function(Event)} [on_success]
     * @param {function(Event)} [on_error]
     *
     * @returns {*}
     */
    function dbRequest(func, request, on_success, on_error) {
        let log_err = () => dbError(func, 'request failed', request.error);
        request.onerror =
            on_error ? (ev => log_err() || on_error(ev)) : (() => log_err());
        request.onsuccess =
            on_success || (() => dbDebug(func, 'request successful'));
        return request;
    }

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * The currently-set DB properties.
     *
     * @returns {DatabaseProperties}
     */
    function getProperties() {
        return {
            name:     db_name,
            version:  db_version,
            store:    default_store,
            template: store_template,
        };
    }

    /**
     * Specify the database name and version.
     *
     * @param {string} name
     * @param {number} [version]
     */
    function setDatabase(name, version) {
        dbName(name);
        dbVersion(version);
    }

    /**
     * The default object store name.
     *
     * @param {string} [new_name]       Set the default if provided.
     *
     * @returns {string|undefined}
     */
    function defaultStore(new_name) {
        if (new_name && !store_template.hasOwnProperty(new_name)) {
            dbError('defaultStore', `invalid store name "${new_name}"`);
        } else if (new_name) {
            default_store = new_name;
        } else if (!default_store) {
            default_store = Object.keys(store_template)[0];
        }
        return default_store;
    }

    /**
     * Get object store properties.
     *
     * @param {string} [store_name]   Default: {@link defaultStore()}.
     *
     * @returns {StoreTemplate}
     */
    function getStoreTemplate(store_name = defaultStore()) {
        return store_template[store_name];
    }

    /**
     * addStoreTemplates
     *
     * @param {Object<StoreTemplate>|string} store_name
     * @param {StoreTemplate}                [template]
     *
     * @returns {Object<StoreTemplate>}
     */
    function addStoreTemplates(store_name, template) {
        const func = 'addStoreTemplates';
        let templates;
        if (typeof store_name === 'object') {
            templates = store_name;
        } else {
            templates = Object.fromEntries([[store_name, template]]);
        }
        $.each(templates, function(name, properties) {
            if (store_template[name]) {
                dbLog(func, `"${name}": already added`);
            } else {
                store_template[name] = { ...properties };
            }
        });
        return store_template;
    }

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * openObjectStore
     *
     * @param {string}                [store_name]
     * @param {function(IDBDatabase)} [callback]
     */
    function openObjectStore(store_name = defaultStore(), callback) {
        const func     = 'DB.openObjectStore';
        const name     = dbName();
        const version  = dbVersion();
        const database = `${name} (v${version})`;
        defaultStore(store_name);
        dbLog(`${func}: store_name: ${default_store}; database: ${database}`);

        let request = window.indexedDB.open(name, version);
        request.onupgradeneeded = event => dbSetupDatabase(event, func);
        request.onblocked       = event => onOpenBlocked(event);
        request.onerror         = event => onOpenError(event);
        request.onsuccess       = event => onOpenSuccess(event);

        // ====================================================================
        // Event handlers
        // ====================================================================

        function onOpenBlocked(event) {
            dbWarn(func, database, 'in use; cannot upgrade');
            // TODO: sleep and retry???
        }

        function onOpenError(event) {
            dbError(func, database, 'load error', asString(event));
        }

        function onOpenSuccess(event) {
            dbDatabase(event.target.result);
            callback && callback(dbDatabase());
        }
    }

    /**
     * Remove all items from the indicated object store.
     *
     * @note This does not effect the autoIncrement sequence.
     *
     * @param {string}                [store_name]
     * @param {function(IDBDatabase)} [callback]
     */
    function clearObjectStore(store_name = defaultStore(), callback) {
        const func = 'DB.clearObjectStore';
        let store  = dbObjectStore(func, store_name)
        let req    = store.clear();
        let cb     = () => callback && callback(req.transaction.db);
        let if_ok  = () => { dbLog(func, `"${store_name}" cleared`); cb(); }
        dbRequest(func, req, if_ok, cb);
    }

    /**
     * Persist one or more items to the database store.
     *
     * @param {object|object[]} item
     * @param {function}        [callback]  Called upon completion.
     * @param {...(IDBObjectStore|IDBTransaction|string)} [args]
     */
    function storeItems(item, callback, ...args) {
        const func = 'DB.storeItems';
        let items  = arrayWrap(item);
        let count  = items.length;
        if (!count) {
            callback && callback();
            return;
        }
        let store  = dbObjectStore(func, ...args);
        let if_ok  = callback && (() => --count || callback());
        let if_err = callback;
        items.forEach(function(item) {
            dbRequest(func, store.add(item), if_ok, if_err);
        });
    }

    /**
     * Iterate through each item of the default object store (or the object
     * stored name given as the second argument).
     *
     * @param {function(IDBCursorWithValue|null,?number)} [item_cb]
     * @param {...(IDBObjectStore|IDBTransaction|string)} [args]
     */
    function fetchItems(item_cb, ...args) {
        const func  = 'DB.fetchItems';
        let number  = 0;
        let store   = dbObjectStore(func, ...args);
        let request = store.openCursor();
        let if_err  = item_cb && (() => item_cb(null, -1));
        let if_ok   = function(event) {
            /** @type {IDBCursorWithValue|null} */
            let cursor = event.target.result;
            item_cb && item_cb(cursor, number);
            if (cursor) {
                dbDebug(func, `item ${++number}`, asString(cursor.value));
                cursor.continue();
            } else {
                dbDebug(func, 'all DB items processed');
            }
        }
        dbRequest(func, request, if_ok, if_err);
    }

    /**
     * Get items with matching values for the given index key.
     *
     * @param {string}                                    index_key
     * @param {any|IDBKeyRange}                           index_value
     * @param {function(object[])}                        [callback]
     * @param {...(IDBObjectStore|IDBTransaction|string)} [args]
     */
    function lookupItems(index_key, index_value, callback, ...args) {
        const func  = 'DB.lookupItems';
        const query = dbMakeIndexQueryArgs(index_key, index_value);
        const key   = query.name;
        const value = query.value;
        let store   = dbObjectStore(func, ...args);
        let request = store.index(key).getAll(value);
        let if_err  = callback && (() => callback([]));
        let if_ok   = function(event) {
            const items = event.target.result;
            dbDebug(func, `${key}="${value}"`, `${items.length} items`);
            callback && callback(items);
        }
        dbRequest(func, request, if_ok, if_err);
    }

    /**
     * Count items with matching values for the given index key.
     *
     * @param {string}                                    index_key
     * @param {any|IDBKeyRange}                           index_value
     * @param {function(number)}                          [callback]
     * @param {...(IDBObjectStore|IDBTransaction|string)} [args]
     */
    function countItems(index_key, index_value, callback, ...args) {
        const func  = 'DB.countItems';
        const query = dbMakeIndexQueryArgs(index_key, index_value);
        const key   = query.name;
        const value = query.value;
        let store   = dbObjectStore(func, ...args);
        let request = store.index(key).count(value);
        let if_err  = callback && (() => callback(-1));
        let if_ok   = function(event) {
            const number = event.target.result;
            dbDebug(func, `${key}="${value}"`, `${number} items found`);
            callback && callback(number);
        }
        dbRequest(func, request, if_ok, if_err);
    }

    /**
     * Get object store keys for items with matching values for the given index
     * key.
     *
     * @param {string}                                    index_key
     * @param {any}                                       index_value
     * @param {function(IDBValidKey[])}                   [callback]
     * @param {...(IDBObjectStore|IDBTransaction|string)} [args]
     */
    function lookupStoreKeys(index_key, index_value, callback, ...args) {
        const func  = 'DB.lookupStoreKeys';
        const query = dbMakeIndexQueryArgs(index_key, index_value);
        const key   = query.name;
        const value = query.value;
        let store   = dbObjectStore(func, ...args);
        let request = store.index(key).getAllKeys(value);
        let if_err  = callback && (() => callback([]));
        let if_ok   = function(event) {
            const keys = event.target.result;
            dbDebug(func, `${key}="${value}"`, `${keys.length} keys`);
            callback && callback(keys);
        }
        dbRequest(func, request, if_ok, if_err);
    }

    /**
     * Delete items with matching values for the given index key.
     *
     * @param {string}                                    index_key
     * @param {any|IDBKeyRange}                           index_value
     * @param {function}                                  [callback]
     * @param {...(IDBObjectStore|IDBTransaction|string)} [args]
     */
    function deleteItems(index_key, index_value, callback, ...args) {
        const func  = 'DB.deleteItems';
        const store = dbObjectStore(func, ...args);
        lookupStoreKeys(index_key, index_value, deleteByStoreKeys, store);

        function deleteByStoreKeys(keys) {
            const ranges = dbNumberKeyRanges(keys);
            if (isEmpty(ranges)) {
                callback && callback();
            } else {
                const final_range = callback && (ranges.length - 1);
                ranges.forEach(function(range, idx) {
                    let cb = (idx === final_range) ? callback : undefined;
                    dbRequest(func, store.delete(range), cb, cb);
                });
            }
        }
    }

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Return a handle to the database.
     *
     * @note For console testing.
     *
     * @returns {IDBDatabase|undefined}
     */
    function database() {
        return dbDatabase();
    }

    /**
     * Close the database.
     *
     * @note For console testing.
     *
     * @returns {IDBDatabase|undefined}
     */
    function closeDatabase() {
        const func = 'closeDatabase';
        if (db_handle) {
            dbCloseDatabase(func);
        } else {
            dbLog(func, `database "${dbName()}" not open`);
        }
    }

    // ========================================================================
    // Exposed definitions
    // ========================================================================

    return {
        getProperties:      getProperties,
        setDatabase:        setDatabase,
        defaultStore:       defaultStore,
        getStoreTemplate:   getStoreTemplate,
        addStoreTemplates:  addStoreTemplates,
        openObjectStore:    openObjectStore,
        clearObjectStore:   clearObjectStore,
        storeItems:         storeItems,
        fetchItems:         fetchItems,
        lookupItems:        lookupItems,
        countItems:         countItems,
        lookupStoreKeys:    lookupStoreKeys,
        deleteItems:        deleteItems,
        database:           database,
        closeDatabase:      closeDatabase,
    };

})();
