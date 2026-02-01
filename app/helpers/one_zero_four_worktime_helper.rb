# frozen_string_literal: true

module OneZeroFourWorktimeHelper
  def _one_zero_four_worktime_path(project = nil, options = {})
    if project
      project_one_zero_four_worktime_path(project, options)
    else
      one_zero_four_worktime_path(options)
    end
  end

  def _one_zero_four_worktime_export_path(project = nil, options = {})
    if project
      project_one_zero_four_worktime_export_path(project, options)
    else
      one_zero_four_worktime_export_path(options)
    end
  end

  def employee_number_for(user)
    cf_id = plugin_settings['employee_number_cf_id']
    return nil if cf_id.blank?

    user.custom_field_value(cf_id.to_i)
  end

  def format_time_hhmm(time_str)
    return time_str if time_str.blank?

    time_str.to_s
  end

  def calculate_end_time(start_time_str, hours)
    return '' if start_time_str.blank?

    parts = start_time_str.split(':')
    start_hour = parts[0].to_i
    start_minute = parts[1].to_i

    total_minutes = start_hour * 60 + start_minute + (hours * 60).to_i
    end_hour = (total_minutes / 60) % 24
    end_minute = total_minutes % 60

    format('%02d:%02d', end_hour, end_minute)
  end

  def plugin_settings
    Setting.plugin_one_zero_four_worktime_export || {}
  end

  def default_start_time
    plugin_settings['default_start_time'].presence || '09:30'
  end
end
