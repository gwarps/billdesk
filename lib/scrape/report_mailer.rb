require "action_mailer"

ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
 :address => "smtp.gmail.com",
 :port => 587,
 :domain => "gmail.com",
 :user_name => "puneet@milaap.org",
 :password => "puneet123",
 :authentication => "plain",
 :enable_starttls_auto => true 
}
ActionMailer::Base.raise_delivery_errors = false
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.view_paths = File.dirname(__FILE__)

class UserMailer < ActionMailer::Base
 default from: "puneet@milaap.org"

 # For sending regular update mails

 def send_mail(from_date,to_date,total,saved,failed,conflict,dropcount,found,file_path)
  @sub = "Billbharo Summary Report"
  @f_date =  from_date
  @t_date = to_date
  @total = total
  @saved = saved
  @failed = failed
  @conflict = conflict
  @dropcount = dropcount
  @found = found

  if (to_date-from_date) ==  6
   @sub = "Billbharo::Status check for last 7 days"
  end
  begin
   attachments['Dropouts.csv'] = File.read(file_path) if @dropcount > 0
   mail(:to => "puneet.mir@gmail.com",:subject => @sub) do |format|
    format.html
   end
  rescue StandardError => ex
   puts ex.message
  end
 end

 # For sending exceptional message due to some reasons
 def  exception_mail(message)
  @msg = message
  begin
   mail(:to => "puneet.mir@gmail.com",:subject => "SCRIPT FAILED") do |format|
    format.html
   end
  rescue StandardError => ex
   puts ex.message
  end
 end

 def dropout_mail(scrap,from_date,to_date,total,dropcount)
  @scrap = scrap
  @f_date =  from_date
  @t_date = to_date
  @total = total
  @dropcount = dropcount 
  
  begin
   mail(:to => "puneet.mir@gmail.com",:subject => "BillBharo::Dropout Transaction") do |format|
    format.html
   end 
  rescue StandardError => ex
   puts ex.message
  end
 end

 def daily_mail(from_date,to_date,dropcount,status,file_path)
  @f_date = from_date
  @t_date = to_date
  @dropcount = dropcount
  @status = status
  
  attachments['Dropouts.csv'] = File.read(file_path)
  begin
   mail(:to => "puneet.mir@gmail.com",:subject => "Billbharo Dropout") do |format|
    format.html
   end
  rescue StandardError => ex
   puts ex.message
  end
 end
end


