module ChefAttributeSearch
  class AttributeParser
    def initialize(node)
      @@node = node
    end

    @@search_regex = /^search\(:(?<type>[\w]+), (\'|\")(?<query>[\w\W]+)(\'|\")\)(?<attributes>(\[['"]?(?<attribute>[\w]+)['"]?\])+)$/
    @@node_regex = /^node(?<attributes>(\[['"]?([\w]+)['"]?\])+)$/

    def is_search_expression(entry)
      (entry =~ @@search_regex) != nil
    end

    def parse_search_expression(entry)
      match = @@search_regex.match(entry)

      { :type => match['type'].to_sym,
        :query => parse_query_tokens(match['query']),
        :attributes => parse_attributes(match['attributes'])}
    end

    def is_node_expression(entry)
       (entry =~ @@node_regex) != nil
    end

    def parse_node_expression(entry)
      parse_attributes(@@node_regex.match(entry)['attributes'])
    end

    private
    def parse_query_tokens(query)
      query.gsub!('node.chef_environment', @@node.chef_environment) if query.include? 'node.chef_environment'
      query
    end

    def parse_attributes(attributes)
      array = attributes.scan(/\[(['"]?[\w^]+['"]?)\]/).flatten
      array.map { |a| (a =~ /['"][\w^]+['"]/) ? /['"](?<attribute>[\w^]+)['"]/.match(a)['attribute'] : a.to_i }
    end
  end
end