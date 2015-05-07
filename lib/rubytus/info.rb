require 'json'

module Rubytus
  class Info < Hash
    def initialize(args = {})
      self['UploadOffset'] = args[:upload_offset] || 0
      self['UploadLength'] = args[:upload_length] || 0
      self['Meta']         = args[:meta]          || nil
    end

    def upload_offset=(value)
      self['UploadOffset'] = value.to_i
    end

    def upload_offset
      self['UploadOffset']
    end

    def upload_length=(value)
      self['UploadLength'] = value.to_i
    end

    def upload_length
      self['UploadLength']
    end

    def remaining_length
      upload_length - upload_offset
    end
  end
end
