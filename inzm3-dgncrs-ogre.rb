#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"

@course_names = %w(アタック ディフェンス スピード テクニック たいりょく ふしぎ 経験値 スーパー経験値)
@chapter_range = 5..11
@item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }

DungeonData = Struct.new(:width, :height, :dist, :num_rooms, :num_enemy_rooms, :treasure)

def dump_data
	dgncrs = read_slice("dgncrs.dat", 20)
	dgntreasure = read_slice("dgntreasure.dat", 48)

	result = []
	@chapter_range.each do |chapter|
		r = []
		@course_names.size.times do |i|
			pos = to_crs_index(chapter, i)
			crs = dgncrs[pos]
			width, height, dist, num_rooms, num_enemy_rooms = read8(crs,0), read8(crs,1), read8(crs,2), read8(crs,3), read8(crs,4)
			treasure_pos = read16(crs,0x12)-1
			treasure = dgntreasure[treasure_pos]
			treasure_raw = 8.times.map do |i|
				[read16(treasure, i * 6 + 0), read16(treasure, i * 6 + 2), read16(treasure, i * 6 + 4)]
			end
			
			r << DungeonData.new(width, height, dist, num_rooms, num_enemy_rooms, treasure_raw)
		end
		result << [chapter, r]
	end
	result
end

def dump_for_js
	result = dump_data()

	puts "{\n%s\n}" % result.map{|(chapter, r)|
		"#{chapter}: [\n%s\n]" % r.map {|x|
			treasure_dump = "[%s]" % x.treasure.map{|(odd,item_id,num)| "{item: %p, odd: %d}" % [@item_names[item_id], odd] }.join(", ")
			"\t{width: %d, height: %d, dist: %d, num_rooms: %d, num_enemy_rooms: %d, treasure: %s}" %
			    [x.width, x.height, x.dist, x.num_rooms, x.num_enemy_rooms, treasure_dump]
		}.join(",\n")
	}.join(",\n")
end

def dump_treasure_text
	result = dump_data()

	result.each do |(chapter, r)|
		chapter_name = chapter == 11 ? "クリア後" : "#{chapter}章"
		r.each_with_index.group_by{|(x, course)| x.treasure }.each do |treasure, courses|
			course_name = courses.map {|(x, course)| @course_names[course] }.join(", ")
			treasure_dump = treasure.map{|(odd,item_id,num)| "  %s%s(%d%%)" % [@item_names[item_id], num == 1 ? "" : " x #{num}", odd] }.join("\n")
			puts "#{chapter_name} #{course_name}:\n#{treasure_dump}"
		end
	end
end

def simple_dump
	dgncrs = read_slice("dgncrs.dat", 20)

	puts "width,height,dist,num_rooms,num_enemy_rooms,match_index,treasure_index"
	dgncrs.each_with_index do |b,pos|
		puts "%3d:%2d,%2d,%2d,%2d,%2d,%2d" % [pos, read8(b,0), read8(b,1), read8(b,2), read8(b,3), read8(b,4), read16(b,0x10)-1, read16(b,0x12)-1]
	end
end

def game_id_dump
	dgncrs = read_slice("dgncrs.dat", 20)
	dgnmatch = read_slice("dgnmatch.dat", 256)
	games_data = open("games-dump.txt", "rb:cp932"){|f| f.read.lines.map{|i| eval(i) } }
	
	@chapter_range.each do |chapter|
		@course_names.size.times do |course|
			pos = to_crs_index(chapter, course)
			crs = dgncrs[pos]
			match_index = read16(crs, 0x10) - 1
			match = dgnmatch[match_index]
			boss_game_id = read16(match, 4)
			team_name, drop_items, drop_odds, exp, nekketu, yuujou = games_data[boss_game_id]
			
			#puts "#{chapter}-#{course}: #{boss_game_id}"
			name = "修練場 #{chapter}章 #{@course_names[course]}"
			puts "{name: #{name.inspect}, drop_items: #{drop_items.inspect}, drop_odds: #{drop_odds.inspect}, exp: #{exp}, nekketu: #{nekketu}, yuujou: #{yuujou}},"
		end
	end
end

def to_crs_index(chapter, course)
	(chapter - 1) * 9 + course
end

#dump_for_js
#dump_treasure_text
game_id_dump
#simple_dump