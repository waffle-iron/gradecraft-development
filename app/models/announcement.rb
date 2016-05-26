class Announcement < ActiveRecord::Base
  belongs_to :author, class_name: "User"
  belongs_to :course
  has_many :states, class_name: "AnnouncementState", dependent: :destroy

  attr_accessible :author_id, :body, :course_id, :title

  validates :author, presence: true
  validates :body, presence: true
  validates :course, presence: true
  validates :title, presence: true

  default_scope { order "created_at DESC" }

  def self.read_count_for(user, course)
    AnnouncementState
      .joins(:announcement)
      .where(announcements: { course_id: course.id })
      .where(user_id: user.id).count
  end

  def self.unread_count_for(user, course)
    Announcement.where(course_id: course.id).count - read_count_for(user, course)
  end

  def abstract(words=25)
    body.split(/\s+/)[0..words].join(" ").strip
  end

  def deliver!
    if course
      course.users.each do |user|
        AnnouncementMailer.announcement_email(self, user).deliver_now
      end
    end
  end

  def mark_as_read!(user)
    if course.user_ids.include?(user.id) &&
        !states.map(&:user_id).include?(user.id)
      states.create(user_id: user.id)
    end
  end

  def mark_as_unread!(user)
    states.destroy(states.where(user_id: user.id))
  end

  def read?(user)
    states.exists?(user_id: user.id)
  end

  def unread?(user)
    !read? user
  end

  def read_count
    states.count
  end

  def unread_count
    return 0 if course.nil?
    course.users.count - read_count
  end
end
