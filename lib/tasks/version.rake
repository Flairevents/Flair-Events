namespace :version do

  # Note: When bumping major, minor, and patch versions... any prerelease info is dropped

  desc 'Reads VERSION file and performs a named regex match'
  def version_as_regex_match
    # Named matches: major, minor, patch, prerelease, buildmetadata
    # Regex adapted from https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
    File.read('VERSION').strip.match /^(?<major>0|[1-9]\d*)\.(?<minor>0|[1-9]\d*)\.(?<patch>0|[1-9]\d*)(?:-(?<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/
  end

  desc 'Takes a new version parameter and updates the VERSION file'
  task :bump, [:new_version] => :environment do | task, args |
    current_version = File.read('VERSION').strip
    File.open("VERSION", "w") { |f| f.write args.new_version }
    puts "Version updated from #{ current_version } to #{ args.new_version }"
  end

  desc 'Bumps the prerelease version'
  task :bump_prerelease do
    current_version = version_as_regex_match
    current_prerelease_version = current_version[:prerelease].match /^(?<type>\D*)(?<increment>\d*)$/
    Rake::Task["version:bump"].invoke [current_version[:major], current_version[:minor], current_version[:patch] + "-#{ current_prerelease_version[:type] }#{ current_prerelease_version[:increment].to_i + 1 }"].join('.')
  end

  desc 'Bumps the patch version'
  task :bump_patch do
    current_version = version_as_regex_match
    Rake::Task["version:bump"].invoke [current_version[:major], current_version[:minor], current_version[:patch].to_i + 1].join('.')
  end

  desc 'Bumps the minor version'
  task :bump_minor do
    current_version = version_as_regex_match
    Rake::Task["version:bump"].invoke [current_version[:major], current_version[:minor].to_i + 1, 0].join('.')
  end

  desc 'Bumps the major version'
  task :bump_major do
    current_version = version_as_regex_match
    Rake::Task["version:bump"].invoke [current_version[:major].to_i + 1, 0, 0].join('.')
  end

  desc 'Takes a parameter and sets the current version as a prerelease (alpha, beta, rc)'
  task :prerelease, [:type] => :environment do | task, args |
    current_version = version_as_regex_match
    Rake::Task["version:bump"].invoke [current_version[:major], current_version[:minor], current_version[:patch] + "-#{ args.type }1"].join('.')
  end

  desc 'Moves a prerelease out into a release'
  task :release do
    current_version = version_as_regex_match
    Rake::Task["version:bump"].invoke [current_version[:major], current_version[:minor], current_version[:patch]].join('.')
  end

end
