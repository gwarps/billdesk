# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
# For Production and comment out the job below
#every 1.day, :at => "18:30 pm" do
# command "MODE=NORMAL ruby /usr/local/current/html_scraping/lib/scrape/billdesk_mis.rb >> /usr/local/scrap_message.txt"
#end
# For dropouts
# every 30.minutes do
# command "MODE=DROPOUT ruby /usr/local/current/html_scraping/lib/scrape/billdesk_mis.rb >> /usr/local/scrap_message.txt"
# end
every 1.minutes do
 command "ruby /home/puneet/programming/rails/billdesk-scrape/lib/scrape/billdesk_mis.rb >> /home/puneet/mesg.txt"
end
