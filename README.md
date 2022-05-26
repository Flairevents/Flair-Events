# Flair Event Staffing

The Flair Event Staffing website is built on Ruby on Rails. There are 3 main sections:

## Public Zone

This uses standard Rails MVC architecture.

## Staff Zone

This uses standard Rails MVC architecture.

This is where temporary employees login to complete their profile, sign up for an interview, select events, do training, etc.

## Office Zone

This is a custom SPA that accesses a Rails API.

Office HQ staff use this to manage events, employees, clients, payroll, etc.

### Data Architecture

When the SPA is loaded, the relevant portions of the database are serialized on the API, and then sent to the SPA. The SPA deserializes this data and stores it in a memory object (db-proxy.coffee). This results in a very responsive front-end as all data is stored in memory.

#### Keeping Front-End Data in Sync

After the initial load, there are a few methods to keep data in sync:
1. A "refresh" link to get any new data and deletions. In the refresh request, we send a timestamp of the last time we refreshed. This way the API can send back only the newly created/updated/delete data.
2. Each endpoint we call in the API returns a result that contains the updated objects, as well as the ID of deleted objects. A helper class, OfficeZoneSync was created to automate this process. To use it, simply `include OfficeZoneSync` in the model that you want to automatically sync. Then in the controller method render with: `render json: OfficeZoneSync.get_synced_response`

#### Specifying which models/columns are sent to the office zone


1. Edit the file `lib/models.rb`. This is used to generate the files that will serialize/deserialize the data sent to the office zone from the `office_controller.rb`. Following the format of the file, add any desired models/columns. Make sure to set "null: true" if this column can be null.
2. Generate the serialization (`lib/models/export.rb`) and deserialization (`/app/assets/javascripts/import.coffee`) files with the following command in a terminal: `rails serialization:generate_code`

Note: Never manually edit `export.rb` nor `import.coffee`. These must always be generated from `lib/models.rb`

This approach was used since it greatly speeds up the initial load of data into the office zone.
