# this class can generate secure tokens for short-term use case that comes up
# across the entire system. Because the #target parent association is,
# any class that implements:
#
#   has_many :secure_tokens, as: :target
#
# Will be able to use a SecureToken to implement polymorphic
require 'scrypt'

class SecureToken < ActiveRecord::Base

  belongs_to :target, polymorphic: true

  before_validation(on: :create) do
    cache_encrypted_key
    cache_uuid
    set_expires_at
  end

  validates_with SecureTokenValidator
  validates :target, presence: true

  # double-check to make sure that the authentication process is correct here
  def unlocked_by?(secret_key)
    # In order to check the secret key against the encrypted key the encrypted
    # key check has to be on the left of the equivalency operand since == has
    # been overwritten in SCrypt::Password and will perform the authentication
    # against the secret_key which is just a plain string. Performing the check
    # in the opposite direction (with the secret_key on the left) will result in
    # a failed outcome since Ruby will recognize that the plain secret_key
    # string is not the same as the SCrypt::Password object.
    #
    # This seems like a poor way to perform the encryption authentication but
    # SCrypt is the strongest encryption available for these purposes, and the
    # scrypt library that implements this method seems to be the most robust
    # available for Ruby at the moment.
    #
    # Also please note that we only have to build a new key here which contains
    # the output from the original SCrypt::Password.create call from
    # SecureToken#cache_encrypted_key. Creating a new token will produce a
    # false outcome since it will literally be creating an entirely new hash
    # rather than just building a new SCrypt::Password object to perform the
    # authentication against the string.
    #
    # Additionally since the documentation for SCrypt is somewhat lacking
    # it's worth noting here that the #scrypt_options hash only need to be
    # passed in with SCrypt::Password.create, and not when building the new
    # SCrypt::Password object below to perform the equivalency/authentication
    # check.
    #
    SCrypt::Password.new(encrypted_key) == secret_key
  end

  def expired?
    expires_at <= Time.now
  end

  def random_secret_key
    # generates a 254-character URL-safe secret key
    @random_secret_key ||= SecureRandom.urlsafe_base64(190)
  end

  protected

  # let's expire the token in a week
  def set_expires_at
    self.expires_at = Time.now + 7.days
  end

  def cache_encrypted_key
    self.encrypted_key = SCrypt::Password
      .create(random_secret_key, scrypt_options)
  end

  def cache_uuid
    self.uuid = SecureRandom.uuid
  end

  def scrypt_options
    # let's use 512 bit security here because the only real loss is speed, and
    # since we'd prefer that this interaction take as long as it needs to in
    # order to deter brute force attacks, the maximum 512-bit hash here suits
    # our needs very well. At this resolution this is basically an uncrackable
    # password unless any of our other security measures fail.

    { key_len: 512 }
  end
end
