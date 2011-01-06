#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"

item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }
premium_item = read_slice("premium_item.dat", 36)
unitbase_dat = read_slice("unitbase.dat", 104)

# unitnoからunitbase.datインデックスへ
unitno_to_index = []
unitbase_dat.each_with_index do |b, unitbase_index|
	unitno = read_short(b, 0x4e)
	unitno_to_index[unitno] = unitbase_index
end

premium_item.each do |b|
	item_id = read16(b, 0)
	units = 8.times.map {|i|
		[read16(b, 4 + i * 4), read16(b, 4 + i * 4 + 2)]
	}
	print "#{item_names[item_id]}(#{read16(b, 2)}): "
	puts units.map {|(unitno, lv)|
		next nil if unitno == 0
		unit = unitbase_dat[unitno_to_index[unitno]]
		name = get_cstr(unit, 28)
		"#{name} (#{lv})"
	}.compact.join(", ")
end
