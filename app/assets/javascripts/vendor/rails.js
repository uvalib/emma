// app/assets/javascripts/vendor/rails.js
//
// Load Rails UJS.


import { AppDebug } from '../application/debug';
import Rails        from '@rails/ujs';

export { Rails };


const MODULE = 'Rails';
const DEBUG  = true;

AppDebug.file('vendor/rails', MODULE, DEBUG);

// ============================================================================
// Functions - other
// ============================================================================

/**
 * Indicate whether console debugging is active.
 *
 * @returns {boolean}
 */
function _debugging() {
    return AppDebug.activeFor(MODULE, DEBUG);
}

/**
 * Emit a console message if debugging.
 *
 * @param {...*} args
 */
function _debug(...args) {
    _debugging() && console.log(`${MODULE}:`, ...args);
}

// ============================================================================
// Rails UJS initialization
// ============================================================================

if (!window._rails_loaded) {
    _debug('LOAD');
    Rails.start();
}
