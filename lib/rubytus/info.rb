require 'json'

module Rubytus
  class Info < Hash
    def initialize(args = {})
      self['Offset']       = args[:offset]        || 0
      self['UploadLength'] = args[:upload_length] || 0
      self['Meta']         = args[:meta]          || nil
    end

    def offset=(value)
      self['Offset'] = value.to_i
    end

    def offset
      self['Offset']
    end

    def upload_length=(value)
      self['UploadLength'] = value.to_i
    end

    def upload_length
      self['UploadLength']
    end

    def remaining_length
      upload_length - offset
    end
  end
end
