require 'budgetbakers/version'
require 'rubygems' if RUBY_VERSION < '1.9'
require 'httparty'
require 'exceptions'
require 'awesome_print'

module Budgetbakers
  class API
    include HTTParty
    API_VERSION = '3.0'

    # Initialize
    API_URI = 'https://api.budgetbakers.com/api/v1'

    def initialize(email, api_key=nil)
      self.class.base_uri(API_URI)
      @headers = {
          'X-Token' => api_key || ENV['BB_TOKEN'],
          'Content-Type' => 'application/json',
          'X-User' => email
      }
      @categories = {}
      @accounts = {}
      @currencies = {}
      list_accounts
      list_currencies
      list_categories
    end

    def check_email(email)
      response = get("/user/exists/#{email}")
      response.code == 200
    end

    def list_accounts
      res = get('/accounts')
      res.each { |v| @accounts[v['name']] = v['id'] }
      res
    end

    def list_currencies
      res = get('/currencies')
      res.each { |v| @currencies[v['code']] = v['id'] }
      res
    end

    def list_records
      get('/records')
    end

    def dump_records_to_file
      records = list_records
      iaccounts = @accounts.invert
      icurrencies = @currencies.invert
      icategories = @categories.invert
      CSV.open("WalletDumpFile-#{Time.now.strftime('%v')}.csv", 'w') do |csv|
        csv << [:date, :category, :account, :currency, :payment_type, :amount, :note]
        records.each { |r|
          csv << [r['date'],
                  icategories[r['categoryId']],
                  iaccounts[r['accountId']],
                  icurrencies[r['currencyId']],
                  r['paymentType'], r['amount'], r['note']]
        }
      end
    end

    def list_categories
      res = get('/categories')
      res.each { |v|
        names = v['name'].split(',')
        names.each { |name| @categories[name.strip.downcase] = v['id'] }
      }
      res
    end

    def create_record(options={})
      required_params = %i(category_name account_name amount date)
      raise MissingParams unless required_params.all? { |p| options[p] }
      account_id = @accounts[options[:account_name]]
      raise AccountNotFound if account_id.nil?
      currency_id = @currencies[options[:currency] || 'ILS']
      raise UnknownCurrency if currency_id.nil?
      category_name = options[:category_name]
      category_id = @categories[category_name.strip.downcase] || create_category(category_name)
      values = [
          {
              categoryId: category_id,
              accountId: account_id,
              currencyId: currency_id,
              amount: options[:amount],
              paymentType: options[:payment_type] || 'credit_card',
              date: DateTime.parse(options[:date]).iso8601(3),
              note: options[:note] || '',
          }
      ]
      ap values.to_json
      post('/records-bulk', body: values.to_json)
    end

    def create_category(name, color=nil)
      puts "creating category #{name}"
      values = {
          name: name,
          color: color || '#ffffff',
          icon: 0,
          defaultType: 'expense',
          position: 1000
        }.to_json
      response = post('/category', body: values)
      @categories[name.strip.downcase] = response['id']
      response['id']
    end

    private

    def get(url, options={})
      @headers.merge!(options[:additional_headers]) if options[:additional_headers]
      res = self.class.get(url, headers: @headers)
      unless res.code == 200
        ap res
        raise InvalidResponse
      end
      res
    end

    def post(url, options={})
      @headers.merge!(options[:additional_headers]) if options[:additional_headers]
      res = self.class.post(url, headers: @headers, body: options[:body])
      unless res.code == 201
        ap res
        raise InvalidResponse
      end
      res
    end
  end
end
