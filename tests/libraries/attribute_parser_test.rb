require 'test/unit'
require 'rspec/mocks/standalone'
require 'ostruct'
require_relative('../../libraries/attribute_parser')

class TestAttributeParser < Test::Unit::TestCase
  def setup
    @@parser = ChefAttributeSearch::AttributeParser.new(setup_nodes)
    @@type = :node
    @@query = 'name:test AND chef_environment:test'
    @@attributes = ['ipaddress']
    create_search_query
  end

  def setup_nodes
    @@node = OpenStruct.new
    @@node.chef_environment = '_default'
    @@node
  end

  def create_search_query
    @@valid_search_query = "search(:#{@@type}, '#{@@query}')#{@@attributes.map { |a| "[#{a.is_a?(String) ? "'#{a}'" : a }]"}.join()}"
  end

  def test_is_search_expression_when_ip_address_returns_false
    result = @@parser.is_search_expression('192.168.1.1')

    assert_false(result)
  end

  def test_is_search_expression_when_search_expression_returns_true
    result = @@parser.is_search_expression(@@valid_search_query)

    assert_true(result)
  end

  def test_parse_search_expression_sets_expected_type
    result = @@parser.parse_search_expression(@@valid_search_query)

    assert_equal(@@type, result[:type])
  end

  def test_parse_search_expression_resolves_databag_types
    @@type = :stuff
    create_search_query
    result = @@parser.parse_search_expression(@@valid_search_query)

    assert_equal(@@type, result[:type])
  end

  def test_parse_search_expression_sets_expected_query
    result = @@parser.parse_search_expression(@@valid_search_query)

    assert_equal(@@query, result[:query])
  end

  def test_parse_search_expression_sets_expected_attribute
    result = @@parser.parse_search_expression(@@valid_search_query)

    assert_equal(@@attributes, result[:attributes])
  end

  def test_parse_search_expression_sets_expected_attributes
    @@attributes = ['attribute1', 'attribute2']
    create_search_query
    result = @@parser.parse_search_expression(@@valid_search_query)

    assert_equal(2, result[:attributes].length)
    assert_equal(@@attributes[0], result[:attributes][0])
    assert_equal(@@attributes[1], result[:attributes][1])
  end

  def test_parse_search_expression_sets_parses_integer_attributes
    @@attributes = [0]
    create_search_query
    result = @@parser.parse_search_expression(@@valid_search_query)

    assert_equal([0], result[:attributes])
  end

  def test_parse_search_expression_replaces_node_chef_environment_with_current_environment
    @@node.chef_environment = 'test'
    expected = "chef_environment:#{@@node.chef_environment}"
    @@query = 'chef_environment:node.chef_environment'
    create_search_query
    result = @@parser.parse_search_expression(@@valid_search_query)

    assert_equal(expected, result[:query])
  end

  def test_is_node_expression_when_ip_address_returns_false
    result = @@parser.is_node_expression('192.168.1.1')

    assert_false(result)
  end

  def test_is_node_expression_when_node_express_returns_true
    result = @@parser.is_node_expression("node['a']['b']")

    assert_true(result)
  end

  def test_parse_node_expression_sets_expected_attributes
    result = @@parser.parse_node_expression("node['a']['b']")

    assert_equal(['a','b'], result)
  end
end