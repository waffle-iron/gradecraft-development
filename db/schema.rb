# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161031184138) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "announcement_states", force: :cascade do |t|
    t.integer  "announcement_id",                null: false
    t.integer  "user_id",                        null: false
    t.boolean  "read",            default: true
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["announcement_id"], name: "index_announcement_states_on_announcement_id", using: :btree
    t.index ["user_id"], name: "index_announcement_states_on_user_id", using: :btree
  end

  create_table "announcements", force: :cascade do |t|
    t.string   "title",      null: false
    t.text     "body",       null: false
    t.integer  "author_id",  null: false
    t.integer  "course_id",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_announcements_on_author_id", using: :btree
    t.index ["course_id"], name: "index_announcements_on_course_id", using: :btree
  end

  create_table "assignment_files", force: :cascade do |t|
    t.string   "filename"
    t.integer  "assignment_id"
    t.string   "filepath"
    t.string   "file"
    t.boolean  "file_processing", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "store_dir"
  end

  create_table "assignment_groups", force: :cascade do |t|
    t.integer "group_id"
    t.integer "assignment_id"
  end

  create_table "assignment_score_levels", force: :cascade do |t|
    t.integer  "assignment_id", null: false
    t.string   "name",          null: false
    t.integer  "points",        null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "assignment_type_weights", force: :cascade do |t|
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "student_id",         null: false
    t.integer  "assignment_type_id", null: false
    t.integer  "weight",             null: false
    t.integer  "course_id"
    t.index ["course_id"], name: "index_assignment_type_weights_on_course_id", using: :btree
    t.index ["student_id", "assignment_type_id"], name: "index_weights_on_student_and_assignment_type", using: :btree
  end

  create_table "assignment_types", force: :cascade do |t|
    t.string   "name",                               null: false
    t.integer  "max_points",         default: 0,     null: false
    t.text     "description"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.integer  "course_id",                          null: false
    t.boolean  "student_weightable", default: false, null: false
    t.integer  "position",                           null: false
    t.integer  "top_grades_counted", default: 0,     null: false
  end

  create_table "assignments", force: :cascade do |t|
    t.string   "name",                                                null: false
    t.text     "description"
    t.integer  "full_points"
    t.datetime "due_at"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.integer  "course_id",                                           null: false
    t.integer  "assignment_type_id",                                  null: false
    t.string   "grade_scope",                  default: "Individual", null: false
    t.boolean  "required",                     default: false,        null: false
    t.boolean  "accepts_submissions",          default: false,        null: false
    t.boolean  "student_logged",               default: false,        null: false
    t.boolean  "release_necessary",            default: false,        null: false
    t.datetime "open_at"
    t.boolean  "visible",                      default: true,         null: false
    t.boolean  "resubmissions_allowed",        default: false,        null: false
    t.integer  "max_submissions"
    t.datetime "accepts_submissions_until"
    t.datetime "accepts_resubmissions_until"
    t.datetime "grading_due_at"
    t.string   "media"
    t.string   "thumbnail"
    t.string   "media_credit"
    t.string   "media_caption"
    t.string   "mass_grade_type"
    t.boolean  "include_in_timeline",          default: false,        null: false
    t.boolean  "include_in_predictor",         default: true,         null: false
    t.integer  "position",                                            null: false
    t.boolean  "include_in_to_do",             default: true,         null: false
    t.boolean  "use_rubric",                   default: true,         null: false
    t.boolean  "accepts_attachments",          default: true,         null: false
    t.boolean  "accepts_text",                 default: true,         null: false
    t.boolean  "accepts_links",                default: true,         null: false
    t.boolean  "pass_fail",                    default: false,        null: false
    t.boolean  "hide_analytics",               default: false,        null: false
    t.boolean  "visible_when_locked",          default: true,         null: false
    t.boolean  "show_name_when_locked",        default: false,        null: false
    t.boolean  "show_points_when_locked",      default: false,        null: false
    t.boolean  "show_description_when_locked", default: false,        null: false
    t.integer  "threshold_points",             default: 0,            null: false
    t.text     "purpose"
    t.boolean  "show_purpose_when_locked",     default: true,         null: false
    t.integer  "min_group_size",               default: 1,            null: false
    t.integer  "max_group_size",               default: 5,            null: false
    t.index ["course_id"], name: "index_assignments_on_course_id", using: :btree
  end

  create_table "badge_files", force: :cascade do |t|
    t.string   "filename"
    t.integer  "badge_id"
    t.string   "filepath"
    t.string   "file"
    t.boolean  "file_processing", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "store_dir"
  end

  create_table "badges", force: :cascade do |t|
    t.string   "name",                                         null: false
    t.text     "description"
    t.integer  "full_points"
    t.integer  "course_id",                                    null: false
    t.string   "icon"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.boolean  "visible",                      default: true,  null: false
    t.boolean  "can_earn_multiple_times",      default: true,  null: false
    t.integer  "position",                                     null: false
    t.boolean  "visible_when_locked",          default: true,  null: false
    t.boolean  "show_name_when_locked",        default: true,  null: false
    t.boolean  "show_points_when_locked",      default: true
    t.boolean  "show_description_when_locked", default: true,  null: false
    t.boolean  "student_awardable",            default: false, null: false
  end

  create_table "challenge_files", force: :cascade do |t|
    t.string   "filename"
    t.integer  "challenge_id"
    t.string   "filepath"
    t.string   "file"
    t.boolean  "file_processing", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "store_dir"
  end

  create_table "challenge_grades", force: :cascade do |t|
    t.integer  "challenge_id", null: false
    t.integer  "score"
    t.string   "status"
    t.integer  "team_id",      null: false
    t.integer  "final_points"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.text     "feedback"
  end

  create_table "challenge_score_levels", force: :cascade do |t|
    t.integer  "challenge_id", null: false
    t.string   "name",         null: false
    t.integer  "points",       null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "challenges", force: :cascade do |t|
    t.string   "name",                                null: false
    t.text     "description"
    t.integer  "full_points"
    t.datetime "due_at"
    t.integer  "course_id",                           null: false
    t.boolean  "visible",             default: true,  null: false
    t.boolean  "accepts_submissions", default: true,  null: false
    t.boolean  "release_necessary",   default: false, null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.datetime "open_at"
    t.string   "mass_grade_type"
    t.string   "media"
    t.string   "thumbnail"
    t.string   "media_credit"
    t.string   "media_caption"
  end

  create_table "course_analytics_exports", force: :cascade do |t|
    t.integer  "course_id",                             null: false
    t.integer  "owner_id",                              null: false
    t.text     "export_filename"
    t.text     "s3_object_key"
    t.text     "s3_bucket_name"
    t.text     "performer_error_log",      default: [], null: false, array: true
    t.datetime "last_export_started_at"
    t.datetime "last_export_completed_at"
    t.string   "last_completed_step"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "course_memberships", force: :cascade do |t|
    t.integer  "course_id"
    t.integer  "user_id"
    t.integer  "score",                          default: 0,         null: false
    t.text     "character_profile"
    t.datetime "last_login_at"
    t.boolean  "auditing",                       default: false,     null: false
    t.string   "role",                           default: "student", null: false
    t.boolean  "instructor_of_record",           default: false
    t.integer  "earned_grade_scheme_element_id"
    t.index ["course_id", "user_id"], name: "index_courses_users_on_course_id_and_user_id", using: :btree
    t.index ["user_id", "course_id"], name: "index_courses_users_on_user_id_and_course_id", using: :btree
  end

  create_table "courses", force: :cascade do |t|
    t.string   "name",                                                                                           null: false
    t.string   "course_number",                                                                                  null: false
    t.string   "year"
    t.string   "semester"
    t.datetime "created_at",                                                                                     null: false
    t.datetime "updated_at",                                                                                     null: false
    t.boolean  "has_badges",                                              default: false,                        null: false
    t.boolean  "has_teams",                                               default: false,                        null: false
    t.string   "student_term",                                            default: "Student",                    null: false
    t.string   "team_term",                                               default: "Team",                       null: false
    t.text     "course_rules"
    t.boolean  "status",                                                  default: true,                         null: false
    t.datetime "weights_close_at"
    t.boolean  "has_team_roles",                                          default: false,                        null: false
    t.string   "team_leader_term",                                        default: "TA",                         null: false
    t.string   "group_term",                                              default: "Group",                      null: false
    t.boolean  "accepts_submissions",                                     default: true,                         null: false
    t.boolean  "teams_visible",                                           default: true,                         null: false
    t.string   "weight_term",                                             default: "Multiplier",                 null: false
    t.decimal  "default_weight",                  precision: 4, scale: 1, default: "1.0"
    t.string   "tagline"
    t.string   "office"
    t.string   "phone"
    t.string   "class_email"
    t.string   "twitter_handle"
    t.string   "twitter_hashtag"
    t.string   "location"
    t.string   "office_hours"
    t.text     "meeting_times"
    t.string   "badge_term",                                              default: "Badge",                      null: false
    t.string   "assignment_term",                                         default: "Assignment",                 null: false
    t.string   "challenge_term",                                          default: "Challenge",                  null: false
    t.text     "gameful_philosophy"
    t.integer  "total_weights"
    t.integer  "max_weights_per_assignment_type"
    t.boolean  "has_character_profiles",                                  default: false,                        null: false
    t.string   "lti_uid"
    t.boolean  "team_score_average",                                      default: false,                        null: false
    t.boolean  "has_team_challenges",                                     default: false,                        null: false
    t.integer  "max_assignment_types_weighted"
    t.integer  "full_points"
    t.boolean  "has_in_team_leaderboards",                                default: false,                        null: false
    t.boolean  "add_team_score_to_student",                               default: false,                        null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "pass_term",                                               default: "Pass",                       null: false
    t.string   "fail_term",                                               default: "Fail",                       null: false
    t.string   "syllabus"
    t.boolean  "has_public_badges",                                       default: true,                         null: false
    t.boolean  "hide_analytics",                                          default: false,                        null: false
    t.boolean  "has_character_names",                                     default: false,                        null: false
    t.string   "time_zone",                                               default: "Eastern Time (US & Canada)"
    t.index ["lti_uid"], name: "index_courses_on_lti_uid", using: :btree
  end

  create_table "criteria", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "max_points"
    t.integer  "rubric_id"
    t.integer  "order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "full_credit_level_id"
    t.integer  "level_count",                 default: 0
    t.integer  "meets_expectations_level_id"
    t.integer  "meets_expectations_points",   default: 0
  end

  create_table "criterion_grades", force: :cascade do |t|
    t.integer  "points"
    t.integer  "criterion_id",  null: false
    t.integer  "level_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "assignment_id", null: false
    t.integer  "student_id",    null: false
    t.text     "comments"
    t.index ["criterion_id", "student_id"], name: "index_criterion_grades_on_criterion_id_and_student_id", unique: true, using: :btree
  end

  create_table "earned_badges", force: :cascade do |t|
    t.integer  "badge_id",                        null: false
    t.integer  "submission_id"
    t.integer  "course_id",                       null: false
    t.integer  "student_id",                      null: false
    t.integer  "grade_id"
    t.integer  "points",          default: 0,     null: false
    t.text     "feedback"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "assignment_id"
    t.integer  "level_id"
    t.boolean  "student_visible", default: false, null: false
    t.integer  "awarded_by_id"
    t.index ["grade_id", "badge_id"], name: "index_earned_badges_on_grade_id_and_badge_id", unique: true, using: :btree
  end

  create_table "events", force: :cascade do |t|
    t.string   "name",          null: false
    t.text     "description"
    t.datetime "open_at"
    t.datetime "due_at"
    t.text     "media"
    t.text     "thumbnail"
    t.text     "media_credit"
    t.string   "media_caption"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "course_id",     null: false
  end

  create_table "flagged_users", force: :cascade do |t|
    t.integer  "course_id",  null: false
    t.integer  "flagger_id", null: false
    t.integer  "flagged_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_flagged_users_on_course_id", using: :btree
    t.index ["flagged_id"], name: "index_flagged_users_on_flagged_id", using: :btree
    t.index ["flagger_id"], name: "index_flagged_users_on_flagger_id", using: :btree
  end

  create_table "grade_files", force: :cascade do |t|
    t.integer  "grade_id"
    t.string   "filename"
    t.string   "filepath"
    t.string   "file"
    t.boolean  "file_processing", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "store_dir"
  end

  create_table "grade_scheme_elements", force: :cascade do |t|
    t.string   "level"
    t.integer  "lowest_points"
    t.string   "letter"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "grade_scheme_id"
    t.string   "description"
    t.integer  "highest_points"
    t.integer  "course_id"
  end

  create_table "grades", force: :cascade do |t|
    t.integer  "raw_points"
    t.integer  "assignment_id"
    t.text     "feedback"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "complete"
    t.boolean  "semis"
    t.boolean  "finals"
    t.string   "type"
    t.string   "status"
    t.boolean  "attempted"
    t.boolean  "substantial"
    t.integer  "final_points"
    t.integer  "submission_id"
    t.integer  "course_id"
    t.boolean  "shared"
    t.integer  "student_id"
    t.integer  "task_id"
    t.integer  "group_id"
    t.string   "group_type"
    t.integer  "score"
    t.integer  "assignment_type_id"
    t.integer  "full_points"
    t.text     "admin_notes"
    t.integer  "graded_by_id"
    t.integer  "team_id"
    t.integer  "predicted_score",            default: 0,     null: false
    t.boolean  "instructor_modified",        default: false
    t.string   "pass_fail_status"
    t.boolean  "is_custom_value",            default: false
    t.boolean  "feedback_read",              default: false
    t.datetime "feedback_read_at"
    t.boolean  "feedback_reviewed",          default: false
    t.datetime "feedback_reviewed_at"
    t.datetime "graded_at"
    t.integer  "adjustment_points",          default: 0,     null: false
    t.text     "adjustment_points_feedback"
    t.boolean  "excluded_from_course_score", default: false
    t.datetime "excluded_at"
    t.integer  "excluded_by_id"
    t.index ["assignment_id", "student_id"], name: "index_grades_on_assignment_id_and_student_id", unique: true, using: :btree
    t.index ["assignment_id", "task_id", "submission_id"], name: "index_grades_on_assignment_id_and_task_id_and_submission_id", unique: true, using: :btree
    t.index ["assignment_id"], name: "index_grades_on_assignment_id", using: :btree
    t.index ["assignment_type_id"], name: "index_grades_on_assignment_type_id", using: :btree
    t.index ["course_id"], name: "index_grades_on_course_id", using: :btree
    t.index ["group_id", "group_type"], name: "index_grades_on_group_id_and_group_type", using: :btree
    t.index ["score"], name: "index_grades_on_score", using: :btree
    t.index ["task_id"], name: "index_grades_on_task_id", using: :btree
  end

  create_table "group_memberships", force: :cascade do |t|
    t.integer  "group_id"
    t.integer  "student_id"
    t.string   "accepted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "course_id"
    t.string   "group_type"
    t.index ["course_id"], name: "index_group_memberships_on_course_id", using: :btree
    t.index ["group_id", "group_type"], name: "index_group_memberships_on_group_id_and_group_type", using: :btree
    t.index ["student_id"], name: "index_group_memberships_on_student_id", using: :btree
  end

  create_table "groups", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.string   "approved"
    t.text     "text_feedback"
    t.text     "text_proposal"
  end

  create_table "imported_assignments", force: :cascade do |t|
    t.integer  "assignment_id"
    t.string   "provider",             null: false
    t.string   "provider_resource_id", null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.hstore   "provider_data"
    t.datetime "last_imported_at"
    t.index ["assignment_id"], name: "index_imported_assignments_on_assignment_id", using: :btree
  end

  create_table "imported_grades", force: :cascade do |t|
    t.integer  "grade_id"
    t.string   "provider"
    t.string   "provider_resource_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["grade_id"], name: "index_imported_grades_on_grade_id", using: :btree
  end

  create_table "imported_users", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "provider_resource_id"
    t.datetime "last_imported_at"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["user_id"], name: "index_imported_users_on_user_id", using: :btree
  end

  create_table "level_badges", force: :cascade do |t|
    t.integer  "level_id"
    t.integer  "badge_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "levels", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "points"
    t.integer  "criterion_id",                       null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "full_credit",        default: false
    t.boolean  "no_credit",          default: false
    t.integer  "sort_order"
    t.boolean  "meets_expectations", default: false
  end

  create_table "linked_courses", force: :cascade do |t|
    t.integer  "course_id"
    t.string   "provider"
    t.string   "provider_resource_id"
    t.datetime "last_linked_at"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["course_id"], name: "index_linked_courses_on_course_id", using: :btree
  end

  create_table "lti_providers", force: :cascade do |t|
    t.string   "name"
    t.string   "uid"
    t.string   "consumer_key"
    t.string   "consumer_secret"
    t.string   "launch_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "predicted_earned_badges", force: :cascade do |t|
    t.integer  "badge_id"
    t.integer  "student_id"
    t.integer  "predicted_times_earned", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["badge_id", "student_id"], name: "index_predidcted_badge_on_student_badge", unique: true, using: :btree
  end

  create_table "predicted_earned_challenges", force: :cascade do |t|
    t.integer  "challenge_id"
    t.integer  "student_id"
    t.integer  "predicted_points", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["challenge_id", "student_id"], name: "index_predidcted_challenge_on_student_challenge", unique: true, using: :btree
  end

  create_table "predicted_earned_grades", force: :cascade do |t|
    t.integer  "assignment_id"
    t.integer  "student_id"
    t.integer  "predicted_points", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["assignment_id", "student_id"], name: "index_predidcted_grade_on_student_assignment", unique: true, using: :btree
  end

  create_table "proposals", force: :cascade do |t|
    t.string   "title"
    t.text     "proposal"
    t.integer  "group_id"
    t.text     "feedback"
    t.boolean  "approved"
    t.integer  "submitted_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rubrics", force: :cascade do |t|
    t.integer  "assignment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "secure_tokens", force: :cascade do |t|
    t.string   "uuid"
    t.text     "encrypted_key"
    t.integer  "user_id"
    t.integer  "course_id"
    t.integer  "target_id"
    t.string   "target_type"
    t.datetime "expires_at"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["course_id"], name: "index_secure_tokens_on_course_id", using: :btree
    t.index ["target_type", "target_id"], name: "index_secure_tokens_on_target_type_and_target_id", using: :btree
    t.index ["user_id"], name: "index_secure_tokens_on_user_id", using: :btree
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
    t.index ["updated_at"], name: "index_sessions_on_updated_at", using: :btree
  end

  create_table "student_academic_histories", force: :cascade do |t|
    t.integer "student_id"
    t.string  "major"
    t.decimal "gpa"
    t.integer "current_term_credits"
    t.integer "accumulated_credits"
    t.string  "year_in_school"
    t.string  "state_of_residence"
    t.string  "high_school"
    t.boolean "athlete"
    t.integer "act_score"
    t.integer "sat_score"
    t.integer "course_id"
  end

  create_table "submission_files", force: :cascade do |t|
    t.string   "filename",                          null: false
    t.integer  "submission_id",                     null: false
    t.string   "filepath"
    t.string   "file"
    t.boolean  "file_processing",   default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_confirmed_at"
    t.boolean  "file_missing",      default: false
    t.string   "store_dir"
    t.index ["submission_id"], name: "index_submission_files_on_submission_id", using: :btree
  end

  create_table "submissions", force: :cascade do |t|
    t.integer  "assignment_id",                      null: false
    t.integer  "student_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "link"
    t.text     "text_comment"
    t.integer  "creator_id"
    t.integer  "group_id"
    t.datetime "released_at"
    t.integer  "task_id"
    t.integer  "course_id"
    t.integer  "assignment_type_id"
    t.string   "assignment_type"
    t.datetime "submitted_at"
    t.boolean  "late",               default: false, null: false
    t.index ["assignment_id", "group_id"], name: "index_submissions_on_assignment_id_and_group_id", using: :btree
    t.index ["assignment_id", "student_id"], name: "index_submissions_on_assignment_id_and_student_id", using: :btree
    t.index ["assignment_id"], name: "index_submissions_on_assignment_id", using: :btree
    t.index ["assignment_type"], name: "index_submissions_on_assignment_type", using: :btree
    t.index ["assignment_type_id"], name: "index_submissions_on_assignment_type_id", using: :btree
    t.index ["course_id"], name: "index_submissions_on_course_id", using: :btree
  end

  create_table "submissions_exports", force: :cascade do |t|
    t.integer  "assignment_id"
    t.integer  "course_id"
    t.integer  "professor_id"
    t.integer  "group_id"
    t.integer  "student_ids",              default: [], null: false, array: true
    t.integer  "team_id"
    t.text     "export_filename"
    t.text     "s3_object_key"
    t.text     "s3_bucket_name"
    t.text     "performer_error_log",      default: [], null: false, array: true
    t.hstore   "submissions_snapshot",     default: {}, null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.datetime "last_export_started_at"
    t.datetime "last_export_completed_at"
    t.string   "last_completed_step"
  end

  create_table "team_leaderships", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "leader_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "team_memberships", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "student_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.integer  "course_id"
    t.integer  "rank"
    t.integer  "challenge_grade_score"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "teams_leaderboard",     default: false
    t.boolean  "in_team_leaderboard",   default: false
    t.string   "banner"
    t.integer  "average_score",         default: 0,     null: false
  end

  create_table "unlock_conditions", force: :cascade do |t|
    t.integer  "unlockable_id"
    t.string   "unlockable_type"
    t.integer  "condition_id"
    t.string   "condition_type"
    t.string   "condition_state"
    t.integer  "condition_value"
    t.datetime "condition_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "unlock_states", force: :cascade do |t|
    t.integer  "unlockable_id"
    t.string   "unlockable_type"
    t.integer  "student_id"
    t.boolean  "unlocked"
    t.boolean  "instructor_unlocked"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["student_id"], name: "index_unlock_states_on_student_id", using: :btree
    t.index ["unlockable_id", "unlockable_type"], name: "index_unlock_states_on_unlockable_id_and_unlockable_type", using: :btree
  end

  create_table "user_authorizations", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "access_token"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "refresh_token"
    t.datetime "expires_at"
    t.index ["user_id", "provider"], name: "index_user_authorizations_on_user_id_and_provider", unique: true, using: :btree
    t.index ["user_id"], name: "index_user_authorizations_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "username",                                                               null: false
    t.string   "email"
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "rank"
    t.string   "display_name"
    t.boolean  "private_display",                 default: false
    t.integer  "current_course_id"
    t.string   "final_grade"
    t.integer  "visit_count"
    t.integer  "predictor_views"
    t.integer  "page_views"
    t.string   "team_role"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.datetime "last_activity_at"
    t.string   "lti_uid"
    t.string   "last_login_from_ip_address"
    t.string   "kerberos_uid"
    t.string   "activation_state"
    t.string   "activation_token"
    t.datetime "activation_token_expires_at"
    t.boolean  "admin",                           default: false
    t.string   "time_zone",                       default: "Eastern Time (US & Canada)"
    t.index ["activation_token"], name: "index_users_on_activation_token", using: :btree
    t.index ["kerberos_uid"], name: "index_users_on_kerberos_uid", using: :btree
    t.index ["last_logout_at", "last_activity_at"], name: "index_users_on_last_logout_at_and_last_activity_at", using: :btree
    t.index ["remember_me_token"], name: "index_users_on_remember_me_token", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", using: :btree
  end

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key", using: :btree
    t.index ["version_id"], name: "index_version_associations_on_version_id", using: :btree
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.integer  "transaction_id"
    t.text     "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
    t.index ["transaction_id"], name: "index_versions_on_transaction_id", using: :btree
  end

  add_foreign_key "announcement_states", "announcements"
  add_foreign_key "announcement_states", "users"
  add_foreign_key "announcements", "courses"
  add_foreign_key "announcements", "users", column: "author_id"
  add_foreign_key "earned_badges", "users", column: "awarded_by_id"
  add_foreign_key "flagged_users", "courses"
  add_foreign_key "flagged_users", "users", column: "flagged_id"
  add_foreign_key "flagged_users", "users", column: "flagger_id"
  add_foreign_key "imported_assignments", "assignments"
  add_foreign_key "imported_grades", "grades"
  add_foreign_key "imported_users", "users"
  add_foreign_key "linked_courses", "courses"
  add_foreign_key "secure_tokens", "courses"
  add_foreign_key "secure_tokens", "users"
  add_foreign_key "user_authorizations", "users"
end
