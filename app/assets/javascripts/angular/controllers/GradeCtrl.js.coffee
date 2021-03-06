@gradecraft.controller 'GradeCtrl', ['$timeout', '$rootScope', '$scope', 'Grade', 'AssignmentScoreLevel', '$window', '$http','EventHelper', ($timeout, $rootScope, $scope, Grade, AssignmentScoreLevel, $window, $http, EventHelper) ->

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
    $scope.populateCollections(initData.assignment_score_levels)

  # add initial score levels
  $scope.populateCollections = (assignmentScoreLevels)->
    $scope.assignmentScoreLevels = []

    unless assignmentScoreLevels.length == 0
      $scope.addAssignmentScoreLevels(assignmentScoreLevels)

  # add assignment score level objects if they exist
  $scope.addAssignmentScoreLevels = (assignmentScoreLevels)->
    angular.forEach(assignmentScoreLevels, (scoreLevel, index)->
      scoreLevelPrototype = new AssignmentScoreLevel(scoreLevel, $scope)
      $scope.assignmentScoreLevels.push scoreLevelPrototype
    )

  $scope.froalaOptions = {
    inlineMode: false,
    heightMin: 200,
    toolbarButtons: [
      'fullscreen', 'bold', 'italic', 'underline', 'strikeThrough',
      'fontFamily', 'fontSize', 'color', 'sep', 'blockStyle', 'emoticons',
      'insertTable', 'sep', 'formatBlock', 'align', 'insertOrderedList',
      'outdent', 'indent', 'insertHorizontalRule', 'insertLink', 'undo', 'redo',
      'clearFormatting', 'selectAll', 'html'
    ]
  }
]
