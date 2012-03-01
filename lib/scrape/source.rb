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
  file = File.open("scrap.log", File::WRONLY | File::APPEND | File::CREAT)
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
   scr.tag = status_string(scr)
  @total = @total + 1
   begin
    if scr.save
     @count = @count + 1
    end
   rescue  StandardError =>ex
     @logger.error ex.message
     @failed = @failed + 1
    
    # Check for data change 
     if not Scrap.match(scr)
      @conflict = @conflict + 1
       dm = ""
      if DetailMatch.find_by_order_id(scr.order_id).nil?
       dm = DetailMatch.new
      else
       dm = DetailMatch.find_by_order_id(scr.order_id)
      end
       dm.order_id = scr.order_id
       dm.order_status = scr.order_status

      begin
       dm.save
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
 end
end
