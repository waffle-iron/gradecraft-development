class SecureTokenAuthenticator

  def initialize(secure_token_uuid:, target_class:, target_id:, secret_key:,
                 slowdown_duration: 1)

    # set attribute values for each keyword in the :initialize definition
    method(__method__).parameters.each do |param_type, keyword|
      send "#{keyword}=", binding.local_variable_get(keyword)
    end
  end

  attr_accessor :secure_token_uuid, :target_class, :target_id, :secret_key,
    :slowdown_duration

  # we should probably add a separate workflow here for just telling the user
  # if the secure token expired so they know that this is happening instead of
  #
  def authenticates?
    uuid_format_valid? &&
    secure_key_format_valid? &&
    secure_token &&
    !secure_token.expired? &&
    secure_token.unlocked_by?(secret_key)
  end

  def valid_token_expired?
    return false unless secure_token
    secure_token.expired?
  end

  def secure_token
    @secure_token ||= SecureToken
      .find_by(
        uuid: secure_token_uuid,
        target_type: target_class,
        target_id: target_id
      )
  end

  def uuid_format_valid?
    if secure_token_uuid.match SecureTokenValidator::Regex.uuid
      true
    else
      # This should only occur if somebody is attempting to crack a key by
      # searching for random uuid values. By sleeping for a moment here we
      # drastically hinder attacks by slowing down the rate at which they can
      # be made but we do so without sacrificing system resources.
      sleep slowdown_duration
      false
    end
  end

  def secure_key_format_valid?
    if secret_key.match SecureTokenValidator::Regex.secret_key
      true
    else
      # This should only occur if somebody is attempting to crack a key by
      # searching for random uuid values. By sleeping for a moment here we
      # drastically hinder attacks by slowing down the rate at which they can
      # be made but we do so without sacrificing system resources.
      sleep slowdown_duration
      false
    end
  end
end
