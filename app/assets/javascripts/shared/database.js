// app/assets/javascripts/shared/database.js


import { AppDebug }                               from "../application/debug";
import { arrayWrap }                              from "./arrays";
import { isDefined, isEmpty, notEmpty, presence } from "./definitions";
import { fromJSON, hasKey }                       from "./objects";
import { asString }                               from "./strings";


const MODULE = "DB";
const DEBUG  = false;

AppDebug.file("shared/database", MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {string|null|undefined} optString
 */

/**
 * @typedef {number|null|undefined} optNumber
 */

/**
 * @typedef {IDBCursorWithValue|null|undefined} optCursor
 */

/**
 * @typedef {object} DbRecordProperties
 *
 * @property {*}                          [default]
 * @property {boolean|IDBIndexParameters} [index]
 * @property {function(...):IDBValidKey}  [func]
 *
 * @note The optional "default" entry is only used by the database client.
 */

/**
 * @typedef {object} StoreTemplate
 *
 * @property {IDBObjectStoreParameters}           options
 * @property {Object.<string,DbRecordProperties>} record
 */

/**
 * @typedef {Object.<string,StoreTemplate>} StoreTemplates
 */

/**
 * @typedef {object} DatabaseProperties
 *
 * @property {string}         name
 * @property {number}         version
 * @property {string}         store
 * @property {StoreTemplates} template
 */

/**
 * Callback - a generic callback argument.
 *
 * @typedef {function} Callback
 */

/**
 * @typedef {function(IDBDatabase)} DbCallback
 */

/**
 * @typedef {function(optCursor, ?number)} CursorCallback
 */

/**
 * @typedef {function(object[])} ObjectsCallback
 */

/**
 * @typedef {function(number)} NumberCallback
 */

/**
 * @typedef {function(IDBValidKey[])} KeysCallback
 */

/**
 * trArg - a generic transaction argument.
 *
 * @typedef {IDBObjectStore|IDBTransaction|string} trArg
 */

/**
 * FunctionStoreTemplates
 *
 * @typedef {
 *      function(StoreTemplates|string, ?StoreTemplate) : StoreTemplates
 * } FunctionStoreTemplates
 */

/**
 * FunctionOpenDatabase
 *
 * @typedef {
 *      function(optString, optNumber, ?DbCallback, ?string)
 * } FunctionOpenDatabase
 */

// ============================================================================
// Database
// ============================================================================

/**
 * An interface to the browser object store.
 *
 * @type {object}
 * @property {function:DatabaseProperties}                    getProperties
 * @property {function(string,?number)}                       setDatabase
 * @property {function(?string):?string}                      defaultStore
 * @property {function(?string):StoreTemplate}                getStoreTemplate
 * @property {FunctionStoreTemplates}                         addStoreTemplates
 * @property {FunctionOpenDatabase}                           openDatabase
 * @property {function(optString,?DbCallback)}                openObjectStore
 * @property {function(optString,?DbCallback)}                clearObjectStore
 * @property {function(optString,?DbCallback)}                clearAllStores
 * @property {function(object|object[],?Callback,...trArg)}   storeItems
 * @property {function(?CursorCallback,...trArg)}             fetchItems
 * @property {function(string,any,?ObjectsCallback,...trArg)} lookupItems
 * @property {function(string,any,?ObjectsCallback,...trArg)} lookupItems
 * @property {function(string,any,?NumberCallback,...trArg)}  countItems
 * @property {function(string,any,?KeysCallback,...trArg)}    lookupStoreKeys
 * @property {function(string,any,?Callback,...trArg)}        deleteItems
 * @property {function:?IDBDatabase}                          database
 * @property {function:?IDBDatabase}                          closeDatabase
 */
export const DB = (function() {

    /**
     * @typedef {IDBValidKey|IDBKeyRange} IndexQueryValue
     */

    /**
     * @typedef {object} IndexQueryArgs
     *
     * @property {string}             name
     * @property {IndexQueryValue}    [value]
     * @property {number}             [count]
     * @property {IDBCursorDirection} [direction]
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Database for applications uses.
     *
     * @readonly
     * @type {string}
     */
    const DEFAULT_DB_NAME = "emma";

    /**
     * Current version of the client database schemas.
     *
     * @readonly
     * @type {number}
     */
    const DEFAULT_DB_VERSION = 1;

    /**
     * Transaction modes.
     *
     * @readonly
     * @type {string[]}
     */
    const TRANSACTION_MODE = ["readonly", "readwrite", "versionchange"];

    /**
     * Normal transaction mode.
     *
     * @readonly
     * @type {string}
     */
    const DEFAULT_TRANSACTION_MODE = "readwrite";

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
     * @type {StoreTemplates}
     */
    let store_template = {};

    /**
     * A flag to allow details of the object store to be displayed only once.
     *
     * @type {boolean}
     */
    let debug_store = true;

    // ========================================================================
    // Functions - internal
    // ========================================================================

    function _error(...args) {
        const tag = `${MODULE} ERROR`;
        const msg = _logArgs(...args);
        console.error(`${tag} -`, ...msg);
        //addFlashError(msg || tag);
    }

    function _warn(...args) {
        const tag = `${MODULE} ERROR`;
        const msg = _logArgs(...args);
        console.warn(`${tag} -`, ...msg);
        //addFlashMessage(msg || tag);
    }

    function _log(...args) {
        const tag = MODULE;
        const msg = _logArgs(...args);
        console.log(`${tag} -`, ...msg);
    }

    function _debug(...args) {
        _debugging() && _log(...args);
    }

    /**
     * Indicate whether console debugging is active.
     *
     * @returns {boolean}
     */
    function _debugging() {
        return AppDebug.activeFor(MODULE, DEBUG);
    }

    /**
     * Handle console logging arguments.
     *
     * @param {...*} args
     *
     * @returns {array|string}
     */
    function _logArgs(...args) {
        const i_max  = args.length - 1;
        const result = args.map(
            (v, i) => ((typeof v === "string") && (i < i_max)) ? `${v}:` : v
        );
        return presence(result) || "";
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
        const result = { name: index_key };
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
        const result = [];
        if (notEmpty(store_keys)) {
            const last_slot = store_keys.length - 1;
            let first_key   = store_keys[0];
            let prev_key    = first_key - 1;
            store_keys.forEach((store_key, array_slot) => {
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
            localStorage.setItem("idb-current", new_name);
        }
        return new_name || localStorage.getItem("idb-current");
    }

    /**
     * Get/set the persisted version of the current database.
     *
     * @param {number} [new_version]
     *
     * @returns {number}
     */
    function savedDbVersion(new_version) {
        const value = localStorage.getItem("idb-version");
        const table = fromJSON(value, "savedDbVersion") || {};
        const name  = dbName();
        if (new_version) {
            table[name] = new_version;
            localStorage.setItem("idb-version", asString(table));
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
     * Return **db_handle** or assign a new **db_handle** and set up generic
     * event handlers for it.
     *
     * @param {IDBDatabase} [new_db]
     *
     * @returns {IDBDatabase}
     */
    function dbDatabase(new_db) {
        if (new_db && (db_handle !== new_db)) {
            const func = "dbDatabase";

            if (db_handle) {
                dbCloseDatabase(func);
            }

            db_handle = new_db;
            db_handle.onversionchange = (evt) => dbSetupDatabase(evt, func);
            db_handle.onclose         = (evt) => onClose(evt);
            db_handle.onabort         = (evt) => onGenericAbort(evt);
            db_handle.onerror         = (evt) => onGenericError(evt);

            // ================================================================
            // Event handlers
            // ================================================================

            function onClose(event) {
                _log(func, "DATABASE CLOSING");
                _debug(event);
            }

            function onGenericAbort(event) {
                _warn(func, "OPERATION ABORTED");
                _debug(event);
            }

            function onGenericError(event) {
                _error(func, "OPERATION ERROR", event);
                _debug(event);
            }
        }
        return db_handle;
    }

    /**
     * Execute the callback with the current database.
     *
     * @param {DbCallback} callback
     * @param {optString}  [database]
     * @param {string}     [caller]
     */
    function dbWithDatabase(callback, database, caller) {
        const func = "dbWithDatabase";
        const db   = dbDatabase();
        if (!db || (database && (database !== dbName()))) {
            openDatabase(database, null, callback, caller);
        } else if (db) {
            callback(db);
        } else {
            _error(func, "no database name given");
        }
    }

    /**
     * Create the named object store and set up indices according to its
     * associated template's record properties.
     *
     * @param {string} [store_name]   Default: {@link defaultStore}.
     */
    function dbCreateObjectStore(store_name) {
        const func     = "dbCreateObjectStore";
        const name     = store_name || defaultStore();
        const template = getStoreTemplate(name);
        try {
            const db    = dbDatabase();
            _log(func, `creating "${name}" for database ${db.name}`);
            const store = db.createObjectStore(name, template.options);
            for (const [key, properties] of Object.entries(template.record)) {
                let index_options;
                if (typeof properties.index === "object") {
                    index_options = properties.index;
                } else if (properties.index !== false) {
                    index_options = { unique: false };
                }
                if (index_options) {
                    _log(func, name, `creating index for "${key}"`);
                    store.createIndex(key, key, index_options);
                }
            }
        } catch (error) {
            _error(func, `failed for object store ${name}; err=`, error);
        }
    }

    /**
     * Create the default object store for a new database.
     *
     * @param {IDBVersionChangeEvent|IDBDatabase} arg
     * @param {string}                            func
     */
    function dbSetupDatabase(arg, func) {
        /** @type {IDBDatabase} */
        const db     = (arg instanceof IDBDatabase) ? arg : arg.target.result;
        const name   = `"${db.name}"`;
        const stores = Object.keys(store_template);
        try {
            _log("dbSetupDatabase", `db = ${name}; object stores = ${stores}`);
            dbDatabase(db);
            stores.forEach(store => dbCreateObjectStore(store));
        } catch (error) {
            _error(func, `failed for database ${name}; error =`, error);
        }
    }

    /**
     * Close the current database.
     *
     * @param {string}      caller
     * @param {IDBDatabase} [db]
     */
    function dbCloseDatabase(caller, db) {
        const tgt_db = db || db_handle;
        if (tgt_db) {
            const clear = (tgt_db === db_handle);
            const func  = caller || "dbCloseDatabase";
            _log(func, "closing database", tgt_db.name);
            tgt_db.close();
            if (clear) { db_handle = undefined }
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
        args.forEach(arg => {
            if      (arg instanceof IDBDatabase)     { db         = arg }
            else if (arg instanceof IDBTransaction)  { tr         = arg }
            else if (TRANSACTION_MODE.includes(arg)) { tr_mode    = arg }
            else if (typeof arg === "string")        { store_name = arg }
            else { _warn(func, "dbTransaction", "unexpected", arg) }
        });
        if (!tr) {
            db         ||= dbDatabase();
            store_name ||= defaultStore();
            tr_mode    ||= DEFAULT_TRANSACTION_MODE;
            tr = db.transaction(store_name, tr_mode);
            tr.onabort    = () => _error(func, "transaction aborted");
            tr.onerror    = () => _error(func, "transaction failed", tr.error);
            tr.oncomplete = () => _debug(func, "transaction complete");
        }
        return tr;
    }

    /**
     * dbObjectStore
     *
     * @param {string}   func         For logging.
     * @param {...trArg} args
     *
     * @returns {IDBObjectStore}
     */
    function dbObjectStore(func, ...args) {
        let store, transaction, store_name;
        args.forEach(arg => {
            if      (arg instanceof IDBObjectStore) { store       = arg }
            else if (arg instanceof IDBTransaction) { transaction = arg }
            else if (typeof arg === "string")       { store_name  = arg }
            // Anything else would be passed to dbTransaction.
        });
        if (!store) {
            transaction ||= dbTransaction(func, ...args);
            store_name  ||= transaction.objectStoreNames[0] || defaultStore();
            store = transaction.objectStore(store_name);
            if (debug_store && _debugging()) {
                _log(func, `object store "${store_name}" properties:`)
                console.log("    .name          =", store.name);
                console.log("    .keyPath       =", store.keyPath);
                console.log("    .indexNames    =", store.indexNames);
                console.log("    .autoIncrement =", store.autoIncrement);
                console.log("    .transaction   =", store.transaction);
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
        const log_err = () => _error(func, "request failed", request.error);
        request.onerror =
            on_error ? (ev => log_err() || on_error(ev)) : (() => log_err());
        request.onsuccess =
            on_success || (() => _debug(func, "request successful"));
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
        if (new_name && !hasKey(store_template, new_name)) {
            _error("defaultStore", `invalid store name "${new_name}"`);
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
     * @param {string} [store_name]   Default: {@link defaultStore}.
     *
     * @returns {StoreTemplate}
     */
    function getStoreTemplate(store_name) {
        const name = store_name || defaultStore();
        return store_template[name];
    }

    /**
     * addStoreTemplates
     *
     * @param {StoreTemplates|string} store_name
     * @param {StoreTemplate}         [template]
     *
     * @returns {StoreTemplates}
     */
    function addStoreTemplates(store_name, template) {
        const func = "addStoreTemplates";
        let templates;
        if (typeof store_name === "object") {
            templates = store_name;
        } else {
            templates = Object.fromEntries([[store_name, template]]);
        }
        for (const [name, properties] of Object.entries(templates)) {
            if (store_template[name]) {
                _log(func, `"${name}": already added`);
            } else {
                store_template[name] = { ...properties };
            }
        }
        return store_template;
    }

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * openDatabase
     *
     * @param {optString}  new_name
     * @param {optNumber}  new_version
     * @param {DbCallback} [callback]
     * @param {string}     [caller]
     */
    function openDatabase(new_name, new_version, callback, caller) {
        const func     = caller      || "DB.openDatabase";
        const name     = new_name    || dbName();
        const version  = new_version || dbVersion();
        const database = `${name} (v${version})`;
        _log(func, database);

        const request = window.indexedDB.open(name, version);
        request.onupgradeneeded = (event) => dbSetupDatabase(event, func);
        request.onblocked       = (event) => onOpenBlocked(event);
        request.onerror         = (event) => onOpenError(event);
        request.onsuccess       = (event) => onOpenSuccess(event);

        // ====================================================================
        // Event handlers
        // ====================================================================

        function onOpenBlocked(_event) {
            _warn(func, database, "in use; cannot upgrade");
            // TODO: sleep and retry???
        }

        function onOpenError(event) {
            _error(func, database, "load error", event);
        }

        function onOpenSuccess(event) {
            dbDatabase(event.target.result);
            callback?.(dbDatabase());
        }
    }

    /**
     * Set the default store (if given) then open the database.
     *
     * @param {optString}  store_name
     * @param {DbCallback} [callback]
     */
    function openObjectStore(store_name, callback) {
        const func     = "DB.openObjectStore";
        const name     = dbName();
        const version  = dbVersion();
        const database = `${name} (v${version})`;
        if (store_name) { defaultStore(store_name) }
        _log(`${func}: store_name: ${default_store}; database: ${database}`);
        openDatabase(name, version, callback, func);
    }

    /**
     * Remove all items from the indicated object store.
     *
     * @note This does not effect the autoIncrement sequence.
     *
     * @param {optString}  store_name   Default: {@link defaultStore}.
     * @param {DbCallback} [callback]
     */
    function clearObjectStore(store_name, callback) {
        const func  = "DB.clearObjectStore";
        const name  = store_name || defaultStore();
        const store = dbObjectStore(func, name)
        const req   = store.clear();
        const cb    = () => callback?.(req.transaction.db);
        const if_ok = () => { _log(func, `"${name}" cleared`); cb() }
        dbRequest(func, req, if_ok, cb);
    }

    /**
     * Clear all object stores.
     *
     * @param {optString}  database
     * @param {DbCallback} [callback]
     */
    function clearAllObjectStores(database, callback) {
        const func = "DB.clearAllObjectStores";
        dbWithDatabase(function(db) {
            const stores = Array.from(db.objectStoreNames);
            const cb     = () => callback?.(db);
            stores.forEach(store => DB.clearObjectStore(store, cb));
        }, database, func);
    }

    /**
     * Persist one or more items to the database store.
     *
     * @param {object|object[]} item
     * @param {function}        [callback]  Called upon completion.
     * @param {...trArg}        [args]
     */
    function storeItems(item, callback, ...args) {
        const func  = "DB.storeItems";
        const items = arrayWrap(item);
        let count   = items.length;
        if (!count) {
            callback?.();
            return;
        }
        const store  = dbObjectStore(func, ...args);
        const if_ok  = callback && (() => --count || callback());
        const if_err = callback;
        items.forEach(item => dbRequest(func, store.add(item), if_ok, if_err));
    }

    /**
     * Iterate through each item of the default object store (or the object
     * stored name given as the second argument).
     *
     * @param {CursorCallback} [item_cb]
     * @param {...trArg}       [args]
     */
    function fetchItems(item_cb, ...args) {
        const func    = "DB.fetchItems";
        const store   = dbObjectStore(func, ...args);
        const request = store.openCursor();
        let number    = 0;
        const if_err  = item_cb && (() => item_cb(null, -1));
        const if_ok   = function(event) {
            /** @type {optCursor} */
            const cursor = event.target.result;
            item_cb?.(cursor, number);
            if (cursor) {
                _debug(func, `item ${++number}`, cursor.value);
                cursor.continue();
            } else {
                _debug(func, "all DB items processed");
            }
        }
        dbRequest(func, request, if_ok, if_err);
    }

    /**
     * Get items with matching values for the given index key.
     *
     * @param {string}          index_key
     * @param {any|IDBKeyRange} index_value
     * @param {ObjectsCallback} [callback]
     * @param {...trArg}        [args]
     */
    function lookupItems(index_key, index_value, callback, ...args) {
        const func    = "DB.lookupItems";
        const query   = dbMakeIndexQueryArgs(index_key, index_value);
        const key     = query.name;
        const value   = query.value;
        const store   = dbObjectStore(func, ...args);
        const request = store.index(key).getAll(value);
        const if_err  = callback && (() => callback([]));
        const if_ok   = function(event) {
            const items = event.target.result;
            _debug(func, `${key}="${value}"`, `${items.length} items`);
            callback?.(items);
        }
        dbRequest(func, request, if_ok, if_err);
    }

    /**
     * Count items with matching values for the given index key.
     *
     * @param {string}           index_key
     * @param {any|IDBKeyRange}  index_value
     * @param {function(number)} [callback]
     * @param {...trArg}         [args]
     */
    function countItems(index_key, index_value, callback, ...args) {
        const func    = "DB.countItems";
        const query   = dbMakeIndexQueryArgs(index_key, index_value);
        const key     = query.name;
        const value   = query.value;
        const store   = dbObjectStore(func, ...args);
        const request = store.index(key).count(value);
        const if_err  = callback && (() => callback(-1));
        const if_ok   = function(event) {
            const number = event.target.result;
            _debug(func, `${key}="${value}"`, `${number} items found`);
            callback?.(number);
        }
        dbRequest(func, request, if_ok, if_err);
    }

    /**
     * Get object store keys for items with matching values for the given index
     * key.
     *
     * @param {string}       index_key
     * @param {any}          index_value
     * @param {KeysCallback} [callback]
     * @param {...trArg}     [args]
     */
    function lookupStoreKeys(index_key, index_value, callback, ...args) {
        const func    = "DB.lookupStoreKeys";
        const query   = dbMakeIndexQueryArgs(index_key, index_value);
        const key     = query.name;
        const value   = query.value;
        const store   = dbObjectStore(func, ...args);
        const request = store.index(key).getAllKeys(value);
        const if_err  = callback && (() => callback([]));
        const if_ok   = function(event) {
            const keys = event.target.result;
            _debug(func, `${key}="${value}"`, `${keys.length} keys`);
            callback?.(keys);
        }
        dbRequest(func, request, if_ok, if_err);
    }

    /**
     * Delete items with matching values for the given index key.
     *
     * @param {string}          index_key
     * @param {any|IDBKeyRange} index_value
     * @param {Callback}        [callback]
     * @param {...trArg}        [args]
     */
    function deleteItems(index_key, index_value, callback, ...args) {
        const func  = "DB.deleteItems";
        const store = dbObjectStore(func, ...args);
        lookupStoreKeys(index_key, index_value, deleteByStoreKeys, store);

        function deleteByStoreKeys(keys) {
            const ranges = dbNumberKeyRanges(keys);
            if (isEmpty(ranges)) {
                callback?.();
            } else {
                const final_range = callback && (ranges.length - 1);
                ranges.forEach((range, idx) => {
                    const cb = (idx === final_range) ? callback : undefined;
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
        const func = "closeDatabase";
        if (db_handle) {
            dbCloseDatabase(func);
        } else {
            _log(func, `database "${dbName()}" not open`);
        }
    }

    // ========================================================================
    // Exposed definitions
    // ========================================================================

    // noinspection JSUnusedGlobalSymbols
    return {
        getProperties:      getProperties,
        setDatabase:        setDatabase,
        defaultStore:       defaultStore,
        getStoreTemplate:   getStoreTemplate,
        addStoreTemplates:  addStoreTemplates,
        openDatabase:       openDatabase,
        openObjectStore:    openObjectStore,
        clearObjectStore:   clearObjectStore,
        clearAllStores:     clearAllObjectStores,
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
