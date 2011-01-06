#!ruby
# encoding: cp932

require_relative "utils.rb"

unitbase_dat = read_slice("unitbase.dat", 104)
usearch_dat = read_slice("usearch.dat", 44)

# unitnoからunitbase.datインデックスへ
unitno_to_index = []
unitbase_dat.each_with_index do |b, unitbase_index|
	unitno = read_short(b, 0x4e)
	unitno_to_index[unitno] = unitbase_index
end

unitno2level = {}
usearch_dat.each do |b|
	unitno = read_short(b, 0x24)
	name = get_cstr(b, 0)
	level = read_byte(b, 0x26)
	
	base_index = unitno_to_index[unitno]
	if base_index
		base = unitbase_dat[base_index]
		name_base = get_cstr(base, 0)
	end
	
	if (191..200).include?(level)
		unitno2level[unitno] = level
		#puts "%s, %s, %d, %d" % [name_base, name, unitno, level]
	end
end


# 仲間にする方法の値 => バトル後仲間になる確率
odds = {191 => 40, 192 => 35, 193 => 25, 194 => 12, 195 => 10}

r = []
unitno2level.keys.sort.each do |unitno|
	r << "#{unitno} => #{odds[unitno2level[unitno]]}"
end
puts r.each_slice(15).map{|i| i.join(", ") }.join(",\n")

