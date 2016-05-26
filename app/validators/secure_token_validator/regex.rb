class SecureTokenValidator < ActiveModel::Validator
  # define the regex formatting for the various secure_token parameters
  module Regex
    class << self
      def uuid
        # this is the regex for testing UUID formatting
        /\A[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}\z/
      end

      def secret_key
        # regex for testing formatting of 190-bit secure keys, 254 characters
        /\A[a-zA-Z0-9_\-]{254}\z/
      end

      def encrypted_key
        # regex for testing formatting of 512-bit secure encrypted keys,
        # 1049 or 1050 characters
        /\A[a-f0-9\$]{1049,1050}\z/
      end
    end
  end
end
