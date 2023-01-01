// app/assets/javascripts/vendor/capybara-lockstep.js
//
// The related script is injected iva HeadHelper::Scripts#page_javascripts
// when running with RAILS_ENV == 'test'.
//
// @note An override was required to accommodate Turbolinks.
// @see file:app/lib/ext/capybara-lockstep "Capybara::Lockstep::HelperExt"


import { AppDebug } from '../application/debug';
import { appSetup } from '../application/setup';


AppDebug.file('vendor/capybara-lockstep');

if (window.CapybaraLockstep) {
    AppDebug.active = false;
    appSetup('vendor/capybara-lockstep', () => CapybaraLockstep.track());
}
