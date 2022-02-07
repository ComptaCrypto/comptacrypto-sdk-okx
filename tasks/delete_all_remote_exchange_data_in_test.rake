# frozen_string_literal: true

require "fileutils"

desc "Delete all remote exchange data in test"
task :delete_all_remote_exchange_data_in_test do
  # remove all files/folders inside `spec/vcr_cassettes/`
  print "Deleting VCR cassettes files... "
  FileUtils.rm_rf(Dir["spec/vcr_cassettes/*"])
  puts "Done."

  # remove the `spec/CURRENT_TIME.iso8601` file
  print "Deleting frozen time file... "
  FileUtils.remove_file("spec/CURRENT_TIME.iso8601", true)
  puts "Done."
end
