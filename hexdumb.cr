require "colorize"

module Color
  Ascii        = Colorize::ColorANSI::LightGreen
  Whitespace   = Colorize::ColorANSI::LightCyan
  Null         = Colorize::ColorANSI::DarkGray
  Nonprintable = Colorize::ColorANSI::Cyan
end

class Hexdumb
  def initialize(io : IO | String)
    @contents = io
    @groupsize = 8
    @groups_per_line = 2
  end

  def linesize
    @groupsize * @groups_per_line
  end

  def lines
    @contents.each_byte.each_slice(linesize)
  end

  def grouped(line, element_sep = "", group_sep = " ") : String
    line.each_slice(@groupsize).map(&.join(element_sep)).join(group_sep)
  end

  def output
    sz = linesize * 3
    lines.each_with_index do |bytes, idx|
      offset = idx * linesize
      hexbytes = bytes.map { |b| ("%02x" % b).colorize(color(b)) }
      while hexbytes.size < linesize
        hexbytes.push("  ".colorize(:default))
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

if STDIN.tty? && ARGV.empty?
  puts "Type something to see it hexdumbed (Ctrl-d to stop)"
  input = STDIN.gets_to_end
  puts
  Hexdumb.new(input).output
else
  begin
    Hexdumb.new(ARGF).output
  rescue exc : File::NotFoundError
    abort "Unable to read file '#{exc.file}': File does not exist"
  rescue exc : File::AccessDeniedError
    abort "Unable to read file '#{exc.file}': Access denied"
  end
end
