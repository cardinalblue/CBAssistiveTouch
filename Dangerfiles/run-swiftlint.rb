# You can test this file by doing dry run with the following command in your terminal at the root of the project:
#
# export DANGER_LOCAL_HEAD=$(git branch --show-current)
# export DANGER_LOCAL_BASE=dev_10
# bundle exec danger dry_run --dangerfile=Dangerfiles/run-swiftlint.rb

swiftlint_path = `mise which swiftlint`.strip

unless File.exist?(swiftlint_path)
  fail("Could not find `swiftlint`.")
  return
end

swiftlint.binary_path = swiftlint_path
swiftlint.lint_all_files = true
swiftlint.lint_files

if swiftlint.issues.any? then
  meme = "https://cb-ios-dev.s3.us-east-1.amazonaws.com/images/where_does_it_come_from.jpeg"
  fail("Swiftlint did not pass. Please fix the issues and push again.\n\n![Swiftlint Meme](#{meme})")
end
