// app/assets/javascripts/vendor/select2.js
//
// Load jQuery in a module to be included in the 'application.js' manifest so
// that the required initialization is in place to respond to 'turbolinks:load'


import { AppDebug } from '../application/debug';
import { appSetup } from '../application/setup';
import select2      from 'select2';


const MODULE = 'vendor/select2';

AppDebug.file(MODULE);

appSetup(MODULE, () => select2($));
