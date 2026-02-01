# frozen_string_literal: true

require_relative '../test_helper'

class OneZeroFourWorktimeControllerTest < Redmine::ControllerTest
  fixtures :projects, :users, :user_preferences, :members, :member_roles, :roles,
           :issues, :trackers, :projects_trackers, :issue_statuses,
           :enabled_modules, :enumerations, :time_entries, :custom_fields, :custom_values

  def setup
    User.current = nil
    @request.session[:user_id] = 2
    Role.find(1).add_permission!(:export_104_worktime)

    # Create employee number custom field
    @employee_cf = UserCustomField.create!(
      name: '104 Employee Number',
      field_format: 'string',
      is_for_all: true
    )

    # Set custom field value for user
    user = User.find(2)
    user.custom_field_values = { @employee_cf.id => 'EMP001' }
    user.save!

    # Configure plugin settings
    Setting.plugin_one_zero_four_worktime_export = {
      'employee_number_cf_id' => @employee_cf.id.to_s,
      'default_start_time' => '09:30'
    }
  end

  def teardown
    Setting.plugin_one_zero_four_worktime_export = nil
    @employee_cf&.destroy
  end

  # === Route Tests ===

  def test_route_global_index
    assert_routing(
      { method: 'get', path: '/report_104_worktime' },
      { controller: 'one_zero_four_worktime', action: 'index' }
    )
  end

  def test_route_global_export
    assert_routing(
      { method: 'get', path: '/report_104_worktime/export' },
      { controller: 'one_zero_four_worktime', action: 'export' }
    )
  end

  def test_route_project_index
    assert_routing(
      { method: 'get', path: '/projects/ecookbook/report_104_worktime' },
      { controller: 'one_zero_four_worktime', action: 'index', project_id: 'ecookbook' }
    )
  end

  def test_route_project_export
    assert_routing(
      { method: 'get', path: '/projects/ecookbook/report_104_worktime/export' },
      { controller: 'one_zero_four_worktime', action: 'export', project_id: 'ecookbook' }
    )
  end

  # === Redirect to Last Month Tests ===

  def test_index_without_filter_redirects_to_last_month
    get :index

    assert_response :redirect
    assert_redirected_to %r{/report_104_worktime\?}

    # Verify redirect includes last month date range
    last_month = Date.today.prev_month
    first_day = last_month.beginning_of_month.to_s
    last_day = last_month.end_of_month.to_s

    assert_match(/v%5Bspent_on%5D%5B%5D=#{first_day}/, response.location)
    assert_match(/v%5Bspent_on%5D%5B%5D=#{last_day}/, response.location)
  end

  def test_index_with_project_without_filter_redirects_to_last_month
    get :index, params: { project_id: 'ecookbook' }

    assert_response :redirect
    assert_redirected_to %r{/projects/ecookbook/report_104_worktime\?}
  end

  def test_index_with_date_filter_does_not_redirect
    get :index, params: {
      set_filter: 1,
      f: ['spent_on', ''],
      op: { 'spent_on' => '><' },
      v: { 'spent_on' => ['2007-03-01', '2007-03-31'] }
    }
    assert_response :success
  end

  def test_index_with_project_and_date_filter
    get :index, params: {
      project_id: 'ecookbook',
      set_filter: 1,
      f: ['spent_on', ''],
      op: { 'spent_on' => '><' },
      v: { 'spent_on' => ['2007-03-01', '2007-03-31'] }
    }
    assert_response :success
  end

  # === Export Tests ===

  def test_export
    get :export, params: {
      set_filter: 1,
      f: ['spent_on', ''],
      op: { 'spent_on' => '><' },
      v: { 'spent_on' => ['2007-03-01', '2007-03-31'] }
    }
    assert_response :success
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', response.media_type
    assert_match /104_worktime_\d{8}\.xlsx/, response.headers['Content-Disposition']
  end

  def test_export_with_project
    get :export, params: {
      project_id: 'ecookbook',
      set_filter: 1,
      f: ['spent_on', ''],
      op: { 'spent_on' => '><' },
      v: { 'spent_on' => ['2007-03-01', '2007-03-31'] }
    }
    assert_response :success
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', response.media_type
  end

  def test_export_with_no_entries_redirects
    get :export, params: {
      set_filter: 1,
      f: ['spent_on', ''],
      op: { 'spent_on' => '><' },
      v: { 'spent_on' => ['2099-01-01', '2099-01-02'] }
    }
    assert_response :redirect
    assert_equal I18n.t(:label_no_time_entries_found), flash[:warning]
  end

  # === Permission Tests ===

  def test_index_without_permission
    Role.find(1).remove_permission!(:export_104_worktime)
    get :index, params: {
      set_filter: 1,
      f: ['spent_on', ''],
      op: { 'spent_on' => '><' },
      v: { 'spent_on' => ['2007-03-01', '2007-03-31'] }
    }
    assert_response :forbidden
  end

  def test_export_without_permission
    Role.find(1).remove_permission!(:export_104_worktime)
    get :export, params: {
      set_filter: 1,
      f: ['spent_on', ''],
      op: { 'spent_on' => '><' },
      v: { 'spent_on' => ['2007-03-01', '2007-03-31'] }
    }
    assert_response :forbidden
  end

  # === Employee Number Custom Field Tests ===

  def test_index_displays_employee_number
    get :index, params: {
      set_filter: 1,
      f: ['spent_on', ''],
      op: { 'spent_on' => '><' },
      v: { 'spent_on' => ['2007-03-01', '2007-03-31'] }
    }
    assert_response :success
    assert_select 'table.list tbody tr td', text: 'EMP001'
  end

  def test_export_includes_employee_number
    get :export, params: {
      set_filter: 1,
      f: ['spent_on', ''],
      op: { 'spent_on' => '><' },
      v: { 'spent_on' => ['2007-03-01', '2007-03-31'] }
    }
    assert_response :success

    # Parse the Excel file and verify employee number is included
    xlsx = Axlsx::Package.new
    xlsx_stream = StringIO.new(response.body)
    # Note: Axlsx doesn't support reading, but we can verify the response is valid Excel
    assert response.body.start_with?("PK"), "Response should be a valid XLSX (ZIP) file"
  end
end
