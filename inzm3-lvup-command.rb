#!ruby
# encoding: cp932
require_relative "utils.rb"

lvup_command = read_slice("lvup_command.dat", 41)

type_name = {
   1 => "G��",    2 => "G��",    3 => "G�x",
 101 => "�^��", 102 => "�^��", 103 => "�^�x",
 201 => "V��",  202 => "V��",  203 => "V�x"
}

lvup_command.each do |b|
	type = read8(b, 0)
	list = [[0, 0]]
	19.times do |i|
		necessary_times = read8(b, 1 + i * 2)
		power = read8(b, 1 + i * 2 + 1)
		break if necessary_times == 255
		list << [necessary_times, power]
	end
	#puts "%.3d: %s" % [type, list.each_with_index.map{|e,i| "#{i+1} => #{e.inspect}" }.join(", ")]
	puts "<th>%s<td>%s" % [type_name[type], list.map{|times,power| power}.join(", ")]
end

