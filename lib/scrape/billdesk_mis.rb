require_relative "./source.rb"

htm = HtmlScrap.new
htm.process_data



puts "===========Recheck for Change in last 7 days============"
ENV["FROMDATE"] = (RunDate.t_date-7).strftime("%Y/%m/%d")
ENV["TODATE"] = (RunDate.t_date-1).strftime("%Y/%m/%d")

html_rerun = HtmlScrap.new
html_rerun.process_data
