# test/system/search_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class SearchTest < ApplicationSystemTestCase

  CTRLR = :search
  PRM   = { controller: CTRLR }.freeze

  PAGE_SIZE    = I18n.t('emma.page.search.pagination.page_size').to_i
  PAGE_COUNT   = 3
  TITLE_SEARCH = 'man'

  setup do
    @member = find_user(:test_dso_1)
    @staff  = find_user(:test_staff_1)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'search - index - title search' do
    list_test(meth: __method__, action: :index) do |index|
      validate_title_entries(index: index)
    end
  end

  test 'search - direct - title search' do
    list_test(meth: __method__, action: :direct) do |index|
      validate_file_entries(index: index)
    end
  end

  # ===========================================================================
  # :section: Download tests
  # ===========================================================================

  test 'search - download - anonymous' do
    download_item(nil, :emma, meth: __method__)
  end

  test 'search - download - staff' do
    download_item(@staff, :emma, meth: __method__)
  end

  test 'search - download - EMMA native item' do
    download_item(@member, :emma, meth: __method__)
  end

  test 'search - download - BiblioVault item' do
    download_item(@member, :biblioVault, meth: __method__) # :bibliovault_ump
  end

  test 'search - download - InternetArchive item' do
    download_item(@member, :internetArchive, meth: __method__)
  end

  test 'search - download - ACE item' do
    download_item(@member, :ace, meth: __method__)
  end

  test 'search - download - OpenAlex item' do
    download_item(@member, :openAlex, meth: __method__)
  end

  # ===========================================================================
  # :section: Other tests
  # ===========================================================================

  test 'search - validate - standard identifiers' do
    action = :validate
    params = PRM.merge(action: action)

    show_item 'Valid IDs:'
    # noinspection SpellCheckingInspection
    valid_ids = %w[
      isbn:9780756633905
      lccn:2018012345
      oclc:3012345678
      doi:10.26717/bjstr.2024.55.008734
    ].flat_map { |i| [i, i.sub(/^[^:]+:/, '')] }.shuffle
    visit url_for(**params, identifier: valid_ids.join(','))
    screenshot
    result = JSON.parse(page.text).symbolize_keys
    assert true?(result[:valid])
    assert_equal valid_ids.size, result[:ids]&.size, 'valid_ids'
    assert result[:errors].blank?

    show_item 'Invalid IDs:'
    invalid_ids = [
      'isbn:9780756633900', # Bad check digit.
      'lccn:2018012',       # Too small.
      'oclc:301234567800',  # Too big.
    ].shuffle
    visit url_for(**params, identifier: invalid_ids.join(','))
    screenshot
    result = JSON.parse(page.text).symbolize_keys
    assert false?(result[:valid])
    assert result[:ids].blank?
    assert_equal invalid_ids.size, result[:errors]&.size, 'invalid_ids'

    show_item 'Mixed valid and invalid IDs:'
    all_ids = [*valid_ids, *invalid_ids].shuffle
    visit url_for(**params, identifier: all_ids.join(','))
    screenshot
    result = JSON.parse(page.text).symbolize_keys
    assert false?(result[:valid])
    assert_equal valid_ids.size,   result[:ids]&.size,    'mixed valid_ids'
    assert_equal invalid_ids.size, result[:errors]&.size, 'mixed invalid_ids'
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'search system test coverage' do
    skipped = %i[advanced]    # This may go away as a distinct endpoint.
    skipped += %i[image show] # Unimplemented endpoints.
    check_system_coverage SearchController, prefix: 'search', except: skipped
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  protected

  # Perform a test to visit multiple pages of search results.
  #
  # @param [Symbol] meth              Calling test method.
  # @param [Hash]   opt               URL parameters.
  #
  # @return [void]
  #
  def list_test(meth: nil, **opt)
    opt[:title] = TITLE_SEARCH unless search_terms?(**opt)
    params      = PRM.merge(action: :index, **opt)
    start_url   = url_for(**params)

    run_test(meth || __method__) do

      # Visit the first search results page.
      visit start_url
      index = 0

      # Forward sequence of search results pages.
      while index < PAGE_COUNT
        go_to_index_page(index, base_url: start_url)
        yield(index)
        click_on NEXT_LABEL, match: :first
        index += 1
      end
      assert_not_first_page

      # Reverse sequence of search results pages.
      while index > 0
        go_to_index_page(index, base_url: start_url)
        yield(index)
        click_on PREV_LABEL, match: :first
        index -= 1
      end
      assert_first_page

      # Back on the first search results page.
      go_to_index_page(index, base_url: start_url)

    end

  end

  # Indicate whether the options include search term specifier(s).
  #
  # @param [Hash] opt
  #
  def search_terms?(**opt)
    opt.slice(:q, :title, :identifier, :creator, :publisher).present?
  end

  # Await the indicated page then output its `:prev` and `:next` links.
  #
  # @param [Integer] index
  # @param [String]  base_url
  # @param [String]  expected_url
  # @param [Integer] max            Maximum number of attempts to make.
  #
  # @return [void]
  #
  # == Implementation Notes
  # Sometimes #wait_for_page succeeds but, in fact, the page is not actually
  # rendered.  For that reason, there is an extra layer of indirection which
  # re-waits for the page if neither :prev nor :next can be found.
  #
  def go_to_index_page(
    index,
    base_url:     nil,
    expected_url: nil,
    max:          DEF_WAIT_MAX_PASS
  )
    page = (index + 1 unless index.zero?)
    expected_url ||= make_path(base_url, page: page)

    links = {}
    while links.compact.blank? && (max -= 1).positive?
      next unless wait_for_page(expected_url, fatal: false)
      links = { PREV: PREV_LABEL, NEXT: NEXT_LABEL }
      links.transform_values! { first(:link, _1, minimum: 0) }
    end

    current = url_without_port(current_url)
    if links.compact.blank?
      flunk "Browser on page #{current} and not on #{expected_url}"
    end

    show_item("PAGE #{page || 1} = #{current}", join: ' | ') do
      links.map do |name, link|
        link = link[:href] if link.is_a?(Capybara::Node::Element)
        link = link&.include?('/') ? url_without_port(link) : link.inspect
        "#{name} = #{link}"
      end
    end
  end

  # For a "Results By Title" search result page, ensure that the entries are
  # valid.
  #
  # @param [Integer, nil] index       Zero-based page index.
  # @param [Integer, nil] page        One-based page number.
  # @param [Integer]      size        Entries per page.
  #
  # @return [void]
  #
  def validate_title_entries(index: nil, page: nil, size: PAGE_SIZE)
    index ||= page - 1
    page  ||= index + 1
    entries = all('.search-list-item')
    counts  = find('.counts', match: :first)

    # Verify that the indicated number of titles matches the number of entries
    # actually on the page.
    units  = counts.find('.text.single-page').text
    titles = counts.find('.total-items').text.to_i
    assert_equal 'titles', units,         'invalid units'
    assert_equal titles,   entries.size,  'invalid total-items count'

    # Verify that the page number is displayed correctly (except on the first
    # page of title results).
    assert_equal "Page #{page}", counts.find('.page-count').text if page > 1

    # Verify that the title entries contain as many file references as received
    # from the index search prior to being reorganized into a hierarchy.
    files = all('.value.field-RecordId', visible: false).size
    assert_equal size, files, 'invalid file count'
  end

  # For a "Results By File" search result page, ensure that the entries are
  # numbered correctly.
  #
  # @param [Integer, nil] index       Zero-based page index.
  # @param [Integer, nil] page        One-based page number.
  # @param [Integer]      size        Entries per page.
  #
  # @return [void]
  #
  def validate_file_entries(index: nil, page: nil, size: PAGE_SIZE)
    index ||= page - 1
    page  ||= index + 1
    entries = all('.search-list .number')
    counts  = find('.counts', match: :first)

    # Verify that the indicated number of records matches the number of entries
    # actually on the page.
    units = counts.find('.text.single-page').text
    files = counts.find('.total-items').text.to_i
    assert_equal 'records', units,        'invalid units'
    assert_equal files,     entries.size, 'invalid total-items count'
    assert_equal size,      files,        'invalid file count'

    # Verify that the page number is displayed correctly.
    assert_equal "Page #{page}", counts.find('.page-count').text

    # Verify that the entries are numbered correctly.
    offset  = index * size
    first   = offset + 1
    last    = offset + size
    assert_equal "Entry #{first}", entries.first.text.squish
    assert_equal "Entry #{last}",  entries.last.text.squish
  end

  # Click on a download link to retrieve a remediated file from search results.
  #
  # In the case of "ACE" and "Internet Archive" items, this is explicitly
  # limited to PDFs because DAISY and EPUB formats are generated "on-the-fly"
  # and that process is currently *extremely* slow on the archive.org side.
  #
  # @param [User, nil] user
  # @param [Symbol]    repo
  # @param [Symbol]    meth
  # @param [Hash]      opt
  #
  # @return [void]
  #
  def download_item(user, repo, meth:, **opt)
    return not_applicable('IA downloads unavailable') if IA_DOWNLOADS_FAILING
    opt[:title] = 'the' unless search_terms?(**opt)
    start_url = url_for(**PRM, action: :index, repository: repo, **opt)

    action, selector, format =
      case repo
        when :ace, :internetArchive then [:retrieval, '.probe', :pdf]
        when :biblioVault           then [:retrieval, '.download']
        else                             [:download,  '.download']
      end

    config  = I18n.t('emma.page._generic.download.link')

    run_test(meth || __method__) do

      final_url = start_url

      # Search results are available anonymously.
      sign_in_as(user) if user
      visit start_url

      # Should be results only for the indicated repository.
      show_url
      screenshot
      assert_current_url(final_url)

      # Get all entries on the page and find the first one which has a download
      # link for the specified format.
      links   = nil
      entries = all('.search-list-item')
      if format
        match = %Q(#{selector}[path*="type=#{format}"])
        entry =
          entries.find { |e| links = e.all(match, visible: false).presence }
        entry.click
      else
        entry = entries.first.click
        links = entry.all(selector)
      end
      screenshot

      # Click on the first applicable link of the entry.
      link = links.first.click
      css  = link[:class].split(' ')
      show_item { "     link css  = #{css.inspect}" }
      show_item { "     link path = #{link[:path].inspect}" }
      show_item { "     link href = #{link[:href].inspect}" }

      if permitted?(action, user, model: Upload)

        # Download the item.
        show_item { "User '#{user}' downloads item." }
        if (alert = entry.all('.failure').first)
          screenshot
          if IA_DOWNLOADS_SUPPORTED
            flunk "Failure alert displayed: #{alert.text.inspect}"
          else
            assert_match 'Item not available', alert.text
          end
        end

      elsif user

        show_item { "User '#{user}' blocked from downloading." }
        message  = config.dig(:role_failure, :tooltip)
        message %= { role: user.role.capitalize }
        assert_equal message, entry.find('.failure')&.text
        assert css.include?('role-failure')

      else

        show_item { 'Anonymous user blocked from downloading.' }
        message = config.dig(:sign_in, :tooltip)
        assert_equal message, entry.find('.failure')&.text
        assert css.include?('sign-in-required')

      end

    end
  end

end
