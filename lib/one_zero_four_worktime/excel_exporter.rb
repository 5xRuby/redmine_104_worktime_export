# frozen_string_literal: true

module OneZeroFourWorktime
  class ExcelExporter
    HEADERS = [
      '序號',
      '員工編號',
      '員工姓名',
      '時數開始日期',
      '時數開始時間',
      '時數結束日期',
      '時數結束時間',
      '是否扣除休息時間'
    ].freeze

    RULE_ROW = [
      '填寫規則',
      '必填',
      '必填',
      '必填',
      '必填',
      '必填',
      '必填',
      '必填'
    ].freeze

    FORMAT_ROW = [
      '欄位格式',
      '',
      '',
      'YYYY/MM/DD',
      'HH:MM',
      'YYYY/MM/DD',
      'HH:MM',
      '選單'
    ].freeze

    EXAMPLE_ROW_1 = [
      '範例',
      '9104',
      '伊琳士',
      '2013/09/01',
      '9:00',
      '2013/09/01',
      '18:00',
      '是'
    ].freeze

    EXAMPLE_ROW_2 = [
      '範例',
      '9104',
      '伊琳士',
      '2013/09/02',
      '14:00',
      '2013/09/03',
      '18:00',
      '否'
    ].freeze

    def initialize(grouped_entries, settings = {})
      @grouped_entries = grouped_entries
      @settings = settings
      @default_start_time = settings['default_start_time'].presence || '09:30'
      @employee_number_cf_id = settings['employee_number_cf_id']
    end

    def generate
      package = Axlsx::Package.new
      workbook = package.workbook

      workbook.add_worksheet(name: '104工時報表') do |sheet|
        # Title row
        sheet.add_row ['時數資料']

        # Header rows
        sheet.add_row HEADERS
        sheet.add_row RULE_ROW
        sheet.add_row FORMAT_ROW
        sheet.add_row EXAMPLE_ROW_1
        sheet.add_row EXAMPLE_ROW_2

        # Data rows
        @grouped_entries.each_with_index do |entry, index|
          sheet.add_row build_data_row(entry, index + 1)
        end
      end

      package
    end

    private

    def build_data_row(entry, sequence)
      user = entry[:user]
      date = entry[:date]
      adjusted_hours = entry[:adjusted_hours]
      deduct_break = entry[:deduct_break]

      employee_number = get_employee_number(user)
      start_time = @default_start_time
      end_time = calculate_end_time(start_time, adjusted_hours)

      # Add 30 mins for dinner break if end time is over 17:30
      end_time = add_dinner_break(end_time)

      date_str = date.strftime('%Y/%m/%d')

      [
        sequence,
        employee_number,
        "#{user.lastname}#{user.firstname}",
        date_str,
        start_time,
        date_str,
        end_time,
        deduct_break ? '是' : '否'
      ]
    end

    def get_employee_number(user)
      return '' if @employee_number_cf_id.blank?

      user.custom_field_value(@employee_number_cf_id.to_i) || ''
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

    # Add 30 minutes for dinner break if end time is over 17:30
    def add_dinner_break(end_time_str)
      return end_time_str if end_time_str.blank?

      parts = end_time_str.split(':')
      hour = parts[0].to_i
      minute = parts[1].to_i

      # Check if over 17:30
      if hour > 17 || (hour == 17 && minute > 30)
        total_minutes = hour * 60 + minute + 30
        hour = (total_minutes / 60) % 24
        minute = total_minutes % 60
      end

      format('%02d:%02d', hour, minute)
    end
  end
end
