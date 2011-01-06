#!ruby
# encoding: cp932

require_relative "utils.rb"

rpgencount = read_slice("rpgencountf.dat", 36)
games_data = open("games-dump.txt", "rb:cp932"){|f| f.lines.map{|i| eval(i) } }
games_data[0][0] = nil

rpgencount.each_with_index do |b, pos|
	x = read32(b, 0)
	data = 8.times.map {|i|
		game_id = read16(b, 4 + i * 4)
		odd = read16(b, 4 + i * 4 + 2)
		name = games_data[game_id][0]
		[name, odd]
	}
	puts "%3d: %p" % [pos, [x, data]]
end
