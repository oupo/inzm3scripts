#!ruby
require_relative "utils.rb"

def get_command_name(command, command_str)
	get_cstr(command_str, read16(command, 24) * 32)
end

def get_command_summary(command, command_str)
	get_cstr(command_str, read16(command, 26) * 32)
end

command_str = open("command.STR", "rb"){|f| f.read }
command_dat = read_slice("command.dat", 36)

command_dat.each_with_index do |b, pos|
	name = get_command_name(b, command_str)
	summary = get_command_summary(b, command_str)
	# タイプ, 威力, 属性, 成長
	# タイプ: 5=オフェンス, 6=ディフェンス, 7=シュート, 8=キーパー
	# 成長百の位: 0=G, 1=真, 2=V
  # 成長一の位: 1=普, 2=速, 3=遅

	puts "%d %s: %d,%d,%d,%d,%s" % [pos, name, read8(b, 0), read8(b, 6), read8(b, 8), read8(b, 0x14), summary]
	
	#puts name if pos > 0
end
