#------------------------------------------------------------------------------#

#                        COURSE DEFAULT CONFIGURATION                          #

#------------------------------------------------------------------------------#

# Add all attributes that will be passed on any course creation here, with a
# default value
# All courses will use defaults when individual attributes aren't supplied

@course_default_config = {
  quotes: {
    course_created: "A new course has been created",
    grade_sceme_elements_created:
      "Grade scheme elements have been added for the course",
    teams_created: "Teams have been added for the course",
    badges_created: "Badges have been added for the course",
    weights_created: "Weights have been configured for the course"
  },
  # All courses must have grade scheme elements
  grade_scheme_hash: { [0,600000] => "F", [600000,649000] => "D+",
    [650000,699999] => "C-", [700000,749999] => "C", [750000,799999] => "C+",
    [800000,849999] => "B-", [850000,899999] => "B", [900000,949999] => "B+",
    [950000,999999] => "A-", [1000000,1244999] => "A",
    [1245000,1600000] => "A+"
  },
  grade_levels: ["Amoeba", "Sponge", "Roundworm", "Jellyfish", "Leech", "Snail",
    "Sea Slug", "Fruit Fly", "Lobster", "Ant", "Honey Bee", "Cockroach", "Frog",
    "Mouse", "Rat", "Octopus", "Cat", "Chimpanzee", "Elephant", "Human",
    "Orca"].shuffle,
  # Not all courses have teams
  team_names: ["Harm & Hammer","Abusement Park","Silver Woogidy Woogidy Snakes",
    "Carpe Ludus","Eduception","Operation Unthinkable","Team Wang",
    "The Carpal Tunnel Crusaders","Pwn Depot"].shuffle,
  attributes: {
    academic_history_visible: false,
    accepts_submissions: false,
    add_team_score_to_student: false,
    assignment_term: nil,
    badge_setting: false,
    badge_term: nil,
    challenge_term: nil,
    character_names: false,
    character_profiles: false,
    class_email: nil,
    courseno: "ABC101",
    grading_philosophy: nil,
    group_setting: false,
    in_team_leaderboard: false,
    location: nil,
    max_group_size: nil,
    media: nil,
    media_caption: nil,
    media_credit: nil,
    meeting_times: nil,
    min_group_size: nil,
    name: "Generic course with Minimum Requirements",
    office: nil,
    office_hours: nil,
    phone: nil,
    semester: "Winter",
    tagline: nil,
    team_challenges: false,
    team_roles: false,
    team_score_average: false,
    team_setting: false,
    team_term: nil,
    teams_visible: false,
    total_assignment_weight: 0,
    twitter_handle: nil,
    twitter_hashtag: nil,
    use_timeline: true,
    user_term: nil,
    year: Date.today.year,
  }
}

#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#

# Note: @courses will hold each course as a hash key.
# The custom attributes should be defined below and will be available throughout
# sample creation.
#
# Additionally, The Active record models associated with the course be
# accessible on each course:
# Course: @courses[:course_name][:course] => Course
# Teams:  @courses[:course_name][:teams] => array of Teams
# Assignment Types: @courses[:course_name][:assignment_types] =>
# hash of AssignmentTypes
# Assignments: @courses[:course_name][:assignments] => hash of Assignments
# Challenges: @courses[:course_name][:challenges] => hash of Challenges
# Badges: @courses[:course_name][:challenges] => hash of Badges

# Create Courses!
@courses = {}

# Define courses in @courses, override default attributes

@courses[:teams_badges_points] = {
  quotes: {
    course_created: "Education is the most powerful weapon which you can use \
to change the world. - Nelson Mandela",
    grade_sceme_elements_created: "Real learning comes about when the \
competitive spirit has ceased. ― Jiddu Krishnamurti",
    teams_created: "The early bird gets the worm, but the second mouse gets \
the cheese. ― Willie Nelson",
  },
  attributes: {
    academic_history_visible: true,
    accepts_submissions: true,
    badge_setting: true,
    badge_term: "Badge",
    class_email: "staff-educ222@umich.edu",
    courseno: "GC101",
    grading_philosophy: "I believe a grading system should put the learner in
      control of their own destiny, promote autonomy, and reward effort and
      risk-taking. Whereas most grading systems start you off with 100% and
      then chips away at that “perfect grade” by averaging in each successive
      assignment, the grading system in this course starts everyone off at zero,
      and then gives you multiple ways to progress towards your goals. Different
      types of assignments are worth differing amounts of points. Some
      assignments are required of everyone, others are optional. Some
      assignments can only be done once, others can be repeated for more points.
      In most cases, the points you earn for an assignment are based on the
      quality of your work on that assignment. Do poor work, earn fewer points.
      Do high-quality work, earn more points. You decide what you want your
      grade to be. Learning in this class should be an active and engaged
      endeavor.",
    group_setting: true,
    location: "Whitney Auditorium, Room 1309 School of Education Building",
    max_group_size: 5,
    media_caption: "The Greatest Wizard Ever Known",
    media_credit: "Albus Dumbledore",
    meeting_times: "Mondays and Wednesdays, 10:30 am – 12:00 noon",
    min_group_size: 3,
    name: "Course with Teams & Badges with Points",
    office: "Room 4121 SEB",
    office_hours: "Tuesdays, 1:30 pm – 3:30 pm",
    phone: "734-644-3674",
    tagline: "Games good, school bad. Why?",
    team_challenges: true,
    team_setting: true,
    teams_visible: true,
    twitter_handle: "barryfishman",
    twitter_hashtag: "EDUC222",
    user_term: "Learner",
  }
}

@courses[:power_ups_locks_weighting_config] = {
  quotes: {
    course_created: "Live as if you were to die tomorrow. Learn as if you were \
to live forever. ― Mahatma Gandhi",
    grade_sceme_elements_created: "Education is the ability to listen to \
almost anything without losing your temper or your self-confidence―Robert \
Frost",
    teams_created: "The best thing for being sad, replied Merlin, beginning to \
puff and blow, is to learn something. That's the only thing that never \
fails. - Merlin via T.H. White",
    badges_created: "Self-education is, I firmly believe, the only kind of \
education there is. ― Isaac Asimov",
    weights_created: nil
  },
  grade_levels: ["Hammurabi", "Confucius", "Socrates", "Cicero",
    "William of Ockham", "Mozi", "Xenophon", "Saint Augustine", "Plato",
    "Diogenes", "Machiavelli", "Aeschines", "Ghazali", "Martin Luther",
    "Aristotle", "Calvin", "Maimonides", "St. Thomas Aquinas", "Xun Zi",
    "Ibn Khaldun", "Thiruvalluvar", "Locke"].shuffle,
  team_names: ["Section 1", "Section 2", "Section 3", "Section 4", "Section 5",
    "Section 6", "Section 7", "Section 8", "Section 9", "Section 10",
    "Section 11", "Section 12", "Section 13", "Section 14", "Section 15",
    "Section 16"].shuffle,
  attributes: {
    academic_history_visible: true,
    accepts_submissions: true,
    badge_setting: true,
    badge_term: "Power Up",
    class_email: "staff-educ222@umich.edu",
    courseno: "GC102",
    grading_philosophy: grading_philosophy = "Think of how video games work.
      This course works along the same logic. There are some things everyone
      will have to do to make progress. In this course, the readings,
      reading-related homework, lectures and discussion sections are those
      things. But game play also allows you to choose some activities -- quests,
      tasks, challenges -- and skip others. You can partly make your own path
      through a game. So also in this course: the are some assignment types you
      may choose(because you are good at them, or because you like challenges)
      and others you can avoid (because your interests are elsewhere). You also
      have a choice on how you want to weight some of the optional components
      you choose! In games, you start with a score of zero and 'level up' as you
      play. You might have to try some tasks several times before you get the
      points, but good games don't ever take your points away. Same here:
      everything you successfully do earns you more points. In games, you
      sometimes earn 'trophies' or 'badges' or 'power-ups' as you play. They
      might not have been your primary goal, but you get them because you do
      something particularly well. In this course, you also can earn power-ups.
      And at the end of the term, your score is your grade.",
    group_setting: true,
    location: "1324 East Hall",
    max_group_size: 5,
    meeting_times: "MW 11:30-1",
    min_group_size: 3,
    name: "Course with Power Ups, Unlocks, and Assignment Weighting",
    office: "7640 Haven",
    office_hours: "1:30-2:30 Tuesdays, 2:00-3:00 Wednesdays",
    phone: "734-644-3674",
    semester: "Fall",
    team_challenges: false,
    team_score_average: true,
    team_setting: true,
    team_term: "Section",
    total_assignment_weight: 6,
    twitter_handle: "polsci101",
    twitter_hashtag: "polsci101",
    weight_attributes: {
      max_assignment_types_weighted: 2,
      max_assignment_weight: 4,
      default_assignment_weight: 0.5,
    }
  }
}

@courses[:leaderboards_team_challenges] = {
  quotes: {
    course_created:
      "I have never let my schooling interfere with my education. ― Mark Twain",
    grade_sceme_elements_created: "The world is a book and those who do not \
travel read only one page. ― Augustine of Hippo",
    teams_created: "Spoon feeding in the long run teaches us nothing but the \
shape of the spoon. ― E.M. Forster",
  },
  grade_levels: ["Shannon", "Weaver", "Vannevar Bush", "Turing", "Boole",
    "Gardner", "Shestakov", "Blackman", "Bode", "John Pierce", "Thorpe",
    "Renyi", "Cohen", "Berners Lee", "Nash", "Cailliau", "Andreessen",
    "Hartill", "Ada Lovelace", "Grace Hopper", "Henrietta Leavitt",
    "Anita Borg"].shuffle,
  team_names: ["Late Night Information Nation", "Heisenberg", "Big Red Dogs",
    "Liu Man Group", "The House that Cliff Built", "TMI"].shuffle,
  attributes: {
    academic_history_visible: true,
    accepts_submissions: true,
    add_team_score_to_student: true,
    assignment_term: "Quest",
    challenge_term: "Ambush",
    character_names: true,
    character_profiles: true,
    class_email: "staff-si110@umich.edu",
    courseno: "GC103",
    grading_philosophy: "In this course, we accrue 'XP' which are points that
      you gain to get to different grade levels. If you can gather 950,000 XP,
      you will receive an A, not to mention the admiration of those around you.
      Because you’re in charge of figuring out how many XP you need to get the
      grade you want, there’s not really such a thing as a required assignment
      in this course. There are opportunities to gain XP, some of which are
      scheduled. Of course, you’ll need to do several Quests in order to get
      higher grade levels, and some Quests count for a ton of XP. Each of these
      quests is managed in GradeCraft, where you can see your progress, as well
      as check the forecasting tool to see what you need to do on future
      assignments to get your desired grade level. A quick note on our
      assessment philosophy. Most Quests will have rubrics attached, which will
      spell out our expectations. However, just meeting the details of the
      assignment is by definition average work, which would receive something
      around the B category. If your goal is to get an A, you will have to go
      above and beyond on some of these Quests.",
    in_team_leaderboard: true,
    location: "2245 North Quad",
    meeting_times: "TTh 12:00-1:30",
    name: "Course with Leaderboards and Team Challenges",
    office_hours: "email me",
    phone: "777-777-7777",
    semester: "Fall",
    team_challenges: true,
    team_roles: true,
    team_score_average: true,
    team_setting: true,
    teams_visible: true,
    twitter_handle: "si110",
    twitter_hashtag: "si101",
  }
}

@courses[:assignment_type_caps_config] = {
  quotes: {
    course_created: "You can never be overdressed or overeducated― Oscar Wilde",
    grade_sceme_elements_created: "To emphasize only the beautiful seems to \
me to be like a mathematical system that only concerns itself with positive \
numbers. ― Paul Klee",
    teams_created: "We learn from failure, not from success! ― Bram Stoker, \
Dracula",
  },
  grade_levels: ["Arp", "Breton", "Dali", "Duchamp", "Earnst", "Giacometti",
    "Magritte", "Masson", "Miro", "Oppenheim", "Ray", "Tanguy"].shuffle,
  attributes: {
    academic_history_visible: true,
    accepts_submissions: true,
    class_email: "staff-si110@umich.edu",
    courseno: "GC104",
    grading_philosophy: "In this course, we accrue 'XP' which are points that
      you gain to get to different grade levels. If you can gather 950,000 XP,
      you will receive an A, not to mention the admiration of those around you.
      Because you’re in charge of figuring out how many XP you need to get the
      grade you want, there’s not really such a thing as a required assignment
      in this course. There are opportunities to gain XP, some of which are
      scheduled. Of course, you’ll need to do several Quests in order to get
      higher grade levels, and some Quests count for a ton of XP. Each of these
      quests is managed in GradeCraft, where you can see your progress, as well
      as check the forecasting tool to see what you need to do on future
      assignments to get your desired grade level. A quick note on our
      assessment philosophy. Most Quests will have rubrics attached, which will
      spell out our expectations. However, just meeting the details of the
      assignment is by definition average work, which would receive something
      around the B category. If your goal is to get an A, you will have to go
      above and beyond on some of these Quests.",
    location: "2245 North Quad",
    meeting_times: "TTh 12:00-1:30",
    name: "Course with Assignment Type Caps",
    office_hours: "email me",
    phone: "777-777-7777",
    semester: "Fall",
    team_setting: true,
    twitter_handle: "si110",
    twitter_hashtag: "si101",
  }
}
