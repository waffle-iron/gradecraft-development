#------------------------------------------------------------------------------#

#                           badge DEFAULT CONFIGURATION                        #

#------------------------------------------------------------------------------#

# Add all attributes that will be passed on any badge creation here, with a
# default value
# All assignment types will use defaults when individual attributes aren't
# supplied

@badge_default_config = {
  quotes: {
    badge_created: "A badge has been created for each course that has badges",
  },
  attributes: {
    name: "Generic badge",
    point_total: (100 * rand(1..10) + 100),
    description: nil,
    visible: false,
    can_earn_multiple_times: false
  },
  assign_samples: false, # assign earned badges on init
  unlock_condition: false,
  unlock_attributes: {
    condition: :nil,
    condition_type: nil,
    condition_state: nil
  }
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

@badges = {}

@badges[:single_earn_badge_earned] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Singularis Earned",
    description: "An visible badge that can only be earned once. Earned badges
      assigned to all students",
    visible: true,
  },
  assign_samples: true,
}

@badges[:single_earn_badge_unearned] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Singularis Unearned",
    description: "An visible badge that can only be earned once.",
    visible: true,
  },
  assign_samples: false,
}

@badges[:multiple_earn_badge_earned] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Multiplus Earned",
    description: "A visible badge that can be seen by all and earned multiple
      times. Earned badges assigned to all students",
    visible: true,
    can_earn_multiple_times: true
  },
  assign_samples: true,
}

@badges[:multiple_earn_badge_unearned] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Multiplus Unearned",
    description: "A visible badge that can be seen by all and earned multiple
      times.",
    visible: true,
    can_earn_multiple_times: true
  },
  assign_samples: false,
}

@badges[:long_description] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Verbose Descriptor",
    description: "A badge with a long description. Earned badges assigned to
      all students. A badge is a device or accessory, often containing the
      insignia of an organization, which is presented or displayed to indicate
      some feat of service, a special accomplishment, a symbol of authority
      granted by taking an oath (e.g., police and fire), a sign of legitimate
      employment or student status, or as a simple means of identification.
      They are also used in advertising, publicity, and for branding purposes.
      Police badges date back to medieval times when knights wore a coat of arms
      representing their allegiances and loyalty.[Wikipedia]",
    visible: true,
    can_earn_multiple_times: true
  },
  assign_samples: false,
}

@badges[:zero_points_single_earn_badge] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Zephirum Singularis",
    description: "A zero points badge that can be earned once.",
    visible: true,
    point_total: 0,
    can_earn_multiple_times: false
  },
  assign_samples: false,
}

@badges[:zero_points_single_earn_badge_earned] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Zephirum Earned",
    description: "A zero points badge already earned by all students.",
    visible: true,
    point_total: 0,
    can_earn_multiple_times: false
  },
  assign_samples: true,
}

@badges[:zero_points_multiple_earn_badge] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Zephira Multiplus",
    visible: true,
    description: "A zero points badge that can be earned multiple times.",
    point_total: 0,
    can_earn_multiple_times: true
  },
  assign_samples: false,
}

@badges[:zero_points_multiple_earn_badge_earned] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Zephira Earned",
    visible: true,
    description: "A zero points badge that can be earned multiple times.",
    point_total: 0,
    can_earn_multiple_times: true
  },
  assign_samples: true,
}

@badges[:invisible_badge_earned] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Secretus Earned",
    description: "An invisible badge that can be earned multiple times. Should
      only be visible to students once they earn it. Earned badges assigned to
      all students",
    can_earn_multiple_times: true
  },
  assign_samples: true,
}

@badges[:invisible_badge_unearned] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Secretus Unearned",
    description: "An invisible badge that can be earned multiple times. Should
      only be visible to students once they earn it.",
    can_earn_multiple_times: true
  },
  assign_samples: false,
}

@badges[:visible_level_badge] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Gradualis Opticus",
    description:
      "Level Badge - A visible badge associated with a Rubric Level.",
    visible: true,
    can_earn_multiple_times: true
  },
  assign_samples: false,
}

@badges[:invisible_level_badge] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Gradualis Secretus",
    description:
      "Level Badge - An invisible badge associated with a Rubric Level.",
    visible: false,
    can_earn_multiple_times: true
  },
  assign_samples: false,
}

# Both badges and assignments need to already exists before we can assign
# each to the other as condition. For now, badges are created first and can be
# sample conditions for both badges and assignments.

@badges[:badge_unlock_assignment_condition] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Assignment-Unlock-Key",
    description: "This badge unlocks the assignment Unlocked-By-Badge-Example",
    visible: true,
    can_earn_multiple_times: false
  },
  assign_samples: false,
}

@badges[:badge_unlock_badge_condition] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Badge-Unlock-Key",
    description: "This badge unlocks the badge Unlocked-By-Badge-Example",
    visible: true,
    can_earn_multiple_times: false
  },
  assign_samples: false,
}

@badges[:badge_is_an_unlock] = {
  quotes: {
    badge_created: nil,
  },
  attributes: {
    name: "Unlocked-By-Badge",
    description:
      "An visible badge which is unlocked by the badge Badge-Unlock-Key.",
    visible: true,
    can_earn_multiple_times: false
  },
  unlock_condition: true,
  unlock_attributes: {
    condition: :badge_unlock_badge_condition,
    condition_type: "Badge",
    condition_state: "Earned"
  },
  assign_samples: false,
}
