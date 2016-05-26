@gradecraft.controller 'PredictorCtrl', ['$scope', '$http', '$q', '$filter', 'PredictorService', ($scope, $http, $q, $filter, PredictorService) ->

  $scope.assignmentMode = true
  $scope.loading = true

  $scope.init = (student_id)->
    $scope.student_id = student_id
    $scope.services().then(()->
      $scope.renderGradeLevelGraphics()
      $scope.loading = false
    )

  $scope.services = ()->
    promises = [PredictorService.getGradeSchemeElements(),
                PredictorService.getAssignments($scope.student_id),
                PredictorService.getAssignmentTypes($scope.student_id),
                PredictorService.getBadges($scope.student_id),
                PredictorService.getChallenges($scope.student_id)]
    return $q.all(promises)

  $scope.assignments = PredictorService.assignments
  $scope.assignmentTypes = PredictorService.assignmentTypes
  $scope.gradeSchemeElements = PredictorService.gradeSchemeElements
  $scope.badges = PredictorService.badges
  $scope.weights = PredictorService.weights
  $scope.challenges = PredictorService.challenges
  $scope.icons = PredictorService.icons
  $scope.termFor = PredictorService.termFor

  # watch for scroll events and keep track of page scroll offset
  $scope.yOffset = 0
  angular.element(window).on('scroll',()->
    $scope.yOffset = window.pageYOffset
    $scope.$apply()
  )
  $scope.offset = (val)->
    $scope.yOffset > val

  $scope.assignmentTypeAtMax = (assignmentType)->
    if $scope.assignmentTypePointExcess(assignmentType) > 0
      return true
    else
      return false

  $scope.articleGraded = (assignment)->
    if assignment.grade.score == null
      return false
    else
      return true

  $scope.challengeGraded = (challenge)->
    if challenge.grade.score == null
      return false
    else
      return true

  $scope.predictionBelowThreshold = (article)->
    article.has_threshold && article.prediction.predicted_points < article.threshold_points

  $scope.articleNoPoints = (assignment)->
    if assignment.pass_fail && assignment.grade.pass_fail_status != "Pass"
      return true
    else if assignment.grade.score == null || assignment.grade.score == 0 || assignment.grade.is_excluded
      return true
    else if $scope.predictionBelowThreshold(assignment)
      return true
    else
      return false

  # Assignments with Score Levels: returns true
  $scope.hasLevels = (assignment)->
    assignment.score_levels != undefined && assignment.score_levels.length > 0

  # Assignments with Score Levels: Returns the Level Name if predicted score in range
  $scope.levelNameForAssignmentScore = (assignment)->
    if $scope.hasLevels(assignment)
      closest = $scope.closestScoreLevel(assignment.score_levels,assignment.prediction.predicted_points)
      if $scope.inSnapRange(assignment,closest,assignment.prediction.predicted_points)
        return closest.name
    return ""

  # Assignments with Score Levels: Returns the Level Name if predicted score in range
  $scope.levelNameForChallengeScore = (challenge)->
    if $scope.hasLevels(challenge)
      closest = $scope.closestScoreLevel(challenge.score_levels,challenge.prediction.predicted_points)
      if $scope.inSnapRange(challenge,closest,challenge.prediction.predicted_points)
        return closest.name
    return ""

  # Assignments with Score Levels: Defines a snap tolerance and returns true if value is within range
  $scope.inSnapRange = (assignment,scoreLevel,value)->
    tolerance = assignment.point_total * 0.05
    if Math.abs(scoreLevel.value - value) <= tolerance
      return true
    else
      return false

  # Assignments with Score Levels: returns closest score level
  $scope.closestScoreLevel = (scoreLevels,value)->
    closest = null
    _.each(scoreLevels, (lvl,i)->
      if (closest == null || Math.abs(lvl.value - value) < Math.abs(scoreLevels[closest].value - value))
        closest = i
    )
    return scoreLevels[closest]

  # Used to avoid rendering an assignment type if it contains no assignments
  $scope.hasAssignments = (assignmentType)->
    $scope.assignmentsForAssignmentType($scope.assignments,assignmentType.id).length > 0

  # Filter the assignments, return just the assignments for the assignment type
  $scope.assignmentsForAssignmentType = (assignments,id)->
    _.where(assignments, {assignment_type_id: id})

  # Total points earned and predicted for a collection of assignments
  # If second argument passed is false, only points actually earned without weights are returned
  $scope.assignmentsPointTotal = (assignments, includePredicted=true)->
    total = 0
    _.each(assignments, (assignment)->
      # use raw score to keep weighting calculation on assignment type level
      if assignment.grade.final_points != null
        if ! assignment.grade.is_excluded
          total += assignment.grade.final_points
      else if ! assignment.pass_fail && ! assignment.closed_without_sumbission && includePredicted
        total += assignment.prediction.predicted_points
    )
    total

  # multiply points by the student's assignment type weight
  # passes points through for unweighted assignment types
  $scope.weightedPoints = (points,assignmentType)->
    if assignmentType.student_weightable
      if assignmentType.student_weight > 0
        points = points * assignmentType.student_weight
      else
        points = points * $scope.weights.default_assignment_weight
    points

  # FIX THIS ONE
  $scope.assignmentTypeMaxPossiblePoints = (assignmentType)->
    total = $scope.weightedPoints(assignmentType.total_points,assignmentType)
    if assignmentType.is_capped
      total = if total > assignmentType.total_points then assignmentType.total_points else total
    total

  # Total points predicted for all assignments by assignments type
  # caps the total points at the assignment type max points
  # only calculates the weighted total if weighted is passed in as true
  # only calcuates earned points if includePredicted is passed in as false
  $scope.assignmentTypePointTotal = (assignmentType, includeWeights=true, includeCaps=true, includePredicted=true)->
    assignments = $scope.assignmentsForAssignmentType($scope.assignments,assignmentType.id)
    if includePredicted
      total = $scope.assignmentsPointTotal(assignments)
    else
      total = $scope.assignmentsPointTotal(assignments, false)

    if includeWeights
      total = $scope.weightedPoints(total,assignmentType)
    if assignmentType.is_capped and includeCaps
      total = if total > assignmentType.total_points then assignmentType.total_points else total
    total

  # Total predicted points above and beyond the assignment type max points
  $scope.assignmentTypePointExcess = (assignmentType)->
    if assignmentType.is_capped
      $scope.assignmentTypePointTotal(assignmentType,true,false) - assignmentType.total_points
    else
      0

  # Total points predicted for badges (works with no badges)
  $scope.badgesPointTotal = ()->
    total = 0
    _.each($scope.badges,(badge)->
        total += badge.prediction.predicted_times_earned * badge.point_total
      )
    total

  $scope.badgePointsDisplay = (badge)->
   return "earned" if badge.total_earned_points == 0
   badge.total_earned_points

  # Total points possible to earn from challenges
  $scope.maxChallengePoints = ()->
    total = 0
    _.each($scope.challenges, (challenge)->
      total += challenge.point_total
      )
    total

  # Total points predicted for challenges
  $scope.challengesPointTotal = ()->
    total = 0
    _.each($scope.challenges, (challenge)->
        if challenge.grade.score > 0
          total += challenge.grade.score
        else
          total += challenge.prediction.predicted_points
      )
    total

  # Total points predicted for all assignments, badges, and challenges
  $scope.allPointsPredicted = ()->
    total = 0
    _.each($scope.assignmentTypes, (assignmentType)->
        total += $scope.assignmentTypePointTotal(assignmentType)
      )
    total += $scope.badgesPointTotal()
    total += $scope.challengesPointTotal()
    total

  # Total points actually earned to date
  $scope.allPointsEarned = ()->
    total = 0
    _.each($scope.assignmentTypes, (assignmentType)->
        total += $scope.assignmentTypePointTotal(assignmentType,true,true,false)
      )
    _.each($scope.badges,(badge)->
        total += badge.total_earned_points
      )
    _.each($scope.challenges,(challenge)->
        total += challenge.grade.score
      )
    total

  $scope.predictedGradeLevel = ()->
    allPointsPredicted = $scope.allPointsPredicted()
    predictedGrade = null
    _.each($scope.gradeSchemeElements,(gse)->
      if allPointsPredicted > gse.low_range
        if ! predictedGrade || predictedGrade.low_range < gse.low_range
          predictedGrade = gse
    )
    if predictedGrade
      return predictedGrade.level + " (" + predictedGrade.letter + ")"
    else
      return ""

  $scope.badgeCompleted = (badge)->
    ! badge.can_earn_multiple_times && badge.earned_badge_count > 0

  # We keep the predictor open on closed assignments IF the student has a
  # a submission
  $scope.closed_for_prediction = (assignment)->
    if assignment.has_closed && !assignment.has_submission
      return true
    else
      return false

  # TODO: Still show due date if submissions are still accepted
  $scope.dueInFuture = (assignment)->
    if assignment.due_at != null && Date.parse(assignment.due_at) >= Date.now()
      return true
    else
      return false

# UI ELEMENTS

  $scope.slider = (article)->
    {
      range: "min"

      #start: (event, ui)->

      slide: (event, ui)->
        slider = ui.handle.parentElement
        articleType = ui.handle.parentElement.dataset.articleType
        if $scope.hasLevels(article)
          closest = $scope.closestScoreLevel(article.score_levels,ui.value)
          if $scope.inSnapRange(article,closest,ui.value)
            event.preventDefault()
            event.stopPropagation()
            angular.element(ui.handle.parentElement).slider("value", closest.value)

            if articleType == 'assignment'
              angular.element("#assignment-" + article.id + "-level .value").text($filter('number')(closest.value) + " / " + $filter('number')(article.point_total))
            else
              angular.element("#challenge-" + article.id + "-level .value").text($filter('number')(closest.value) + " / " + $filter('number')(article.point_total))
          else

            if articleType == 'assignment'
              angular.element("#assignment-" + article.id + "-level .value").text($filter('number')(ui.value) + " / " + $filter('number')(article.point_total))
            else
              angular.element("#challenge-" + article.id + "-level .value").text($filter('number')(ui.value) + " / " + $filter('number')(article.point_total))

      stop: (event, ui)->
        articleType = ui.handle.parentElement.dataset.articleType
        value = ui.value

        if articleType == 'assignment' and $scope.predictionBelowThreshold(article)
          article.prediction.predicted_points = 0
          PredictorService.postPredictedGrade(article.prediction.id, 0)
        else if articleType == 'assignment'
          article.prediction.predicted_points = value
          PredictorService.postPredictedGrade(article.prediction.id, value)
        else
          article.prediction.predicted_points = value
          PredictorService.postPredictedChallenge(article.prediction.id,value)
    }

# WEIGHTS

  $scope.unusedWeightsRange = ()->
    _.range($scope.weights.unusedWeights())

  $scope.weightsAvailable = ()->
    $scope.weights.unusedWeights() && $scope.weights.open

# GRAPHICS RENDERING

  $scope.GraphicsStats = ()->
    # add 10% to the graph above the highest grade
    totalPoints = PredictorService.totalPoints() * 1.1
    width = parseInt(d3.select("#predictor-graphic").style("width")) - 20
    height = parseInt(d3.select("#predictor-graphic").style("height"))
    stats = {
      width: width
      height: height
      padding: 10
      # Maximum possible points for the course
      totalPoints: totalPoints
      #scale for placing elements along the x axis
      scale: d3.scale.linear().domain([0,totalPoints]).range([0,width])
    }

  $scope.gradeLevelPosition = (scale,lowRange,width,padding)->
    alignWithTickMark = 8
    position = scale(lowRange)
    textWidth = angular.element(".grade_scheme-label-" + lowRange)[0].getBBox().width
    if position < padding
      return alignWithTickMark
    else if position + textWidth > width
      return width - textWidth
    else
      return position + alignWithTickMark

  # Loads the grade points values and corresponding grade levels name/letter-grade into the predictor graphic
  $scope.renderGradeLevelGraphics = ()->
    gradeSchemeElements = $scope.gradeSchemeElements
    svg = d3.select("#svg-grade-levels")
    stats = $scope.GraphicsStats()
    padding = stats.padding
    scale = stats.scale
    axis = d3.svg.axis().scale(scale).orient("bottom")
    g = svg.selectAll('g').data(gradeSchemeElements).enter().append('g')
            .attr("transform", (gse)->
              "translate(" + (scale(gse.low_range) + padding) + "," + 25 + " )")
            .on("mouseover", (gse)->
              d3.select(".grade_scheme-label-" + gse.low_range).style("visibility", "visible")
              d3.select(".grade_scheme-pointer-" + gse.low_range)
                .attr("transform","scale(4) translate(-.5,-3)")
                .attr("fill", "#68A127")
            )
            .on("mouseout", (gse)->
              d3.select(".grade_scheme-label-" + gse.low_range).style("visibility", "hidden")
              d3.select(".grade_scheme-pointer-" + gse.low_range)
                .attr("transform","scale(2) translate(0,0)")
                .attr("fill", "black")
            )
    g.append("path")
      .attr("d", "M3,2.492c0,1.392-1.5,4.48-1.5,4.48S0,3.884,0,2.492c0-1.392,0.671-2.52,1.5-2.52S3,1.101,3,2.492z")
      .attr("class",(gse)-> "grade_scheme-pointer-" + gse.low_range)
      .attr("transform","scale(2)")
    txt = d3.select("#svg-grade-level-text").selectAll('g').data(gradeSchemeElements).enter()
            .append('g')
            .attr("class", (gse)->
              "grade_scheme-label-" + gse.low_range)
            .style("visibility", "hidden")
    txt.append('text')
      .text( (gse)-> gse.name)
      .attr("y","15")
      .attr("x",padding)
      .attr("font-family","Verdana")
      .attr("fill", "#FFFFFF")
    txt.insert("rect",":first-child")
      .attr("width", (gse)->
          angular.element(".grade_scheme-label-" + gse.low_range)[0].getBBox().width + (padding * 2)
        )
      .attr("height", 22)
      .attr("fill","#68A127")
    txt.attr("transform", (gse)->
      "translate(" + $scope.gradeLevelPosition(scale,gse.low_range,stats.width,padding) + "," + 0 + ")")
    d3.select("svg").append("g")
      .attr("class": "grade-point-axis")
      .attr("transform": "translate(" + padding + "," + (65) + ")")
      .call(axis)

  $scope.svgEarnedBarWidth = ()->
    width = $scope.GraphicsStats().scale($scope.allPointsEarned())
    width = width || 0

  $scope.svgPredictedBarWidth = ()->
    width = $scope.GraphicsStats().scale($scope.allPointsPredicted())
    width = width || 0

  return
]
