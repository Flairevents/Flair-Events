# Changelog

All changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- jpegtran for image rotation
- Rails 6 upgrade
- Reinitialize ZoomIt after image rotation
- Office > Planner > Popup: datepicker fix
- Office > Planner > CSS > #planner.slideover: responsive issue
- Custom EventTasks should have a proper template and "task" value. Don't use nil.

## [1.0.21] - 2020-12-04

### Changed

- Removed job notes from WebApp CSV, now just a blank column

## [1.0.20] - 2020-12-02

### Changed

- Tweaked job name for WebApp CSV

## [1.0.19] - 2020-11-30

### Added

- Office zone now has a data export for the WebApp
- Gigs now have a 'published' attribute. This indicates if the data for a particular gig has been exported yet or not.
- Added a 'Pub?' filter for gigs view
- Added a callback on GigTaxWeek. If the confirmed attribute is toggled then the Gig association will change the 'published' state to false.
- Created a rake task for Reports
- Added two scopes to Gig: :published and :unpublished
- Added a conditional css to events' prospect name. If a prospect is confirmed and published, the background is orange.

### Changed

- Hid some filters in the events views. We can probably remove them later if they are not used.
- Disabled Google Analytics until we have the cookie policy and banner in place

## [1.0.18] - 2020-11-25

### Added

- Google Analytics

## [1.0.17] - 2020-11-25

### Added

- Added capistrano task to run a remote rake task.

## [1.0.16] - 2020-11-25

### Added

- Two reports were added: WebApp Daily, WebApp Weekly

### Changed

- Some minor hacks added to report.rb model to support the time reporting webapp. These should be removed after we merge that webapp with master.
- Footer company name and logo for reports have been replaced with new ones.

## [1.0.15] - 2020-11-12

### Changed

- Changed sitemaps to differentiate between eventstaffing.co.uk and www.eventstaffing.co.uk

## [1.0.14] - 2020-11-12

### Added

- Added sitemap_generator gem

## [1.0.13] - 2020-11-12

### Added

- Added meta description for the public layout

### Changed

- Changed the title tag for the public layout

## [1.0.12] - 2020-10-26

### Changed

- Changed the dropdown options in gigs-view.coffee so that the options are filtered by the selected job. Should cut down on the number of options displayed.
- Updated the note regarding the captistrano task db:update_staging. Sometimes there are connections even though the processes have been killed. Not sure why. Anyways, kill them off with a command then run the task. The command could be integrated into the task later [TODO](#Unreleased).

## [1.0.11] - 2020-10-07

### Added

- Added "No FHS" and "No DBS" to qualifications filters.
- Created the ability to upload a DBS, similar to scanned ids. On successful upload the Prospect's dbs_qualification attribute is toggled to true. As a side note, the dbs_qualification attribute is on the questionnaire association. We might want to move this into the Prospect model [TODO](#Unreleased). 
- Added dbs_certificate_number to Questionnaire model. We might change this to the Prospect model later.
- Created config/initializers/inflections.rb to handle irregular inflection of dbs and dbses.

### Changed

- Changed DBS filter in db-proxy.coffee to not only consider the dbs_issue_date but also check if the date is null and the status of the Prospect's questionnaire dbs_qualification attribute.
- Fixed some layout issues in the upload modals and prospect view

## [1.0.10] - 2020-09-17

### Changed

- Added a couple of includes for a query in OfficeController#update_jobs
- Changed EventTask query in the Report model. Records were missing due to multiple joins. Also, "custom" event tasks were displayed as blank, so we added a hacky loop to add the text "Custom" to each record. This should be removed when we create a proper "custom" template, [TODO](#Unreleased).

## [1.0.9] - 2020-09-02

### Added

- Added custom CSS in app/assets/stylesheets/office.sass for #planner.slideover. The planner is more reasonably sized. But the issue of responsive design still exists. Small browser windows or mobile devices will have issues and needs to be addressed later.

### Changed

- Changed app/assets/javascripts/office-views/planner-view.coffee to comment out some debugging code and noted a new bug
- Tweaked app/assets/javascripts/db-proxy.coffee where @addFilters('event_tasks', ignore_canceled_events) was hiding event_tasks where the event_id was null
- Fixed a bug in OfficeController#update_event_tasks_from_event where changes to the event task name in the Contracts view didn't update the task in the Planner.

## [1.0.8] - 2020-09-02

### Changed

- Updated app/assets/javascripts/office-views/[bar license approval|id approval].hamlc to trigger an action on the server to rotate images.
- Fixed an AJAX request in app/assets/javascripts/staff.js. The function onFocusOutAjaxCall was looking for a form that could not be found and would throw an error. Before executing the AJAX, it now checks for the form.

### Added

- Added two 2 actions in the OfficeController and corresponding routes to handle image rotation: rotate_scanned_bar_license, rotate_scanned_id
- Added #rotate method to models ScannedBarLicense and ScannedId. Calling this method will locate the photo attachment, rotate it 90degrees clockwise, then save. It should be noted that the process may be lossy and we should implement jpegtran later.

## [1.0.7] - 2020-09-01

### Changed

- Changed PublicController#register to pre-fill registration form on development and staging only
- Added @city to PublicController#back_to_register
- Modified app/views/public/_registration_form so that we don't lose the city field

## [1.0.6] - 2020-09-01

### Added

- Added gems 'slim', 'webconsole' to Gemfile
- Added webconsole to Public and Staff layouts (Development only)
- Created an ExceptionMailer to allow graceful fails yet capture instances where a bug is still slipping through. It takes 2 variables - @id: the class#method, @info: a string with some useful info like params, user agent, etc.

### Changed

- Changed recipients in config/initializers/override_mail_recipient.rb to error@tayden.ca, moved appybara to bcc for now.

## [1.0.5] - 2020-09-01

### Removed

- Removed Twitter/Facebook JS, can reimplement later if needed. The Twitter one in particular was throwing a 'twttr' is undefined error.

## [1.0.4] - 2020-08-31

### Changed

- Added error@tayden.ca to bbc for emails. We can leave appybara as-is for now.
- Added note in staff.js where an AJAX post is missing a route.

## [1.0.3] - 2020-08-27

### Changed

- ApplicationController#prospect_photo throws a 500 error when the prospect is nil since it's looking for root_url/prospect_photos/null. A condition checking for a nil prospect was added. It should return the placeholder avatar.

## [1.0.2] - 2020-08-27

### Added

- NewRelic will now automatically track deployments.

## [1.0.1] - 2020-08-27

### Added

- NewRelic performance monitoring was added.

## [1.0.0] - 2020-08-20

### Added

- A CHANGELOG.md has been added to track changes made to the project in a human readable format. All changes should be documented here and include an explanation of why the changes were made and how they were implemented.
- Added files VERSION and config/initializers/version.rb and set initial application version to 1.0.0. We can now keep track of versions and tag releases in git.
- Added a rake task, lib/tasks/version.rake, to help increment changes to the project's version number and to ahear to semver convention:
  - Incrementing a version number can be done like so:
    -  rails version:bump_prerelease
    -  rails version:bump_patch
    -  rails version:bump_minor
    -  rails version:bump_major
  - To set a prerelease execute:
    - rails version:prerelease[alpha|beta|rc]
  - To move from a prerelease to release execute:
    - rails version:release
  - Versions can be manually changed in config/initializers/version.rb
  - Care should be taken before pushing to origin to ensure the version numbers have not already been taken.
