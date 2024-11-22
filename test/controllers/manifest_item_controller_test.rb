# test/controllers/manifest_item_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class ManifestItemControllerTest < ApplicationControllerTestCase

  MODEL = ManifestItem
  CTRLR = :manifest_item
  PRM   = { controller: CTRLR }.freeze
  OPT   = { controller: CTRLR, sign_out: false }.freeze

  TEST_READERS  = ALL_TEST_USERS
  TEST_WRITERS  = ALL_TEST_USERS

  READ_FORMATS  = :all
  WRITE_FORMATS = :html

  NO_READ       = formats_other_than(*READ_FORMATS).freeze
  NO_WRITE      = formats_other_than(*WRITE_FORMATS).freeze

  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
    @item    = manifest_items(:example)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'manifest_item index - list manifest items' do
    action  = :index
    owner   = @item.manifest
    params  = PRM.merge(action: action, manifest: owner.id)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_READ.include?(fmt)
          opt[:expect] = :not_found if able
        else
          opt[:redir]  = index_redirect(user: user, **opt) if able
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'manifest_item show - details of an existing manifest item' do
    action  = :show
    owner   = @item.manifest
    params  = PRM.merge(action: action, manifest: owner.id, id: @item.id)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = manifests(:example)
        url = url_for(id: rec.id, **u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_READ.include?(fmt)
          opt[:expect] = :not_found if able
        end
        get_as(user, url, **opt)
      end
    end
  end

end
