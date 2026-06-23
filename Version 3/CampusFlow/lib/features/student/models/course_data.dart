class CourseData {
  static final Map<String, List<Map<String, dynamic>>> courses = {
    // ==================== HEALTH SCIENCES & MEDICINE ====================
    'Health Sciences & Medicine': [
      {
        'code': 'MBChB',
        'name': 'Bachelor of Medicine and Bachelor of Surgery',
        'credits': 6,
      },
      {
        'code': 'BNSG',
        'name': 'Bachelor of Nursing (Direct/Upgrading)',
        'credits': 5,
      },
      {'code': 'BPHARM', 'name': 'Bachelor of Pharmacy', 'credits': 5},
      {'code': 'BCM', 'name': 'Bachelor of Clinical Medicine', 'credits': 5},
      {
        'code': 'BMLS',
        'name': 'Bachelor of Medical Laboratory Sciences',
        'credits': 5,
      },
      {'code': 'BPH', 'name': 'Bachelor of Public Health', 'credits': 4},
      {
        'code': 'BHSM',
        'name': 'Bachelor of Health Systems Management',
        'credits': 4,
      },
      {'code': 'BDT', 'name': 'Bachelor of Dental Technology', 'credits': 5},
    ],

    // ==================== LAW ====================
    'Law': [
      {'code': 'LLB', 'name': 'Bachelor of Laws (LLB)', 'credits': 5},
    ],

    // ==================== COMPUTING & INFORMATICS ====================
    'Computing & Informatics': [
      {'code': 'BScCS', 'name': 'BSc Computer Science', 'credits': 4},
      {'code': 'BScIT', 'name': 'BSc Information Technology', 'credits': 4},
      {
        'code': 'BBIT',
        'name': 'Bachelor of Business Information Technology',
        'credits': 4,
      },
      {'code': 'BScIS', 'name': 'BSc Information Science', 'credits': 4},
    ],

    // ==================== BUSINESS & ECONOMICS ====================
    'Business & Economics': [
      {
        'code': 'BCom',
        'name': 'BCom (Accounting, Finance, Marketing, HRM)',
        'credits': 4,
      },
      {'code': 'BBM', 'name': 'Bachelor of Business Management', 'credits': 4},
      {
        'code': 'BEcon',
        'name': 'Bachelor of Economics/Economics & Finance',
        'credits': 4,
      },
      {'code': 'BProc', 'name': 'Bachelor of Procurement', 'credits': 4},
    ],

    // ==================== EDUCATION & SOCIAL SCIENCES ====================
    'Education & Social Sciences': [
      {
        'code': 'BEd',
        'name': 'Bachelor of Education (Arts, Science, Special Needs, ECD)',
        'credits': 4,
      },
      {'code': 'BMM', 'name': 'Bachelor of Mass Media', 'credits': 4},
      {'code': 'BCrim', 'name': 'Bachelor of Criminology', 'credits': 4},
      {
        'code': 'BIR',
        'name': 'Bachelor of International Relations',
        'credits': 4,
      },
      {
        'code': 'BCDSW',
        'name': 'Bachelor of Community Development/Social Work',
        'credits': 4,
      },
      {
        'code': 'BPA',
        'name': 'Bachelor of Public Administration',
        'credits': 4,
      },
    ],

    // ==================== SCIENCE, ENGINEERING & HOSPITALITY ====================
    'Science, Engineering & Hospitality': [
      {'code': 'BActSc', 'name': 'Bachelor of Actuarial Science', 'credits': 5},
      {'code': 'BIC', 'name': 'Bachelor of Industrial Chemistry', 'credits': 5},
      {'code': 'BAB', 'name': 'Bachelor of Applied Biology', 'credits': 5},
      {
        'code': 'BEEE',
        'name': 'Bachelor of Electrical/Electronic Engineering',
        'credits': 5,
      },
      {'code': 'BHosp', 'name': 'Bachelor of Hospitality', 'credits': 4},
      {
        'code': 'BTTM',
        'name': 'Bachelor of Travel & Tourism Management',
        'credits': 4,
      },
    ],
  };

  // Units by course code
  static final Map<String, List<Map<String, dynamic>>> units = {
    // ===== COMPUTER SCIENCE =====
    'BScCS': [
      {'code': 'CS301', 'name': 'Software Engineering', 'credits': 4},
      {'code': 'CS302', 'name': 'Database Systems', 'credits': 4},
      {'code': 'CS303', 'name': 'Web Development', 'credits': 3},
      {'code': 'CS304', 'name': 'Data Structures and Algorithms', 'credits': 4},
      {'code': 'CS305', 'name': 'Computer Networks', 'credits': 3},
      {'code': 'CS306', 'name': 'Mobile App Development', 'credits': 3},
      {'code': 'CS307', 'name': 'Artificial Intelligence', 'credits': 4},
      {'code': 'CS308', 'name': 'Cybersecurity', 'credits': 3},
    ],

    // ===== INFORMATION TECHNOLOGY =====
    'BScIT': [
      {'code': 'IT301', 'name': 'Information Systems Management', 'credits': 4},
      {'code': 'IT302', 'name': 'Network Security', 'credits': 4},
      {'code': 'IT303', 'name': 'Database Management', 'credits': 3},
      {'code': 'IT304', 'name': 'Web Technologies', 'credits': 4},
      {'code': 'IT305', 'name': 'IT Project Management', 'credits': 3},
      {'code': 'IT306', 'name': 'Cloud Computing', 'credits': 3},
      {'code': 'IT307', 'name': 'Data Analytics', 'credits': 4},
      {'code': 'IT308', 'name': 'IT Infrastructure', 'credits': 3},
    ],

    // ===== BUSINESS INFORMATION TECHNOLOGY =====
    'BBIT': [
      {'code': 'BIT301', 'name': 'Business Information Systems', 'credits': 4},
      {'code': 'BIT302', 'name': 'E-Commerce', 'credits': 3},
      {'code': 'BIT303', 'name': 'Database Management', 'credits': 4},
      {'code': 'BIT304', 'name': 'Systems Analysis', 'credits': 4},
      {'code': 'BIT305', 'name': 'IT Governance', 'credits': 3},
      {'code': 'BIT306', 'name': 'Digital Marketing', 'credits': 3},
    ],

    // ===== SOFTWARE ENGINEERING =====
    'BScSE': [
      {'code': 'SE301', 'name': 'Software Design', 'credits': 4},
      {'code': 'SE302', 'name': 'Agile Development', 'credits': 4},
      {'code': 'SE303', 'name': 'DevOps', 'credits': 3},
      {'code': 'SE304', 'name': 'Software Testing', 'credits': 4},
      {'code': 'SE305', 'name': 'Cloud Computing', 'credits': 3},
      {'code': 'SE306', 'name': 'Software Architecture', 'credits': 4},
      {'code': 'SE307', 'name': 'Mobile Development', 'credits': 3},
    ],

    // ===== BUSINESS ADMINISTRATION =====
    'BBA': [
      {'code': 'BA301', 'name': 'Business Strategy', 'credits': 4},
      {'code': 'BA302', 'name': 'Organizational Behaviour', 'credits': 4},
      {'code': 'BA303', 'name': 'Business Ethics', 'credits': 3},
      {'code': 'BA304', 'name': 'Entrepreneurship', 'credits': 4},
      {'code': 'BA305', 'name': 'International Business', 'credits': 3},
    ],

    // ===== LLB (Law) =====
    'LLB': [
      {'code': 'LW301', 'name': 'Constitutional Law', 'credits': 5},
      {'code': 'LW302', 'name': 'Criminal Law', 'credits': 5},
      {'code': 'LW303', 'name': 'Contract Law', 'credits': 4},
      {'code': 'LW304', 'name': 'Tort Law', 'credits': 4},
      {'code': 'LW305', 'name': 'Land Law', 'credits': 4},
      {'code': 'LW306', 'name': 'Equity and Trusts', 'credits': 4},
      {'code': 'LW307', 'name': 'Jurisprudence', 'credits': 4},
    ],

    // ===== NURSING =====
    'BNSG': [
      {'code': 'NS301', 'name': 'Fundamentals of Nursing', 'credits': 5},
      {'code': 'NS302', 'name': 'Medical-Surgical Nursing', 'credits': 5},
      {'code': 'NS303', 'name': 'Maternal-Child Nursing', 'credits': 5},
      {'code': 'NS304', 'name': 'Psychiatric Nursing', 'credits': 4},
      {'code': 'NS305', 'name': 'Community Health Nursing', 'credits': 4},
      {'code': 'NS306', 'name': 'Nursing Research', 'credits': 4},
    ],

    // ===== EDUCATION =====
    'BEd': [
      {'code': 'ED301', 'name': 'Educational Psychology', 'credits': 4},
      {'code': 'ED302', 'name': 'Curriculum Development', 'credits': 4},
      {'code': 'ED303', 'name': 'Teaching Methods', 'credits': 4},
      {'code': 'ED304', 'name': 'Educational Technology', 'credits': 3},
      {'code': 'ED305', 'name': 'Special Needs Education', 'credits': 4},
      {'code': 'ED306', 'name': 'Early Childhood Development', 'credits': 4},
    ],
  };

  static List<String> getFaculties() {
    return courses.keys.toList();
  }

  static List<Map<String, dynamic>> getCoursesByFaculty(String faculty) {
    return courses[faculty] ?? [];
  }

  static List<Map<String, dynamic>> getUnitsByCourse(String courseCode) {
    return units[courseCode] ?? [];
  }

  static String? getCourseName(String courseCode) {
    for (var faculty in courses.values) {
      for (var course in faculty) {
        if (course['code'] == courseCode) {
          return course['name'];
        }
      }
    }
    return null;
  }
}
