@gradecraft.factory 'PredictorService', ['$http', ($http) ->
    termFor = {
        assignmentType: ""
        assignment: ""
        pass: ""
        fail: ""
        badges: ""
        challenges: ""
        weights: ""
    }
    gradeSchemeElements = []
    _totalPoints  = 0
    assignments = []
    assignmentTypes = []
    update = {}
    weights = {
      unusedWeights: ()->
        return 0
    }
    badges = []
    challenges = []
    icons = [
      "has_info", "is_required", "is_rubric_graded","accepting_submissions",
      "has_submission", "has_threshold", "is_late", "closed_without_submission",
      "is_locked", "has_been_unlocked", "is_a_condition", "is_earned_by_group"
    ]
    unusedWeights = null

    uri_prefix = (student_id)->
      if student_id
        '/api/students/' + student_id + '/'
      else
        'api/'

    totalPoints = ()->
      _totalPoints

    getGradeSchemeElements = ()->
      $http.get("/api/grade_scheme_elements").success((res)->
        _.each(res.data, (gse)->
          gradeSchemeElements.push(gse.attributes)
        )
        _totalPoints = res.meta.total_points
      )

    getAssignmentTypes = (student_id)->
      $http.get(uri_prefix(student_id) + "assignment_types").success((res)->
        _.each(res.data, (assignment_type)->
          assignmentTypes.push(assignment_type.attributes)
        )
        termFor.assignmentType = res.meta.term_for_assignment_type
        termFor.weights = res.meta.term_for_weights
        update.weights = res.meta.update_weights
        weights.open = !res.meta.assignment_weight_close_at ||
          Date.parse(res.meta.assignment_weight_close_at) >= Date.now()
        weights.total_assignment_weight = res.meta.total_assignment_weight
        weights.assignment_weight_close_at = res.meta.assignment_weight_close_at
        weights.max_assignment_weight = res.meta.max_assignment_weight
        weights.max_assignment_types_weighted = res.meta.max_assignment_types_weighted
        weights.default_assignment_weight = res.meta.default_assignment_weight

        weights.unusedWeights = ()->
          used = 0
          _.each(assignmentTypes,(at)->
            if at.student_weightable
              used += at.student_weight
          )
          weights.total_assignment_weight - used
        weights.unusedTypes = ()->
          types = 0
          _.each(assignmentTypes, (at)->
            if at.student_weight > 0
              types += 1
          )
          weights.max_assignment_types_weighted - types
        )

    getAssignments = (student_id)->
      $http.get(uri_prefix(student_id) + 'predicted_earned_grades').success( (res)->
        _.each(res.data, (assignment)->
          assignments.push(assignment.attributes)
        )
        termFor.assignment = res.meta.term_for_assignment
        termFor.pass = res.meta.term_for_pass
        termFor.fail = res.meta.term_for_fail
        update.assignments = res.meta.update_assignments
      )

    getBadges = (student_id)->
      $http.get(uri_prefix(student_id) + 'predicted_earned_badges').success( (res)->
        _.each(res.data, (badge)->
          badges.push(badge.attributes)
        )
        termFor.badges = res.meta.term_for_badges
        termFor.badge = res.meta.term_for_badge
        update.badges = res.meta.update_badges
      )

    getChallenges = (student_id)->
      $http.get(uri_prefix(student_id) + 'predicted_earned_challenges').success( (res)->
        _.each(res.data, (challenge)->
          challenges.push(challenge.attributes)
        )
        termFor.challenges = res.meta.term_for_challenges
        update.challenges = res.meta.update_challenges
      )

    postPredictedGrade = (student_id, value)->
      if update.assignments
        $http.put('/api/predicted_earned_grades/' + student_id, predicted_points: value).success(
            (data)->
              console.log(data);
          ).error(
            (data)->
              console.log(data);
          )

    postPredictedChallenge = (student_id, value)->
      if update.challenges
        $http.put('/api/predicted_earned_challenges/' + student_id, predicted_points: value).success(
            (data)->
              console.log(data);
          ).error(
            (data)->
              console.log(data);
          )

    postPredictedBadge = (student_id, value)->
      if update.badges
        $http.put('/api/predicted_earned_badges/' + student_id, predicted_times_earned: value).success(
            (data)->
              console.log(data);
          ).error(
            (data)->
              console.log(data);
          )

    postAssignmentTypeWeight = (assignmentType_id,value)->
      if update.weights
        $http.post('/assignment_type_weight', id: assignmentType_id, weight: value).success(
            (data)->
              console.log(data);
          ).error(
            (data)->
              console.log(data);
          )

    return {
        getGradeSchemeElements: getGradeSchemeElements
        getAssignmentTypes: getAssignmentTypes
        getAssignments: getAssignments
        getBadges: getBadges
        getChallenges: getChallenges
        postPredictedGrade: postPredictedGrade
        postPredictedBadge: postPredictedBadge
        postPredictedChallenge: postPredictedChallenge
        postAssignmentTypeWeight: postAssignmentTypeWeight
        assignments: assignments
        assignmentTypes: assignmentTypes
        weights: weights
        gradeSchemeElements: gradeSchemeElements
        totalPoints: totalPoints
        badges: badges
        challenges: challenges
        termFor: termFor
        icons: icons
    }
]
