@gradecraft.controller 'GradeCtrl', ['$timeout', '$rootScope', '$scope', 'Grade', 'AssignmentScoreLevel', '$window', '$http', 'Badge', 'EventHelper', ($timeout, $rootScope, $scope, Grade, AssignmentScoreLevel, $window, $http, Badge, EventHelper) ->

  # setup the controller scope on initialize
  $scope.init = (initData)->
    # is interactive ui debugging on?
    $scope.debug = false

    # grade stuff
    $scope.grade = new Grade(initData.grade, $http)
    $scope.gradeId = initData.grade.id

    # assignment stuff
    $scope.releaseNecessary = initData.assignment.release_necessary

    $scope.rawScoreUpdating = false
    $scope.hasChanges = false

    # establish and populate all necessary collections for UI
    $scope.populateCollections(initData.badges, initData.assignment_score_levels)

  # add initial score levels and badges
  $scope.populateCollections = (badges, assignmentScoreLevels)->
    $scope.badges = []
    $scope.badgesEarned = []
    $scope.assignmentScoreLevels = []

    unless assignmentScoreLevels.length == 0
      $scope.addAssignmentScoreLevels(assignmentScoreLevels)

    unless badges.length == 0
      $scope.addBadges(badges)

  # have any badges been awarded for this grade at all?
  $scope.badgesAwarded = ()->
    earnedBadgeCount = 0
    angular.forEach($scope.badges, (badge)->
      earnedBadgeCount += 1 if badge.earnedBadge
    )
    earnedBadgeCount != 0

  # are there badges still available to be earned for this grade?
  $scope.badgesAvailable = ()->
    earnedBadgeCount = 0
    angular.forEach($scope.badges, (badge)->
      earnedBadgeCount += 1 if badge.earnedBadge
    )
    earnedBadgeCount != $scope.badges.length

  # add assignment score level objects if they exist
  $scope.addAssignmentScoreLevels = (assignmentScoreLevels)->
    angular.forEach(assignmentScoreLevels, (scoreLevel, index)->
      scoreLevelPrototype = new AssignmentScoreLevel(scoreLevel, $scope)
      $scope.assignmentScoreLevels.push scoreLevelPrototype
    )

  # create a new badge object for each json badge
  $scope.addBadges = (badges)->
    # parameters for earned badge creation
    angular.forEach(badges, (badge, index)->
      badgePrototype = new Badge(badge, $scope.gradeId)
      $scope.badges.push badgePrototype
    )

  # add all unearned badges for student for this grade
  $scope.addRemainingEarnedBadges = (event)->
    EventHelper.killEvent(event)

    unearnedBadges = {}
    unearnedBadgesPostParams = []

    angular.forEach($scope.badges, (badge)->
      if badge.unearned()
        badge.setCreating()
        unearnedBadges[badge.id] = badge
        unearnedBadgesPostParams.push $scope.earnedBadgePostParams(badge)
    )

    $http.post("/grade/#{$scope.grade.id}/earn_student_badges", {earned_badges: unearnedBadgesPostParams}).success(
      (data, status)->
        angular.forEach(data["grades"], (earnedBadge)->
          badge = unearnedBadges[earnedBadge.badge_id]
          badge.earnBadge(earnedBadge)
          badge.timeoutCreate()
        )
        $scope.hideAvailableShowRewarded()
    )
    .error((err)->
      console.log "EarnedBadge deletion failed"
      return false
    )

  # remove all remaining earned badges for student for this grade
  $scope.removeAllEarnedBadges = (event)->
    EventHelper.killEvent(event)
    angular.element(event.currentTarget).addClass("ng-hide")

    angular.forEach($scope.badges, (badge)->
      if badge.earned()
        badge.setDeleting()
    )

    $http.delete("/grade/#{$scope.grade.id}/earned_badges").success(
      (data, status)->
        angular.forEach($scope.badges, (badge) ->
          badge.handleDestroyAll()
          badge.doneDeleting()
        )
        # conditionally add/remove hide-after-fade class
        $scope.showAvailableHideAwarded()
    )
    .error((err)->
      console.log "delete failed"
      return false
    )

  # helpers for very non-angular-like conditional class removal/addition
  $scope.hideAvailableShowRewarded = ()->
    availableBadges = document.getElementsByClassName("grade-badge available")
    `$timeout(function() { angular.element(availableBadges).addClass("hide-after-fade")}, 1000)`
    awardedBadges = document.getElementsByClassName("grade-badge awarded")
    `$timeout(function() { angular.element(awardedBadges).removeClass("hide-after-fade")}, 1000)`

  $scope.showAvailableHideAwarded = ()->
    availableBadges = document.getElementsByClassName("grade-badge available")
    `$timeout(function() { angular.element(availableBadges).removeClass("hide-after-fade")}, 1000)`
    awardedBadges = document.getElementsByClassName("grade-badge awarded")
    `$timeout(function() { angular.element(awardedBadges).addClass("hide-after-fade")}, 1000)`

  # earn one badge for a student
  $scope.earnBadgeForStudent = (badge)->
    thisBadge = badge

    unless badge.creating
      badge.setCreating()
      badge.earnBadgeForStudent({earned_badge: $scope.earnedBadgePostParams(badge)}).then ((response)->
        # earned badge promise returned successfully,
        # so add the badge and remove the hold on creation
        thisBadge.earnBadge(response)
        thisBadge.doneCreating()
        return
      ), (error) ->
        # promise rejected, could log the error with: console.log('error', error);
        thisBadge.doneCreating()
        return


  # parameters for earned badge creation
  $scope.earnedBadgePostParams = (badge)->
    student_id: $scope.grade.student_id
    badge_id: badge.id,
    grade_id: $scope.grade.id,
    assignment_id: $scope.grade.assignment_id
    score: badge.point_total
    student_visible: $scope.grade.student_visible

  $scope.froalaOptions = {
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
