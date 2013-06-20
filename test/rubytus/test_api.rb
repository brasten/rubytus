require 'test_helper'
require 'rubytus/api'

class TestAPI < MiniTest::Test
  include Rubytus::Mock
  include Goliath::TestHelper

  def setup
    @err = Proc.new { assert false, 'API request failed' }
  end

  def test_get_request_for_root
    with_api(Rubytus::API, default_options) do
      get_request({ :path => '/' }, @err) do |c|
        assert_equal 404, c.response_header.status
      end
    end
  end

  def test_options_request_for_collection
    with_api(Rubytus::API, default_options) do
      options_request({ :path => '/uploads/' }, @err) do |c|
        assert_equal 200, c.response_header.status
        assert_equal '', c.response
      end
    end
  end

  def test_get_request_for_collection
    with_api(Rubytus::API, default_options) do
      get_request({ :path => '/uploads/' }, @err) do |c|
        assert_equal 405, c.response_header.status
        assert_equal 'POST', c.response_header['ALLOW']
      end
    end
  end

  def test_post_request_for_collection_without_final_length
    with_api(Rubytus::API, default_options) do
      post_request({ :path => '/uploads/' }, @err) do |c|
        assert_equal 400, c.response_header.status
      end
    end
  end

  def test_post_request_for_collection_with_negative_final_length
    with_api(Rubytus::API, default_options) do
      post_request({ :path => '/uploads/', :head => { 'Final-Length' => '-1'} }, @err) do |c|
        assert_equal 400, c.response_header.status
      end
    end
  end

  def test_post_request_for_collection
    with_api(Rubytus::API, default_options) do
      post_request({ :path => '/uploads/', :head => { 'Final-Length' => '10' } }, @err) do |c|
        assert_equal 201, c.response_header.status
        assert c.response_header.location
      end
    end
  end

  def test_put_request_for_resource
    with_api(Rubytus::API, default_options) do
      put_request({ :path => "/uploads/#{uid}" }, @err) do |c|
        assert_equal 405, c.response_header.status
        assert_equal 'HEAD,PATCH', c.response_header['ALLOW']
      end
    end
  end

  def test_patch_request_for_resource_without_valid_content_type
    params = { :path => "/uploads/#{uid}", :head => { 'Offset' => '0', 'Content-Type' => 'plain/text' }, :body => 'abc'}

    with_api(Rubytus::API, default_options) do
      patch_request(params, @err) do |c|
        assert_equal 400, c.response_header.status
      end
    end
  end

  def test_patch_request_for_resource
    params = { :path => "/uploads/#{uid}", :head => { 'Offset' => '0', 'Content-Type' => 'application/offset+octet-stream' }, :body => 'abc'}

    with_api(Rubytus::API, default_options) do
      patch_request(params, @err) do |c|
        assert_equal 200, c.response_header.status
      end
    end
  end

  def test_patch_request_for_resource_failure
    options = default_options.merge({:data_dir => '/opt/rubytusd'})
    params  = { :path => "/uploads/#{uid}", :head => { 'Offset' => '0', 'Content-Type' => 'application/offset+octet-stream' }, :body => 'abc'}

    any_instance_of(Rubytus::API) do |klass|
      stub(klass).setup { true }
      stub(klass).storage { Rubytus::Storage.new(options) }
    end

    with_api(Rubytus::API, options) do
      patch_request(params, @err) do |c|
        assert_equal 500, c.response_header.status
      end
    end
  end

  def test_head_request_for_resource
    ruid = uid

    any_instance_of(Rubytus::Storage) do |klass|
      stub(klass).read_info(ruid) { { 'Offset' => 3 } }
    end

    with_api(Rubytus::API, default_options) do
      head_request({ :path => "/uploads/#{ruid}" }, @err) do |c|
        assert_equal 200, c.response_header.status
        assert_equal '3', c.response_header['OFFSET']
      end
    end
  end

  def test_get_request_for_resource
    ruid = uid

    any_instance_of(Rubytus::Storage) do |klass|
      stub(klass).read_file(ruid) { 'abc' }
    end

    with_api(Rubytus::API, default_options) do
      get_request({ :path => "/uploads/#{ruid}" }, @err) do |c|
        assert_equal 200, c.response_header.status
        assert_equal 'abc', c.response
      end
    end
  end
end