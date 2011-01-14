#!ruby
# encoding: cp932

require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"


item_dat = decode_file("item.dat", 44)
fmtsm_dat = read_slice("fmtsm.dat", 96)

# フォーメーション番号のサーチ
if false
p search_binary_offset(item_dat, 8) {|i|
	if i == 450 # ベーシック
		1
	elsif i == 514 # ブランゼル
		47
	else
		nil
	end
}
end

item_dat.each do |b|
	if read8(b, 0x1d) == 14
		name = get_cstr(b, 0)
		id = read8(b, 0x26)
		fmtsm = fmtsm_dat[id]
		
		coords = []
		16.times do |i|
			coords << [read8(fmtsm, i*2), read8(fmtsm, i*2+1)]
		end
		
		puts "{name: %p, coords: %p}," % [name, coords]
		
	end
end
