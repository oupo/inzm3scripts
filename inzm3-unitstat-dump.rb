#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"

def read_unit_names(buf)
	result = []
	(0...buf.size).step(104) do |i|
		result << get_cstr(buf[i, 104], 28)
	end
	result
end

def read_command_names(path_command_dat, path_command_str)
	command_dat = read_slice(path_command_dat, 36)
	command_str = open(path_command_str, "rb"){|f| f.read }
	command_dat.map {|b|
		get_cstr(command_str, read16(b, 24) * 32)
	}
end

def get_bytes(b, indexes)
	result = []
	indexes.each do |index, len|
		result << b[index, len].each_byte.map{|i| "%.2x" % i}.join(" ")
	end
	result.join(" | ")
end

def gen_unitno_to_usearch(usearch)
	r = {}
	usearch.each do |b|
		id = read_short(b, 0x24)
		r[id] = b
	end
	r
end

COMMAND_TYPE_MARK = {5 => "$", 6 => "@", 7 => "!", 8 => "#", 9 => "%"}

def command_type_mark(command)
  COMMAND_TYPE_MARK[read_byte(command, 0)] || " "
end

command_names = read_command_names("command.dat", "command.STR")
command_dat = read_slice("command.dat", 36)
unitstat = read_slice("unitstat.dat", 0x48)
unitbase = read_slice("unitbase.dat", 104)
usearch = read_slice("usearch.dat", 0x2c)
unitno_to_usearch = gen_unitno_to_usearch(usearch)

zokusei_names = [nil, "風", "林", "火", "山"]

unitbase.size.times do |pos|
	b = unitstat[pos]
	base = unitbase[pos]
	
	decode_bytes! b
	gp = read_short(b, 2)
	tp = read_short(b, 10)
	kick = read_byte(b, 17)
	body = read_byte(b, 21)
	guard = read_byte(b, 25)
	ctrl = read_byte(b, 29)
	speed = read_byte(b, 33)
	guts = read_byte(b, 37)
	stamina = read_byte(b, 41)
	wazas = 4.times.map{|i| read_short(b, 44 + i * 4) }
	waza_lvs = 4.times.map{|i| read_byte(b, 44 + i * 4 + 2) }
	limit = read_short(b, 60)
	free_val = limit - (kick+body+guard+ctrl+speed+guts+stamina)
	waza = wazas.zip(waza_lvs).map{|i, lv|
		"%s%s(%3d)" % [command_type_mark(command_dat[i]),
		               sjis_ljust(command_names[i], 20),
		               lv]
	}.join("\t")
	
	unitno = read_short(base, 0x4e)
	name = get_cstr(base, 28)
	zokusei = read_byte(base, 0x62)
	gender = read_byte(base, 0x5a)
	
	usearch_entry = unitno_to_usearch[unitno]
	
	# 11..129: ガチャスカウト
	way_scout = read_byte(usearch_entry, 0x26)
	
	bytes = get_bytes(b, [[4,4], [12,4], [18,2], [22,2], [26,2], [30,2], [34,2], [38,2], [42,2], [62,10]])
	
	puts ["%4d" % unitno, sjis_ljust(name, 10), gp, tp, kick, body, ctrl, guard, speed, stamina, guts, free_val, waza, zokusei_names[zokusei] || zokusei, way_scout].join("\t")
end
