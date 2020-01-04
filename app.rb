require 'sinatra'
require 'open-uri'
require 'openssl'
require 'nokogiri'
require 'nintendo_eshop'
require 'pry'

NintendoEshop::Game.class_eval do
  def refresh_object(result)
    self.art = "https://www.nintendo.com#{result.dig(:boxArt)}"
    self.id = result.dig(:nsuid)
    self.msrp = result.dig(:msrp)
    self.sale_price = result.dig(:salePrice)
    self.title = result.dig(:title)
  end
end 

helpers do 
  # inherit module, explicitly set client values
  def set_client
    NintendoEshop.base_url = 'https://u3b6gr4ua3-dsn.algolia.net'
    NintendoEshop.api_key  = '9a20c93440cf63cf1a7008d75f7438bf'
    NintendoEshop.app_id   = 'U3B6GR4UA3'
  end 

  def document  
    Nokogiri::HTML(open('https://switcher.co/deals'))
  end 

  def game_titles 
    document.css("span.bg-black").children.map {|child| child.text}
  end

  def listings 
    set_client 
    game_titles.map do |title| 
      NintendoEshop::GamesList.by_title(title).first 
    end 
  end 
 
  def game_count
    eshop_games.count 
  end 

  def discount(retail, sale) 
    difference = retail - sale 
    enumerator = difference / retail 

    "-#{(enumerator * 100).round}%"
  end 

  def generate_json
    @file = File.new("data/eshop_sale_#{Time.now.strftime('%Y%m%d')}.json", 'w')
    arr = []
    eshop_games.each do |g|
      game = {
        :title => g.title,
        :id => g.id, 
        :msrp => g.msrp, 
        :sale_price => g.sale_price, 
        :discount => discount(g.msrp, g.sale_price),
        :art => g.art,
      }
      arr << game 
    end
    @file.write(JSON.pretty_generate(arr))
    @file.close
  end 

  # only include listings from nintendo eshop 
  def eshop_games 
    arr = [] 
    listings.each do |g| 
      if g.sale_price 
        arr << g 
      end 
    end 
    arr 
  end 

  # include to json
  def meta_critic 
  end 

  # profile to check if you own the game 
  def own?(game)
    # current_user.games.find(id: game.id)
  end 
# helpers 
end 

get '/' do 
  file = File.read('data/eshop_sale_20191209.json')
  @data_hash = JSON.parse(file)
   
  erb :layout
end 
