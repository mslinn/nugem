class NestedOptionParser
  def initialize(option_parser, subcommand_parser = nil)
    @option_parser = option_parser
    @subcommand_parser = subcommand_parser
  end
end
