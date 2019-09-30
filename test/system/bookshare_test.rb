# test/system/bookshare_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class BookshareTest < ApplicationSystemTestCase

  API_REQUEST_ELEMENTS = '.sect3 h4'
  API_RECORD_ELEMENTS  = '#content > :last-child .sect2 h3'

  # ===========================================================================
  # :section: Verify Bookshare API request implementation
  # ===========================================================================

  test 'bookshare - API requests' do

    api = ApiService.instance

    # Scan the API documentation page.
    missing  = {}
    problems = {}
    bookshare_apidoc.find_all(API_REQUEST_ELEMENTS).each do |element|

      # Derive the specified method from the HTML element ID.
      id     = element[:id].to_s
      method = api_request_method(id)
      next if method.blank?

      # Note whether the specified method is unimplemented.
      next if !api.respond_to?(method) && (missing[method] = id)

      # Get the specified request parameters.
      parent_element   = element.first(:xpath, './parent::*', minimum: 0)
      specified_params = api_request_parameters(parent_element)
      show_request_params(specified_params, method)

      # Get the parameters defined for the implemented method.
      required_params    = ApiService::REQUIRED_PARAMETERS[method.to_sym] || []
      implemented_params = method_params(method)
      show_method_params(implemented_params, method)

      # Verify that the method implementation has all of the required
      # parameters.
      problem_params =
        specified_params.map { |specified|
          param_name  = specified[:name]
          required    = specified[:required].present?
          implemented =
            implemented_params.find { |p|
              param_name == (API_PARAM_MAPPING[p[:name]] || p[:name])
            }
          issue =
            if implemented
              implemented[:checked] = true
              i_name  = implemented[:name]
              i_req   = implemented[:required].present?
              i_req ||= required_params.include?(i_name.to_sym)
              i_req ||= (i_name == 'user') # Special case.
              if required != i_req
                is_or_not = required ? '' : 'not '
                "#{is_or_not}specified to be a required parameter"
              end
            elsif required && !required_params.include?(param_name.to_sym)
              'NOT IMPLEMENTED'
            end
          [param_name, issue] if issue.present?
        }.compact.to_h

      # Check for parameters that are not defined in the API specification.
      problem_params.merge!(
        implemented_params.map { |p|
          next if p[:checked]
          param_name = p[:name]
          specified  = API_PARAM_MAPPING[param_name] || param_name
          ignored    = (specified == '*')
          [param_name, 'INVALID (not in API specification)'] unless ignored
        }.compact.to_h
      )

      # Note any problem parameters associated with the implementation of this
      # request method.
      if problem_params.present?
        problems[method] = problem_params
        show_problem_fields(problem_params)
      end

    end

    # Report all documented requests without a corresponding implementation.
    failures = failure_list('ApiService methods', missing, problems)
    assert failures.blank?, failures

  end if TESTING_API_REQUESTS

  # ===========================================================================
  # :section: Verify Bookshare API record implementation
  # ===========================================================================

  test 'bookshare - API records' do

    # Collect API-related class names in a normalized form.
    types =
      Object.constants.map do |c|
        # API message classes from app/models/*.rb.
        next unless c.to_s.start_with?('Api')
        next unless "Object::#{c}".constantize.is_a?(Class)
        c.to_s.delete_prefix('Api').underscore
      end
    types +=
      ObjectSpace.each_object(Class).map do |c|
        # Scalar value classes from app/models/concerns/api/common.rb.
        next unless c.ancestors.include?(ScalarType)
        c.to_s.underscore
      end
    types +=
      ObjectSpace.each_object(Class).map do |c|
        # API record classes from app/models/api/*.rb.
        next unless c.ancestors.include?(Api::Record::Base)
        c.to_s.delete_prefix('Api::').underscore
      end
    types.compact!
    types.sort!
    types.uniq!

    # Scan the API documentation page.
    missing  = {}
    problems = {}
    bookshare_apidoc.find_all(API_RECORD_ELEMENTS).map do |element|

      # Derive the specified type from the HTML element ID.
      id   = element[:id].to_s
      type = record_type(id)
      next if type.blank?

      # Note whether the specified type is unimplemented.
      next if !types.include?(type) && (missing[type] = id)

      # NOTE: This enum is incorrectly documented with the records.
      # This causes #records_fields to bog down (for some reason) due to the
      # fact that the table isn't there.
      next if type == 'content_warning'

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
          field_name  = specified[:name]
          implemented = implemented_fields.find { |f| field_name == f[:name] }
          issue =
            if implemented
              implemented[:checked] = true
              s_type  = specified[:type]
              s_array = specified[:collection].present?
              i_type  = implemented[:type]
              i_array = implemented[:collection].present?
              if s_array != i_array
                is_or_not = s_array ? '' : 'not '
                "#{is_or_not}specified to be an array"
              elsif (s_type != i_type) && (s_type != API_TYPE_MAPPING[i_type])
                s_type = "Array[#{s_type}]" if s_array
                i_type = "Array[#{i_type}]" if i_array
                "should have type #{s_type} (not #{i_type})"
              end
            else
              'NOT IMPLEMENTED'
            end
          [field_name, issue] if issue.present?
        }.compact.to_h

      # Check for fields that are not defined in the API specification.
      problem_fields.merge!(
        implemented_fields.map { |f|
          next if f[:checked]
          [f[:name], 'INVALID (not in API specification)']
        }.compact.to_h
      )

      # Note any problem fields associated with the implementation of this
      # record type.
      if problem_fields.present?
        problems[type] = problem_fields
        show_problem_fields(problem_fields)
      end

    end

    # Report all documented record definitions without a corresponding
    # implementation.
    failures = failure_list('API record types', missing, problems)
    assert failures.blank?, failures

  end if TESTING_API_RECORDS

end if TESTING_BOOKSHARE_API
