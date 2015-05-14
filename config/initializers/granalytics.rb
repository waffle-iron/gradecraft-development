
Granalytics.configure do |config|

  config.event_aggregates = {
    predictor: [
      Aggregates::AssignmentEvent,
      Aggregates::AssignmentPrediction,
      Aggregates::AssignmentUserEvent,
      Aggregates::CourseEvent,
      Aggregates::CourseRoleEvent,
      Aggregates::CoursePrediction,
      Aggregates::CourseUserEvent
    ],
    pageview: [
      Aggregates::CoursePageview,
      Aggregates::CourseUserPageview,
      Aggregates::CourseUserPagePageview,
      Aggregates::CoursePageviewByTime,
      Aggregates::CoursePagePageview,
      Aggregates::CourseRolePageview,
      Aggregates::CourseRolePagePageview
    ],
    login: [
      Aggregates::CourseLogin,
      Aggregates::CourseRoleLogin,
      Aggregates::CourseUserLogin
    ]
  }

  config.exports = {
    course: [
      Exports::CourseEventExport,
      Exports::CoursePredictorExport,
      Exports::CourseUserAggregateExport
    ]
  }
end
