require "active_record"
require "nokogiri"
require "date"
require "open-uri"
require "logger"

# ----------------

ActiveRecord::Base.establish_connection(
:adapter=>"mysql",
:host=>"localhost",
:username=>"root",
:password=>"puneet123",
:database=>"html-scrap_development")

# Class for Scraps ActiveRecord
class Scrap < ActiveRecord::Base
 self.primary_key = "order_id"
end

# Class for Storing Dates for a particular run (ActiveRecord)
class RunDate < ActiveRecord::Base
 def self.f_date
  return RunDate.first.from_date
 end

 def self.t_date
  return RunDate.first.to_date
 end
end

# Class for HTML Scrap Data

class HtmlScrap

 def initialize
  # Initialize Logger
  file = File.open("scrap.log", File::WRONLY | File::APPEND | File::CREAT)
  @logger = Logger.new(file)
  @logger.info("SCRAP"){DateTime.now.to_s + "---------------------"}

  @count = 0
  @total = 0
  @failed = 0

  command_line
 end

# Check for command line arguments if found
 def command_line
  if (ENV["FROMDATE"].nil? | ENV["TODATE"].nil?)
   @from_date = RunDate.f_date
   @to_date = RunDate.t_date

   msg = "No Environment Variables found, Using Database Dates FROM DATE :: #{@from_date} TO DATE #{@to_date}"
   @logger.info("SCRAP"){msg}
   puts msg
  else
   @from_date = Date.parse(ENV["FROMDATE"])
   @to_date = Date.parse(ENV["TODATE"])

   msg = "Using Command Line Arguments FROM DATE :: #{@from_date} TO DATE #{@to_date}"
   @logger.info("SCRAP"){msg}
   puts msg
  end
 end

# Process url using nokogiri and enter data into database
def process_data
  # Prepare URL & Nokogiri HTML
  url = "http://billbharo.com/milaap/checkorders.php?fromdate=#{@from_date}&todate=#{@to_date}&Submit=Search+Orders#"
  html_doc = Nokogiri::HTML(open(url))


  html_doc.xpath("//html/body/table/tr").each do |node|
   arr = []

   node.css("td").each do |row|
    arr << row.inner_text.strip
   end

   next if(arr[0] == "Order ID")

   scr = Scrap.new
   scr.order_id = arr[0]
   scr.order_date = DateTime.parse(arr[1])
   scr.order_amt = arr[2].to_f
   scr.order_status = arr[3]
   scr.payment_mode = arr[4]
   scr.mil_tx_id = arr[5]
   scr.order_desc = arr[6]
   scr.borrower_id = arr[7].to_i
   scr.borrower_name = arr[8]
   scr.cust_name = arr[9]
   scr.cust_email = arr[10]
   scr.cust_phone = arr[11]
   scr.cust_addr = arr[12]

  @total = @total + 1
   begin
    if scr.save
     @count = @count + 1
    end
   rescue  StandardError =>ex
     @logger.error ex.message
     @failed = @failed + 1
   end
  end

  puts "Total Parsed :: #{@total}, Total Saved :: #{@count}, Failed :: #{@failed}"
 end
end
