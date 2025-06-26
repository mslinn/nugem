class NestedOptionParser
  def initialize(option_parser_pro, subcommand_parser_proc = nil)
    @option_parser = option_parser
    @subcommand_parser = subcommand_parser
  end
end
