module Classroom
  class User < ActiveRecord::Base
    authenticates_with_sorcery!

    # TODO: Move this to Regex::Email
    email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

    attr_accessor :password

    validates :email, presence: true,
                      format: { with: email_regex },
                      uniqueness: { case_sensitive: false }
  end
end
