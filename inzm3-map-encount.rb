#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"
require "set"

class DataFiles
	def initialize
		@games_dat = read_slice("games.dat", 48)
		@team_pkb = read_slice("team.pkb", 352)
		@clbonus_dat = read_slice("clbonus.dat", 24)
		@rpgencountf_dat = read_slice("rpgencountf.dat", 36)
		@rpgencountb_dat = read_slice("rpgencountb.dat", 36)
		@unitbase_dat = read_slice("unitbase.dat", 104)
		@unitno_to_index = gen_unitno_to_index(@unitbase_dat)
		@item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }
	end
	
	attr_reader :games_dat, :team_pkb, :clbonus_dat, :rpgencountf_dat, :rpgencountb_dat, :unitbase_dat, :unitno_to_index, :item_names
	
	def gen_unitno_to_index(unitbase_dat)
		unitno_to_index = []
		unitbase_dat.each_with_index do |b, unitbase_index|
			unitno = read_short(b, 0x4e)
			unitno_to_index[unitno] = unitbase_index
		end
		unitno_to_index
	end
end

def dump_for_js
	maps = []
	# 「"商店街",20」のようにマップ名のエンカウントインデックスの対応を書いたファイル
	open("mapname-encount.txt", "rb:cp932") do |f|
		f.each_line do |line|
			next if line.chomp == ""
			maps << eval("[#{line}]")
		end
	end
	
	datafiles = DataFiles.new
	
	game_ids = Set.new

	buf = []
	maps.each do |(name, encount_index)|
		encount_spark  = datafiles.rpgencountf_dat[encount_index - 1]
		encount_bomber = datafiles.rpgencountb_dat[encount_index - 1]
		odds = []
		spark_game_ids = []
		bomber_game_ids = []
		
		8.times do |i|
			spark, bomber = [encount_spark, encount_bomber].map{|e| 
				{:game_id => read16(e, 4 + i * 4),
				 :odd => read16(e, 4 + i * 4 + 2)}
			}
			if spark[:odd] != bomber[:odd]
				raise "spark odd(%d) != bomber odd(%d)" % [spark[:odd], bomber[:odd]]
			end
			odd = spark[:odd]
			next if odd == 0
			odds << odd
			spark_game_ids << spark[:game_id]
			bomber_game_ids << bomber[:game_id]
			game_ids << spark[:game_id] << bomber[:game_id]
		end
		buf << to_js_obj_literal([:name, name, :odds, odds, :spark_game_ids, spark_game_ids, :bomber_game_ids, bomber_game_ids])
	end
	puts "var ENCOUNT_TABLE = [\n#{buf.join(",\n")}\n];\n\n"
	
	unitno_set = Set.new
	
	buf = []
	game_ids.sort.each do |game_id|
		game = datafiles.games_dat[game_id]
		team = get_team(datafiles, game)
		team_name = get_team_name(team)
		
		unitnos = get_team_unitnos(datafiles, team)
		unitno_set.merge(unitnos)
		
		items, nekketu, yuujou, exp = read_game_clbonus(datafiles, game)
		item_names = items.map{|i| i[0] }
		item_odds = items.map{|i| i[1] }
		buf << game_id << to_js_obj_literal([:team_name, team_name, :unitnos, unitnos, :item_names, item_names, :item_odds, item_odds, :nekketu, nekketu, :yuujou, yuujou, :exp, exp])
	end
	puts "var GAMES_DATA = #{to_js_obj_literal(buf, 1, true)};\n\n"
	
	buf = []
	unitno_set.sort.each do |unitno|
		buf << unitno << unitno_to_name(datafiles, unitno)
	end
	puts "var UNIT_NAMES = #{to_js_obj_literal(buf, 10, false)};"
	
end

def get_team(datafiles, game)
	team_id = read16(game, 0)
	datafiles.team_pkb.find{|b| read16(b, 0x20) == team_id }
end

def get_team_name(team)
	get_cstr(team, 0)
end

def get_team_unitnos(datafiles, team)
	unitnos = []
	16.times do |i|
		unitno = read16(team, 0x40 + i * 8)
		next if unitno == 0
		unitnos << unitno
	end
	unitnos
end

def unitno_to_name(datafiles, unitno)
	unit = unitno_to_unitbase(datafiles, unitno)
	get_cstr(unit, 28)
end

def unitno_to_unitbase(datafiles, unitno)
	datafiles.unitbase_dat[datafiles.unitno_to_index[unitno]]
end

def read_game_clbonus(datafiles, game)
	clbonus_id = read16(game, 0xc)
	read_clbonus(clbonus_id)
end

def read_clbonus(datafiles, clbonus_id)
	clbonus = datafiles.clbonus_dat[clbonus_id]
	items = []
	3.times do |i|
		item_id = read16(clbonus, 10 + i * 2)
		item_odd = read8(clbonus, 16 + i)
		item_name = datafiles.item_names[item_id]
		items << [item_name, item_odd]
	end
	nekketu = read_long(clbonus, 0)
	yuujou = read_long(clbonus, 4)
	exp = read_short(clbonus, 8)
	odd = read_byte(clbonus, 22)
	return items, nekketu, yuujou, exp, odd
end

def to_js_obj_literal(obj, block_num=nil, no_inspect=false)
	ret = []
	obj.each_slice(2) do |(key, val)|
		val_s = no_inspect ? val : val.inspect
		ret << "#{key}: #{val_s}"
	end
	s = ret.each_slice(block_num || ret.size).map{|i| i.join(", ") }.join(",\n")
	x = block_num ? "\n" : ""
	"{#{x}#{s}#{x}}"
end

def dump_all_encount_info
	maps = []
	open("mapname-encount.txt", "rb:cp932") do |f|
		f.each_line do |line|
			next if line.chomp == ""
			maps << eval("[#{line}]")
		end
	end
	
	datafiles = DataFiles.new

	maps.each do |(name, encount_index)|
		encount_spark  = datafiles.rpgencountf_dat[encount_index - 1]
		encount_bomber = datafiles.rpgencountb_dat[encount_index - 1]
		odd_sum = 0
		
		num_units_spark = count_all_unit_num(datafiles, encount_spark)
		num_units_bomber = count_all_unit_num(datafiles, encount_bomber)
		
		if num_units_spark == num_units_bomber
			puts "#{name} (合計人数 #{num_units_spark})"
		else
			puts "#{name} (合計人数 スパーク:#{num_units_spark}, ボンバー:#{num_units_bomber})"
		end
		
		8.times do |i|
			spark, bomber = [encount_spark, encount_bomber].map{|e| 
				{:game_id => read16(e, 4 + i * 4),
				 :odd => read16(e, 4 + i * 4 + 2)}
			}
			if spark[:odd] != bomber[:odd]
				raise "spark odd(%d) != bomber odd(%d)" % [spark[:odd], bomber[:odd]]
			end
			odd = spark[:odd]
			odd_sum += odd
			next if odd == 0
			
			if spark[:game_id] == bomber[:game_id]
				dump_game datafiles, spark[:game_id], odd
			else
				dump_game datafiles, spark[:game_id], odd, "スパーク限定:"
				dump_game datafiles, bomber[:game_id], odd, "ボンバー限定:"
			end
			
		end
		raise "odd_sum = #{odd_sum}" if odd_sum != 100
	end
end

def count_all_unit_num(datafiles, encount)
	sum = 0
	8.times do |i|
		game_id = read16(encount, 4 + i * 4)
		sum += game_id_to_team_num_units(datafiles, game_id)
	end
	sum
end

def game_id_to_team_num_units(datafiles, game_id)
	get_team_unitnos(datafiles, get_team(datafiles, datafiles.games_dat[game_id])).length
end

def dump_game(datafiles, game_id, odd, note = "")
	game = datafiles.games_dat[game_id]
	team = get_team(datafiles, game)
	team_name = get_team_name(team)
	clbonus_id = read16(game, 0xc)
	
	unitnos = get_team_unitnos(datafiles, team)
	unitnames = unitnos.map{|unitno| unitno_to_name(datafiles, unitno) }
	
	puts "  #{note}#{team_name} (#{odd}%)"
	puts "    メンバー: #{unitnames.join(",")} (#{unitnos.length}人)"
	puts "    [デフォルト] #{dump_clbonus(datafiles, clbonus_id)}"
	
	unitnos.each do |unitno|
		unitbase = unitno_to_unitbase(datafiles, unitno)
		name = unitno_to_name(datafiles, unitno)
		special_clbonus_id = read8(unitbase, 0x63)
		if special_clbonus_id != 0
			label = sjis_ljust("[#{name}]", 5*2+2)
			puts "    #{label} #{dump_clbonus(datafiles, special_clbonus_id)}"
		end
	end
end

def dump_clbonus(datafiles, clbonus_id)
	items, nekketu, yuujou, exp, odd = read_clbonus(datafiles, clbonus_id)
	items = items.map {|(name, o)| "#{sjis_ljust(name, 20)}(#{"%3d" % o}%)" }
	odd_note = odd != 0 ? "(%2d%%)" % odd : "     "
	"%sドロップ: %s, クリアポイント: %4d, 熱血: %4d, 友情: %3d" % [odd_note, items.join(","), exp, nekketu, yuujou]
end


#dump_mapname_encount
dump_all_encount_info
#dump_for_js
