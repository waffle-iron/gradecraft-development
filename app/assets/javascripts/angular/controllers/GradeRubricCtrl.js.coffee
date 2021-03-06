@gradecraft.controller 'GradeRubricCtrl', ['$scope', 'Restangular', 'RubricService', '$q', ($scope, Restangular, RubricService, $q) ->

  $scope.courseBadges = RubricService.badges
  $scope.criteria = RubricService.criteria
  $scope.criterionGrades = RubricService.criterionGrades
  $scope.updateCriterion = RubricService.updateCriterion
  $scope.grade = RubricService.grade
  $scope.updateGrade = RubricService.updateGrade
  $scope.gradeStatusOptions = RubricService.gradeStatusOptions

  # Criterion factory is dependent on CriterionGrades existing in scope
  $scope.init = (assignment_id, scope_type, scoped_id)->
    $scope.assignment = {
      id: assignment_id,
      scope: {
        type: scope_type,
        id: scoped_id
      }
    }
    $scope.services()

  $scope.services = () ->
    # because getting Criteria requires badges from $scope
    # we need to wait until the badges are created before
    # making this call.
    queCriteriaAfterBadges = ()->
      if (RubricService.badgesAvailable() == false)
        window.setTimeout(queCriteriaAfterBadges, 100)
      else
        RubricService.getCriteria($scope.assignment.id, $scope)

    promises = [
      RubricService.getBadges(),
      RubricService.getCriterionGrades($scope.assignment),
      queCriteriaAfterBadges(),
      RubricService.getGrade($scope.assignment)]
    $q.all(promises)

  $scope.pointsPossible = ()->
    RubricService.pointsPossible()

  $scope.thresholdPoints = ()->
    RubricService.thresholdPoints()


  # distill key/value pairs for criterion ids and relative order
  $scope.pointsAssigned = ()->
    points = 0
    angular.forEach($scope.criteria, (criterion, index)->
      points += criterion.max_points if criterion.max_points
    )
    points or 0

  $scope.adjustmentPoints = ()->
    parseInt($scope.grade.adjustment_points) || 0

  $scope.pointsAdjusted = ()->
    $scope.adjustmentPoints() != 0

  # sum of points from selected levels
  $scope.pointsAllocated = ()->
    points = 0
    angular.forEach($scope.criteria, (criterion, index)->
      if criterion.selectedLevel
        points += criterion.selectedLevel.points
    )
    points

  $scope.finalPoints = ()->
    finalPoints = $scope.pointsAllocated() + $scope.adjustmentPoints()
    if $scope.isBelowThreshold() then 0 else finalPoints

  $scope.isBelowThreshold = ()->
    $scope.thresholdPoints() > $scope.pointsAllocated() + $scope.adjustmentPoints()

  $scope.pointsBelowThreshold = ()->
    $scope.thresholdPoints() - $scope.pointsAllocated() - $scope.adjustmentPoints()

  $scope.pointsDifference = ()->
    $scope.pointsPossible() - $scope.pointsAllocated()

  $scope.pointsRemaining = ()->
    pointsRemaining = $scope.pointsDifference()
    if pointsRemaining > 0 then pointsRemaining else 0

  # Methods for identifying point deficit/overage
  $scope.pointsMissing = ()->
    $scope.pointsDifference() > 0 and $scope.pointsAllocated() > 0

  $scope.pointsSatisfied = ()->
    $scope.pointsDifference() == 0 and $scope.pointsAllocated() > 0

  $scope.pointsOverage = ()->
    $scope.pointsDifference() < 0

  # count how many levels have been selected in the UI
  $scope.selectedLevels = ()->
    levels = []
    angular.forEach($scope.criteria, (criterion, index)->
      if criterion.selectedLevel
        levels.push criterion.selectedLevel
    )
    levels

  # count how many levels have been selected in the UI
  $scope.selectedLevelIds = ()->
    levelIds = []
    angular.forEach($scope.criteria, (criterion, index)->
      if criterion.selectedLevel
        levelIds.push criterion.selectedLevel.id
    )
    levelIds

  # ids of all the criteria in the rubric
  $scope.allCriterionIds = ()->
    criterionIds = []
    angular.forEach($scope.criteria, (criterion, index)->
      criterionIds.push criterion.id
    )
    criterionIds

  $scope.gradedCriteria = ()->
    criteria = []
    angular.forEach($scope.criteria, (criterion, index)->
      if criterion.selectedLevel
        criteria.push criterion
    )
    criteria

  $scope.selectedCriteria = ()->
    criteria = []
    angular.forEach($scope.criteria, (criterion, index)->
      if criterion.selectedLevel
        criteria.push criterion
    )
    $scope.selectedCriteria = criteria
    criteria

  # Patch: (TODO test and then remove gradedCriteriaParams)
  # For params submitted, we want to include criteria with
  # comments but no selected level
  $scope.criteriaParams = ()->
    params = []
    angular.forEach($scope.criteria, (criterion, index)->
      # get params just from the criterion object
      criterionParams = $scope.criterionOnlyParams(criterion,index)

      # add params from the level if a level has been selected
      if criterion.selectedLevel
        jQuery.extend(criterionParams, $scope.gradedLevelParams(criterion))

      # create params for the rubric grade regardless
      params.push criterionParams
    )
    params

  $scope.gradedCriteriaParams = ()->
    params = []
    angular.forEach($scope.gradedCriteria(), (criterion, index)->
      # get params just from the criterion object
      criterionParams = $scope.criterionOnlyParams(criterion,index)

      # add params from the level if a level has been selected
      if criterion.selectedLevel
        jQuery.extend(criterionParams, $scope.gradedLevelParams(criterion))

      # create params for the rubric grade regardless
      params.push criterionParams
    )
    params

  # params for just the criterion
  $scope.criterionOnlyParams = (criterion,index)->
    {
      criterion_name:        criterion.name,
      criterion_description: criterion.description,
      max_points:            criterion.max_points,
      order:                 index,
      criterion_id:          criterion.id,
      comments:              criterion.comments
    }

  # additional level params if a level is selected
  $scope.gradedLevelParams = (criterion) ->
    {
      level_name:        criterion.selectedLevel.name,
      level_description: criterion.selectedLevel.description,
      points:            criterion.selectedLevel.points,
      level_id:          criterion.selectedLevel.id
    }

  $scope.gradeParams = ()->
    {
      raw_points: $scope.pointsAllocated(),
      feedback: $scope.grade.feedback,
      status:   $scope.grade.status,
      adjustment_points: $scope.grade.adjustment_points || 0,
      adjustment_points_feedback: $scope.grade.adjustment_points_feedback
    }

  # Document any updates to this format in the specs: /spec/support/api_calls/rubric_grade_put.rb
  # student_id or group_id is now passed through the route, see RubricService.putRubricGradeSubmission
  $scope.gradedRubricParams = ()->
    {
      points_possible:  $scope.pointsPossible(),
      criterion_grades: $scope.criteriaParams(),
      level_ids:        $scope.selectedLevelIds(),
      criterion_ids:    $scope.allCriterionIds(),
      grade:            $scope.gradeParams(),
    }

  $scope.submitGrade = (returnURL)->
    if !$scope.grade.status
      return alert "You must select a grade status before you can submit this grade"
    if confirm "Are you sure you want to submit the grade for this assignment?"
      RubricService.putRubricGradeSubmission($scope.assignment, $scope.gradedRubricParams(), returnURL)

  $scope.froalaOptions = {
    inlineMode: false,
    heightMin: 120,
    toolbarButtons: [
      'bold', 'italic', 'underline', 'strikeThrough',
      'sep', 'formatBlock', 'insertOrderedList', 'insertUnorderedList',
      'insertHorizontalRule', 'insertLink'
    ]
  }

  $scope.froalaSummaryOptions = {
    inlineMode: false,
    heightMin: 200,
    toolbarButtons: [
      'fullscreen', 'bold', 'italic', 'underline', 'strikeThrough',
      'fontFamily', 'fontSize', 'color', 'sep', 'blockStyle', 'emoticons',
      'insertTable', 'sep', 'formatBlock', 'align', 'insertOrderedList',
      'outdent', 'indent', 'insertHorizontalRule', 'createLink', 'undo', 'redo',
      'clearFormatting', 'selectAll', 'html'
    ]
  }
]
