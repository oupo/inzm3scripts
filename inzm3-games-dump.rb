#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"

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

def dump_games
	games_dat = read_slice("games.dat", 48)
	team_pkb = read_slice("team.pkb", 352)
	clbonus_dat = read_slice("clbonus.dat", 24)

	team_pkh = open("team.pkh", "rb") {|f|
		f.pos = 48
		f.read.unpack("V*")
	}

	item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }

	unitno_to_name = [nil] + open("unitno_to_name.txt", "rb:cp932"){|f| f.read.lines.map(&:chomp) }

	games_dat.each_with_index do |b, pos|
		team_id = read_short(b, 0)
		team_index = team_pkh.index(team_id)
		base_level = read_byte(b, 3)
		
		clbonus_id = read_short(b, 0xc)
		clbonus = read_clbonus(clbonus_dat[clbonus_id], item_names)
		
		
		if team_index
			team = team_pkb[team_index]
			team_name = get_cstr(team, 0)
			
			team_unit_names = []
			16.times do |i|
				unitno = read_short(team, 0x40 + i * 8)
				next if unitno == 0
				team_unit_names << unitno_to_name[unitno]
			end
		else
			team_name = nil
			team_unit_names = nil
		end
		
		items, item_odds = clbonus.items.transpose
		puts [team_name, items, item_odds, clbonus.exp, clbonus.nekketu, clbonus.yuujou, base_level, team_unit_names].inspect
	end
end

def search_level_addr
	games_dat = read_slice("games.dat", 48)
	sample = {464 => 40, 375 => 52}
	hit = Array.new(48, true)
	
	sample.each do |game_id, expected|
		game = games_dat[game_id]
		game.bytes.each_with_index do |v, i|
			if v != expected
				hit[i] = false
			end
		end
	end
	
	p hit.each_with_index.select{|(hit,i)| hit}.map{|(hit,i)| i}
end


dump_games
