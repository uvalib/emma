# test/test_helper/system_tests/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Common values for system tests.
#
module TestHelper::SystemTests::Common

  # Properties which drive parameterized system tests.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  PROPERTY = {
    category: {
      index: {
        title:          'Categories',
        heading:        'Category Index',
        count:          'categories found',
        body_class:     '.category-index',
        entry_class:    '.category-list-entry',
      }
    },
    title: {
      index: {
        title:          'Titles',
        heading:        'Catalog Titles Index',
        count:          'titles found',
        body_class:     '.title-index',
        entry_class:    '.title-list-entry',
      },
      show: {
        body_class:     '.title-show',
        content_class:  '.title-details',
      }
    },
    periodical: {
      index: {
        title:          'Periodicals',
        heading:        'Periodicals Index',
        count:          'periodicals found',
        body_class:     '.periodical-index',
        entry_class:    '.periodical-list-entry',
      },
      show: {
        body_class:     '.periodical-show',
        content_class:  '.periodical-details',
      }
    },
    member: {
      index: {
        title:          'Members',
        heading:        'Members Index',
        count:          'members found',
        body_class:     '.member-index',
        entry_class:    '.member-list-entry',
      },
      show: {
        body_class:     '.member-show',
        content_class:  '.member-details',
      }
    },
    reading_list: {
      index: {
        title:          'Lists',
        heading:        'Reading Lists',
        count:          'reading lists found',
        body_class:     '.reading_list-index',
        entry_class:    '.reading_list-list-entry',
      },
      show: {
        body_class:     '.reading_list-show',
        content_class:  '.reading_list-details',
      }
    },
  }.deep_freeze

  # These ApiService methods should succeed for any user.
  #
  # @type [Array<Symbol>]
  #
  ANONYMOUS_METHODS = %i[
    get_title_count
    get_titles
    get_title
    get_periodicals
    get_periodical
    get_periodical_editions
    get_categories
  ].freeze

  # These ApiService methods should fail for an anonymous user.
  #
  # @type [Array<Symbol>]
  #
  AUTHORIZED_METHODS = %i[
    get_my_preferences
    get_my_assigned_titles
    get_assigned_titles
    get_my_reading_lists
    get_reading_lists
    get_reading_list_titles
    get_my_download_history
    get_subscriptions
    get_subscription
    get_user_agreements
    get_user_pod
    get_organization_members
    download_title
    download_periodical_edition
    get_catalog
    get_subscription_types
  ].freeze

end
