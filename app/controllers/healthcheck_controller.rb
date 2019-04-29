class HealthcheckController < ApplicationController

  #skip_before_filter :require_auth

  # the basic health status object
  class Health
    attr_accessor :healthy
    attr_accessor :message

    def initialize( status, message )
      @healthy = status
      @message = message
    end

  end

  # the response
  class HealthCheckResponse

    attr_accessor :mysql

    def is_healthy?
       mysql.healthy
    end
  end

  # # GET /healthcheck
  # # GET /healthcheck.json
  def index
    status = get_health_status( )
    response = make_response( status )
    render json: response, :status => response.is_healthy? ? 200 : 500
  end

  private

  def get_health_status
    status = {}

    # check mysql
    connected = ActiveRecord::Base.connection_pool.with_connection { |con| con.active? }  rescue false
    status[ :mysql ] = Health.new( connected, connected ? '' : 'Database connection error' )

    return( status )
  end

  def make_response( health_status )
    r = HealthCheckResponse.new
    r.mysql = health_status[ :mysql ]

    return( r )
  end

end
