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

# For comparing change with previous record
 def self.match(scr)
  rec = Scrap.find(scr.order_id)
  if (scr.order_status==rec.order_status && scr.order_desc==rec.order_desc)
   return true
  else
   return false 
  end
 end
end

# Class for Storing Dates for a particular run (ActiveRecord)
class RunDate < ActiveRecord::Base
 def self.f_date
  return RunDate.first.from_date
 end

 def self.t_date
  return RunDate.first.to_date
 end

 def self.save_date(f_date,t_date)
  if RunDate.exists?
   dt = RunDate.first
   dt.to_date = t_date
  else
   dt = RunDate.new
   dt.from_date = f_date
   dt.to_date = t_date
  end 
 

  begin
   dt.save
   puts "Dates Saved to database for next Run"
  rescue StandardError => ex
   puts "Saving Date Failed"
  end
 end
end

# Class for Transactions
class Transaction < ActiveRecord::Base 
end
# Class for detail match

class DetailMatch < ActiveRecord::Base
 belongs_to :scrap,:class_name=>"Scrap",:foreign_key=>"order_id"
end


# Class for HTML Scrap Data

class HtmlScrap

 def initialize
  # Initialize Logger
  log_file_path = File.expand_path(File.join(File.dirname(__FILE__),"scrap.log"))
  
  file = File.open(log_file_path, File::WRONLY | File::APPEND | File::CREAT)
  @logger = Logger.new(file)
  @logger.info("SCRAP"){DateTime.now.to_s + "---------------------"}

  @count = 0
  @total = 0
  @failed = 0
  @conflict=0

  command_line
 end

# Check for command line arguments if found
 def command_line
  if (ENV["FROMDATE"].nil? | ENV["TODATE"].nil?)

   if RunDate.exists?
    @from_date = RunDate.t_date
    @to_date = Date.today
    msg = "No Environment Variables found, Using Database Dates FROM DATE :: #{@from_date} TO DATE #{@to_date}"
   else
    msg ="Input Error. No Entry in database found"
    puts msg
    exit
   end
   @logger.info("SCRAP"){msg}
   puts msg
  else
   # Checking Date for input format 
   begin
    @from_date = Date.parse(ENV["FROMDATE"])
    @to_date = Date.parse(ENV["TODATE"])
   rescue StandardError => ex
    @logger.error ex.message
    puts "Invalid Format (DATE)"
    exit
   end
   msg = "Using Command Line Arguments FROM DATE :: #{@from_date} TO DATE #{@to_date}"
   @logger.info("SCRAP"){msg}
   puts msg
  end
 end
# Return status string
def status_string(scr)
 if Transaction.exists?(scr.mil_tx_id)
   status = scr.order_status[0,1].upcase + Transaction.find(scr.mil_tx_id).status[0,1].upcase 
   return status
 else 
   return "NT"
 end 
end
# Process url using nokogiri and enter data into database
def process_data
  # Prepare URL & Nokogiri HTML
  #url = "http://localhost/milaap/check.html" #( For Testing Swap URL but specify ENV FROMDATE TODATE)
  url = "http://billbharo.com/milaap/checkorders.php?fromdate=#{@from_date}&todate=#{@to_date}&Submit=Search+Orders#"
  html_doc = Nokogiri::HTML(open(url))


  html_doc.xpath("//html/body/table/tr").each do |node|
   arr = []

   node.css("td").each do |row|
    arr << row.inner_text.strip
   end

   next if(arr[0] == "Order ID")

   scrap = Scrap.new
   scrap.order_id = arr[0]
   scrap.order_date = DateTime.parse(arr[1])
   scrap.order_amt = arr[2].to_f
   scrap.order_status = arr[3]
   scrap.payment_mode = arr[4]
   scrap.mil_tx_id = arr[5]
   scrap.order_desc = arr[6]
   scrap.borrower_id = arr[7].to_i
   scrap.borrower_name = arr[8]
   scrap.cust_name = arr[9]
   scrap.cust_email = arr[10]
   scrap.cust_phone = arr[11]
   scrap.cust_addr = arr[12]
   scrap.tag = status_string(scrap)
  @total = @total + 1
   begin
    if scrap.save
     @count = @count + 1
    end
   rescue  StandardError =>ex
     @logger.error ex.message
     @failed = @failed + 1
    
    # Check for data change 
     if not Scrap.match(scrap)
      @conflict = @conflict + 1
       detail_match = ""
      if DetailMatch.find_by_order_id(scr.order_id).nil?
       detail_match = DetailMatch.new
      else
       detail_match = DetailMatch.find_by_order_id(scr.order_id)
      end
       detail_match.order_id = scrap.order_id
       detail_match.order_status = scrap.order_status

      begin
       detail_match.save
      rescue StandardError =>ex
       @logger.error ex.message
      end
     end
   end
  end
  # Save/Update Dates in Database
  RunDate.save_date(@from_date,@to_date)
  puts "Total Parsed :: #{@total}, Total Saved :: #{@count}, Failed :: #{@failed}"
  puts "Change Db Entered/Altered :: #{@conflict}"
  @logger.info("PARSE RESULT"){"Total Parsed :: #{@total}, Total Saved :: #{@count}, Failed :: #{@failed}"}
  @logger.info("Change Data RESULT"){"Change Db Entered/Altered :: #{@conflict}\n\n"}
 end
end
