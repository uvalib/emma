// app/assets/javascripts/shared/lookup-request.js


import { BaseClass }             from '../shared/base-class'
import { isDefined, isPresent }  from '../shared/definitions'
import { arrayWrap, deepFreeze } from '../shared/objects'


// ============================================================================
// Class Queue
// ============================================================================

/**
 * A lookup request object formed by parsing one or more term strings.
 */
export class LookupRequest extends BaseClass {

    static CLASS_NAME = 'LookupRequest';

    /**
     * LookupRequestObject
     *
     * @typedef {{
     *     ids?:   string[],
     *     query?: string[],
     *     limit?: string[],
     * }} LookupRequestObject
     */

    /**
     * Each request type and the valid search term prefixes associated with it.
     *
     * @constant
     * @type {LookupRequestObject}
     */
    static REQUEST_TYPE = deepFreeze({
        ids:    ['isbn', 'issn', 'doi', 'oclc', 'lccn'],
        query:  ['author', 'title', 'keyword'],  // TODO: expand
        limit:  [], // TODO: none yet
    });

    static DEF_ID_TYPE      = 'isbn';
    static DEF_QUERY_TYPE   = 'keyword';
    static DEF_REQUEST_TYPE = 'query';

    /**
     * A blank object containing an array value for every key defined by
     * {@link REQUEST_TYPE}.
     *
     * @constant
     * @type {{[k: string]: *[]}}
     */
    static TEMPLATE = deepFreeze(
        Object.fromEntries(Object.keys(this.REQUEST_TYPE).map(k => [k, []]))
    );

    static CHARACTER_MAPPING = deepFreeze({
        '"': '%22',
        "'": '%27',
        ':': '%3A'
    });

    static DEF_SEPARATORS = deepFreeze([ '\\s', '|' ]);

    /**
     * Create a new instance.
     *
     * @param {string|string[]|LookupRequest|LookupRequestObject} [terms]
     * @param {string|string[]} [separators]
     */
    constructor(terms, separators) {
        super();
        if (separators) {
            this.separators = arrayWrap(separators);
        } else {
            this.separators = this.constructor.DEF_SEPARATORS;
        }
        this.parts = this._blankParts();
        this.add(terms);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get ids()    { return this.parts.ids   || [] }
    get query()  { return this.parts.query || [] }
    get limit()  { return this.parts.limit || [] }

    get length() {
        return Object.values(this.parts).reduce(
            (total, array) => total + (array?.length || 0)
        );
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get idTypes()    { return this.REQUEST_TYPE.ids   || [] }
    static get queryTypes() { return this.REQUEST_TYPE.query || [] }
    static get limitTypes() { return this.REQUEST_TYPE.limit || [] }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Clear all terms.
     */
    clear() {
        this.parts = this._blankParts();
    }

    /**
     * Add one or more terms.
     *
     * @param {string|string[]|LookupRequest|LookupRequestObject} [term]
     */
    add(term) {
        let req;
        if (Array.isArray(term) || (typeof term === 'string')) {
            req = this.parse(term);
        } else {
            req = term;
        }
        if (isPresent(req)) {
            let req_parts = req.parts || req;
            this._appendParts(this.parts, req_parts);
        } else if (isDefined(req)) {
            this._warn('nothing to add');
        }
    }

    /**
     * Create a lookup request object from the provided terms.
     *
     * @param {string|string[]} terms
     *
     * @returns {LookupRequestObject}
     */
    parse(terms) {
        const REQUEST_TYPE     = this.constructor.REQUEST_TYPE;
        const DEF_REQUEST_TYPE = this.constructor.DEF_REQUEST_TYPE;
        let parts = this._blankParts();
        let pairs;
        if (Array.isArray(terms)) {
            pairs = terms.map(term => this.extractParts(term)).flat(1);
        } else {
            pairs = this.extractParts(terms);
        }
        pairs.forEach(function(pair) {
            let [prefix, value] = pair;
            let term = `${prefix}:${value}`;
            let type;
            $.each(REQUEST_TYPE, function(req_type, prefixes) {
                if (prefixes.includes(prefix)) {
                    type = req_type;
                }
                return !type; // break loop if type found
            });
            type ||= DEF_REQUEST_TYPE;
            parts[type].push(term);
        });
        return parts;
    }

    /**
     * Split the terms string into an array of prefix/value pairs.
     *
     * * prefix:value
     * * prefix:'value'     If the value string was single-quoted.
     * * prefix:"value"     If the value string was double-quoted.
     *
     * Terms can be separated by one or more space, tab, '|' characters.
     * Values which contain any of those characters must be quoted, however the
     * quotes are removed from the returned elements.
     *
     * @param {string} terms
     *
     * @returns {[string,string][]}
     */
    extractParts(terms) {
        const ID_TYPE    = this.constructor.DEF_ID_TYPE;
        const QUERY_TYPE = this.constructor.DEF_QUERY_TYPE;
        const MAP        = this.constructor.CHARACTER_MAPPING;
        const PRE        = this._prefixMatcher;
        const VAL        = this._valueMatcher;
        // part         ___2____             ___4___   ___5___  ___6____
        const TERM  = `((${PRE})\\s*:\\s*)?("([^"]*)"|'([^']*)'|(${VAL}))`;
        let term_re = new RegExp(TERM, 'g');
        let parts   = terms.matchAll(term_re);
        return Array.from(parts).map(function(part) {
            let prefix = part[2]?.toLowerCase();
            let value =
                part[4] || // value inside double quotes
                part[5] || // value inside single quotes
                part[6];   // value if unquoted
            value    = value?.replaceAll(/[:"']/g, c => MAP[c] || c) || '';
            prefix ||= value.match(/^\d+$/) ? ID_TYPE : QUERY_TYPE;
            return [prefix, value];
        });
    }

    // ========================================================================
    // Protected methods
    // ========================================================================

    /**
     * Generate a new empty request object.
     *
     * @returns {LookupRequestObject}
     * @private
     */
    _blankParts() {
        return $.extend(true, {}, this.constructor.TEMPLATE);
    }

    /**
     * Append the elements from *src* to *dst*.
     *
     * @param {object} dst
     * @param {object} src
     *
     * @returns {object}
     * @private
     */
    _appendParts(dst, src) {
        $.each(dst, function(key, val) {
            dst[key] = Array.from(new Set([...val, ...src[key]]));
        });
        return dst;
    }

    // ========================================================================
    // Protected properties
    // ========================================================================

    get _separatorChars() { return this.separators.join('') }
    get _prefixMatcher()  { return `[^${this._separatorChars}"']+`; }
    get _valueMatcher()   { return `[^${this._separatorChars}]+`; }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {string|string[]|LookupRequest|LookupRequestObject} item
     * @param {*} args Passed to constructor (if required).
     *
     * @returns {LookupRequest}
     */
    static wrap(item, ...args) {
        return (item instanceof this) ? item : new this(item, ...args);
    }

    /**
     * Return lookup request parts, creating a temporary instance if necessary
     * to parse value(s).
     *
     * @param {string|string[]|LookupRequest|LookupRequestObject} item
     * @param {*} args Passed to constructor (if required).
     *
     * @returns {LookupRequestObject|undefined}
     */
    static parts(item, ...args) {
        let result;
        if (Array.isArray(item) || (typeof item === 'string')) {
            result = new this(item, ...args).parts;
        } else if (typeof item === 'object') {
            result = item.parts || item;
        }
        return result;
    }
}
