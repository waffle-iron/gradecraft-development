@gradecraft.controller 'AssignmentCtrl', ['$scope', '$http', ($scope, $http) ->

  $scope.init = (assignmentId, useRubric)->
    $scope.assignmentId = assignmentId
    $scope.useRubric = useRubric

  $scope.rubricsOff = ()->
    if confirm "Are you sure you want to turn off rubrics for this assignment?"
      self = this
      $http.put("/assignments/#{$scope.assignmentId}", {assignment: {use_rubric:false}}).success(
        $scope.useRubric = false
      )
      .error(
      )

  $scope.rubricsOn = ()->
    if confirm "Are you sure you want to turn on rubrics for this assignment?"
      self = this
      $http.put("/assignments/#{$scope.assignmentId}", {assignment: {use_rubric:true}}).success(
        $scope.useRubric = true
      )
      .error(
      )

  ]
