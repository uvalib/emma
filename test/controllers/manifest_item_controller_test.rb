# test/controllers/manifest_item_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ManifestItemControllerTest < ActionDispatch::IntegrationTest

  MODEL         = ManifestItem
  CONTROLLER    = :manifest_item
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER }.freeze

  TEST_USERS    = ALL_TEST_USERS
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = TEST_USERS

  READ_FORMATS  = :all
  WRITE_FORMATS = :html

  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
    @item    = manifest_items(:example)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'manifest_item index - list all manifest items' do
    action  = :index
    owner   = @item.manifest
    params  = PARAMS.merge(action: action, manifest: owner.id)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        case opt[:expect]
          when :success then opt[:redir] = index_redirect(user: user, **opt)
        end
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'manifest show - details of an existing manifest item' do
    action  = :show
    owner   = @item.manifest
    params  = PARAMS.merge(action: action, manifest: owner.id, id: @item.id)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = manifests(:example)
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

end
