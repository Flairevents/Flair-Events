require 'active_record'

$:.unshift(File.expand_path('../lib', __dir__))
require_relative '../app/models/application_record'
require_relative '../app/models/account'
class Officer < ActiveRecord::Base; end
require_relative '../app/models/country'
require_relative '../app/models/region'
require_relative '../app/models/event_category'
class FaqEntry < ActiveRecord::Base; end
require_relative '../app/models/post_region'
require_relative '../app/models/post_area'
class TextBlock < ActiveRecord::Base; self.inheritance_column = '__none__'; end

require 'process_utils'
extend Flair::Processes

test_db_config = {
  'adapter' => 'postgresql',
  'database' => 'flair_test_pristine',
  'encoding' => 'unicode',
  'user' => 'postgres'
}

include ActiveRecord::Tasks
DatabaseTasks.database_configuration = { 'test' => test_db_config }
DatabaseTasks.db_dir = File.expand_path('../db', __dir__)
DatabaseTasks.root   = File.expand_path('..', __dir__)

# drop and re-create test DB
DatabaseTasks.drop(test_db_config)
DatabaseTasks.create(test_db_config)

# dump out 'development' schema so we can load it into test DB
cmd('pg_dump --schema-only -x -O --file="/tmp/flair-schema.sql" flair_development')
# also dump out migrations which have been run
cmd('pg_dump --data-only --table=schema_migrations --file="/tmp/flair-migrations.sql" flair_development')

# load DB schema and migrations into 'flair_test_pristine'
cmd('psql -v ON_ERROR_STOP=1 --file="/tmp/flair-schema.sql" flair_test_pristine')
cmd('psql -v ON_ERROR_STOP=1 --file="/tmp/flair-migrations.sql" flair_test_pristine')

ActiveRecord::Base.establish_connection(test_db_config)

# make 3 accounts for 3 officers
staffer = Officer.create!(first_name: 'Staffy', last_name: 'Staffer', email: 'staffer@blah.com', role: 'staffer')
manager = Officer.create!(first_name: 'Manny',  last_name: 'Manager', email: 'manager@blah.com', role: 'manager')
admin   = Officer.create!(first_name: 'Addy',   last_name: 'Admin',   email: 'admin@blah.com',   role: 'admin')
acct1   = Account.create!(user: staffer, password: 'abc', confirmed_email: true)
acct2   = Account.create!(user: manager, password: 'abc', confirmed_email: true)
acct3   = Account.create!(user: admin,   password: 'abc', confirmed_email: true)

# countries
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

# regions
["London", "Yorkshire", "Wales", "Northeast", "Northwest", "Southeast", "Southwest", "Eastern", "Midlands", "Scotland", "Ireland", "East Midlands"].each do |region|
  Region.create!(name: region)
end

# event categories
["Sport", "Promo", "Other", "Hospitality", "Festival", "Concert"].each do |category|
  EventCategory.create!(name: category)
end

# FAQ entries
FaqEntry.create!(
  question: 'What is your name?',
  answer: 'Launcelot',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'What is your quest?',
  answer: 'To seek the holy grail',
  topic: 'recruitment')
FaqEntry.create!(
  question: 'What is your favorite color?',
  answer: 'Blue',
  topic: 'recruitment')

# post areas, post regions
require 'csv'

regions      = {}
post_regions = {}

CSV.parse(File.read(File.expand_path('../db/legacy_data/Regions.tsv', __dir__)), headers: true, col_sep: "\t").each_with_index do |row,i|
  regions[row['RegionCode']] = Region.find_by_name(row['Region'])
end

CSV.parse(File.read(File.expand_path('../db/legacy_data/PostRegions.tsv', __dir__)), headers: true, col_sep: "\t").each_with_index do |row,i|
   post_region = PostRegion.create!(id: i, region: regions[row['Region']], name: row['PostName'], subcode: row['PostRegion'])
   post_regions[row['PostRegion']] = post_region
end

CSV.parse(File.read(File.expand_path('../db/legacy_data/PostLocations.csv', __dir__)), headers: true).each do |row|
  subcode = row['PostSubcode'][/^[A-Z]+/]
  next if subcode == 'GY' # Guernsey Island -- it's not even on our map
  next if subcode == 'IM' # Isle of Man -- it's not on our map
  next if subcode == 'JE' # Jersey
  # When running test suite, we will *only* test using postcodes which start with A or B
  # This will make loading the Office Zone faster
  next unless subcode.start_with?('A') || subcode.start_with?('B')
  PostArea.create!(post_region: post_regions[subcode], region_id: post_regions[subcode].region.id, subcode: row['PostSubcode'], latitude: row['Latitude'], longitude: row['Longitude'])
end

# reports???

# text blocks
TextBlock.create!(key: 'welcome-message', type: 'page', contents: "Flair is a unique staffing company that provides staff for music and sporting events all over the UK. Flair helps run huge internationally renowned weekend festivals like the V festivals to smaller, more unique events such as the Rat Race Adventure Series.

  We don't just drop staff off at the door. Essentially we are a team of organisers that manage staff from start to finish. We take care of staff every step of the way from the interview, to the event, to getting you home after a great weekend.

  We are always looking for new staff to help us at events. We need active individuals from all walks of life that want to join our fun and vibrant team. So if you are a team player and love the idea of working at energetic, busy music events or exciting promotional and sporting events then go to our Events Page.

  Notes on employment: Seeking rewarding and interesting work? Not the normal 9-5 and want the flexibility to select your contacts? Want a company that treats you with respect? Want to get involved in some of the UK's top events from festivals, music concerns, adventure racing, inner city sports to promotional work? Then Flair is the link you seek!

  Note to clients: Seeking a staffing provider to demonstrate the same skills, loyalty, and enthusiasm as your core team? Flair is proud of over 12 years service to the event industry, providing the complete staffing experience. We offer solutions, not problems, with service beyond your expectations.

  If you want Flair to staff your event, take a look at our \"Need Staff?\" page.

  Cheers,
  The Flair Team")

TextBlock.create!(key: 'about-us', type: 'page', contents: "Established in the year 2000, Flair has an impressive track record of delivering organised and impressively managed staffing teams to some of the UK's national events -- from music festivals, one day concerts, and adventure sports to inner city charity events. From national promotional tours and city sampling teams to experienced bar crew at boutique events. Flair has the knowledge, experience, and exceptional history of delivering every time.

  To date, Flair has been involved with over 730 events, which have created enough work to see 26,000 people pass through our database. We have the skills to supply dual venues with over 1500 people, back to back weekends on a national UK level, to small, one-person front-of-house promo style contacts.")

TextBlock.create!(key: 'company-address', type: 'page', contents: '90 Buxton Road, Congleton, Cheshire CW12 2DY')
TextBlock.create!(key: 'company-tel',     type: 'page', contents: '01925 368 368')
TextBlock.create!(key: 'company-mobile',  type: 'page', contents: "07961 988 644\n07933 614 34")

TextBlock.create!(key: 'privacy', type: 'page', contents: 'Privacy boilerplate will go here')
TextBlock.create!(key: 'cookies', type: 'page', contents: "In the United States and Canada a cookie is a small, flat, baked treat, usually containing fat, flour, eggs and sugar. In Scotland the term cookie is sometimes used to describe a plain bun. In most English-speaking countries outside North America, including the United Kingdom, the most common word for a small, flat, baked treat, usually containing fat, flour, eggs and sugar is biscuit and the term cookie is often used to describe drop cookies exclusively. However, in many regions both terms are used, such as the American-inspired Maryland Cookies, while in others the two words have different meanings.\n\nCookies are most commonly baked until crisp or just long enough that they remain soft, but some kinds of cookies are not baked at all. Cookies are made in a wide variety of styles, using an array of ingredients including sugars, spices, chocolate, butter, peanut butter, nuts or dried fruits. The softness of the cookie may depend on how long it is baked.")

TextBlock.create!(key: 'funky-popup', type: 'page', contents: 'Pop-up contents here')
TextBlock.create!(key: 'history-message', type: 'page', contents: 'History page contents here')

TextBlock.create!(key: 'sport-history-intro', type: 'page', contents: 'Paragraph about Sporting Events')
TextBlock.create!(key: 'music-history-intro', type: 'page', contents: 'Paragraph about Music Events')
TextBlock.create!(key: 'promo-history-intro', type: 'page', contents: 'Paragraph about Promo Events')
TextBlock.create!(key: 'corporate-history-intro', type: 'page', contents: 'Paragraph about Corporate Events')

TextBlock.create!(key: 'confirmed-events-paragraph', type: 'page', contents: 'You are confirmed for the below events. We will be sending e-mails with more information about each event closer to its date. If you have to cancel your attendance for any of these events for any reason, please call the office as there is always someone else would love to work and we can\'t fill the space if we don\'t know you are not coming.')
TextBlock.create!(key: 'pending-events-paragraph', type: 'page', contents: "Hold tight, the following events you have chosen have been sent to the office and are awaiting the Flair office team to confirm your application")

# add stored procedures
# these should be in structure.sql, but let's make sure we have the most up-to-date
`psql flair_test_pristine --file="#{File.expand_path('../db/stored_procedures.sql', __dir__)}"`

# dump out as a file, which can be quickly reloaded to create a fresh test DB
# `pg_dump --format=c --compress=9 --file="#{__dir__}/data/test_db.bin" flair_test_pristine`
