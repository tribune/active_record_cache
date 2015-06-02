# Install gems for all appraisal definitions:
#
#     $ appraisal install
#
# To run tests on different versions:
#
#     $ appraisal activerecord_x.x rspec spec

[
  [ '3.2', '~> 3.2.0' ],
  [ '4.0', '~> 4.0.0' ],
  [ '4.1', '~> 4.1.0' ],
  [ '4.2', '~> 4.2.0' ],
].each do |ver_name, ver_req|
  appraise "rails_#{ver_name}" do
    gem 'activerecord', ver_req
  end
end
