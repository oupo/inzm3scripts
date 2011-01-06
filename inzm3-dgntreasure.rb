#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"

item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }

dgntreasure = read_slice("dgntreasure.dat", 48)
dgntreasure.each_with_index do |b,pos|
	l = 8.times.map do |i|
		[read16(b, i * 6 + 0), read16(b, i * 6 + 2), read16(b, i * 6 + 4)]
	end
	puts "%3d:%s" % [pos, l.map{|(odd,item_id,unknown)| "[#{item_names[item_id]},#{unknown},#{odd}]" }.join(",")]
end
