require 'fileutils'

# The purpose of this module is just to help us figure out whether to use s3fs,
# as we can in staging and production, or whether we can use the tmp directories
# local to the machine running this code.
#
module S3fs
  class << self
    # Make a tmp directory, optionally with the s3fs prefix in the event that
    # we're using s3fs, otherwise just make a local tmpdir
    #
    def mktmpdir
      Dir.mktmpdir nil, tmpdir_prefix
    end

    # is s3fs available? This should probably be a setting on our environmental
    # config files, something to the effect of:
    #
    # config.use_s3fs = true
    #
    def available?
      # check whether we need to use S3fs
      %w[staging production].include? rails_env
    end

    # this is the format for our s3fs tmpdirs. This could additionally be
    # be defined in an s3fs initializer.
    #
    def tmpdir_prefix
      available? ? "/s3mnt/tmp/#{rails_env}" : nil
    end

    # create a separate tmp dir for storing the final generated archive
    def ensure_tmpdir
      FileUtils.mkdir_p(tmpdir_prefix) if available?
    end

    def rails_env
      ENV["RAILS_ENV"]
    end
  end
end
