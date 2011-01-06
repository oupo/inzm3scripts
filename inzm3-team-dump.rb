#!ruby
# encoding: cp932
require_relative "utils.rb"


team_pkb = read_slice("team.pkb", 352)
team_pkh = open("team.pkh", "rb") {|f|
	f.pos = 48
	f.read.unpack("V*")
}

unitno_to_name = [nil] + open("unitno_to_name.txt", "rb:cp932"){|f| f.read.lines.map(&:chomp) }

teams_long = []
team_pkb.each do |b|
	team_id = read_short(b, 0x20)
	teams_long[team_id] = b
end

teams_long.each_with_index do |b, pos|
	#puts "#{b ? get_cstr(b) : "nil"}"; next
	next unless b
	name = get_cstr(b)
	team_id = read_short(b, 0x20)
	r = []
	16.times do |i|
		unitno = read_short(b, 0x40 + i * 8)
		x = read_byte(b, 0x40 + i * 8 + 2)
		next if unitno == 0
		r << "%s %s" % [unitno_to_name[unitno], dump_binary(b[0x40 + i * 8 + 2, 6])]
	end
	puts "#{name}: #{team_id}"
	puts r.join("\n")
	puts
end
