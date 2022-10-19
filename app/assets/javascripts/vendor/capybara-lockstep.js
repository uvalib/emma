// app/assets/javascripts/vendor/capybara-lockstep.js
//
// The related script is injected iva HeadHelper::Scripts#page_javascripts
// when running with RAILS_ENV == 'test'.
//
// @note An override was required to accommodate Turbolinks.
// @see file:app/lib/ext/capybara-lockstep "Capybara::Lockstep::HelperExt"

if (window.CapybaraLockstep) {
    $(document).on('turbolinks:load', function() {
        CapybaraLockstep.track();
    });
    window.DEBUG.active = false;
}
