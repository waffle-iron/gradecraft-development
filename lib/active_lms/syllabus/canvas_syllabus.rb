require "canvas"

# Internal: Provides communication between Canvas to satisfy the Syllabus
# signature methods in order to retrieve data from the Canvas LMS.
#
# This should not be used directly. This is used as a specific adapter for
# ActiveLMS::Syllabus.
module ActiveLMS
  class CanvasSyllabus
    # Internal: Initializes a CanvasSyllabus
    #
    # access_token - A String that holds the Canvas access token to connect to
    # the Canvas API.
    def initialize(access_token)
      @client = Canvas::API.new(access_token)
    end

    # Internal: Retrieves a single course from the Canvas API.
    #
    # id - A String representing the course id from the Canvas API.
    # exception_handler - A block that is called (if provided) when an error occurs
    # so the calling client can handle an exception gracefully. Currently rescues
    # `HTTParty::Error`, `Canvas::ResponseError`, and `JSON::ParserError`.
    #
    # Examples
    #
    # GET: http://instructure.com/api/v1/courses/:id
    #
    # Returns a Hash representing a single Course.
    #
    # {
    #   "id": 370663,
    #   "sis_course_id": null,
    #   "integration_id": null,
    #   "name": "InstructureCon 2012",
    #   "course_code": "INSTCON12",
    #   "workflow_state": "available",
    #   "account_id": 81259,
    #   "root_account_id": 81259,
    #   "enrollment_term_id": 34,
    #   "grading_standard_id": 25,
    #   "start_at": "2012-06-01T00:00:00-06:00",
    #   "end_at": "2012-09-01T00:00:00-06:00",
    #   "enrollments": null,
    #   "total_students": 32,
    #   "calendar": null,
    #   "default_view": "feed",
    #   "syllabus_body": "<p>syllabus html goes here</p>",
    #   "needs_grading_count": 17,
    #   "term": null,
    #   "course_progress": null,
    #   "apply_assignment_group_weights": true,
    #   "permissions": {"create_discussion_topic":true,"create_announcement":true},
    #   "is_public": true,
    #   "is_public_to_auth_users": true,
    #   "public_syllabus": true,
    #   "public_description": "Come one, come all to InstructureCon 2012!",
    #   "storage_quota_mb": 5,
    #   "storage_quota_used_mb": 5,
    #   "hide_final_grades": false,
    #   "license": "Creative Commons",
    #   "allow_student_assignment_edits": false,
    #   "allow_wiki_comments": false,
    #   "allow_student_forum_attachments": false,
    #   "open_enrollment": true,
    #   "self_enrollment": false,
    #   "restrict_enrollments_to_course_dates": false,
    #   "course_format": "online",
    #   "access_restricted_by_date": false,
    #   "time_zone": "America/Denver"
    # }
    def course(id, &exception_handler)
      handle_exceptions(exception_handler) do
        course = nil
        client.get_data("/courses/#{id}") { |data| course = data }
        course
      end
    end

    # Internal: Retrieves all the courses assigned to as a teacher from
    # the Canvas API.
    #
    # exception_handler - A block that is called (if provided) when an error occurs
    # so the calling client can handle an exception gracefully. Currently rescues
    # `HTTParty::Error`, `Canvas::ResponseError`, and `JSON::ParserError`.
    #
    # Examples
    #
    # GET: http://instructure.com/api/v1/courses?enrollment_type=teacher
    #
    # Returns an Array of Hashes representing multiple courses.
    #
    # [{
    #   "id": 370663,
    #   "sis_course_id": null,
    #   "integration_id": null,
    #   "name": "InstructureCon 2012",
    #   "course_code": "INSTCON12",
    #   "workflow_state": "available",
    #   "account_id": 81259,
    #   "root_account_id": 81259,
    #   "enrollment_term_id": 34,
    #   "grading_standard_id": 25,
    #   "start_at": "2012-06-01T00:00:00-06:00",
    #   "end_at": "2012-09-01T00:00:00-06:00",
    #   "enrollments": null,
    #   "total_students": 32,
    #   "calendar": null,
    #   "default_view": "feed",
    #   "syllabus_body": "<p>syllabus html goes here</p>",
    #   "needs_grading_count": 17,
    #   "term": null,
    #   "course_progress": null,
    #   "apply_assignment_group_weights": true,
    #   "permissions": {"create_discussion_topic":true,"create_announcement":true},
    #   "is_public": true,
    #   "is_public_to_auth_users": true,
    #   "public_syllabus": true,
    #   "public_description": "Come one, come all to InstructureCon 2012!",
    #   "storage_quota_mb": 5,
    #   "storage_quota_used_mb": 5,
    #   "hide_final_grades": false,
    #   "license": "Creative Commons",
    #   "allow_student_assignment_edits": false,
    #   "allow_wiki_comments": false,
    #   "allow_student_forum_attachments": false,
    #   "open_enrollment": true,
    #   "self_enrollment": false,
    #   "restrict_enrollments_to_course_dates": false,
    #   "course_format": "online",
    #   "access_restricted_by_date": false,
    #   "time_zone": "America/Denver"
    # }]
    def courses(&exception_handler)
      @courses || begin
        @courses = []
        handle_exceptions(exception_handler) do
          client.get_data("/courses", enrollment_type: "teacher") do |data|
            @courses += data
          end
        end
      end
      @courses
    end

    # Internal: Retrieves all the assignments for a specific course from
    # the Canvas API.
    #
    # id - A String representing the course id from the Canvas API.
    # assignment_ids - An Array of ids that can filter out the assignments
    # there were retrieved.
    # exception_handler - A block that is called (if provided) when an error occurs
    # so the calling client can handle an exception gracefully. Currently rescues
    # `HTTParty::Error`, `Canvas::ResponseError`, and `JSON::ParserError`.
    #
    # Examples
    #
    # GET: http://instructure.com/api/v1/courses/:id/assignments
    #
    # Returns an Array of Hashes representing multiple assignments.
    #
    # [{
    #   "id": 4,
    #   "name": "some assignment",
    #   "description": "<p>Do the following:</p>...",
    #   "created_at": "2012-07-01T23:59:00-06:00",
    #   "updated_at": "2012-07-01T23:59:00-06:00",
    #   "due_at": "2012-07-01T23:59:00-06:00",
    #   "lock_at": "2012-07-01T23:59:00-06:00",
    #   "unlock_at": "2012-07-01T23:59:00-06:00",
    #   "has_overrides": true,
    #   "all_dates": null,
    #   "course_id": 123,
    #   "html_url": "https://...",
    #   "submissions_download_url": ".../courses/:course_id/assignments/:id/submissions",
    #  "assignment_group_id": 2,
    #  "allowed_extensions": ["docx", "ppt"],
    #  "turnitin_enabled": true,
    #  "turnitin_settings": null,
    #  "grade_group_students_individually": false,
    #  "external_tool_tag_attributes": null,
    #  "peer_reviews": false,
    #  "automatic_peer_reviews": false,
    #  "peer_review_count": 0,
    #  "peer_reviews_assign_at": "2012-07-01T23:59:00-06:00",
    #  "group_category_id": 1,
    #  "needs_grading_count": 17,
    #  "needs_grading_count_by_section": [{
    #     "section_id":"123456",
    #     "needs_grading_count":5 }],
    #  "position": 1,
    #  "post_to_sis": true,
    #  "integration_id": "12341234",
    #  "integration_data": "12341234",
    #  "muted": null,
    #  "points_possible": 12,
    #  "submission_types": ["online_text_entry"],
    #  "grading_type": "points",
    #  "grading_standard_id": null,
    #  "published": true,
    #  "unpublishable": false,
    #  "only_visible_to_overrides": false,
    #  "locked_for_user": false,
    #  "lock_info": null,
    #  "lock_explanation": "This assignment is locked until September 1 at 12:00am",
    #  "quiz_id": 620,
    #  "anonymous_submissions": false,
    #  "discussion_topic": null,
    #  "freeze_on_copy": false,
    #  "frozen": false,
    #  "frozen_attributes": ["title"],
    #  "submission": null,
    #  "use_rubric_for_grading": true,
    #  "rubric_settings": "{"points_possible"=>12}",
    #  "rubric": null,
    #  "assignment_visibility": [137, 381, 572],
    #  "overrides": null,
    #  "omit_from_final_grade": true
    # }]
    def assignments(course_id, assignment_ids=nil, &exception_handler)
      assignments = []

      if assignment_ids.nil?
        handle_exceptions(exception_handler) do
          client.get_data("/courses/#{course_id}/assignments") do |data|
            data.select { |assignment| assignment["published"] }.each do |assignment|
              assignments << assignment
            end
          end
        end
      else
        [assignment_ids].flatten.uniq.compact.each do |assignment_id|
          assignments << self.assignment(course_id, assignment_id)
        end
      end

      assignments
    end

    # Internal: Retrieves the assignments for a specific course and assignment from
    # the Canvas API.
    #
    # course_id - A String representing the course id from the Canvas API.
    # assignment_id - A String representing the assignment id from the Canvas API.
    # exception_handler - A block that is called (if provided) when an error occurs
    # so the calling client can handle an exception gracefully. Currently rescues
    # `HTTParty::Error`, `Canvas::ResponseError`, and `JSON::ParserError`.
    #
    # Examples
    #
    # GET: http://instructure.com/api/v1/courses/:course_id/assignments/:id
    #
    # Returns a Hash representing a single assignment.
    #
    # {
    #   "id": 4,
    #   "name": "some assignment",
    #   "description": "<p>Do the following:</p>...",
    #   "created_at": "2012-07-01T23:59:00-06:00",
    #   "updated_at": "2012-07-01T23:59:00-06:00",
    #   "due_at": "2012-07-01T23:59:00-06:00",
    #   "lock_at": "2012-07-01T23:59:00-06:00",
    #   "unlock_at": "2012-07-01T23:59:00-06:00",
    #   "has_overrides": true,
    #   "all_dates": null,
    #   "course_id": 123,
    #   "html_url": "https://...",
    #   "submissions_download_url": ".../courses/:course_id/assignments/:id/submissions",
    #  "assignment_group_id": 2,
    #  "allowed_extensions": ["docx", "ppt"],
    #  "turnitin_enabled": true,
    #  "turnitin_settings": null,
    #  "grade_group_students_individually": false,
    #  "external_tool_tag_attributes": null,
    #  "peer_reviews": false,
    #  "automatic_peer_reviews": false,
    #  "peer_review_count": 0,
    #  "peer_reviews_assign_at": "2012-07-01T23:59:00-06:00",
    #  "group_category_id": 1,
    #  "needs_grading_count": 17,
    #  "needs_grading_count_by_section": [{
    #     "section_id":"123456",
    #     "needs_grading_count":5 }],
    #  "position": 1,
    #  "post_to_sis": true,
    #  "integration_id": "12341234",
    #  "integration_data": "12341234",
    #  "muted": null,
    #  "points_possible": 12,
    #  "submission_types": ["online_text_entry"],
    #  "grading_type": "points",
    #  "grading_standard_id": null,
    #  "published": true,
    #  "unpublishable": false,
    #  "only_visible_to_overrides": false,
    #  "locked_for_user": false,
    #  "lock_info": null,
    #  "lock_explanation": "This assignment is locked until September 1 at 12:00am",
    #  "quiz_id": 620,
    #  "anonymous_submissions": false,
    #  "discussion_topic": null,
    #  "freeze_on_copy": false,
    #  "frozen": false,
    #  "frozen_attributes": ["title"],
    #  "submission": null,
    #  "use_rubric_for_grading": true,
    #  "rubric_settings": "{"points_possible"=>12}",
    #  "rubric": null,
    #  "assignment_visibility": [137, 381, 572],
    #  "overrides": null,
    #  "omit_from_final_grade": true
    # }
    def assignment(course_id, assignment_id, &exception_handler)
      handle_exceptions(exception_handler) do
        assignment = nil
        client.get_data("/courses/#{course_id}/assignments/#{assignment_id}") do |data|
          assignment = data
        end
        assignment
      end
    end

    # Internal: Retrieves all the grades for a specific course and assignments from
    # the Canvas API.
    #
    # course_id - A String representing the course id from the Canvas API.
    # assignment_ids - An Array of ids that can filter out the assignments
    # there were retrieved.
    # grade_ids - An array of ids that can filter out the grades that were retrieved.
    # exception_handler - A block that is called (if provided) when an error occurs
    # so the calling client can handle an exception gracefully. Currently rescues
    # `HTTParty::Error`, `Canvas::ResponseError`, and `JSON::ParserError`.
    #
    # Examples
    #
    # GET: http://instructure.com/api/v1/courses/:id/students/submission
    #
    # Returns an Array of Hashes representing multiple grades.
    #
    # [{
    #   "assignment_id": 23,
    #   "assignment": "Assignment",
    #   "course": "Course",
    #   "attempt": 1,
    #   "body": "There are three factors too...",
    #   "grade": "A-",
    #   "grade_matches_current_submission": true,
    #   "html_url": "http://example.com/courses/255/assignments/543/submissions/134",
    #   "preview_url": ".../courses/255/assignments/543/submissions/134?preview=1",
    #   "score": 13.5,
    #   "submission_comments": null,
    #   "submission_type": "online_text_entry",
    #   "submitted_at": "2012-01-01T01:00:00Z",
    #   "url": null,
    #   "user_id": 134,
    #   "grader_id": 86,
    #   "user": "User",
    #   "late": false,
    #   "assignment_visible": true,
    #   "excused": true
    # }]
    def grades(course_id, assignment_ids, grade_ids=nil, &exception_handler)
      handle_exceptions(exception_handler) do
        grades = []
        params = { assignment_ids: assignment_ids,
                   student_ids: "all",
                   include: ["assignment", "course", "user"] }
        client.get_data("/courses/#{course_id}/students/submissions", params) do |data|
          if grade_ids.nil?
            grades += data
          else
            filtered_ids = [grade_ids].flatten.uniq.compact.map(&:to_s)
            data.select { |grade| filtered_ids.include?(grade["id"].to_s) }.each do |grade|
              grades << grade
            end
          end
        end
        grades
      end
    end

    # Internal: Updates an assignment on Canvas with the specified params on
    # the Canvas API.
    #
    # course_id - A String representing the course id from the Canvas API.
    # assignment_id - A String representing the assignment id from the Canvas API.
    # params - A hash representing the changes for the assignment on the Canvas API.
    # exception_handler - A block that is called (if provided) when an error occurs
    # so the calling client can handle an exception gracefully. Currently rescues
    # `HTTParty::Error`, `Canvas::ResponseError`, and `JSON::ParserError`.
    #
    # Examples
    #
    # PUT: http://instructure.com/api/v1/courses/:id/students/submission
    #
    # Returns a Hash representing an updated assignment.
    #
    # {
    #   "id": 4,
    #   "name": "some assignment",
    #   "description": "<p>Do the following:</p>...",
    #   "created_at": "2012-07-01T23:59:00-06:00",
    #   "updated_at": "2012-07-01T23:59:00-06:00",
    #   "due_at": "2012-07-01T23:59:00-06:00",
    #   "lock_at": "2012-07-01T23:59:00-06:00",
    #   "unlock_at": "2012-07-01T23:59:00-06:00",
    #   "has_overrides": true,
    #   "all_dates": null,
    #   "course_id": 123,
    #   "html_url": "https://...",
    #   "submissions_download_url": ".../courses/:course_id/assignments/:id/submissions",
    #  "assignment_group_id": 2,
    #  "allowed_extensions": ["docx", "ppt"],
    #  "turnitin_enabled": true,
    #  "turnitin_settings": null,
    #  "grade_group_students_individually": false,
    #  "external_tool_tag_attributes": null,
    #  "peer_reviews": false,
    #  "automatic_peer_reviews": false,
    #  "peer_review_count": 0,
    #  "peer_reviews_assign_at": "2012-07-01T23:59:00-06:00",
    #  "group_category_id": 1,
    #  "needs_grading_count": 17,
    #  "needs_grading_count_by_section": [{
    #     "section_id":"123456",
    #     "needs_grading_count":5 }],
    #  "position": 1,
    #  "post_to_sis": true,
    #  "integration_id": "12341234",
    #  "integration_data": "12341234",
    #  "muted": null,
    #  "points_possible": 12,
    #  "submission_types": ["online_text_entry"],
    #  "grading_type": "points",
    #  "grading_standard_id": null,
    #  "published": true,
    #  "unpublishable": false,
    #  "only_visible_to_overrides": false,
    #  "locked_for_user": false,
    #  "lock_info": null,
    #  "lock_explanation": "This assignment is locked until September 1 at 12:00am",
    #  "quiz_id": 620,
    #  "anonymous_submissions": false,
    #  "discussion_topic": null,
    #  "freeze_on_copy": false,
    #  "frozen": false,
    #  "frozen_attributes": ["title"],
    #  "submission": null,
    #  "use_rubric_for_grading": true,
    #  "rubric_settings": "{"points_possible"=>12}",
    #  "rubric": null,
    #  "assignment_visibility": [137, 381, 572],
    #  "overrides": null,
    #  "omit_from_final_grade": true
    # }
    def update_assignment(course_id, assignment_id, params, &exception_handler)
      assignment = nil
      handle_exceptions(exception_handler) do
        client.set_data(
          "/courses/#{course_id}/assignments/#{assignment_id}", :put, params) do |data|
            assignment = data
        end
      end
      assignment
    end

    # Internal: Retrieves single user from the Canvas API.
    #
    # id - A String representing the user id from the Canvas API.
    #
    # Examples
    #
    # GET: http://instructure.com/api/v1/users/:id/profile
    #
    # Returns a Hashe representing a single user.
    #
    # {
    #   "id": 2,
    #  "name": "Sheldon Cooper",
    #  "sortable_name": "Cooper, Sheldon",
    #  "short_name": "Shelly",
    #  "sis_user_id": "SHEL93921",
    #  "sis_import_id": 18,
    #  "sis_login_id": null,
    #  "integration_id": "ABC59802",
    #  "login_id": "sheldon@caltech.example.com",
    #  "avatar_url": ".../gravatar.com/avatar/d8cb8c8cd40ddf0cd05241443a591868?s=80&r=g",
    #  "enrollments": null,
    #  "email": "sheldon@caltech.example.com",
    #  "locale": "tlh",
    #  "time_zone": "America/Denver",
    #  "bio": "I like the Muppets."
    # }
    def user(id)
      user = nil
      client.get_data("/users/#{id}/profile") { |data| user = data }
      user
    end

    private

    attr_reader :client

    def handle_exceptions(exception_handler, &blk)
      blk.call
    rescue Canvas::ResponseError, HTTParty::Error, JSON::ParserError => e
      if !exception_handler.nil?
        exception_handler.call(e)
      else
        raise e
      end
    end
  end
end
