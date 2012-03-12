require_relative "./source.rb"

htm = HtmlScrap.new
htm.process_data


ENV["FROMDATE"] = (RunDate.t_date-7).to_s
ENV["TODATE"] = (RunDate.t_date-1).to_s

puts "===========Recheck for Change in last 7 days============"
html_rerun = HtmlScrap.new
html_rerun.process_data
