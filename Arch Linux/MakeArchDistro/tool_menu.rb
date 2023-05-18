#!/usr/bin/env ruby
# obtener lista de herramientas de repositorio blackarch
puts "Herramientas"

# gem install nokogiri
require 'nokogiri'
# gem install httparty
require 'httparty'

blackarch_tools = "https://blackarch.org/tools.html"

def scraper(url)
        unparse = HTTParty.get(url)
        parse = Nokogiri::HTML(unparse.body)
        return parse
end

def get_tools
        tools = scraper(blackarch_tools)
        tools = tools.css('div.list-group-item')
        tr = tools.css('tr')
        tr.each do |tool|
                tool_name = tool.css('td.tbl-name').text
                tool_description = tool.css('td.tbl-description').text
                puts "#{tool_name}: #{tool_description}"
        end
end
