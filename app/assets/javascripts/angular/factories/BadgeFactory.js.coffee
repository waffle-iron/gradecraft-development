@gradecraft.factory 'Badge', ['EarnedBadge', '$timeout', '$http', (EarnedBadge, $timeout, $http)->
  class Badge

    constructor: (attrs, gradeId) ->
      @id = attrs.id
      @name = attrs.name
      @description = attrs.name
      @point_total = attrs.point_total
      @multiple = attrs.multiple
      @icon = attrs.icon
      @value = attrs.value
      @formatted_value = null
      @grade_id = gradeId
      @assignment_id = attrs.assignment_id
      @student_earned_badges_serial = attrs.student_earned_badges
      this.otherEarnedBadges = []
      this.earnedBadge = null
      this.addEarnedBadges()
      @awarded = this.earnedBadge ? true : false
      @creating = false
      @deleting = false

    handleDestroyAll: ()->
      this.earnedBadge = null
      $timeout(this.setAvailable, 300)

    deleteEarnedStudentBadge: ()->
      thisBadge = this

      unless this.deleting == true
        this.setDeleting()

        this.earnedBadge.deleteFromServer(this).then ((deleteResponse) ->
          if deleteResponse.success
            # delete the earned badge at the badge and make the badge available
            thisBadge.earnedBadge = null
            `$timeout(function() { thisBadge.setAvailable() }, 1000)`
          else
            # indicate that badge was not deleted
          return
        ), (error) ->
          # promise rejected, could log the error with: console.log('error', error);
          return

    earnBadge: (params)->
      self = this
      earnedBadge = new EarnedBadge(params)
      if earnedBadge.grade_id == self.grade_id
        self.earnedBadge = earnedBadge
      else
        self.otherEarnedBadges.push earnedBadge

    addEarnedBadges: ()->
      self = this
      angular.forEach(@student_earned_badges_serial, (earnedBadgeParams, index)->
        self.earnBadge(earnedBadgeParams)
      )

    totalEarnedBadges: ()->
      totalCount = this.otherEarnedBadges.length
      totalCount += 1 if this.earnedBadge
      totalCount

    prettyEarnedBadge: ()->
      JSON.stringify(this.earnedBadge)

    earnBadgeForStudent: (requestParams)->
      $http.post("/api/earned_badges", requestParams).then ((response)->
        if typeof response.data == 'object'
          console.log "Successfully created Earned Badge"
          response.data
        else
          # invalid response
          console.log "Failed to create Earned Badge"
          $q.reject response.data
      ), (response) ->
        # something went wrong
        console.log "Error occurred while trying to create Earned Badge"
        $q.reject response.data


    unearned: ()->
      ! this.earnedBadge

    earned: ()->
      this.earnedBadge

    timeoutCreate: ()->
      thisBadge = this
      `$timeout(function() {thisBadge.createDone()}, 1000);`

    doneCreating: ()->
      this.timeoutCreate()

    doneDeleting: ()->
      thisBadge = this
      `$timeout(function() {thisBadge.deleteDone()}, 1000);`

    setAwarded: ()->
      this.awarded = true

    setAvailable: ()->
      this.deleting = false
      this.awarded = false

    setCreating: ()->
      this.creating = true

    createDone: ()->
      this.creating = false

    setDeleting: ()->
      this.deleting = true

    deleteDone: ()->
      this.deleting = false

]
