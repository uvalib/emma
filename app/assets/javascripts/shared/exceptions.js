// app/assets/javascripts/shared/exceptions.js


import { AppDebug } from "../application/debug";


AppDebug.file("shared/exceptions");

// ============================================================================
// Classes
// ============================================================================

/**
 * Exception
 *
 * @extends Error
 */
export class Exception extends Error {

    static CLASS_NAME = "Exception";

    // ========================================================================
    // Variables
    // ========================================================================

    /** @type {array} */ args;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {string} [message]
     * @param {...*}   [args]
     */
    constructor(message, ...args) {
        super(message);
        this.name = this.CLASS_NAME;
        this.args = args;
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /**
     * The message and additional arguments supplied in the constructor that
     * can be used in a `console.log` statement with the spread operator.
     *
     * @returns {array}
     */
    get messageParts() {
        let message = this.message || "";
        if (this.args.length) {
            message = message.replace(/([^:])$/, "$1:");
        }
        return [message, ...this.args];
    }

}

/**
 * ValidationError
 *
 * @extends Exception
 */
export class ValidationError extends Exception {
    static CLASS_NAME = "ValidationError";
}
