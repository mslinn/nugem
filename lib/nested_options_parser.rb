class NestedOptionParser
  def initialize(option_parser_proc, subcommand_parser_procs = [])
    @option_parser = OptionParser.new option_parser_proc
    @subcommand_parser_procs = subcommand_parser_procs
    yield self if block_given?
  end
end
