#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"

def read_command_names(path_command_dat, path_command_str)
	command_dat = read_slice(path_command_dat, 36)
	command_str = open(path_command_str, "rb"){|f| f.read }
	command_dat.map {|b|
		get_cstr(command_str, read16(b, 24) * 32)
	}
end

item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }
premiumcondition = read_slice("premiumcondition.dat", 60)
@unitbase_dat = read_slice("unitbase.dat", 104)
command_names = read_command_names("command.dat", "command.STR")

# unitnoからunitbase.datインデックスへ
@unitno_to_index = []
@unitbase_dat.each_with_index do |b, unitbase_index|
	unitno = read_short(b, 0x4e)
	@unitno_to_index[unitno] = unitbase_index
end

def get_unitname(unitno)
	get_cstr(@unitbase_dat[@unitno_to_index[unitno]], 28)
end

premiumcondition.each do |b|
	unitno = read16(b, 0)
	conditions = 8.times.map {|i|
		[read16(b, 0x1c + i * 4), read16(b, 0x1c + i * 4 + 2)]
	}
	print "#{unitno} - #{get_unitname(unitno)} #{read16(b, 2)} #{get_cstr(b, 4)}: "
	puts conditions.each_with_index.map {|(no, lv), i|
		next nil if no == 0
		if i == 4
			name = command_names[no]
		else
			name = get_unitname(no)
		end
		"#{name} (#{lv})"
	}.compact.join(", ")
end
