require_relative "./source.rb"


ENV["FROMDATE"] = "2011/12/01"
ENV["TODATE"] = "2011/12/30"
htm = HtmlScrap.new
#htm.process_data
puts RunDate.t_date-1
puts RunDate.t_date-8

