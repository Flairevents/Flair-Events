# Machine generated, do not edit
# See lib/tasks/serialization.rake
window.importAccountFromJSON = (array) ->
  {
    id: array[0],
    user_id: array[1],
    locked: array[2]
  }

window.importActionTakenFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    prospect_id: array[2],
    action: array[3],
    created_at: (val = array[4]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2], ymd[3], ymd[4], ymd[5])))),
    reason: array[5]
  }

window.importAssignmentFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    job_id: array[2],
    shift_id: array[3],
    location_id: array[4],
    staff_needed: array[5],
    created_at: (val = array[6]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2], ymd[3], ymd[4], ymd[5]))))
  }

window.importAssignmentEmailTemplateFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    name: array[2],
    office_message: array[3],
    arrival_time: array[4],
    meeting_location: array[5],
    meeting_location_coords: array[6],
    on_site_contact: array[7],
    contact_number: array[8],
    confirmation: array[9],
    uniform: array[10],
    welfare: array[11],
    transport: array[12],
    details: array[13],
    additional_info: array[14]
  }

window.importBookingFromJSON = (array) ->
  {
    id: array[0],
    event_client_id: array[1],
    client_contact_id: array[2],
    dates: array[3],
    timings: array[4],
    crew_required: array[5],
    job_description: array[6],
    event_description: array[7],
    selling_points: array[8],
    staff_qualities: array[9],
    uniform: array[10],
    food: array[11],
    breaks: array[12],
    wages: array[13],
    terms: array[14],
    invoicing: array[15],
    timesheets: array[16],
    minimum_hours: array[17],
    any_other_information: array[18],
    office_notes: array[19],
    amendments: array[20],
    transport: array[21],
    meeting_location: array[22],
    date_sent: (val = array[23]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    date_received: (val = array[24]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    health_safety: array[25],
    rates: array[26]
  }

window.importBulkInterviewFromJSON = (array) ->
  {
    id: array[0],
    name: array[1],
    venue: array[2],
    positions: array[3],
    date_start: (val = array[4]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    date_end: (val = array[5]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    address: array[6],
    city: array[7],
    post_code: array[8],
    note_for_applicant: array[9],
    target_region_id: array[10],
    region_id: array[11],
    photo: array[12],
    directions: array[13],
    status: array[14],
    interview_type: array[15]
  }

window.importBulkInterviewEventFromJSON = (array) ->
  {
    id: array[0],
    bulk_interview_id: array[1],
    event_id: array[2]
  }

window.importClientFromJSON = (array) ->
  {
    id: array[0],
    active: array[1],
    name: array[2],
    company_type: array[3],
    address: array[4],
    phone_no: array[5],
    email: array[6],
    accountant_email: array[7],
    flair_contact: array[8],
    primary_client_contact_id: array[9],
    terms_date_sent: (val = array[10]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    terms_date_received: (val = array[11]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    terms_client_contact_id: array[12],
    safety_date_sent: (val = array[13]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    safety_date_received: (val = array[14]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    safety_client_contact_id: array[15],
    notes: array[16],
    invoice_notes: array[17]
  }

window.importClientContactFromJSON = (array) ->
  {
    id: array[0],
    active: array[1],
    first_name: array[2],
    last_name: array[3],
    mobile_no: array[4],
    email: array[5],
    client_id: array[6],
    account_status: array[7]
  }

window.importEventFromJSON = (array) ->
  {
    id: array[0],
    name: array[1],
    display_name: array[2],
    category_id: array[3],
    date_start: (val = array[4]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    date_end: (val = array[5]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    public_date_start: (val = array[6]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    public_date_end: (val = array[7]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    date_callback_due: (val = array[8]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    status: array[9],
    fullness: array[10],
    blurb_legacy: array[11],
    blurb_title: array[12],
    blurb_subtitle: array[13],
    blurb_opening: array[14],
    blurb_closing: array[15],
    blurb_job: array[16],
    blurb_shift: array[17],
    blurb_wage_additional: array[18],
    blurb_uniform: array[19],
    blurb_transport: array[20],
    leader_general: array[21],
    leader_meeting_location: array[22],
    leader_meeting_location_coords: array[23],
    leader_accomodation: array[24],
    leader_job_role: array[25],
    leader_arrival_time: array[26],
    leader_flair_phone_no: array[27],
    leader_handbooks: array[28],
    leader_staff_job_roles: array[29],
    leader_staff_arrival: array[30],
    leader_energy: array[31],
    leader_uniform: array[32],
    leader_food: array[33],
    leader_transport: array[34],
    leader_client_contact_id: array[35],
    location: array[36],
    address: array[37],
    post_code: array[38],
    region_id: array[39],
    website: array[40],
    notes: array[41],
    site_manager: array[42],
    office_manager_id: array[43],
    photo: array[44],
    show_in_history: array[45],
    show_in_public: array[46],
    show_in_home: array[47],
    show_in_payroll: array[48],
    show_in_time_clocking_app: array[49],
    remove_task: array[50],
    staff_needed: array[51],
    additional_staff: array[52],
    gigs_count: array[53],
    is_concert: array[54],
    jobs_description: array[55],
    accom_status: array[56],
    accom_hotel_name: array[57],
    accom_address: array[58],
    accom_phone: array[59],
    accom_parking: array[60],
    accom_total_cost: array[61],
    accom_booking_ref: array[62],
    accom_notes: array[63],
    accom_room_info: array[64],
    accom_distance: array[65],
    accom_booking_dates: array[66],
    accom_parking: array[67],
    accom_wifi: array[68],
    accom_cancellation_policy: array[69],
    accom_payment_method: array[70],
    accom_booked_by: array[71],
    accom_booking_dates: array[72],
    expense_notes: array[73],
    post_notes: array[74],
    default_job_id: array[75],
    default_location_id: array[76],
    default_assignment_id: array[77],
    require_training_ethics: array[78],
    require_training_customer_service: array[79],
    require_training_health_safety: array[80],
    require_training_sports: array[81],
    require_training_bar_hospitality: array[82],
    admin_completed: array[83],
    paid_breaks: array[84],
    show_in_ongoing: array[85],
    show_in_featured: array[86],
    show_in_planner: array[87],
    requires_booking: array[88],
    send_scheduled_to_work_auto_email: array[89],
    size_id: array[90],
    reviewed_by_manager: array[91],
    accom_booking_via: array[92],
    accom_refund_date: (val = array[93]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    is_restricted: array[94],
    has_bar: array[95],
    has_sport: array[96],
    has_hospitality: array[97],
    has_festivals: array[98],
    has_office: array[99],
    has_retail: array[100],
    has_warehouse: array[101],
    has_promotional: array[102],
    shift_start_time: array[103],
    featured_job: array[104],
    request_message: array[105],
    spares_message: array[106],
    applicants_message: array[107],
    action_message: array[108],
    other_info: array[109],
    created_at: (val = array[110]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2], ymd[3], ymd[4], ymd[5]))))
    senior_manager_id: array[111],
  }

window.importEventClientFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    client_id: array[2]
  }

window.importEventDateFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    date: (val = array[2]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    tax_week_id: array[3]
  }

window.importEventSizeFromJSON = (array) ->
  {
    id: array[0],
    name: array[1]
  }

window.importEventTaskFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    officer_id: array[2],
    second_officer_id: array[3],
    template_id: array[4],
    task: array[5],
    notes: array[6],
    due_date: (val = array[7]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    completed: array[8],
    completed_date: (val = array[9]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    additional_notes: array[10],
    manager_notes: array[11],
    confirmed: array[12],
    tax_week_id: array[13],
    task_completed: array[14]
  }

window.importEventTaskTemplateFromJSON = (array) ->
  {
    id: array[0],
    task: array[1],
    notes: array[2]
  }

window.importExpenseFromJSON = (array) ->
  {
    id: array[0],
    name: array[1],
    event_id: array[2],
    cost: array[3],
    notes: array[4]
  }

window.importFaqEntryFromJSON = (array) ->
  {
    id: array[0],
    question: array[1],
    answer: array[2],
    position: array[3],
    topic: array[4]
  }

window.importGigFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    prospect_id: array[2],
    job_id: array[3],
    location_id: array[4],
    notes: array[5],
    rating: array[6],
    status: array[7],
    miscellaneous_boolean: array[8],
    published: array[9]
  }

window.importGigAssignmentFromJSON = (array) ->
  {
    id: array[0],
    gig_id: array[1],
    assignment_id: array[2]
  }

window.importGigRequestFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    gig_id: array[2],
    prospect_id: array[3],
    created_at: array[4],
    spare: array[5],
    is_best: array[6],
    left_voice_message: array[7],
    email_status: array[8],
    texted: array[9],
    job_id: array[10],
    notes: array[11]
  }

window.importGigTagFromJSON = (array) ->
  {
    id: array[0],
    gig_id: array[1],
    tag_id: array[2]
  }

window.importGigTaxWeekFromJSON = (array) ->
  {
    id: array[0],
    gig_id: array[1],
    tax_week_id: array[2],
    assignment_email_type: array[3],
    assignment_email_template_id: array[4],
    confirmed: array[5]
  }

window.importInterviewFromJSON = (array) ->
  {
    id: array[0],
    interview_slot_id: array[1],
    interview_block_id: array[2],
    time_type: array[3],
    telephone_call_interview: array[4],
    video_call_interview: array[5],
    prospect_id: array[6]
  }

window.importInterviewBlockFromJSON = (array) ->
  {
    id: array[0],
    bulk_interview_id: array[1],
    date: (val = array[2]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    time_start: array[3],
    time_end: array[4],
    slot_mins: array[5],
    number_of_applicants_per_slot: array[6],
    is_morning: array[7],
    morning_applicants: array[8],
    is_afternoon: array[9],
    afternoon_applicants: array[10],
    is_evening: array[11],
    evening_applicants: array[12],
    morning_interviews: array[13],
    afternoon_interviews: array[14],
    evening_interviews: array[15]
  }

window.importInterviewSlotFromJSON = (array) ->
  {
    id: array[0],
    interview_block_id: array[1],
    time_start: array[2],
    time_end: array[3],
    interviews_count: array[4]
  }

window.importInvoiceFromJSON = (array) ->
  {
    id: array[0],
    event_client_id: array[1],
    who: array[2],
    status: array[3],
    date_emailed: (val = array[4]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    tax_week_id: array[5]
  }

window.importJobFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    name: array[2],
    public_name: array[3],
    description: array[4],
    pay_17_and_under: array[5],
    pay_21_and_over: array[6],
    pay_18_and_over: array[7],
    pay_25_and_over: array[8],
    number_of_positions: array[9],
    shift_information: array[10],
    uniform_information: array[11],
    other_information: array[12],
    new_description: array[13],
    include_in_description: array[14]
  }

window.importLibraryItemFromJSON = (array) ->
  {
    id: array[0],
    name: array[1],
    filename: array[2]
  }

window.importLocationFromJSON = (array) ->
  {
    id: array[0],
    name: array[1],
    event_id: array[2],
    type: array[3]
  }

window.importLogEntryFromJSON = (array) ->
  {
    id: array[0],
    type: array[1],
    data: JSON.parse(array[2])
  }

window.importOfficerFromJSON = (array) ->
  {
    id: array[0],
    first_name: array[1],
    last_name: array[2],
    email: array[3],
    role: array[4],
    active_operational_manager: array[5],
    senior_manager: array[6]
  }

window.importPayWeekFromJSON = (array) ->
  {
    id: array[0],
    job_id: array[1],
    event_id: array[2],
    prospect_id: array[3],
    tax_week_id: array[4],
    monday: array[5],
    tuesday: array[6],
    wednesday: array[7],
    thursday: array[8],
    friday: array[9],
    saturday: array[10],
    sunday: array[11],
    rate: array[12],
    deduction: array[13],
    allowance: array[14],
    status: array[15],
    type: array[16]
  }

window.importPostAreaFromJSON = (array) ->
  {
    id: array[0],
    region_id: array[1],
    subcode: array[2],
    latitude: array[3],
    longitude: array[4]
  }

window.importProspectFromJSON = (array) ->
  {
    id: array[0],
    gender: array[1],
    status: array[2],
    client_id: array[3],
    email: array[4],
    first_name: array[5],
    last_name: array[6],
    date_of_birth: (val = array[7]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    nationality_id: array[8],
    country: array[9],
    address: array[10],
    address2: array[11],
    city: array[12],
    post_code: array[13],
    region_id: array[14],
    mobile_no: array[15],
    home_no: array[16],
    emergency_no: array[17],
    emergency_name: array[18],
    tax_choice: array[19],
    ni_number: array[20],
    bank_account_name: array[21],
    bank_sort_code: array[22],
    bank_account_no: array[23],
    bar_experience: array[24],
    bar_license_type: array[25],
    bar_license_no: array[26],
    bar_license_issued_by: array[27],
    bar_license_expiry: (val = array[28]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    training_type: array[29],
    agreed_terms: array[30],
    id_number: array[31],
    visa_number: array[32],
    id_type: array[33],
    id_expiry: (val = array[34]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    visa_issue_date: (val = array[35]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    visa_expiry: (val = array[36]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    visa_indefinite: array[37],
    id_sighted: (val = array[38]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    notes: array[39],
    registered: (val = array[40]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    good_sport: array[41],
    good_bar: array[42],
    good_promo: array[43],
    good_hospitality: array[44],
    good_management: array[45],
    date_start: (val = array[46]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    date_end: (val = array[47]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    student_loan: array[48],
    applicant_status: array[49],
    rating: array[50],
    photo: array[51],
    has_large_photo: array[52],
    prefers_in_person: array[53],
    prefers_phone: array[54],
    prefers_skype: array[55],
    prefers_facetime: array[56],
    preferred_phone: array[57],
    preferred_skype: array[58],
    preferred_facetime: array[59],
    prefers_morning: array[60],
    prefers_afternoon: array[61],
    prefers_early_evening: array[62],
    prefers_midweek: array[63],
    prefers_weekend: array[64],
    performance_notes: array[65],
    manager_level: array[66],
    last_login: (val = array[67]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    training_ethics: array[68],
    training_customer_service: array[69],
    training_health_safety: array[70],
    training_sports: array[71],
    training_bar_hospitality: array[72],
    send_marketing_email: array[73],
    qualification_food_health_2: array[74],
    qualification_dbs: array[75],
    headquarter: array[76],
    texted_date: (val = array[77]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    email_status: array[78],
    missed_interview_date: (val = array[79]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    left_voice_message: array[80],
    flair_image: array[81],
    experienced: array[82],
    chatty: array[83],
    confident: array[84],
    language: array[85],
    big_teams: array[86],
    all_teams: array[87],
    prospect_character: array[88],
    team_notes: array[89],
    bespoke: array[90],
    flag_photo: array[91],
    cancelled_contracts: array[92],
    cancelled_eighteen_hrs_contracts: array[93],
    no_show_contracts: array[94],
    non_confirmed_contracts: array[95],
    held_spare_contracts: array[96],
    completed_contracts: array[97],
    dbs_certificate_number: array[98],
    dbs_issue_date: (val = array[99]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    has_bar_and_hospitality: array[100],
    has_sport_and_outdoor: array[101],
    has_promotional_and_street_marketing: array[102],
    has_merchandise_and_retail: array[103],
    has_reception_and_office_admin: array[104],
    has_festivals_and_concerts: array[105],
    has_bar_management_experience: array[106],
    has_staff_leadership_experience: array[107],
    has_hospitality_marketing: array[108],
    has_warehouse_marketing: array[109],
    warehouse_skill: array[110],
    hospitality_skill: array[111],
    bar_skill: array[112],
    sport_skill: array[113],
    festival_skill: array[114],
    office_skill: array[115],
    promo_skill: array[116],
    retail_skill: array[117],
    bar_manager_skill: array[118],
    staff_leader_skill: array[119],
    city_of_study: array[120],
    has_c19_test: array[121],
    is_clean: array[122],
    is_convicted: array[123],
    c19_tt_at: (val = array[124]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    test_site_code: array[125],
    created_at: (val = array[126]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2], ymd[3], ymd[4], ymd[5])))),
    share_code: array[127],
    dbs_qualification_type: array[128],
    condition: array[129]
  }

window.importQuestionnaireFromJSON = (array) ->
  {
    id: array[0],
    prospect_id: array[1],
    enjoy_working_on_team: array[2],
    interested_in_bar: array[3],
    promotions_experience: array[4],
    retail_experience: array[5],
    interested_in_marshal: array[6],
    staff_leadership_experience: array[7],
    bar_management_experience: array[8],
    evening_shifts_work: array[9],
    day_shifts_work: array[10],
    weekends_work: array[11],
    week_days_work: array[12],
    contact_via_whatsapp: array[13],
    contact_via_text: array[14],
    contact_via_email: array[15],
    contact_via_telephone: array[16],
    scottish_personal_licence_qualification: array[17],
    dbs_qualification: array[18],
    food_health_level_two_qualification: array[19],
    english_personal_licence_qualification: array[20],
    has_bar_and_hospitality: array[21],
    has_sport_and_outdoor: array[22],
    has_promotional_and_street_marketing: array[23],
    has_merchandise_and_retail: array[24],
    has_reception_and_office_admin: array[25],
    has_festivals_and_concerts: array[26],
    team_leader_experience: array[27]
  }

window.importQuoteRequestFromJSON = (array) ->
  {
    id: array[0],
    name: array[1],
    company_name: array[2],
    telephone: array[3],
    email: array[4],
    contract_name: array[5],
    location: array[6],
    post_code: array[7],
    start_date: (val = array[8]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2], ymd[3], ymd[4], ymd[5])))),
    finish_date: (val = array[9]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2], ymd[3], ymd[4], ymd[5])))),
    job_position: array[10],
    full_range: array[11],
    number_of_people: array[12],
    wage_rates: array[13],
    other_facts: array[14]
  }

window.importRegionFromJSON = (array) ->
  {
    id: array[0],
    name: array[1]
  }

window.importShiftFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    tax_week_id: array[2],
    date: (val = array[3]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    time_start: array[4],
    time_end: array[5]
  }

window.importTagFromJSON = (array) ->
  {
    id: array[0],
    name: array[1],
    event_id: array[2]
  }

window.importTaxWeekFromJSON = (array) ->
  {
    id: array[0],
    date_start: (val = array[1]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    date_end: (val = array[2]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    tax_year_id: array[3],
    week: array[4]
  }

window.importTaxYearFromJSON = (array) ->
  {
    id: array[0],
    date_start: (val = array[1]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    date_end: (val = array[2]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2]))))
  }

window.importTeamLeaderRoleFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    user_id: array[2],
    user_type: array[3],
    enabled: array[4]
  }

window.importTextBlockFromJSON = (array) ->
  {
    id: array[0],
    key: array[1],
    type: array[2],
    title: array[3],
    status: array[4],
    thumbnail: array[5],
    updated_at: (val = array[6]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2], ymd[3], ymd[4], ymd[5])))),
    contents: array[7]
  }

window.importTimeClockReportFromJSON = (array) ->
  {
    id: array[0],
    event_id: array[1],
    date: (val = array[2]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2])))),
    user_id: array[3],
    user_type: array[4],
    tax_week_id: array[5],
    status: array[6],
    notes: array[7],
    client_notes: array[8],
    client_rating: array[9],
    signed_by_name: array[10],
    signed_by_job_title: array[11],
    signed_by_company_name: array[12],
    signature: array[13],
    date_submitted: (val = array[14]; val && (ymd = val.split(/[- :.T]/); (new Date(ymd[0], ymd[1]-1, ymd[2], ymd[3], ymd[4], ymd[5]))))
  }

window.importTimesheetEntryFromJSON = (array) ->
  {
    id: array[0],
    gig_assignment_id: array[1],
    tax_week_id: array[2],
    time_start: array[3],
    time_end: array[4],
    break_minutes: array[5],
    status: array[6],
    rating: array[7],
    notes: array[8],
    invoiced: array[9],
    time_clock_report_id: array[10]
  }

window.importUnworkedGigAssignmentFromJSON = (array) ->
  {
    id: array[0],
    gig_id: array[1],
    assignment_id: array[2],
    reason: array[3]
  }

window.importTables = (tables, callback) ->
  if records = tables['accounts']
    callback('accounts', records.map(importAccountFromJSON))
  if records = tables['action_takens']
    callback('action_takens', records.map(importActionTakenFromJSON))
  if records = tables['assignments']
    callback('assignments', records.map(importAssignmentFromJSON))
  if records = tables['assignment_email_templates']
    callback('assignment_email_templates', records.map(importAssignmentEmailTemplateFromJSON))
  if records = tables['bookings']
    callback('bookings', records.map(importBookingFromJSON))
  if records = tables['bulk_interviews']
    callback('bulk_interviews', records.map(importBulkInterviewFromJSON))
  if records = tables['bulk_interview_events']
    callback('bulk_interview_events', records.map(importBulkInterviewEventFromJSON))
  if records = tables['clients']
    callback('clients', records.map(importClientFromJSON))
  if records = tables['client_contacts']
    callback('client_contacts', records.map(importClientContactFromJSON))
  if records = tables['events']
    callback('events', records.map(importEventFromJSON))
  if records = tables['event_clients']
    callback('event_clients', records.map(importEventClientFromJSON))
  if records = tables['event_dates']
    callback('event_dates', records.map(importEventDateFromJSON))
  if records = tables['event_sizes']
    callback('event_sizes', records.map(importEventSizeFromJSON))
  if records = tables['event_tasks']
    callback('event_tasks', records.map(importEventTaskFromJSON))
  if records = tables['event_task_templates']
    callback('event_task_templates', records.map(importEventTaskTemplateFromJSON))
  if records = tables['expenses']
    callback('expenses', records.map(importExpenseFromJSON))
  if records = tables['faq_entries']
    callback('faq_entries', records.map(importFaqEntryFromJSON))
  if records = tables['gigs']
    callback('gigs', records.map(importGigFromJSON))
  if records = tables['gig_assignments']
    callback('gig_assignments', records.map(importGigAssignmentFromJSON))
  if records = tables['gig_requests']
    callback('gig_requests', records.map(importGigRequestFromJSON))
  if records = tables['gig_tags']
    callback('gig_tags', records.map(importGigTagFromJSON))
  if records = tables['gig_tax_weeks']
    callback('gig_tax_weeks', records.map(importGigTaxWeekFromJSON))
  if records = tables['interviews']
    callback('interviews', records.map(importInterviewFromJSON))
  if records = tables['interview_blocks']
    callback('interview_blocks', records.map(importInterviewBlockFromJSON))
  if records = tables['interview_slots']
    callback('interview_slots', records.map(importInterviewSlotFromJSON))
  if records = tables['invoices']
    callback('invoices', records.map(importInvoiceFromJSON))
  if records = tables['jobs']
    callback('jobs', records.map(importJobFromJSON))
  if records = tables['library_items']
    callback('library_items', records.map(importLibraryItemFromJSON))
  if records = tables['locations']
    callback('locations', records.map(importLocationFromJSON))
  if records = tables['admin_log_entries']
    callback('admin_log_entries', records.map(importLogEntryFromJSON))
  if records = tables['officers']
    callback('officers', records.map(importOfficerFromJSON))
  if records = tables['pay_weeks']
    callback('pay_weeks', records.map(importPayWeekFromJSON))
  if records = tables['post_areas']
    callback('post_areas', records.map(importPostAreaFromJSON))
  if records = tables['prospects']
    callback('prospects', records.map(importProspectFromJSON))
  if records = tables['questionnaires']
    callback('questionnaires', records.map(importQuestionnaireFromJSON))
  if records = tables['quote_requests']
    callback('quote_requests', records.map(importQuoteRequestFromJSON))
  if records = tables['regions']
    callback('regions', records.map(importRegionFromJSON))
  if records = tables['shifts']
    callback('shifts', records.map(importShiftFromJSON))
  if records = tables['tags']
    callback('tags', records.map(importTagFromJSON))
  if records = tables['tax_weeks']
    callback('tax_weeks', records.map(importTaxWeekFromJSON))
  if records = tables['tax_years']
    callback('tax_years', records.map(importTaxYearFromJSON))
  if records = tables['team_leader_roles']
    callback('team_leader_roles', records.map(importTeamLeaderRoleFromJSON))
  if records = tables['text_blocks']
    callback('text_blocks', records.map(importTextBlockFromJSON))
  if records = tables['time_clock_reports']
    callback('time_clock_reports', records.map(importTimeClockReportFromJSON))
  if records = tables['timesheet_entries']
    callback('timesheet_entries', records.map(importTimesheetEntryFromJSON))
  if records = tables['unworked_gig_assignments']
    callback('unworked_gig_assignments', records.map(importUnworkedGigAssignmentFromJSON))


