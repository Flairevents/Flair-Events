class InitialSetup < ActiveRecord::Migration
  def up

    # *************
    # PROSPECT DATA
    # *************

    create_table :prospects do |t|
      t.string :status,        null: false, default: 'APPLICANT'
      t.date   :date_start # date of first employment

      t.string :first_name,    null: false
      t.string :last_name,     null: false
      t.date   :date_of_birth
      t.string :gender

      t.integer :nationality_id
      t.string  :country  # england/wales/scotland/n-ireland/non-uk

      t.string  :address
      t.string  :address2 # second Address line
      t.string  :city
      t.string  :post_code

      t.string  :email,        null: false

      t.string  :mobile_no
      t.string  :home_no
      t.string  :emergency_no
      t.string  :emergency_name

      t.string  :tax_code
      t.string  :tax_choice # statement which was chosen in 'Tax Code' section of Staff Zone
      t.date    :date_tax_choice

      # Has this Prospect left a course of UK higher education before last 6 April
      #  and also received their first student loan installment on or after
      #  1 September 1998, and the student loan is not fully repaid?
      t.boolean :student_loan, null: false, default: false

      t.string  :ni_number
      t.string  :bank_sort_code
      t.string  :bank_account_no
      t.string  :bank_account_name # defaults to first_name + ' ' + last_name

      t.string  :id_type
      t.string  :id_number
      t.string  :visa_number
      t.date    :visa_expiry
      t.date    :id_sighted # date approved by a Flair officer; NULL if not yet approved

      t.boolean :has_bar_license, null: false, default: false

      t.datetime :datetime_agreement # NULL if they have not agreed yet to terms of employment

      t.text     :notes

      t.string   :photo # filename, relative to /var/www/flair/shared/uploads/prospect_photos

      # which kind of Events does this person have special skills/experience for?
      t.boolean :good_sport, null: false, default: false
      t.boolean :good_music, null: false, default: false
      t.boolean :good_promo, null: false, default: false
      t.boolean :good_corporate, null: false, default: false
      t.boolean :good_management, null: false, default: false

      t.timestamps
    end
    add_index :prospects, :email, :unique => true
    add_index :prospects, :updated_at

    create_table :scanned_ids do |t|
      t.integer :prospect_id, null: false
      t.string  :photo, null: false # filename, relative to /var/www/flair/shared/scanned_ids
      # Unlike the library and event photos, scanned_ids is NOT symlinked to our public
      #   directory. Otherwise, anyone on the Internet could view the scanned IDs!

      t.timestamps
    end
    add_index :scanned_ids, :prospect_id

    # if Prospects want to change their contact info or payroll info or ID, they have to submit a change request
    create_table :change_requests do |t|
      t.integer :prospect_id

      # NULL for any of the following fields means: do not change the record
      t.string  :address
      t.string  :address2
      t.string  :city
      t.string  :post_code
      t.string  :email
      t.string  :home_no
      t.string  :mobile_no
      t.string  :emergency_no
      t.string  :emergency_name
      t.string  :ni_number
      t.string  :tax_choice
      t.boolean :student_loan
      t.date    :date_tax_choice

      t.string  :bank_sort_code
      t.string  :bank_account_no
      t.string  :bank_account_name

      t.string  :id_type
      t.string  :id_number
      t.string  :visa_number
      t.date    :visa_expiry

      t.boolean :processed, null: false, default: false
      t.boolean :accepted,  null: false, default: false
      t.integer :officer_id # who was it processed by?

      t.timestamps
    end
    add_index :change_requests, [:processed, :prospect_id]

    # history of what prospect details were in the past
    create_table :details_history do |t|
      t.integer  :prospect_id
      t.datetime :created_at
      t.string   :description

      # only the fields which actually changed will be filled in
      t.string  :first_name
      t.string  :last_name
      t.date    :date_of_birth
      t.string  :gender
      t.integer :nationality_id
      t.string  :address
      t.string  :address2
      t.string  :city
      t.string  :post_code
      t.string  :email
      t.string  :home_no
      t.string  :mobile_no
      t.string  :emergency_no
      t.string  :emergency_name
      t.string  :ni_number
      t.string  :tax_choice
      t.boolean :student_loan
      t.string  :bank_sort_code
      t.string  :bank_account_no
      t.string  :bank_account_name
      t.string  :id_type
      t.string  :id_number
      t.string  :visa_number
      t.date    :visa_expiry
    end
    add_index :details_history, :prospect_id

   # **********
   # EVENT DATA
   # **********

    create_table :events do |t|
      t.string  :name,        null: false
      t.string  :display_name
      t.string  :description, null: false # for display to office staff only
      t.text    :blurb      # for display to the general public
      t.text    :final_info # information for people who have been hired

      t.string  :photo # filename, relative to /var/www/flair/shared/uploads/event_photos

      t.date    :date_start,  null: false
      t.date    :date_end,    null: false
      t.date    :date_callback # date when office staff confirm who is actually going

      t.string  :status,      null: false, default: 'NEW'

      t.string  :location
      t.string  :address
      t.string  :city
      t.string  :post_code

      t.string  :website

      t.integer :category_id, null: false

      t.text    :notes

      t.string  :client
      t.string  :manager
      t.string  :jobs_description # for display to public

      t.boolean :show_in_history, null: false, default: false
      t.integer :staff_for_history

      # following field is only meaningful for 'Music' events
      t.boolean :is_concert, null: false, default: false

      # when people are hired on to this event, initialize their 'job' to:
      t.integer :default_job_id

      # accomodation-related fields:
      t.string  :accom_required
      t.string  :accom_hotel_name
      t.string  :accom_address
      t.string  :accom_email
      t.boolean :accom_parking,  null: false, default: false
      t.string  :accom_num_rooms
      t.string  :accom_num_beds
      t.date    :accom_booking_date
      t.string  :accom_total_cost
      t.string  :accom_booking_ref
      t.boolean :accom_paid,         null: false, default: false
      t.boolean :accom_confirmation, null: false, default: false
      t.text    :accom_notes, rows: 6, cols: 80

      # transport-related fields:
      t.string  :trans_required
      t.string  :trans_types_used
      t.boolean :trans_bookings_made, null: false, default: false
      t.string  :trans_booking_refs
      t.boolean :trans_tickets_received, null: false, default: false
      t.string  :trans_cost
      t.text    :trans_notes

      t.boolean :exported_tax_weeks, null: false, default: false

      t.timestamps
    end
    add_index :events, :category_id
    add_index :events, :updated_at
    add_index :events, :name, unique: true

    # Event "Categories" include Sport, Music, etc.
    create_table :event_categories do |t|
      t.string :name, null: false, unique: true
    end

    create_table :jobs do |t|
      t.integer :event_id, null: false
      t.string  :name,     null: false # unique within a single Event

      t.timestamps
    end
    add_index :jobs, :event_id
    add_index :jobs, :updated_at

    create_table :shifts do |t|
      t.integer :job_id,        null: false

      t.time    :time_start,    null: false # will use postgres "time" type, doesn't include date
      t.time    :time_end,      null: false # if earlier than time_start, we assume the shift went overnight

      t.decimal :break_mins,    null: false, default: 0 # break time in mins for this shift

      t.decimal :pay_under_21,  null: false # hourly pay rate
      t.decimal :pay_over_21,   null: false # this is for 21 AND OVER

      t.decimal :allowance,     null: false, default: 0
      t.decimal :min_hrs_for_allowance, null: false, default: 0

      t.timestamps
    end
    add_index :shifts, :job_id
    add_index :shifts, :updated_at

    create_table :locations do |t|
      t.integer :event_id,    null: false
      t.string  :name,        null: false
      t.integer :staff_count, null: false

      t.timestamps
    end
    add_index :locations, [:event_id, :name], unique: true
    add_index :locations, :updated_at

    create_table :transports do |t|
      t.integer :event_id, null: false
      t.string  :name,     null: false
      t.decimal :cost,     null: false, default: 0
      t.timestamps
    end
    add_index :transports, [:event_id, :name], unique: true
    add_index :transports, :updated_at

    # ********
    # GIG DATA
    # ********

    create_table :gigs do |t|
      t.integer :prospect_id,  null: false
      t.integer :event_id,     null: false

      t.integer :job_id       # if null, specific job has not been chosen yet (but Prospect has been chosen to work this event)
      t.integer :transport_id # if null, prospect is using their "own" transport
      t.integer :location_id  # location can be set arbitrarily to any of the locations for this event

      t.boolean :callback,     null: false, default: false
      t.integer :rating
      t.text    :notes

      t.timestamps
    end
    add_index :gigs, [:prospect_id, :event_id], unique: true
    add_index :gigs, :event_id
    add_index :gigs, :updated_at

    # a Gig Request indicates a Prospect wants to work at a certain Event
    create_table :gig_requests do |t|
      t.integer :prospect_id, null: false
      t.integer :event_id,    null: false
      t.integer :gig_id # if this Prospect was hired, this will link to a Gig, otherwise NULL

      # if request is 'pending', that means this person should NOT be hired right now
      t.boolean :pending, null: false, default: false

      t.timestamps
    end
    # We want to avoid pesky duplicate records in JOIN tables; sometimes they cause subtle bugs
    # We can accomplish that either by adding a UNIQUE index *or* a UNIQUE constraint...
    # In this case the index will be useful, so we'll go that way
    add_index :gig_requests, [:prospect_id, :event_id], unique: true
    add_index :gig_requests, [:event_id, :prospect_id], unique: true
    add_index :gig_requests, :updated_at
    add_index :gig_requests, :gig_id

    ###############
    # TAX WEEK DATA
    ###############

    create_table :tax_weeks do |t|
      t.integer :event_id
      t.integer :prospect_id,    null: false

      t.integer :year,           null: false
      t.integer :tax_week,       null: false # 1-52
      t.decimal :monday,         null: false, default: 0 # number of hrs worked
      t.decimal :tuesday,        null: false, default: 0
      t.decimal :wednesday,      null: false, default: 0
      t.decimal :thursday,       null: false, default: 0
      t.decimal :friday,         null: false, default: 0
      t.decimal :saturday,       null: false, default: 0
      t.decimal :sunday,         null: false, default: 0
      t.decimal :rate,           null: false
      t.decimal :deduction,      null: false, default: 0
      t.decimal :allowance,      null: false, default: 0
      t.string  :job_role
      t.string  :work_location
      t.string  :shift

      t.boolean :paid,           null: false, default: false
      t.string  :payment_method, null: false

      t.boolean :exported,       null: false, default: false

      t.timestamps
    end
    add_index :tax_weeks, :event_id
    add_index :tax_weeks, [:year, :tax_week]

    # ************************************
    # SYNCHRONIZATION WITH CLIENT-SIDE APP
    # ************************************

    # For our Office Zone, we have a HTML/JS "app" which preloads all the needed data,
    #   and pings the server periodically for updated data
    # Our `updated_at` fields on all the tables of interest can be used to retrieve
    #   data which has changed efficiently and send it to the client
    # But what if records have been deleted since last time the client pinged us?
    # We need to keep track of that

    create_table :deletions, id: false do |t|
      t.string   :table
      t.integer  :record_id
      t.datetime :updated_at
    end
    add_index :deletions, :updated_at

    # *************
    # USER ACCOUNTS
    # *************

    create_table :accounts do |t|
      t.integer  :user_id,   null: false
      t.string   :user_type, null: false # either 'Prospect' or 'Officer'

      t.string   :password_hash # an automatically created account may have no password; the user will have to use the 'Forgot Password' page to gain access
      t.boolean  :locked,          null: false, default: false
      t.integer  :failed_attempts, null: false, default: 0
      t.string   :remember_token
      t.string   :one_time_token
      t.boolean  :confirmed_email, null: false, default: false
    end
    add_index :accounts, [:user_id, :user_type], unique: true
    add_index :accounts, :remember_token
    add_index :accounts, :one_time_token

    # A log of user access to the site
    create_table :account_sessions do |t|
      t.integer  :account_id, null: false
      t.string   :login_ip,   null: false
      t.datetime :time_start, null: false
      t.datetime :time_end,   null: false
    end
    add_index :account_sessions, :time_end

    create_table :officers do |t|
      t.string :name,  null: false, unique: true
      t.string :email, null: false, unique: true
      t.string :role,  null: false, default: 'staffer' # staffer/manager/admin

      t.boolean :logged_in, null: false, default: false

      t.timestamps
    end
    add_index :officers, :email, unique: true
    add_index :officers, :updated_at

    # ******************
    # CONTENT MANAGEMENT
    # ******************

    # The following table holds admin-editable text for e-mail templates and static pages
    # Page (or fragment) caching will likely be used for the static pages, but besides that,
    #   this data will also be cached in memory
    # This DB table will persist the text blocks between application server restarts

    # I'm not bothering with indexing here, since this will only be used to persist data between restarts
    # 99.9% of the time, requests will be satisfied directly from our application-level in-memory cache
    create_table :text_blocks do |t|
      t.string   :key,      null: false
      t.string   :type,     null: false, default: 'page' # page/email/terms
      t.text     :contents, null: false

      t.timestamps
    end

    create_table :answers do |t|
      t.integer :prospect_id, null: false
      t.string  :question_id, null: false # a short mnemonic string. The set of strings used is defined by StaffController#application and views/staff/application.html.haml
      t.string  :answer,      null: false
    end
    add_index :answers, :prospect_id

    create_table :faq_entries do |t|
      t.string  :question, null: false
      t.text    :answer,   null: false
      t.integer :position, null: false, default: 1
      t.string  :topic

      t.timestamps
    end
    add_index :faq_entries, :topic

    create_table :library_items do |t|
      t.string :name,     null: false
      t.string :filename, null: false

      t.timestamps
    end

    # ***************
    # BITS AND SCRAPS
    # ***************

    create_table :countries do |t|
      t.string :name, null: false, unique: true
    end

    create_table :regions do |t|
      t.string :name, null: false, unique: true
    end

    create_table :post_regions do |t|
      t.string  :name,      null: false, unique: true
      t.string  :subcode,   null: false, unique: true
      t.integer :region_id, null: false
    end
    add_index :post_regions, :subcode


    create_table :post_areas do |t|
      t.integer :post_region_id, :null => false
      t.string  :subcode,   null: false, unique: true # leading (or trailing) digits for a group of postal codes
      t.float   :latitude,  null: false # latitude in degrees of the center of the area
      t.float   :longitude, null: false # longitude in degrees of the center of the area
    end
    add_index :post_areas, :subcode

    create_table :reports do |t|
      t.string  :name,       null: false
      t.string  :print_name, null: false
      t.string  :table,      null: false
      t.string  :fields,     null: false # comma-delimited
      t.boolean :row_numbers, null: false, default: false
    end
    add_index :reports, :name, unique: true

    # ***********
    # VIEWS
    # ***********

    execute "CREATE VIEW prospects_avg_ratings
      AS SELECT prospects.id AS prospect_id, AVG(gigs.rating) AS avg_rating
           FROM prospects JOIN gigs ON prospects.id = gigs.prospect_id
       GROUP BY prospects.id"

    # **************************************************************
    # DB CONSTRAINTS to prevent illegal data from being stored in DB
    # **************************************************************

    execute "ALTER TABLE prospects ADD CHECK (first_name <> '')"
    execute "ALTER TABLE prospects ADD CHECK (last_name <> '')"
    execute "ALTER TABLE prospects ADD CHECK (address IS NULL OR address <> '')"
    execute "ALTER TABLE prospects ADD CHECK (address2 IS NULL OR address2 <> '')"
    execute "ALTER TABLE prospects ADD CHECK (city IS NULL OR city <> '')"
    execute "ALTER TABLE prospects ADD CHECK (bank_account_name IS NULL OR bank_account_name <> '')"
    execute "ALTER TABLE prospects ADD CHECK (gender IS NULL OR gender = 'M' OR gender = 'F')"
    execute "ALTER TABLE prospects ADD CHECK (status IN ('APPLICANT', 'EMPLOYEE', 'LIMBO', 'HAS_BEEN', 'SLEEPER'))"
    execute "ALTER TABLE prospects ADD CHECK (tax_choice IS NULL OR tax_choice IN ('A', 'B', 'C', 'Manual'))"
    execute "ALTER TABLE prospects ADD CHECK (tax_code IS NULL OR tax_code <> '')"
    execute "ALTER TABLE prospects ADD CHECK (country IS NULL OR country IN ('england', 'wales', 'scotland', 'n-ireland', 'non-uk'))"
    execute "ALTER TABLE prospects ADD CHECK (email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9._-]+[.][A-Za-z]+$')"
    execute "ALTER TABLE prospects ADD CHECK (ni_number IS NULL OR ni_number ~ '^[A-CEGHJ-NOPR-TW-Z][A-CEGHJ-NPR-TW-Z][0-9]{6}[A-D\\s]$')"
    execute "ALTER TABLE prospects ADD CHECK (ni_number IS NULL OR ni_number !~ '^(GB|BG|NK|KN|TN|NT|ZZ)')"
    execute "ALTER TABLE prospects ADD CHECK (post_code IS NULL OR post_code ~ '^[a-zA-Z][a-zA-Z0-9]{1,3} \\d[a-zA-Z]{2}$')"
    execute "ALTER TABLE prospects ADD CHECK (mobile_no IS NULL OR mobile_no ~ '^[0-9]+(\\([0-9]+\\))?$')" # allow extension at the end
    execute "ALTER TABLE prospects ADD CHECK (home_no IS NULL OR home_no ~ '^[0-9]+(\\([0-9]+\\))?$')"
    execute "ALTER TABLE prospects ADD CHECK (emergency_no IS NULL OR emergency_no ~ '^[0-9]+(\\([0-9]+\\))?$')"
    execute "ALTER TABLE prospects ADD CHECK (id_type IN ('UK Passport', 'EU Passport', 'Work/Residency Visa', 'BC+NI'))"
    execute "ALTER TABLE prospects ADD CHECK (id_number IS NULL OR id_number <> '')"
    # We need to export data to a payroll program called 12Pay, and they don't allow square brackets
    #   in address or bank account name
    # (the bank account name has to use only legal characters from the BACS 18 format)
    execute "ALTER TABLE prospects ADD CHECK (address !~ '\\[|\\]')"
    execute "ALTER TABLE prospects ADD CHECK (address2 !~ '\\[|\\]')"
    execute "ALTER TABLE prospects ADD CHECK (bank_account_name !~ '[^A-Z0-9&./ -]')"
    execute "ALTER TABLE prospects ADD FOREIGN KEY (nationality_id) REFERENCES countries (id) MATCH FULL"

    # The following constraint is *important* for system security!
    # In the Office Zone, ID scan files are served up using 'scanned_ids.photo' as a relative path
    # If someone managed to INSERT a record with slashes in 'photo', the relative path could go up and out of the 'scanned_ids'
    #   directory and they could download other files off the server's filesystem
    execute "ALTER TABLE scanned_ids ADD CHECK (photo ~ '^[A-Za-z0-9._%-]+\\.(jpg|jpeg|gif|png)$')"

    execute "ALTER TABLE change_requests ADD FOREIGN KEY (prospect_id) REFERENCES prospects (id) MATCH FULL"
    execute "ALTER TABLE change_requests ADD CHECK (email IS NULL OR email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')"

    execute "ALTER TABLE events ADD CHECK (name <> '')"
    execute "ALTER TABLE events ADD CHECK (description <> '')"
    execute "ALTER TABLE events ADD CHECK (date_end >= date_start)"
    execute "ALTER TABLE events ADD CHECK (status IN ('NEW', 'OPEN', 'CANCELLED', 'FULL', 'HIDDEN', 'HAPPENING', 'CLOSED'))"
    execute "ALTER TABLE events ADD CHECK (website IS NULL OR website ~ '^[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+/&@#%=~_|]$')"
    execute "ALTER TABLE events ADD CHECK (post_code IS NULL OR post_code ~ '^[a-zA-Z][a-zA-Z0-9]{1,3} \\d[a-zA-Z]{2}$')"
    execute "ALTER TABLE events ADD FOREIGN KEY (category_id) REFERENCES event_categories (id) MATCH FULL"

    execute "ALTER TABLE event_categories ADD CHECK (name <> '')"

    execute "ALTER TABLE jobs ADD CHECK (name <> '')"
    execute "ALTER TABLE jobs ADD FOREIGN KEY (event_id) REFERENCES events (id) MATCH FULL"

    execute "ALTER TABLE shifts ADD CHECK (pay_under_21 >= 0)"
    execute "ALTER TABLE shifts ADD CHECK (pay_over_21 >= 0)"
    execute "ALTER TABLE shifts ADD CHECK (break_mins >= 0)"
    execute "ALTER TABLE shifts ADD CHECK (allowance >= 0)"
    execute "ALTER TABLE shifts ADD CHECK (min_hrs_for_allowance >= 0)"
    execute "ALTER TABLE shifts ADD FOREIGN KEY (job_id) REFERENCES jobs (id) MATCH FULL"

    execute "ALTER TABLE locations ADD CHECK (staff_count >= 0)"
    execute "ALTER TABLE locations ADD CHECK (name <> '')"
    execute "ALTER TABLE locations ADD FOREIGN KEY (event_id) REFERENCES events (id) MATCH FULL"

    execute "ALTER TABLE transports ADD CHECK (name <> '')"
    execute "ALTER TABLE transports ADD FOREIGN KEY (event_id) REFERENCES events (id) MATCH FULL"

    execute "ALTER TABLE gigs ADD FOREIGN KEY (prospect_id) REFERENCES prospects (id) MATCH FULL"
    execute "ALTER TABLE gigs ADD FOREIGN KEY (event_id) REFERENCES events (id) MATCH FULL"
    execute "ALTER TABLE gigs ADD FOREIGN KEY (job_id) REFERENCES jobs (id) MATCH FULL"
    execute "ALTER TABLE gigs ADD FOREIGN KEY (transport_id) REFERENCES transports (id) MATCH FULL"
    execute "ALTER TABLE gigs ADD FOREIGN KEY (location_id) REFERENCES locations (id) MATCH FULL"

    execute "ALTER TABLE gig_requests ADD CHECK (gig_id IS NULL OR NOT pending)"
    execute "ALTER TABLE gig_requests ADD FOREIGN KEY (prospect_id) REFERENCES prospects (id) MATCH FULL"
    execute "ALTER TABLE gig_requests ADD FOREIGN KEY (event_id) REFERENCES events (id) MATCH FULL"

    execute "ALTER TABLE tax_weeks ADD FOREIGN KEY (event_id) REFERENCES events (id) MATCH FULL"
    execute "ALTER TABLE tax_weeks ADD FOREIGN KEY (prospect_id) REFERENCES prospects (id) MATCH FULL"
    execute "ALTER TABLE tax_weeks ADD CHECK (tax_week > 0 AND tax_week <= 52)"
    execute "ALTER TABLE tax_weeks ADD CHECK (monday >= 0 AND tuesday >= 0 AND wednesday >= 0 AND thursday >= 0 AND friday >= 0 AND saturday >= 0 AND sunday >= 0)"
    execute "ALTER TABLE tax_weeks ADD CHECK (rate > 0 AND deduction >= 0 AND allowance >= 0)"
    execute "ALTER TABLE tax_weeks ADD UNIQUE (prospect_id, tax_week, year, event_id, rate)"

    # we can't easily add a foreign key constraint to accounts.user_id, since it's a polymorphic association
    #   (it can cross-reference either `prospects` or `officers`)
    execute "ALTER TABLE accounts ADD CHECK (user_type IN ('Prospect', 'Officer'))"

    execute "ALTER TABLE account_sessions ADD CHECK (time_end >= time_start)"
    execute "ALTER TABLE account_sessions ADD FOREIGN KEY (account_id) REFERENCES accounts (id) MATCH FULL"

    execute "ALTER TABLE officers ADD CHECK (name <> '')"
    execute "ALTER TABLE officers ADD CHECK (role IN ('admin', 'manager', 'staffer'))"

    execute "ALTER TABLE text_blocks ADD CHECK (key <> '')"
    execute "ALTER TABLE text_blocks ADD CHECK (type IN ('page', 'email', 'terms'))"

    execute "ALTER TABLE answers ADD FOREIGN KEY (prospect_id) REFERENCES prospects (id) MATCH FULL"
    execute "ALTER TABLE answers ADD CHECK (answer <> '')"
    execute "ALTER TABLE answers ADD UNIQUE (prospect_id, question_id)"

    execute "ALTER TABLE faq_entries ADD CHECK (position >= 0)"
    execute "ALTER TABLE faq_entries ADD CHECK (question <> '')"
    execute "ALTER TABLE faq_entries ADD CHECK (answer <> '')"

    execute "ALTER TABLE library_items ADD CHECK (name <> '')"
    execute "ALTER TABLE library_items ADD UNIQUE (name)"
    execute "ALTER TABLE library_items ADD UNIQUE (filename)"
    execute "ALTER TABLE library_items ADD CHECK (filename <> '' AND filename !~ '\\\\|/')"

    execute "ALTER TABLE scanned_ids ADD CHECK (photo ~ '^[A-Za-z0-9._%-]+\\.(jpg|jpeg|gif|png)$')"
    execute "ALTER TABLE scanned_ids ADD FOREIGN KEY (prospect_id) REFERENCES prospects (id) MATCH FULL"

    execute "ALTER TABLE countries ADD CHECK (name <> '')"

    execute "ALTER TABLE regions ADD CHECK (name <> '')"

    execute "ALTER TABLE post_regions ADD FOREIGN KEY (region_id) REFERENCES regions (id) MATCH FULL"

    execute "ALTER TABLE post_areas ADD FOREIGN KEY (post_region_id) REFERENCES post_regions (id) MATCH FULL"
  end

  def down
    raise "Just DROP the silly DB, CREATE it again, and be done with it!"
  end
end
