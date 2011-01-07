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
	["�Η��Z���̃G�N�X�g���ΐ탋�[�g", [["��", 3], ["��", 4], ["��", 7]]],
	["�G�L�V�r�V�����ΐ탋�[�g", [["��", 6], ["��", 7]]],
	["�i�]�̃G�N�X�g���ΐ탋�[�g", [["��", 4], ["��", 6]]],
	["�_�C�X�P�̒������g�[�i�����g", [["��", 7], ["��", 8]]],
	["�S���Y���̒������g�[�i�����g", [["��", 10], ["��", 9]]],
	["�[���̒������g�[�i�����g", [["��", 11], ["��", 9]]],
	["�h���[���������g�[�i�����g", [["��", 5], ["��", 6]]],
	["����Y�̒������g�[�i�����g", [["��", 7], ["��", 10]]],
	["���q�̒������g�[�i�����g", [["��", 9], ["��", 9]]],
	["���V�F�̒������g�[�i�����g", [["", 10]]],
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
		drop_text = [drop_items, drop_odds].transpose.map{|name,odd| "#{name.chomp("�@")}(#{odd}%)"}.join(",")
		puts " #{name}:#{drop_text},#{exp},#{nekketu},#{yuujou}"
		#add_result result, games_dump[game_id]
	end
end

all_result.map {|(category_name, result)|
	"%p: [\n%s\n]" % [category_name, result.join(",\n")]
}.join(",\n")
