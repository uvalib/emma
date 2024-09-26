// app/assets/javascripts/vendor/rails.js
//
// Load Rails UJS.


import { AppDebug } from "../application/debug";
import { Emma }     from "../shared/assets";
import Rails        from "@rails/ujs";

export { Rails };


const MODULE = "Rails";
const DEBUG  = Emma.Debug.JS_DEBUG_RAILS;

AppDebug.file("vendor/rails", MODULE, DEBUG);

// ============================================================================
// Rails UJS initialization
// ============================================================================

if (!window._rails_loaded) {
    AppDebug.consoleLogging(MODULE, DEBUG).debug("LOAD");
    Rails.start();
}
