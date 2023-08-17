require 'simplecov'
require 'simplecov-cobertura'
SimpleCov.start 'rails'

class SimpleCov::Formatter::QualityFormatter
  def format(result)
    SimpleCov::Formatter::HTMLFormatter.new.format(result)
    File.open("coverage/covered_percent", "w") do |f|
      f.puts result.source_files.covered_percent.to_f
    end
  end
end

SimpleCov.formatters = [
  SimpleCov::Formatter::QualityFormatter,
  SimpleCov::Formatter::CoberturaFormatter]
