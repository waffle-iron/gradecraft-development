#------------------------------------------------------------------------------#

#                       ASSIGNMENT TYPE DEFAULT CONFIGURATION
#

#------------------------------------------------------------------------------#

# Add all attributes that will be passed on any assignment type creation here,
# with a default value
# All assignment types will use defaults when individual attributes aren't
# supplied

@assignment_type_default_config = {
  quotes: {
    assignment_type_created:
      "A new assignment type for each course has been created"
  },
  attributes: {
    name: "Genric Assignment Type",
    description: nil,
    max_points: nil,
    position: nil,
    student_weightable: false,
  }
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

@assignment_types = {}

# Define Assignment Types, override default values

@assignment_types[:grading] = {
  quotes: {
    assignment_type_created: "Well, I gotta look on the bright side. Maybe I \
can still get kicked out of school. - Buffy"
  },
  attributes: {
    name: "Grading Settings",
    description: "This category should include all of the different ways \
assignments can be graded.",
    position: 1
  }
}

@assignment_types[:submissions] = {
  quotes: {
    assignment_type_created: "Creativity is the process of having original \
ideas that have value. It is a process; it's not random.-Sir Ken Robinson"
  },
  attributes: {
    name: "Submission Settings",
    description: "This category includes all of the different ways that \
assignments can handle submissions.",
    position: 2
  }
}

@assignment_types[:predictor] = {
  quotes: {
    assignment_type_created: "Beware of overconfidence; especially in \
matters of structure. – Cass Gilbert"
  },
  attributes: {
    name: "Predictor Settings",
    description: "This category includes all of the different ways that \
assignments can handle submissions.",
    position: 3
  }
}

@assignment_types[:visibility] = {
  quotes: {
    assignment_type_created: "A different voice may be particularly effective \
in disturbing the existing participants into re-examining matters they had \
come to take for granted. ― Stefan Collini"
  },
  attributes: {
    name: "Visibility Settings",
    description: "This category includes checks for visibile and not-visible \
assignments",
    position: 4
  }
}

@assignment_types[:capped] = {
  quotes: {
    assignment_type_created: nil
  },
  attributes: {
    name: "Assignment Type with a Capped Point Total",
    description: "This category includes checks for when the assignment type \
caps the total points",
    max_points: 100000,
    position: 5
  }
}

@assignment_types[:notifications] = {
  quotes: {
    assignment_type_created: "Play is our brain's favorite way of learning. – \
Diane Ackerman"
  },
  attributes: {
    name: "Notification Settings",
  }
}

@assignment_types[:analytics] = {
  quotes: {
    assignment_type_created: "People want to forget the impossible. It makes \
their world safer. ― Neil Gaiman"
  },
  attributes: {
    name: "Analytics Settings",
  }
}

@assignment_types[:unlocks] = {
  quotes: {
    assignment_type_created: "Life's under no obligation to give us what we \
expect. ― Margaret Mitchell"
  },
  attributes: {
    name: "Unlock Settings",
  }
}

@assignment_types[:sorting] = {
  quotes: {
    assignment_type_created: "Every maker of video games knows something that \
the makers of curriculum don't seem to understand. You'll never see a video \
game being advertised as being easy. Kids who do not like school will tell \
you it's not because it's too hard. It's because it's--boring ― Seymour Papert"
  },
  attributes: {
    name: "Sorting Settings",
  }
}

@assignment_types[:weighting_one] = {
  quotes: {
    assignment_type_created: nil,
  },
  attributes: {
    name: "Weighted Assignment Type #1 Settings",
    student_weightable: true,
  }
}

@assignment_types[:weighting_two] = {
  quotes: {
    assignment_type_created: nil,
  },
  attributes: {
    name: "Weighted Assignment Type #2 Settings",
    student_weightable: true,
  }
}

@assignment_types[:weighting_three] = {
  quotes: {
    assignment_type_created: nil,
  },
  attributes: {
    name: "Weighted Assignment Type #3 Settings",
    student_weightable: true,
  }
}

@assignment_types[:weighting_four] = {
  quotes: {
    assignment_type_created: nil,
  },
  attributes: {
    name: "Weighted Assignment Type #3 Settings",
    student_weightable: true,
  }
}
