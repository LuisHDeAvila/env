#!/usr/bin/env ruby
# simple web scraper, by: eleAche

# gem install httparty
require 'httparty'
# gem install nokogiri
require 'nokogiri'

source_code = "https://theprivacyguide1.github.io/linux_hardening_guide"

def scraper(url)
    unparse = HTTParty.get(ur)
    parse = Nokogiri::HTML(unparse.body)
    return parse
end


page = scraper(source_code)
# seleccionamos solo las cajas con codigo
boxes_raw = page.css('div.boxed')

# imprime el contenido de las cajas
puts boxes_raw.text

# imprime el numero de cajas del articulo, para revisar e implementar cada una en un script
# puts boxes_raw.count
