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
	# �^�C�v, �З�, ����, ����
	# �^�C�v: 5=�I�t�F���X, 6=�f�B�t�F���X, 7=�V���[�g, 8=�L�[�p�[
	# �����S�̈�: 0=G, 1=�^, 2=V
  # ������̈�: 1=��, 2=��, 3=�x

	puts "%d %s: %d,%d,%d,%d,%s" % [pos, name, read8(b, 0), read8(b, 6), read8(b, 8), read8(b, 0x14), summary]
	
	#puts name if pos > 0
end
