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
	game_name, drop_items, drop_odds, exp, nekketu, yuujou = *line
	result << [name || game_name, drop_items, drop_odds, exp, nekketu, yuujou]
end

def add_dungeon_boss_result(all_result, games_dump)
	dgncrs = read_slice("dgncrs.dat", 20)
	dgnmatch = read_slice("dgnmatch.dat", 256)
	course_no_to_name = %w(アタック ディフェンス スピード テクニック たいりょく ふしぎ 経験値 スーパー経験値)
	chapter_range = 5..11
	num_base_courses = 6
	
	result = []
	all_result << ["地下修練場 ボス", result]
	
	chapter_range.each do |chapter|
		chapter_name = chapter == 11 ? "クリア後" : "#{chapter}章"
		
		game_ids = []
		course_no_to_name.size.times do |course|
			pos = (chapter - 1) * 9 + course
			crs = dgncrs[pos]
			match_index = read16(crs, 0x10) - 1
			match = dgnmatch[match_index]
			boss_game_id = read16(match, 4)
			game_ids << boss_game_id
		end
		
		bundle_game_id_and_course(game_ids).each do |(game_id, courses)|
			if courses.length == num_base_courses
				course_names_str = ""
			else
				course_names_str = " " + courses.map {|course| course_no_to_name[course] }.join("・")
			end
			add_result result, games_dump[game_id], "修練場 #{chapter_name}#{course_names_str}"
		end
		
	end
end

def bundle_game_id_and_course(game_ids)
	result = []
	game_id_to_result_index = {}
	game_ids.each_with_index do |game_id, course|
		if game_id_to_result_index.has_key?(game_id)
			result[game_id_to_result_index[game_id]][1] << course
		else
			game_id_to_result_index[game_id] = result.length
			result << [game_id, [course]]
		end
	end
	result
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
		end
		
		name, game_id = game_data.name, game_data.game_id
		
		add_result result, games_dump[game_id], name
	end
end

add_dungeon_boss_result all_result, games_dump


if true # text dump
	all_result.each do |(category_name, result)|
		puts "#{category_name}"
		result.each do |(name, drop_items, drop_odds, exp, nekketu, yuujou)|
			drop_text = [drop_items, drop_odds].transpose.map{|name,odd| "#{name.chomp("　")}(#{odd}%)"}.join(",")
			puts " #{name}:#{drop_text},#{exp},#{nekketu},#{yuujou}"
		end
	end
else # js dump
	puts all_result.map {|(category_name, result)|
		"%p: [\n%s\n]" % [category_name, result.map{|(name, drop_items, drop_odds, exp, nekketu, yuujou)|
			"\t{name: %p, drop_items: %p, drop_odds: %p, exp: %d, nekketu: %d, yuujou: %d}" % [name, drop_items, drop_odds, exp, nekketu, yuujou]
		}.join(",\n")]
	}.join(",\n")
end
