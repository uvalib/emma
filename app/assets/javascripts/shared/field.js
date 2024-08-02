// app/assets/javascripts/shared/field.js
//
// noinspection LocalVariableNamingConventionJS, JSUnusedGlobalSymbols


import { AppDebug }                    from "../application/debug";
import { arrayWrap }                   from "./arrays";
import { Emma }                        from "./assets";
import { BaseClass }                   from "./base-class";
import { isEmpty }                     from "./definitions";
import { htmlEncode }                  from "./html";
import { compact, fromJSON, isObject } from "./objects";
import { asString }                    from "./strings";


AppDebug.file("shared/field");

// ============================================================================
// Type definitions
// ============================================================================

/**
 * Data type information for data cells of a given column as defined by the
 * attributes attached to that column's header.
 *
 * @typedef {object} FieldProperties
 *
 * @property {string}   [field]
 * @property {string}   [label]
 * @property {string}   [type]
 * @property {number}   [min]
 * @property {number}   [max]
 * @property {string}   [tooltip]
 * @property {string}   [notes]
 * @property {string}   [notes_html]
 * @property {string}   [placeholder]
 * @property {string}   [origin]
 * @property {boolean}  [ignored]
 * @property {boolean}  [required]
 * @property {boolean}  [readonly]
 * @property {boolean}  [array]
 * @property {string}   [role]
 * @property {object}   [cond]
 * @property {object}   [pairs]
 *
 * @see "Field::PROPERTY_KEYS"
 * @see "Field::SYNTHETIC_KEYS"
 * @see "ManifestItemDecorator::SharedGenericMethods#grid_head_cell"
 */

// ============================================================================
// Class Properties
// ============================================================================

/**
 * Data type information for data cells of a given column as defined by the
 * attributes attached to that column's header.
 *
 * @extends BaseClass
 * @extends FieldProperties
 */
export class Properties extends BaseClass {

    static CLASS_NAME = "Properties";
    static DEBUGGING  = false;

    // ========================================================================
    // Constants
    // ========================================================================

    static TYPE = {
        field:          "string",
        label:          "string",
        type:           "string",
        min:            "number",
        max:            "number",
        tooltip:        "string",
        notes:          "string",
        notes_html:     "string",
        placeholder:    "string",
        origin:         "string",
        ignored:        "boolean",
        required:       "boolean",
        readonly:       "boolean",
        array:          "boolean",
        role:           "string",
        cond:           "object",
        pairs:          "object",   // Enumeration value/label pairs.
    };

    // ========================================================================
    // Fields
    // ========================================================================

    /**
     * Field property value.
     *
     * @type {FieldProperties}
     * @protected
     */
    _value;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {FieldProperties|Properties|object|undefined} [arg]
     */
    constructor(arg) {
        super();
        if (arg instanceof jQuery) {
            const elem  = $(arg)[0];
            this._value = elem && this._extractFromAttributes(elem.attributes);

        } else if (arg instanceof HTMLElement) {
            this._value = this._extractFromAttributes(arg.attributes);

        } else if (arg instanceof NamedNodeMap) {
            this._value = this._extractFromAttributes(arg);

        } else if (arg instanceof this.constructor) {
            this._value = this._extractFromObject(arg.value);

        } else if (typeof arg === "object") {
            this._value = this._extractFromObject(arg);

        } else if (arg) {
            this._error("unexpected arg =", arg);
        }
        this._value ||= {};
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Get values from an element's `data-*` attributes.
     *
     * @param {NamedNodeMap} arg
     *
     * @returns {FieldProperties}
     * @protected
     */
    _extractFromAttributes(arg) {
        const result = {};
        Array.from(arg).forEach(attr => {
            const name = attr.name;
            if (name.startsWith("data-")) {
                const key = name.replace(/^data-/, "");
                result[key] = attr.value;
            }
        });
        return this._extractFromObject(result);
    }

    /**
     * Initialize from another Value instance.
     *
     * @param {object} arg
     *
     * @returns {FieldProperties}
     * @protected
     */
    _extractFromObject(arg) {
        let n;
        const result = {};
        for (const [k, v] of Object.entries(arg)) {
            switch (this.constructor.TYPE[k]) {
                case typeof(v):
                    result[k] = v;
                    break;
                case "number":
                    result[k] = ((n = Number(v)) || (n === 0)) ? n : null;
                    break;
                case "boolean":
                    result[k] = Boolean(v);
                    break;
                case "object":
                    result[k] = fromJSON(v) || null;
                    break;
                case "string":
                    result[k] = v?.toString() || null;
                    break;
                default:
                    this._debug(`invalid: key = ${k}; value =`, v);
                    break;
            }
        }
        return result;
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /** @returns {FieldProperties} */
    get value() { return this._value }

    get field()       { return this.value.field }
    get label()       { return this.value.label }
    get type()        { return this.value.type }
    get min()         { return this.value.min }
    get max()         { return this.value.max }
    get tooltip()     { return this.value.tooltip }
    get notes()       { return this.value.notes }
    get notes_html()  { return this.value.notes_html }
    get placeholder() { return this.value.placeholder }
    get origin()      { return this.value.origin }
    get ignored()     { return this.value.ignored }
    get required()    { return this.value.required }
    get readonly()    { return this.value.readonly }
    get array()       { return this.value.array }
    get role()        { return this.value.role }
    get cond()        { return this.value.cond }
    get pairs()       { return this.value.pairs }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Create new instance of the current class.
     *
     * @returns {Value}
     */
    static type(key) {
        return this.TYPE[key];
    }

}

// ============================================================================
// Class Value
// ============================================================================

/**
 * Value
 *
 * @extends BaseClass
 */
export class Value extends BaseClass {

    static CLASS_NAME = "Value";
    static DEBUGGING  = false;

    // ========================================================================
    // Constants
    // ========================================================================

    static EMPTY_VALUE = Emma.Field.empty;

    static TRANSLATION = {
        textarea: "array",
        textbox:  "array",
        text:     "string",
        date:     "string", // TODO: convert to Date (?); limiter for date-only?
        time:     "string", // TODO: convert to Date (?); limiter for time-only?
        datetime: "string", // TODO: convert to Date (?)
        json:     "object",
    };

    // ========================================================================
    // Fields
    // ========================================================================

    /**
     * The normalized value.
     *
     * @type {*}
     * @protected
     */
    _value;

    /**
     * The type of _value.
     *
     * @type {string}
     * @protected
     */
    _type;

    /**
     * Whether the instance was initialized with null/undefined.
     *
     * @type {boolean}
     * @protected
     */
    _unset;

    /**
     * Whether the instance must have a non-blank value in order to be
     * considered valid.
     *
     * @type {boolean}
     * @protected
     */
    _required;

    /**
     * Mapping of enumeration values to their display representations.
     *
     * @type {StringTable}
     * @protected
     */
    _map = {};

    /**
     * Mapping of invalid values to their error messages.
     *
     * @type {StringTable}
     * @protected
     */
    _errors = {};

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {*}                                 [arg]
     * @param {string|Properties|FieldProperties} [type]
     * @param {Object.<string,(string|string[])>} [errs]
     */
    constructor(arg, type, errs) {
        super();
        if (arg instanceof this.constructor) {
            this._setFromValue(arg);
        } else {
            this._setFrom(arg, type);
        }
        this._errors = { ...errs };
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Initialize from another Value instance.
     *
     * @param {Value} other
     *
     * @protected
     */
    _setFromValue(other) {
        this._map   = other._map;
        this._unset = other._unset;
        this._type  = other._type;
        switch (this._typeFor(other._value)) {
            case "array":  this._value = [ ...other._value ]; break;
            case "object": this._value = { ...other._value }; break;
            case "string": this._value = `${other._value}`;   break;
            default:       this._value = other._value;        break;
        }
    }

    /**
     * Initialize from a supplied value.
     *
     * @param {*}                                 [arg]
     * @param {string|Properties|FieldProperties} [as_type]
     *
     * @protected
     *
     * @overload _setFrom()
     *  A blank unset Value.
     *
     * @overload _setFrom(arg)
     *  Determine the type of *arg* dynamically.
     *  @param {*}               arg
     *
     * @overload _setFrom(arg, from_type)
     *  Interpret *arg* as the given type.
     *  @param {*}               arg
     *  @param {string}          as_type
     *
     * @overload _setFrom(arg, prop)
     *  Determine the type of *arg* based on the given properties.
     *  @param {*}                          arg
     *  @param {Properties|FieldProperties} as_type
     */
    _setFrom(arg, as_type) {
        const arg_type  = this._typeFor(arg);
        let type, value = this._normalize(arg, arg_type);
        const prop      = (typeof(as_type) === "object");
        if (prop) {
            // noinspection JSValidateTypes
            this._map   = { ...as_type.pairs };
            this._required = !!as_type.required;
            type = as_type.array ? "array" : as_type.type;
        } else {
            type = as_type || "undefined";
        }
        type = this._translateType(type);
        if ((type === "undefined") && (arg_type === "undefined")) {
            [type, value] = ["string", ""];
        } else {
            switch (type) {
               case "array":   value = this._asArray(value, arg_type);   break;
               case "object":  value = this._asObject(value, arg_type);  break;
               case "string":  value = this._asString(value, arg_type);  break;
               case "number":  value = this._asNumber(value, arg_type);  break;
               case "boolean": value = this._asBoolean(value, arg_type); break;
               default:        type  = arg_type; break;
           }
        }
        this._type  = type;
        this._value = value;
        this._unset = (arg_type === "undefined");
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Give the type of *value*.
     *
     * @param {*} value
     *
     * @returns {string}
     * @protected
     */
    _typeFor(value) {
        switch (true) {
            case Array.isArray(value):  return "array";
            case (value === null):      return "undefined";
            default:                    return typeof(value);
        }
    }

    /**
     * Convert the argument to an accepted type.
     *
     * @param {string|undefined} type
     *
     * @returns {string}
     * @protected
     */
    _translateType(type) {
        const translation = type && this.constructor.TRANSLATION[type];
        return translation || type || "string";
    }

    /**
     * Indicate whether the value not blank.
     *
     * @param {*} value
     *
     * @returns {boolean}
     * @protected
     */
    _significant(value) {
        return !!value || [0, false].includes(value);
    }

    /**
     * Prepare a raw value.
     *
     * @param {*}      val
     * @param {string} [type]
     *
     * @returns {Array}
     * @protected
     */
    _normalize(val, type) {
        let v, empty = this.constructor.EMPTY_VALUE;
        switch (type || this._typeFor(val)) {
            case "array":   return compact(val).filter(v => (v !== empty));
            case "string":  return (v = val.trim()) && (v === empty) ? "" : v;
            default:        return this._significant(val) ? val : "";
        }
    }

    /**
     * Convert value to Array.
     *
     * @param {*}             value
     * @param {string}        [type]
     * @param {string|RegExp} [separator]   Only applies for type === "array".
     *
     * @returns {Array}
     * @protected
     */
    _asArray(value, type, separator = /\s*[;|]\s*\n|\s*[;|]\s*|\s*\n/) {
        if (!value) { return this._significant(value) ? [value] : [] }
        switch (type || this._typeFor(value)) {
            case 'array':   return value;
            case 'string':  return compact(value.split(separator));
            default:        return arrayWrap(value);
        }
    }

    /**
     * Convert value to String.
     *
     * @param {*}      value
     * @param {string} [type]
     *
     * @returns {string}
     * @protected
     */
    _asString(value, type) {
        switch (type || this._typeFor(value)) {
            case "string":  return value;
            case "array":   return value.join("\n");
            case "object":  return asString(value);
            default:        return value?.toString() || "";
        }
    }

    /**
     * Convert value to Boolean.
     *
     * @param {*}      value
     * @param {string} [type]
     *
     * @returns {boolean}
     * @protected
     */
    _asBoolean(value, type) {
        switch (type || this._typeFor(value)) {
            case "string":  return (value.toLowerCase() === "true");
            default:        return Boolean(value);
        }
    }

    /**
     * Convert value to Number.
     *
     * @param {*}      value
     * @param {string} [_type]
     *
     * @returns {number}
     * @protected
     */
    _asNumber(value, _type) {
        return Number(value) || 0;
    }

    /**
     * Convert value to Object.
     *
     * @param {*}      value
     * @param {string} [type]
     *
     * @returns {object}
     * @protected
     */
    _asObject(value, type) {
        if (!value) { return {} }
        switch (type || this._typeFor(value)) {
            case 'object': return value;
            case 'string': return fromJSON(value);
            default:       return Object.fromEntries(value);
        }
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get value() { return this._value }
    get type()  { return this._type }
    get unset() { return this._unset }
    get lines() { return this.toArray() }

    get valid()   { return !this.invalid }
    get invalid() {
        if (this.blank) { return this._required }
        const invalid = Object.keys(this.errorTable);
        if (isEmpty(invalid)) { return false }
        return !!this.toArray().find(v => invalid.includes(v));
    }

    get blank()    { return this.unset || isEmpty(this.value) }
    get nonBlank() { return !this.blank }

    get errorTable()    { return this._errors }
    set errorTable(arg) { this._errors = { ...arg } }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Add entry/entries to the error table.
     *
     * @param {string|Object.<string,(string|string[])>} key
     * @param {string|string[]}                          [val]
     */
    addErrorTable(key, val) {
        const pairs = isObject(key) ? Object.entries(key) : [[key, val]];
        for (const [k, v] of pairs) {
            const msg = this._errors[k] ? [...this._errors[k]] : [];
            if (Array.isArray(v)) {
                msg.push(...v);
            } else {
                msg.push(v || Emma.Messages.invalid);
            }
            this._errors[k] = msg.join("; ");
        }
    }

    /**
     * Indicate whether the instance has the same value.
     *
     * @param {*}       value         A Value or convertible to a Value.
     * @param {boolean} [ordered]     If **true**, array order matters.
     *
     * @returns {boolean}             They represent the same value.
     */
    sameAs(value, ordered) {
        return this.constructor.same(this, value, ordered, true);
    }

    /**
     * Indicate whether the instance has a different value.
     *
     * @param {*}       value         A Value or convertible to a Value.
     * @param {boolean} [ordered]     If **true**, array order matters.
     *
     * @returns {boolean}             They represent different values.
     */
    differsFrom(value, ordered) {
        return this.constructor.differ(this, value, ordered, true);
    }

    /**
     * Return value as a String.
     *
     * @param {string} [separator]    Only applies for type === "array".
     *
     * @returns {string}
     */
    toString(separator = "\n") {
        if (this.type === "array") {
            let val = this.value;
            let sep = separator || "";
            if (sep.trim()) {
                val = val.map(v => this._asString(v));
                val = val.map(v => v.endsWith(sep) ? v : (v + sep));
                sep = "\n";
            }
            return val.join(sep);
        } else {
            return this._asString(this.value, this.type);
        }
    }

    /**
     * Return value as an Array.
     *
     * @returns {string[]}
     */
    toArray() {
        if (this.type === "array") {
            return this.value;
        } else {
            const value = this._asString(this.value, this.type);
            return value ? [value] : [];
        }
    }

    /**
     * Return value as a sequence of zero or more elements.
     *
     * @param {string|string[]|function} [cls_or_fn]
     *
     * @returns {string}
     *
     * @overload toHtml()
     *  Elements generated with CSS classes "item item-${idx}".
     *
     * @overload toHtml(classes)
     *  Additional CSS classes before "item item-${idx}".
     *  @param {string|string[]} [cls_or_fn]
     *
     * @overload toHtml(fn)
     *  Replace the item generating function.
     *  @param {function(any,number):string} [cls_or_fn]
     */
    toHtml(cls_or_fn) {
        let fn;
        if (typeof(cls_or_fn) === "function") {
            fn = cls_or_fn;
        } else {
            const cls = ["item", ...arrayWrap(cls_or_fn)].join(" ");
            fn = (v, idx) => `<div class="${cls} item-${idx}">${v}</div>`;
        }
        const values = this.toArray().map(v => this._representation(v));
        return values.map((v, idx) => fn(v, idx)).join("\n");
    }

    /**
     * Return a representation of the value for display. <p/>
     *
     * The caller must determine how to handle the result.
     * - For type === "array", the result is always HTML.
     * - Otherwise the result is not HTML-safe without *encode* === **true**.
     *
     * @param {boolean} [encode]    Ensure the result is HTML.
     *
     * @returns {string|string[]}
     *
     * @overload forDisplay()
     *  Return either HTML or plain text per {@link type}.
     *  @returns {string}
     *
     * @overload forDisplay(true)
     *  Ensure the result is HTML regardless of the type.
     *  @param {boolean} encode
     *  @returns {string}
     *
     * @overload forDisplay(false)
     *  Return only plain string(s)
     *  @param {boolean} encode
     *  @returns {string|string[]}
     */
    forDisplay(encode) {
        if (this.type === "array") {
            return (encode === false) ? this.value : this.toHtml();
        } else {
            const value = this._representation(this.value, this.type);
            return (encode === true) ? htmlEncode(value) : value;
        }
    }

    /**
     * Return a representation of the value for initializing an input.
     *
     * @param {string} [separator]  Only for {@link type} === "array".
     *
     * @returns {string}
     */
    forInput(separator = "\n") {
        return this.toString(separator);
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * The representation of a specific value element.
     *
     * @param {*} item
     * @param {*} [type]
     *
     * @returns {string}
     * @protected
     */
    _representation(item, type) {
        const value = this._asString(item, type);
        return value && this._map[value] || value;
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Create new instance of the current class.
     *
     * @returns {Value}
     */
    static new(...args) {
        return new this(...args);
    }

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {*}      [item]
     * @param {string} [type]
     *
     * @returns {Value}
     */
    static wrap(item, type) {
        return (item instanceof this) ? item : new this(item, type);
    }

    /**
     * Indicate whether two values are the same.
     *
     * @param {*}       value1        A Value or convertible to a Value.
     * @param {*}       value2        A Value or convertible to a Value.
     * @param {boolean} [ordered]     If **true**, array order matters.
     * @param {boolean} [value_only]  If **true**, blank strings and undefined
     *                                  are treated as the same (not applied
     *                                  to array elements or object values).
     *
     * @returns {boolean}             They represent the same value.
     */
    static same(value1, value2, ordered, value_only) {
        return !this.differ(value1, value2, ordered, value_only);
    }

    /**
     * Indicate whether two values are different.
     *
     * @param {*}       value1        A Value or convertible to a Value.
     * @param {*}       value2        A Value or convertible to a Value.
     * @param {boolean} [ordered]     If **true**, array order matters.
     * @param {boolean} [value_only]  If **true**, blank strings and undefined
     *                                  are treated as the same (not applied
     *                                  to array elements or object values).
     *
     * @returns {boolean}             They represent different values.
     */
    static differ(value1, value2, ordered, value_only) {
        const [v1, v2] = [value1, value2].map(v => this.wrap(v));

        const [a1, a2] = [v1, v2].map(v => (v.type === "array"));
        if (a1 || a2) {
            return !a1 || !a2 || this._diffArray(v1.value, v2.value, ordered);
        }

        const [o1, o2] = [v1, v2].map(v => (v.type === "object"));
        if (o1 || o2) {
            return !o1 || !o2 || this._diffObject(v1.value, v2.value, ordered);
        }

        if (value_only) {
            return (v1.toString() !== v2.toString());
        } else {
            return (v1.value !== v2.value);
        }
    }

    /**
     * Indicate whether two arrays are different.
     *
     * @param {array}   a1
     * @param {array}   a2
     * @param {boolean} [ordered]     If **true**, array order matters.
     *
     * @returns {boolean}
     * @protected
     */
    static _diffArray(a1, a2, ordered) {
        if (a1.length !== a2.length) { return true }
        if (!ordered) { [a1, a2] = [a1, a2].map(v => [...v].sort()) }
        return !!a1.find((v, i) => this._diffItem(v, a2[i], ordered));
    }

    /**
     * Indicate whether two objects are different.
     *
     * @param {object}  o1
     * @param {object}  o2
     * @param {boolean} [ordered]     If **true**, object keys must be in the
     *                                  same order.
     *
     * @returns {boolean}
     * @protected
     */
    static _diffObject(o1, o2, ordered) {
        const [k1, k2] = [o1, o2].map(v => Object.keys(v));
        if (this._diffArray(k1, k2, ordered)) { return true }
        return !!k1.find(k => this._diffItem(o1[k], o2[k], ordered));
    }

    /**
     * Indicate whether two item values are different.
     *
     * @param {array|object|string|number|boolean|null|undefined} v1
     * @param {array|object|string|number|boolean|null|undefined} v2
     * @param {boolean}                                           [ordered]
     *
     * @returns {boolean}
     * @protected
     */
    static _diffItem(v1, v2, ordered) {
        if (v1 === v2) { return false }

        const [a1, a2] = [v1, v2].map(v => Array.isArray(v));
        if (a1 || a2) { return !a1 || !a2 || this._diffArray(v1, v2, ordered) }

        const [o1, o2] = [v1, v2].map(v => (typeof(v) === "object"));
        return !o1 || !o2 || this._diffObject(v1, v2, ordered);
    }

}
