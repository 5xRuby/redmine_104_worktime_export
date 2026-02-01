# frozen_string_literal: true

require_relative 'lib/one_zero_four_worktime/excel_exporter'

Redmine::Plugin.register :one_zero_four_worktime_export do
  name '104 Worktime Export'
  author '5xRuby CO., LTD'
  author_url 'https://5xruby.com/en'
  url 'https://5xruby.com/en'
  description 'Export time entries in 104 HR system format'
  version '1.0.0'

  settings default: {
    'employee_number_cf_id' => '',
    'default_start_time' => '09:30'
  }, partial: 'settings/one_zero_four_worktime_settings'

  permission :export_104_worktime, {one_zero_four_worktime: [:index, :export]}, require: :loggedin
end

Rails.configuration.to_prepare do
  ApplicationController.send(:helper, OneZeroFourWorktimeHelper)
end
