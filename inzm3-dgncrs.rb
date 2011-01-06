#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"


def dump_for_js
	dgncrs = read_slice("dgncrs.dat", 20)
	dgntreasure = read_slice("dgntreasure.dat", 48)
	item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }
	chapter_range = 5..11

	result = []
	chapter_range.each do |chapter|
		r = []
		6.times do |i|
			pos = (chapter - 1) * 7 + i
			crs = dgncrs[pos]
			width, height, dist, num_rooms, num_enemy_rooms = read8(crs,0), read8(crs,1), read8(crs,2), read8(crs,3), read8(crs,4)
			treasure_pos = read16(crs,0x12)-1
			treasure = dgntreasure[treasure_pos]
			treasure_raw = 8.times.map do |i|
				[read16(treasure, i * 6 + 0), read16(treasure, i * 6 + 2), read16(treasure, i * 6 + 4)]
			end
			treasure_dump = "[%s]" % treasure_raw.map{|(odd,item_id,unknown)| "{item: %p, odd: %d}" % [item_names[item_id], odd] }.join(", ")
			
			r << "\t{width: %d, height: %d, dist: %d, num_rooms: %d, num_enemy_rooms: %d, treasure: %s}" % [width, height, dist, num_rooms, num_enemy_rooms, treasure_dump]
		end
		result << [chapter, r]
	end

	puts "{\n%s\n}" % result.map{|(chapter, r)|
	  "#{chapter}: [\n%s\n]" % r.join(",\n")
	}.join(",\n")
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
	course_names = %w(�A�^�b�N �f�B�t�F���X �X�s�[�h �e�N�j�b�N ������傭 �ӂ���)
	
	chapter_range = 5..10
	num_course = 6
	
	chapter_range.each do |chapter|
		num_course.times do |course|
			pos = to_crs_index(chapter, course)
			crs = dgncrs[pos]
			match_index = read16(crs, 0x10) - 1
			match = dgnmatch[match_index]
			boss_game_id = read16(match, 4)
			team_name, drop_items, drop_odds, exp, nekketu, yuujou = games_data[boss_game_id]
			
			puts "#{chapter}-#{course}: #{boss_game_id}"
			#name = "�C���� #{chapter}�� #{course_names[course]}"
			#puts "{name: #{name.inspect}, drop_items: #{drop_items.inspect}, drop_odds: #{drop_odds.inspect}, exp: #{exp}, nekketu: #{nekketu}, yuujou: #{yuujou}},"
		end
	end
end

def to_crs_index(chapter, course)
	chapter * 7 + course
end

dump_for_js
#game_id_dump
