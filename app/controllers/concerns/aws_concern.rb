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
  # @note Currently unused.
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
  # @param [Hash]                       prm       Passed to #param_values.
  #
  # @return [Array<Symbol>]
  #
  def repositories(default: nil, **prm)
    values = param_values(prm, *REPOSITORY_PARAMS)
    values = values.presence || Array.wrap(default).compact.presence
    if values.nil? || values.include?('*')
      values = EmmaRepository.values.map(&:to_sym)
    else
      values.map! { |v|
        case v.to_s.downcase
          when 'bs', /bookshare/         then :bookshare
          when 'ia', /internet.*archive/ then :internetArchive
          when 'ht', /hathi.*trust/      then :hathiTrust
          else Log.debug { "#{__method__}: #{v.inspect}: invalid" }
        end
      }.uniq!
    end
    emma = EmmaRepository.default.to_sym
    values << emma if values.delete(emma)
    values
  end

  # deployments
  #
  # @param [String, Symbol, Array, nil] default   Default: '*'
  # @param [Hash]                       prm       Passed to #param_values.
  #
  # @return [Array<Symbol>]
  #
  def deployments(default: nil, **prm)
    values = param_values(prm, *DEPLOYMENT_PARAMS)
    values = values.presence || Array.wrap(default).compact.presence
    if values.nil? || values.include?('*')
      values = Deployment.values.map(&:to_sym)
    else
      values.map! { |v|
        # noinspection SpellCheckingInspection
        case v.to_s.downcase
          when /prod(uction)?/                then :production
          when /stag(ing)?/, /dev(elopment)?/ then :staging
          else Log.debug { "#{__method__}: #{v.inspect}: invalid" }
        end
      }.uniq!
    end
    values
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get a list of values from one of the indicated parameter keys.
  #
  # @param [Hash, nil]     opt        Default: `#url_parameters`.
  # @param [Array<Symbol>] keys
  #
  # @return [Array<String>]
  #
  def param_values(opt, *keys)
    prm = url_parameters(opt.presence)
    prm.values_at(*keys).compact_blank.first.to_s.downcase.split(/\s*,\s*/)
  end

  # aws_params
  #
  # @param [Hash, nil] opt            Default: `#url_parameters`.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def aws_params(opt = nil)
    prm = url_parameters(opt)
    prm[:service] ||= AwsS3Service.instance
    prm.except!(*NON_AWS_PARAMS)
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
  # @return [String]
  #
  #--
  # noinspection RubyMismatchedParameterType
  #++
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
  # @note Currently unused.
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
  # @note Currently unused.
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
  # @note Currently unused.
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
    aws_s3.aws_list_objects(bucket, **opt) || []
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
