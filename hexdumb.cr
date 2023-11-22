require "colorize"
require "option_parser"

module Color
  Ascii        = Colorize::ColorANSI::LightGreen
  Whitespace   = Colorize::ColorANSI::LightCyan
  Null         = Colorize::ColorANSI::DarkGray
  Nonprintable = Colorize::ColorANSI::Cyan
end

class Hexdumb
  def initialize(
    @input : IO | String,
    @max_bytes : UInt32? = nil,
    @skip = 0_u32,
    @group_size = 8_u32,
    @groups_per_line = 2_u32,
    @bytefmt = "%02x"
  )
  end

  def linesize : UInt32
    @group_size * @groups_per_line
  end

  def filler
    nspaces = (@bytefmt % 255).size
    (" " * nspaces).colorize(:default)
  end

  def lines
    if n = @max_bytes
      @input.each_byte.skip(@skip).first(n).each_slice(linesize)
    else
      @input.each_byte.skip(@skip).each_slice(linesize)
    end
  end

  def grouped(line, element_sep = "", group_sep = " ") : String
    line.each_slice(@group_size).map(&.join(element_sep)).join(group_sep)
  end

  def output
    lines.each_with_index do |bytes, idx|
      offset = @skip + idx * linesize
      hexbytes = bytes.map { |b| (@bytefmt % b).colorize(color(b)) }
      while hexbytes.size < linesize
        hexbytes.push(filler)
      end
      asciibytes = bytes.map { |b| show_ascii(b.chr).colorize(color(b)) }
      grouped_hex = grouped(hexbytes, " ", "  ")
      grouped_ascii = grouped(asciibytes, "", " ")

      begin
        puts "%08x ┃  %s  │  %s" % [offset, grouped_hex, grouped_ascii]
      rescue exc : IO::Error
        # Prevent printing long and confusing stack trace when pipe is closed
        # (for example when piping output to a pager and the pager is stopped)
        abort if exc.os_error == Errno::EPIPE
        raise exc
      end
    end
  end

  def color(ch : UInt8) : Colorize::Color
    case ch
    when 0_u8          then Color::Null
    when 9, 10, 13, 32 then Color::Whitespace
    when 33..127       then Color::Ascii
    else                    Color::Nonprintable
    end
  end

  def show_ascii(ch : Char) : Char
    case ch
    when '\t'     then '–'
    when '\r'     then '␍'
    when '\n'     then '⏎'
    when ' '      then '·'
    when '!'..'~' then ch
    else               '.'
    end
  end
end

skip = 0_u32
max_bytes : UInt32? = nil
group_size = 8_u8
groups_per_line = 2_u8
bytefmt = "%02x"

OptionParser.parse do |parser|
  parser.banner = "Usage: hexdumb [filename]"

  parser.on("-n N", "--length=N", "Interpret only N bytes of input") do |n|
    max_bytes = n.to_u32 rescue abort "Invalid UInt32: #{n}"
  end

  parser.on("-s OFFSET", "--skip=OFFSET", "Skip OFFSET bytes from the beginning of the input") do |n|
    skip = n.to_u32 rescue abort "Invalid UInt32: #{n}"
  end

  parser.on("-g N", "--groups=N", "Number of groups per line (default: 2)") do |n|
    groups_per_line = n.to_u8 rescue abort "Invalid UInt8: #{n}"
  end

  parser.on("-b N", "--bytes-per-group=N", "Number of bytes per group (default: 8)") do |n|
    group_size = n.to_u8 rescue abort "Invalid UInt8: #{n}"
  end

  parser.on("-d", "--decimal", "Show bytes in base 10") do
    bytefmt = "%3d"
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
end

if STDIN.tty? && ARGV.empty?
  puts "Type something to see it hexdumbed (Ctrl-d to stop)"
  input = STDIN.gets_to_end
  puts
else
  input = ARGF
end

hexdumb = Hexdumb.new(
  input,
  skip: skip,
  max_bytes: max_bytes,
  group_size: group_size,
  groups_per_line: groups_per_line,
  bytefmt: bytefmt
)

begin
  hexdumb.output
rescue exc : File::NotFoundError
  abort "Unable to read file '#{exc.file}': File does not exist"
rescue exc : File::AccessDeniedError
  abort "Unable to read file '#{exc.file}': Access denied"
rescue exc : IO::Error
  abort "#{exc}"
end
