module SecureTokenHelper
  def secure_download_url(secure_token)
    # we've enforced presence of SecureToken[:target_type] so this shouldn't be
    # able to be a nil value. Let's presume that this will work rather than
    # assume that it might not.
    target_type = secure_token.target_type.demodulize.underscore

    # we're basically just going to call the appropriate url helper method for
    # the custom routes using the uuid and the secret key, but by inferring the
    # target type from from the SecureToken we can clean up the views and really
    # don't need multiple helper methods for this single purpose.
    send("secure_download_#{target_type}_url",
           id: secure_token.target_id,
           secure_token_uuid: secure_token.uuid,
           secret_key: secure_token.random_secret_key
        )
  end
end
