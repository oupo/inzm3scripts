#!ruby
# encoding: cp932

require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"

def dump_clbonus(clbonus_dat, index, item_names)
	b = clbonus_dat[index]
	items = []
	3.times do |i|
		item_id = read_short(b, 10 + i * 2)
		odd = read_byte(b, 16 + i)
		items << [item_names[item_id], odd]
	end
	nekketu = read_long(b, 0)
	yuujou = read_long(b, 4)
	exp = read_short(b, 8)
	
	"clbonus#%d: %s, %p" % [index, "[%s]" % items.map{|(n,o)| "#{n}(#{o})"}.join(", "), [exp, nekketu, yuujou]]
end

unitbase_dat = read_slice("unitbase.dat", 104)
clbonus_dat = read_slice("clbonus.dat", 24)
item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }


unitbase_dat.each do |unitbase|
	unitno = read16(unitbase, 0x4e)
	name = get_cstr(unitbase, 28)
	clbonus_index = read8(unitbase, 0x63)
	if clbonus_index != 0
		puts "#{name}: #{dump_clbonus(clbonus_dat, clbonus_index, item_names)}"
	end
end
