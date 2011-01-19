#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"
require_relative "inzm3-utils.rb"

def dump_tournament_rank
	b = readfile("TournamentRank.dat")
	l = b.size / 4
	l.times do |i|
		puts "rank#{i+1}: Lv #{read16(b, i * 4)}-#{read16(b, i * 4 + 2)}"
	end
end

def dump_tournament_rank_plus
	(1..3).each do |n|
		b = readfile("TournamentRankPlus#{n}.dat")
		puts "rank +#{n}: Lv#{read16(b, 0x20)} #{read16(b, 0x22)}"
		16.times do |i|
			unitno = read16(b, i * 2)
			puts "#{get_unit_name(unitno)} (#{unitno})"
		end
		puts
	end
end

def dump_tournament
	(1..16).each do |rank|
		print "### ランク #{rank}"
		puts " (%s)" % read_slice("TournamentName%02d.dat" % rank, 20).map {|b|
			name = get_cstr(b, 0)
			odd = #{read8(b, 19)}
			"#{name}"
		}.join(", ")
		
		puts read_slice("TournamentTeam%02d.dat" % rank, 8).map {|b|
			game_id = read16(b, 0)
			odd = read8(b, 2)
			infinity_tp = read8(b, 3)
			lv = read8(b, 5)
			power = read8(b, 6)
			
			name = game_id_to_team_name(game_id)
			
			bytes = [4, 7].map {|i| "%.2x" % read8(b, i) }.join(" ")
			
			"  %.4x:%s %2d %2d  (%s)" % [game_id, sjis_ljust(name, 18), odd, lv, bytes]
		}.join("\n")
	end
end

def dump_tournament_item
	(1..16).each do |rank|
		print "### ランク #{rank}"
		puts " (%s)" % read_slice("TournamentName%02d.dat" % rank, 20).map {|b|
			name = get_cstr(b, 0)
			odd = #{read8(b, 19)}
			"#{name}"
		}.join(", ")
		
		puts "<table>"
		puts "<tr><th>アイテム<th>選択確率<th>ドロップ率<th>回復なし確率"
		
		puts read_slice("TournamentItem%02d.dat" % rank, 12).map {|b|
			item_id = read16(b, 0)
			unknown_2 = read16(b, 2)
			quantity = read16(b, 4)
			unknown_5 = read8(b, 5)
			type = read8(b, 6)
			odd_select = read8(b, 7)
			odd_drop = read8(b, 8)
			odd_no_recover = read8(b, 9)
			unknown_a = read8(b, 0xa)
			unknown_b = read8(b, 0xb)
			
			bytes = "%.4x %.2x %.2x %.2x" %
			          [unknown_2, unknown_5, unknown_a, unknown_b]
			
			item_name = get_item_name(item_id)
			if (1..3) === type
				item_name += "(#{quantity})"
			end
			
			 # "  %s %2d %2d%% %3d%% (%s)" % [sjis_ljust(item_name, 20), odd_select, odd_drop, odd_no_recover, bytes]
			 
			 "<tr><th>#{item_name}<td>#{odd_select}<td>#{odd_drop}%<td>#{odd_no_recover}%"
		}.join("\n")
		
		puts "</table>"
		
		puts
	end
end
