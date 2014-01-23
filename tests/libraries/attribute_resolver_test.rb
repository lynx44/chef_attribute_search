require 'test/unit'
require 'rspec/mocks/standalone'
require_relative('../../libraries/attribute_resolver')

class TestAttributeResolver < Test::Unit::TestCase
  def setup
    RSpec::Mocks::setup(self)
    setup_resolver
  end

  def setup_resolver(node = nil)
    @@resolver = ChefAttributeSearch::AttributeResolver.new(node, setup_parser, setup_query, setup_logger)
  end

  def setup_parser
    @@parser = double()
    @@parser.stub(:is_search_expression).and_return(true)
    @@parser.stub(:is_node_expression).and_return(false)
    @@search_query = create_search_query
    stub_search_query(@@search_string, @@search_query)

    @@parser
  end

  def create_search_query(args = nil)
    args ||= Hash.new
    args[:type] ||= :node
    args[:query] ||= 'name:test'
    args[:attributes] ||= ['ipaddress']

    @@search_query = args

    @@search_string = create_search_string(@@search_query)

    @@search_query
  end

  def stub_search_query(query_string, value)
    @@parser.stub(:parse_search_expression).with(query_string).and_return(value)
  end

  def create_search_string(query)
    @@valid_search_query = "search(:#{query[:type]}, '#{query[:query]}')#{query[:attributes].map { |a| "['#{a}']"}.join()}"
  end

  def setup_query
    @@query = double()
    setup_nodes([{'ipaddress' => '192.168.1.1' }])

    @@query
  end

  def setup_nodes(nodes)
    stub_nodes(@@search_query[:type], @@search_query[:query], nodes)
  end

  def stub_nodes(type, query_string, nodes)
    @@query.stub(:search).with(type, query_string).and_return([nodes, 0, 0])
  end

  def setup_logger
    @@logger = double()
    @@logger.stub(:debug)

    @@logger
  end

  def logger
    @@logger
  end

  def test_resolve_returns_value_when_not_search_expression
    @@parser.stub(:is_search_expression).and_return(false)

    expected = '192.168.1.254'
    result = @@resolver.resolve(expected)

    assert_equal(expected, result)
  end

  def test_resolve_returns_value_when_search_returns_expected
    expected = '192.168.1.10'
    setup_nodes([{'ipaddress' => expected}])
    create_search_query({ :attributes => ['ipaddress'] })
    result = @@resolver.resolve(@@search_string)

    assert_equal(expected, result)
  end

  def test_resolve_returns_value_when_multiple_attributes_search_returns_expected
    expected = '192.168.1.10'
    setup_nodes([{'ipaddress' => { 'abc123' => expected } }])
    query = create_search_query({:attributes => ['ipaddress', 'abc123']})
    stub_search_query(@@search_string, query)
    result = @@resolver.resolve(@@search_string)

    assert_equal(expected, result)
  end

  def test_resolve_returns_value_supports_attribute_indicies
    expected = '192.168.1.10'
    setup_nodes([[{ 'ipaddress' => expected }]])
    query = create_search_query({ :attributes => [0,'ipaddress'] })
    stub_search_query(@@search_string, query)
    result = @@resolver.resolve(@@search_string)

    assert_equal(expected, result)
  end

  def test_resolve_raises_error_when_multiple_nodes_found
    setup_nodes([{'ipaddress' => '192.168.1.1' }, {'ipaddress' => '192.168.1.2' }])

    assert_raise do
      @@resolver.resolve(@@search_string)
    end
  end

  def test_resolve_raises_error_when_no_nodes_found
    setup_nodes([])

    assert_raise do
      @@resolver.resolve(@@search_string)
    end
  end

  def test_resolve_all_returns_value_when_search_returns_expected
    query1 = 'query1'
    query2 = 'query2'
    query1type = :node
    query2type = :role
    search_query1 = create_search_query({:type => query1type, :query => query1, :attributes => ['attribute1'] })
    search_query2 = create_search_query({:type => query2type, :query => query2, :attributes => ['attribute2'] })
    stub_search_query(query1, search_query1)
    stub_search_query(query2, search_query2)
    stub_nodes(query1type, query1, [{ 'attribute1' => '1' }])
    stub_nodes(query2type, query2, [{ 'attribute2' => '2' }])
    result = @@resolver.resolve_all(query1, query2)

    assert_equal(2, result.length)
    assert_equal('1', result[query1])
    assert_equal('2', result[query2])
  end

  def test_resolve_node_attribute
    expected = '1'
    setup_resolver({ 'a' => { 'b' => expected }})
    @@parser.stub(:is_node_expression).and_return(true)
    @@parser.stub(:parse_node_expression).and_return(['a','b'])
    result = @@resolver.resolve("node['a']['b']")

    assert_equal(expected, result)
  end
end