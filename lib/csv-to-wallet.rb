require 'budgetbakers'
require 'date'

# CSV should be as follows in UTF-8
# DATE,NAME,AMOUNT

module CsvToWallet
  def self.push_csv_to_wallet(filename, email, apikey, params={})
    fix_date = params[:fixed_date]
    default_category = params[:default_category]
    flip_amount = params[:flip_amount]
    account_name = params[:account_name] || 'Credit Cards'

    api = Budgetbakers::API.new(email, apikey)
    load_name_category_map
    CSV.foreach(filename, { :col_sep => "," } ) do |row|
      date = row[0]
      name = row[1]
      amount = row[2]
      category = default_category || @category_map[name.downcase]
      if category.nil?
        puts "Enter category for #{name} | #{name.reverse}:"
        category = gets
        @category_map[name] = category.chomp!
      end
      body = { category_name: category,
               account_name: account_name,
               amount: flip_amount ? 0 - amount.to_f : amount,
               date: fix_date || date,
               note: name }
      api.create_record(body)
    end
  rescue StandardError => e
    puts e
  ensure
    write_name_category_map
  end

  MAP_FILENAME = 'CATMAP.csv'.freeze

  def self.load_name_category_map(filename = MAP_FILENAME)
    @category_map = {}
    CSV.foreach(filename) { |row| @category_map[row[0].downcase] = row[1].downcase }
  rescue
    @category_map
  end

  def self.write_name_category_map(filename = MAP_FILENAME)
    CSV.open(filename, 'w') do |csv|
      @category_map.each { |x, y| csv << [x,y] }
    end
  end
end
