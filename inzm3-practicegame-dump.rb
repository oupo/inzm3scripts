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

games_dump = open("games-dump.txt", "rb:cp932"){|f| f.read.lines.map{|i| i.chomp } }

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
]

GameData = Struct.new(:name, :game_id)

all_result = []

def add_result(result, line, name=nil)
	game_name, drop_items, drop_odds, exp, nekketu, yuujou = eval(line)
	result << "\t{name: %p, drop_items: %p, drop_odds: %p, exp: %d, nekketu: %d, yuujou: %d}" % [name || game_name, drop_items, drop_odds, exp, nekketu, yuujou]
end

def add_dungeon_boss_result(all_result, games_dump)
	dgncrs = read_slice("dgncrs.dat", 20)
	dgnmatch = read_slice("dgnmatch.dat", 256)
	course_no_to_name = %w(�A�^�b�N �f�B�t�F���X �X�s�[�h �e�N�j�b�N ������傭 �ӂ���)
	chapter_range = 5..11
	num_course = 6
	
	result = []
	all_result << ["�n���C���� �{�X", result]
	
	chapter_range.each do |chapter|
		chapter_name = chapter == 11 ? "�N���A��" : "#{chapter}��"
		
		game_ids = []
		num_course.times do |course|
			pos = (chapter - 1) * 7 + course
			crs = dgncrs[pos]
			match_index = read16(crs, 0x10) - 1
			match = dgnmatch[match_index]
			boss_game_id = read16(match, 4)
			game_ids << boss_game_id
		end
		
		bundle_game_id_and_course(game_ids).each do |(game_id, courses)|
			if courses.length == num_course
				course_names_str = ""
			else
				course_names_str = " " + courses.map {|course| course_no_to_name[course] }.join("�E")
			end
			add_result result, games_dump[game_id], "�C���� #{chapter_name}#{course_names_str}"
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
	data_other = read_slice(path.sub("F.dat", "B.dat"), 74)
	reader = RouteDataReader.new(route_data)
	result = nil
	
	data.zip(data_other) do |b, b_other|
		game_data = [b, b_other].map{|i| GameData.new(get_cstr(i, 12), read_short(i, 60)) }
		
		next if game_data[0].game_id == 0 or game_data[0].game_id == 0xffff
		
		route_name, route_offset = reader.next()
		if route_offset == 0
			result = []
			all_result << ["#{practice_name} - #{route_name}", result]
		end
		
		if game_data[0].game_id == game_data[1].game_id # �X�p�[�N�ƃ{���o�[�œ����Ȃ�Е��폜
			game_data.delete_at(1)
		end
		
		game_data.each do |e|
			name, game_id = e.name, e.game_id
			add_result result, games_dump[game_id]
		end
	end
end

add_dungeon_boss_result all_result, games_dump

puts all_result.map {|(category_name, result)|
	"%p: [\n%s\n]" % [category_name, result.join(",\n")]
}.join(",\n")

