#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"

class RouteDataReader
	def initialize(data)
		@data = data
		@index = 0
		@offset = 0
	end
	
	def next()
		if @index >= @data.size
			return ["nil", @offset]
		end
		name, num = @data[@index]
		offset = @offset
		@offset += 1
		if @offset >= num
			@index += 1
			@offset = 0
		end
		[name, offset]
	end
end

games_dump = open("games-dump.txt", "rb:cp932"){|f| f.read.lines.map{|i| eval(i) } }

practice_metadata = [
	["火来校長のエクストラ対戦ルート", [["中", 3], ["上", 4], ["下", 7]]],
	["エキシビション対戦ルート", [["上", 6], ["下", 7]]],
	["ナゾのエクストラ対戦ルート", [["上", 4], ["下", 6]]],
	["ダイスケの超次元トーナメント", [["上", 7], ["下", 8]]],
	["鬼瓦刑事の超次元トーナメント", [["上", 10], ["下", 9]]],
	["夕香の超次元トーナメント", [["上", 11], ["下", 9]]],
	["ドリーム超次元トーナメント", [["上", 5], ["下", 6]]],
	["総一郎の超次元トーナメント", [["上", 7], ["下", 10]]],
	["瞳子の超次元トーナメント", [["上", 9], ["下", 9]]],
	["ルシェの超次元トーナメント", [["", 10]]],
]

GameData = Struct.new(:name, :game_id)

all_result = []

def add_result(result, line, name=nil)
	game_name, drop_items, drop_odds, exp, nekketu, yuujou = eval(line)
	result << "\t{name: %p, drop_items: %p, drop_odds: %p, exp: %d, nekketu: %d, yuujou: %d}" % [name || game_name, drop_items, drop_odds, exp, nekketu, yuujou]
end

Dir.glob("PracticeGame*F.dat") do |path|
	practice_name, route_data = practice_metadata[path[/\d+/].to_i]
	
	data = read_slice(path, 74)
	reader = RouteDataReader.new(route_data)
	result = nil
	
	data.each do |b|
		game_data = GameData.new(get_cstr(b, 12), read_short(b, 60))
		
		next if game_data.game_id == 0 or game_data.game_id == 0xffff
		
		route_name, route_offset = reader.next()
		if route_offset == 0
			result = []
			all_result << ["#{practice_name} - #{route_name}", result]
			puts "#{practice_name} - #{route_name}"
		end
		
		name, game_id = game_data.name, game_data.game_id
		
		game_name, drop_items, drop_odds, exp, nekketu, yuujou = games_dump[game_id]
		drop_text = [drop_items, drop_odds].transpose.map{|name,odd| "#{name.chomp("　")}(#{odd}%)"}.join(",")
		puts " #{name}:#{drop_text},#{exp},#{nekketu},#{yuujou}"
		#add_result result, games_dump[game_id]
	end
end

all_result.map {|(category_name, result)|
	"%p: [\n%s\n]" % [category_name, result.join(",\n")]
}.join(",\n")
