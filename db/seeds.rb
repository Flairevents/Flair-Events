# encoding: UTF-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

TextBlock.create(:key => 'welcome-message', :type => 'page', :contents => "Flair is a unique staffing company that provides staff for music and sporting events all over the UK. Flair helps run huge internationally renowned weekend festivals like the V festivals to smaller, more unique events such as the Rat Race Adventure Series.

  We don't just drop staff off at the door. Essentially we are a team of organisers that manage staff from start to finish. We take care of staff every step of the way from the interview, to the event, to getting you home after a great weekend.

  We are always looking for new staff to help us at events. We need active individuals from all walks of life that want to join our fun and vibrant team. So if you are a team player and love the idea of working at energetic, busy music events or exciting promotional and sporting events then go to our Events Page.

  Notes on employment: Seeking rewarding and interesting work? Not the normal 9-5 and want the flexibility to select your contacts? Want a company that treats you with respect? Want to get involved in some of the UK's top events from festivals, music concerns, adventure racing, inner city sports to promotional work? Then Flair is the link you seek!

  Note to clients: Seeking a staffing provider to demonstrate the same skills, loyalty, and enthusiasm as your core team? Flair is proud of over 12 years service to the event industry, providing the complete staffing experience. We offer solutions, not problems, with service beyond your expectations.

  If you want Flair to staff your event, take a look at our \"Need Staff?\" page.

  Cheers,
  The Flair Team")

TextBlock.create(:key => 'about-us', :type => 'page', :contents => "Established in the year 2000, Flair has an impressive track record of delivering organised and impressively managed staffing teams to some of the UK's national events -- from music festivals, one day concerts, and adventure sports to inner city charity events. From national promotional tours and city sampling teams to experienced bar crew at boutique events. Flair has the knowledge, experience, and exceptional history of delivering every time.

  To date, Flair has been involved with over 730 events, which have created enough work to see 26,000 people pass through our database. We have the skills to supply dual venues with over 1500 people, back to back weekends on a national UK level, to small, one-person front-of-house promo style contacts.")

TextBlock.create(:key => 'company-address', :type => 'page', :contents => '90 Buxton Road, Congleton, Cheshire CW12 2DY')
TextBlock.create(:key => 'company-tel',     :type => 'page', :contents => '01925 368 368')
TextBlock.create(:key => 'company-mobile',  :type => 'page', :contents => "07961 988 644\n07933 614 34")

TextBlock.create(:key => 'privacy', :type => 'page', :contents => 'Privacy boilerplate will go here')
TextBlock.create(:key => 'cookies', :type => 'page', :contents => "In the United States and Canada a cookie is a small, flat, baked treat, usually containing fat, flour, eggs and sugar. In Scotland the term cookie is sometimes used to describe a plain bun. In most English-speaking countries outside North America, including the United Kingdom, the most common word for a small, flat, baked treat, usually containing fat, flour, eggs and sugar is biscuit and the term cookie is often used to describe drop cookies exclusively. However, in many regions both terms are used, such as the American-inspired Maryland Cookies, while in others the two words have different meanings.\n\nCookies are most commonly baked until crisp or just long enough that they remain soft, but some kinds of cookies are not baked at all. Cookies are made in a wide variety of styles, using an array of ingredients including sugars, spices, chocolate, butter, peanut butter, nuts or dried fruits. The softness of the cookie may depend on how long it is baked.")

TextBlock.create(key: 'funky-popup', type: 'page', contents: 'Pop-up contents here')
TextBlock.create(key: 'history-message', type: 'page', contents: 'History page contents here')

TextBlock.create(key: 'sport-history-intro', type: 'page', contents: 'Paragraph about Sporting Events')
TextBlock.create(key: 'music-history-intro', type: 'page', contents: 'Paragraph about Music Events')
TextBlock.create(key: 'promo-history-intro', type: 'page', contents: 'Paragraph about Promo Events')
TextBlock.create(key: 'corporate-history-intro', type: 'page', contents: 'Paragraph about Corporate Events')

TextBlock.create(key: 'confirmed-events-paragraph', type: 'page', contents: 'You are confirmed for the below events. We will be sending e-mails with more information about each event closer to its date. If you have to cancel your attendance for any of these events for any reason, please call the office as there is always someone else would love to work and we can\'t fill the space if we don\'t know you are not coming.')
TextBlock.create(key: 'pending-events-paragraph', type: 'page', contents: "Hold tight, the following events you have chosen have been sent to the office and are awaiting the Flair office team to confirm your application")

["London", "Yorkshire", "Wales", "Northeast", "Northwest", "Southeast", "Southwest", "Eastern", "Midlands", "Scotland", "Ireland", "East Midlands"].each do |region|
  Region.create!(:name => region)
end

["Afghanistan", "Albania", "Angola", "Argentina", "Armenia", "Australia", "Austria",
  "Bangladesh", "Barbados", "Belarus", "Belgium", "Bolivia", "Botswana",
  "Boznia and Herzegovina", "Brazil", "Bulgaria", "Burundi", "Cameroon", "Canada",
  "Chile", "China", "Colombia", "Congo", "Costa Rica", "Croatia", "Cyprus", "Czech Republic",
  "Denmark", "Dominican Republic", "Ecuador", "Egypt", "Estonia", "Ethiopia", "Finland",
  "France", "Gambia", "Germany", "Ghana", "Greece", "Grenada", "Guinea", "Hong Kong", "Hungary",
  "India", "Indonesia", "Iran", "Iraq", "Ireland", "Israel", "Italy", "Ivory Coast",
  "Jamaica", "Japan", "Kazakhstan", "Kenya", "Latvia", "Liberia", "Lithuania",
  "Macedonia", "Madagascar", "Malawi", "Malaysia", "Mauritius", "Mexico", "Moldova", "Mongolia",
  "Morocco", "Mozambique", "Namibia", "Nepal", "Netherlands", "New Zealand", "Nigeria",
  "North Korea", "Norway", "Pakistan", "Panama", "Peru", "Philippines", "Poland",
  "Portugal", "Romania", "Russia", "Rwanda", "Sierra Leone", "Singapore", "Slovakia",
  "Slovenia", "Somalia", "South Africa", "South Korea", "Spain", "Sri Lanka", "Swaziland", "Sweden",
  "Switzerland", "Syria", "Taiwan", "Tajikistan", "Tanzania", "Thailand",
  "Trinidad and Tobago", "Tunisia", "Turkey", "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom",
  "United States", "Uruguay", "Uzbekistan", "Venezuela", "Vietnam", "Zambia", "Zimbabwe"].each do |country|
  Country.create!(name: country)
end

Report.create!(name: 'email_list', print_name: 'E-mail List', table: 'prospects',
               fields: ['name', 'email'])
Report.create!(name: 'phone_list', print_name: 'Phone List',  table: 'prospects',
               fields: ['name', 'mobile_no', 'home_no', 'emergency_no'])
Report.create!(name: 'call_list',  print_name: 'Call List',   table: 'prospects',
               fields: ['name', 'mobile_no', 'home_no', 'email'])

Report.create!(name: 'reg_sheet',       print_name: 'Reg Sheet',       table: 'gigs',
               fields: ['name', 'has_tax', 'has_id', 'has_ni', 'location', 'job_name', 'transport', 'notes', 'avg_rating'],
               row_numbers: true)
Report.create!(name: 'peoples_details', print_name: 'Peoples Details', table: 'gigs',
               fields: ['name', 'mobile_no', 'home_no', 'email', 'bank_sort_code', 'bank_account_no', 'bank_name', 'location', 'transport'],
               row_numbers: true)
Report.create!(name: 'tel_no',          print_name: 'Tel List',        table: 'gigs',
               fields: ['name', 'home_no', 'mobile_no', 'emergency_no'])
Report.create!(name: 'gigs_call_list',  print_name: 'Call List',       table: 'gigs',
               fields: ['name', 'email', 'mobile_no', 'location', 'job_name', 'transport'])


FaqEntry.create!(
  question: 'What job roles does Flair offer?',
  answer: 'Since 2000, Flair has provided a bag full of different job roles and exciting positions within the UK festival and event industry. The general rule is Bar staffing teams from stock runners and drink servers to Managers and Supervisors. We also are leaders in supplying teams of marshals and stewards to sporting events from mud runs, bike events to inner city triathlons, promotional tours and street samplers to the more obscure job roles like wristband activators and extras to films sets!',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'What experience or qualifications do I need to apply?',
  answer: 'It’s got to be said some events will of course require a person with skills and experience but in general it’s about you. If you have a “can do” attitude, positive outlook and the willingness to succeed in anything you turn your hand too then we want you!
90% of our work requires customer interaction - so good communication skills are required.
Event work will always require a degree of flexibility so come with an open mind and you will walk away with great energy and experience.
If you have experience of management, supervisor or staffing team leader within the bar industry and/or mass sporting participation environment then we want to hear from you.',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'The Flair Viewpoint',
  answer: 'We believe temporary event work should not be a chore. Our mission is to create a great working environment for everyone.',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'I have worked for Flair before, how do I register my interest in future events?',
  answer: '‘Login’ to your staff zone, you should have received an email from us during the big “flair embracing technology” change over? If you haven’t simply call our office then ‘Login’, update your details, select events etc. We will then start bouncing back emails with information.
What do you think? Like the new Flair method? We hope it’s much easier and also gives you greater control over the events you work. Feedback is always welcome!',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'I’ve not worked for Flair before, where do I sign up?',
  answer: 'You can ‘Register’ with us by selecting the ‘Login/Register’ button at the top of our website.
You will be sent an email with a temporary password. Use this to “Login”, fill in your details as requested and select events of interest. Please be practical and consider your travel arrangements.
Once interviewed and accepted to work for Flair you can “Login” to your own personal staff Zone at any time. Your staff zone will then give you greater control over the events you want to work, events you are working and events you have requested to work and pending acceptance. ',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'I have registered on the website, what happens now?',
  answer: 'After you have ‘Registered’ we will contact you with regards to an interview/recruitment method. You may get invited to attend a face-to-face interview or a telephone interview to assess whether you are an ideal candidate.
We fill our events from people already active on our database then start to bring in new people.
Depending on the event and time of year our recruitment drives will start anything from 1 month to 1 week before each event.  Once you have your ‘Login’ details and applied we have your application so please be patient and stand by.
We recruit on event by event bases. Once interviewed and selected for one event you’re more than welcome to work any event and remain on our books as a temporary event employee.
We always like to recruit local to each event (to keep your travel costs low). However, for bigger events we target large cities, if staffing numbers require this and supply a coach. We welcome applicants on a national scale but please consider your travel options and cost.
Please also see: What should I bring to an interview?  What will I be asked in a Telephone Interview?',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'My friend wants to work, but has not had an interview?',
  answer: 'Please direct them towards the ‘Login/Register’ button at the top of our website. They will need to fill out all the information required and select the events they wish to work. We will then contact them about joining the team when recruiting per event.',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'What to expect from your Telephone Interview…',
  answer: 'This will take the form of an informal chat lasting 5-15 minutes. Even though it’s informal please sell yourself, expect questions and demonstrate your enthusiasm.  You will receive a formal email with a suggested window to call. If this time is not suitable please try and call with one day either side or contact our office for a new time slot.
Questions you may get asked, but are not exhaustive:
Why do you want to work with us?
What interests you about the event you are applying to work?
What experience do you have?
What do you think we are looking for in our event team?
What are you doing at the moment, education/career?
Please Note: You’ll hear from us 1month - 1 week before an event and we can only perform a telephone interview if you have thoroughly filled out your online profile.
Please note if you have “Registered” to work with Flair, but then unable to work, your registered form and details will be deleted after 12months of inactivity. All data covered under data protection laws and are safely stored.',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'What should I bring to a live face to face recruitment day?',
  answer: 'Yourself, a positive attitude, open mind approach and of course a smile. As a staffing agency we are bound by law to comply with UK recruitment law specifications and to ensure all our employees are legally allowed to work within the UK. Before you work for Flair you must provide the following documentation:
Identification - We need to see it, photocopy or upload a scan & we then retain a copy for 2 years after you have worked for Flair.  Please provide ONE of the following:
A) Valid passport – within 12 months of expiry date
Which would also include your working visa if non EU
B) A Birth Certificate + National Insurance Evidence & any photo ID
N.I evidence could be – P45, P60, NI card
Also bring and know:
National Insurance number
Bank details for fast payment: Sort code and Account number
A passport sized photo
Completed application form & signed contract of employment
Pen & paper
Any other supporting documentation we will inform you of before the interview.',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'What happens after the Interview?',
  answer: 'After completing your online profile and interview, we will then except you and ‘green light’ your online profile.  You will be added to events we feel you’re suitable to join and the information email stream will begin.',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'What happens between being accepted and attending an event?',
  answer: 'You will be informed of an event \'Call Back Day,\' this is the day you have to verbally call to confirm your attendance, order camping equipment, book coaches, suggest friends you wish to work with etc. ONLY after this telephone call is your job 100% confirmed.
In this day of faceless texting and emails we like the human touch, so before every event please expect to confirm your attendance and receive odd information from us to back up emails.
You will then be sent a final information email with any additional event information that we think you need to know before the event. ',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'How old do I need to be to work with Flair?',
  answer: 'Flair employs people of all ages however; some restrictions are in place due to client requirements or licensing or practicalities of events may restrict anyone under the age of 18.
Communication – let us know! There may be another work area we can assign you to that doesn’t involve the sale of alcohol
Guardian – it is preferable that if you are under the age of 18 you come to the event with a responsible older family member / friend
Be responsible – this goes for everyone! Be responsible for your own safety and be mindful of the safety of others!
Other work – It may not be possible to assign you to a particular event but rest assured we have loads of events all summer long that may be more appropriate!',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'Do I have to pay a deposit to work with Flair?',
  answer: 'NO NO NO!! - Unlike many other companies, we do not ask you to pay a deposit – we think that’s really mean and slightly unsure if it’s legal.
However it’s not free –
Event Pass - By agreeing to work the event you have entered into a contract with Flair. The wristband is entrusted to you during the duration of the event, it doesn’t belong to you. If you abscond from your shift without informing Flair Staff Management, our clients can and do prosecute. You could be charged for the wristband, admin fees & court costs
Genuine reason for leaving - Inform the Flair event office verbally on the day. If you fail to inform us you will also be prosecuted. Remember, we have heard several stories over the years, many very unbelievable, some very stupid and some honest but the person never thought to let us know.
It could cost you more! – So if you’re broke & you want a free ride into a festival, don’t do it through Flair, its dishonest & could cost you more!',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'What Identification is required?',
  answer: 'As a staffing agency we are bound by law to comply with UK recruitment law specifications and to ensure all our employees are legally allowed to work within the UK. Before you work for Flair you must provide the following documentation:
Identification - We need to see it, photocopy it & then retain a copy for 1 year after you have worked for Flair. Provide ONE of the following:
A) Valid passport – within 12 months of expiry date
Which would also include your working visa if non EU
B) A Birth Certificate + National Insurance Evidence and any Photo ID
N.I evidence could be – P45, P60, NI card',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'Do you accept a driving licence as photo ID?',
  answer: 'No!! – Not on its own, only along with a full UK Birth Certificate.  Under employment law, a driving licence alone is not a valid form of ID. Neither is a student card, bank card or library card. Please stick to the documents we have specified & you can’t go wrong! ',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'Why do you ask me for a copy of my passport, UK Birth Certificate and NI evidence or working visa?',
  answer: 'We require, from everyone that comes to work for us, proof of right to work in the UK. We are required by law to retain a copy of your documents for 2 calendar years after you have worked for us. It’s simple everyone who is legally allowed to work...can, but needs to demonstrate this by showing us their ID. All scanned ID via your “Staff Zone” upload is viewed and confirmed. Then stored encrypted in a big magic Flair storage box in a cloud, it can only then be accessed via several passwords that only Clare and our database designer know if requested by border control. Every 2 years you will be prompted to scan across new evidence. ',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'Why do I have to phone the office on \'Call Back Day\' before each event? Have I not already accepted the job?',
  answer: 'Call us old fashioned-Verbal confirmation from our Staff is required so we have the knowledge that you will be there. Its temporary work, plans change, we understand this so we want to hear that you will 100% be working and accept the contract. Please also inform us if you are unable to make the event.
Call back day is also important as you will receive the meeting location, time and any additional information we think you need to know.',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'I didn’t call on Call Back Day, what happens now?',
  answer: 'Best to check – Contact us to let us know you still want to work in case we have spaces available.
No contact / No work – If you don’t make any contact at all, you cannot work. It’s just like any other job in the world!
Missed opportunity – We may now be fully staffed, sorry.',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'I can’t work anymore. So need to cancel?',
  answer: 'More than two weeks prior to an event:
If you can no longer work an event, login to your account and cancel the event on the ‘Events Page’.
Within two weeks prior to an event:
Call us (01400 220022)/ text / email (work@flairevents.co.uk) Please always remember to put your full name, no name really does not help and we also have a few Sarah’s on our books!',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'I have selected a few events, when will I know if I am working?',
  answer: '“Login” to your Staff Zone page and head to your events page. At any time you will see what events you\'re working, what events you have worked and also what events are pending. We are working on a system of accepting requests daily via our very special bespoke shiny database dashboard! Every event we accept you for will result in an instant email of acceptance. Pending event requests will be indicated and noted the reasons why.',
  topic: 'recruitment')

FaqEntry.create!(
  question: 'I’m working at an event. How do I get the details?',
  answer: 'Our main form of communication is e-mail however; you will always be able to view event details via your “Staff Zone” once you are down to work that specific event.  Because we communicate in this manner it is very important you give us you correct e-mail and postal address.  Or go old fashion telephone; give us a call, we’re here for you and nice people honest. ',
  topic: 'event_info')
FaqEntry.create!(
  question: 'When will I receive event information?',
  answer: 'In addition to the initial event info on our website you will start receiving targeted event information emails once you have been selected to work. We pride ourselves in our pre-event information we give our teams and are fully aware how many other companies out there copy our methods of working and staff organisation!  We will arm you with all pre-event information you need to attend any venue.
There should be no sensible reason why, when arriving to any event venue for Flair you do not know where your meeting, what time, who your meeting and have a contact number.
There should be no sensible reason why, when arriving to any event venue for Flair you do not know you shift times, rates of pay, job roll and many other details that will enable you to embrace and enjoy your working time with us thoroughly.
So our pre-event information starts off being quite wide and general. Then as we get closer and as details are confirmed by clients we start to target information via emails ready for you to accept the working standard and regulations. This is all backed up via our call back days and verbal conformation your 100% committed to work.
We’re Humans! If in doubt, call us any time for a chat and questions can be answered in minutes compared to email tennis!',
  topic: 'event_info')
FaqEntry.create!(
  question: 'I have not received the event info email but my friends have?',
  answer: 'Check junk mail - often our emails end up there.
Incorrect email address - We may have your email address wrong on our database so go online and check your profile details. Also check you’re down to work this event.',
  topic: 'event_info')
FaqEntry.create!(
  question: 'What info is in the email?',
  answer: 'Call back day info – The day you MUST call back to confirm that you still want to work
Meeting points: Flair always gives you a meeting location. Always!
Event Mobiles: Flair will also always give you a contact number as we are there to help.
Shift Times – These are guidelines and can depend on the weather & crowd demand
Minimum Shift times: We are starting to confirm with all clients minimum confirmed payment terms for you guys, every event is different so please read all emails.
Wages – How much, when & by what means you are getting paid
Uniform – Generally, the uniform is: Black shoes, Black trousers (skirts or shorts), Black top (we provide an event T shirt)
Transport – Directions if driving, car park directions, coach drop off/pick up times/locations
Accommodation – It’s generally all about camping!
Food & Breaks: Some events food is supplied others you have to bring your own.',
  topic: 'event_info')
FaqEntry.create!(
  question: 'One week before is very short notice?',
  answer: 'When we know, you know – Sometimes we get our information from our client’s last minute.... and we mean last minute. Before accepting any event you get the general low down and then target info coming 10day to 1 week before each event or the day before!
Things change – To save time and confusion, we wait till we know the info we give you is as accurate as possible!
General information should be enough to help you make travel plans etc. Call us if any questions and we can try and help.',
  topic: 'event_info')
FaqEntry.create!(
  question: 'Why do I have to sign in & out of my shift?',
  answer: 'Err.... because that’s what makes the world go round! Very important for you and us.
Paid to work – So we know exactly how many hours to pay you for all your hard work!
Always FLAIR- We are now entering new contacts where you may be working for an additional event team so please always remember to indicate your working for FLAIR next to your name.
Health & Safety – In case of emergency we know where you are.',
  topic: 'event_info')
FaqEntry.create!(
  question: 'What do I need to bring with me on shift?',
  answer: 'Please ensure you bring with you on shift:
A small carrier bag of food
Any personal money would need to either be declared at the start of your shift or stored in allocated areas. Every client has different rules and we will do everything in our power to inform you per event.
Valuable – keep these to a minimum please.
Any documentation you have not yet supplied i.e. Identification
A Smile!',
  topic: 'event_info')
FaqEntry.create!(
  question: 'Employment Law and breaks?',
  answer: 'The Facts:
Workers over 18: If you work more than 6 hours a day, you have the right to one uninterrupted 20 minute rest break during the working day (this could be a tea or lunch break).
Young Workers: (over school leaving age and under 18). A 30 minute rest break if they work more than 4.5 hours (if possible this should be one continuous break). Due to the nature of our work, there will be some events that are not open to young workers.
Manager discretion – At quiet periods your Manager may allow you extra breaks if you need the rest. During busy periods this may not possible.
Communication – Your Manager and Supervisor are there for your safety; talk to them! They are there to help you!',
  topic: 'event_info')
FaqEntry.create!(
  question: 'Do I have to provide my own snacks/lunch?',
  answer: 'Depends on the event – Some events we are provided with food vouchers for staff, other events, staff are responsible with providing their own lunch/dinners.
This information is provided on the email roughly a week before the event',
  topic: 'event_info')
FaqEntry.create!(
  question: 'Can I work in the same area as my friend?',
  answer: 'Call Back Day – Requests to work with friends are taken on ‘Call Back Day’. Only ONE member of your group should confirm for the whole team (decide on the best person for the job, it could mean your job!)
Doing our best – We do our absolute 100% best to honour your requests but please note, we do not guarantee anything.
New BFF’s – Rest assured you are bound to make some funky, cool, new friends during the event too! Remember it’s work guys so if parted from friend just smile and enjoy.',
  topic: 'event_info')
FaqEntry.create!(
  question: 'Will my travel expenses be paid?',
  answer: 'We recruit locally - To help keep travel costs down.
Coaches - Flair often provides coaches to events but these will be from set towns only.
Staff parking – Parking is usually available. We will inform you in our e-mail with regards to parking.
It’s on you - If you really want to travel to events book your travel arrangements early to keep costs down.
Be realistic – If you live in Bristol & you want to work an event in Aberdeen, is it really feasible to travel? If you can make it work & you’re happy then we’re happy to have you.',
  topic: 'event_info')
FaqEntry.create!(
  question: 'Do I get to see the bands at Festivals & Concerts?',
  answer: 'The shifts that we operate are generally all day shifts. During your break you will be able to go off into the event and have fun.',
  topic: 'event_info')
FaqEntry.create!(
  question: 'Can I party in the crowd when I finish my shift?',
  answer: 'YES!! – go for it!!
Please remember to take your staff T-shirt off.
Buying staff drinks -
You can ONLY get served at the bar if it is a CASH event and there is no staff discount available.
You can NEVER get served at the bar if it is a token event.
You can buy drinks from Flair office at specific times only, staff discount AVAILBALE!
Every Client provides us with different rules so please pay attention to event information emails.',
  topic: 'event_info')
FaqEntry.create!(
  question: 'What shall I do if I become unwell during the event?',
  answer: 'If you’re not well enough to work:
Inform your manager, they will direct you to Flair Office.
Flair will help you call a parent / friend to pick you up.
We’ll help you get off site and home.',
  topic: 'event_info')
FaqEntry.create!(
  question: 'Staff Zone Library and a whole heap of Flair information.',
  answer: 'Handbooks, Flair Terms and Conditions, Temporary Staffing contact and many more books are stored in your Staff Zone library for your review at any time of employment. Enjoy!',
  topic: 'event_info')
FaqEntry.create!(
  question: 'Basic event standards to consider?',
  answer: 'Ying and Yang – working standards and respect should work both ways. We promise and strive to make the best possible working environment for you, offer you all the correct contact information so you can make an adult decision  to work for us or not. So in return please respect us, keep us informed if you need to cancel and let someone else have that job. Do the job you have been engage to work to the best of your ability so you walk away happy with your days work.
Your working standards are now rated per event by our shiny new system, clients, team leaders and managers. If you are always turning in a poor performance we simply will stop offering you work.
Enjoy your time with Flair and constrictive criticism is always welcome if this helps us help you in the long run.',
  topic: 'event_info')

FaqEntry.create!(
  question: 'Do I get paid for working with Flair?',
  answer: 'Yes most definitely! -  The rate of pay differs for each event and will be specified when you accept each contract with us.
Above minimum wage  -All wages are subject to PAYE deductions by law and are above minimum wage within each age bracket.
Know your rights - The government sets a new minimum wage each October so check yearly to know your rights.
Very occasionally at the clients request we provide volunteers / Value in Kind engagement– If this is the case it will be very clear at all stages of the process',
  topic: 'wages')
FaqEntry.create!(
  question: 'How and when do I get paid?',
  answer: 'Flair prides itself on paying wages by the end of the following calendar week (Friday – always). It’s not a hard thing to do if you all sign timesheets. We have managed events of 500 plus on back to back weekends and still managed to pay everyone within 5 working days!!  Our standard form of payment is directly into your bank account, assuming we have received all the information we need from you in order to do this e.g ID, NI and correct bank details.
Payments- will either be made by bank transfer the week following the event or cash the last day of the event– bank payment, pay slips will emailed.
Remember tax deducted - Flair always pays promptly and follows your tax instructions!
Remember bank transaction delay - Banks can take 2-3 days to clear a payment; we send your payments the Wednesday after each weekend to be in your banks by Friday.
Payslips: We will endeavour to email your payslips at least one day before making our wage run. If you have any wage questions, you have 24hrs to email us before the magic button is pressed. If emailing us a wage question please your full name, event name, work location and hours you feel you worked.
Holiday Pay. By law you are entitled to holiday pay per hour you work for anyone!  That’s an extra 12.5% per hour on top of your hourly figure. Some events we include this figure and it will be stated clearly within the pre-event emails. Or within your contract you have until the end of every tax year to request your accrued holiday pay. Please email us with “holiday Pay” in the subject box. Your full name in the body of the email please. ',
  topic: 'wages')
FaqEntry.create!(
  question: 'I have not been paid, what do I do?',
  answer: 'Please bear in mind we do our bank transfers at the end of the week following the event.
Please check you’re with your bank before contacting us either by checking your statements or going into your bank. Don’t blame us if you have already spent the money!
If you still believe you have not been paid there are a number of possible reasons why this may have happened.
Have you provided us with photocopies of your Identification?
Have you given us your bank details?
Are your details correct?
Please call (01400 220022) or e-mail (work@flairevents.co.uk) with the words ‘Wage Enquiries’ in the subject box. ',
  topic: 'wages')
FaqEntry.create!(
  question: 'Will my travel expenses be paid?',
  answer: 'We recruit locally - To help keep travel costs down.
Coaches - Flair often provides coaches to events but these will be from set towns only.
Staff parking – Parking is usually available. We will inform you  in our e-mail with regards to parking.
It’s on you - If you really want to travel to events book your travel arrangements early to keep costs down.
Be realistic – If you live in Bristol & you want to work an event in Aberdeen, is it really feasible to travel? If you can make it work & you’re happy then we’re happy to have you.',
  topic: 'wages')
FaqEntry.create!(
  question: 'I need my pay slips from Flair, how do I get them?',
  answer: 'Your payslips are generated with each event you work so you can keep account of all your finances! Yay!
Payslips from ‘cash paid’ events – Will be in your wage envelope accompanied by your cash wages, which you will collect on the last day of the event.
Payslips from ‘cheque / bank paid’ events – Will be emailed to you the week following the event.
Keep them secret, keep them safe – We advise you to save, store, file & organise your payslips somewhere safe so you can refer to them easily if ever you need to you.',
  topic: 'wages')
FaqEntry.create!(
  question: 'How do I request my p45?',
  answer: 'Emailing - in subject box: "P45 Request" full name & current full postal address',
  topic: 'wages')
FaqEntry.create!(
  question: 'Deposit? Do I have to pay a deposit to work with Flair?',
  answer: 'NO NO NO!! - Unlike many other companies, we do not ask you to pay a deposit – we think that’s really mean and slightly unsure if it’s legal.
However it’s not free –
Event Pass - By agreeing to work the event you have entered into a contract with Flair. The wristband is entrusted to you during the duration of the event, it doesn’t belong to you. If you abscond from your shift without informing Flair Staff Management, our clients can and do prosecute. You could be charged for the wristband, admin fees & court costs
Genuine reason for leaving - Inform the Flair event office verbally on the day. If you fail to inform us you will also be prosecuted. Remember we have heard several stories over the years, many very unbelievable, some very stupid and some honest but the person never thought to let us know.
It could cost you more! – So if you’re broke & you want a free ride into a festival, don’t do it through Flair, its dishonest & could cost you more!',
  topic: 'wages')
FaqEntry.create!(
  question: 'Am I taxed on my wages?',
  answer: 'Yes - It is UK law. Cash in hand, cash under the table is against the UK law.
All wages are subject to PAYE deductions. At each event and you are taxed accordingly.
Please refer to  www.hmrc.gov.uk for more information.
“Login” and complete your tax assessment for us. You will have the option of 3 boxes to tick. One states that’s it’s your first job since April, one states it’s your only job and the other that we are your second employer within that tax period.  If we are your second employer then by Law we have to place a BR tax code to your wages and tax you at source. Depending on your individual earning levels you will receive a refund direct form the Government.
Blame the Government: We get a lot of abuse about this! We are just following YOUR instructions and the Government requirements. So please fill in the correct tax information.
RTI: April 2013 the UK Government has change the way PAYE information is stored and received from employers forever! Each week we send them your payroll figures and information so I am assuming the rebates system will be simplified. Also we are starting to receive alternative tax codes to implement on an individual bases.',
  topic: 'wages')
FaqEntry.create!(
  question: 'I am a Student so I don’t pay tax!',
  answer: 'Wrong, I am afraid the below information is sourced from: www.hmrc.gov.uk/students/work_hols_while_student_8_1.htm
If you\'re a student, from 6 April 2013 employers will no longer use the P38(S) process, your employer will operate PAYE (Pay as You Earn) to deduct Income Tax and National Insurance from your wages. Although the P38(S) process has stopped, nearly everyone in the UK is entitled to an Income Tax Personal Allowance. This is the amount of income you can earn or receive each year without having to pay tax on it. The Personal Allowance for the tax year 2013-14 is £9,440 it goes up each year so please Google to get current figures.',
  topic: 'wages')
FaqEntry.create!(
  question: 'I want to claim my tax back, how do I do it?',
  answer: 'P45 round up - You need to collect all your P45\'s from ALL employers with in that tax year.
Getting it from, Flair - simply call or email us your request
Emailing - in subject box "P45 Please" full name & current full postal address
It\'s not a P60 - This is only for jobs held across the whole tax year – your all temporary employees so work a per event contact than leave.
3 months of none RTI filing under your name the new Government system put you as not working for any company. ',
  topic: 'wages')
FaqEntry.create!(
  question: 'Why do you need my National Insurance Number?',
  answer: 'The National Insurance number (NI number) is the reference number by which HM Revenue & Customs (HMRC) identifies you in its records. In particular, it is the key to your National Insurance contributions record. Details of the National Insurance contributions (NICs) that you paid during each tax year are carefully recorded and used to calculate your state pension and additional state pension when you retire.',
  topic: 'wages')

FaqEntry.create!(
  question: 'What shall I wear for work?',
  answer: 'Always the uniform we state clearly in every event email. Incorrect uniform or untidy appearance and you will be sent away.',
  topic: 'uniform')
FaqEntry.create!(
  question: 'Why do we have to wear a Uniform?',
  answer: 'Health & Safety – You will be easily identified as Flair staff in case of emergency
Image – The festival organisers request smart, clean, professional looking bar staff to work their event
One for all & all for one – We’re all in it together! All the other Flair staff will know you are one of them & you’ll make loads of lovely new friends!',
  topic: 'uniform')
FaqEntry.create!(
  question: 'What is the Uniform?',
  answer: 'This can differ depending on what type of event you are working at. If there are any special uniform requirements you will be told. See below for a general rule for bar and catering work:
Black shoes – Think comfy, think not too precious, think closed toe (health & safety) think BLACK!
Black trousers – Combats /shorts /leggings /skirts (black tights must be worn with skirts) / jeans (are allowed as long as they’re BLACK!)
FREE staff T shirt – We provide! Bring long sleeved top to wear underneath when it’s cold at night
Any colour wellies!! – pink / blue / lime green with zebra stripes / whatever you want!
See below for a general rule for sporting events:
NO JEANS! We want the sporty look, get in the vibe of the event.
Jogging bottoms or casual bottoms whether and event dependant.
Trainers  and wellies are fine.
You will normally provided an event t-shirt or Hi-viz vest.
Waterproofs – always please protect yourself against the elements.
I don\'t have black trousers / or sporty outfits!
Savvy shopper – charity shops, cheap shops, borrow your brother / sisters / uncles / aunts / mates
We have a set uniform so if you ignore this you will be sent home, sorry. Please don’t accept the work if you have no intention of complying.',
  topic: 'uniform')

FaqEntry.create!(
  question: 'What Equipment/facilities are available at the event?',
  answer: 'Basic always basic.
The facilities differ depending on the event and are provided by the event organisers.
In the best-case scenario there are plenty of toilets and some showers, in a bad case there are no showers or the showers are cold, or they’re not plumbed in!????
Unfortunately, we don\'t know what the situation is until we arrive on site so baby wipes are your best friend!',
  topic: 'camping_travel')
FaqEntry.create!(
  question: 'I\'m working at a camping festival, what do I need to bring?',
  answer: 'Good quality double skinned tent – Perhaps the most important thing you’ll need! Think keeping in heat and waterproof!
Sleeping bag – A nice warm one, the nights are cold even in the height of summer!
Roll mat – It keeps you off the ground, making you much warmer and comfy. Its Light weight, easy to carry, cheap, better than an airbed, doesn’t puncture!
A Pillow – You wouldn’t believe how many people forget their pillow! However when this happens, you can always find comfort in a folded up jumper!
Torch – To work your way across the guy ropes at night!
Toilet roll – Advised to keep a roll on you at all times!
Toothbrush/toothpaste – Amazing how easy it is to forget.
Baby wipes – Next best thing to a shower!
Hand sanitizer – Or good old fashioned bar of soap. Wash your hands often!
Sun cream and after sun – Sunburn can make you sore, dehydrated and drained of energy. Protect yourself!
Warm clothes – Again it gets cold at night, bring long sleeved tops, a fleece, woolly hat and warm socks!
Wellies!!! – Hello unpredictable British summer time!
Ear Plugs - Chances of getting a decent night’s kip, vastly improved!!
Food – Breakfast snacks, water, nuts, chocolate, munchies! The more you eat and drink, the more energy you’ll have!!
No valuables – No expensive camera’s, phones, iPods etc. There is nowhere safe to keep your precious items and festival lost property is very poor. Want to keep your stuff safe? Leave it at home!',
  topic: 'camping_travel')
FaqEntry.create!(
  question: 'Eek! I don\'t have a tent/sleeping bag/roll mat!',
  answer: 'Basically you want to be warm and dry for the weekend but you don’t want to be spending a fortune! Here’s what we recommend:
Think inexpensive, good quality, waterproof
Beg and borrow from friends / family
Don’t scrimp on quality, single skinned tents are not ideal
Buy quality at the beginning of the season, use it 100 times!
Being comfy could make or break your weekend
Light weight & compact – remember you have to carry it all!!
We sell good quality Vango tents, Vango sleeping bags and roll mats all at cost price. Hooray!! This is how you buy:
Place order on call back day
No paying upfront, you pay with your wages from event
Arrive at event and collect items from us
Sign for items collected & we will deduct total amount from your wages
Receipts included, full price and VAT stated
What’s the cost and what am I getting? -  We sell good quality Vango 2 man, double skinned tents & Sleeping bags all at cost price. These prices are going up each year like everything! So watch out of information within our event emails.
I ordered a tent from Flair but I don’t need it anymore – Not a problem, just let us know on arrival that you no longer need the items.',
  topic: 'camping_travel')
FaqEntry.create!(
  question: 'Are we provided with food at weekend camping events?',
  answer: 'Generally we will provide you with a packed lunch style lunch and an evening meal that is usually served canteen style, tokens for food vans or another packed lunch.
Unfortunately, we cannot cater for any special dietary requirements.
Please bring your own snacks/lunch etc.',
  topic: 'camping_travel')
FaqEntry.create!(
  question: 'Can I cook my own food at the event?',
  answer: 'Unfortunately no - we do not provide cooking facilities
Bring snacks, fruit etc. Anything that doesn’t require cooking
You cannot bring your own cooking equipment as it is a fire hazard',
  topic: 'camping_travel')
FaqEntry.create!(
  question: 'Can I camp with my friends who are coming to the events as customers?',
  answer: 'NO!! - Staff wrist band = Staff camping pass ONLY.
Security guards - Some will let you in to the general camping ground & others will not let you out - the result is you being stuck and us having to come and get you - BAD!!',
  topic: 'camping_travel')
FaqEntry.create!(
  question: 'Where do I keep my belongings?',
  answer: 'Valuables - Don\'t bring any! Wallets / keys / phones make sure you can keep them safe in your pockets
Bring a small bag – big enough for your lunch and extra clothes. Keep valuables on your person
Don’t leave valuables in your tent – just don’t! If stuff gets stolen you’re very unlikely to get it back',
  topic: 'camping_travel')
