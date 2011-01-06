#!ruby
# encoding: cp932

require_relative "utils.rb"

@unitbase_dat = read_slice("unitbase.dat", 104)
@usearch_dat = read_slice("usearch.dat", 44)

# unitnoからunitbase.datインデックスへ
@unitno_to_index = []
@unitbase_dat.each_with_index do |b, unitbase_index|
	unitno = read_short(b, 0x4e)
	@unitno_to_index[unitno] = unitbase_index
end

def unitno_to_name(unitno)
	index = @unitno_to_index[unitno]
	base = @unitbase_dat[index]
	get_cstr(base, 28)
end

num_machine = 12
num_color = 3

cupsule_type_to_unitno = Array.new(num_machine+1) { Array.new(num_color) { [] } }
@usearch_dat.each do |b|
	unitno = read16(b, 0x24)
	jointype = read8(b, 0x26)
	
	next unless (11..129).include?(jointype)
	machineno = jointype / 10
	if jointype % 10 == 0
		raise "jointype = %d, unit = %s" % [jointype, unitno_to_name(unitno)]
	end
	color = (jointype % 10 - 1) / 3
	rare_degree = (jointype % 10 - 1) % 3
	
	cupsule_type_to_unitno[machineno][color] << [unitno, rare_degree]
end

result = []
(1..num_machine).each do |machineno|
	r = []
	cupsule_type_to_unitno[machineno].each_with_index do |units, color|
		#puts "%d-%d: %s" % [machineno, color,
		#	units.map{|(unitno, rare_degree)| "%s(%d)" % [unitno_to_name(unitno), rare_degree] }.join(", ")]
		r << "[%s]" % units.map{|(unitno, rare_degree)| "[%p, %d]" % [unitno_to_name(unitno), rare_degree] }.join(", ")
	end
	result << r.join(",\n")
end
puts "[\n%s\n]" % result.join("\n], [\n")

