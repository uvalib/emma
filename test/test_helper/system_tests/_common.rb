# test/test_helper/system_tests/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Common values for system tests.
#
module TestHelper::SystemTests::Common

  # Properties which drive parameterized system tests.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>String}}]
  #
  PROPERTY = {
    category: {
      index: {
        title:          I18n.t('emma.category.index.label'),
        heading:        I18n.t('emma.category.index.title'),
        count:          'categories found',
        body_class:     '.category-index',
        entry_class:    '.category-list-item',
      }
    },
    title: {
      index: {
        title:          I18n.t('emma.title.index.label'),
        heading:        I18n.t('emma.title.index.title'),
        count:          'titles found',
        body_class:     '.title-index',
        entry_class:    '.title-list-item',
      },
      show: {
        body_class:     '.title-show',
        content_class:  '.title-details',
      }
    },
    periodical: {
      index: {
        title:          I18n.t('emma.periodical.index.label'),
        heading:        I18n.t('emma.periodical.index.title'),
        count:          'periodicals found',
        body_class:     '.periodical-index',
        entry_class:    '.periodical-list-item',
      },
      show: {
        body_class:     '.periodical-show',
        content_class:  '.periodical-details',
      }
    },
    member: {
      index: {
        title:          I18n.t('emma.member.index.label'),
        heading:        I18n.t('emma.member.index.title'),
        count:          'members found',
        body_class:     '.member-index',
        entry_class:    '.member-list-item',
      },
      show: {
        body_class:     '.member-show',
        content_class:  '.member-details',
      }
    },
    reading_list: {
      index: {
        title:          I18n.t('emma.reading_list.index.label'),
        heading:        I18n.t('emma.reading_list.index.title'),
        count:          'lists found',
        body_class:     '.reading_list-index',
        entry_class:    '.reading_list-list-item',
      },
      show: {
        body_class:     '.reading_list-show',
        content_class:  '.reading_list-details',
      }
    },
  }.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # assert_current_url
  #
  # @param [String] url
  #
  def assert_current_url(url)
    assert_equal url, URI(current_url).tap { |uri| uri.port = nil }.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that the current page is valid.
  #
  # @param [String] title
  # @param [String] heading
  #
  def assert_valid_page(title: nil, heading: nil, **)
    assert_title title                  if title
    assert_selector 'h1', text: heading if heading
  end

end
