require 'budgetbakers/version'
require 'rubygems' if RUBY_VERSION < '1.9'
require 'httparty'
require 'awesome_print'

module Budgetbakers
  class API
    include HTTParty
    API_VERSION = '3.0'

    # Initialize
    def initialize
      self.class.base_uri('https://api.budgetbakers.com/api/v1')
      @headers = {
          'X-Token' => ENV['BB_TOKEN'],
          'Content-Type' => 'application/json'
      }
    end

    def check_email(email)
      response = get("/user/exists/#{email}")
      response.code == 200
    end

    def list_accounts(email)
      response = get('/accounts', additional_headers: { 'X-User' => email })
      ap response
    end

    def list_records(email)
      response = get('/records', additional_headers: { 'X-User' => email })
      ap response
    end

    private

    def get(url, options={})
      @headers.merge!(options[:additional_headers]) if options[:additional_headers]
      self.class.get(url, headers: @headers)
    end
  end
end
