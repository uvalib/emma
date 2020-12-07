# test/system/bookshare_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class BookshareTest < ApplicationSystemTestCase

  API_REQUEST_ELEMENTS = '.sect3 h4'
  API_RECORD_ELEMENTS  = '#content > :last-child .sect2 h3'

  # ===========================================================================
  # :section: Verify Bookshare API definitions.
  # ===========================================================================
  #
  test 'bookshare - API methods' do
    reference = {}
    duplicate = {}
    # noinspection RubyNilAnalysis
    BookshareService.api_methods.each_pair do |method, properties|
      next if (ref_id = properties[:reference_id].to_s).blank?
      if (existing_method = reference[ref_id])
        duplicate[ref_id] ||= [existing_method]
        duplicate[ref_id] << method
      else
        reference[ref_id] = method
      end
    end
    assert duplicate.blank?, ->() {
      duplicate.map { |element_id, methods|
        "#{element_id}: #{methods.join(', ')}"
      }.unshift('Same :reference_id for two or more API methods:').join("\n")
    }
  end

  # ===========================================================================
  # :section: Verify Bookshare API request implementation
  # ===========================================================================

  test 'bookshare - API requests' do

    # Scan the API documentation page.
    missing  = {}
    problems = {}
    bookshare_apidoc.each do |session|
      session.find_all(API_REQUEST_ELEMENTS).each do |element|

        # Derive the specified method from the HTML element ID.
        id     = element[:id].to_s
        method = api_request_method(id)
        unless method.present?
          show("*** INVALID ID #{id.inspect} for #{element.text.inspect}")
          next
        end

        # Note whether the specified method is unimplemented.
        unless bs_api.respond_to?(method)
          missing[method] = id
          next
        end

        # Get the specified request parameters.
        parent_element   = element.first(:xpath, './parent::*', minimum: 0)
        specified_params = api_request_parameters(parent_element)
        show_request_params(specified_params, method)

        # Get the parameters defined for the implemented method.
        specification      = bs_api.api_methods(method) || {}
        required_keys      = specification[:required]&.keys&.map(&:to_s) || []
        alias_params       = specification[:alias]&.stringify_keys || {}
        implemented_params = method_params(method)
        show_method_params(implemented_params, method)

        # Verify that the method implementation has all of the required
        # parameters.
        problem_params =
          specified_params.map { |specified|
            param_name  = specified[:name]
            required    = specified[:required].present?
            implemented =
              implemented_params.find do |p|
                name = p[:name]
                param_name == (alias_params[name]&.to_s || name)
              end
            problem =
              if implemented
                implemented[:checked] = true
                name = implemented[:name]
                name = alias_params[name]&.to_s || name
                req  = implemented[:required] || required_keys.include?(name)
                if required != req
                  is_or_not = required ? '' : 'not '
                  "#{is_or_not}specified to be a required parameter"
                end
              elsif required && !required_keys.include?(param_name)
                'NOT IMPLEMENTED'
              end
            [param_name, problem] if problem.present?
          }.compact.to_h

        # Check for parameters that are not defined in the API specification.
        problem_params.merge!(
          implemented_params.map { |p|
            next if p[:checked]
            param_name = p[:name]
            ignored    = %w(* ** opt).include?(param_name)
            [param_name, 'INVALID (not in API specification)'] unless ignored
          }.compact.to_h
        )

        # Note any problem parameters associated with the implementation of
        # this request method.
        if problem_params.present?
          problems[method] = problem_params
          show_problems(problem_params)
        end

      end
    end

    # Report all documented requests without a corresponding implementation.
    failures = failure_list('BookshareService methods', missing, problems)
    assert failures.blank?, failures

  end if TESTING_API_REQUESTS

  # ===========================================================================
  # :section: Verify Bookshare API record implementation
  # ===========================================================================

  test 'bookshare - API records' do

    # Collect API-related class names.
    types =
      API_NAMESPACES.flat_map do |base|
        ns = base.constants.map(&:to_s)
        ns.select { |name| "#{base}::#{name}".safe_constantize.is_a?(Class) }
      end
    types += API_ENUMS_DOCUMENTED_AS_RECORDS
    types.sort!.uniq!

    # Scan the API documentation page.
    missing  = {}
    problems = {}
    bookshare_apidoc.each do |session|
      session.find_all(API_RECORD_ELEMENTS).each do |element|

        # Derive the specified type from the HTML element ID.
        id   = element[:id].to_s
        type = record_type(id)
        unless type.present?
          show("*** INVALID ID #{id.inspect} for #{element.text.inspect}")
          next
        end

        # Note whether the specified type is unimplemented.
        unless types.include?(type)
          missing[type] = id
          next
        end

        # Skip names associated with entries in the records section which cause
        # #records_fields to bog down (for some reason) due to the fact that
        # the table isn't there.
        next if API_ENUMS_DOCUMENTED_AS_RECORDS.include?(type)

        # Get the specified record field definitions.
        parent_element   = element.first(:xpath, './parent::*', minimum: 0)
        specified_fields = record_fields(parent_element)
        show_record_fields(specified_fields, type)

        # Get the field definitions from the record implementation.
        implemented_fields = model_fields(type)
        show_model_fields(implemented_fields, type)

        # Verify that the class which implements this API record has fields
        # which meet the API specifications.
        problem_fields =
          specified_fields.map { |specified|
            field       = specified[:name]
            implemented = implemented_fields.find { |f| field == f[:name] }
            problem =
              if implemented
                implemented[:checked] = true
                s_type  = specified[:type]
                s_array = specified[:collection].present?
                i_type  = implemented[:type]
                i_array = implemented[:collection].present?
                if s_array != i_array
                  is_or_not = s_array ? '' : 'not '
                  "#{is_or_not}specified to be an array"
                elsif (s_type != i_type) && (s_type != API_TYPE_MAP[i_type])
                  s_type = "Array[#{s_type}]" if s_array
                  i_type = "Array[#{i_type}]" if i_array
                  "should have type #{s_type} (not #{i_type})"
                end
              else
                'NOT IMPLEMENTED'
              end
            [field, problem] if problem.present?
          }.compact.to_h

        # Check for fields that are not defined in the API specification.
        problem_fields.merge!(
          implemented_fields.map { |f|
            next if f[:checked]
            [f[:name], 'INVALID (not in Bookshare API specification)']
          }.compact.to_h
        )

        # Note any problem fields associated with the implementation of this
        # record type.
        if problem_fields.present?
          problems[type] = problem_fields
          show_problems(problem_fields)
        end

      end
    end

    # Report all documented record definitions without a corresponding
    # implementation.
    failures = failure_list('Bookshare API record types', missing, problems)
    assert failures.blank?, failures

  end if TESTING_API_RECORDS

end if TESTING_BOOKSHARE_API
