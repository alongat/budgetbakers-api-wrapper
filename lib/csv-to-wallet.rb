require 'budgetbakers'
require 'date'

# CSV should be as follows in UTF-8
# DATE,NAME,AMOUNT

module CsvToWallet
  def self.push_csv_to_wallet(filename, email, fix_date=nil, apikey=nil, flip_amount=true)
    api = Budgetbakers::API.new(email, apikey)
    load_name_category_map
    CSV.foreach(filename) do |row|
      date = row[0]
      name = row[1]
      amount = row[2]
      category = @category_map[name]
      if category.nil?
        puts "Enter category for #{name} | #{name.reverse}:"
        category = gets
        @category_map[name] = category.chomp!
      end
      body = {
          category_name: category,
          account_name: 'Bank account',
          amount: flip_amount ? 0-amount.to_i : amount,
          date: fix_date || date,
          note: name
      }
      api.create_record(body)
    end
  rescue Exception => e
    puts e
  ensure
    write_name_category_map
  end

  MAP_FILENAME = 'CATMAP.csv'.freeze

  def self.load_name_category_map(filename=MAP_FILENAME)
    @category_map = {}
    CSV.foreach(filename) { |row| @category_map[row[0]]=row[1] }
  rescue
    @category_map
  end

  def self.write_name_category_map(filename=MAP_FILENAME)
    CSV.open(filename, 'w') do |csv|
      @category_map.each { |x,y| csv << [x,y] }
    end
  end
end