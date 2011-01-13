#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"
require_relative "inzm3-utils.rb"

@ogre = true

def text_dump()
	all_result = build_data()
	all_result.each do |(category_name, result)|
		puts "#{category_name}"
		result.each do |e|
			bonus = e.clbonus
			drop_text = bonus.items.map{|name,odd| "#{name.chomp("　")}(#{odd}%)"}.join(",")
			bonus_text = "#{bonus.exp},#{bonus.nekketu},#{bonus.yuujou}"
			
			puts " #{e.name2}:#{drop_text},#{bonus_text}"
			
			e.unitnos.each do |unitno|
				sym = hastalkfile?(unitno) ? "o " : "x "
				puts "#{sym} #{get_unit_name(unitno)}"
			end
		end
	end
end

def js_dump
	unitno_to_id = {}
	Dir.chdir("inazuma3-dumpfile") {
		@ogre = false
		puts "var PRACTICE_GAME_DATA = {\n#{js_dump0(unitno_to_id)}\n};"
	}
	puts
	Dir.chdir("ogre-dumpfile") {
		@ogre = true
		puts "var PRACTICE_GAME_DATA_OGRE = {\n#{js_dump0(unitno_to_id)}\n};"
	}
	puts
	
	unitnos = unitno_to_id.each_pair.to_a.sort_by{|unitno, id| id }.map{|unitno, id| unitno }
	
	Dir.chdir("ogre-dumpfile") {
		uninames = []
		puts "var UNITNAMES = ["
		puts unitnos.map {|unitno| get_unit_name(unitno).inspect }.each_slice(10).map{|i| i.join(", ") }.join(",\n")
		puts "];"
		
		puts "var UNIT_HASTALKFILE = ["
		puts unitnos.map {|unitno| hastalkfile?(unitno) }.each_slice(15).map{|i| i.join(", ") }.join(",\n")
		puts "];"
	}
end

def js_dump0(unitno_to_id)
	all_result = build_data()
	all_result.map {|(category_name, result)|
		"\t%p: [\n%s\n\t]" % [category_name, result.map{|e|
			drop_items, drop_odds = *e.clbonus.items.transpose
			bonus = e.clbonus
			
			# 選手名とかの配列を小さくするためそのままの選手Noではなく、登場する選手だけで詰めたIDを使う
			unitids = e.unitnos.map {|unitno| unitno_to_id[unitno] ||= unitno_to_id.size }
			
			"\t\t{name: %p, drop_items: %p, drop_odds: %p, exp: %d, nekketu: %d, yuujou: %d, units: %p}" % [e.name2, drop_items, drop_odds, bonus.exp, bonus.nekketu, bonus.yuujou, unitids]
		}.join(",\n")]
	}.join(",\n")
end

@practice_metadata = [
	["火来校長のエクストラ対戦ルート", [["中", 3], ["上", 4], ["下", 7]]],
	["エキシビション対戦ルート", [["上", 6], ["下", 7]]],
	["ナゾのエクストラ対戦ルート", [["上", 4], ["下", 6]]],
	["ダイスケの超次元トーナメント", [["上", 7], ["下", 8]]],
	["鬼瓦刑事の超次元トーナメント", [["上", 10], ["下", 9]]],
	["夕香の超次元トーナメント", [["上", 11], ["下", 9]]],
	["ドリーム超次元トーナメント", [["上", 5], ["下", 6]]],
	["総一郎の超次元トーナメント", [["上", 7], ["下", 10]]],
	["瞳子の超次元トーナメント", [["上", 9], ["下", 9]]],
]

if @ogre
	@practice_metadata << ["ルシェの超次元トーナメント", [["", 10]]]
end

def build_data()
	games_data = build_games_data()
	
	all_result = []
	
	Dir.glob("PracticeGame*F.dat") do |path|
		practice_name, route_data = @practice_metadata[path[/\d+/].to_i]
		
		data = read_slice(path, 74)
		data_other = @ogre ? data : read_slice(path.sub("F.dat", "B.dat"), 74)
		
		reader = RouteDataReader.new(route_data)
		result = nil
		
		data.zip(data_other) do |b, b2|
			name,  game_id  = get_cstr(b,  12), read_short(b,  60)
			name2, game_id2 = get_cstr(b2, 12), read_short(b2, 60)
			
			next if game_id == 0 or game_id == 0xffff
			
			route_name, route_offset = reader.next()
			if route_offset == 0
				result = []
				all_result << ["#{practice_name} - #{route_name}", result]
			end
			
			add_result result, games_data[game_id], name
			
			if game_id != game_id2
				add_result result, games_data[game_id2], name2
			end
		end
	end

	add_dungeon_boss_result all_result, games_data
	
	all_result
end

GameData = Struct.new(:id, :name, :name2, :clbonus, :unitnos)

def build_games_data()
	games_dat = read_slice("games.dat", 48)
	team_pkb = read_slice("team.pkb", 352)
	clbonus_dat = read_slice("clbonus.dat", 24)

	team_pkh = open("team.pkh", "rb") {|f|
		f.pos = 48
		f.read.unpack("V*")
	}

	item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }

	result = []

	games_dat.each_with_index do |b, pos|
		team_id = read_short(b, 0)
		team_index = team_pkh.index(team_id)
		base_level = read_byte(b, 3)
		
		clbonus_id = read_short(b, 0xc)
		clbonus = read_clbonus(clbonus_dat[clbonus_id], item_names)
		
		next unless team_index
		
		team = team_pkb[team_index]
		team_name = get_cstr(team, 0)
		
		unitnos = []
		16.times do |i|
			unitno = read_short(team, 0x40 + i * 8)
			next if unitno == 0
			unitnos << unitno
		end
		
		result[pos] = GameData.new(team_id, team_name, team_name, clbonus, unitnos)
	end
	result
end

ClBonus = Struct.new(:items, :exp, :nekketu, :yuujou)

def read_clbonus(b, item_names)
	items = []
	3.times do |i|
		item_id = read_short(b, 10 + i * 2)
		odd = read_byte(b, 16 + i)
		items << [item_names[item_id], odd]
	end
	nekketu = read_long(b, 0)
	yuujou = read_long(b, 4)
	exp = read_short(b, 8)
	
	ClBonus.new(items, exp, nekketu, yuujou)
end

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

def add_result(result, game_data, name=nil)
	r = game_data.dup
	r.name2 = name || r.name
	result << r
end

def add_dungeon_boss_result(all_result, games_data)
	dgncrs = read_slice("dgncrs.dat", 20)
	dgnmatch = read_slice("dgnmatch.dat", 256)
	course_no_to_name = %w(アタック ディフェンス スピード テクニック たいりょく ふしぎ)
	course_no_to_name += %w(経験値 スーパー経験値) if @ogre
	chapter_range = 5..11
	num_base_courses = 6
	
	result = []
	all_result << ["地下修練場 ボス", result]
	
	chapter_range.each do |chapter|
		chapter_name = chapter == 11 ? "クリア後" : "#{chapter}章"
		
		game_ids = []
		course_no_to_name.size.times do |course|
			pos = (chapter - 1) * (@ogre ? 9 : 7) + course
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
			add_result result, games_data[game_id], "修練場 #{chapter_name}#{course_names_str}"
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
