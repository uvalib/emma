# app/controllers/concerns/aws_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http'

# Controller support methods for access to the AWS S3 API service.
#
module AwsConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'AwsConcern')
  end

  include ApiConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  REPOSITORY_PARAMS = %i[repo   repository].freeze
  DEPLOYMENT_PARAMS = %i[deploy deployment].freeze

  NON_AWS_PARAMS = [
    *REPOSITORY_PARAMS,
    *DEPLOYMENT_PARAMS,
    *AwsHelper::AWS_SORT_OPT,
    *AwsHelper::AWS_FILTER_OPT,
  ].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the AWS S3 API service.
  #
  # @return [AwsS3Service]
  #
  def aws_api
    # noinspection RubyMismatchedReturnType
    api_service(AwsS3Service)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # repositories
  #
  # If :emma is included it will be moved to the end of the list.
  #
  # @param [String, Symbol, Array, nil] default   Default: '*'
  # @param [Hash]                       opt       Default: `#url_parameters`.
  #
  # @return [Array<Symbol>]
  #
  def repositories(default: nil, **opt)
    opt    = url_parameters if opt.blank?
    emma   = EmmaRepository.default.to_sym
    values = param_values(opt, *REPOSITORY_PARAMS)
    values = values.presence || Array.wrap(default).compact.presence || %w(*)
    values.map! do |v|
      case v.to_s.downcase
        when 'bs', /bookshare/         then :bookshare
        when 'ia', /internet.*archive/ then :internetArchive
        when 'ht', /hathi.*trust/      then :hathiTrust
        when emma.to_s                 then emma
        else                                '*'
      end
    end
    values = EmmaRepository.values.map(&:to_sym) if values.include?('*')
    values << emma if values.delete(emma)
    values
  end

  # deployments
  #
  # @param [String, Symbol, Array, nil] default   Default: '*'
  # @param [Hash]                       opt       Default: `#url_parameters`.
  #
  # @return [Array<Symbol>]
  #
  def deployments(default: nil, **opt)
    opt    = url_parameters if opt.blank?
    values = param_values(opt, *DEPLOYMENT_PARAMS)
    values = values.presence || Array.wrap(default).compact.presence || %w(*)
    values.map! do |v|
      case v.to_s.downcase
        when /prod/        then :production
        when /stag/, /dev/ then :staging
        else                    '*'
      end
    end
    values = Deployment.values.map(&:to_sym) if values.include?('*')
    values
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get a list of values from one of the indicated parameter keys.
  #
  # @param [Hash]          opt
  # @param [Array<Symbol>] keys
  #
  # @return [Array<String>]
  #
  def param_values(opt, *keys)
    opt.values_at(*keys).compact_blank.first.to_s.downcase.split(/\s*,\s*/)
  end

  # aws_params
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def aws_params(opt = nil)
    opt = url_parameters if opt.blank?
    opt[:service] ||= AwsS3Service.instance
    opt.except!(*NON_AWS_PARAMS)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # repo_bucket
  #
  # @param [Symbol, String]      repository
  # @param [Symbol, String, nil] deployment   Def: `#aws_deployment`.
  # @param [AwsS3Service, nil]   service      Def: `AwsS3Service.instance`.
  #
  # @option opt [AwsS3Service] :service       Default: `AwsS3Service.instance`
  #
  # @return [String]
  #
  def repo_bucket(repository, deployment = nil, service: nil, **)
    aws_s3 = service || AwsS3Service.instance
    aws_s3.bucket_for(repository, deployment)
  end

  # get_repo_bucket
  #
  # @param [Symbol, String]      repository
  # @param [Symbol, String, nil] deployment   Def: `#aws_deployment`.
  # @param [Hash]   opt                       Passed to #get_s3_bucket
  #
  # @option opt [AwsS3Service] :service       Default: `AwsS3Service.instance`
  #
  # @return [Aws::S3::Bucket]
  #
  def get_repo_bucket(repository, deployment = nil, **opt)
    opt  = aws_params(opt)
    name = repo_bucket(repository, deployment, **opt)
    get_s3_bucket(name, **opt)
  end

  # get_repo_objects
  #
  # @param [Symbol, String]      repository
  # @param [Symbol, String, nil] deployment   Def: `#aws_deployment`.
  # @param [Hash]   opt                       Passed to #get_s3_objects
  #
  # @option opt [AwsS3Service] :service       Default: `AwsS3Service.instance`
  #
  # @return [Array<Aws::S3::Object>]
  #
  def get_repo_objects(repository, deployment = nil, **opt)
    opt  = aws_params(opt)
    name = repo_bucket(repository, deployment, **opt)
    get_s3_objects(name, **opt)
  end

  # get_bucket_table
  #
  # @param [Array<Symbol,String>] repos
  # @param [Array<Symbol,String>] deploys
  # @param [Hash]                 opt
  #
  # @option opt [AwsS3Service, nil] :service  Default: `AwsS3Service.instance`
  #
  # @return [Hash{String=>Aws::S3::Bucket}]
  #
  def get_bucket_table(repos, deploys, **opt)
    opt = aws_params(opt)
    repos.flat_map { |repo|
      deploys.map do |deploy|
        name   = repo_bucket(repo, deploy, **opt)
        bucket = get_s3_bucket(name, **opt)
        [name, bucket]
      end
    }.to_h
  end

  # get_object_table
  #
  # @param [Array<Symbol,String>] repos
  # @param [Array<Symbol,String>] deploys
  # @param [Hash]                 opt
  #
  # @option opt [AwsS3Service, nil] :service  Default: `AwsS3Service.instance`
  #
  # @return [Hash{String=>Array<Aws::S3::Object>}]
  #
  def get_object_table(repos, deploys, **opt)
    opt = aws_params(opt)
    repos.flat_map { |repo|
      deploys.map do |deploy|
        name    = repo_bucket(repo, deploy, **opt)
        objects = get_s3_objects(name, **opt)
        [name, objects]
      end
    }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # get_s3_bucket
  #
  # @param [String] bucket
  # @param [Hash]   opt                       Passed to #s3_bucket except for:
  #
  # @option opt [AwsS3Service, nil] :service  Default: `AwsS3Service.instance`
  #
  # @return [Aws::S3::Bucket]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def get_s3_bucket(bucket, **opt)
    opt    = aws_params(opt)
    aws_s3 = opt.delete(:service)
    aws_s3.s3_bucket(bucket, **opt)
  end

  # get_s3_objects
  #
  # @param [String, Aws::S3::Bucket] bucket
  # @param [Hash]   opt                       Passed to #s3_bucket except for:
  #
  # @option opt [AwsS3Service, nil] :service  Default: `AwsS3Service.instance`
  #
  # @return [Array<Aws::S3::Object>]
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def get_s3_objects(bucket, **opt)
    opt    = aws_params(opt)
    aws_s3 = opt.delete(:service)
    aws_s3.api_list_objects(bucket, **opt)
  end

end

__loading_end(__FILE__)
