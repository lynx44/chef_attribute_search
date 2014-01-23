require_relative('attribute_reader')

module ChefAttributeSearch
  class AttributeResolver
    include ChefAttributeSearch::AttributeReader

    def initialize(node, attribute_parser = nil, query = nil, logger = nil)
      @@node = node
      @@parser = attribute_parser || ChefAttributeSearch::AttributeParser.new(node)
      @@query = query || ::Chef::Search::Query.new()
      @@logger = logger || Chef::Log
    end

    def resolve(attribute_value)
      if !@@parser.is_search_expression(attribute_value) && !@@parser.is_node_expression(attribute_value)
        return attribute_value
      end

      if(@@parser.is_node_expression(attribute_value))
        args = @@parser.parse_node_expression(attribute_value)
        return get_attribute_value(@@node, args)
      end

      args = @@parser.parse_search_expression(attribute_value)
      node = find_node(args)
      get_attribute_value(node, args[:attributes])
    end

    def resolve_all(*attribute_values)
      hash = Hash.new
      attribute_values.each do |a|
        hash[a] = resolve(a)
      end

      hash
    end

    def logger
      @@logger
    end

    private
    def find_node(args)
      nodes = search(args[:type], args[:query])
      raise "No nodes were found when using search query '#{args[:query]}'" if nodes.length == 0
      raise "More than 1 nodes were found when using search query '#{args[:query]}'. Nodes found: #{nodes}" if nodes.length > 1
      node = nodes[0]
      node
    end

    def search(type, query="*:*")
      @@query.search(type, query)[0]
    end

    def get_attribute_value(node, attributes)
      read_attribute(node, true, node, *attributes)
      #value = node
      #attributes.each do |attr|
      #  value = value[attr]
      #end
      #
      #value
    end
  end
end