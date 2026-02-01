# frozen_string_literal: true

class OneZeroFourWorktimeController < ApplicationController
  menu_item :time_entries

  before_action :find_optional_project
  before_action :authorize_global

  helper :queries
  include QueriesHelper
  helper :timelog
  include TimelogHelper
  helper :one_zero_four_worktime

  rescue_from Query::StatementInvalid, with: :query_statement_invalid
  rescue_from Query::QueryError, with: :query_error

  def index
    # Redirect to last month if no date filter is set
    if params[:set_filter].blank? && session[:time_entry_query].blank?
      redirect_to_with_last_month_filter
      return
    end

    retrieve_time_entry_query

    # Also redirect if date filter is "any" (no spent_on filter)
    if @query.filters['spent_on'].blank?
      redirect_to_with_last_month_filter
      return
    end

    @grouped_entries = grouped_time_entries
  end

  def export
    retrieve_time_entry_query
    @grouped_entries = grouped_time_entries

    if @grouped_entries.empty?
      flash[:warning] = l(:label_no_time_entries_found)
      redirect_to_index
      return
    end

    workbook = OneZeroFourWorktime::ExcelExporter.new(@grouped_entries, plugin_settings).generate

    send_data workbook.to_stream.read,
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              filename: "104_worktime_#{Date.today.strftime('%Y%m%d')}.xlsx"
  end

  private

  def retrieve_time_entry_query
    retrieve_query(TimeEntryQuery, false)
    filter_active_users_only
  end

  # Override user filter to only show active users (simple list, no grouping)
  def filter_active_users_only
    return unless @query

    user_filter = @query.available_filters['user_id']
    return unless user_filter

    # Replace the values proc in the filter's options
    user_filter.instance_variable_get(:@options)[:values] = lambda {
      User.active.sorted.map { |u| [u.name, u.id.to_s] }
    }
    # Clear memoized values so new lambda is used
    user_filter.instance_variable_set(:@values, nil)
  end

  def time_entry_scope
    @query.results_scope
  end

  def grouped_time_entries
    scope = time_entry_scope.preload(user: :custom_values)
    entries = scope.to_a

    # Group by (date, user)
    grouped = entries.group_by { |e| [e.spent_on, e.user_id] }

    # Build result array
    result = []
    grouped.each do |(date, user_id), user_entries|
      user = user_entries.first.user
      total_hours = user_entries.sum(&:hours)

      # If hours > 4, add 1 hour for break time
      deduct_break = total_hours > 4
      adjusted_hours = deduct_break ? total_hours + 1 : total_hours

      result << {
        date: date,
        user: user,
        total_hours: total_hours,
        adjusted_hours: adjusted_hours,
        deduct_break: deduct_break
      }
    end

    # Sort by date, then by user name
    result.sort_by { |r| [r[:date], r[:user].name] }
  end

  def plugin_settings
    Setting.plugin_one_zero_four_worktime_export || {}
  end

  def redirect_to_index
    if @project
      redirect_to project_one_zero_four_worktime_path(@project)
    else
      redirect_to one_zero_four_worktime_path
    end
  end

  def redirect_to_with_last_month_filter
    last_month = Date.today.prev_month
    first_day = last_month.beginning_of_month
    last_day = last_month.end_of_month

    filter_params = {
      set_filter: 1,
      f: ['spent_on', ''],
      op: { 'spent_on' => '><' },
      v: { 'spent_on' => [first_day.to_s, last_day.to_s] }
    }

    if @project
      redirect_to project_one_zero_four_worktime_path(@project, filter_params)
    else
      redirect_to one_zero_four_worktime_path(filter_params)
    end
  end

  def query_error(exception)
    session.delete(:time_entry_query)
    super
  end
end
