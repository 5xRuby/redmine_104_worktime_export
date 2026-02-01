# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  # Use separate namespace to avoid conflict with time_entries/:id
  # Global routes
  get 'report_104_worktime', to: 'one_zero_four_worktime#index', as: 'one_zero_four_worktime'
  get 'report_104_worktime/export', to: 'one_zero_four_worktime#export', as: 'one_zero_four_worktime_export'

  # Project-scoped routes
  get 'projects/:project_id/report_104_worktime', to: 'one_zero_four_worktime#index', as: 'project_one_zero_four_worktime'
  get 'projects/:project_id/report_104_worktime/export', to: 'one_zero_four_worktime#export', as: 'project_one_zero_four_worktime_export'
end
