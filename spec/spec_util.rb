module SpecUtil
  class << self
    # modified from
  # https://github.com/sonota88/anbt-sql-formatter/blob/main/bin/anbt-sql-formatter
    def format_sql(sql)
      rule = AnbtSql::Rule.new
      rule.keyword = AnbtSql::Rule::KEYWORD_LOWER_CASE
      rule.indent_string = '  '
      formatter = AnbtSql::Formatter.new(rule)
      formatter.format(sql)
    end
  end
end
