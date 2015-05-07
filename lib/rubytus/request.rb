require 'rubytus/constants'
require 'rubytus/common'

module Rubytus
  class Request
    include Rubytus::Constants
    include Rubytus::Common

    def initialize(env)
      @env = env
    end

    def get?;     request_method == 'GET'; end
    def post?;    request_method == 'POST'; end
    def head?;    request_method == 'HEAD'; end
    def patch?;   request_method == 'PATCH'; end
    def options?; request_method == 'OPTIONS'; end

    def resumable_content_type?
      content_type == RESUMABLE_CONTENT_TYPE
    end

    def unknown?
      !collection? && !resource?
    end

    def collection?
      path_info.chomp('/') == base_path.chomp('/')
    end

    def resource?
      !!(resource_uid =~ RESOURCE_UID_REGEX)
    end

    def resource_uid
      rpath = path_info.dup
      rpath.slice!(base_path)
      rpath
    end

    def resource_url(uid)
      "#{scheme}://#{host_with_port}#{base_path}#{uid}"
    end

    def upload_length
      fetch_positive_header('HTTP_ENTITY_LENGTH')
    end

    def upload_offset
      fetch_positive_header('HTTP_OFFSET')
    end

    def base_path
      @env['api.options'][:base_path]
    end

    def scheme
      @env['HTTPS'] ? 'https' : 'http'
    end

    def path_info
      @env['PATH_INFO']
    end

    def host_with_port
      @env['HTTP_HOST'] || "#{@env['SERVER_NAME']}:#{@env['SERVER_PORT']}"
    end

    def request_method
      @env['REQUEST_METHOD']
    end

    def content_type
      @env['CONTENT_TYPE']
    end

    def content_length
      @env['CONTENT_LENGTH'].to_i
    end

    protected
    def fetch_positive_header(header_name)
      header_val  = @env[header_name] || ''
      value       = header_val.to_i
      header_orig = normalize_header_name(header_name)

      if header_val.empty?
        error!(STATUS_BAD_REQUEST, "#{header_orig} header must not be empty")
      end

      if (header_name == 'HTTP_ENTITY_LENGTH') && (value < 0)
        error!(STATUS_BAD_REQUEST, "Invalid Upload-Length: #{value}. It should non-negative integer or string 'streaming'")
      end

      value
    end

    def normalize_header_name(header_name)
      header_name.gsub('HTTP_', '').split('_').map(&:capitalize).join('-')
    end
  end
end
