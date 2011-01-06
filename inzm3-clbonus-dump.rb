#!ruby
# encoding: cp932
require_relative "utils.rb"


clbonus = open("clbonus.dat", "rb"){|f| f.read }
item_names = open("item-names.txt", "rb:cp932"){|f| f.read.lines.map{|i| i.chomp} }

(clbonus.size / 24).times do |pos|
	b = clbonus[pos*24, 24]
	items = 3.times.map {|i|
		item_id = read_short(b, 10 + i * 2)
		odd = read_byte(b, 16 + i)
		"#{item_names[item_id]}: #{odd}"
	}.join(", ")
	nekketu = read_long(b, 0)
	yuujou = read_long(b, 4)
	exp = read_short(b, 8)
	bytes = b.bytes.map{|i|"%.2x"%i}.join(" ")
	puts "#{pos}: #{items}, #{[exp, nekketu, yuujou].inspect}"
end
