#!ruby
# encoding: cp932
require_relative "utils.rb"
require_relative "inzm3-data-decode.rb"

@settings = [
	{name: "premiumcondition.dat", size: 60, type: :unit},
	{name: "premium_item.dat", size: 36, type: :item},
	{name: "premiumcondition_hurri.dat", size: 64, type: :unit},
	{name: "premium_item_hurri.dat", size: 36, type: :item},
]

def main(filename)
	init()
	setting = @settings.find{|x| x[:name] == filename }
	unit_p = setting[:type] == :unit
	conditions_start_offset = unit_p ? 28 : 4
	
	binaries = read_slice(setting[:name], setting[:size])
	
	binaries.each do |b|
		premium_no = read16(b, 0)
		next if premium_no == 0
		premium_name = get_unit_or_item_name(premium_no, setting[:type])
		conditions = 8.times.map {|i|
			[read16(b, conditions_start_offset + i * 4),
			 read16(b, conditions_start_offset + i * 4 + 2)]
		}
		print "#{premium_no} - #{premium_name} #{read16(b, 2)}"
		print " #{get_cstr(b, 4)}" if unit_p
		print ": "
		puts conditions.each_with_index.map {|(no, lv), i|
			next nil if no == 0
			if i == 4
				name = @command_names[no]
			else
				name = get_unitname(no)
			end
			"#{name} (#{lv})"
		}.compact.join(", ")
	end
end

def read_command_names(path_command_dat, path_command_str)
	command_dat = read_slice(path_command_dat, 36)
	command_str = open(path_command_str, "rb"){|f| f.read }
	command_dat.map {|b|
		get_cstr(command_str, read16(b, 24) * 32)
	}
end

def init
	@item_names = decode_file("item.dat", 44).map{|b| get_cstr(b, 0) }
	@unitbase_dat = read_slice("unitbase.dat", 104)
	@command_names = read_command_names("command.dat", "command.STR")

	# unitnoからunitbase.datインデックスへ
	@unitno_to_index = []
	@unitbase_dat.each_with_index do |b, unitbase_index|
		unitno = read_short(b, 0x4e)
		@unitno_to_index[unitno] = unitbase_index
	end
end

def get_unit_or_item_name(no, type)
	if type == :item
		@item_names[no]
	elsif type == :unit
		get_unitname(no)
	end
end

def get_unitname(unitno)
	get_cstr(@unitbase_dat[@unitno_to_index[unitno]], 28)
end

if $0 == __FILE__
	main(ARGV[0])
end
